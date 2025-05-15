Create Or Replace Package ksm_pkg_gifts Is

/*************************************************************************
Author  : PBH634
Created : 4/25/2025
Purpose : Base table combining hard and soft credit, opportunity, designation,
  constituent, and organization into a normalized transactions list. One credited donor
  transaction per row.
Dependencies: dw_pkg_base (mv_designation_detail), ksm_pkg_entity (mv_entity),
  ksm_pkg_designation (mv_designation)

Suggested naming conventions:
  Pure functions: [function type]_[description]
  Row-by-row retrieval (slow): get_[object type]_[action or description] e.g.
  Table or cursor retrieval (fast): tbl_[object type]_[action or description]
*************************************************************************/

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_gifts';

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
-- Gift transactions
Type rec_transaction Is Record (
      credited_donor_id mv_entity.donor_id%type
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
      , designation_record_id mv_ksm_designation.designation_record_id%type
      , designation_status mv_ksm_designation.designation_status%type
      , legacy_allocation_code mv_ksm_designation.legacy_allocation_code%type
      , designation_name mv_ksm_designation.designation_name%type
      , ksm_af_flag mv_ksm_designation.ksm_af_flag%type
      , ksm_cru_flag mv_ksm_designation.ksm_cru_flag%type
      , cash_category mv_ksm_designation.cash_category%type
      , full_circle_campaign_priority mv_ksm_designation.full_circle_campaign_priority%type
      , credit_date stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__credit_date_formula__c%type
      , fiscal_year stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.nu_fiscal_year__c%type
      , entry_date dm_alumni.dim_opportunity.opportunity_entry_date%type
      , credit_type stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__credit_type__c%type
      , credit_amount stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__credit_amount__c%type
      , hard_credit_amount stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__credit_amount__c%type
      , recognition_credit stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__credit_amount__c%type
      , tender_type varchar2(128)
      , min_etl_update_date mv_entity.etl_update_date%type
      , max_etl_update_date mv_entity.etl_update_date%type
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type discounted_transactions Is Table Of rec_discount;
Type transactions Is Table Of rec_transaction;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

Function tbl_discounted_transactions
  Return discounted_transactions Pipelined;

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
-- Kellogg normalized transactions
Cursor c_ksm_transactions Is

    With
    
    gift_cash_exceptions As (
    -- Override cash categorization for specific opportunities
      -- Headers
      (
      Select
        NULL As opportunity_record_id
        , NULL As cash_category
      From DUAL
      ) Union All (
      Select 'PN2463400', 'KEC' From DUAL -- NH override
      )
    )

    , tribute As (
      -- In memory/honor of
      Select Distinct
        trib.ucinn_ascendv2__opportunity__c As opportunity_salesforce_id
        , trib.ucinn_ascendv2__contact__c As tributee_salesforce_id
        , mv_entity.full_name As tributee_name
        , trib.ucinn_ascendv2__tributee__c As tributee_name_text
        , trib.ucinn_ascendv2__tribute_type__c As tribute_type
      From stg_alumni.ucinn_ascendv2__tribute__c trib
      Left Join mv_entity
        On mv_entity.salesforce_id = trib.ucinn_ascendv2__contact__c
    )
    
    , tribute_concat As (
      Select
        tribute.opportunity_salesforce_id
        , Listagg(tribute_type, '; ' || chr(13))
          Within Group (Order By tribute_type, tributee_name_text)
          As tribute_type
        , Listagg(tributee_name || tributee_name_text, '; ' || chr(13))
          Within Group (Order By tribute_type, tributee_name_text)
          As tributees
      From tribute
      Group By opportunity_salesforce_id
    )

    , gcred As (
      Select
        gc.*
        , tribute_concat.tribute_type
        , tribute_concat.tributees
        -- Fill in or extract Donor ID
        , Case
            When gc.donor_salesforce_id Is Not Null
              Then mv_entity.donor_id
            Else
              regexp_substr(
                -- Take last 10 characters of concatenated name/id field
                substr(donor_name_and_id, -10)
                -- Return consecutive digits
                , '[0-9]+'
              )
            End
          As credited_donor_id
      From table(dw_pkg_base.tbl_gift_credit) gc
      Left Join mv_entity
        On mv_entity.salesforce_id = gc.donor_salesforce_id
      Left Join tribute_concat
        On tribute_concat.opportunity_salesforce_id = gc.opportunity_salesforce_id
    )
    
    Select
      gcred.credited_donor_id
      , mve.full_name
        As credited_donor_name
      , mve.sort_name
        As credited_donor_sort_name
      , gcred.donor_name_and_id
        As credited_donor_audit
      , opp.opportunity_donor_id
      , opp.opportunity_donor_name
      , gcred.tribute_type
      , gcred.tributees
      , Case
          When pay.payment_record_id Is Not Null
            Then pay.payment_record_id
          Else opp.opportunity_record_id
          End
        As tx_id
      , opp.opportunity_record_id
      , pay.payment_record_id
      , Case
          When pay.payment_record_id Is Not Null
            Then pay.anonymous_type
          Else opp.anonymous_type
          End
        As anonymous_type
      , Case
          When pay.payment_record_id Is Not Null
            Then pay.legacy_receipt_number
          Else opp.legacy_receipt_number
          End
        As legacy_receipt_number
      , opp.opportunity_stage
      , opp.opportunity_record_type
      , opp.opportunity_type
      , opp.payment_schedule
      , gcred.source_type
      , gcred.source_type_detail
      -- gypm_ind logic deliberately leaves some sources as NULL
      -- Business purpose is to distinguish between GYM cash and GPM NGC
      , Case
          When gcred.source_type_detail = 'Outright Gift' Then 'G'
          When gcred.source_type_detail = 'Matching Gift Payment' Then 'M'
          When gcred.source_type_detail = 'Pledge' Then 'P'
          When gcred.source_type_detail Like '%Payment%' Then 'Y'
          End
        As gypm_ind
      -- A at end of opportunity/payment number implies adjustment
      , Case
          When opp.opportunity_closed_stage = 'Adjusted' Then 'Y'
          End
        As adjusted_opportunity_ind
      , gcred.hard_and_soft_credit_salesforce_id
      , gcred.receipt_number
        As credit_receipt_number
      , opp.matched_gift_record_id
      , Case
          When gcred.source_type = 'Pledge'
            Then opp.opportunity_record_id
          End
        As pledge_record_id
      , opp.linked_proposal_record_id
      , kdes.designation_record_id
      , kdes.designation_status
      , kdes.legacy_allocation_code
      , kdes.designation_name
      , kdes.ksm_af_flag
      , kdes.ksm_cru_flag
      , Case
          -- Cash category exceptions
          When gce.cash_category Is Not Null
            Then gce.cash_category
          -- Gift-In-Kind
          When pay.tender_type Like '%Gift_in_Kind%'
            Then 'Gift In Kind'
          When opp.tender_type Like '%Gift_in_Kind%'
            Then 'Gift In Kind'
          Else kdes.cash_category
          End
        As cash_category
      , kdes.full_circle_campaign_priority
      -- Credit date is from opportunity object for matching gift payments
      , Case
          When gcred.source_type_detail = 'Matching Gift Payment'
            Then opp.credit_date
          Else gcred.credit_date
          End
        As credit_date
      , Case
          When gcred.source_type_detail = 'Matching Gift Payment'
            Then opp.fiscal_year
          Else gcred.fiscal_year
          End
        As fiscal_year
      -- For entry date: needs to check processed date for pledge payments
      ,  Case
            When gcred.source_type_detail = 'Matching Gift Payment'
              Then opp.entry_date
            When gcred.source_type_detail Like '%Payment%'
              Then pay.entry_date
            Else opp.entry_date
            End
          As entry_date
      , gcred.credit_type
      -- Credit calculations
      , Case
          -- Bequests always show discounted amount
          When bequests.bequest_flag = 'Y'
            Then bequests.bequest_amount_calc
          Else gcred.credit_amount
          End
        As credit_amount
      -- Hard credit
      , Case
          When gcred.credit_type = 'Hard'
            -- Keep same logic as soft credit, above
            Then Case
              -- Bequests always show discounted amount
              When bequests.bequest_flag = 'Y'
                Then bequests.bequest_amount_calc
              Else gcred.hard_credit_amount
              End
            Else 0
          End
        As hard_credit_amount
      , Case
        -- Overpaid pledges use the paid amount
          When overpaid.overpaid_flag = 'Y'
            Then overpaid.total_paid_amount
          Else gcred.credit_amount
          End
        As recognition_credit
      , Case
          When pay.payment_record_id Is Not Null
            Then pay.tender_type
          Else opp.tender_type
          End
        As tender_type
      , least(opp.etl_update_date, gcred.etl_update_date, kdes.etl_update_date, mve.etl_update_date)
        As min_etl_update_date
      , greatest(opp.etl_update_date, gcred.etl_update_date, kdes.etl_update_date, mve.etl_update_date)
        As max_etl_update_date
    From gcred
    Inner Join table(dw_pkg_base.tbl_opportunity) opp
      On opp.opportunity_salesforce_id = gcred.opportunity_salesforce_id
    Inner Join mv_ksm_designation kdes
      On kdes.designation_salesforce_id = gcred.designation_salesforce_id
    Left Join mv_entity mve
      On mve.donor_id = gcred.credited_donor_id
    Left Join table(dw_pkg_base.tbl_payment) pay
      On pay.payment_salesforce_id = gcred.payment_salesforce_id
    -- Discounted bequests
    Left Join table(tbl_discounted_transactions) bequests
      -- Pledge + designation should be a unique identifier
      On bequests.bequest_flag = 'Y'
      And bequests.pledge_or_gift_record_id = opp.opportunity_record_id
      And bequests.designation_record_id = gcred.designation_record_id
    -- Overpaid pledges
    Left Join mv_designation_detail overpaid
      On gcred.source_type_detail = 'Pledge'
      And overpaid.overpaid_flag = 'Y'
      And overpaid.pledge_or_gift_record_id = opp.opportunity_record_id
      And overpaid.designation_record_id = gcred.designation_record_id
    -- Cash category exceptions
    Left Join gift_cash_exceptions gce
      On gce.opportunity_record_id = opp.opportunity_record_id
;

/*************************************************************************
Pipelined functions
*************************************************************************/

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
