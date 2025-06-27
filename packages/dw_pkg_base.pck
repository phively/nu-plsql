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
  , household_id dm_alumni.dim_constituent.constituent_household_account_donor_id%type
  , household_primary dm_alumni.dim_constituent.household_primary_constituent_indicator%type
  , donor_id dm_alumni.dim_constituent.constituent_donor_id%type
  , full_name dm_alumni.dim_constituent.full_name%type
  , sort_name dm_alumni.dim_constituent.full_name%type
  , first_name dm_alumni.dim_constituent.first_name%type
  , last_name dm_alumni.dim_constituent.last_name%type
  , is_deceased_indicator dm_alumni.dim_constituent.is_deceased_indicator%type
  , primary_constituent_type dm_alumni.dim_constituent.primary_constituent_type%type
  , institutional_suffix dm_alumni.dim_constituent.institutional_suffix%type
  , spouse_donor_id dm_alumni.dim_constituent.spouse_constituent_donor_id%type
  , spouse_name dm_alumni.dim_constituent.spouse_name%type
  , spouse_instituitional_suffix dm_alumni.dim_constituent.spouse_instituitional_suffix%type
  , preferred_address_status dm_alumni.dim_constituent.preferred_address_status%type
  , preferred_address_type dm_alumni.dim_constituent.preferred_address_type%type
  , preferred_address_line_1 dm_alumni.dim_constituent.preferred_address_line_1%type
  , preferred_address_line_2 dm_alumni.dim_constituent.preferred_address_line_2%type
  , preferred_address_line_3 dm_alumni.dim_constituent.preferred_address_line_3%type
  , preferred_address_line_4 dm_alumni.dim_constituent.preferred_address_line_4%type
  , preferred_address_city dm_alumni.dim_constituent.preferred_address_city%type
  , preferred_address_state dm_alumni.dim_constituent.preferred_address_state%type
  , preferred_address_postal_code dm_alumni.dim_constituent.preferred_address_postal_code%type
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
  , preferred_address_status dm_alumni.dim_organization.preferred_address_status%type
  , preferred_address_type dm_alumni.dim_organization.preferred_address_type%type
  , preferred_address_line_1 dm_alumni.dim_organization.preferred_address_line_1%type
  , preferred_address_line_2 dm_alumni.dim_organization.preferred_address_line_2%type
  , preferred_address_line_3 dm_alumni.dim_organization.preferred_address_line_3%type
  , preferred_address_line_4 dm_alumni.dim_organization.preferred_address_line_4%type
  , preferred_address_city dm_alumni.dim_organization.preferred_address_city%type
  , preferred_address_state dm_alumni.dim_organization.preferred_address_state%type
  , preferred_address_postal_code dm_alumni.dim_organization.preferred_address_postal_code%type
  , preferred_address_country dm_alumni.dim_organization.preferred_address_country_name%type
  , etl_update_date dm_alumni.dim_organization.etl_update_date%type
);

