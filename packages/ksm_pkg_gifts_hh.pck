Create Or Replace Package ksm_pkg_gifts_hh Is

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_gifts_hh';
collect_default_limit Constant pls_integer := 100;

/*************************************************************************
Public type declarations
*************************************************************************/

Type klc_member Is Record (
  fiscal_year integer
  , level_desc varchar2(40)
  , id_number entity.id_number%type
  , household_id entity.id_number%type
  , household_record entity.record_type_code%type
  , household_rpt_name entity.report_name%type
  , household_spouse_id entity.id_number%type
  , household_spouse entity.pref_mail_name%type
  , household_suffix entity.institutional_suffix%type
  , household_ksm_year degrees.degree_year%type
  , household_masters_year degrees.degree_year%type
  , household_program_group varchar2(20)
  , klc_fytd character
);

Type trans_household Is Record (
  household_id entity.id_number%type
  , household_rpt_name entity.report_name%type
  , id_number entity.id_number%type
  , report_name entity.report_name%type
  , anonymous gift.gift_associated_anonymous%type
  , tx_number gift.gift_receipt_number%type
  , tx_sequence gift.gift_sequence%type
  , transaction_type_code varchar2(10)
  , transaction_type varchar2(40)
  , tx_gypm_ind varchar2(1)
  , associated_code tms_association.associated_code%type
  , associated_desc tms_association.short_desc%type
  , pledge_number pledge.pledge_pledge_number%type
  , pledge_fiscal_year pledge.pledge_year_of_giving%type
  , matched_tx_number matching_gift.match_gift_matched_receipt%type
  , matched_fiscal_year number
  , payment_type tms_payment_type.short_desc%type
  , allocation_code allocation.allocation_code%type
  , alloc_short_name allocation.short_name%type
  , ksm_flag varchar2(1)
  , af_flag varchar2(1)
  , cru_flag varchar2(1)
  , gift_comment primary_gift.prim_gift_comment%type
  , proposal_id primary_pledge.proposal_id%type
  , pledge_status primary_pledge.prim_pledge_status%type
  , date_of_record gift.gift_date_of_record%type
  , fiscal_year number
  , legal_amount gift.gift_associated_amount%type
  , credit_amount gift.gift_associated_amount%type
  , recognition_credit gift.gift_associated_amount%type
  , stewardship_credit_amount gift.gift_associated_amount%type
  , hh_credit gift.gift_associated_amount%type
  , hh_recognition_credit gift.gift_associated_amount%type
  , hh_stewardship_credit gift.gift_associated_amount%type
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type t_klc_members Is Table Of klc_member;
Type t_trans_household Is Table Of trans_household;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

-- Pipelined table of KLC members
Function tbl_klc_history(
    limit_size In pls_integer Default collect_default_limit
  )
  Return t_klc_members Pipelined;

-- Pipelined table of Kellogg transactions
Function tbl_gift_credit_hh_ksm(
    limit_size In pls_integer Default collect_default_limit
  )
  Return t_trans_household Pipelined;

/*************************************************************************
Public cursors -- data definitions
*************************************************************************/

-- Definition of a KLC member
Cursor c_klc_history(fy_start_month In integer) Is
  Select
    extract(year from ksm_pkg_utility.to_date2(gift_club_end_date, 'yyyymmdd'))
      As fiscal_year
    , tms_lvl.short_desc As level_desc
    , hh.id_number
    , hh.household_id
    , hh.household_record
    , hh.household_rpt_name
    , hh.household_spouse_id
    , hh.household_spouse
    , hh.household_suffix
    , hh.household_ksm_year
    , hh.household_masters_year
    , hh.household_program_group
    -- FYTD indicator
    , Case
        When extract(year from ksm_pkg_utility.to_date2(gift_club_start_date, 'yyyymmdd')) <
          extract(year from ksm_pkg_utility.to_date2(gift_club_end_date, 'yyyymmdd'))
          And extract(month from ksm_pkg_utility.to_date2(gift_club_start_date, 'yyyymmdd')) < fy_start_month
          Then 'Y'
        Else fytd_indicator(ksm_pkg_utility.to_date2(gift_club_start_date, 'yyyymmdd'))
      End As klc_fytd
  From gift_clubs
  Inner Join table(ksm_pkg_households.tbl_entity_households_ksm) hh
    On hh.id_number = gift_clubs.gift_club_id_number
  Left Join nu_mem_v_tmsclublevel tms_lvl
    On tms_lvl.level_code = gift_clubs.school_code
  Where gift_club_code = 'LKM'
  ;
 
-- Definition of householded KSM giving transactions for summable credit
-- Depends on c_gift_credit_ksm, through tbl_gift_credit_ksm table function
Cursor c_gift_credit_hh_ksm Is
  With
  hhid As (
    Select
      hh.household_id
      , entity.report_name As household_rpt_name
      , ksm_trans.*
    From table(ksm_pkg_households.tbl_households_fast) hh
    Inner Join table(ksm_pkg_gifts.tbl_gift_credit_ksm) ksm_trans
      On ksm_trans.id_number = hh.id_number
    Inner Join entity
      On entity.id_number = hh.household_id
  )
  , giftcount As (
    Select
      household_id
      , tx_number
      , count(id_number) As id_cnt
    From hhid
    Group By household_id, tx_number
  )
  /* Main query */
  Select
    hhid.*
    -- Household primary credit
    , Case
        When hhid.id_number = hhid.household_id Then hhid.credit_amount
        When id_cnt = 1 Then hhid.credit_amount
        Else 0
      End As hh_credit
    -- Household recognition credit
    , Case
        When hhid.id_number = hhid.household_id Then hhid.recognition_credit
        When id_cnt = 1 Then hhid.recognition_credit
        Else 0
      End As hh_recognition_credit
    -- Household stewardship credit
    , Case
        When hhid.id_number = hhid.household_id Then hhid.stewardship_credit_amount
        When id_cnt = 1 Then hhid.stewardship_credit_amount
        Else 0
      End As hh_stewardship_credit
  From hhid
  Inner Join giftcount gc
    On gc.household_id = hhid.household_id
    And gc.tx_number = hhid.tx_number
  ;

End ksm_pkg_gifts_hh;
/
Create Or Replace Package Body ksm_pkg_gifts_hh Is

/*************************************************************************
Pipelined functions
*************************************************************************/

-- Pipelined function returning KLC members (per c_klc_history)
Function tbl_klc_history(
    limit_size In pls_integer Default collect_default_limit
  )
  Return t_klc_members Pipelined As
  -- Declarations
  klc t_klc_members;

  Begin
    If c_klc_history %ISOPEN then
      Close c_klc_history;
    End If;
    Open c_klc_history(ksm_pkg_calendar.get_numeric_constant('fy_start_month'));
    Loop
      Fetch c_klc_history Bulk Collect Into klc Limit limit_size;
      Exit When klc.count = 0;
      For i in 1..(klc.count) Loop
        Pipe row(klc(i));
      End Loop;
    End Loop;
    Close c_klc_history;
    Return;
  End;

-- Householdable entity giving, based on c_gift_credit_hh_ksm
  Function tbl_gift_credit_hh_ksm(
    limit_size In pls_integer Default collect_default_limit
  )
    Return t_trans_household Pipelined As
    -- Declarations
    trans t_trans_household;
    
    Begin
      If c_gift_credit_hh_ksm %ISOPEN then
        Close c_gift_credit_hh_ksm;
      End If;
      Open c_gift_credit_hh_ksm;
      Loop
        Fetch c_gift_credit_hh_ksm Bulk Collect Into trans Limit limit_size;
        Exit When trans.count = 0;
        For i in 1..(trans.count) Loop
          Pipe row(trans(i));
        End Loop;
      End Loop;
      Close c_gift_credit_hh_ksm;
      Return;
    End;

End ksm_pkg_gifts_hh;
/
