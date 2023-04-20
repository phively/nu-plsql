Create Or Replace Package ksm_pkg_gifts_campaign Is

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_gifts_campaign';
collect_default_limit Constant pls_integer := 100;

/*************************************************************************
Public type declarations
*************************************************************************/

Type campaign_exception Is Record (
  tx_number nu_rpt_t_cmmt_dtl_daily.rcpt_or_plg_number%type
  , anonymous varchar2(1)
  , amount nu_rpt_t_cmmt_dtl_daily.amount%type
  , amount_explanation varchar2(128)
  , associated_code nu_rpt_t_cmmt_dtl_daily.transaction_type%type
  , associated_desc varchar2(40)
  , ksm_flag varchar2(1)
  , af_flag varchar2(1)
  , cru_flag varchar2(1)
);

Type trans_campaign Is Record (
  id_number nu_rpt_t_cmmt_dtl_daily.id_number%type
  , record_type_code nu_rpt_t_cmmt_dtl_daily.record_type_code%type
  , person_or_org nu_rpt_t_cmmt_dtl_daily.person_or_org%type
  , birth_dt nu_rpt_t_cmmt_dtl_daily.birth_dt%type
  , rcpt_or_plg_number nu_rpt_t_cmmt_dtl_daily.rcpt_or_plg_number%type
  , xsequence nu_rpt_t_cmmt_dtl_daily.xsequence%type
  , anonymous varchar2(1)
  , amount nu_rpt_t_cmmt_dtl_daily.amount%type
  , credited_amount nu_rpt_t_cmmt_dtl_daily.credited_amount%type
  , unsplit_amount nu_rpt_t_cmmt_dtl_daily.prim_amount%type
  , year_of_giving nu_rpt_t_cmmt_dtl_daily.year_of_giving%type
  , date_of_record nu_rpt_t_cmmt_dtl_daily.date_of_record%type
  , alloc_code nu_rpt_t_cmmt_dtl_daily.alloc_code%type
  , alloc_school nu_rpt_t_cmmt_dtl_daily.alloc_school%type
  , alloc_purpose nu_rpt_t_cmmt_dtl_daily.alloc_purpose%type
  , annual_sw nu_rpt_t_cmmt_dtl_daily.annual_sw%type
  , restrict_code nu_rpt_t_cmmt_dtl_daily.restrict_code%type
  , transaction_type_code nu_rpt_t_cmmt_dtl_daily.transaction_type%type
  , transaction_type varchar2(40)
  , pledge_status nu_rpt_t_cmmt_dtl_daily.pledge_status%type
  , gift_pledge_or_match nu_rpt_t_cmmt_dtl_daily.gift_pledge_or_match%type
  , matched_donor_id nu_rpt_t_cmmt_dtl_daily.matched_donor_id%type
  , matched_receipt_number nu_rpt_t_cmmt_dtl_daily.matched_receipt_number%type
  , this_date nu_rpt_t_cmmt_dtl_daily.this_date%type
  , first_processed_date nu_rpt_t_cmmt_dtl_daily.first_processed_date%type
  , std_area nu_rpt_t_cmmt_dtl_daily.std_area%type
  , zipcountry nu_rpt_t_cmmt_dtl_daily.zipcountry%type
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type t_trans_campaign Is Table Of trans_campaign;
Type t_campaign_exception Is Table Of campaign_exception;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

Function tbl_campaign_exceptions_2008
  Return t_campaign_exception Pipelined;

Function tbl_gift_credit_campaign
  Return t_trans_campaign Pipelined;
    
Function tbl_gift_credit_hh_campaign
  Return ksm_pkg_gifts_hh.t_trans_household Pipelined;

/*************************************************************************
Public cursors -- data definitions
*************************************************************************/

-- Definition of Transforming Together Campaign (2008) new gifts & commitments
Cursor c_gift_credit_campaign_2008 Is
  -- Anonymous indicators
  With anons As (
    (
      Select
        gift_receipt_number As tx_number
        , gift_sequence As tx_sequence
        , gift_associated_anonymous As anon
      From gift
    ) Union All (
      Select
        pledge.pledge_pledge_number
        , pledge.pledge_sequence
        , pledge.pledge_anonymous
      From pledge
    ) Union All (
      Select
        match_gift_receipt_number
        , 1
        , gftanon.anon
      From matching_gift
      Inner Join (
          Select
            gift_receipt_number
            , gift_sequence
            , gift_associated_anonymous As anon
          From gift
        ) gftanon On gftanon.gift_receipt_number = matching_gift.match_gift_matched_receipt
          And gftanon.gift_sequence = matching_gift.match_gift_matched_sequence
    )
  )
  -- Transaction and pledge TMS table definition
  , tms_trans As (
    (
      Select
        transaction_type_code
        , short_desc As transaction_type
      From tms_transaction_type
    ) Union All (
      Select
        pledge_type_code
        , short_desc
      From tms_pledge_type
    )
  )
  -- Unsplit definition - summing legal amounts across the KSM portion of each gift
  , unsplit As (
    Select
      rcpt_or_plg_number
      , sum(amount) As unsplit_amount
    From nu_rpt_t_cmmt_dtl_daily daily
    Where daily.alloc_school = 'KM'
    Group By rcpt_or_plg_number
  )
  -- Main query
  (
  Select
    id_number
    , record_type_code
    , person_or_org
    , birth_dt
    , daily.rcpt_or_plg_number
    , xsequence
    , anons.anon
    , amount
    , credited_amount
    , unsplit.unsplit_amount
    , year_of_giving
    , date_of_record
    , alloc_code
    , alloc_school
    , alloc_purpose
    , annual_sw
    , restrict_code
    , daily.transaction_type As transaction_type_code
    , tms_trans.transaction_type
    , pledge_status
    , gift_pledge_or_match
    , matched_donor_id
    , matched_receipt_number
    , this_date
    , first_processed_date
    , std_area
    , zipcountry
  From nu_rpt_t_cmmt_dtl_daily daily
  Inner Join tms_trans On tms_trans.transaction_type_code = daily.transaction_type
  Left Join anons On anons.tx_number = daily.rcpt_or_plg_number
    And anons.tx_sequence = daily.xsequence
  Left Join unsplit On unsplit.rcpt_or_plg_number = daily.rcpt_or_plg_number
  Where daily.alloc_school = 'KM'
  ) Union All (
  -- Internal transfer: 344303 is 50%
  Select
    id_number
    , record_type_code
    , person_or_org
    , birth_dt
    , rcpt_or_plg_number
    , xsequence
    , anons.anon
    , 344303 As amount
    , 344303 As credited_amount
    , 344303 As unsplit_amount
    , year_of_giving
    , date_of_record
    , alloc_code
    , alloc_school
    , alloc_purpose
    , annual_sw
    , restrict_code
    , daily.transaction_type As transaction_type_code
    , tms_trans.transaction_type
    , pledge_status
    , gift_pledge_or_match
    , matched_donor_id
    , matched_receipt_number
    , this_date
    , first_processed_date
    , std_area
    , zipcountry
  From nu_rpt_t_cmmt_dtl_daily daily
  Inner Join tms_trans On tms_trans.transaction_type_code = daily.transaction_type
  Left Join anons On anons.tx_number = daily.rcpt_or_plg_number
    And anons.tx_sequence = daily.xsequence
  Where daily.rcpt_or_plg_number = '0002275766'
  )
  ;
  
-- Definition of householded KSM campaign transactions for summable credit
Cursor c_gift_credit_hh_campaign_2008 Is
  (
  Select
    hh_cred.household_id
    , hh_cred.household_rpt_name
    , hh_cred.id_number
    , hh_cred.report_name
    , hh_cred.anonymous
    , hh_cred.tx_number
    , hh_cred.tx_sequence
    , transaction_type_code
    , transaction_type
    , tx_gypm_ind
    , associated_code
    , associated_desc
    , pledge_number
    , pledge_fiscal_year
    , matched_tx_number
    , matched_fiscal_year
    , payment_type
    , allocation_code
    , alloc_short_name
    , ksm_flag
    , af_flag
    , cru_flag
    , gift_comment
    , proposal_id
    , pledge_status
    , date_of_record
    , fiscal_year
    , legal_amount
    , credit_amount
    , recognition_credit
    , stewardship_credit_amount
    , hh_credit
    , hh_recognition_credit
    , hh_stewardship_credit
  From table(ksm_pkg_gifts_hh.tbl_gift_credit_hh_ksm) hh_cred
  Inner Join (Select Distinct rcpt_or_plg_number From nu_rpt_t_cmmt_dtl_daily) daily
    On hh_cred.tx_number = daily.rcpt_or_plg_number
  ) Union All (
  -- Internal transfer: 344303 is 50%
  Select
    daily.id_number As household_id
    , entity.report_name As household_rpt_name
    , daily.id_number
    , entity.report_name
    , ' ' As anonymous
    , daily.rcpt_or_plg_number
    , daily.xsequence
    , NULL As transaction_type_code
    , 'Internal Transfer' As transaction_type
    , daily.gift_pledge_or_match
    , 'IT' As associated_code
    , 'Internal Transfer' As associated_desc
    , NULL As pledge_number
    , NULL As pledge_fiscal_year
    , NULL As matched_tx_number
    , NULL As matched_fiscal_year
    , 'Internal Transfer'
    , daily.alloc_code
    , allocation.short_name
    , 'Y' As ksm_flag
    , 'N' As af_flag
    , 'N' As cru_flag
    , primary_gift.prim_gift_comment
    , NULL As proposal_id
    , daily.pledge_status
    , daily.date_of_record
    , to_number(daily.year_of_giving) As fiscal_year
    , 344303 As legal_amount
    , 344303 As credit_amount
    , 344303 As recognition_amount
    , 344303 As stewardship_credit_amount
    , 344303 As hh_credit
    , 344303 As hh_recognition_credit
    , 344303 As hh_stewardship_credit
  From nu_rpt_t_cmmt_dtl_daily daily
  Inner Join entity On entity.id_number = daily.id_number
  Inner Join allocation On allocation.allocation_code = daily.alloc_code
  Inner Join primary_gift On primary_gift.prim_gift_receipt_number = daily.rcpt_or_plg_number
  Where daily.rcpt_or_plg_number = '0002275766'
  )
  ;

End ksm_pkg_gifts_campaign;
/
Create Or Replace Package Body ksm_pkg_gifts_campaign Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

-- 2008 campaign exceptions
Cursor campaign_exceptions_2008 Is
  Select
    '0002275766' As tx_number
    , ' ' As anonymous
    , 344303 As amount
    , '50% of face value' As amount_explanation
    , 'IT' As associated_code
    , 'Internal Transfer' As associated_desc
    , 'Y' As ksm_flag
    , 'N' As af_flag
    , 'N' As cru_flag
  From DUAL
  ;

/*************************************************************************
Pipelined functions
*************************************************************************/

-- 2008 campaign exceptions
  Function tbl_campaign_exceptions_2008
    Return t_campaign_exception Pipelined As
    -- Declarations
    trans t_campaign_exception;

  Begin
      Open campaign_exceptions_2008;
        Fetch campaign_exceptions_2008 Bulk Collect Into trans;
      Close campaign_exceptions_2008;
      For i in 1..(trans.count) Loop
        Pipe row(trans(i));
      End Loop;
      Return;
  End;

-- Campaign giving by entity, based on c_gifts_campaign_2008
  Function tbl_gift_credit_campaign
    Return t_trans_campaign Pipelined As
    -- Declarations
    trans t_trans_campaign;
    
    Begin
      Open c_gift_credit_campaign_2008;
        Fetch c_gift_credit_campaign_2008 Bulk Collect Into trans;
      Close c_gift_credit_campaign_2008;
      For i in 1..(trans.count) Loop
        Pipe row(trans(i));
      End Loop;
      Return;
    End;

  -- Householdable entity campaign giving, based on c_ksm_trans_hh_campaign_2008
  Function tbl_gift_credit_hh_campaign
    Return ksm_pkg_gifts_hh.t_trans_household Pipelined As
    -- Declarations
    trans ksm_pkg_gifts_hh.t_trans_household;
    
    Begin
      Open c_gift_credit_hh_campaign_2008;
        Fetch c_gift_credit_hh_campaign_2008 Bulk Collect Into trans;
      Close c_gift_credit_hh_campaign_2008;
      For i in 1..(trans.count) Loop
        Pipe row(trans(i));
      End Loop;
      Return;
    End;

End ksm_pkg_gifts_campaign;
/
