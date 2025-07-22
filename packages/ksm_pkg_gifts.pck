Create Or Replace Package ksm_pkg_gifts Is

/*************************************************************************
Author  : PBH634
Created : 4/25/2025
Purpose : Base table combining hard and soft credit, opportunity, designation,
  constituent, and organization into a normalized transactions list. One credited donor
  transaction per row.
Dependencies: dw_pkg_base (mv_designation_detail), ksm_pkg_entity (mv_entity),
  ksm_pkg_designation (mv_designation), ksm_pkg_transactions (mv_transactions), ksm_pkg_utility,
  ksm_pkg_prospect (mv_assignment_history)

Suggested naming conventions:
  Pure functions: [function type]_[description]
  Row-by-row retrieval (slow): get_[object type]_[action or description] e.g.
  Table or cursor retrieval (fast): tbl_[object type]_[action or description]
*************************************************************************/

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_gifts';

-- Campaign constants
campaign_kfc_start_fy integer := 2022;
campaign_kfc_end_fy integer := 2029;

/*************************************************************************
Public type declarations
*************************************************************************/

--------------------------------------
-- Discounted gift transactions
Type rec_discount Is Record (
      pledge_or_gift_record_id dm_alumni.dim_designation_detail.pledge_or_gift_record_id%type
      , pledge_or_gift_date dm_alumni.dim_designation_detail.pledge_or_gift_date%type
      , designation_detail_record_id dm_alumni.dim_designation_detail.designation_detail_record_id%type
      , designation_record_id dm_alumni.dim_designation_detail.designation_record_id%type
      , designation_detail_name dm_alumni.dim_designation_detail.designation_detail_name%type
      , designation_amount dm_alumni.dim_designation_detail.designation_amount%type
      , bequest_amount_calc number
      , bequest_flag varchar2(1)
      , countable_amount_bequest dm_alumni.dim_designation_detail.countable_amount_bequest%type
      , total_paid_amount dm_alumni.dim_designation_detail.total_payment_credit_to_date_amount%type
      , overpaid_flag varchar2(1)
);

--------------------------------------
-- Unsplit amounts
Type rec_unsplit Is Record (
      pledge_or_gift_record_id mv_designation_detail.pledge_or_gift_record_id%type
      , unsplit_amount mv_designation_detail.designation_amount%type
);

--------------------------------------
-- Householded donor counts
Type rec_donor_count Is Record (
    tx_id mv_transactions.tx_id%type
    , designation_record_id mv_transactions.designation_record_id%type
    , household_id mv_entity.household_id%type
    , hh_credited_donors integer
    , etl_update_date mv_entity.etl_update_date%type
);

--------------------------------------
-- Source donor ID
Type rec_source_donor Is Record (
  tx_id mv_transactions.tx_id%type
  , legacy_receipt_number mv_transactions.legacy_receipt_number%type
  , source_donor_id mv_transactions.credited_donor_id%type
  , etl_update_date mv_transactions.max_etl_update_date%type
);

