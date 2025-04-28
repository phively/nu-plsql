Create Or Replace Package ksm_pkg_gifts Is

/*************************************************************************
Author  : PBH634
Created : 4/25/2025
Purpose : Base table combining hard and soft credit, opportunity, designation,
  constituent, and organization into a normalized transactions list. One credited donor
  transaction per row.
Dependencies: dw_pkg_base, ksm_pkg_entity (mv_entity), ksm_pkg_designation (mv_designation)

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
-- Gift transactions
Type rec_transaction Is Record (
      credited_donor_id mv_entity.donor_id%type
      , credited_donor_name mv_entity.full_name%type
      , credited_donor_sort_name mv_entity.sort_name%type
      , credited_donor_audit varchar2(255) -- See dw_pkg_base.rec_gift_credit.donor_name_and_id
      , opportunity_donor_id mv_entity.donor_id%type
      , opportunity_donor_name mv_entity.full_name%type
      , opportunity_record_id dm_alumni.dim_opportunity.opportunity_record_id%type
      , anonymous_type dm_alumni.dim_opportunity.anonymous_type%type
      , opp_receipt_number dm_alumni.dim_opportunity.legacy_receipt_number%type
      , opportunity_stage dm_alumni.dim_opportunity.opportunity_stage%type
      , opportunity_record_type dm_alumni.dim_opportunity.opportunity_record_type%type
      , opportunity_type dm_alumni.dim_opportunity.opportunity_type%type
      , source_type stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__source__c%type
      , source_type_detail stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__gift_type_formula__c%type
      , gypm_ind varchar2(1)
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
      , credit_type stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__credit_type__c%type
      , credit_amount stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__credit_amount__c%type
      , hard_credit_amount stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__credit_amount__c%type
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type transactions Is Table Of rec_transaction;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

Function tbl_ksm_transactions
  Return transactions Pipelined;

End ksm_pkg_gifts;
/
Create Or Replace Package Body ksm_pkg_gifts Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

--------------------------------------
-- Kellogg normalized transactions
Cursor c_ksm_transactions Is

    With

    gcred As (
      Select
        gc.*
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
      , opp.opportunity_record_id
      , opp.anonymous_type
      , opp.legacy_receipt_number
        As opp_receipt_number
      , opp.opportunity_stage
      , opp.opportunity_record_type
      , opp.opportunity_type
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
      , kdes.cash_category
      , kdes.full_circle_campaign_priority
      , gcred.credit_date
      , gcred.fiscal_year
      , gcred.credit_type
      , gcred.credit_amount
      , gcred.hard_credit_amount
    From table(dw_pkg_base.tbl_opportunity) opp
    Inner Join gcred
      On gcred.opportunity_salesforce_id = opp.opportunity_salesforce_id
    Inner Join mv_ksm_designation kdes
      On kdes.designation_salesforce_id = gcred.designation_salesforce_id
    Left Join mv_entity mve
      On mve.donor_id = gcred.credited_donor_id
;

/*************************************************************************
Pipelined functions
*************************************************************************/

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
