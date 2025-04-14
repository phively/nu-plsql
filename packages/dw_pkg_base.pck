Create Or Replace Package dw_pkg_base Is

/*************************************************************************
Author  : PBH634
Created : 4/9/2025
Purpose : Zero dependency tables constructed directly from SF or DW objects.
  Should run very quickly.
Dependencies: none

Suggested naming conventions:
  Pure functions: [function type]_[description]
  Row-by-row retrieval (slow): get_[object type]_[action or description] e.g.
  Table or cursor retrieval (fast): tbl_[object type]_[action or description]
*************************************************************************/

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'dw_pkg_base';

/*************************************************************************
Public type declarations
*************************************************************************/

--------------------------------------
Type rec_constituent Is Record (
  salesforce_id dm_alumni.dim_constituent.constituent_salesforce_id%type
  , household_id dm_alumni.dim_constituent.constituent_household_account_salesforce_id%type
  , household_primary dm_alumni.dim_constituent.household_primary_constituent_indicator%type
  , donor_id dm_alumni.dim_constituent.constituent_donor_id%type
  , full_name dm_alumni.dim_constituent.full_name%type
  , sort_name dm_alumni.dim_constituent.full_name%type
  , is_deceased_indicator dm_alumni.dim_constituent.is_deceased_indicator%type
  , primary_constituent_type dm_alumni.dim_constituent.primary_constituent_type%type
  , institutional_suffix dm_alumni.dim_constituent.institutional_suffix%type
  , spouse_donor_id dm_alumni.dim_constituent.spouse_constituent_donor_id%type
  , spouse_name dm_alumni.dim_constituent.spouse_name%type
  , spouse_instituitional_suffix dm_alumni.dim_constituent.spouse_instituitional_suffix%type
  , preferred_address_city dm_alumni.dim_constituent.preferred_address_city%type
  , preferred_address_state dm_alumni.dim_constituent.preferred_address_state%type
  , preferred_address_country_name dm_alumni.dim_constituent.preferred_address_country_name%type
  , etl_update_date dm_alumni.dim_constituent.etl_update_date%type
);

--------------------------------------
Type rec_organization Is Record (
  salesforce_id dm_alumni.dim_organization.organization_salesforce_id%type
  , ult_parent_id dm_alumni.dim_organization.organization_ultimate_parent_donor_id%type
  , donor_id dm_alumni.dim_organization.organization_donor_id%type
  , org_primary dm_alumni.dim_constituent.household_primary_constituent_indicator%type
  , organization_name dm_alumni.dim_organization.organization_name%type
  , sort_name dm_alumni.dim_organization.organization_name%type
  , organization_inactive_indicator dm_alumni.dim_organization.organization_inactive_indicator%type
  , organization_type dm_alumni.dim_organization.organization_type%type
  , org_ult_parent_donor_id dm_alumni.dim_organization.organization_ultimate_parent_donor_id%type
  , org_ult_parent_name dm_alumni.dim_organization.organization_ultimate_parent_name%type
  , preferred_address_city dm_alumni.dim_organization.preferred_address_city%type
  , preferred_address_state dm_alumni.dim_organization.preferred_address_state%type
  , preferred_address_country_name dm_alumni.dim_organization.preferred_address_country_name%type
  , etl_update_date dm_alumni.dim_organization.etl_update_date%type
);

--------------------------------------
Type rec_degrees Is Record (
  placeholder varchar2(1)
);