--------------------------------------
-- Gift transactions
Type rec_transaction Is Record (
      credited_donor_id mv_entity.donor_id%type
      , household_id mv_entity.household_id%type
      , credited_donor_name mv_entity.full_name%type
      , credited_donor_sort_name mv_entity.sort_name%type
      , credited_donor_audit varchar2(255) -- See dw_pkg_base.rec_gift_credit.donor_name_and_id
      , opportunity_donor_id mv_entity.donor_id%type
      , opportunity_donor_name mv_entity.full_name%type
      , tribute_type varchar2(255)
      , tributees varchar2(1023)
      , tx_id dm_alumni.dim_opportunity.opportunity_record_id%type
      , opportunity_record_id dm_alumni.dim_opportunity.opportunity_record_id%type
      , payment_record_id stg_alumni.ucinn_ascendv2__payment__c.name%type
      , anonymous_type dm_alumni.dim_opportunity.anonymous_type%type
      , legacy_receipt_number dm_alumni.dim_opportunity.legacy_receipt_number%type
      , opportunity_stage dm_alumni.dim_opportunity.opportunity_stage%type
      , opportunity_record_type dm_alumni.dim_opportunity.opportunity_record_type%type
      , opportunity_type dm_alumni.dim_opportunity.opportunity_type%type
      , payment_schedule stg_alumni.opportunity.ap_payment_schedule__c%type
      , source_type stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__source__c%type
      , source_type_detail stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__gift_type_formula__c%type
      , gypm_ind varchar2(1)
      , adjusted_opportunity_ind varchar2(1)
      , hard_and_soft_credit_salesforce_id stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.id%type
      , credit_receipt_number stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__receipt_number__c%type
      , matched_gift_record_id dm_alumni.dim_opportunity.matched_gift_record_id%type
      , pledge_record_id dm_alumni.dim_opportunity.opportunity_record_id%type
      , linked_proposal_record_id dm_alumni.dim_opportunity.linked_proposal_record_id%type
      , historical_pm_user_id mv_proposals.historical_pm_user_id%type
      , historical_pm_name mv_proposals.historical_pm_name%type
      , historical_pm_role mv_proposals.historical_pm_role%type
      , historical_pm_unit mv_proposals.historical_pm_business_unit%type
      , historical_pm_is_active mv_proposals.historical_pm_is_active%type
      , historical_prm_name mv_assignment_history.staff_name%type
      , historical_prm_start_date mv_assignment_history.start_date%type
      , historical_prm_unit mv_assignment_history.assignment_business_unit%type
      , historical_prm_ksm_flag mv_assignment_history.ksm_flag%type
      , historical_lagm_name mv_assignment_history.staff_name%type
      , historical_lagm_start_date mv_assignment_history.start_date%type
      , historical_lagm_unit mv_assignment_history.assignment_business_unit%type
      , historical_lagm_ksm_flag mv_assignment_history.ksm_flag%type
      , designation_record_id mv_ksm_designation.designation_record_id%type
      , designation_status mv_ksm_designation.designation_status%type
      , legacy_allocation_code mv_ksm_designation.legacy_allocation_code%type
      , designation_name mv_ksm_designation.designation_name%type
      , fin_fund_id mv_ksm_designation.fin_fund_id%type
      , fin_department_id mv_ksm_designation.fin_department_id%type
      , fin_project_id mv_ksm_designation.fin_project_id%type
      , fin_activity mv_ksm_designation.fin_activity_id%type
      , ksm_af_flag mv_ksm_designation.ksm_af_flag%type
      , ksm_cru_flag mv_ksm_designation.ksm_cru_flag%type
      , cash_category mv_ksm_designation.cash_category%type
      , full_circle_campaign_priority mv_ksm_designation.full_circle_campaign_priority%type
      , credit_date stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__credit_date_formula__c%type
      , fiscal_year integer
      , entry_date dm_alumni.dim_opportunity.opportunity_entry_date%type
      , credit_type stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__credit_type__c%type
      , credit_amount stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__credit_amount__c%type
      , hard_credit_amount stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__credit_amount__c%type
      , recognition_credit stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__credit_amount__c%type
      , tender_type varchar2(128)
      , min_etl_update_date mv_entity.etl_update_date%type
      , max_etl_update_date mv_entity.etl_update_date%type
      , historical_credit_user_id mv_assignment_history.staff_user_salesforce_id%type
      , historical_credit_name mv_assignment_history.staff_name%type
      , historical_credit_assignment_type mv_assignment_history.assignment_type%type
      , historical_credit_unit mv_assignment_history.assignment_business_unit%type
      , historical_credit_active_flag varchar2(1)
      , hh_credited_donors integer
      , hh_credit number -- not currency, do not round
      , hh_recognition_credit number -- not currency, do not round
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type discounted_transactions Is Table Of rec_discount;
Type unsplit_amounts Is Table Of rec_unsplit;
Type donor_counts Is Table Of rec_donor_count;
Type source_donors Is Table Of rec_source_donor;
Type transactions Is Table Of rec_transaction;

/*************************************************************************
Public function declarations
*************************************************************************/

Function get_numeric_constant(
  const_name In varchar2 -- Name of constant to retrieve
) Return number Deterministic;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

Function tbl_discounted_transactions
  Return discounted_transactions Pipelined;

Function tbl_unsplit_amounts
  Return unsplit_amounts Pipelined;

Function tbl_hh_donor_count
  Return donor_counts Pipelined;

Function tbl_source_donors
  Return source_donors Pipelined;

Function tbl_ksm_transactions
  Return transactions Pipelined;

End ksm_pkg_gifts;
/
Create Or Replace Package Body ksm_pkg_gifts Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

--------------------------------------
-- Discounted bequest amounts by designation

Cursor c_discounted_transactions Is

  Select
    dd.pledge_or_gift_record_id
    , dd.pledge_or_gift_date
    , dd.designation_detail_record_id
    , dd.designation_record_id
    , dd.designation_detail_name
    , dd.designation_amount
    -- Written off bequests should have actual, not countable, amount posted
    , Case
        When dd.pledge_or_gift_status In ('Written Off', 'Paid')
          Then dd.total_paid_amount
        Else dd.countable_amount_bequest
        End
      As bequest_amount_calc
    , dd.bequest_flag
    , dd.countable_amount_bequest
    , dd.total_paid_amount
    , dd.overpaid_flag
  From mv_designation_detail dd
  Where dd.bequest_flag = 'Y'
;

--------------------------------------
-- Unsplit amounts: all KSM dollars per transaction
Cursor c_unsplit_amounts Is

  Select
     dd.pledge_or_gift_record_id
      As pledge_or_gift_record_id
    , sum(dd.designation_amount)
      As unsplit_amount
  From mv_designation_detail dd
  Inner Join mv_ksm_designation des
    On des.designation_record_id = dd.designation_record_id
  Group By dd.pledge_or_gift_record_id
;

--------------------------------------
-- Householded count of donors per designation/payment/opportunity
Cursor c_hh_donor_count Is

Select Distinct
    trans.tx_id
    , trans.designation_record_id
    , mve.household_id
    , count(trans.credited_donor_id)
      As hh_credited_donors
    , max(trans.max_etl_update_date)
      As etl_update_date
  From mv_transactions trans
  Inner Join mv_entity mve
    On mve.donor_id = trans.credited_donor_id
  Inner Join mv_ksm_designation des
    On des.designation_record_id = trans.designation_record_id
  Group By
    trans.tx_id
    , trans.designation_record_id
    , mve.household_id
;

Cursor c_source_donors Is
  
  With
  
  trans As (
    Select
      mvt.credited_donor_id
      , mvt.credited_donor_name
      , mvt.credited_donor_sort_name
      , mvt.tx_id
      , mvt.legacy_receipt_number
      , mvt.gypm_ind
      , mvt.opportunity_record_id
      , mvt.matched_gift_record_id
      , mvt.pledge_record_id
      , mvt.credit_type
      , mvt.max_etl_update_date
    From mv_transactions mvt
    -- Exclude in honor/memory of donors
    Left Join table(ksm_pkg_transactions.tbl_tributes) trib
      On trib.opportunity_salesforce_id = mvt.opportunity_salesforce_id
    Where trib.opportunity_salesforce_id Is Null
  )
  
  Select
    tx_id
    , min(legacy_receipt_number)
      As legacy_receipt_number
    , Case
        -- Matching gift logic pending
        When max(gypm_ind) = 'MatchTBD'
          Then 'MatchTBD'
        Else max(credited_donor_id)
          keep(dense_rank First Order By
            -- 'P'erson before 'O'rg
            mve.person_or_org Desc
            -- Earlier grad year before later grad year
            , deg.first_ksm_year Asc Nulls Last
            -- Donor ID as tiebreak
            , mve.donor_id Asc
          )
        End
      As source_donor_id
    , max(trans.max_etl_update_date)
      As etl_update_date
  From trans
  Inner Join mv_entity mve
    On mve.donor_id = trans.credited_donor_id
  Left Join mv_entity_ksm_degrees deg
    On deg.donor_id = trans.credited_donor_id
  Group By trans.tx_id
;

--------------------------------------
-- Kellogg normalized transactions
Cursor c_ksm_transactions Is

    With
    
    gift_category_exceptions As (
    -- Override cash or campaign categorization for specific opportunities
    -- Use NULL to ignore category or space ' ' to insert NULL for category
      -- Headers
      (
      Select
        NULL As opportunity_record_id
        , NULL As cash_category
        , NULL As full_circle_campaign_priority
      From DUAL
      )
      Union All
      -- Back-end transfers
      Select 'PN2463400', 'KEC', ' ' From DUAL -- NH override
      Union All
      Select 'PN2297936', NULL, ' ' From DUAL -- Complexity Institute
      -- TBD funds (clean up as moved)
      Union All
      Select 'PN2480673', NULL, 'Faculty' From DUAL
      Union All
      Select 'PN2482912', NULL, 'Faculty' From DUAL
      Union All
      Select 'PN2481184', NULL, 'Students' From DUAL
      Union All
      Select 'GN2218698', NULL, 'Students' From DUAL
      Union All
      Select 'PN2484020', NULL, 'Students' From DUAL
      Union All
      Select 'GN2233453', NULL, 'Students' From DUAL
      Union All
      Select 'GN2217992', NULL, 'Students' From DUAL
    )
    
    , tribute As (
      -- In memory/honor of
      Select Distinct
        trib.opportunity_salesforce_id
        , trib.tributee_salesforce_id
        , mv_entity.full_name As tributee_name
        , trib.tributee_name_text
        , trib.tribute_type
      From table(ksm_pkg_transactions.tbl_tributes) trib
      Left Join mv_entity
        On mv_entity.salesforce_id = trib.tributee_salesforce_id
    )
    
    , tribute_concat As (
      Select
        opportunity_salesforce_id
        , Listagg(tribute_type, '; ' || chr(13))
          Within Group (Order By tribute_type, tributee_name_text)
          As tribute_type
        , Listagg(tributee_name || tributee_name_text, '; ' || chr(13))
          Within Group (Order By tribute_type, tributee_name_text)
          As tributees
      From tribute
      Group By opportunity_salesforce_id
    )
    
    -- Historical managers
    , historical_mgrs As (
      Select Distinct
        ah.household_id
        , mve.person_or_org
        , ah.donor_id
        , ah.sort_name
        , ah.start_date
        , ah.end_date
        , ah.assignment_active_calc
        , ah.staff_user_salesforce_id
        , ah.staff_name
        , ah.assignment_code
        , ah.assignment_business_unit
        , ah.ksm_flag
        , mvt.credit_date
        , mvt.tx_id
      From mv_assignment_history ah
      Inner Join mv_entity mve
        On mve.household_id = ah.household_id
      Inner Join mv_transactions mvt
        On mvt.credited_donor_id = mve.donor_id
        And mvt.credit_date Between ah.start_date And nvl(ah.end_date, to_date('99990101', 'yyyymmdd'))
      Where ah.assignment_code In ('PRM', 'LAGM')
    )
    
    , ranked_managers As (
      -- For each transaction, tiebreak person before org, then PRM before LAGM, then whoever started/ended as manager earlier/later
      Select Distinct
        tx_id
        , start_date
        , end_date
        , assignment_active_calc
        , staff_user_salesforce_id
        , staff_name
        , assignment_code
        , assignment_business_unit
        , ksm_flag
        , row_number() Over(Partition By tx_id Order By person_or_org Desc, assignment_code Desc, start_date Asc, end_date Desc, staff_name Asc, staff_user_salesforce_id Asc)
          As rank_credit
        , row_number() Over(Partition By tx_id, assignment_code Order By person_or_org Desc, start_date Asc, end_date Desc, staff_name Asc, staff_user_salesforce_id Asc)
          As rank_prm
        , row_number() Over(Partition By tx_id, assignment_code Order By person_or_org Desc, start_date Asc, end_date Desc, staff_name Asc, staff_user_salesforce_id Asc)
          As rank_lagm
      From historical_mgrs
      Where assignment_code In ('PRM', 'LAGM')
    )
    
    -- Unified transactions
    , trans_data As (
      Select
        trans.credited_donor_id
        , mve.household_id
        , trans.credited_donor_name
        , trans.credited_donor_sort_name
        , trans.credited_donor_audit
        , trans.opportunity_donor_id
        , trans.opportunity_donor_name
        , tribute_concat.tribute_type
        , tribute_concat.tributees
        , trans.tx_id
        , trans.opportunity_record_id
        , trans.payment_record_id
        , trans.anonymous_type
        , trans.legacy_receipt_number
        , trans.opportunity_stage
        , trans.opportunity_record_type
        , trans.opportunity_type
        , trans.payment_schedule
        , trans.source_type
        , trans.source_type_detail
        , trans.gypm_ind
        , trans.adjusted_opportunity_ind
        , trans.hard_and_soft_credit_salesforce_id
        , trans.credit_receipt_number
        , trans.matched_gift_record_id
        , trans.pledge_record_id
        , trans.linked_proposal_record_id
        , prop.historical_pm_user_id
        , prop.historical_pm_name
        , prop.historical_pm_role
        , prop.historical_pm_business_unit
          As historical_pm_unit
        , prop.historical_pm_is_active
        , prms.staff_name
          As historical_prm_name
        , prms.start_date
          As historical_prm_start_date
        , prms.assignment_business_unit
          As historical_prm_unit
        , prms.ksm_flag
          As historical_prm_ksm_flag
        , lagms.staff_name
          As historical_lagm_name
        , lagms.start_date
          As historical_lagm_start_date
        , lagms.assignment_business_unit
          As historical_lagm_unit
        , lagms.ksm_flag
          As historical_lagm_ksm_flag
        , trans.designation_record_id
        , trans.designation_status
        , trans.legacy_allocation_code
        , trans.designation_name
        , trans.fin_fund_id
        , trans.fin_department_id
        , trans.fin_project_id
        , trans.fin_activity_id
        , kdes.ksm_af_flag
        , kdes.ksm_cru_flag
        , Case
            -- Cash category exceptions
            When gexcept.cash_category Is Not Null
              Then gexcept.cash_category
            -- Gift-In-Kind
            When trans.tender_type Like '%Gift_in_Kind%'
              Then 'Gift In Kind'
            When trans.tender_type Like '%Gift_in_Kind%'
              Then 'Gift In Kind'
            Else kdes.cash_category
            End
          As cash_category
        , Case
            -- KFC campaign exceptions
            When gexcept.opportunity_record_id Is Not Null
              Then Case
                -- Null means skip override
                When gexcept.full_circle_campaign_priority Is Null
                  Then kdes.full_circle_campaign_priority
                -- Space means insert null
                When trim(gexcept.full_circle_campaign_priority) Is Null
                  Then NULL
                Else gexcept.full_circle_campaign_priority
                End
            -- Outside of campaign counting period is Null
            When trans.fiscal_year Not Between
              ksm_pkg_gifts.get_numeric_constant('ksm_pkg_gifts.campaign_kfc_start_fy')
              And ksm_pkg_gifts.get_numeric_constant('ksm_pkg_gifts.campaign_kfc_end_fy')
              Then NULL
            -- Fallback
            Else kdes.full_circle_campaign_priority
            End
          As full_circle_campaign_priority
        , trans.credit_date
        , trans.fiscal_year
        , trans.entry_date
        , trans.credit_type
        -- Credit calculations
        , Case
            -- Bequests always show discounted amount
            When bequests.bequest_flag = 'Y'
              Then bequests.bequest_amount_calc
            Else trans.credit_amount
            End
          As credit_amount
        -- Hard credit
        , Case
            When trans.credit_type = 'Hard'
              -- Keep same logic as soft credit, above
              Then Case
                -- Bequests always show discounted amount
                When bequests.bequest_flag = 'Y'
                  Then bequests.bequest_amount_calc
                Else trans.hard_credit_amount
                End
              Else 0
            End
          As hard_credit_amount
        , Case
          -- Overpaid pledges use the paid amount
            When overpaid.overpaid_flag = 'Y'
              Then overpaid.total_paid_amount
            Else trans.credit_amount
            End
          As recognition_credit
        , trans.tender_type
        , least(trans.max_etl_update_date, kdes.etl_update_date)
          As min_etl_update_date
        , greatest(trans.max_etl_update_date, kdes.etl_update_date)
          As max_etl_update_date
      From mv_transactions trans
      Inner Join mv_entity mve
        On mve.donor_id = trans.credited_donor_id
      Inner Join mv_ksm_designation kdes
        On kdes.designation_record_id = trans.designation_record_id
      -- Discounted bequests
      Left Join table(ksm_pkg_gifts.tbl_discounted_transactions) bequests
        -- Pledge + designation should be a unique identifier
        On bequests.bequest_flag = 'Y'
        And bequests.pledge_or_gift_record_id = trans.opportunity_record_id
        And bequests.designation_record_id = trans.designation_record_id
        -- Override only pledge amount, not payments
        And trans.gypm_ind = 'P'
      -- Overpaid pledges
      Left Join mv_designation_detail overpaid
        On trans.source_type_detail = 'Pledge'
        And overpaid.overpaid_flag = 'Y'
        And overpaid.pledge_or_gift_record_id = trans.opportunity_record_id
        And overpaid.designation_record_id = trans.designation_record_id
      -- Cash or campaign category exceptions
      Left Join gift_category_exceptions gexcept
        On gexcept.opportunity_record_id = trans.opportunity_record_id
      -- In memory/honor of
      Left Join tribute_concat
        On tribute_concat.opportunity_salesforce_id = trans.opportunity_salesforce_id
      -- Proposal manager
      Left Join mv_proposals prop
        On prop.proposal_record_id = trans.linked_proposal_record_id
      -- Historical PRM
      Left Join ranked_managers prms
        On prms.tx_id = trans.tx_id
        And prms.rank_prm = 1
        And prms.assignment_code = 'PRM'
      -- Historical LAGM
      Left Join ranked_managers lagms
        On lagms.tx_id = trans.tx_id
        And lagms.rank_lagm = 1
        And lagms.assignment_code = 'LAGM'
    )
    
    -- Final householded credit
    Select
      t.*
        -- Historical credit info
      , Case
          When t.historical_pm_user_id Is Not Null
            Then t.historical_pm_user_id 
          Else mgr_credit.staff_user_salesforce_id
          End
        As historical_credit_user_id
      , Case
          When t.historical_pm_name Is Not Null
            Then t.historical_pm_name 
          Else mgr_credit.staff_name
          End
        As historical_credit_name
      , Case
          When t.historical_pm_role Is Not Null
            Then t.historical_pm_role
          Else mgr_credit.assignment_code
          End
        As historical_credit_assignment_type
      , Case
          When t.historical_pm_unit Is Not Null
            Then t.historical_pm_unit 
          Else mgr_credit.assignment_business_unit
          End
        As historical_credit_unit
      , Case
          When t.historical_pm_is_active = 'true'
            Then 'Y'
          Else mgr_credit.assignment_active_calc
          End
        As historical_credit_active_flag
      -- Household credit is evenly split between household members per transaction and designation
      , hhdc.hh_credited_donors
      , t.credit_amount / hhdc.hh_credited_donors
        As hh_credit 
      , t.recognition_credit / hhdc.hh_credited_donors
        As hh_recognition_credit
    From trans_data t
    -- Householded counts, for hh_credit
    Inner Join table(ksm_pkg_gifts.tbl_hh_donor_count) hhdc
      On hhdc.household_id = t.household_id
      And hhdc.tx_id = t.tx_id
      And hhdc.designation_record_id = t.designation_record_id
    -- Historical credit
    Left Join ranked_managers mgr_credit
      On mgr_credit.tx_id = t.tx_id
      And mgr_credit.rank_credit = 1
;

/*************************************************************************
Functions
*************************************************************************/

--------------------------------------
-- Retrieve one of the named numeric constants from the package
-- Requires a quoted constant name
Function get_numeric_constant(const_name In varchar2)
  Return number Deterministic Is
  -- Declarations
  val number;
  var varchar2(255);
  
  Begin
    -- If const_name doesn't include ksm_pkg, prepend it
    If substr(lower(const_name), 1, length(pkg_name)) <> pkg_name
      Then var := pkg_name || '.' || const_name;
    Else
      var := const_name;
    End If;
    Execute Immediate
      'Begin :val := ' || var || '; End;'
      Using Out val;
      Return val;
  End;

/*************************************************************************
Pipelined functions
*************************************************************************/

--------------------------------------
Function tbl_discounted_transactions
  Return discounted_transactions Pipelined As
  -- Declarations
  dt discounted_transactions;
  
  Begin
    Open c_discounted_transactions;
      Fetch c_discounted_transactions Bulk Collect Into dt;
    Close c_discounted_transactions;
    For i in 1..(dt.count) Loop
      Pipe row(dt(i));
    End Loop;
    Return;
  End;

--------------------------------------
Function tbl_unsplit_amounts
  Return unsplit_amounts Pipelined As
  -- Declarations
  ua unsplit_amounts;
  
  Begin
    Open c_unsplit_amounts;
      Fetch c_unsplit_amounts Bulk Collect Into ua;
    Close c_unsplit_amounts;
    For i in 1..(ua.count) Loop
      Pipe row(ua(i));
    End Loop;
    Return;
  End;

--------------------------------------
Function tbl_hh_donor_count
  Return donor_counts Pipelined As
  -- Declarations
  dc donor_counts;
  
  Begin
    Open c_hh_donor_count;
      Fetch c_hh_donor_count Bulk Collect Into dc;
    Close c_hh_donor_count;
    For i in 1..(dc.count) Loop
      Pipe row(dc(i));
    End Loop;
    Return;
  End;

--------------------------------------
-- Source donor logic
Function tbl_source_donors
  Return source_donors Pipelined As
  -- Declarations
  srcd source_donors;

  Begin
    Open c_source_donors;
      Fetch c_source_donors Bulk Collect Into srcd;
    Close c_source_donors;
    For i in 1..(srcd.count) Loop
      Pipe row(srcd(i));
    End Loop;
    Return;
  End;

--------------------------------------
-- Individual entity giving, all units, based on c_ksm_transactions
Function tbl_ksm_transactions
  Return transactions Pipelined As
  -- Declarations
  trn transactions;

  Begin
    Open c_ksm_transactions;
      Fetch c_ksm_transactions Bulk Collect Into trn;
    Close c_ksm_transactions;
    For i in 1..(trn.count) Loop
      Pipe row(trn(i));
    End Loop;
    Return;
  End;

End ksm_pkg_gifts;
/
