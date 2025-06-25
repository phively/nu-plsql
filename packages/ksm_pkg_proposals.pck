Create Or Replace Package ksm_pkg_proposals Is

/*************************************************************************
Author  : PBH634
Created : 6/23/2025
Purpose : Consolidated proposals: proposal + opportunity + prospect info
Dependencies: dw_pkg_base, ksm_pkg_calendar

Suggested naming conventions:
  Pure functions: [function type]_[description]
  Row-by-row retrieval (slow): get_[object type]_[action or description] e.g.
  Table or cursor retrieval (fast): tbl_[object type]_[action or description]
*************************************************************************/

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_proposals';

/*************************************************************************
Public type declarations
*************************************************************************/

Type rec_proposal Is Record (
    opportunity_salesforce_id dm_alumni.dim_proposal_opportunity.opportunity_salesforce_id%type
    , proposal_record_id dm_alumni.dim_proposal_opportunity.proposal_record_id%type
    , proposal_legacy_id dm_alumni.dim_proposal_opportunity.proposal_legacy_id%type
    , proposal_strategy_record_id dm_alumni.dim_proposal_opportunity.proposal_strategy_record_id%type
    , household_id dm_alumni.dim_constituent.constituent_household_account_salesforce_id%type
    , household_primary dm_alumni.dim_constituent.household_primary_constituent_indicator%type
    , donor_id dm_alumni.fact_proposal_opportunity.constituent_donor_id%type
    , full_name dm_alumni.dim_constituent.full_name%type
    , sort_name dm_alumni.dim_constituent.full_name%type
    , institutional_suffix dm_alumni.dim_constituent.institutional_suffix%type
    , is_deceased_indicator dm_alumni.dim_constituent.is_deceased_indicator%type
    , person_or_org varchar2(1)
    , primary_record_type dm_alumni.dim_constituent.primary_constituent_type%type
    , proposal_active_indicator dm_alumni.dim_proposal_opportunity.proposal_active_indicator%type
    , proposal_stage dm_alumni.dim_proposal_opportunity.proposal_stage%type
    , proposal_type dm_alumni.dim_proposal_opportunity.proposal_type%type
    , proposal_name dm_alumni.dim_proposal_opportunity.proposal_name%type
    , proposal_probability dm_alumni.dim_proposal_opportunity.proposal_probability%type
    , proposal_amount dm_alumni.dim_proposal_opportunity.proposal_amount%type
    , proposal_submitted_amount dm_alumni.dim_proposal_opportunity.proposal_submitted_amount%type
    , proposal_anticipated_amount dm_alumni.dim_proposal_opportunity.proposal_anticipated_amount%type
    , proposal_funded_amount dm_alumni.dim_proposal_opportunity.proposal_funded_amount%type
    , proposal_created_date dm_alumni.dim_proposal_opportunity.proposal_created_date%type
    , proposal_submitted_date dm_alumni.dim_proposal_opportunity.proposal_submitted_date%type
    , proposal_close_date dm_alumni.dim_proposal_opportunity.proposal_close_date%type
    , proposal_close_fy integer
    , proposal_payment_schedule dm_alumni.dim_proposal_opportunity.proposal_payment_schedule%type
    , proposal_designation_units dm_alumni.dim_proposal_opportunity.proposal_designation_work_plan_units%type
    , active_proposal_manager_salesforce_id dm_alumni.dim_proposal_opportunity.active_proposal_manager_salesforce_id%type
    , active_proposal_manager_name dm_alumni.dim_proposal_opportunity.active_proposal_manager_name%type
    , active_proposal_manager_unit dm_alumni.dim_proposal_opportunity.active_proposal_manager_business_unit%type
    , historical_pm_user_id stg_alumni.opportunityteammember.id%type
    , historical_pm_name stg_alumni.opportunityteammember.name%type
    , historical_pm_role stg_alumni.opportunityteammember.teammemberrole%type
    , historical_pm_business_unit stg_alumni.opportunityteammember.ap_business_unit__c%type
    , historical_pm_is_active stg_alumni.user_tbl.isactive%type
    , etl_update_date dm_alumni.dim_proposal_opportunity.etl_update_date%type
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type proposals Is Table Of rec_proposal;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

Function tbl_proposals
  Return proposals Pipelined;

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

End ksm_pkg_proposals;
/
Create Or Replace Package Body ksm_pkg_proposals Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

Cursor c_proposals Is

  Select
    prop.opportunity_salesforce_id
    , prop.proposal_record_id
    , prop.proposal_legacy_id
    , prop.proposal_strategy_record_id
    , me.household_id
    , me.household_primary
    , prop.donor_id
    , me.full_name
    , me.sort_name
    , me.institutional_suffix
    , me.is_deceased_indicator
    , me.person_or_org
    , me.primary_record_type
    , prop.proposal_active_indicator
    , prop.proposal_stage
    , prop.proposal_type
    , prop.proposal_name
    , prop.proposal_probability
    , prop.proposal_amount
    , prop.proposal_submitted_amount
    , prop.proposal_anticipated_amount
    , prop.proposal_funded_amount
    , prop.proposal_created_date
    , prop.proposal_submitted_date
    , prop.proposal_close_date
    , ksm_pkg_calendar.get_fiscal_year(prop.proposal_close_date)
      As proposal_close_fy
    , prop.proposal_payment_schedule
    , prop.proposal_designation_units
    , prop.active_proposal_manager_salesforce_id
    , prop.active_proposal_manager_name
    , prop.active_proposal_manager_unit
    , prop.historical_pm_user_id
    , prop.historical_pm_name
    , prop.historical_pm_role
    , prop.historical_pm_business_unit
    , prop.historical_pm_is_active
    , prop.etl_update_date
  From table(dw_pkg_base.tbl_proposals) prop
  Left Join table(dw_pkg_base.tbl_mini_entity) me
    On me.donor_id = prop.donor_id
;

/*************************************************************************
Pipelined functions
*************************************************************************/

Function tbl_proposals
  Return proposals Pipelined As
    -- Declarations
    prp proposals;

  Begin
    Open c_proposals;
      Fetch c_proposals Bulk Collect Into prp;
    Close c_proposals;
    For i in 1..(prp.count) Loop
      Pipe row(prp(i));
    End Loop;
    Return;
  End;

End ksm_pkg_proposals;
/
