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
  , preferred_address_country dm_alumni.dim_constituent.preferred_address_country_name%type
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
  , preferred_address_country dm_alumni.dim_organization.preferred_address_country_name%type
  , etl_update_date dm_alumni.dim_organization.etl_update_date%type
);

--------------------------------------
Type rec_degrees Is Record (
    constituent_donor_id dm_alumni.dim_degree_detail.constituent_donor_id%type
    , constituent_name dm_alumni.dim_degree_detail.constituent_name%type
    , degree_record_id stg_alumni.ucinn_ascendv2__degree_information__c.name%type
    , degree_status stg_alumni.ucinn_ascendv2__degree_information__c.ap_status__c%type
    , nu_indicator varchar2(1)
    , degree_organization_name dm_alumni.dim_degree_detail.degree_organization_name%type
    , degree_school_name stg_alumni.ucinn_ascendv2__degree_information__c.ap_school_name_formula__c%type
    , degree_level stg_alumni.ucinn_ascendv2__degree_information__c.ap_degree_type_from_degreecode__c%type
    , degree_year stg_alumni.ucinn_ascendv2__degree_information__c.ucinn_ascendv2__conferred_degree_year__c%type
    , degree_reunion_year stg_alumni.ucinn_ascendv2__degree_information__c.ucinn_ascendv2__reunion_year__c%type
    , degree_grad_date stg_alumni.ucinn_ascendv2__degree_information__c.ucinn_ascendv2__degree_date__c%type
    , degree_code stg_alumni.ucinn_ascendv2__degree_code__c.ucinn_ascendv2__degree_code__c%type
    , degree_name stg_alumni.ucinn_ascendv2__degree_code__c.ucinn_ascendv2__description__c%type
    , department_code stg_alumni.ucinn_ascendv2__academic_organization__c.ucinn_ascendv2__code__c%type
    , department_desc stg_alumni.ucinn_ascendv2__academic_organization__c.ucinn_ascendv2__description_short__c%type
    , department_desc_full stg_alumni.ucinn_ascendv2__academic_organization__c.ucinn_ascendv2__description_long__c%type
    , degree_campus stg_alumni.ucinn_ascendv2__degree_information__c.ap_campus__c%type
    , degree_program_code stg_alumni.ap_program__c.ap_program_code__c%type
    , degree_program stg_alumni.ap_program__c.name%type
    , degree_concentration_desc stg_alumni.ucinn_ascendv2__specialty__c.name%type
    , degree_major_code_1 stg_alumni.ucinn_ascendv2__post_code__c.ap_major_code__c%type
    , degree_major_code_2 stg_alumni.ucinn_ascendv2__post_code__c.ap_major_code__c%type 
    , degree_major_code_3 stg_alumni.ucinn_ascendv2__post_code__c.ap_major_code__c%type
    , degree_major_1 stg_alumni.ucinn_ascendv2__post_code__c.name%type
    , degree_major_2 stg_alumni.ucinn_ascendv2__post_code__c.name%type
    , degree_major_3 stg_alumni.ucinn_ascendv2__post_code__c.name%type
    , degree_notes stg_alumni.ucinn_ascendv2__degree_information__c.ap_notes__c%type
    , etl_update_date stg_alumni.ucinn_ascendv2__degree_information__c.etl_update_date%type
);