--------------------------------------
Type rec_designation Is Record (
      designation_record_id dm_alumni.dim_designation.designation_record_id%type
    , designation_name dm_alumni.dim_designation.designation_name%type
    , designation_status dm_alumni.dim_designation.designation_status%type
    , legacy_allocation_code dm_alumni.dim_designation.legacy_allocation_code%type
    , fin_fund dm_alumni.dim_designation.fin_fund%type
    , fin_fund_id dm_alumni.dim_designation.fin_fund%type
    , fin_project_id dm_alumni.dim_designation.fin_project%type
    , fin_activity dm_alumni.dim_designation.designation_activity%type
    , fin_department_id dm_alumni.dim_designation.designation_fin_department_id%type
    , ksm_flag varchar2(1)
    , designation_school dm_alumni.dim_designation.designation_school%type
    , department_program dm_alumni.dim_designation.designation_department_program_code%type
    , fasb_type dm_alumni.dim_designation.fasb_type%type
    , case_type dm_alumni.dim_designation.case_type%type
    , case_purpose dm_alumni.dim_designation.case_purpose%type
    , designation_tier_1 dm_alumni.dim_designation.designation_tier_1%type
    , designation_tier_2 dm_alumni.dim_designation.designation_tier_2%type
    , designation_comment dm_alumni.dim_designation.designation_comment%type
    , designation_date_added dm_alumni.dim_designation.designation_date_added%type
    , designation_date_modified dm_alumni.dim_designation.designation_date_modified%type
    , gl_effective_date dm_alumni.dim_designation.gl_effective_date%type
    , gl_expiration_date dm_alumni.dim_designation.gl_expiration_date%type
);

--------------------------------------
Type rec_opportunity Is Record (
    opportunity_salesforce_id dm_alumni.dim_opportunity.opportunity_salesforce_id%type
    , opportunity_record_id dm_alumni.dim_opportunity.opportunity_record_id%type
    , legacy_receipt_number dm_alumni.dim_opportunity.legacy_receipt_number%type
    , opportunity_stage dm_alumni.dim_opportunity.opportunity_stage%type
    , opportunity_record_type dm_alumni.dim_opportunity.opportunity_record_type%type
    , opportunity_type dm_alumni.dim_opportunity.opportunity_type%type
    , opportunity_donor_id dm_alumni.dim_opportunity.opportunity_donor_id%type
    , opportunity_donor_name dm_alumni.dim_opportunity.opportunity_constituent_name%type
    , credit_date dm_alumni.dim_opportunity.opportunity_credit_date%type
    , fiscal_year dm_alumni.dim_opportunity.opportunity_funded_fiscal_year%type
    , amount dm_alumni.dim_opportunity.opportunity_amount%type
    , designation_salesforce_id dm_alumni.dim_opportunity.designation_salesforce_id%type
    , is_anonymous_indicator dm_alumni.dim_opportunity.is_anonymous_indicator%type
    , anonymous_type dm_alumni.dim_opportunity.anonymous_type%type
    , linked_proposal_record_id dm_alumni.dim_opportunity.linked_proposal_record_id%type
    , linked_proposal_active_proposal_manager dm_alumni.dim_opportunity.linked_proposal_active_proposal_manager%type
    , next_scheduled_payment_date dm_alumni.dim_opportunity.next_scheduled_payment_date%type
    , next_scheduled_payment_amount dm_alumni.dim_opportunity.next_scheduled_payment_amount%type
    , matched_gift_record_id dm_alumni.dim_opportunity.matched_gift_record_id%type
    , matching_gift_stage dm_alumni.dim_opportunity.matching_gift_stage%type
);

--------------------------------------
Type rec_gift_credit Is Record (
  placeholder varchar2(1)
);

--------------------------------------
Type rec_involvement Is Record (
  placeholder varchar2(1)
);

