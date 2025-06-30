Create Or Replace Package ksm_pkg_transactions Is

/*************************************************************************
Author  : PBH634
Created : 5-20-2025
Purpose : Consolidated gift transactions: credit + opportunity + payment, for
  ease of downstream processing.
Dependencies: dw_pkg_base

Suggested naming conventions:
  Pure functions: [function type]_[description]
  Row-by-row retrieval (slow): get_[object type]_[action or description] e.g.
  Table or cursor retrieval (fast): tbl_[object type]_[action or description]
*************************************************************************/

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_transactions';

/*************************************************************************
Public type declarations
*************************************************************************/

--------------------------------------
Type rec_transaction Is Record (
  credited_donor_id mv_entity.donor_id%type
  , credited_donor_name mv_entity.full_name%type
  , credited_donor_sort_name mv_entity.sort_name%type
  , credited_donor_audit varchar2(255) -- See dw_pkg_base.rec_gift_credit.donor_name_and_id
  , opportunity_donor_id mv_entity.donor_id%type
  , opportunity_donor_name mv_entity.full_name%type
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
  , designation_record_id dm_alumni.dim_designation.designation_record_id%type 
  , designation_status dm_alumni.dim_designation.designation_status%type 
  , legacy_allocation_code dm_alumni.dim_designation.legacy_allocation_code%type 
  , designation_name dm_alumni.dim_designation.designation_name%type
  , fin_fund_id dm_alumni.dim_designation.fin_fund%type
  , fin_department_id dm_alumni.dim_designation.designation_fin_department_id%type
  , fin_project_id dm_alumni.dim_designation.fin_project%type
  , fin_activity_id dm_alumni.dim_designation.designation_activity%type
  , credit_date stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__credit_date_formula__c%type
  , fiscal_year integer
  , entry_date dm_alumni.dim_opportunity.opportunity_entry_date%type
  , credit_type stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__credit_type__c%type
  , credit_amount stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__credit_amount__c%type
  , hard_credit_amount stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__credit_amount__c%type
  , tender_type varchar2(128)
  , min_etl_update_date mv_entity.etl_update_date%type
  , max_etl_update_date mv_entity.etl_update_date%type
);

--------------------------------------
Type rec_tribute Is Record (   
  opportunity_salesforce_id stg_alumni.ucinn_ascendv2__tribute__c.ucinn_ascendv2__opportunity__c%type
  , tributee_salesforce_id stg_alumni.ucinn_ascendv2__tribute__c.ucinn_ascendv2__contact__c%type
  , tributee_name_text stg_alumni.ucinn_ascendv2__tribute__c.ucinn_ascendv2__tributee__c%type
  , tribute_type stg_alumni.ucinn_ascendv2__tribute__c.ucinn_ascendv2__tribute_type__c%type
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type transactions Is Table Of rec_transaction;
Type tributes Is Table Of rec_tribute;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

Function tbl_transactions
  Return transactions Pipelined;

Function tbl_tributes
  Return tributes Pipelined;

/*********************** About pipelined functions ***********************
Q: What is a pipelined function?

A: Pipelined functions are used to return the results of a cursor row by row.
This is an efficient way to re-use a cursor between multiple programs. Pipelined
tables can be queried in SQL exactly like a table when embedded in the table()
function. My experience has been that thanks to the magic of the Oracle compiler,
joining on a table() function scales hugely better than running a function once
on each element of a returned column. Note that the exact columns returned need
to be specified as a public type, which I did in the type and table declarations
above, or the pipelined function can't be run in pure SQL. Alternately, the
pipelined function could return a generic table, but the columns would still need
to be individually named.
*************************************************************************/

/*************************************************************************
End of package
*************************************************************************/

End ksm_pkg_transactions;
/
Create Or Replace Package Body ksm_pkg_transactions Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

--------------------------------------
Cursor c_transactions Is

  With
  
  mini_entity As (
    Select *
    From table(dw_pkg_base.tbl_mini_entity)
  )
  
  , gcred As (
    Select
      gc.*
      -- Fill in or extract Donor ID
      , Case
          When gc.donor_salesforce_id Is Not Null
            Then me.donor_id
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
    Left Join mini_entity me
      On me.salesforce_id = gc.donor_salesforce_id
  )
  
  Select
    gcred.credited_donor_id
    , me.full_name
      As credited_donor_name
    , me.sort_name
      As credited_donor_sort_name
    , gcred.donor_name_and_id
      As credited_donor_audit
    , opp.opportunity_donor_id
    , opp.opportunity_donor_name
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
    , des.designation_record_id
    , des.designation_status
    , des.legacy_allocation_code
    , des.designation_name
    , des.fin_fund_id
    , des.fin_department_id
    , des.fin_project_id
    , des.fin_activity_id
    -- Credit date is from opportunity object for matching gift payments
    , Case
        When gcred.source_type_detail = 'Matching Gift Payment'
          Then opp.credit_date
        Else gcred.credit_date
        End
      As credit_date
    , Case
        When gcred.source_type_detail = 'Matching Gift Payment'
          Then ksm_pkg_utility.to_number2(opp.fiscal_year)
        Else ksm_pkg_utility.to_number2(gcred.fiscal_year)
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
    , gcred.credit_amount
    , gcred.hard_credit_amount
    , Case
        When pay.payment_record_id Is Not Null
          Then pay.tender_type
        Else opp.tender_type
        End
      As tender_type
    , least(opp.etl_update_date, gcred.etl_update_date, pay.etl_update_date)
      As min_etl_update_date
    , greatest(opp.etl_update_date, gcred.etl_update_date, pay.etl_update_date)
      As max_etl_update_date
  From gcred
  Inner Join table(dw_pkg_base.tbl_opportunity) opp
    On opp.opportunity_salesforce_id = gcred.opportunity_salesforce_id
  Inner Join table(dw_pkg_base.tbl_designation) des
    On des.designation_salesforce_id = gcred.designation_salesforce_id
  Inner Join mini_entity me
    On me.donor_id = gcred.credited_donor_id
  Left Join table(dw_pkg_base.tbl_payment) pay
    On pay.payment_salesforce_id = gcred.payment_salesforce_id
;

--------------------------------------
Cursor c_tributes Is
  
  -- In memory/honor of
  Select Distinct
    trib.ucinn_ascendv2__opportunity__c As opportunity_salesforce_id
    , trib.ucinn_ascendv2__contact__c As tributee_salesforce_id
    , trib.ucinn_ascendv2__tributee__c As tributee_name_text
    , trib.ucinn_ascendv2__tribute_type__c As tribute_type
  From stg_alumni.ucinn_ascendv2__tribute__c trib
;

/*************************************************************************
Pipelined functions
*************************************************************************/

--------------------------------------
Function tbl_transactions
  Return transactions Pipelined As
  -- Declarations
  trn transactions;

  Begin
    Open c_transactions;
      Fetch c_transactions Bulk Collect Into trn;
    Close c_transactions;
    For i in 1..(trn.count) Loop
      Pipe row(trn(i));
    End Loop;
    Return;
  End;

--------------------------------------
Function tbl_tributes
  Return tributes Pipelined As
  -- Declarations
  trb tributes;

  Begin
    Open c_tributes;
      Fetch c_tributes Bulk Collect Into trb;
    Close c_tributes;
    For i in 1..(trb.count) Loop
      Pipe row(trb(i));
    End Loop;
    Return;
  End;

End ksm_pkg_transactions;
/