--------------------------------------
Type rec_designation Is Record (
    designation_salesforce_id dm_alumni.dim_designation.designation_salesforce_id%type
    , designation_record_id dm_alumni.dim_designation.designation_record_id%type
    , designation_name dm_alumni.dim_designation.designation_name%type
    , designation_status dm_alumni.dim_designation.designation_status%type
    , legacy_allocation_code dm_alumni.dim_designation.legacy_allocation_code%type
    , fin_fund dm_alumni.dim_designation.fin_fund%type
    , fin_fund_id dm_alumni.dim_designation.fin_fund%type
    , fin_project_id dm_alumni.dim_designation.fin_project%type
    , fin_activity dm_alumni.dim_designation.designation_activity%type
    , fin_department_id dm_alumni.dim_designation.designation_fin_department_id%type
    , ksm_flag varchar2(1)
    , nu_af_flag dm_alumni.dim_designation.annual_fund_designation_indicator%type
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
    , etl_update_date dm_alumni.dim_designation.etl_update_date%type
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
    , discounted_amount dm_alumni.dim_opportunity.pledge_total_countable_amount%type
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
  hard_and_soft_credit_salesforce_id stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.id%type
    , receipt_number stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__receipt_number__c%type
    , hard_and_soft_credit_record_id stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.name%type
    , credit_amount stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__credit_amount__c%type
    , hard_credit_amount stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__credit_amount__c%type
    , credit_date stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__credit_date_formula__c%type
    , fiscal_year stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.nu_fiscal_year__c%type
    , credit_type stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__credit_type__c%type
    , source_type stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__source__c%type
    , source_type_detail stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__gift_type_formula__c%type
    , opportunity_salesforce_id stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__opportunity__c%type
    , designation_salesforce_id stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__designation__c%type
    , designation_record_id stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__designation_code_formula__c%type
    , donor_name_and_id varchar2(255) -- Original is varchar2(1300)
    , donor_salesforce_id stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__credit_id__c%type
    , hard_credit_salesforce_id stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__hard_credit_recipient_account__c%type
    , hard_credit_donor_name stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__hard_credit_formula__c%type
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
    , nullif(institutional_suffix, '-')
      As institutional_suffix
    , nullif(spouse_constituent_donor_id, '-')
      As spouse_donor_id
    , nullif(spouse_name, '-')
      As spouse_name
    , nullif(spouse_instituitional_suffix, '-')
      As spouse_instituitional_suffix
    , nullif(preferred_address_city, '-')
      As preferred_address_city
    , nullif(preferred_address_state, '-')
      As preferred_address_state
    , nullif(preferred_address_country_name, '-')
      As preferred_address_country
    , trunc(etl_update_date)
      As etl_update_date
  From dm_alumni.dim_constituent con
  Where con.constituent_salesforce_id != '-'
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
    , Case
        When organization_donor_id = organization_ultimate_parent_donor_id
          Then 'Y'
        Else 'N'
        End
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
    , nullif(preferred_address_city, '-')
      As preferred_address_city
    , nullif(preferred_address_state, '-')
      As preferred_address_state
    , nullif(preferred_address_country_name, '-')
      As preferred_address_country
    , trunc(etl_update_date)
      As etl_update_date
  From dm_alumni.dim_organization org
  Where org.organization_salesforce_id != '-'
;

--------------------------------------
Cursor c_degrees Is
  Select
    dcon.constituent_donor_id
    , dcon.full_name
      As constituent_name
    , deginf.name
      As degree_record_id
    , deginf.ap_status__c
      As degree_status
    , Case
        When deginf.Ucinn_Ascendv2__Degree_Institution__c = '001O800000B8YHhIAN' -- Northwestern University
          Then 'Y'
          Else 'N'
        End
      As nu_indicator
    , dorg.organization_name
      As degree_organization_name
    , deginf.ap_school_name_formula__c
      As degree_school_name
    , deginf.ap_degree_type_from_degreecode__c
      As degree_level
    , deginf.ucinn_ascendv2__conferred_degree_year__c
      As degree_year
    , deginf.ucinn_ascendv2__reunion_year__c
      As degree_reunion_year
    , deginf.ucinn_ascendv2__degree_date__c
      As degree_grad_date
    , degcd.ucinn_ascendv2__degree_code__c
      As degree_code
    , degcd.ucinn_ascendv2__description__c
      As degree_name
    , acaorg.ucinn_ascendv2__code__c
      As department_code
    , acaorg.ucinn_ascendv2__description_short__c
      As department_desc
    , acaorg.ucinn_ascendv2__description_long__c
      As department_desc_full
    , deginf.ap_campus__c
      As degree_campus
    , prog.ap_program_code__c
      As degree_program_code
    , prog.name
      As degree_program
    , spec.name
      As degree_concentration_desc
    , postcd.ap_major_code__c
      As degree_major_code_1
    , postcd2.ap_major_code__c
      As degree_major_code_2
    , postcd3.ap_major_code__c
      As degree_major_code_3
    , postcd.name
      As degree_major_1
    , postcd2.name
      As degree_major_2
    , postcd3.name
      As degree_major_3
    , deginf.ap_notes__c
      As degree_notes
    , trunc(deginf.etl_update_date) -- data refresh timestamp
      As etl_update_date
  -- Degree information detail
  From stg_alumni.ucinn_ascendv2__degree_information__c deginf
  -- Constituent and organization lookup tables
  Inner Join dm_alumni.dim_constituent dcon
    On dcon.constituent_salesforce_id = deginf.ucinn_ascendv2__contact__c
  Left Join dm_alumni.dim_organization dorg
    On dorg.organization_salesforce_id = deginf.ucinn_ascendv2__degree_institution__c
  -- Degree code
  Left Join stg_alumni.ucinn_ascendv2__degree_code__c degcd
    On degcd.id = deginf.ucinn_ascendv2__degree_code__c
  -- Major codes
  Left Join stg_alumni.ucinn_ascendv2__post_code__c postcd
    On postcd.id = deginf.ucinn_ascendv2__post_code__c
  Left Join stg_alumni.ucinn_ascendv2__post_code__c postcd2
    On postcd2.id = deginf.ucinn_ascendv2__second_major_post_code__c
  Left Join stg_alumni.ucinn_ascendv2__post_code__c postcd3
    On postcd3.id = deginf.ap_third_major_post_code__c
  -- Program/cohort
  Left Join stg_alumni.ap_program__c prog
    On prog.id = deginf.ap_program_class_section__c
  -- Specialty code
  Left Join stg_alumni.ucinn_ascendv2__specialty__c spec
    On spec.id = deginf.ucinn_ascendv2__concentration_specialty__c
  -- Academic orgs, aka department
  Left Join stg_alumni.ucinn_ascendv2__academic_organization__c acaorg
    On acaorg.id = deginf.ap_department__c
;

--------------------------------------
Cursor c_designation Is
  Select
    designation_salesforce_id
    , designation_record_id
    , designation_name
    , designation_status
    , legacy_allocation_code
    , nullif(fin_fund, '-')
      As fin_fund
    , Case
        When fin_fund Not In ('Historical Data', '-')
          Then substr(fin_fund, 0, 3)
        End
      As fin_fund_id
    , fin_project
      As fin_project_id
    , nullif(designation_activity, '-')
      As fin_activity
    , nullif(designation_fin_department_id, '-')
      As fin_department_id
    , Case
        When designation_school = 'Kellogg'
          Or (
            -- Include any historical funds missing designation school
            designation_department_program_code Like '%Kellogg%'
            And nullif(designation_school, '-') Is Null
          )
        Then 'Y'
        End
      As ksm_flag
    , annual_fund_designation_indicator
      As nu_af_flag
    , designation_school
    , designation_department_program_code
      As department_program
    , nullif(fasb_type, '-')
      As fasb_type
    , nullif(case_type, '-')
      case_type
    , nullif(case_purpose, '-')
      As case_purpose
    , nullif(designation_tier_1, '-')
      As designation_tier_1
    , nullif(designation_tier_2, '-')
      As designation_tier_2
    , nullif(designation_comment, '-')
      As designation_comment
    , designation_date_added
    , designation_date_modified
    , gl_effective_date
    , gl_expiration_date
    , trunc(etl_update_date)
      As etl_update_date
  From dm_alumni.dim_designation
  Where designation_record_id != '-'
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
    , to_number(nullif(opportunity_funded_fiscal_year, '-'))
      As fiscal_year
    , opportunity_amount
      As amount
    , pledge_total_countable_amount
      As discounted_amount
    , designation_salesforce_id
    , nullif(is_anonymous_indicator, '-')
      As is_anonymous_indicator
    , nullif(anonymous_type, '-')
      As anonymous_type
    , nullif(linked_proposal_record_id, '-')
      As linked_proposal_record_id
    , nullif(linked_proposal_active_proposal_manager, '-')
      As linked_proposal_active_proposal_manager
    , next_scheduled_payment_date
    , next_scheduled_payment_amount
    , nullif(matched_gift_record_id, '-')
      As matched_gift_record_id
    , matching_gift_stage
  From dm_alumni.dim_opportunity opp
  Where opportunity_record_id != '-'
;

--------------------------------------
Cursor c_gift_credit Is
  Select
      hsc.id
      As hard_and_soft_credit_salesforce_id
    , hsc.ucinn_ascendv2__receipt_number__c
      As receipt_number
    , hsc.name
      As hard_and_soft_credit_record_id
    , hsc.ucinn_ascendv2__credit_amount__c
      As credit_amount
      -- Hard credit calculation
    , Case
        When hsc.ucinn_ascendv2__credit_type__c = 'Hard'
          Then hsc.ucinn_ascendv2__credit_amount__c
          Else 0.0
        End
      As hard_credit_amount
    , hsc.ucinn_ascendv2__credit_date_formula__c
      As credit_date
    , to_number(hsc.nu_fiscal_year__c)
      As fiscal_year
    , hsc.ucinn_ascendv2__credit_type__c
      As credit_type
    , hsc.ucinn_ascendv2__source__c
      As source_type
    , hsc.ucinn_ascendv2__gift_type_formula__c
      As source_type_detail
    , hsc.ucinn_ascendv2__opportunity__c
      As opportunity_salesforce_id
    , hsc.ucinn_ascendv2__designation__c
      As designation_salesforce_id
    , hsc.ucinn_ascendv2__designation_code_formula__c
      As designation_record_id
    , hsc.ucinn_ascendv2__contact_name_and_donor_id_formula__c
      As donor_name_and_id
    , hsc.ucinn_ascendv2__credit_id__c
      As donor_salesforce_id
    , hsc.ucinn_ascendv2__hard_credit_recipient_account__c
      As hard_credit_salesforce_id
    , hsc.ucinn_ascendv2__hard_credit_formula__c
      As hard_credit_donor_name
  From stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c hsc
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
    For i in 1..(si.count) Loop
      Pipe row(si(i));
    End Loop;
    Return;
  End;

End dw_pkg_base;
/