--------------------------------------
Type rec_mini_entity Is Record (
  person_or_org varchar2(1)
  , salesforce_id dm_alumni.dim_constituent.constituent_salesforce_id%type
  , household_id dm_alumni.dim_constituent.constituent_household_account_salesforce_id%type
  , household_primary dm_alumni.dim_constituent.household_primary_constituent_indicator%type
  , donor_id dm_alumni.dim_constituent.constituent_donor_id%type
  , full_name dm_alumni.dim_constituent.full_name%type
  , sort_name dm_alumni.dim_constituent.full_name%type
  , is_deceased_indicator dm_alumni.dim_constituent.is_deceased_indicator%type
  , primary_record_type dm_alumni.dim_constituent.primary_constituent_type%type
  , institutional_suffix dm_alumni.dim_constituent.institutional_suffix%type
  , spouse_donor_id dm_alumni.dim_constituent.spouse_constituent_donor_id%type
  , spouse_name dm_alumni.dim_constituent.spouse_name%type
  , spouse_institutional_suffix dm_alumni.dim_constituent.spouse_instituitional_suffix%type
  , org_ult_parent_donor_id dm_alumni.dim_organization.organization_ultimate_parent_donor_id %type
  , org_ult_parent_name dm_alumni.dim_organization.organization_ultimate_parent_name%type
  , etl_update_date dm_alumni.dim_constituent.etl_update_date%type
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
    , fin_department_id dm_alumni.dim_designation.designation_fin_department_id%type
    , fin_project_id dm_alumni.dim_designation.fin_project%type
    , fin_activity_id dm_alumni.dim_designation.designation_activity%type
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
Type rec_designation_detail Is Record (
    pledge_or_gift_record_id dm_alumni.dim_designation_detail.pledge_or_gift_record_id%type
    , pledge_or_gift_date dm_alumni.dim_designation_detail.pledge_or_gift_date%type
    , pledge_or_gift_status dm_alumni.dim_designation_detail.pledge_or_gift_status%type
    , designation_detail_record_id dm_alumni.dim_designation_detail.designation_detail_record_id%type
    , designation_record_id dm_alumni.dim_designation_detail.designation_record_id%type
    , designation_detail_name dm_alumni.dim_designation_detail.designation_detail_name%type
    , designation_amount dm_alumni.dim_designation_detail.designation_amount%type
    , countable_amount_bequest dm_alumni.dim_designation_detail.countable_amount_bequest%type
    , bequest_flag varchar2(1)
    , total_paid_amount dm_alumni.dim_designation_detail.total_payment_credit_to_date_amount%type
    , overpaid_flag varchar2(1)
);

--------------------------------------
Type rec_opportunity Is Record (
    opportunity_salesforce_id dm_alumni.dim_opportunity.opportunity_salesforce_id%type
    , opportunity_record_id dm_alumni.dim_opportunity.opportunity_record_id%type
    , opportunity_id_full stg_alumni.opportunity.name%type
    , legacy_receipt_number dm_alumni.dim_opportunity.legacy_receipt_number%type
    , opportunity_stage dm_alumni.dim_opportunity.opportunity_stage%type
    , opportunity_closed_stage stg_alumni.opportunity.stagename%type
    , opportunity_record_type dm_alumni.dim_opportunity.opportunity_record_type%type
    , opportunity_type dm_alumni.dim_opportunity.opportunity_type%type
    , opportunity_donor_id dm_alumni.dim_opportunity.opportunity_donor_id%type
    , opportunity_donor_name dm_alumni.dim_opportunity.opportunity_constituent_name%type
    , credit_date dm_alumni.dim_opportunity.opportunity_credit_date%type
    , fiscal_year dm_alumni.dim_opportunity.opportunity_funded_fiscal_year%type
    , entry_date dm_alumni.dim_opportunity.opportunity_entry_date%type
    , amount dm_alumni.dim_opportunity.opportunity_amount%type
    , discounted_amount dm_alumni.dim_opportunity.pledge_total_countable_amount%type
    , tender_type dm_alumni.dim_opportunity.tender_type%type
    , designation_salesforce_id dm_alumni.dim_opportunity.designation_salesforce_id%type
    , is_anonymous_indicator dm_alumni.dim_opportunity.is_anonymous_indicator%type
    , anonymous_type dm_alumni.dim_opportunity.anonymous_type%type
    , linked_proposal_record_id dm_alumni.dim_opportunity.linked_proposal_record_id%type
    , linked_proposal_active_proposal_manager dm_alumni.dim_opportunity.linked_proposal_active_proposal_manager%type
    , payment_schedule stg_alumni.opportunity.ap_payment_schedule__c%type
    , opp_amount_paid dm_alumni.dim_opportunity.pledge_amount_paid_to_date%type
    , next_scheduled_payment_date dm_alumni.dim_opportunity.next_scheduled_payment_date%type
    , next_scheduled_payment_amount dm_alumni.dim_opportunity.next_scheduled_payment_amount%type
    , matched_gift_record_id dm_alumni.dim_opportunity.matched_gift_record_id%type
    , matching_gift_stage dm_alumni.dim_opportunity.matching_gift_stage%type
    , etl_update_date dm_alumni.dim_opportunity.etl_update_date%type
);

--------------------------------------
Type rec_payment Is Record (
    payment_salesforce_id stg_alumni.ucinn_ascendv2__payment__c.id%type
    , payment_record_id stg_alumni.ucinn_ascendv2__payment__c.name%type
    , legacy_receipt_number stg_alumni.ucinn_ascendv2__payment__c.ap_legacy_receipt_number__c%type
    , opportunity_stage stg_alumni.ucinn_ascendv2__payment__c.ucinn_ascendv2__opportunity_stage__c%type
    , opportunity_record_type stg_alumni.ucinn_ascendv2__payment__c.ucinn_ascendv2__opportunity_record_type__c%type
    , opportunity_type stg_alumni.ucinn_ascendv2__payment__c.ucinn_ascendv2__transaction_type__c%type
    , payment_donor_id stg_alumni.ucinn_ascendv2__payment__c.ucinn_ascendv2__donor_id_formula__c%type
    , payment_donor_name  stg_alumni.ucinn_ascendv2__payment__c.ucinn_ascendv2__gift_receipt_name_formula__c%type
    , credit_date stg_alumni.ucinn_ascendv2__payment__c.ucinn_ascendv2__credit_date__c%type
    , fiscal_year stg_alumni.ucinn_ascendv2__payment__c.ucinn_ascendv2__fiscal_year_formula__c%type
    , entry_date stg_alumni.ucinn_ascendv2__payment__c.ap_processed_date__c%type
    , amount stg_alumni.ucinn_ascendv2__payment__c.ap_transaction_amount__c%type
    , tender_type stg_alumni.ucinn_ascendv2__payment__c.ucinn_ascendv2__tender_type_formula__c%type
    , designation_salesforce_id stg_alumni.ucinn_ascendv2__payment__c.ucinn_ascendv2__designation_detail__c%type
    , is_anonymous_indicator stg_alumni.ucinn_ascendv2__payment__c.ucinn_ascendv2__is_anonymous__c%type
    , anonymous_type stg_alumni.ucinn_ascendv2__payment__c.anonymous_type__c%type
    , etl_update_date stg_alumni.ucinn_ascendv2__payment__c.etl_update_date%type
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
    , payment_salesforce_id stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__payment__c%type
    , designation_salesforce_id stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__designation__c%type
    , designation_record_id stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__designation_code_formula__c%type
    , donor_name_and_id varchar2(255) -- Original is varchar2(1300)
    , donor_salesforce_id stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__credit_id__c%type
    , hard_credit_salesforce_id stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__hard_credit_recipient_account__c%type
    , hard_credit_donor_name stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.ucinn_ascendv2__hard_credit_formula__c%type
    , etl_update_date stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c.etl_update_date%type
);

--------------------------------------
Type rec_involvement Is Record (
    constituent_donor_id dm_alumni.dim_involvement.constituent_donor_id%type
    , constituent_name dm_alumni.dim_involvement.constituent_name%type
    , involvement_record_id dm_alumni.dim_involvement.involvement_record_id%type
    , involvement_code stg_alumni.ucinn_ascendv2__involvement_value__c.ucinn_ascendv2__code__c%type
    , involvement_name dm_alumni.dim_involvement.involvement_name%type
    , involvement_status dm_alumni.dim_involvement.involvement_status%type
    , involvement_type dm_alumni.dim_involvement.involvement_type%type
    , involvement_role dm_alumni.dim_involvement.involvement_role%type
    , involvement_business_unit dm_alumni.dim_involvement.involvement_business_unit%type
    , involvement_start_date dm_alumni.dim_involvement.involvement_start_date%type
    , involvement_end_date dm_alumni.dim_involvement.involvement_end_date%type
    , involvement_comment stg_alumni.ucinn_ascendv2__involvement__c.nu_comments__c%type
    , etl_update_date dm_alumni.dim_involvement.etl_update_date%type
);

--------------------------------------
Type rec_service_indicators Is Record (
  constituent_salesforce_id stg_alumni.ucinn_ascendv2__service_indicator__c.ucinn_ascendv2__contact__c%type
  , service_indicator_record_id stg_alumni.ucinn_ascendv2__service_indicator__c.ucinn_ascendv2__service_indicator_name_auto_number__c%type
  , business_unit stg_alumni.ucinn_ascendv2__service_indicator__c.ap_business_unit__c%type
  , service_indicator_code stg_alumni.ucinn_ascendv2__service_indicator__c.ucinn_ascendv2__code_formula__c%type
  , service_indicator stg_alumni.ucinn_ascendv2__service_indicator__c.ap_service_indicator_value_name__c%type
  , active_ind varchar2(1)
  , comments stg_alumni.ucinn_ascendv2__service_indicator__c.ucinn_ascendv2__comments__c%type
  , start_date stg_alumni.ucinn_ascendv2__service_indicator__c.ucinn_ascendv2__start_date__c%type
  , end_date stg_alumni.ucinn_ascendv2__service_indicator__c.ucinn_ascendv2__end_date__c%type
  , etl_update_date stg_alumni.ucinn_ascendv2__service_indicator__c.etl_update_date%type
);

--------------------------------------
Type rec_assignment Is Record (
    assignment_record_id stg_alumni.ucinn_ascendv2__assignment__c.name%type
    , staff_user_salesforce_id stg_alumni.user_tbl.id%type
    , staff_username stg_alumni.user_tbl.username%type
    , staff_constituent_salesforce_id stg_alumni.user_tbl.contactid%type
    , staff_name stg_alumni.user_tbl.name%type
    , staff_is_active stg_alumni.user_tbl.isactive%type
    , assignment_type stg_alumni.ucinn_ascendv2__assignment__c.ucinn_ascendv2__assignment_type__c%type
    , assignment_code varchar2(8)
    , assignment_business_unit stg_alumni.ucinn_ascendv2__assignment__c.ap_business_unit__c%type
    , ksm_flag varchar2(1)
    , assigneee_salesforce_id stg_alumni.ucinn_ascendv2__assignment__c.ucinn_ascendv2__contact__c%type
    , assignee_donor_id stg_alumni.ucinn_ascendv2__assignment__c.ucinn_ascendv2__donor_id_formula__c%type
    , assignee_last_name stg_alumni.ucinn_ascendv2__assignment__c.ucinn_ascendv2__contact_last_name_formula__c%type
    , assignee_stage stg_alumni.ucinn_ascendv2__assignment__c.ucinn_ascendv2__stage_of_readiness_formula__c%type
    , is_active_indicator stg_alumni.ucinn_ascendv2__assignment__c.ap_is_active__c%type
    , start_date stg_alumni.ucinn_ascendv2__assignment__c.ucinn_ascendv2__assignment_start_date__c%type
    , end_date stg_alumni.ucinn_ascendv2__assignment__c.ucinn_ascendv2__assignment_end_date__c%type
    , etl_update_date stg_alumni.ucinn_ascendv2__assignment__c.etl_update_date%type
);

--------------------------------------
Type rec_proposal Is Record (
    opportunity_salesforce_id dm_alumni.dim_proposal_opportunity.opportunity_salesforce_id%type
    , proposal_record_id dm_alumni.dim_proposal_opportunity.proposal_record_id%type
    , proposal_legacy_id dm_alumni.dim_proposal_opportunity.proposal_legacy_id%type
    , proposal_strategy_record_id dm_alumni.dim_proposal_opportunity.proposal_strategy_record_id%type
    , donor_id dm_alumni.fact_proposal_opportunity.constituent_donor_id%type
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
    , proposal_payment_schedule dm_alumni.dim_proposal_opportunity.proposal_payment_schedule%type
    , proposal_designation_units dm_alumni.dim_proposal_opportunity.proposal_designation_work_plan_units%type
    , ksm_flag varchar2(1)
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

Type constituent Is Table Of rec_constituent;
Type organization Is Table Of rec_organization;
Type mini_entity Is Table Of rec_mini_entity;
Type degrees Is Table Of rec_degrees;
Type designation Is Table Of rec_designation;
Type designation_detail Is Table Of rec_designation_detail;
Type opportunity Is Table Of rec_opportunity;
Type payment Is Table Of rec_payment;
Type gift_credit Is Table Of rec_gift_credit;
Type involvement Is Table Of rec_involvement;
Type service_indicators Is Table Of rec_service_indicators;
Type assignments Is Table Of rec_assignment;
Type proposals Is Table Of rec_proposal;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

Function tbl_constituent
  Return constituent Pipelined;

Function tbl_organization
  Return organization Pipelined;

Function tbl_mini_entity
  Return mini_entity Pipelined;

Function tbl_degrees
  Return degrees Pipelined;

Function tbl_designation
  Return designation Pipelined;

Function tbl_designation_detail
  Return designation_detail Pipelined;

Function tbl_opportunity
  Return opportunity Pipelined;

Function tbl_payment
  Return payment Pipelined;

Function tbl_gift_credit
  Return gift_credit Pipelined;

Function tbl_involvement
  Return involvement Pipelined;

Function tbl_service_indicators
  Return service_indicators Pipelined;

Function tbl_assignments
  Return assignments Pipelined;

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
    , constituent_household_account_donor_id
      As household_id
    , household_primary_constituent_indicator
      As household_primary
    , constituent_donor_id
      As donor_id
    , full_name
    , trim(trim(last_name || ', ' || first_name) || ' ' || Case When middle_name != '-' Then middle_name End)
      As sort_name
    , first_name
    , last_name
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
    , nullif(preferred_address_status, '-')
      As preferred_address_status
    , nullif(preferred_address_type, '-')
      As preferred_address_type
    , nullif(preferred_address_line_1, '-')
      As preferred_address_line_1
    , nullif(preferred_address_line_2, '-')
      As preferred_address_line_2
    , nullif(preferred_address_line_3, '-')
      As preferred_address_line_3
    , nullif(preferred_address_line_4, '-')
      As preferred_address_line_4
    , nullif(preferred_address_city, '-')
      As preferred_address_city
    , nullif(preferred_address_state, '-')
      As preferred_address_state
    , nullif(preferred_address_postal_code, '-')
      As preferred_address_postal_code
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
    , nullif(organization_type, '-')
      As organization_type
    , organization_ultimate_parent_donor_id
      As org_ult_parent_donor_id
    , organization_ultimate_parent_name
      As org_ult_parent_name
    , nullif(preferred_address_status, '-')
      As preferred_address_status
    , nullif(preferred_address_type, '-')
      As preferred_address_type
    , nullif(preferred_address_line_1, '-')
      As preferred_address_line_1
    , nullif(preferred_address_line_2, '-')
      As preferred_address_line_2
    , nullif(preferred_address_line_3, '-')
      As preferred_address_line_3
    , nullif(preferred_address_line_4, '-')
      As preferred_address_line_4
    , nullif(preferred_address_city, '-')
      As preferred_address_city
    , nullif(preferred_address_state, '-')
      As preferred_address_state
    , nullif(preferred_address_postal_code, '-')
      As preferred_address_postal_code
    , nullif(preferred_address_country_name, '-')
      As preferred_address_country
    , trunc(etl_update_date)
      As etl_update_date
  From dm_alumni.dim_organization org
  Where org.organization_salesforce_id != '-'
;


--------------------------------------
Cursor c_mini_entity Is
  (
  Select
    'P' As person_or_org
    , c.salesforce_id
    , c.household_id
    , c.household_primary
    , c.donor_id
    , c.full_name
    , c.sort_name
    , c.is_deceased_indicator
    , c.primary_constituent_type As primary_record_type
    , institutional_suffix
    , spouse_donor_id
    , spouse_name
    , spouse_instituitional_suffix
    , NULL As org_ult_parent_donor_id
    , NULL As org_ult_parent_name
    , c.etl_update_date
  From table(dw_pkg_base.tbl_constituent) c
  ) Union All ( 
  Select 
    'O' As person_or_org
    , o.salesforce_id
    , o.ult_parent_id As household_id
    , o.org_primary
    , o.donor_id
    , o.organization_name
    , o.sort_name
    , o.organization_inactive_indicator
    , o.organization_type As primary_record_type
    , NULL As institutional_suffix
    , NULL As spouse_donor_id
    , NULL As spouse_name
    , NULL As spouse_institutional_suffix
    , o.org_ult_parent_donor_id
    , o.org_ult_parent_name
    , o.etl_update_date
  From table(dw_pkg_base.tbl_organization) o
  )
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
        When dorg.organization_name = 'Northwestern University' -- Northwestern University
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
    , nullif(designation_fin_department_id, '-')
      As fin_department_id
    , nullif(fin_project, '-')
      As fin_project_id
    , nullif(designation_activity, '-')
      As fin_activity
    , Case
        When designation_school Like '%Kellogg%'
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
Cursor c_designation_detail Is
  Select 
    pledge_or_gift_record_id
    , pledge_or_gift_date
    , pledge_or_gift_status
    , designation_detail_record_id
    , designation_record_id
    , designation_detail_name
    , designation_amount
    , countable_amount_bequest
    , Case When pledge_or_gift_type Like 'PGBEQ%' Then 'Y' End
      As bequest_flag
    , total_payment_credit_to_date_amount
      As total_paid_amount
    , Case
        When nvl(total_payment_credit_to_date_amount, 0) > nvl(designation_amount, 0)
          Then 'Y'
        End
      As overpaid_flag
  From dm_alumni.dim_designation_detail
;

--------------------------------------
Cursor c_opportunity Is
  
  With
  
  opp_raw As (
    Select
      id As opportunity_salesforce_id
      , ap_payment_schedule__c As payment_schedule
      , name As opportunity_id_full
      , stagename As opportunity_closed_stage
    From stg_alumni.opportunity o
  )

  Select
    opp.opportunity_salesforce_id
    , opp.opportunity_record_id
    , opp_raw.opportunity_id_full
    , nullif(legacy_receipt_number, '-')
      As legacy_receipt_number
    , opportunity_stage
    , opp_raw.opportunity_closed_stage
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
    , opportunity_entry_date
      As entry_date
    , opportunity_amount
      As amount
    , pledge_total_countable_amount
      As discounted_amount
    , nullif(opp.tender_type, '-')
      As tender_type
    , designation_salesforce_id
    , nullif(is_anonymous_indicator, '-')
      As is_anonymous_indicator
    , nullif(anonymous_type, '-')
      As anonymous_type
    , nullif(linked_proposal_record_id, '-')
      As linked_proposal_record_id
    , nullif(linked_proposal_active_proposal_manager, '-')
      As linked_proposal_active_proposal_manager
    , opp_sch.payment_schedule
    , opp.pledge_amount_paid_to_date
      As opp_amount_paid
    , next_scheduled_payment_date
    , next_scheduled_payment_amount
    , nullif(matched_gift_record_id, '-')
      As matched_gift_record_id
    , nullif(matching_gift_stage, '-')
      As matching_gift_stage
    , trunc(etl_update_date)
      As etl_update_date
  From dm_alumni.dim_opportunity opp
  Inner Join opp_raw
    On opp_raw.opportunity_salesforce_id = opp.opportunity_salesforce_id
  Left Join opp_raw opp_sch
    On opp_sch.opportunity_salesforce_id = opp.linked_proposal_salesforce_id
  Where opportunity_record_id != '-'
;

--------------------------------------
Cursor c_payment Is
  Select
    pay.id
      As payment_salesforce_id
    , pay.name
      As payment_record_id
    , pay.ap_legacy_receipt_number__c
      As legacy_receipt_number
    , pay.ucinn_ascendv2__opportunity_stage__c
      As opportunity_stage
    , pay.ucinn_ascendv2__opportunity_record_type__c
      As opportunity_record_type
    , pay.ucinn_ascendv2__transaction_type__c
      As opportunity_type
    , pay.ucinn_ascendv2__donor_id_formula__c
      As payment_donor_id
    , pay.ucinn_ascendv2__gift_receipt_name_formula__c
      As payment_donor_name
    , pay.ucinn_ascendv2__credit_date__c
      As credit_date
    , pay.ucinn_ascendv2__fiscal_year_formula__c
      As fiscal_year
    , pay.ap_processed_date__c
      As entry_date
    , pay.ap_transaction_amount__c
      As amount
    , pay.ucinn_ascendv2__tender_type_formula__c
      As tender_type
    , pay.ucinn_ascendv2__designation_detail__c
      As designation_salesforce_id
    , pay.ucinn_ascendv2__is_anonymous__c
      As is_anonymous_indicator
    , pay.anonymous_type__c
      As anonymous_type
    , trunc(etl_update_date)
      As etl_update_date
  From stg_alumni.ucinn_ascendv2__payment__c pay
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
    , hsc.ucinn_ascendv2__payment__c
      As payment_salesforce_id
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
    , trunc(hsc.etl_update_date)
      As etl_update_date
  From stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c hsc
;

--------------------------------------
Cursor c_involvement Is
  Select
    inv.constituent_donor_id
    , inv.constituent_name
    , inv.involvement_record_id
    , ival.ucinn_ascendv2__code__c
      As involvement_code
    , inv.involvement_name
    , inv.involvement_status
    , inv.involvement_type
    , inv.involvement_role
    , inv.involvement_business_unit
    , inv.involvement_start_date
    , inv.involvement_end_date
    , stginv.nu_comments__c
      As involvement_comment
    , trunc(inv.etl_update_date)
      As etl_update_date
  From dm_alumni.dim_involvement inv
  Inner Join stg_alumni.ucinn_ascendv2__involvement__c stginv
    On stginv.id = inv.involvement_salesforce_id
  Inner Join stg_alumni.ucinn_ascendv2__involvement_value__c ival
    On ival.id = stginv.ucinn_ascendv2__involvement_code__c
;

--------------------------------------
Cursor c_service_indicators Is
  Select
    ucinn_ascendv2__contact__c
      As constituent_salesforce_id
    , ucinn_ascendv2__service_indicator_name_auto_number__c
      As service_indicator_record_id
    , ap_business_unit__c
      As business_unit
    , ucinn_ascendv2__code_formula__c
      As service_indicator_code
    , ap_service_indicator_value_name__c
      As service_indicator
    , Case
        When lower(ucinn_ascendv2__is_active__c) = 'true'
          Then 'Y'
        Else 'N'
        End
      As active_ind
    , ucinn_ascendv2__comments__c
      As comments
    , ucinn_ascendv2__start_date__c
      As start_date
    , ucinn_ascendv2__end_date__c
      As end_date
    , etl_update_date
  From stg_alumni.ucinn_ascendv2__service_indicator__c
;

--------------------------------------
Cursor c_assignments Is
  Select
    assign.name
      As assignment_record_id
    , staff.id
      As staff_user_salesforce_id
    , staff.username
      As staff_username
    , staff.contactid
      As staff_constituent_salesforce_id
    , staff.name
      As staff_name
    , staff.isactive
      As staff_is_active
    , assign.ucinn_ascendv2__assignment_type__c
      As assignment_type
    , Case
        When assign.ucinn_ascendv2__assignment_type__c = 'Primary Relationship Manager'
          Then 'PRM'
        When assign.ucinn_ascendv2__assignment_type__c = 'Leadership Annual Gift Manager'
          Then 'LAGM'
        End
      As assignment_code
    , assign.ap_business_unit__c
      As assignment_business_unit      
    , Case When assign.ap_business_unit__c Like '%Kellogg%' Then 'Y' End
      As ksm_flag
    , assign.ucinn_ascendv2__contact__c
      As assigneee_salesforce_id
    , assign.ucinn_ascendv2__donor_id_formula__c
      As assignee_donor_id
    , assign.ucinn_ascendv2__contact_last_name_formula__c
      As assignee_last_name
    , assign.ucinn_ascendv2__stage_of_readiness_formula__c
      As assignee_stage
    , assign.ap_is_active__c
      As is_active_indicator
    , assign.ucinn_ascendv2__assignment_start_date__c
      As start_date
    , assign.ucinn_ascendv2__assignment_end_date__c
      As end_date
    , assign.etl_update_date
  From stg_alumni.ucinn_ascendv2__assignment__c assign
  Inner Join stg_alumni.user_tbl staff
    On staff.id = assign.ucinn_ascendv2__assigned_relationship_manager_user__c
;

--------------------------------------
Cursor c_proposals Is

  With
  
  opportunity_team_member As (
    Select
      otm.opportunityid
        As opportunity_salesforce_id
      , otm.id
        As opportunity_team_member_salesforce_id
      , otm.userid
        As team_member_user_id
      , otm.name
        As team_member_name
      , otm.teammemberrole
        As team_member_role
      , otm.ap_start_date__c
        As start_date
      , otm.ap_end_date__c
        As end_date
      , staff.isactive
        As staff_is_active
      , otm.ap_business_unit__c
        As business_unit
    From stg_alumni.opportunityteammember otm
    Left Join stg_alumni.user_tbl staff
      On staff.id = otm.userid
  )
  
  , last_pm As (
    Select
      opportunity_salesforce_id
      , max(team_member_user_id) keep(dense_rank First Order By end_date Desc, start_date Desc, team_member_role Asc, business_unit Asc, team_member_name Asc)
        As historical_pm_user_id
      , max(team_member_name) keep(dense_rank First Order By end_date Desc, start_date Desc, team_member_role Asc, business_unit Asc, team_member_name Asc)
        As historical_pm_name
      , max(team_member_role) keep(dense_rank First Order By end_date Desc, start_date Desc, team_member_role Asc, business_unit Asc, team_member_name Asc)
        As historical_pm_role
      , max(business_unit) keep(dense_rank First Order By end_date Desc, start_date Desc, team_member_role Asc, business_unit Asc, team_member_name Asc)
        As historical_business_unit
      , max(staff_is_active) keep(dense_rank First Order By end_date Desc, start_date Desc, team_member_role Asc, business_unit Asc, team_member_name Asc)
        As historical_is_active
    From opportunity_team_member
    Where team_member_role = 'Proposal Manager'
    Group By opportunity_salesforce_id
  )

  Select
    nullif(dpo.opportunity_salesforce_id, '-')
      As opportunity_salesforce_id
    , nullif(dpo.proposal_record_id, '-')
      As proposal_record_id
    , nullif(dpo.proposal_legacy_id, '-')
      As proposal_legacy_id
    , nullif(dpo.proposal_strategy_record_id, '-')
      As proposal_strategy_record_id
    , Case
        When nullif(fpo.constituent_donor_id, '-') Is Not Null
          Then fpo.constituent_donor_id
        Else nullif(fpo.organization_donor_id, '-')
        End
      As donor_id
    , dpo.proposal_active_indicator
    , dpo.proposal_stage
    , dpo.proposal_type
    , dpo.proposal_name
    , dpo.proposal_probability
    , dpo.proposal_amount
    , dpo.proposal_submitted_amount
    , dpo.proposal_anticipated_amount
    , dpo.proposal_funded_amount
    , dpo.proposal_created_date
    , dpo.proposal_submitted_date
    , dpo.proposal_close_date
    , nullif(dpo.proposal_payment_schedule, '-')
      As proposal_payment_schedule
    , nullif(dpo.proposal_designation_work_plan_units, '-')
      As proposal_designation_units
    , Case When dpo.proposal_designation_work_plan_units Like '%Kellogg%' Then 'Y' End
      As ksm_flag
    , nullif(dpo.active_proposal_manager_salesforce_id, '-')
      As active_proposal_manager_salesforce_id
    , nullif(dpo.active_proposal_manager_name, '-')
      As active_proposal_manager_name
    , nullif(dpo.active_proposal_manager_business_unit, '-')
      As active_proposal_manager_unit
    , last_pm.historical_pm_user_id
    , last_pm.historical_pm_name
    , last_pm.historical_pm_role
    , last_pm.historical_business_unit
      As historical_pm_business_unit
    , last_pm.historical_is_active
      As historical_pm_is_active
    , trunc(dpo.etl_update_date)
      As etl_update_date
  From dm_alumni.dim_proposal_opportunity dpo
  Inner Join last_pm
    On last_pm.opportunity_salesforce_id = dpo.opportunity_salesforce_id
  Inner Join dm_alumni.fact_proposal_opportunity fpo
    On fpo.opportunity_salesforce_id = dpo.opportunity_salesforce_id
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
Function tbl_mini_entity
  Return mini_entity Pipelined As
    -- Declarations
    e mini_entity;

  Begin
    Open c_mini_entity;
      Fetch c_mini_entity Bulk Collect Into e;
    Close c_mini_entity;
    For i in 1..(e.count) Loop
      Pipe row(e(i));
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
Function tbl_designation_detail
  Return designation_detail Pipelined As
    -- Declarations
    des designation_detail;

  Begin
    Open c_designation_detail;
      Fetch c_designation_detail Bulk Collect Into des;
    Close c_designation_detail;
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
Function tbl_payment
  Return payment Pipelined As
    -- Declarations
    pay payment;

  Begin
    Open c_payment;
      Fetch c_payment Bulk Collect Into pay;
    Close c_payment;
    For i in 1..(pay.count) Loop
      Pipe row(pay(i));
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

--------------------------------------
Function tbl_assignments
  Return assignments Pipelined As
    -- Declarations
    asn assignments;

  Begin
    Open c_assignments;
      Fetch c_assignments Bulk Collect Into asn;
    Close c_assignments;
    For i in 1..(asn.count) Loop
      Pipe row(asn(i));
    End Loop;
    Return;
  End;

--------------------------------------
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
  
End dw_pkg_base;
/