--------------------------------------
Type rec_service_indicators Is Record (
  placeholder varchar2(1)
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type constituent Is Table Of rec_constituent;
Type organization Is Table Of rec_organization;
Type degrees Is Table Of rec_degrees;
Type designation Is Table Of rec_designation;
Type opportunity Is Table Of rec_opportunity;
Type gift_credit Is Table Of rec_gift_credit;
Type involvement Is Table Of rec_involvement;
Type service_indicators Is Table Of rec_service_indicators;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

Function tbl_constituent
  Return constituent Pipelined;

Function tbl_organization
  Return organization Pipelined;

Function tbl_degrees
  Return degrees Pipelined;

Function tbl_designation
  Return designation Pipelined;

Function tbl_opportunity
  Return opportunity Pipelined;

Function tbl_gift_credit
  Return gift_credit Pipelined;

Function tbl_involvement
  Return involvement Pipelined;

Function tbl_service_indicators
  Return service_indicators Pipelined;

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

End dw_pkg_base;
/
Create Or Replace Package Body dw_pkg_base Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

--------------------------------------
Cursor c_constituent Is
  Select
      constituent_salesforce_id
      As salesforce_id
    , constituent_household_account_salesforce_id
      As household_id
    , household_primary_constituent_indicator
      As household_primary
    , constituent_donor_id
      As donor_id
    , full_name
    , trim(trim(last_name || ', ' || first_name) || ' ' || Case When middle_name != '-' Then middle_name End)
      As sort_name
    , is_deceased_indicator
    , primary_constituent_type
    , institutional_suffix
    , spouse_constituent_donor_id
      As spouse_donor_id
    , spouse_name
    , spouse_instituitional_suffix
    , preferred_address_city
    , preferred_address_state
    , preferred_address_country_name
    , trunc(etl_update_date)
      As etl_update_date
  From dm_alumni.dim_constituent entity
;

--------------------------------------
Cursor c_organization Is
  Select
    organization_salesforce_id
    As salesforce_id
    , organization_ultimate_parent_donor_id
      As ult_parent_id
    , organization_donor_id
      As donor_id
    , Case When organization_donor_id = organization_ultimate_parent_donor_id Then 'Y' End
      As org_primary
    , organization_name
    , organization_name
      As sort_name
    , organization_inactive_indicator
    , organization_type
    , organization_ultimate_parent_donor_id
      As org_ult_parent_donor_id
    , organization_ultimate_parent_name
      As org_ult_parent_name
    , preferred_address_city
    , preferred_address_state
    , preferred_address_country_name
    , trunc(etl_update_date)
      As etl_update_date
  From dm_alumni.dim_organization org
;

--------------------------------------
Cursor c_degrees Is
  Select NULL
  From dm_alumni.dim_degree_detail
;

--------------------------------------
Cursor c_designation Is
  Select
    designation_record_id
    , designation_name
    , designation_status
    , legacy_allocation_code
    , fin_fund
    , Case
        When fin_fund Not In ('Historical Data', '-')
          Then substr(fin_fund, 0, 3)
        End
      As fin_fund_id
    , fin_project
      As fin_project_id
    , Case
        When designation_activity != '-'
          Then designation_activity
        End
      As fin_activity
    , Case
        When designation_fin_department_id != '-'
          Then designation_fin_department_id
        End
      As fin_department_id
    , Case
        When designation_school = 'Kellogg'
          Or designation_department_program_code Like '%Kellogg%'
        Then 'Y'
        End
      As ksm_flag
    , designation_school
    , designation_department_program_code
      As department_program
    , fasb_type
    , case_type
    , case_purpose
    , designation_tier_1
    , designation_tier_2
    , designation_comment
    , designation_date_added
    , designation_date_modified
    , gl_effective_date
    , gl_expiration_date
  From dm_alumni.dim_designation
;

--------------------------------------
Cursor c_opportunity Is
  Select
    opportunity_salesforce_id
    , opportunity_record_id
    , legacy_receipt_number
    , opportunity_stage
    , opportunity_record_type
    , opportunity_type
    , opportunity_donor_id
    , Case
        When opportunity_constituent_name != '-'
          Then opportunity_constituent_name
          Else opportunity_organization_name
        End
      As opportunity_donor_name
    , opportunity_credit_date
      As credit_date
    , opportunity_funded_fiscal_year
      As fiscal_year
    , opportunity_amount
      As amount
    , designation_salesforce_id
    , is_anonymous_indicator
    , anonymous_type
    , linked_proposal_record_id
    , linked_proposal_active_proposal_manager
    , next_scheduled_payment_date
    , next_scheduled_payment_amount
    , matched_gift_record_id
    , matching_gift_stage
  From dm_alumni.dim_opportunity
;

--------------------------------------
Cursor c_gift_credit Is
  Select NULL
  From dm_alumni.fact_giving_credit_details
;

--------------------------------------
Cursor c_involvement Is
  Select NULL
  From dm_alumni.dim_involvement
;

--------------------------------------
Cursor c_service_indicators Is
  Select NULL
  From stg_alumni.ucinn_ascendv2__service_indicator__c
;

/*************************************************************************
Pipelined functions
*************************************************************************/

--------------------------------------
Function tbl_constituent
  Return constituent Pipelined As
    -- Declarations
    con constituent;

  Begin
    Open c_constituent;
      Fetch c_constituent Bulk Collect Into con;
    Close c_constituent;
    -- Pipe out the rows
    For i in 1..(con.count) Loop
      Pipe row(con(i));
    End Loop;
    Return;
  End;

--------------------------------------
Function tbl_organization
  Return organization Pipelined As
    -- Declarations
    org organization;

  Begin
    Open c_organization;
      Fetch c_organization Bulk Collect Into org;
    Close c_organization;
    -- Pipe out the rows
    For i in 1..(org.count) Loop
      Pipe row(org(i));
    End Loop;
    Return;
  End;

--------------------------------------
Function tbl_degrees
  Return degrees Pipelined As
    -- Declarations
    deg degrees;

  Begin
    Open c_degrees;
      Fetch c_degrees Bulk Collect Into deg;
    Close c_degrees;
    -- Pipe out the rows
    For i in 1..(deg.count) Loop
      Pipe row(deg(i));
    End Loop;
    Return;
  End;

--------------------------------------
Function tbl_designation
  Return designation Pipelined As
    -- Declarations
    des designation;

  Begin
    Open c_designation;
      Fetch c_designation Bulk Collect Into des;
    Close c_designation;
    -- Pipe out the rows
    For i in 1..(des.count) Loop
      Pipe row(des(i));
    End Loop;
    Return;
  End;
  
--------------------------------------
Function tbl_opportunity
  Return opportunity Pipelined As
    -- Declarations
    opp opportunity;

  Begin
    Open c_opportunity;
      Fetch c_opportunity Bulk Collect Into opp;
    Close c_opportunity;
    -- Pipe out the rows
    For i in 1..(opp.count) Loop
      Pipe row(opp(i));
    End Loop;
    Return;
  End;

--------------------------------------
Function tbl_gift_credit
  Return gift_credit Pipelined As
    -- Declarations
    gcr gift_credit;

  Begin
    Open c_gift_credit;
      Fetch c_gift_credit Bulk Collect Into gcr;
    Close c_gift_credit;
    -- Pipe out the rows
    For i in 1..(gcr.count) Loop
      Pipe row(gcr(i));
    End Loop;
    Return;
  End;

--------------------------------------
Function tbl_involvement
  Return involvement Pipelined As
    -- Declarations
    inv involvement;

  Begin
    Open c_involvement;
      Fetch c_involvement Bulk Collect Into inv;
    Close c_involvement;
    -- Pipe out the rows
    For i in 1..(inv.count) Loop
      Pipe row(inv(i));
    End Loop;
    Return;
  End;

--------------------------------------
Function tbl_service_indicators
  Return service_indicators Pipelined As
    -- Declarations
    si service_indicators;

  Begin
    Open c_service_indicators;
      Fetch c_service_indicators Bulk Collect Into si;
    Close c_service_indicators;
    -- Pipe out the rows
    For i in 1..(si.count) Loop
      Pipe row(si(i));
    End Loop;
    Return;
  End;

End dw_pkg_base;
/
