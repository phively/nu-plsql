Create Or Replace Package rpt_pbh634.ksm_pkg Is

/*************************************************************************
Author  : PBH634
Created : 2/8/2017 5:43:38 PM
Purpose : Kellogg-specific package with lots of fun functions
Dependencies:
  v_addr_continents (view)
  mv_past_ksm_gos (materialized view)

Suggested naming convetions:
  Pure functions: [function type]_[description] e.g.
    math_mod
  Row-by-row retrieval (slow): get_[object type]_[action or description] e.g.
    get_entity_degrees_concat_ksm
    get_gift_source_donor_ksm
  Table or cursor retrieval (fast): tbl_[object type]_[action or description] e.g.
    tbl_alloc_annual_fund_ksm
    
*************************************************************************/

/*************************************************************************
Initial procedures
*************************************************************************/

/*************************************************************************
Public type declarations
*************************************************************************/

/* Allocation information */
Type allocation_info Is Record (
  allocation_code allocation.allocation_code%type
  , status_code allocation.status_code%type
  , short_name allocation.short_name%type
  , af_flag allocation.annual_sw%type
);

Type calendar Is Record (
  today date
  , yesterday date
  , yesterday_last_year date
  , ninety_days_ago date
  , curr_fy number
  , prev_fy_start date
  , curr_fy_start date
  , next_fy_start date
  , curr_py number
  , prev_py_start date
  , curr_py_start date
  , next_py_start date
  , prev_fy_today date
  , next_fy_today date
  , prev_week_start date
  , curr_week_start date
  , next_week_start date
  , prev_month_start date
  , curr_month_start date
  , next_month_start date
);

Type random_id Is Record (
  id_number entity.id_number%type
  , random_id entity.id_number%type
);

/* Degreed alumi, for entity_degrees_concat */
Type degreed_alumni Is Record (
  id_number entity.id_number%type
  , report_name entity.report_name%type
  , record_status_code entity.record_status_code%type
  , degrees_verbose varchar2(1024)
  , degrees_concat varchar2(512)
  , first_ksm_year degrees.degree_year%type
  , first_masters_year degrees.degree_year%type
  , last_masters_year degrees.degree_year%type
  , last_noncert_year degrees.degree_year%type
  , stewardship_years varchar2(80)
  , program tms_dept_code.short_desc%type
  , program_group varchar2(20)
  , program_group_rank number
  , class_section varchar2(80)
  , majors_concat varchar2(512)
);

/* Committee member list, for committee results */
Type committee_member Is Record (
  id_number committee.id_number%type
  , committee_code committee_header.committee_code%type
  , short_desc committee_header.short_desc%type
  , start_dt committee.start_dt%type
  , stop_dt committee.stop_dt%type
  , status tms_committee_status.short_desc%type
  , role tms_committee_role.short_desc%type
  , xcomment committee.xcomment%type
  , date_modified committee.date_modified%type
  , operator_name committee.operator_name%type
  , spouse_id_number entity.spouse_id_number%type
);

/* Geo code primary, for addresses */
Type geo_code_primary Is Record (
  id_number address.id_number%type
  , xsequence address.xsequence%type
  , addr_pref_ind address.addr_pref_ind%type
  , geo_codes varchar2(1024)
  , geo_code_primary geo_code.geo_code%type
  , geo_code_primary_desc geo_code.description%type
);

/* Household, for entity_households */
Type household Is Record (
  id_number entity.id_number%type
  , report_name entity.report_name%type
  , pref_mail_name entity.pref_mail_name%type
  , record_status_code entity.record_status_code%type
  , degrees_concat varchar2(512)
  , first_ksm_year degrees.degree_year%type
  , program varchar2(20)
  , program_group varchar2(20)
  , last_noncert_year degrees.degree_year%type
  , institutional_suffix entity.institutional_suffix%type
  , spouse_id_number entity.spouse_id_number%type
  , spouse_report_name entity.report_name%type
  , spouse_pref_mail_name entity.pref_mail_name%type
  , spouse_suffix entity.institutional_suffix%type
  , spouse_degrees_concat varchar2(512)
  , spouse_first_ksm_year degrees.degree_year%type
  , spouse_program varchar2(20)
  , spouse_program_group varchar2(20)
  , spouse_last_noncert_year degrees.degree_year%type
  , fmr_spouse_id entity.id_number%type
  , fmr_spouse_name entity.report_name%type
  , fmr_marital_status tms_marital_status.short_desc%type
  , household_id entity.id_number%type
  , household_primary varchar2(1)
  , household_record entity.record_type_code%type
  , person_or_org entity.person_or_org%type
  , household_name entity.pref_mail_name%type
  , household_rpt_name entity.report_name%type
  , household_spouse_id entity.id_number%type
  , household_spouse entity.pref_mail_name%type
  , household_spouse_rpt_name entity.report_name%type
  , household_list_first entity.id_number%type
  , household_list_second entity.id_number%type
  , household_suffix entity.institutional_suffix%type
  , household_spouse_suffix entity.institutional_suffix%type
  , household_ksm_year degrees.degree_year%type
  , household_masters_year degrees.degree_year%type
  , household_last_masters_year degrees.degree_year%type
  , household_program varchar2(20)
  , household_program_group varchar2(20)
  , xsequence address.xsequence%type
  , household_city address.city%type
  , household_state address.state_code%type
  , household_zip address.zipcode%type
  , household_geo_codes varchar2(512)
  , household_geo_primary geo_code.geo_code%type
  , household_geo_primary_desc geo_code.description%type
  , household_country tms_country.short_desc%type
  , household_continent varchar2(80)
);

/* Source donor, for gift_source_donor */
Type src_donor Is Record (
  tx_number nu_gft_trp_gifttrans.tx_number%type
  , id_number nu_gft_trp_gifttrans.id_number%type
  , degrees_concat varchar2(512)
  , person_or_org nu_gft_trp_gifttrans.person_or_org%type
  , associated_code nu_gft_trp_gifttrans.associated_code%type
  , credit_amount nu_gft_trp_gifttrans.credit_amount%type
);

/* University strategy */
Type university_strategy Is Record (
  prospect_id prospect.prospect_id%type
  , university_strategy task.task_description%type
  , strategy_sched_date task.sched_date%type
  , strategy_responsible varchar2(1024)
  , strategy_modified_date task.sched_date%type
  , strategy_modified_name entity.report_name%type
);

/* Numeric capacity */
Type numeric_capacity Is Record (
    rating_code tms_rating.rating_code%type
    , rating_desc tms_rating.short_desc%type
    , numeric_rating number
    , numeric_bin number
);

/* Modeled score */
Type modeled_score Is Record (
  id_number segment.id_number%type
  , segment_year segment.segment_year%type
  , segment_month segment.segment_month%type
  , segment_code segment.segment_code%type
  , description segment_header.description%type
  , score segment.xcomment%type
);

/* KLC member */
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

/* KSM staff */
Type ksm_staff Is Record (
  id_number entity.id_number%type
  , report_name entity.report_name%type
  , last_name entity.last_name%type
  , team varchar2(5)
  , former_staff varchar2(1)
  , job_title employment.job_title%type
  , employer employment.employer_unit%type
);

/* NU ARD current/past staff */
Type nu_ard_staff Is Record (
  id_number employment.id_number%type
  , report_name entity.report_name%type
  , job_title employment.job_title%type
  , employer_unit employment.employer_unit%type
  , job_status_code employment.job_status_code%type
  , primary_emp_ind employment.primary_emp_ind%type
  , start_dt employment.start_dt%type
  , stop_dt employment.stop_dt%type
);

/* Active prospect entities */
Type prospect_entity_active Is Record (
  prospect_id prospect.prospect_id%type
  , id_number entity.id_number%type
  , report_name entity.report_name%type
  , primary_ind prospect_entity.primary_ind%type
);

/* Employee record type for company queries */
Type employee Is Record (
  id_number entity.id_number%type
  , report_name entity.report_name%type
  , record_status tms_record_status.short_desc%type
  , institutional_suffix entity.institutional_suffix%type
  , degrees_concat varchar2(512)
  , first_ksm_year degrees.degree_year%type
  , program varchar2(20)
  , business_title nu_prs_trp_prospect.business_title%type
  , business_company varchar2(1024)
  , job_title varchar2(1024)
  , employer_name varchar2(1024)
  , business_city nu_prs_trp_prospect.business_city%type
  , business_state nu_prs_trp_prospect.business_state%type
  , business_country tms_country.short_desc%type
  , prospect_manager nu_prs_trp_prospect.prospect_manager%type
  , team nu_prs_trp_prospect.team%type
);

Type prospect_categories Is Record (
  prospect_id prospect.prospect_id%type
  , primary_ind prospect_entity.primary_ind%type
  , id_number entity.id_number%type
  , report_name entity.report_name%type
  , person_or_org entity.person_or_org%type
  , prospect_category_code tms_prospect_category.prospect_category_code%type
  , prospect_category tms_prospect_category.short_desc%type
);

/* Discounted pledge amounts */
Type plg_disc Is Record (
  pledge_number pledge.pledge_pledge_number%type
  , pledge_sequence pledge.pledge_sequence%type
  , prim_pledge_type primary_pledge.prim_pledge_type%type
  , prim_pledge_status primary_pledge.prim_pledge_status%type
  , status_change_date primary_pledge.status_change_date%type
  , proposal_id primary_pledge.proposal_id%type
  , pledge_comment primary_pledge.prim_pledge_comment%type
  , pledge_amount pledge.pledge_amount%type
  , pledge_associated_credit_amt pledge.pledge_associated_credit_amt%type
  , prim_pledge_amount primary_pledge.prim_pledge_amount%type
  , prim_pledge_amount_paid primary_pledge.prim_pledge_amount_paid%type
  , prim_pledge_remaining_balance primary_pledge.prim_pledge_amount%type
  , prim_pledge_original_amount primary_pledge.prim_pledge_original_amount%type
  , discounted_amt primary_pledge.prim_pledge_amount%type
  , legal primary_pledge.prim_pledge_amount%type
  , credit primary_pledge.prim_pledge_amount%type
  , recognition_credit pledge.pledge_amount%type
);

/* Entity transaction for credit */
Type trans_entity Is Record (
  id_number entity.id_number%type
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
);

/* Householdable transaction for credit */
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
  , hh_credit gift.gift_associated_amount%type
  , hh_recognition_credit gift.gift_associated_amount%type
);

/* Campaign transactions */
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

/* Special handling concat */
Type special_handling Is Record (
     id_number entity.id_number%type
     , spouse_id_number entity.spouse_id_number%type
     , special_handling_concat varchar2(1024)
     , spec_hnd_codes varchar2(1024)
     , mailing_list_concat varchar2(1024)
     , ml_codes varchar2(1024)
     , no_contact varchar2(1)
     , no_solicit varchar2(1)
     , no_release varchar2(1)
     , active_with_restrictions varchar2(1)
     , never_engaged_forever varchar2(1)
     , never_engaged_reunion varchar2(1)
     , has_opt_ins_opt_outs varchar2(1)
     , anonymous_donor varchar2(1)
     , exc_all_comm varchar2(1)
     , exc_all_sols varchar2(1)
     , no_phone_ind varchar2(1)
     , no_phone_sol_ind varchar2(1)
     , no_email_ind varchar2(1)
     , no_email_sol_ind varchar2(1)
     , no_mail_ind varchar2(1)
     , no_mail_sol_ind varchar2(1)
     , no_texts_ind varchar2(1)
     , no_texts_sol_ind varchar2(1)
     , ksm_stewardship_issue varchar2(1)
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type t_varchar2_long Is Table Of varchar2(512);
Type t_allocation Is Table Of allocation_info;
Type t_calendar Is Table Of calendar;
Type t_random_id Is Table Of random_id;
Type t_degreed_alumni Is Table Of degreed_alumni;
Type t_committee_members Is Table Of committee_member;
Type t_geo_code_primary Is Table Of geo_code_primary;
Type t_households Is Table Of household;
Type t_src_donors Is Table Of src_donor;
Type t_university_strategy Is Table Of university_strategy;
Type t_numeric_capacity Is Table Of numeric_capacity;
Type t_modeled_score Is Table Of modeled_score;
Type t_klc_members Is Table Of klc_member;
Type t_ksm_staff Is Table Of ksm_staff;
Type t_prospect_entity_active Is Table Of prospect_entity_active;
Type t_nu_ard_staff Is Table Of nu_ard_staff;
Type t_employees Is Table Of employee;
Type t_prospect_categories Is Table Of prospect_categories;
Type t_plg_disc Is Table Of plg_disc;
Type t_trans_entity Is Table Of trans_entity;
Type t_trans_household Is Table Of trans_household;
Type t_trans_campaign Is Table Of trans_campaign;
Type t_special_handling Is Table Of special_handling;

/*************************************************************************
Public constant declarations
*************************************************************************/

/* Start months */
fy_start_month Constant number := 9; -- fiscal start month, 9 = September
py_start_month Constant number := 6; -- performance start month, 5 = May
py_start_month_pre_py21 Constant number := 5; -- performance start month was 5 = May until PY2021

/* Committees */
committee_gab Constant committee.committee_code%type := 'U'; -- Kellogg Global Advisory Board committee code
committee_kac Constant committee.committee_code%type := 'KACNA'; -- Kellogg Alumni Council committee code
committee_phs Constant committee.committee_code%type := 'KPH'; -- KSM Pete Henderson Society
committee_KFN Constant committee.committee_code%type := 'KFN'; -- Kellogg Finance Network code
committee_CorpGov Constant committee.committee_code%type := 'KCGN'; -- KSM Corporate Governance Network code
committee_WomenSummit Constant committee.committee_code%type := 'KGWS'; -- KSM Global Women's Summit code
committee_DivSummit Constant committee.committee_code%type := 'KCDO'; -- KSM chief Diversity Officer Summit code
committee_RealEstCouncil Constant committee.committee_code%type := 'KREAC'; -- Real Estate Advisory Council code
committee_AMP Constant committee.committee_code%type := 'KAMP'; -- AMP Advisory Council code
committee_trustee Constant committee.committee_code%type := 'TBOT'; -- NU Board of Trustees code
committee_healthcare Constant committee.committee_code%type := 'HAK'; -- Healthcare at Kellogg Advisory Council
committee_WomensLeadership Constant committee.committee_code%type := 'KWLC'; -- Women's Leadership Advisory Council
committee_KALC Constant committee.committee_code%type := 'KALC'; -- Kellogg Admissions Leadership Council
committee_kic Constant committee.committee_code%type := 'KIC'; -- Kellogg Inclusion Coalition

/*************************************************************************
Public variable declarations
*************************************************************************/

/*************************************************************************
Public function declarations
*************************************************************************/

/* Mathematical modulo operator */
Function math_mod(
  m In number
  , n In number
) Return number; -- m % n
  
/* Rewritten to_date to return NULL for invalid dates */
Function to_date2(
  str In varchar2
  , format In varchar2 Default 'yyyymmdd'
) Return date;

/* Rewritten to_number to return NULL for invalid strings */
Function to_number2(
  str In varchar2
) Return number;

/* Parse yyyymmdd string into a date after checking for invalid terms */
Function date_parse(
  str In varchar2
  , dt In date Default current_date()
) Return date;

/* Fiscal year to date indicator */
Function fytd_indicator(
  dt In date
  , day_offset In number Default -1 -- default offset in days; -1 means up to yesterday is year-to-date, 0 up to today, etc.
) Return character; -- Y or N

/* Function to return private numeric constants */
Function get_numeric_constant(
  const_name In varchar2 -- Name of constant to retrieve
) Return number Deterministic;

/* Compute fiscal or performance quarter from date */
Function get_quarter(
  dt In date
  , fisc_or_perf In varchar2 Default 'fiscal' -- 'f'iscal or 'p'erformance quarter
) Return number; -- Quarter, 1-4

/* Takes a date and returns the fiscal year */
-- Date version
Function get_fiscal_year(
  dt In date
) Return number; -- Fiscal year part of date
-- String version
Function get_fiscal_year(
  dt In varchar2
  , format In varchar2 Default 'yyyy/mm/dd'
) Return number; -- Fiscal year part of date

/* Takes a date and returns the performance year */
-- Date version
Function get_performance_year(
  dt In date
) Return number; -- Performance year part of date

/* Quick SQL-only retrieval of KSM degrees concat */
Function get_entity_degrees_concat_fast(
  id In varchar2
) Return varchar2;

/* Return specified master address information, defined as preferred if available, else home if available, else business.
   The field parameter should match an address table field or tms table name, e.g. street1, state_code, country, etc. */
Function get_entity_address(
  id In varchar2 -- entity id_number
  , field In varchar2 -- address item to pull, including city, state_code, country, etc.
  , debug In boolean Default FALSE -- if TRUE, debug output is printed via dbms_output.put_line()
) Return varchar2; -- matched address piece

/* Take receipt number and return id_number of entity to receive primary Kellogg gift credit */
Function get_gift_source_donor_ksm(
  receipt In varchar2
  , debug In boolean Default FALSE -- if TRUE, debug output is printed via dbms_output.put_line()
) Return varchar2; -- entity id_number

/* Take a string containing a dollar amount and extract the (first) numeric value */
Function get_number_from_dollar(
  str In varchar2
) Return number;

/* Take entity ID and return officer or evaluation rating bin from nu_prs_trp_prospect */
Function get_prospect_rating_numeric(
  id In varchar2
) Return number;

/* Binned version of the results from get_prospect_rating_numeric */
Function get_prospect_rating_bin(
  id In varchar2
) Return number;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

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

Examples: 
Select ksm_af.*
From table(rpt_pbh634.ksm_pkg.tbl_alloc_annual_fund_ksm) ksm_af;
Select cal.*
From table(rpt_pbh634.ksm_pkg.tbl_current_calendar) cal;
*************************************************************************/

/* Return allocations, both active and historical, as a pipelined function */
Function tbl_alloc_annual_fund_ksm
  Return t_allocation Pipelined; -- returns list of matching values

Function tbl_alloc_curr_use_ksm
  Return t_allocation Pipelined; -- returns list of matching values

/* Return current calendar object */
Function tbl_current_calendar
  Return t_calendar Pipelined;

/* Return random IDs */
Function tbl_random_id
  Return t_random_id Pipelined;

/* Return pipelined table of entity_degrees_concat_ksm */
Function tbl_entity_degrees_concat_ksm
  Return t_degreed_alumni Pipelined;

/* Return pipelined table of primary geo codes per address */
Function tbl_geo_code_primary
  Return t_geo_code_primary Pipelined;

/* Return pipelined table of entity_households_ksm */
Function tbl_entity_households_ksm
  Return t_households Pipelined;
  
/* Return pipelined table of company employees with Kellogg degrees
   N.B. uses matches pattern, user beware! */
Function tbl_entity_employees_ksm (company In varchar2)
  Return t_employees Pipelined;

/* Return pipelined table of Top 150/300 KSM prospects */
Function tbl_entity_top_150_300
  Return t_prospect_categories Pipelined;
  
/* Return pipelined table of KLC members */
Function tbl_klc_history
  Return t_klc_members Pipelined;

/* Return pipelined table of frontline KSM staff */
Function tbl_frontline_ksm_staff
  Return t_ksm_staff Pipelined;

/* Return pipelined table of active prospect entities */
Function tbl_prospect_entity_active
  Return t_prospect_entity_active Pipelined;

/* Return pipelined table of current and past NU ARD staff, with most recent NU job */
Function tbl_nu_ard_staff
  Return t_nu_ard_staff Pipelined;

/* Returns pipelined table of Kellogg transactions with household info */
Function plg_discount
  Return t_plg_disc Pipelined;

Function tbl_gift_credit
  Return t_trans_entity Pipelined;

Function tbl_gift_credit_ksm
  Return t_trans_entity Pipelined;
  
Function tbl_gift_credit_hh_ksm
  Return t_trans_household Pipelined;

Function tbl_gift_credit_campaign
  Return t_trans_campaign Pipelined;
    
Function tbl_gift_credit_hh_campaign
--    Return t_trans_campaign_hh Pipelined;
  Return t_trans_household Pipelined;

/* Return pipelined tasks */
Function tbl_university_strategy
  Return t_university_strategy Pipelined;

/* Return pipelined numeric ratings */
Function tbl_numeric_capacity_ratings
  Return t_numeric_capacity Pipelined;

/* Return pipelined model scores */
Function tbl_model_af_10k (
  model_year In integer
  , model_month In integer
) Return t_modeled_score Pipelined;

Function tbl_model_mg_identification (
  model_year In integer
  , model_month In integer
) Return t_modeled_score Pipelined;

Function tbl_model_mg_prioritization (
  model_year In integer
  , model_month In integer
) Return t_modeled_score Pipelined;

/* Return pipelined special handling preferences */
Function tbl_special_handling_concat
    Return t_special_handling Pipelined;

/* Return pipelined table of committee members */
Function tbl_committee_gab
  Return t_committee_members Pipelined;

Function tbl_committee_phs
  Return t_committee_members Pipelined;
    
Function tbl_committee_kac
  Return t_committee_members Pipelined;

Function tbl_committee_KFN
  Return t_committee_members Pipelined;
  
 Function tbl_committee_CorpGov
  Return t_committee_members Pipelined;
  
 Function tbl_committee_WomenSummit
  Return t_committee_members Pipelined;
  
 Function tbl_committee_DivSummit
  Return t_committee_members Pipelined;
  
 Function tbl_committee_RealEstCouncil
  Return t_committee_members Pipelined;
  
 Function tbl_committee_AMP
  Return t_committee_members Pipelined;

Function tbl_committee_trustee
  Return t_committee_members Pipelined;

Function tbl_committee_healthcare
  Return t_committee_members Pipelined;
  
Function tbl_committee_WomensLeadership
  Return t_committee_members Pipelined;

Function tbl_committee_KALC
  Return t_committee_members Pipelined;

Function tbl_committee_kic
  Return t_committee_members Pipelined;

/*************************************************************************
End of package
*************************************************************************/

End ksm_pkg;
/
Create Or Replace Package Body rpt_pbh634.ksm_pkg Is

/*************************************************************************
Private cursor tables -- data definitions; update indicated sections as needed
*************************************************************************/

/* Definition of current and historical Kellogg Annual Fund allocations
   2017-02-09 */
Cursor ct_alloc_annual_fund_ksm Is
  Select Distinct
    allocation_code
    , status_code
    , short_name
    , 'Y' As af_flag
  From allocation
  Where
    -- KSM af-flagged allocations
    (annual_sw = 'Y' And alloc_school = 'KM')
    -- Include additional fields
    Or allocation_code In (
      /************ UPDATE BELOW HERE ************/
        '3203003665401GFT' -- Expendable Excellence Grant (JRF)
      , '3203004227201GFT' -- Expendable Excellence Grant (DC)
      , '3203000861201GFT' -- Real Estate Conference
      , '3203004707901GFT' -- GIM Trip Scholarship (LS)
      , '3203002954201GFT' -- KSM Student Club Support
      , '3303001899301GFT' -- KSM Gift-In-Kind
      , '3203000859901GFT' -- Center for Nonprofit Management
      , '3203004959801GFT' -- Collaboration Plaza fund (MS -- building support)
      , '3203004993001GFT' -- GIM Trip Scholarships (general)
      , '3203003655501GFT' -- EMP Scholarships
      , '3203004984101GFT' -- Deloitte Scholarship
      , '3203005137401GFT' -- Expendable Excellence Grant (TMS)
      , '3203005214601GFT' -- Class of 1989 Scholarship
      , '3203005228501GFT' -- KFN Scholarship
      , '3203005334201GFT' -- KSM 1Y Class of 2019 Scholar
      , '3203005590301GFT' -- KSM Student Assistance Fund
      /************ UPDATE ABOVE HERE ************/
    )
  ;

/* Definition of frontline gift officers
   2017-09-26 */
Cursor ct_frontline_ksm_staff Is
  With
  staff As (
    -- First query block pulls from past KSM staff materialized view
    Select
      id_number
      , team
      , Case When stop_dt Is Not Null Then 'Y' End As former_staff
    From mv_past_ksm_gos
  )
  -- Job title information
  , employ As (
    Select
      employment.id_number
      , job_title
      , employer_unit As employer
    From employment
    Inner Join staff On staff.id_number = employment.id_number
    Where job_status_code = 'C'
    And primary_emp_ind = 'Y'
  )
  -- Main query
  Select
    staff.id_number
    , entity.report_name
    , entity.last_name
    , staff.team
    , staff.former_staff
    , employ.job_title
    , employ.employer
  From staff
  Inner Join entity On entity.id_number = staff.id_number
  Left Join employ on employ.id_number = staff.id_number
  ;

/* Definition of numeric capacity ratings
   2018-04-27 */
Cursor ct_numeric_capacity_ratings Is
  With
  -- Extract numeric ratings from tms_rating.short_desc
  numeric_rating As (
    Select
      rating_code
      , short_desc As rating_desc
      , Case
          When rating_code = 0 Then 0
          Else rpt_pbh634.ksm_pkg.get_number_from_dollar(short_desc) / 1000000
        End As numeric_rating
    From tms_rating
  )
  -- Main query
  Select
    rating_code
    , rating_desc
    , numeric_rating
    , Case
        When numeric_rating >= 10 Then 10
        When numeric_rating = 0.25 Then 0.1
        When numeric_rating < 0.1 Then 0
        Else numeric_rating
      End As numeric_bin
  From numeric_rating
  ;

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

/* Definition of Kellogg Current Use allocations for Annual Giving
   2017-07-11 */
Cursor c_alloc_curr_use_ksm Is
  With
  ksm_af As (
    Select *
    From table(tbl_alloc_annual_fund_ksm)
  )
  Select Distinct
    alloc.allocation_code
    , alloc.status_code
    , alloc.short_name
    , nvl(af_flag, 'N') As af_flag
  From allocation alloc
  Left Join ksm_af On ksm_af.allocation_code = alloc.allocation_code
  Where (agency = 'CRU' And alloc_school = 'KM'
      And alloc.allocation_code <> '3303002283701GFT' -- Exclude Envision building gifts
    )
    Or alloc.allocation_code In ksm_af.allocation_code -- Include AF allocations that happen to not match criteria
  ;

/* Compiles useful dates together for use in other functions.
    Naming convention:
    curr_, or no prefix, for current year, e.g. today, curr_fy
    prev_fy, prev_fy2, prev_fy3, etc. for 1, 2, 3 years ago, e.g. prev_fy_today
    next_fy, next_fy2, next_fy3, etc. for 1, 2, 3 years in the future, e.g. next_fy_today
   2017-02-03 */
Cursor c_current_calendar (fy_start_month In integer, py_start_month In integer) Is
  With
  -- Store today from sysdate and calculate current fiscal year; always year + 1 unless the FY starts in Jan
  curr_date As (
    Select
      trunc(sysdate) As today
      -- Current fiscal year; uses fy_start_month constant
      , get_fiscal_year(sysdate)
        As yr
      -- Current performance year; uses py_start_month constant
      , get_performance_year(sysdate)
        As perf_yr
      -- Correction for starting after January
      , Case
        When fy_start_month != 1 Then 1 Else 0
      End As yr_dif
    From DUAL
  )
  -- Final table with definitions
  Select
    -- Current day
    curr_date.today As today
    -- Yesterday
    , curr_date.today - 1 As yesterday
    , add_months(curr_date.today - 1, -12) As yesterday_last_year
    -- 90 days ago (for clearance)
    , curr_date.today - 90 As ninety_days_ago
    -- Current fiscal year
    , curr_date.yr As curr_fy
    -- Start of fiscal year objects
    , to_date(fy_start_month || '/01/' || (curr_date.yr - yr_dif - 1), 'mm/dd/yyyy')
      As prev_fy_start
    , to_date(fy_start_month || '/01/' || (curr_date.yr - yr_dif + 0), 'mm/dd/yyyy')
      As curr_fy_start
    , to_date(fy_start_month || '/01/' || (curr_date.yr - yr_dif + 1), 'mm/dd/yyyy')
      As next_fy_start
    -- Current performance year
    , curr_date.perf_yr As curr_py
    -- Start of performance year objects
    -- Previous PY correction for 2020
    , Case
        When perf_yr - 1 <= 2020
          Then to_date(py_start_month_pre_py21 || '/01/' || (curr_date.perf_yr - yr_dif - 1), 'mm/dd/yyyy')
        Else to_date(py_start_month || '/01/' || (curr_date.perf_yr - yr_dif - 1), 'mm/dd/yyyy')
        End
      As prev_py_start
    , Case
        When perf_yr <= 2020
          Then to_date(py_start_month_pre_py21 || '/01/' || (curr_date.perf_yr - yr_dif + 0), 'mm/dd/yyyy')
        Else to_date(py_start_month || '/01/' || (curr_date.perf_yr - yr_dif + 0), 'mm/dd/yyyy')
        End
      As curr_py_start
    , Case
        When perf_yr + 1 <= 2020
          Then to_date(py_start_month_pre_py21 || '/01/' || (curr_date.perf_yr - yr_dif + 1), 'mm/dd/yyyy')
        Else to_date(py_start_month || '/01/' || (curr_date.perf_yr - yr_dif + 1), 'mm/dd/yyyy')
        End
      As next_py_start
    -- Year-to-date objects
    , add_months(trunc(sysdate), -12) As prev_fy_today
    , add_months(trunc(sysdate), 12) As next_fy_today
    -- Start of week objects
    , trunc(sysdate, 'IW') - 7 As prev_week_start
    , trunc(sysdate, 'IW') As curr_week_start
    , trunc(sysdate, 'IW') + 7 As next_week_start
    -- Start of month objects
    , add_months(trunc(sysdate, 'Month'), -1) As prev_month_start
    , add_months(trunc(sysdate, 'Month'), 0) As curr_month_start
    , add_months(trunc(sysdate, 'Month'), 1) As next_month_start
  From curr_date
  ;

/* Random ID generator using dbms_random
   2020-02-11 */
Cursor c_random_id Is
  With

  -- Random sort of entity table
  random_seed As (
    Select
      id_number
      , dbms_random.value rv
    From entity
    Order By dbms_random.value
  )

  -- Relabel id_number with row number from random sort
  Select
    id_number
    , rownum As random_id
  From random_seed
  ;

/* Definition of current Kellogg committee members
   2017-03-01 */
Cursor c_committee_members (my_committee_cd In varchar2) Is
  Select
    comm.id_number
    , comm.committee_code
    , hdr.short_desc
    , comm.start_dt
    , comm.stop_dt
    , tms_status.short_desc As status
    , tms_role.short_desc As role
    , comm.xcomment
    , comm.date_modified
    , comm.operator_name
    , trim(entity.spouse_id_number) As spouse_id_number
  From committee comm
  Inner Join entity
    On entity.id_number = comm.id_number
  Left Join tms_committee_status tms_status On comm.committee_status_code = tms_status.committee_status_code
  Left Join tms_committee_role tms_role On comm.committee_role_code = tms_role.committee_role_code
  Left Join committee_header hdr On comm.committee_code = hdr.committee_code
  Where comm.committee_code = my_committee_cd
    And comm.committee_status_code In ('C', 'A') -- 'C'urrent or 'A'ctive; 'A' is deprecated
  ;

/* Definition of Kellogg degrees concatenated
   2017-02-15 */
Cursor c_entity_degrees_concat_ksm Is
  With
  -- Stewardship concatenated years; uses Distinct to de-dupe multiple degrees in one year
  stwrd_yrs As (
    Select Distinct
      id_number
      , degree_year
      , trim('''' || substr(trim(degree_year), -2)) As degree_yr
    From degrees
    Where institution_code = '31173' -- Northwestern institution code
      And school_code In ('KSM', 'BUS') -- Kellogg and College of Business school codes
      And degree_year <> ' ' -- Exclude rows with blank year
      And non_grad_code <> 'N' -- Exclude non-grads
  )
  , stwrd_deg As (
    Select Distinct
      id_number
      , Listagg(degree_yr, ', ') Within Group (Order By degree_year Asc) As stewardship_years
    From stwrd_yrs
    Where degree_year <> ''''
    Group By id_number
  )
  -- Concatenated degrees subqueries
  , deg_data As (
    Select
      id_number
      , degree_year
      , non_grad_code
      , Case When non_grad_code = 'N' Then 'Nongrad ' End As nongrad
      , Case When non_grad_code = 'N' Then 'NONGRD ' End As nongrd
      , degrees.degree_level_code
      , tms_degree_level.short_desc As degree_level
      , degrees.degree_code
      , tms_degrees.short_desc As degree_desc
      , degrees.school_code
      , degrees.dept_code
      , tms_dept_code.short_desc As dept_desc
      , degrees.division_code
      , tms_division.short_desc As division_desc
      , Case
          When degrees.dept_code = '01MDB' Then 'MDMBA'
          When degrees.dept_code Like '01%' Then substr(degrees.dept_code, 3)
          When degrees.dept_code = '13JDM' Then 'JDMBA'
          When degrees.dept_code = '13LLM' Then 'LLM'
          When degrees.dept_code Like '41%' Then substr(degrees.dept_code, 3)
          When degrees.dept_code = '95BCH' Then 'BCH'
          When degrees.dept_code = '96BEV' Then 'BEV'
          When degrees.dept_code In ('AMP', 'AMPI', 'EDP', 'KSMEE') Then degrees.dept_code
          When degrees.dept_code = '0000000' Then ''
          Else tms_dept_code.short_desc
        End As dept_short_desc
      , class_section
      , tms_class_section.short_desc As class_section_desc
      -- Concatenated majors; separate by , within a single degree
      , trim(
          trim(
            m1.short_desc ||
            Case When m2.short_desc Is Not Null Then ', ' End ||
            m2.short_desc
          ) || Case When m3.short_desc Is Not Null Then ', ' End ||
          m3.short_desc
        ) As majors
    -- Table joins, etc.
    From degrees
    Left Join tms_class_section -- For class section short_desc
      On degrees.class_section = tms_class_section.section_code
    Left Join tms_dept_code -- For department short_desc
      On degrees.dept_code = tms_dept_code.dept_code
    Left Join tms_division -- For division short_desc
      On degrees.division_code = tms_division.division_code
    Left Join tms_degree_level -- For degree level short_desc
      On degrees.degree_level_code = tms_degree_level.degree_level_code
    Left Join tms_degrees -- For degreee short_desc (to replace degree_code)
      On degrees.degree_code = tms_degrees.degree_code
    -- Major codes
    Left Join tms_majors m1
      On m1.major_code = degrees.major_code1
    Left Join tms_majors m2
      On m2.major_code = degrees.major_code2
    Left Join tms_majors m3
      On m3.major_code = degrees.major_code3
    Where institution_code = '31173' -- Northwestern institution code
      And degrees.school_code In ('KSM', 'BUS') -- Kellogg and College of Business school codes
  )
  -- Listagg all degrees, including incomplete
  , concat As (
    Select
      id_number
      -- Verbose degrees
      , Listagg(
          trim(degree_year || ' ' || nongrad || degree_level || ' ' || degree_desc || ' ' || school_code ||
            ' ' || dept_desc || ' ' || class_section_desc)
          , '; '
        ) Within Group (Order By degree_year) As degrees_verbose
      -- Terse degrees
      , Listagg(
          trim(degree_year || ' ' || nongrd || degree_code || ' ' || school_code || ' ' || dept_short_desc ||
            -- Class section code
            ' ' || class_section)
          , '; '
        ) Within Group (Order By degree_year) As degrees_concat
      -- Class sections
      , Listagg(
          trim(Case When trim(class_section) Is Not Null Then dept_short_desc End || ' ' || class_section)
          , '; '
        ) Within Group (Order By degree_year) As class_section
      -- Majors
      , Listagg(
        trim(majors)  
        , '; '
      ) Within Group (Order By degree_year) As majors_concat
      -- First Kellogg year; exclude non-grad years
      , min(trim(Case When non_grad_code = 'N' Then NULL Else degree_year End))
        As first_ksm_year
      -- First MBA or other Master's year; exclude non-grad years
      , min(Case
          When degree_level_code = 'M' -- Master's level
            Or degree_code In('MBA', 'MMGT', 'MS', 'MSDI', 'MSHA', 'MSMS') -- In case of data errors
            Then trim(Case When non_grad_code = 'N' Then NULL Else degree_year End)
          Else NULL
        End)
        As first_masters_year
      , max(Case
          When degree_level_code = 'M' -- Master's level
            Or degree_code In('MBA', 'MMGT', 'MS', 'MSDI', 'MSHA', 'MSMS') -- In case of data errors
            Then trim(Case When non_grad_code = 'N' Then NULL Else degree_year End)
          Else NULL
        End)
        As last_masters_year
      -- Last non-certificate year, e.g. for young alumni status, excluding non-grad years
      , max(Case
          When degree_level_code In('B', 'D', 'M')
          Then trim(Case When non_grad_code = 'N' Then NULL Else degree_year End)
          Else NULL
        End)
        As last_noncert_year
      From deg_data
      Group By id_number
    )
    -- Completed degrees only
    -- ***** IMPORTANT: If updating, update concat.degrees_concat above as well *****
    , clean_concat As (
      Select
        id_number
        -- Verbose degrees
      , Listagg(
          trim(degree_year || ' ' || nongrad || degree_level || ' ' || degree_desc || ' ' || school_code ||
            ' ' || dept_desc || ' ' || class_section_desc)
          , '; '
        ) Within Group (Order By degree_year) As clean_degrees_verbose
        -- Terse degrees
        , Listagg(
          trim(degree_year || ' ' || nongrd || degree_code || ' ' || school_code || ' ' || dept_short_desc ||
            -- Class section code
            ' ' || class_section)
          , '; '
        ) Within Group (Order By degree_year) As clean_degrees_concat
      From deg_data
      Where non_grad_code = ' ' Or non_grad_code Is Null
      Group By id_number
    )
    -- Extract program
    , prg As (
      Select
        concat.id_number
        , Case
            -- Account for certificate degree level/degree program mismatch by choosing exec ed
            When last_noncert_year Is Null And clean_degrees_concat Is Not Null Then
              Case
                When clean_degrees_concat Like '%KSM AEP%' Then 'CERT-AEP'
                When clean_degrees_concat Like '%KSMEE%' Then 'EXECED'
                When clean_degrees_concat Like '%CERT%' Then 'EXECED'
                When clean_degrees_concat Like '%Institute for Mgmt%' Then 'EXECED'
                When clean_degrees_concat Like '%LLM%' Then 'CERT-LLM'
                When clean_degrees_verbose Like '%Certificate%' Then 'CERT'
                Else 'EXECED'
              End
            -- People who have a completed degree
            -- ***** IMPORTANT: Keep in same order as below *****
            When clean_degrees_concat Like '%KGS2Y%' Then 'FT-2Y'
            When clean_degrees_concat Like '%KGS1Y%' Then 'FT-1Y'
            When clean_degrees_concat Like '%JDMBA%' Then 'FT-JDMBA'
            When clean_degrees_concat Like '%MMM%' Then 'FT-MMM'
            When clean_degrees_concat Like '%MDMBA%' Then 'FT-MDMBA'
            When clean_degrees_concat Like '%KSM KEN%' Then 'FT-KENNEDY'
            When clean_degrees_concat Like '%KSM TMP%' Then 'TMP'
            When clean_degrees_concat Like '%KSM PTS%' Then 'TMP-SAT'
            When clean_degrees_concat Like '%KSM PSA%' Then 'TMP-SATXCEL'
            When clean_degrees_concat Like '%KSM PTA%' Then 'TMP-XCEL'
            When clean_degrees_concat Like '%KSM NAP%' Then 'EMP-IL'
            When clean_degrees_concat Like '%KSM WHU%' Then 'EMP-GER'
            When clean_degrees_concat Like '%KSM SCH%' Then 'EMP-CAN'
            When clean_degrees_concat Like '%KSM LAP%' Then 'EMP-FL'
            When clean_degrees_concat Like '%KSM HK%' Then 'EMP-HK'
            When clean_degrees_concat Like '%KSM JNA%' Then 'EMP-JAN'
            When clean_degrees_concat Like '%KSM RU%' Then 'EMP-ISR'
            When clean_degrees_concat Like '%KSM PKU%' Then 'EMP-CHI'
            When clean_degrees_concat Like '% EMP%' Then 'EMP'
            When clean_degrees_concat Like '%KGS%' Then 'FT'
            When clean_degrees_concat Like '%BEV%' Then 'FT-EB'
            When clean_degrees_concat Like '%BCH%' Then 'FT-CB'
            When clean_degrees_concat Like '%PHD%' Then 'PHD'
            When clean_degrees_concat Like '%KSM AEP%' Then 'CERT-AEP'
            When clean_degrees_concat Like '%KSMEE%' Then 'EXECED'
            When clean_degrees_concat Like '%MBA %' Then 'FT'
            When clean_degrees_concat Like '%CERT%' Then 'EXECED'
            When clean_degrees_concat Like '%Institute for Mgmt%' Then 'EXECED'
            When clean_degrees_concat Like '%MS %' Then 'FT-MS'
            When clean_degrees_concat Like '%LLM%' Then 'CERT-LLM'
            When clean_degrees_concat Like '%MMGT%' Then 'FT-MMGT'
            When clean_degrees_verbose Like '%Certificate%' Then 'CERT'
            -- People who don't have a completed degree
            -- ***** IMPORTANT: Keep in same order as above *****
            When degrees_concat Like '%KGS2Y%' Then 'FT-2Y NONGRD'
            When degrees_concat Like '%KGS1Y%' Then 'FT-1Y NONGRD'
            When degrees_concat Like '%JDMBA%' Then 'FT-JDMBA NONGRD'
            When degrees_concat Like '%MMM%' Then 'FT-MMM NONGRD'
            When degrees_concat Like '%MDMBA%' Then 'FT-MDMBA NONGRD'
            When degrees_concat Like '%KSM KEN%' Then 'FT-KENNEDY NONGRD'
            When degrees_concat Like '%KSM TMP%' Then 'TMP NONGRD'
            When degrees_concat Like '%KSM PTS%' Then 'TMP-SAT NONGRD'
            When degrees_concat Like '%KSM PSA%' Then 'TMP-SATXCEL NONGRD'
            When degrees_concat Like '%KSM PTA%' Then 'TMP-XCEL NONGRD'
            When degrees_concat Like '% EMP%' Then 'EMP NONGRD'
            When degrees_concat Like '%KSM NAP%' Then 'EMP-IL NONGRD'
            When degrees_concat Like '%KSM WHU%' Then 'EMP-GER NONGRD'
            When degrees_concat Like '%KSM SCH%' Then 'EMP-CAN NONGRD'
            When degrees_concat Like '%KSM LAP%' Then 'EMP-FL NONGRD'
            When degrees_concat Like '%KSM HK%' Then 'EMP-HK NONGRD'
            When degrees_concat Like '%KSM JNA%' Then 'EMP-JAN NONGRD'
            When degrees_concat Like '%KSM RU%' Then 'EMP-ISR NONGRD'
            When degrees_concat Like '%KGS%' Then 'FT NONGRD'
            When degrees_concat Like '%BEV%' Then 'FT-EB NONGRD'
            When degrees_concat Like '%BCH%' Then 'FT-CB NONGRD'
            When degrees_concat Like '%PHD%' Then 'PHD NONGRD'
            When degrees_concat Like '%KSM AEP%' Then 'CERT-AEP NONGRD'
            When degrees_concat Like '%KSMEE%' Then 'EXECED NONGRD'
            When degrees_concat Like '%MBA %' Then 'FT NONGRD'
            When degrees_concat Like '%CERT%' Then 'EXECED NONGRD'
            When degrees_concat Like '%Institute for Mgmt%' Then 'EXECED NONGRD'
            When degrees_concat Like '%MS %' Then 'FT-MS NONGRD'
            When degrees_concat Like '%LLM%' Then 'CERT-LLM NONGRD'
            When degrees_concat Like '%MMGT%' Then 'FT-MMGT NONGRD'
            When degrees_verbose Like '%Certificate%' Then 'CERT NONGRD'
            Else 'UNK' -- Unable to determine program
          End As program
      From concat
      Left Join clean_concat On concat.id_number = clean_concat.id_number
    )
    -- Final results
    Select
      concat.id_number
      , entity.report_name
      , entity.record_status_code
      , degrees_verbose
      , degrees_concat
      , first_ksm_year
      , first_masters_year
      , last_masters_year
      , last_noncert_year
      , stwrd_deg.stewardship_years
      , prg.program
      -- program_group and program_group_rank; make sure to keep entries in the same order
      , Case
          When program Like '%NONGRD%' Then 'NONGRD'
          When program Like 'FT%' Then  'FT'
          When program Like 'TMP%' Then 'TMP'
          When program Like 'EMP%' Then 'EMP'
          When program Like 'PHD%' Then 'PHD'
          When program Like 'EXEC%' Or program Like 'CERT%' Then 'EXECED'
          Else program
        End As program_group
      , Case
          When program Like '%NONGRD%' Then 100000
          When program Like 'FT%' Then 10
          When program Like 'TMP%' Then 20
          When program Like 'EMP%' Then 30
          When program Like 'PHD%' Then 40
          When program Like 'EXEC%' Or program Like 'CERT%' Then 100
          Else 9999999999
        End As program_group_rank
      , class_section
      , majors_concat
    From concat
    Inner Join entity On entity.id_number = concat.id_number
    Inner Join prg On concat.id_number = prg.id_number
    Left Join stwrd_deg On stwrd_deg.id_number = concat.id_number
    ;

/* Definition of Kellogg gift source donor
   2017-02-27 */
Cursor c_source_donor_ksm (receipt In varchar2) Is
  Select
    gft.tx_number
    , gft.id_number
    , get_entity_degrees_concat_fast(id_number) As ksm_degrees
    , gft.person_or_org
    , gft.associated_code
    , gft.credit_amount
  From nu_gft_trp_gifttrans gft
  Where gft.tx_number = receipt
    And associated_code Not In ('H', 'M') -- Exclude In Honor Of and In Memory Of from consideration
  -- People with earlier KSM degree years take precedence over those with later ones
  -- People with smaller ID numbers take precedence over those with larger oens
  Order By
    get_entity_degrees_concat_fast(id_number) Asc
    , id_number Asc
  ;

/* Definition of primary geo code
   2019-11-05 */
Cursor c_geo_code_primary Is 
  Select
    address.id_number
    , address.xsequence
    , address.addr_pref_ind
    , Listagg(trim(geo_code.description), '; ') Within Group (Order By geo_code.description Asc)
      As geo_codes
    , min(geo_code.geo_code) keep(dense_rank First Order By geo_type.hierarchy_order Desc, address_geo.date_added Asc, geo_code.geo_code Asc)
      As geo_code_primary
    , min(geo_code.description) keep(dense_rank First Order By geo_type.hierarchy_order Desc, address_geo.date_added Asc, geo_code.geo_code Asc)
      As geo_code_primary_desc
  From address
  Inner Join address_geo
    On address.id_number = address_geo.id_number
    And address.xsequence = address_geo.xsequence
  Inner Join geo_code
    On geo_code.geo_code = address_geo.geo_code
  Inner Join geo_type
    On geo_type.geo_type = geo_code.geo_type
  Where 
    address.addr_status_code = 'A' -- Active addresses only
    And address_geo.geo_type In (100, 110) -- Tier 1 Region; Club
    And address_geo.geo_code Not In (
      'C035' -- Lake Arc 
      , 'C068' -- SF without SJ
      , 'C069' -- San Jose
      , 'C046' -- North Carolina
      , 'C011' -- Chi city only
      , 'C074' -- Miami-Ft Laud combined
    )
  Group By
    address.id_number
    , address.xsequence
    , address.addr_pref_ind
;

/* Definition of Kellogg householding
   2017-02-21 */
Cursor c_entity_households_ksm Is
With
  -- Entities and spouses, with Kellogg degrees concat fields
  degs As (
    Select deg.*
    From table(tbl_entity_degrees_concat_ksm) deg
  )
  , couples As (
    Select
      -- Entity fields
      entity.id_number
      , entity.pref_mail_name
      , entity.report_name
      , entity.record_type_code
      , entity.gender_code
      , entity.person_or_org
      , entity.record_status_code
      , entity.institutional_suffix
      , edc.degrees_concat
      , edc.first_ksm_year
      , edc.first_masters_year
      , edc.last_masters_year
      , edc.last_noncert_year
      , edc.program
      , edc.program_group
      , edc.program_group_rank
      -- Spouse fields
      , entity.spouse_id_number
      , spouse.pref_mail_name As spouse_pref_mail_name
      , spouse.report_name As spouse_report_name
      , spouse.gender_code As spouse_gender_code
      , spouse.institutional_suffix As spouse_suffix
      , sdc.degrees_concat As spouse_degrees_concat
      , sdc.first_ksm_year As spouse_first_ksm_year
      , sdc.first_masters_year As spouse_first_masters_year
      , sdc.last_masters_year As spouse_last_masters_year
      , sdc.last_noncert_year As spouse_last_noncert_year
      , sdc.program As spouse_program
      , sdc.program_group As spouse_program_group
      , sdc.program_group_rank As spouse_program_group_rank
    From entity
    Left Join degs edc On entity.id_number = edc.id_number
    Left Join degs sdc On entity.spouse_id_number = sdc.id_number
    Left Join entity spouse On entity.spouse_id_number = spouse.id_number
  )
  , household As (
    Select
      id_number
      , report_name
      , record_status_code
      , pref_mail_name
      , institutional_suffix
      , degrees_concat
      , first_ksm_year
      , last_noncert_year
      , program
      , program_group
      , spouse_id_number
      , spouse_report_name
      , spouse_pref_mail_name
      , spouse_suffix
      , spouse_degrees_concat
      , spouse_first_ksm_year
      , spouse_program
      , spouse_program_group
      , spouse_last_noncert_year
      -- Choose which spouse is primary based on program_group
      , Case
          When length(spouse_id_number) < 10 Or spouse_id_number Is Null Then id_number -- if no spouse, use id_number
          -- if same program (or both null), use lower id_number
          When program_group = spouse_program_group Or program_group Is Null And spouse_program_group Is Null Then
            Case When id_number < spouse_id_number Then id_number Else spouse_id_number End
          When spouse_program_group Is Null Then id_number -- if no spouse program, use id_number
          When program_group Is Null Then spouse_id_number -- if no self program, use spouse_id_number
          When program_group_rank < spouse_program_group_rank Then id_number
          When spouse_program_group_rank < program_group_rank Then spouse_id_number
        End As household_id
      -- Compute last master's degree year in household
      , Case
          When spouse_last_masters_year Is Null Then last_masters_year
          When last_masters_year Is Null Then spouse_last_masters_year
          When last_masters_year >= spouse_last_masters_year Then last_masters_year
          When spouse_last_masters_year >= last_masters_year Then spouse_last_masters_year
        End As household_last_masters_year
    From couples
  )
  -- Address info
  , geo As (
    Select *
    From table(tbl_geo_code_primary)
    Where addr_pref_ind = 'Y'
  )

  , pref_addr As (
    Select
      addr.id_number
      , addr.xsequence
      , addr.city As pref_city
      , addr.state_code As pref_state
      , addr.zipcode
      , geo.geo_codes
      , geo.geo_code_primary
      , geo.geo_code_primary_desc
      , cont.country As pref_country
      , cont.continent As pref_continent
    From address addr
    Left Join v_addr_continents cont On addr.country_code = cont.country_code
    Left Join geo On geo.id_number = addr.id_number
    Where addr.addr_pref_ind = 'Y'
      And addr.addr_status_code = 'A'
  )
  -- Deceased spouse logic
  , deceased_spouses As (
    Select Distinct
      id_number
      , spouse_id_number
      , marital_status_chg_dt
      , xsequence
      , tms.short_desc As marital_status
    From former_spouse
    Inner Join tms_marital_status tms On tms.marital_status_code = former_spouse.marital_status_code
    Where
      -- Marriage ended by death, married at time of death, widowed, widowed at time of death, former spouse
      -- If updated, also change below in fmr_spouse query
      tms.marital_status_code In ('I', 'Q', 'Z', 'W', 'N', 'F', ' ')
  )
  -- Deduping
  , deceased_spouse As (
    Select
      ds.id_number
      -- If multiple keep only most recent (determined by change date, then xsequence) deceased spouse
      , min(spouse_id_number) keep(dense_rank First Order By marital_status_chg_dt Desc, xsequence Desc) As spouse_id_number
    From deceased_spouses ds
    Group By ds.id_number
  )
  , fmr_spouse As (
    Select
      entity.id_number
      , entity.report_name
      , tms.short_desc As record_status
      , tms_ms.short_desc As marital_status
      , ds.spouse_id_number
      , spouse.report_name As spouse_name
      , tmsd.short_desc As spouse_record_status
      , tms_sms.short_desc As spouse_marital_status
    From entity
    Inner Join tms_record_status tms On tms.record_status_code = entity.record_status_code
    Left Join deceased_spouse ds On ds.id_number = entity.id_number
    Left Join tms_marital_status tms_ms On tms_ms.marital_status_code = entity.marital_status_code
    Left Join entity spouse On spouse.id_number = ds.spouse_id_number
    Inner Join tms_record_status tmsd On tmsd.record_status_code = spouse.record_status_code
    Left Join tms_marital_status tms_sms On tms_sms.marital_status_code = spouse.marital_status_code
    Inner Join (Select id_number From deceased_spouse Union Select spouse_id_number From deceased_spouse) ds
      On ds.id_number = entity.id_number
    -- If updated, also change above in deceased_spouses query
    Where entity.marital_status_code In ('I', 'Q', 'Z', 'W', 'N', 'F', ' ')
      And spouse.marital_status_code In ('I', 'Q', 'Z', 'W', 'N', 'F', ' ')
  )
  -- Spouse order for mailing lists, etc.
  , mailing_order As (
    Select Distinct
      household.household_id
      , Case
          -- Check whether household spouse ID exists
          When trim(household.spouse_id_number) Is Not Null
            Then Case
              -- Check whether male is alum and female is nonalum
              When couples.gender_code = 'M'
                And couples.first_ksm_year Is Not Null
                And couples.spouse_gender_code = 'F'
                And couples.spouse_first_ksm_year Is Null
                  Then household_id
              When couples.gender_code = 'F'
                And couples.first_ksm_year Is Null
                And couples.spouse_gender_code = 'M'
                And couples.spouse_first_ksm_year Is Not Null
                  Then couples.spouse_id_number
              -- Check whether one record is male and one female
              When couples.gender_code = 'M'
                And couples.spouse_gender_code = 'F'
                  Then couples.spouse_id_number
              When couples.gender_code = 'F'
                And couples.spouse_gender_code = 'M'
                  Then household_id
              -- Check whether one record is alum and one nonalum
              When couples.first_ksm_year Is Not Null
                And couples.spouse_first_ksm_year Is Null
                  Then household_id
              When couples.first_ksm_year Is Null
                And couples.spouse_first_ksm_year Is Not Null
                  Then couples.spouse_id_number
              -- Alpha order as a fallback
              When lower(couples.report_name) <= lower(couples.spouse_report_name)
                Then household_id
              When lower(couples.report_name) > lower(couples.spouse_report_name)
                Then couples.spouse_id_number
              Else '#ERROR'
            End
          -- When no household spouse ID use household ID
          Else household_id
          End
        As household_list_first
    From household
    Inner Join couples On household.household_id = couples.id_number
  )
  -- Main query
  Select
    household.id_number
    , household.report_name
    , household.pref_mail_name
    , household.record_status_code
    , household.degrees_concat
    , household.first_ksm_year
    , household.program
    , household.program_group
    , household.last_noncert_year
    , household.institutional_suffix
    , household.spouse_id_number
    , household.spouse_report_name
    , household.spouse_pref_mail_name
    , household.spouse_suffix
    , household.spouse_degrees_concat
    , household.spouse_first_ksm_year
    , household.spouse_program
    , household.spouse_program_group
    , household.spouse_last_noncert_year
    , fmr_spouse.spouse_id_number As fmr_spouse_id
    , fmr_spouse.spouse_name As fmr_spouse_name
    , fmr_spouse.marital_status As fmr_marital_status
    , household.household_id
    , Case When household.household_id = household.id_number Then 'Y' End
      As household_primary
    , couples.record_type_code As household_record
    , couples.person_or_org
    , couples.pref_mail_name As household_name
    , couples.report_name As household_rpt_name
    , couples.spouse_id_number As household_spouse_id
    , couples.spouse_pref_mail_name As household_spouse
    , couples.spouse_report_name As household_spouse_rpt_name
    , mailing_order.household_list_first
    , Case
        When mailing_order.household_list_first <> household.household_id
          Then household.household_id
        Else trim(couples.spouse_id_number)
        End
      As household_list_second
    , couples.institutional_suffix As household_suffix
    , couples.spouse_suffix As household_spouse_suffix
    , couples.first_ksm_year As household_ksm_year
    , couples.first_masters_year As household_masters_year
    -- Household last non-certificate year, for (approximate) young alumni designation
    , household.household_last_masters_year
    , couples.program As household_program
    , couples.program_group As household_program_group
    , pref_addr.xsequence
    , pref_addr.pref_city
    , pref_addr.pref_state
    , pref_addr.zipcode
    , pref_addr.geo_codes
    , pref_addr.geo_code_primary
    , pref_addr.geo_code_primary_desc
    , pref_addr.pref_country
    , pref_addr.pref_continent
  From household
  Inner Join couples On household.household_id = couples.id_number
  Left Join mailing_order On household.household_id = mailing_order.household_id
  Left Join pref_addr On household.id_number = pref_addr.id_number
  Left Join fmr_spouse On household.id_number = fmr_spouse.id_number
  ;

/* Definition of a Kellogg alum employed by a company */
Cursor c_entity_employees_ksm (company In varchar2) Is
  With
  -- Employment table subquery
  employ As (
    Select
      id_number
      , job_title
      -- If there's an employer ID filled in, use the entity name
      , Case
          When employer_id_number Is Not Null And employer_id_number != ' ' Then (
            Select pref_mail_name
            From entity
            Where id_number = employer_id_number
          )
          -- Otherwise use the write-in field
          Else trim(employer_name1 || ' ' || employer_name2)
        End As employer_name
    From employment
    Where employment.primary_emp_ind = 'Y'
  )
  -- Record status tms table
  , tms_rec_status As (
    Select
      record_status_code
      , short_desc As record_status
    From tms_record_status
  )
  , tms_ctry As (
    Select
      country_code
      , short_desc As country
    From tms_country
  )
  -- Main query
  Select
    -- Entity fields
    deg.id_number
    , entity.report_name
    , tms_rec_status.record_status
    , entity.institutional_suffix
    , deg.degrees_concat
    , deg.first_ksm_year
    , trim(deg.program_group) As program
    -- Employment fields
    , prs.business_title
    , trim(prs.employer_name1 || ' ' || prs.employer_name2) As business_company
    , employ.job_title
    , employ.employer_name
    , prs.business_city
    , prs.business_state
    , tms_ctry.country As business_country
    -- Prospect fields
    , prs.prospect_manager
    , prs.team
  From table(tbl_entity_degrees_concat_ksm) deg -- KSM alumni definition
  Inner Join entity On deg.id_number = entity.id_number
  Inner Join tms_rec_status On tms_rec_status.record_status_code = entity.record_status_code
  Left Join employ On deg.id_number = employ.id_number
  Left Join nu_prs_trp_prospect prs On deg.id_number = prs.id_number
  Left Join tms_ctry On tms_ctry.country_code = prs.business_country
  Where
    -- Matches pattern; user beware (Apple vs. Snapple)
    lower(employ.employer_name) Like lower('%' || company || '%')
    Or lower(prs.employer_name1) Like lower('%' || company || '%')
  ;

/* Definition of top 150/300 KSM campaign prospects */
Cursor c_entity_top_150_300 Is
  Select
    pc.prospect_id
    , pe.primary_ind
    , pe.id_number
    , entity.report_name
    , entity.person_or_org
    , pc.prospect_category_code
    , tms_pc.short_desc As prospect_category
  From prospect_entity pe
  Inner Join prospect_category pc On pc.prospect_id = pe.prospect_id
  Inner Join entity On pe.id_number = entity.id_number
  Inner Join tms_prospect_category tms_pc On tms_pc.prospect_category_code = pc.prospect_category_code
  Where pc.prospect_category_code In ('KT1', 'KT3')
  Order By pe.prospect_id Asc, pe.primary_ind Desc
  ;

/* Definition of university strategy */
Cursor c_university_strategy Is
  With
  -- Pull latest upcoming University Overall Strategy
  uos_ids As (
    Select
      prospect_id
      , min(task_id) keep(dense_rank First Order By sched_date Desc, task.task_id Asc) As task_id
    From task
    Where prospect_id Is Not Null -- Prospect strategies only
      And task_code = 'ST' -- University Overall Strategy
      And task_status_code Not In (4, 5) -- Not Completed (4) or Cancelled (5) status
    Group By prospect_id
  )
  , next_uos As (
    Select
      task.prospect_id
      , task.task_id
      , task.task_description As university_strategy
      , task.sched_date As strategy_sched_date
      , trunc(task.date_modified) As strategy_modified_date
      , task.operator_name As strategy_modified_netid
    From task
    Inner Join uos_ids
      On uos_ids.prospect_id = task.prospect_id
      And uos_ids.task_id = task.task_id
  )
  , netids As (
    Select
      ids.other_id
      , ids.id_number
      , entity.report_name
    From ids
    Inner Join entity
      On entity.id_number = ids.id_number
    Where ids_type_code = 'NET'
  )
  -- Append task responsible data to first upcoming UOS
  , next_uos_resp As (
    Select
      uos.prospect_id
      , uos.university_strategy
      , uos.strategy_sched_date
      , uos.strategy_modified_date
      , uos.strategy_modified_netid
      , netids.report_name As strategy_modified_name
      , Listagg(tr.id_number, ', ') Within Group (Order By tr.date_added Desc)
        As strategy_responsible_id
      , Listagg(entity.pref_mail_name, ', ') Within Group (Order By tr.date_added Desc)
        As strategy_responsible
    From next_uos uos
    Left Join netids
      On netids.other_id = uos.strategy_modified_netid
    Left Join task_responsible tr On tr.task_id = uos.task_id
    Left Join entity On entity.id_number = tr.id_number
    Group By
      uos.prospect_id
      , uos.university_strategy
      , uos.strategy_sched_date
      , uos.strategy_modified_date
      , uos.strategy_modified_netid
      , netids.report_name
  )
  -- Main query; uses nu_prs_trp_prospect fields if available
  Select Distinct
    uos.prospect_id
    , Case
        When prs.strategy_description Is Not Null Then prs.strategy_description
        Else uos.university_strategy
      End As university_strategy
    , Case
        When prs.strategy_description Is Not Null Then ksm_pkg.to_date2(prs.strategy_date, 'mm/dd/yyyy')
        Else uos.strategy_sched_date
      End As strategy_sched_date
    , Case
        When prs.strategy_description Is Not Null Then task_resp
        Else uos.strategy_responsible
      End As strategy_responsible
    , uos.strategy_modified_date
    , uos.strategy_modified_name
  From next_uos_resp uos
  Left Join advance_nu.nu_prs_trp_prospect prs On prs.prospect_id = uos.prospect_id
  ;

/* Extract from the segment table given the passed year, month, and segment code */
Cursor c_segment_extract (year In integer, month In integer, code In varchar2) Is
  Select
    s.id_number
    , s.segment_year
    , s.segment_month
    , s.segment_code
    , sh.description
    , s.xcomment As score
  From segment s
  Inner Join segment_header sh On sh.segment_code = s.segment_code
  Where s.segment_code Like code
    And to_number2(s.segment_year) = year
    And to_number2(s.segment_month) = month
  ;

/* Definition of historical NU ARD employees */
Cursor c_nu_ard_staff Is
  With
  -- NU ARD employment
  nuemploy As (
    Select
      employment.id_number
      , entity.report_name
      , xsequence
      , row_number() Over(Partition By employment.id_number Order By primary_emp_ind Desc, job_status_code Asc, xsequence Desc) As nbr
      , job_status_code
      , primary_emp_ind
      , job_title
      , employer_id_number
      , employer_unit
      , trunc(employment.start_dt) As start_dt
      , trunc(employment.stop_dt) As stop_dt
      , trunc(employment.date_added) As date_added
      , trunc(employment.date_modified) As date_modified
    From employment
    Inner Join entity On entity.id_number = employment.id_number
    Where employer_id_number = '0000439808' -- Northwestern University
      And employ_relat_code Not In ('ZZ', 'MA') -- Exclude historical and matching gift employers
  )
  -- Last NU job
  , last_nuemploy As (
    Select
      id_number
      , report_name
      , job_title
      , employer_unit
      , job_status_code
      , primary_emp_ind
      , start_dt
      , stop_dt
      , date_added
      , date_modified
    From nuemploy
    Where nbr = 1
  )
  -- Main query
  Select Distinct
    nuemploy.id_number
    , nuemploy.report_name
    , last_nuemploy.job_title
    , last_nuemploy.employer_unit
    , last_nuemploy.job_status_code
    , last_nuemploy.primary_emp_ind
    , last_nuemploy.start_dt
    , last_nuemploy.stop_dt
  From nuemploy
  Inner Join last_nuemploy On last_nuemploy.id_number = nuemploy.id_number
  Where 
    nuemploy.id_number In ('0000768730', '0000299349') -- HG, SB
    -- Ever worked for University-wide ARD
    Or lower(nuemploy.employer_unit) Like '%alumni%'
    Or lower(nuemploy.employer_unit) Like '%development%'
    Or lower(nuemploy.employer_unit) Like '%advancement%'
    Or nuemploy.employer_unit Like '%ARD%'
    Or lower(nuemploy.employer_unit) Like '%campaign strategy%'
    Or lower(nuemploy.employer_unit) Like '%external relations%'
    Or lower(nuemploy.employer_unit) Like '%gifts%'
    -- Job title sounds like frontline staff
    Or lower(last_nuemploy.job_title) Like '%gifts%'
  ;

/* Definition of a KLC member */
Cursor c_klc_history (fy_start_month In integer) Is
  Select
    extract(year from to_date2(gift_club_end_date, 'yyyymmdd')) As fiscal_year
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
        When extract(year from to_date2(gift_club_start_date, 'yyyymmdd')) < extract(year from to_date2(gift_club_end_date, 'yyyymmdd'))
          And extract(month from to_date2(gift_club_start_date, 'yyyymmdd')) < fy_start_month Then 'Y'
        Else fytd_indicator(to_date2(gift_club_start_date, 'yyyymmdd'))
      End As klc_fytd
  From gift_clubs
  Inner Join table(tbl_entity_households_ksm) hh On hh.id_number = gift_clubs.gift_club_id_number
  Left Join nu_mem_v_tmsclublevel tms_lvl On tms_lvl.level_code = gift_clubs.school_code
  Where gift_club_code = 'LKM'
  ;

/* Definition of discounted pledge amounts */
Cursor c_plg_discount Is
  Select
    pledge.pledge_pledge_number As pledge_number
    , pledge.pledge_sequence
    , pplg.prim_pledge_type
    , pplg.prim_pledge_status
    , trim(pplg.status_change_date)
      As status_change_date
    , pplg.proposal_id
    , pplg.prim_pledge_comment
    , pledge.pledge_amount
    , pledge.pledge_associated_credit_amt
    , pplg.prim_pledge_amount
    , pplg.prim_pledge_amount_paid
    , Case
        When pplg.prim_pledge_status = 'A'
          Then pplg.prim_pledge_amount - pplg.prim_pledge_amount_paid
        Else 0
        End
      As prim_pledge_remaining_balance
    , pplg.prim_pledge_original_amount
    , pplg.discounted_amt
    -- Discounted pledge legal amounts
    , Case
        -- Not inactive, not a BE or LE
        When (pplg.prim_pledge_status Is Null Or pplg.prim_pledge_status = 'A')
          And pplg.prim_pledge_type Not In ('BE', 'LE') Then pledge.pledge_amount
        -- Not inactive, is BE or LE; make sure to allocate proportionally to program code allocation
        When (pplg.prim_pledge_status Is Null Or pplg.prim_pledge_status = 'A')
          And pplg.prim_pledge_type In ('BE', 'LE') Then pplg.discounted_amt * pledge.pledge_amount /
            (Case When pplg.prim_pledge_amount = 0 Then 1 Else pplg.prim_pledge_amount End)
        -- If inactive, take amount paid
        Else Case
          When pplg.prim_pledge_amount > 0
            Then pplg.prim_pledge_amount_paid * pledge.pledge_amount / pplg.prim_pledge_amount
          When pledge.pledge_amount > 0
            Then pplg.prim_pledge_amount_paid
          Else 0
        End
      End As legal
    -- Discounted pledge credit amounts
    , Case
        -- Not inactive, not a BE or LE
        When (pplg.prim_pledge_status Is Null Or pplg.prim_pledge_status = 'A')
          And pplg.prim_pledge_type Not In ('BE', 'LE') Then pledge.pledge_associated_credit_amt
        -- Not inactive, is BE or LE; make sure to allocate proportionally to program code allocation
        When (pplg.prim_pledge_status Is Null Or pplg.prim_pledge_status = 'A')
          And pplg.prim_pledge_type In ('BE', 'LE') Then pplg.discounted_amt * pledge.pledge_associated_credit_amt /
            (Case When pplg.prim_pledge_amount = 0 Then 1 Else pplg.prim_pledge_amount End)
        -- If inactive, take amount paid
        Else Case
          When pledge.pledge_amount = 0 And pplg.prim_pledge_amount > 0
            Then pplg.prim_pledge_amount_paid * pledge.pledge_associated_credit_amt / pplg.prim_pledge_amount
          When pplg.prim_pledge_amount > 0
            Then pplg.prim_pledge_amount_paid * pledge.pledge_amount / pplg.prim_pledge_amount
          Else pplg.prim_pledge_amount_paid
        End
      End As credit
    -- Discounted pledge credit with face value on bequests
    , Case
      -- All active pledges
        When (pplg.prim_pledge_status Is Null Or pplg.prim_pledge_status = 'A') Then pledge.pledge_associated_credit_amt
        -- If not active, take amount paid
        Else Case
          When pledge.pledge_amount = 0 And pplg.prim_pledge_amount > 0
            Then pplg.prim_pledge_amount_paid * pledge.pledge_associated_credit_amt / pplg.prim_pledge_amount
          When pplg.prim_pledge_amount > 0
            Then pplg.prim_pledge_amount_paid * pledge.pledge_amount / pplg.prim_pledge_amount
          Else pplg.prim_pledge_amount_paid
        End
      End As recognition_credit
  From primary_pledge pplg
  Inner Join pledge On pledge.pledge_pledge_number = pplg.prim_pledge_number
  Where pledge.pledge_program_code = 'KM'
    Or pledge_alloc_school = 'KM'
  ;

/* Prospect entity table filtered for active prospects only */
Cursor c_prospect_entity_active Is
  Select
    pe.prospect_id
    , pe.id_number
    , e.report_name
    , pe.primary_ind
  From prospect_entity pe
  Inner Join prospect p On p.prospect_id = pe.prospect_id
  Inner Join entity e On e.id_number = pe.id_number
  Where p.active_ind = 'Y' -- Active only
;

/* Rework of match + matched + gift + payment + pledge union definition
   Intended to replace nu_gft_trp_gifttrans with KSM-specific fields 
   Shares significant code with c_gift_credit_ksm below */
Cursor c_gift_credit Is
  With
  /* Primary pledge discounted amounts */
  plg_discount As (
    Select *
    From table(plg_discount)
  )
  /* KSM allocation info */
  , ksm_allocs As (
    Select
      allocation.allocation_code
      , allocation.short_name
      , Case When alloc_school = 'KM' Then 'Y' End As ksm_flag
      , Case When ksm_cru_allocs.af_flag Is Not Null Then 'Y' End As cru_flag
      , Case When ksm_cru_allocs.af_flag = 'Y' Then 'Y' End As af_flag
    From allocation
    Left Join table(tbl_alloc_curr_use_ksm) ksm_cru_allocs
      On ksm_cru_allocs.allocation_code = allocation.allocation_code
  )
  /* Transaction and pledge TMS table definition */
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
  /* Payment types */
  , tms_pmt_type As (
    Select
      payment_type_code
      , short_desc As payment_type
    From tms_payment_type
  )
  , tms_assoc As (
    Select
      associated_code
      , short_desc As associated_desc
    From tms_association
  )
  /* Kellogg transactions list */
  (
      -- Matching gift matching company
    Select
      match_gift_company_id
      , entity.report_name
      , gftanon.anon
      , match_gift_receipt_number
      , match_gift_matched_sequence
      , NULL As transaction_type_code
      , 'Matching Gift' As transaction_type
      , 'M' As tx_gypm_ind
      , 'MG' As associated_code
      , 'Matching Gift' As associated_desc
      , NULL As pledge_number
      , match_gift_matched_receipt As matched_tx_number
      , to_number(gift.gift_year_of_giving) As matched_fiscal_year
      , tms_pmt_type.payment_type
      , match_gift_allocation_name
      , ksm_allocs.short_name
      , ksm_flag
      , af_flag
      , cru_flag
      , matching_gift.match_gift_comment
      , NULL As proposal_id
      , NULL As pledge_status
      , match_gift_date_of_record
      , get_fiscal_year(match_gift_date_of_record)
      -- Full legal amount to matching company
      , match_gift_amount
      , match_gift_amount
      , match_gift_amount
    From matching_gift
    Inner Join entity On entity.id_number = matching_gift.match_gift_company_id
    -- Matched gift data
    Left Join gift On gift.gift_receipt_number = match_gift_matched_receipt
    -- Only KSM allocations
    Inner Join ksm_allocs On ksm_allocs.allocation_code = matching_gift.match_gift_allocation_name
    -- Anonymous association on the matched gift
    Inner Join (
        Select
          gift_receipt_number
          , gift_sequence
          , gift_associated_anonymous As anon
        From gift
      ) gftanon On gftanon.gift_receipt_number = matching_gift.match_gift_matched_receipt
          And gftanon.gift_sequence = matching_gift.match_gift_matched_sequence
    -- Trans payment descriptions
    Left Join tms_pmt_type On tms_pmt_type.payment_type_code = matching_gift.match_payment_type
  ) Union ( -- NOT Union All as we need to dedupe so the company does not get double credit
  -- Matching gift matched donors
    Select
      gft.id_number
      , entity.report_name
      , gftanon.anon
      , match_gift_receipt_number
      , match_gift_matched_sequence
      , NULL As transaction_type_code
      , 'Matching Gift' As transaction_type
      , 'M' As tx_gypm_ind
      , 'MG' As associated_code
      , 'Matching Gift' As associated_desc
      , NULL As pledge_number
      , match_gift_matched_receipt As matched_tx_number
      , to_number(gift.gift_year_of_giving) As matched_fiscal_year
      , tms_pmt_type.payment_type
      , match_gift_allocation_name
      , ksm_allocs.short_name
      , ksm_flag
      , af_flag
      , cru_flag
      , matching_gift.match_gift_comment
      , NULL As proposal_id
      , NULL As pledge_status
      , match_gift_date_of_record
      , get_fiscal_year(match_gift_date_of_record)
      -- 0 legal amount to matched donors
      , Case When gft.id_number = match_gift_company_id Then match_gift_amount Else 0 End As legal_amount
      , match_gift_amount
      , match_gift_amount
    From matching_gift
    -- Matched gift data
    Left Join gift On gift.gift_receipt_number = match_gift_matched_receipt
    -- Inner join to add all attributed donor IDs on the original gift
    Inner Join (
        Select
          gift_donor_id As id_number
          , gift.gift_receipt_number
        From gift
      ) gft On matching_gift.match_gift_matched_receipt = gft.gift_receipt_number
    Inner Join entity On entity.id_number = gft.id_number
    -- Only KSM allocations
    Inner Join ksm_allocs On ksm_allocs.allocation_code = matching_gift.match_gift_allocation_name
    -- Anonymous association on the matched gift
    Inner Join (
        Select
          gift_donor_id
          , gift_receipt_number
          , gift_sequence
          , gift_associated_anonymous As anon
        From gift
      ) gftanon On gftanon.gift_receipt_number = matching_gift.match_gift_matched_receipt
          And gftanon.gift_sequence = matching_gift.match_gift_matched_sequence
    -- Trans payment descriptions
    Left Join tms_pmt_type On tms_pmt_type.payment_type_code = matching_gift.match_payment_type
  ) Union All (
  -- Outright gifts and payments
    Select
      gift.gift_donor_id As id_number
      , entity.report_name
      , gift.gift_associated_anonymous As anon
      , gift.gift_receipt_number As tx_number
      , gift.gift_sequence As tx_sequence
      , gift.gift_transaction_type As transaction_type_code
      , tms_trans.transaction_type
      , Case
          When gift.pledge_payment_ind = 'Y'
            Then 'Y' -- Y = pledge payment
          Else 'G' -- G = outright gift
          End
        As tx_gypm_ind
      , gift.gift_associated_code
      , tms_assoc.associated_desc
      , primary_gift.prim_gift_pledge_number As pledge_number
      , NULL As matched_tx_number
      , NULL As matched_fiscal_year
      , tms_pmt_type.payment_type
      , gift.gift_associated_allocation As allocation_code
      , allocation.short_name As alloc_short_name
      , ksm_flag
      , af_flag
      , cru_flag
      , primary_gift.prim_gift_comment As gift_comment
      , Case When primary_gift.proposal_id <> 0 Then primary_gift.proposal_id End As proposal_id
      , NULL As pledge_status
      , gift.gift_date_of_record As date_of_record
      , get_fiscal_year(gift.gift_date_of_record) As fiscal_year
      , gift.gift_associated_amount As legal_amount
      , gift.gift_associated_credit_amt As credit_amount
      -- Recognition credit; for $0 internal transfers, extract dollar amount stated in comment
      , Case
          When tms_pmt_type.payment_type = 'Internal Transfer'
            And gift.gift_associated_credit_amt = 0
            Then get_number_from_dollar(primary_gift.prim_gift_comment)
          Else gift.gift_associated_credit_amt
        End As recognition_credit
    From gift
    Inner Join entity On entity.id_number = gift.gift_donor_id
    -- Allocation
    Inner Join allocation On allocation.allocation_code = gift.gift_associated_allocation
    -- Anonymous association and linked proposal
    Inner Join primary_gift On primary_gift.prim_gift_receipt_number = gift.gift_receipt_number
    -- Trans type descriptions
    Left Join tms_trans On tms_trans.transaction_type_code = gift.gift_transaction_type
    Left Join tms_pmt_type On tms_pmt_type.payment_type_code = gift.gift_payment_type
    Left Join tms_assoc On tms_assoc.associated_code = gift.gift_associated_code
    -- KSM Annual Fund indicator
    Left Join ksm_allocs On ksm_allocs.allocation_code = gift.gift_associated_allocation
  ) Union All (
  -- Pledges, including BE and LE program credit
    Select
      pledge_donor_id
      , entity.report_name
      , pledge_anonymous
      , pledge_pledge_number
      , pledge.pledge_sequence
      , pledge.pledge_pledge_type As transaction_type_code
      , tms_trans.transaction_type
      , 'P' As tx_gypm_ind
      , pledge.pledge_associated_code
      , tms_assoc.associated_desc
      , pledge.pledge_pledge_number As pledge_number
      , NULL As matched_tx_number
      , NULL As matched_fiscal_year
      , NULL As payment_type
      , pledge.pledge_allocation_name
      , Case
          When ksm_allocs.short_name Is Not Null Then ksm_allocs.short_name
          When ksm_allocs.short_name Is Null Then allocation.short_name
        End As short_name
      -- Include KSM allocations as well as the BE/LE account gifts where the gift is counted toward the KM program
      , Case
          When pledge_allocation_name In ('BE', 'LE') -- BE and LE discounted amounts
            And pledge_program_code = 'KM'
            Then 'Y'
          Else ksm_flag
          End
        As ksm_flag
      , ksm_allocs.af_flag
      , cru_flag
      , pledge_comment
      , Case When proposal_id <> 0 Then proposal_id End As proposal_id
      , prim_pledge_status
      , pledge_date_of_record
      , get_fiscal_year(pledge_date_of_record)
      , plgd.legal
      , plgd.credit
      , plgd.recognition_credit
    From pledge
    Inner Join entity On entity.id_number = pledge.pledge_donor_id
    -- Trans type descriptions
    Inner Join tms_trans On tms_trans.transaction_type_code = pledge.pledge_pledge_type
    Left Join tms_assoc On tms_assoc.associated_code = pledge.pledge_associated_code
    -- Allocation name backup
    Inner Join allocation On allocation.allocation_code = pledge.pledge_allocation_name
    -- Discounted pledge amounts where applicable
    Left Join plg_discount plgd On plgd.pledge_number = pledge.pledge_pledge_number
      And plgd.pledge_sequence = pledge.pledge_sequence
    -- KSM AF flag
    Left Join ksm_allocs On ksm_allocs.allocation_code = pledge.pledge_allocation_name
  )
  ;

/* Definition of KSM giving transactions for summable credit
   Shares significant code with c_gift_credit above but uses inner joins for a ~3x speedup */
Cursor c_gift_credit_ksm Is
  With
  /* Primary pledge discounted amounts */
  plg_discount As (
    Select *
    From table(plg_discount)
  )
  /* KSM allocations */
  , ksm_cru_allocs As (
    Select *
    From table(tbl_alloc_curr_use_ksm) cru
  )
  , ksm_allocs As (
    Select
      allocation.allocation_code
      , allocation.short_name
      , Case When ksm_cru_allocs.af_flag Is Not Null Then 'Y' End As cru_flag
      , Case When ksm_cru_allocs.af_flag = 'Y' Then 'Y' End As af_flag
    From allocation
    Left Join ksm_cru_allocs On ksm_cru_allocs.allocation_code = allocation.allocation_code
    Where alloc_school = 'KM'
  )
  /* Transaction and pledge TMS table definition */
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
  /* Payment types */
  , tms_pmt_type As (
    Select
      payment_type_code
      , short_desc As payment_type
    From tms_payment_type
  )
  , tms_assoc As (
    Select
      associated_code
      , short_desc As associated_desc
    From tms_association
  )
  /* Kellogg transactions list */
  (
      -- Matching gift matching company
    Select
      match_gift_company_id
      , entity.report_name
      , gftanon.anon
      , match_gift_receipt_number
      , match_gift_matched_sequence
      , NULL As transaction_type_code
      , 'Matching Gift' As transaction_type
      , 'M' As tx_gypm_ind
      , 'MG' As associated_code
      , 'Matching Gift' As associated_desc
      , NULL As pledge_number
      , match_gift_matched_receipt As matched_tx_number
      , to_number(gift.gift_year_of_giving) As matched_fiscal_year
      , tms_pmt_type.payment_type
      , match_gift_allocation_name
      , ksm_allocs.short_name
      , 'Y' As ksm_flag
      , af_flag
      , cru_flag
      , matching_gift.match_gift_comment
      , NULL As proposal_id
      , NULL As pledge_status
      , match_gift_date_of_record
      , get_fiscal_year(match_gift_date_of_record)
      -- Full legal amount to matching company
      , match_gift_amount
      , match_gift_amount
      , match_gift_amount
    From matching_gift
    Inner Join entity On entity.id_number = matching_gift.match_gift_company_id
    -- Matched gift data
    Left Join gift On gift.gift_receipt_number = match_gift_matched_receipt
    -- Only KSM allocations
    Inner Join ksm_allocs On ksm_allocs.allocation_code = matching_gift.match_gift_allocation_name
    -- Anonymous association on the matched gift
    Inner Join (
        Select
          gift_receipt_number
          , gift_sequence
          , gift_associated_anonymous As anon
        From gift
      ) gftanon On gftanon.gift_receipt_number = matching_gift.match_gift_matched_receipt
          And gftanon.gift_sequence = matching_gift.match_gift_matched_sequence
    -- Trans payment descriptions
    Left Join tms_pmt_type On tms_pmt_type.payment_type_code = matching_gift.match_payment_type
  ) Union ( -- NOT Union All as we need to dedupe so the company does not get double credit
  -- Matching gift matched donors
    Select
      gft.id_number
      , entity.report_name
      , gftanon.anon
      , match_gift_receipt_number
      , match_gift_matched_sequence
      , NULL As transaction_type_code
      , 'Matching Gift' As transaction_type
      , 'M' As tx_gypm_ind
      , 'MG' As associated_code
      , 'Matching Gift' As associated_desc
      , NULL As pledge_number
      , match_gift_matched_receipt As matched_tx_number
      , to_number(gift.gift_year_of_giving) As matched_fiscal_year
      , tms_pmt_type.payment_type
      , match_gift_allocation_name
      , ksm_allocs.short_name
      , 'Y' As ksm_flag
      , af_flag
      , cru_flag
      , matching_gift.match_gift_comment
      , NULL As proposal_id
      , NULL As pledge_status
      , match_gift_date_of_record
      , get_fiscal_year(match_gift_date_of_record)
      -- 0 legal amount to matched donors
      , Case When gft.id_number = match_gift_company_id Then match_gift_amount Else 0 End As legal_amount
      , match_gift_amount
      , match_gift_amount
    From matching_gift
    -- Matched gift data
    Left Join gift On gift.gift_receipt_number = match_gift_matched_receipt
    -- Inner join to add all attributed donor IDs on the original gift
    Inner Join (
        Select
          gift_donor_id As id_number
          , gift.gift_receipt_number
        From gift
      ) gft On matching_gift.match_gift_matched_receipt = gft.gift_receipt_number
    Inner Join entity On entity.id_number = gft.id_number
    -- Only KSM allocations
    Inner Join ksm_allocs On ksm_allocs.allocation_code = matching_gift.match_gift_allocation_name
    -- Anonymous association on the matched gift
    Inner Join (
        Select
          gift_donor_id
          , gift_receipt_number
          , gift_sequence
          , gift_associated_anonymous As anon
        From gift
      ) gftanon On gftanon.gift_receipt_number = matching_gift.match_gift_matched_receipt
          And gftanon.gift_sequence = matching_gift.match_gift_matched_sequence
    -- Trans payment descriptions
    Left Join tms_pmt_type On tms_pmt_type.payment_type_code = matching_gift.match_payment_type
  ) Union All (
  -- Outright gifts and payments
    Select
      gift.gift_donor_id As id_number
      , entity.report_name
      , gift.gift_associated_anonymous As anon
      , gift.gift_receipt_number As tx_number
      , gift.gift_sequence As tx_sequence
      , gift.gift_transaction_type As transaction_type_code
      , tms_trans.transaction_type
      , Case
          When gift.pledge_payment_ind = 'Y'
            Then 'Y' -- Y = pledge payment
          Else 'G' -- G = outright gift
          End
        As tx_gypm_ind
      , tms_assoc.associated_code
      , tms_assoc.associated_desc
      , primary_gift.prim_gift_pledge_number As pledge_number
      , NULL As matched_tx_number
      , NULL As matched_fiscal_year
      , tms_pmt_type.payment_type
      , gift.gift_associated_allocation As allocation_code
      , allocation.short_name As alloc_short_name
      , 'Y' As ksm_flag
      , af_flag
      , cru_flag
      , primary_gift.prim_gift_comment As gift_comment
      , Case When primary_gift.proposal_id <> 0 Then primary_gift.proposal_id End As proposal_id
      , NULL As pledge_status
      , gift.gift_date_of_record As date_of_record
      , get_fiscal_year(gift.gift_date_of_record) As fiscal_year
      , gift.gift_associated_amount As legal_amount
      , gift.gift_associated_credit_amt As credit_amount
      -- Recognition credit; for $0 internal transfers, extract dollar amount stated in comment
      , Case
          When tms_pmt_type.payment_type = 'Internal Transfer'
            And gift.gift_associated_credit_amt = 0
            Then get_number_from_dollar(primary_gift.prim_gift_comment)
          Else gift.gift_associated_credit_amt
        End As recognition_credit
    From gift
    Inner Join entity On entity.id_number = gift.gift_donor_id
    -- Allocation
    Inner Join allocation On allocation.allocation_code = gift.gift_associated_allocation
    -- Anonymous association and linked proposal
    Inner Join primary_gift On primary_gift.prim_gift_receipt_number = gift.gift_receipt_number
    -- Trans type descriptions
    Left Join tms_trans On tms_trans.transaction_type_code = gift.gift_transaction_type
    Left Join tms_pmt_type On tms_pmt_type.payment_type_code = gift.gift_payment_type
    Left Join tms_assoc On tms_assoc.associated_code = gift.gift_associated_code
    -- KSM Annual Fund indicator
    Left Join ksm_allocs On ksm_allocs.allocation_code = gift.gift_associated_allocation
    Where alloc_school = 'KM'
  ) Union All (
  -- Pledges, including BE and LE program credit
    Select
      pledge_donor_id
      , entity.report_name
      , pledge_anonymous
      , pledge_pledge_number
      , pledge.pledge_sequence
      , pledge.pledge_pledge_type As transaction_type_code
      , tms_trans.transaction_type
      , 'P' As tx_gypm_ind
      , tms_assoc.associated_code
      , tms_assoc.associated_desc
      , pledge.pledge_pledge_number As pledge_number
      , NULL As matched_tx_number
      , NULL As matched_fiscal_year
      , NULL As payment_type
      , pledge.pledge_allocation_name
      , Case
          When ksm_allocs.short_name Is Not Null Then ksm_allocs.short_name
          When ksm_allocs.short_name Is Null Then allocation.short_name
        End As short_name
      , 'Y' As ksm_flag
      , ksm_allocs.af_flag
      , cru_flag
      , pledge_comment
      , Case When proposal_id <> 0 Then proposal_id End As proposal_id
      , prim_pledge_status
      , pledge_date_of_record
      , get_fiscal_year(pledge_date_of_record)
      , plgd.legal
      , plgd.credit
      , plgd.recognition_credit
    From pledge
    Inner Join entity On entity.id_number = pledge.pledge_donor_id
    -- Trans type descriptions
    Inner Join tms_trans On tms_trans.transaction_type_code = pledge.pledge_pledge_type
    Inner Join tms_assoc On tms_assoc.associated_code = pledge.pledge_associated_code
    -- Allocation name backup
    Inner Join allocation On allocation.allocation_code = pledge.pledge_allocation_name
    -- Discounted pledge amounts where applicable
    Left Join plg_discount plgd On plgd.pledge_number = pledge.pledge_pledge_number
      And plgd.pledge_sequence = pledge.pledge_sequence
    -- KSM AF flag
    Left Join ksm_allocs On ksm_allocs.allocation_code = pledge.pledge_allocation_name
    -- Include KSM allocations as well as the BE/LE account gifts where the gift is counted toward the KM program
    Where ksm_allocs.allocation_code Is Not Null
      Or (
      -- KSM program code
        pledge_allocation_name In ('BE', 'LE') -- BE and LE discounted amounts
        And pledge_program_code = 'KM'
      )
  )
  ;
  
/* Definition of householded KSM giving transactions for summable credit
   Depends on c_gift_credit_ksm, through tbl_gift_credit_ksm table function */
Cursor c_gift_credit_hh_ksm Is
  With
  hhid As (
    Select
      hh.household_id
      , hh.household_rpt_name
      , ksm_trans.*
    From table(tbl_entity_households_ksm) hh
    Inner Join table(tbl_gift_credit_ksm) ksm_trans On ksm_trans.id_number = hh.id_number
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
  From hhid
  Inner Join giftcount gc On gc.household_id = hhid.household_id
    And gc.tx_number = hhid.tx_number
  ;
  
/* Definition of Transforming Together Campaign (2008) new gifts & commitments
   2017-08-25 */
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
  -- Main query
  (
  Select
    id_number
    , record_type_code
    , person_or_org
    , birth_dt
    , rcpt_or_plg_number
    , xsequence
    , anons.anon
    , amount
    , credited_amount
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
  Where daily.alloc_school = 'KM'
  ) Union All (
  -- Internal transfer; 344303 is 50%
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
  
/* Definition of householded KSM campaign transactions for summable credit */
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
    , hh_credit
    , hh_recognition_credit
  From table(tbl_gift_credit_hh_ksm) hh_cred
  Inner Join (Select Distinct rcpt_or_plg_number From nu_rpt_t_cmmt_dtl_daily) daily
    On hh_cred.tx_number = daily.rcpt_or_plg_number
  ) Union All (
  -- Internal transfer; 344303 is 50%
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
    , 344303 As hh_credit
    , 344303 As hh_recognition_credit
  From nu_rpt_t_cmmt_dtl_daily daily
  Inner Join entity On entity.id_number = daily.id_number
  Inner Join allocation On allocation.allocation_code = daily.alloc_code
  Inner Join primary_gift On primary_gift.prim_gift_receipt_number = daily.rcpt_or_plg_number
  Where daily.rcpt_or_plg_number = '0002275766'
  )
  ;

/* Special handling concatenated definition */
Cursor c_special_handling_concat Is
  With
  -- Special handling entities
  spec_hnd As (
    Select
      h.id_number
      , e.spouse_id_number
      , Listagg(
          ht.short_desc ||
          Case
            When ds.short_desc Is Not Null Then ' (' || ds.short_desc || ')'
            Else NULL
          End
          , '; '
        ) Within Group (Order By ht.short_desc Asc)
        As special_handling_concat
      , Listagg(h.hnd_type_code, '; ') Within Group (Order By ht.short_desc Asc)
        As spec_hnd_codes
      -- No contact
      , max(Case When h.hnd_type_code = 'NC' Then 'Y' End)
        As no_contact
      -- No solicit
      , max(Case When h.hnd_type_code = 'DNS' Then 'Y' End)
        As no_solicit
      -- No release
      , max(Case When h.hnd_type_code = 'DNR' Then 'Y' End)
        As no_release
      -- Active with restrictions
      , max(Case When h.hnd_type_code = 'AWR' Then 'Y' End)
        As active_with_restrictions
      -- Never engaged forever
      , max(Case When h.hnd_type_code = 'NED' Then 'Y' End)
        As never_engaged_forever
      -- Never engaged reunion
      , max(Case When h.hnd_type_code = 'NDR' Then 'Y' End)
        As never_engaged_reunion
      -- Has opt-outs
      , max(Case When h.hnd_type_code = 'OOO' Or h.hnd_type_code = 'OIO' Then 'Y' End)
        As has_opt_ins_opt_outs
      -- No phone
      , max(Case When h.hnd_type_code = 'DNP' Then 'Y' End)
        As no_phone
      -- No phone solicitation
      , max(Case When h.hnd_type_code = 'NPS' Then 'Y' End)
        As no_phone_solicit
      -- No email
      , max(Case When h.hnd_type_code = 'NE' Then 'Y' End)
        As no_email
      -- No email solicitation
      , max(Case When h.hnd_type_code = 'NES' Then 'Y' End)
        As no_email_solicit
      -- No postal mail
      , max(Case When h.hnd_type_code = 'NM' Then 'Y' End)
        As no_mail
      -- No postal solicitation
      , max(Case When h.hnd_type_code = 'NMS' Then 'Y' End)
        As no_mail_solicit
      -- No texts
      , max(Case When h.hnd_type_code = 'NTX' Then 'Y' End)
        As no_texts
      -- No text solicitation
      , max(Case When h.hnd_type_code = 'NTS' Then 'Y' End)
        As no_texts_solicit
      -- Anonymous donor
      , max(Case When h.hnd_type_code = 'AN' Then 'Y' End)
        As anonymous_donor
    From handling h
    Inner Join entity e On e.id_number = h.id_number
    Inner Join tms_handling_type ht On ht.handling_type = h.hnd_type_code
    Left Join tms_data_source ds On ds.data_source_code = h.data_source_code
    Where h.hnd_status_code = 'A'
      And h.hnd_type_code Not In ( -- Interest codes list
        'CPG', 'ENT', 'FB', 'FW', 'HF', 'MAR', 'MCE', 'MFU', 'MLC'
        , 'NYF', 'NYW', 'PER', 'SPC', 'SRC', 'TEC', 'TF', 'VC'
      )
    Group By
      h.id_number
      , e.spouse_id_number
  )
  -- Mailing list entities
  , mailing_lists As (
    Select
      ml.id_number
      , e.spouse_id_number
      , Listagg(
          trim(
            mlc.short_desc || Case When uc.unit_code <> ' ' Then ' ' End || trim(uc.unit_code)
            || Case When c.short_desc Is Not Null Then ' (' || c.short_desc || ')' End
          )
          , '; '
        ) Within Group (Order By mlc.short_desc Asc)
        As mailing_list_concat
      , Listagg(
          trim(
            ml.mail_list_code || Case When ml.unit_code <> ' ' Then ' ' End || trim(ml.unit_code)
            || ' ' || ml.mail_list_ctrl_code
          )
          , '; '
        ) Within Group (Order By mlc.short_desc Asc)
        As ml_codes
      -- All communication
      , max(Case When ml.mail_list_code = 'AC' And ml.mail_list_ctrl_code = 'EXC' Then 'Y' End)
        As exc_all_comm
      -- All solicitation
      , max(Case When ml.mail_list_code = 'AS' And ml.mail_list_ctrl_code = 'EXC' Then 'Y' End)
        As exc_all_sols
      -- Phonathon communication
      , max(Case When ml.mail_list_code = 'PC' And ml.mail_list_ctrl_code = 'EXC' Then 'Y' End)
        As exc_phone_comm
      -- Phonathon solicitation
      , max(Case When ml.mail_list_code = 'PS' And ml.mail_list_ctrl_code = 'EXC' Then 'Y' End)
        As exc_phone_sols
      -- Email communication
      , max(Case When ml.mail_list_code = 'EC' And ml.mail_list_ctrl_code = 'EXC' Then 'Y' End)
        As exc_email_comm
      -- Email solicitation
      , max(Case When ml.mail_list_code = 'ES' And ml.mail_list_ctrl_code = 'EXC' Then 'Y' End)
        As exc_email_sols
      -- Mail communication
      , max(Case When ml.mail_list_code = 'MC' And ml.mail_list_ctrl_code = 'EXC' Then 'Y' End)
        As exc_mail_comm
      -- Mail solicitation
      , max(Case When ml.mail_list_code = 'MS' And ml.mail_list_ctrl_code = 'EXC' Then 'Y' End)
        As exc_mail_sols
    From mailing_list ml
    Inner Join entity e On e.id_number = ml.id_number
    Inner Join tms_mail_list_code mlc On ml.mail_list_code = mlc.mail_list_code_code
    Left Join tms_unit_code uc On ml.unit_code = uc.unit_code
    Left Join tms_mail_list_ctrl c On ml.mail_list_ctrl_code = c.mail_list_ctrl_code
    Where ml.mail_list_status_code = 'A'
       And (
         -- Must be a KSM mailing list, or blank with one of the exclusion preferences
         ml.unit_code = 'KM'
         Or (
          ml.unit_code = ' '
          And ml.mail_list_code In ('AC', 'AS', 'PC', 'PS', 'EC', 'ES', 'MC', 'MS')
         )
       )
    Group By
      ml.id_number
      , e.spouse_id_number
  )
  -- Alerts
  , all_alerts As (
    Select
      id_number
      , start_date
      , stop_date
      , message
      -- Kellogg Stewardship Issue indicator
      , Case
          When lower(message) Like '%ksm%stewardship%issue%'
            Or lower(message) Like '%kellogg%stewardship%issue%'
            Then 'Y'
          End
        As ksm_stewardship_issue
    From zz_alert_message
  )
  , alerts As (
    Select
      all_alerts.id_number
      , e.spouse_id_number
      , start_date
      , stop_date
      , message As alert_message
      , ksm_stewardship_issue
    From all_alerts
    Inner Join entity e
      On e.id_number = all_alerts.id_number
    Where
      ksm_stewardship_issue = 'Y'
      -- Or other indicators, if ever added
  )
  -- All IDs
  , ids As (
    Select id_number, spouse_id_number
    From spec_hnd
    Union
    Select id_number, spouse_id_number
    From mailing_lists
    Union
    Select id_number, spouse_id_number
    From alerts
  )
  -- Universal no contact or no solicit
  -- Anyone with one of a few select codes should NEVER be contacted or solicited
  , unc_ids As (
    Select
      ids.id_number
      , ids.spouse_id_number
      , Case
          When no_contact = 'Y'
            Or exc_all_comm = 'Y'
            Or active_with_restrictions = 'Y'
            Then 'Y'
          End
        As univ_no_contact
      , Case
          When no_contact = 'Y'
            Or exc_all_comm = 'Y'
            Or active_with_restrictions = 'Y'
            Or no_solicit = 'Y'
            Or exc_all_sols = 'Y'
            Then 'Y'
          End
        As univ_no_solicit
    From ids
    Left Join spec_hnd On spec_hnd.id_number = ids.id_number
    Left Join mailing_lists On mailing_lists.id_number = ids.id_number
  )
  -- Main query
  Select
    ids.id_number
    , trim(ids.spouse_id_number) As spouse_id_number
    , spec_hnd.special_handling_concat
    , spec_hnd.spec_hnd_codes
    , mailing_lists.mailing_list_concat
    , mailing_lists.ml_codes
    -- Overall special handling indicators
    , spec_hnd.no_contact
    , spec_hnd.no_solicit
    , spec_hnd.no_release
    , spec_hnd.active_with_restrictions
    , spec_hnd.never_engaged_forever
    , spec_hnd.never_engaged_reunion
    , spec_hnd.has_opt_ins_opt_outs
    , spec_hnd.anonymous_donor
    -- Overall mailing list indicators
    , exc_all_comm
    , exc_all_sols
    -- No phone combined
    , Case
        When univ_no_contact = 'Y'
          Or no_phone = 'Y'
          Then 'Y'
      End As no_phone_ind
    -- No phone solicit combined
    , Case
        When univ_no_contact = 'Y'
          Or no_phone = 'Y'
          Or univ_no_solicit = 'Y'
          Or no_phone_solicit = 'Y'
          Then 'Y'
      End As no_phone_sol_ind
    -- No email combined
    , Case
        When univ_no_contact = 'Y'
          Or no_email = 'Y'
          Or exc_email_comm = 'Y'
          Then 'Y'
      End As no_email_ind
    -- No email solicit combined
    , Case
        When univ_no_contact = 'Y'
          Or no_email = 'Y'
          Or univ_no_solicit = 'Y'
          Or no_email_solicit = 'Y'
          Or exc_email_comm = 'Y'
          Or exc_email_sols = 'Y'
          Then 'Y'
      End As no_email_sol_ind
    -- No mail combined
    , Case
        When univ_no_contact = 'Y'
          Or no_mail = 'Y'
          Or exc_mail_comm = 'Y'
            Then 'Y'
      End As no_mail_ind
    -- No mail solicit combined
    , Case
        When univ_no_contact = 'Y'
          Or no_mail = 'Y'
          Or univ_no_solicit = 'Y'
          Or no_mail_solicit = 'Y'
          Or exc_mail_comm = 'Y'
          Or exc_mail_sols = 'Y'
            Then 'Y'
      End As no_mail_sol_ind
    -- No texts combined
    , Case
        When univ_no_contact = 'Y'
          Or no_texts = 'Y'
          Then 'Y'
      End As no_texts_ind
    -- No texts solicit combined
    , Case
        When univ_no_contact = 'Y'
          Or no_texts = 'Y'
          Or univ_no_solicit = 'Y'
          Or no_texts_solicit = 'Y'
          Then 'Y'
      End As no_texts_sol_ind
    -- Alerts
    , alerts.ksm_stewardship_issue
  From unc_ids ids
  Left Join spec_hnd On spec_hnd.id_number = ids.id_number
  Left Join mailing_lists On mailing_lists.id_number = ids.id_number
  Left Join alerts On alerts.id_number = ids.id_number
  ;

/*************************************************************************
Private type declarations
*************************************************************************/

/*************************************************************************
Private table declarations
*************************************************************************/

/*************************************************************************
Private constant declarations
*************************************************************************/

/* Segments */
seg_af_10k Constant segment.segment_code%type := 'KMAA_'; -- AF $10K model pattern
seg_mg_id Constant segment.segment_code%type := 'KMID_'; -- MG identification model pattern
seg_mg_pr Constant segment.segment_code%type := 'KMPR_'; -- MG prioritization model pattern

/*************************************************************************
Private variable declarations
*************************************************************************/

/*************************************************************************
Functions
*************************************************************************/

/* Calculates the modulo function; needed to correct Oracle mod() weirdness
   2017-02-08 */
Function math_mod(m In number, n In number)
  Return number Is
  -- Declarations
  remainder number;

  Begin
    remainder := mod(m - n * floor(m/n), n);
    Return(remainder);
  End;

/* Check whether a passed yyyymmdd string can be parsed sucessfully as a date 
   2019-01-24 */
Function to_date2(str In varchar2, format In varchar2)
  Return date Is
  
  Begin
    Return to_date(str, format);
    Exception
      When Others Then
        Return NULL;
  End;

/* Check whether a passed string can be parsed sucessfully as a number
   2019-08-02 */
Function to_number2(str In varchar2)
  Return number Is
  
  Begin
    Return to_number(str);
    Exception
      When Others Then
        Return NULL;
  End;

/* Takes a yyyymmdd string and an optional fallback date argument and produces a date type
   2019-01-24 */
Function date_parse(str In varchar2, dt In date)
  Return date Is
  -- Declarations
  dt_out date;
  -- Parsed from string
  y varchar2(4);
  m varchar2(2);
  d varchar2(2);
  -- Parsed from fallback date
  fy varchar2(4);
  fm varchar2(2);
  fd varchar2(2);
  
  Begin
    -- Try returning str as-is (y-m-d) as a date
    dt_out := to_date2(str);
    If dt_out Is Not Null Then
      Return(dt_out);
    End If;
    
    -- Extract ymd
    y    := substr(str, 1, 4);
    m    := substr(str, 5, 2);
    d    := substr(str, 7, 2);
    fy   := lpad(extract(year from dt), 4, '0');
    fm   := lpad(extract(month from dt), 2, '0');
    fd   := lpad(extract(day from dt), 2, '0');
    
    -- Try returning y-m-01
    dt_out := to_date2(y || m || '01');
    If dt_out Is Not Null Then
      Return(dt_out);
    End If;
    -- Try returning y-fm-fd
    dt_out := to_date2(y || fm || fd);
    If dt_out Is Not Null Then
      Return(dt_out);
    End If;
    -- Try returning fy-m-d
    dt_out := to_date2(fy || m || d);
    If dt_out Is Not Null Then
      Return(dt_out);
    End If;
    -- Try returning fy-m-01
    dt_out := to_date2(fy || m || '01');
    If dt_out Is Not Null Then
      Return(dt_out);
    End If;
    -- If all else fails return the fallback date
    Return(trunc(dt));
    
  End;


/* Fiscal year to date indicator: Takes as an argument any date object and returns Y/N
   2017-02-08 */
Function fytd_indicator(dt In date, day_offset In number)
  Return character Is
  -- Declarations
  output character;
  today_fisc_day number;
  today_fisc_mo number;
  dt_fisc_day number;
  dt_fisc_mo number;

  Begin
    -- extract dt fiscal month and day
    today_fisc_day := extract(day from sysdate);
    today_fisc_mo  := math_mod(m => extract(month from sysdate) - fy_start_month, n => 12) + 1;
    dt_fisc_day    := extract(day from dt);
    dt_fisc_mo     := math_mod(m => extract(month from dt) - fy_start_month, n => 12) + 1;
    -- logic to construct output
    If dt_fisc_mo < today_fisc_mo Then
      -- if dt_fisc_mo is earlier than today_fisc_mo no need to continue checking
      output := 'Y';
    ElsIf dt_fisc_mo > today_fisc_mo Then
      output := 'N';
    ElsIf dt_fisc_mo = today_fisc_mo Then
      If dt_fisc_day <= today_fisc_day + day_offset Then
        output := 'Y';
      Else
        output := 'N';
      End If;
    Else
      -- fallback condition
      output := NULL;
    End If;
    
    Return(output);
  End;

/* Retrieve one of the named constants from the package 
   Requires a quoted constant name
   2019-03-19 */
Function get_numeric_constant(const_name In varchar2)
  Return number Deterministic Is
  -- Declarations
  val number;
  var varchar2(100);
  
  Begin
    -- If const_name doesn't include ksm_pkg, prepend it
    If substr(lower(const_name), 1, 8) <> 'ksm_pkg.'
      Then var := 'ksm_pkg.' || const_name;
    Else
      var := const_name;
    End If;
    -- Run command
    Execute Immediate
      'Begin :val := ' || var || '; End;'
      Using Out val;
      Return val;
  End;

/* Compute fiscal or performance quarter from date
   Defaults to fiscal quarter
   2018-04-06 */
Function get_quarter(dt In date, fisc_or_perf In varchar2 Default 'fiscal')
  Return number Is
  -- Declarations
  this_month number;
  chron_month number;
  
  Begin
    this_month := extract(month from dt);
    -- Convert to chronological month number, where FY/PY start month = 1
    If lower(fisc_or_perf) Like 'f%' Then
      chron_month := math_mod(this_month - fy_start_month, 12) + 1;
    ElsIf lower(fisc_or_perf) Like 'p%' Then
      chron_month := math_mod(this_month - py_start_month, 12) + 1;
    End If;
    -- Return appropriate quarter corresponding to month; 3 months per quarter
    Return ceil(chron_month / 3);
  End;

/* Compute fiscal year from date parameter
   2017-03-15 */
-- Date version
Function get_fiscal_year(dt In date)
  Return number Is
  -- Declarations
  this_year number;
  
  Begin
    this_year := extract(year from dt);
    -- If month is before fy_start_month, return this_year
    If extract(month from dt) < fy_start_month
      Or fy_start_month = 1 Then
      Return this_year;
    End If;
    -- Otherwise return out_year + 1
    Return (this_year + 1);
  End;
-- String version
Function get_fiscal_year(dt In varchar2, format In varchar2)
  Return number Is
  -- Declarations
  this_year number;
  
  Begin
    this_year := extract(year from to_date(dt, format));
    -- If month is before fy_start_month, return this_year
    If extract(month from to_date(dt, format)) < fy_start_month
      Or fy_start_month = 1 Then
      Return this_year;
    End If;
    -- Otherwise return out_year + 1
    Return (this_year + 1);
  End;

/* Compute performance year from date parameter
   2018-04-06 */
-- Date version
Function get_performance_year(dt In date)
  Return number Is
  -- Declarations
  this_year number;
  
  Begin
    this_year := extract(year from dt);
    -- If year is pre 2020 use the old start month
    If this_year < 2020 Then
      If extract(month from dt) < py_start_month_pre_py21 Then
        Return this_year;
      End If;
      Return (this_year + 1);
    End If;
    -- If month is before fy_start_month, return this_year
    If extract(month from dt) < py_start_month
      Or py_start_month = 1 Then
      Return this_year;
    End If;
    -- Otherwise return out_year + 1
    Return (this_year + 1);
  End;

/* Fast degree years concat
   2017-02-15 */
Function get_entity_degrees_concat_fast(id In varchar2)
  Return varchar2 Is
  -- Declarations
  deg_conc varchar2(1024);
  
  Begin
  
    Select
      -- Concatenated degrees string
      Listagg(
        trim(degree_year || ' ' || degree_code || ' ' || school_code || ' ' || 
          tms_dept_code.short_desc || ' ' || class_section), '; '
      ) Within Group (Order By degree_year) As degrees_concat
    Into deg_conc
    From degrees
      Left Join tms_dept_code On degrees.dept_code = tms_dept_code.dept_code
    Where institution_code = '31173'
      And school_code in('BUS', 'KSM')
      And id_number = id
    Group By id_number;
    
    Return deg_conc;
  End;

/* Takes an ID and returns xsequence of master address, defined as preferred if available, else home,
   else business.
   2017-02-15 */
Function get_entity_address_master_xseq(id In varchar2, debug In Boolean Default FALSE)
  Return number Is
  -- Declarations
  xseq number(6); -- final xsequence of address to retrieve
  
  -- Address types available for consideration as master/primary address
  Cursor c_address_types Is
    With
    pref As (
      Select id_number, xsequence As pref_xseq
      From address
      Where addr_status_code = 'A' And addr_pref_ind = 'Y'
    ),
    home As (
      Select id_number, xsequence As home_xseq
      From address
      Where addr_status_code = 'A' And addr_type_code = 'H'
    ),
    bus As (
      Select id_number, xsequence As bus_xseq
      From address
      Where addr_status_code = 'A' And addr_type_code = 'B'
    )
    -- Combine preferred, home, and business xseq into a row
    Select pref_xseq, home_xseq, bus_xseq
    From entity
      Left Join pref On entity.id_number = pref.id_number
      Left Join home On entity.id_number = home.id_number
      Left Join bus On entity.id_number = bus.id_number
    Where entity.id_number = id;

  -- Table to hold address xsequence numbers
  Type t_number Is Table Of c_address_types%rowtype;
    t_xseq t_number;
  
  Begin
    -- Determine which xsequence to use for master address
    Open c_address_types;
      Fetch c_address_types Bulk Collect Into t_xseq;
    Close c_address_types;
    
    -- Debug -- print the retrieved address xsequence numbers
    If debug Then
      dbms_output.put_line('P: ' || t_xseq(1).pref_xseq || '; H: ' || t_xseq(1).home_xseq ||
        '; B: ' || t_xseq(1).bus_xseq);
    End If;
    
    -- Store best choice in xseq
    If t_xseq(1).pref_xseq Is Not Null Then xseq := t_xseq(1).pref_xseq;
    ElsIf t_xseq(1).home_xseq Is Not Null Then xseq := t_xseq(1).home_xseq;
    ElsIf t_xseq(1).bus_xseq Is Not Null Then xseq := t_xseq(1).bus_xseq;
    Else xseq := 0;
    End If;
    
    Return xseq;
  End;

/* Takes an ID and field and returns active address part from master address. Standardizes input
   fields to lower-case.
   2017-02-15 */
Function get_entity_address(id In varchar2, field In varchar2, debug In Boolean Default FALSE)
  Return varchar2 Is
  -- Declarations
  master_addr varchar2(120); -- final output
  field_ varchar2(60) := lower(field); -- lower-case field
  xseq number; -- stores master address xsequence
   
  Begin
    -- Determine the xsequence of the master address
    xseq := get_entity_address_master_xseq(id => id, debug => debug);
    -- Debug -- print the retrieved master address sequence and field type
    If debug Then dbms_output.put_line(xseq || ' ' || field || ' is: ');
    End If;
    -- Retrieve the master address
    If xseq = 0 Then Return('LOST_ALUMNI'); -- failsafe condition
    End If;
     -- Big Case-When to fill in the appropriate field
    Select Case
      When field_ = 'care_of' Then care_of
      When field_ = 'company_name_1' Then company_name_1
      When field_ = 'company_name_2' Then company_name_2
      When field_ = 'business_title' Then business_title
      When field_ = 'street1' Then street1
      When field_ = 'street2' Then street2
      When field_ = 'street3' Then street3
      When field_ = 'foreign_cityzip' Then foreign_cityzip
      When field_ = 'city' Then city
      When field_ = 'state_code' Then address.state_code
      When field_ Like 'state%' Then tms_states.short_desc
      When field_ = 'zipcode' Then zipcode
      When field_ = 'zip_suffix' Then zip_suffix
      When field_ = 'postnet_zip' Then postnet_zip
      When field_ = 'county_code' Then address.county_code
      When field_ Like 'county%' Then tms_county.full_desc
      When field_ = 'country_code' Then address.country_code
      When field_ Like 'country%' Then tms_country.short_desc
    End
    Into master_addr
    From address
      Left Join tms_country On address.country_code = tms_country.country_code
      Left Join tms_states On address.state_code = tms_states.state_code
      Left Join tms_county On address.county_code = tms_county.county_code
    Where id_number = id And xsequence = xseq;
    
    Return(master_addr);
  End;

/* Take a string containing a dollar amount and extract the (first) numeric value */
Function get_number_from_dollar(str In varchar2) 
  Return number Is
  -- Delcarations
  trimmed varchar2(32);
  mult number;
  amt number;
  
  Begin
    -- Regular expression: extract string starting with $ up to the last digit, period, or comma,
    Select
      -- Target substring starts with a dollar sign and may contain 0-9,.KMB
      regexp_substr(upper(str), '\$[0-9,KMB\.]*')
    Into trimmed
    From DUAL;
    
    -- Look for suffixes K and M and B and calculate the appropriate multiplier
    Select
      Case
        When trimmed Like '%K%' Then 1E3 -- K = thousand = 1,000
        When trimmed Like '%M%' Then 1E6 -- M = million = 1,000,000
        When trimmed Like '%B%' Then 1E9 -- B = billion = 1,000,000,000
        Else 1
      End As mult
    Into mult
    From DUAL;
    
    -- Strip the $ and commas and letters and treat as numeric
    Select
      -- Convert string to numeric
      to_number(
        regexp_replace(
          trimmed
          , '[^0-9\.]' -- Remove non-numeric characters
          , '') -- Replace non-numeric characters with null
        )
    Into amt
    From DUAL;
    
    Return amt * mult;
  End;

/* Convert rating to numeric amount */
Function get_prospect_rating_numeric(id In varchar2)
  Return number Is
  -- Delcarations
  numeric_rating number;
  
  Begin
    -- Convert officer rating or evaluation rating into numeric values
    Select Distinct
      Case
        -- If officer rating exists
        When officer_rating <> ' ' Then
          Case
            When trim(substr(officer_rating, 1, 2)) = 'H' Then 0 -- Under $10K is 0
            Else get_number_from_dollar(officer_rating) / 1000000 -- Everything else in millions
          End
        -- Else use evaluation rating
        When evaluation_rating <> ' ' Then
          Case
            When trim(substr(evaluation_rating, 1, 2)) = 'H' Then 0
            Else get_number_from_dollar(evaluation_rating) / 1000000 -- Everthing else in millions
          End
        Else 0
      End
    Into numeric_rating
    From nu_prs_trp_prospect
    Where id_number = id;
  
    Return numeric_rating;
  End;

/* Binned numeric prospect ratings */
Function get_prospect_rating_bin(id In varchar2)
  Return number Is
  -- Delcarations
  numeric_rating number;
  numeric_bin number;
  
  Begin
    -- Convert officer rating or evaluation rating into numeric values
    numeric_rating := get_prospect_rating_numeric(id);
    -- Bin numeric_rating amount
    Select
      Case
        When numeric_rating >= 10 Then 10
        When numeric_rating = 0.25 Then 0.1
        When numeric_rating < 0.1 Then 0
        Else numeric_rating
      End
    Into numeric_bin
    From DUAL;
  
    Return numeric_bin;
  End;

/* Takes a receipt number and returns the ID number of the entity who should receive primary Kellogg gift credit.
   Relies on nu_gft_trp_gifttrans, which combines gifts and matching gifts into a single table.
   Kellogg alumni status is defined as get_entity_degrees_concat_ksm(id_number) returning a non-null result.
   2017-02-09 */
Function get_gift_source_donor_ksm(receipt In varchar2, debug In boolean Default FALSE)
  Return varchar2 Is
  -- Declarations
  gift_type char(1); -- GPYM indicator
  donor_type char(1); -- record type of primary associated donor
  id_tmp varchar2(10); -- temporary holder for id_number or receipt
    
  -- Table type corresponding to above cursor
  Type t_results Is Table Of c_source_donor_ksm%rowtype;
    results t_results;

  Begin
    -- Check if the receipt is a matching gift
    Select Distinct gift.tx_gypm_ind
    Into gift_type
    From nu_gft_trp_gifttrans gift
    Where gift.tx_number = receipt;

  -- For matching gifts, recursively run this function but replace the matching gift receipt with matched receipt
    If gift_type = 'M' Then
      -- If debug, mention that it's a matched gift
      If debug Then
        dbms_output.put_line('==== Matching Gift! ====' || chr(10) || '*Matching receipt: ' || receipt);
      End If;
      -- Pull the matched receipt into id_tmp
      Select gift.matched_receipt_nbr
      Into id_tmp
      From nu_gft_trp_gifttrans gift
      Where gift.tx_number = receipt;
      -- Run id_tmp through this function
      id_tmp := get_gift_source_donor_ksm(receipt => id_tmp,  debug => debug);
      -- Return found ID and break out of function
      Return(id_tmp);
    End If;

  -- For any other type of gift, proceed through the hierarchy of potential source donors

    -- Retrieve c_source_donor_ksm cursor results
    Open c_source_donor_ksm(receipt => receipt);
      Fetch c_source_donor_ksm Bulk Collect Into results;
    Close c_source_donor_ksm;
    
    -- Debug -- test that the cursors worked --
    If debug Then
      dbms_output.put_line('==== Cursor Results ====' || chr(10) || '*Gift receipt: ' || receipt);
      -- Loop through the lists
      For i In 1..(results.count) Loop
        -- Concatenate output
        dbms_output.put_line(results(i).id_number || '; ' || results(i).ksm_degrees || '; ' || results(i).person_or_org || '; ' ||
          results(i).associated_code || '; ' || results(i).credit_amount);
      End Loop;
    End If;

    -- Check if the primary donor has a KSM degree
    For i In 1..(results.count) Loop
      If results(i).associated_code = 'P' Then
        -- Store the record type of the primary donor
        donor_type := results(i).person_or_org;
        -- If the primary donor is a KSM alum we're done
        If results(i).ksm_degrees Is Not Null Then
          Return(results(i).id_number);
        -- Otherwise jump to next check
        Else Exit;
        End If;
      End If;
    End Loop;
    
    -- Check if any non-primary donors have a KSM degree; grab first that has a non-null l_degrees
    -- IMPORTANT: this means the cursor c_source_donor_ksm needs to be sorted in preferred order!
    For i In 1..(results.count) Loop
      -- If we find a KSM alum we're done
      If results(i).ksm_degrees Is Not Null Then
        Return(results(i).id_number);
      End If;
    End Loop;
    
    -- Check if the primary donor is an organization; if so, grab first person who's associated
    -- IMPORTANT: this means the cursor c_source_donor_ksm needs to be sorted in preferred order!
    -- If primary record type is not person, continue
    If donor_type != 'P' Then  
      For i In 1..(results.count) Loop
        If results(i).person_or_org = 'P' Then
          return(results(i).id_number);
        End If;
      End Loop;  
    End If;
    
    -- Fallback is to use the existing primary donor ID
    For i In 1..(results.count) Loop
      -- If we find a KSM alum we're done
      If results(i).associated_code = 'P' Then
        Return(results(i).id_number);
      End If;
    End Loop;
    -- If we got all the way to the end, return null
    Return(NULL);
    
  End;

/*************************************************************************
Pipelined functions
*************************************************************************/

/* Pipelined function returning Kellogg Annual Fund allocations, both active and historical
   2017-02-09 */
Function tbl_alloc_annual_fund_ksm
  Return t_allocation Pipelined As
    -- Declarations
    allocs t_allocation;

  Begin
    Open ct_alloc_annual_fund_ksm; -- Annual Fund allocations cursor
      Fetch ct_alloc_annual_fund_ksm Bulk Collect Into allocs;
    Close ct_alloc_annual_fund_ksm;
    -- Pipe out the allocations
    For i in 1..(allocs.count) Loop
      Pipe row(allocs(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning Kellogg current use allocations
   2017-07-11 */
Function tbl_alloc_curr_use_ksm
  Return t_allocation Pipelined As
    -- Declarations
    allocs t_allocation;

  Begin
    Open c_alloc_curr_use_ksm; -- Annual Fund allocations cursor
      Fetch c_alloc_curr_use_ksm Bulk Collect Into allocs;
    Close c_alloc_curr_use_ksm;
    -- Pipe out the allocations
    For i in 1..(allocs.count) Loop
      Pipe row(allocs(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning the current calendar definition
   2017-09-21 */
Function tbl_current_calendar
  Return t_calendar Pipelined As
  -- Declarations
  cal t_calendar;
    
  Begin
    Open c_current_calendar(fy_start_month, py_start_month);
      Fetch c_current_calendar Bulk Collect Into cal;
    Close c_current_calendar;
    For i in 1..(cal.count) Loop
      Pipe row(cal(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning a randomly generated ID conversion table
   2020-02-11 */
Function tbl_random_id
  Return t_random_id Pipelined As
  -- Declarations
  rid t_random_id;
  
  Begin
    Open c_random_id;
      Fetch c_random_id Bulk Collect Into rid;
    Close c_random_id;
    For i in 1..(rid.count) Loop
      Pipe row(rid(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning all non-null entity_degrees_concat_ksm rows
   2017-02-15 */
Function tbl_entity_degrees_concat_ksm
  Return t_degreed_alumni Pipelined As
  -- Declarations
  degrees t_degreed_alumni;
    
  Begin
    Open c_entity_degrees_concat_ksm;
      Fetch c_entity_degrees_concat_ksm Bulk Collect Into degrees;
    Close c_entity_degrees_concat_ksm;
    For i in 1..(degrees.count) Loop
      Pipe row(degrees(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning concatenated geo codes for all addresses
   2019-11-05 */
Function tbl_geo_code_primary
  Return t_geo_code_primary Pipelined As
  -- Declarations
  geo t_geo_code_primary;
  
  Begin
    Open c_geo_code_primary;
      Fetch c_geo_code_primary Bulk Collect Into geo;
    Close c_geo_code_primary;
    For i in 1..(geo.count) Loop
      Pipe row(geo(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning households and household degree information
   2017-02-15 */
Function tbl_entity_households_ksm
  Return t_households Pipelined As
  -- Declarations
  households t_households;
  
  Begin
    Open c_entity_households_ksm;
      Fetch c_entity_households_ksm Bulk Collect Into households;
    Close c_entity_households_ksm;
    For i in 1..(households.count) Loop
      Pipe row(households(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning Kellogg alumni (per c_entity_degrees_concat_ksm) who
   work for the specified company
   2017-07-25 */
Function tbl_entity_employees_ksm (company In varchar2)
  Return t_employees Pipelined As
  -- Declarations
  employees t_employees;
  
  Begin
    Open c_entity_employees_ksm (company => company);
      Fetch c_entity_employees_ksm Bulk Collect Into employees;
    Close c_entity_employees_ksm;
    For i in 1..(employees.count) Loop
      Pipe row(employees(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning Kellogg top 150/300 Campaign prospects
   Coded in Prospect Categories; see cursor for definition 
   2017-12-20 */
Function tbl_entity_top_150_300
  Return t_prospect_categories Pipelined As
  -- Declarations
  prospects t_prospect_categories;
  
  Begin
    Open c_entity_top_150_300;
      Fetch c_entity_top_150_300 Bulk Collect Into prospects;
    Close c_entity_top_150_300;
    For i in 1..(prospects.count) Loop
      Pipe row(prospects(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning KLC members (per c_klc_history)
   2017-07-26 */
Function tbl_klc_history
  Return t_klc_members Pipelined As
  -- Declarations
  klc t_klc_members;
  
  Begin
    Open c_klc_history(fy_start_month);
      Fetch c_klc_history Bulk Collect Into klc;
    Close c_klc_history;
    For i in 1..(klc.count) Loop
      Pipe row(klc(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning frontline KSM staff (per c_frontline_ksm_staff)
   2017-09-26 */
Function tbl_frontline_ksm_staff
  Return t_ksm_staff Pipelined As
  -- Declarations
  staff t_ksm_staff;
    
  Begin
    Open ct_frontline_ksm_staff;
      Fetch ct_frontline_ksm_staff Bulk Collect Into staff;
    Close ct_frontline_ksm_staff;
    For i in 1..(staff.count) Loop
      Pipe row(staff(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning prospect entity table filtered for active prospects
   2018-08-14 */
Function tbl_prospect_entity_active
  Return t_prospect_entity_active Pipelined As
  -- Declarations
  pe t_prospect_entity_active;
    
  Begin
    Open c_prospect_entity_active;
      Fetch c_prospect_entity_active Bulk Collect Into pe;
    Close c_prospect_entity_active;
    For i in 1..(pe.count) Loop
      Pipe row(pe(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning current/historical NU ARD employees (per c_nu_ard_staff)
   2018-01-17 */
Function tbl_nu_ard_staff
  Return t_nu_ard_staff Pipelined As
  -- Declarations
  staff t_nu_ard_staff;
    
  Begin
    Open c_nu_ard_staff;
      Fetch c_nu_ard_staff Bulk Collect Into staff;
    Close c_nu_ard_staff;
    For i in 1..(staff.count) Loop
      Pipe row(staff(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning current university strategies (per c_university_strategy)
   2017-09-29 */
Function tbl_university_strategy
  Return t_university_strategy Pipelined As
  -- Declarations
  task t_university_strategy;
    
  Begin
    Open c_university_strategy;
      Fetch c_university_strategy Bulk Collect Into task;
    Close c_university_strategy;
    For i in 1..(task.count) Loop
      Pipe row(task(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning numeric capacity and binned capacity */
Function tbl_numeric_capacity_ratings
  Return t_numeric_capacity Pipelined As
  -- Declarations
  caps t_numeric_capacity;
  
  Begin
    Open ct_numeric_capacity_ratings;
      Fetch ct_numeric_capacity_ratings Bulk Collect Into caps;
    Close ct_numeric_capacity_ratings;
    For i in 1..(caps.count) Loop
      Pipe row(caps(i));
    End Loop;
    Return;
  End;
  
/* Pipelined function for Kellogg modeled scores */

  /* Generic function returning matching segment(s)
     2019-01-23 */
  Function segment_extract (year In integer, month In integer, code In varchar2)
    Return t_modeled_score As
    -- Declarations
    score t_modeled_score;
    
    -- Return table results
    Begin
      Open c_segment_extract (year => year, month => month, code => code);
        Fetch c_segment_extract Bulk Collect Into score;
      Close c_segment_extract;
      Return score;
    End;

  -- AF 10K model
  Function tbl_model_af_10k (model_year In integer, model_month In integer)
    Return t_modeled_score Pipelined As
    -- Declarations
    score t_modeled_score;
    
    Begin
      score := segment_extract (year => model_year, month => model_month, code => seg_af_10k);
      For i in 1..(score.count) Loop
        Pipe row(score(i));
      End Loop;
      Return;
    End;

  -- MG identification model
  Function tbl_model_mg_identification (model_year In integer, model_month In integer)
    Return t_modeled_score Pipelined As
    -- Declarations
    score t_modeled_score;
    
    Begin
      Open c_segment_extract(year => model_year, month => model_month, code => seg_mg_id);
        Fetch c_segment_extract Bulk Collect Into score;
      Close c_segment_extract;
      For i in 1..(score.count) Loop
        Pipe row(score(i));
      End Loop;
      Return;
    End;

  -- MG prioritization model
  Function tbl_model_mg_prioritization (model_year In integer, model_month In integer)
    Return t_modeled_score Pipelined As
    -- Declarations
    score t_modeled_score;
    
    Begin
      Open c_segment_extract(year => model_year, month => model_month, code => seg_mg_pr);
        Fetch c_segment_extract Bulk Collect Into score;
      Close c_segment_extract;
      For i in 1..(score.count) Loop
        Pipe row(score(i));
      End Loop;
      Return;
    End;

/* Pipelined function returning giving credit for entities or households */

  /* Function to return discounted pledge amounts */
  Function plg_discount
    Return t_plg_disc Pipelined As
    -- Declarations
    trans t_plg_disc;
    
    Begin
      Open c_plg_discount;
        Fetch c_plg_discount Bulk Collect Into trans;
      Close c_plg_discount;
      For i in 1..(trans.count) Loop
        Pipe row(trans(i));
      End Loop;
      Return;
    End;

  /* Individual entity giving, all units, based on c_gift_credit
     2019-10-25 */
  Function tbl_gift_credit
    Return t_trans_entity Pipelined As
    -- Declarations
    trans t_trans_entity;
    
    Begin
      Open c_gift_credit;
        Fetch c_gift_credit Bulk Collect Into trans;
      Close c_gift_credit;
      For i in 1..(trans.count) Loop
        Pipe row(trans(i));
      End Loop;
      Return;
    End;
    

  /* Individual entity giving, based on c_gift_credit_ksm
     2017-08-04 */
  Function tbl_gift_credit_ksm
    Return t_trans_entity Pipelined As
    -- Declarations
    trans t_trans_entity;
    
    Begin
      Open c_gift_credit_ksm;
        Fetch c_gift_credit_ksm Bulk Collect Into trans;
      Close c_gift_credit_ksm;
      For i in 1..(trans.count) Loop
        Pipe row(trans(i));
      End Loop;
      Return;
    End;

  /* Householdable entity giving, based on c_gift_credit_hh_ksm
     2017-08-04 */
  Function tbl_gift_credit_hh_ksm
    Return t_trans_household Pipelined As
    -- Declarations
    trans t_trans_household;
    
    Begin
      Open c_gift_credit_hh_ksm;
        Fetch c_gift_credit_hh_ksm Bulk Collect Into trans;
      Close c_gift_credit_hh_ksm;
      For i in 1..(trans.count) Loop
        Pipe row(trans(i));
      End Loop;
      Return;
    End;

  /* Campaign giving by entity, based on c_gifts_campaign_2008
     2017-08-04 */
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

  /* Householdable entity campaign giving, based on c_ksm_trans_hh_campaign_2008
     2017-09-05 */
  Function tbl_gift_credit_hh_campaign
    Return t_trans_household Pipelined As
    -- Declarations
    trans t_trans_household;
    
    Begin
      Open c_gift_credit_hh_campaign_2008;
        Fetch c_gift_credit_hh_campaign_2008 Bulk Collect Into trans;
      Close c_gift_credit_hh_campaign_2008;
      For i in 1..(trans.count) Loop
        Pipe row(trans(i));
      End Loop;
      Return;
    End;

/* Concatenated special handling preferences */

Function tbl_special_handling_concat
    Return t_special_handling Pipelined As
    -- Declarations
    hnd t_special_handling;
    
    Begin
      Open c_special_handling_concat;
        Fetch c_special_handling_concat Bulk Collect Into hnd;
      Close c_special_handling_concat;
      For i in 1..(hnd.count) Loop
        Pipe row(hnd(i));
      End Loop;
      Return;
    End;

/* Pipelined function for Kellogg committees */
  
  /* Generic function returning 'C'urrent or 'A'ctive (deprecated) committee members
     2017-03-01 */
  Function committee_members (my_committee_cd In varchar2)
    Return t_committee_members As
    -- Declarations
    committees t_committee_members;
    
    -- Return table results
    Begin
      Open c_committee_members (my_committee_cd => my_committee_cd);
        Fetch c_committee_members Bulk Collect Into committees;
      Close c_committee_members;
      Return committees;
    End;

  -- GAB
  Function tbl_committee_gab
    Return t_committee_members Pipelined As
    committees t_committee_members;
    
    Begin
      committees := committee_members (my_committee_cd => committee_gab);
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;
  
  -- KAC
  Function tbl_committee_kac
    Return t_committee_members Pipelined As
    committees t_committee_members;
    
    Begin
      committees := committee_members (my_committee_cd => committee_kac);
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;

  -- PHS
  Function tbl_committee_phs
    Return t_committee_members Pipelined As
    committees t_committee_members;
    
    Begin
      committees := committee_members (my_committee_cd => committee_phs);
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;

  -- KFN
  Function tbl_committee_KFN
    Return t_committee_members Pipelined As
    committees t_committee_members;
    
    Begin
      committees := committee_members (my_committee_cd => committee_KFN);
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;

  -- CorpGov
  Function tbl_committee_CorpGov
    Return t_committee_members Pipelined As
    committees t_committee_members;
    
    Begin
      committees := committee_members (my_committee_cd => committee_CorpGov);
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;
    
  -- GlobalWomenSummit
  Function tbl_committee_WomenSummit
    Return t_committee_members Pipelined As
    committees t_committee_members;
    
    Begin
      committees := committee_members (my_committee_cd => committee_WomenSummit);
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;
    
  -- DivSummit
  Function tbl_committee_DivSummit
    Return t_committee_members Pipelined As
    committees t_committee_members;
    
    Begin
      committees := committee_members (my_committee_cd => committee_DivSummit);
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;
    
  -- RealEstCouncil
  Function tbl_committee_RealEstCouncil
    Return t_committee_members Pipelined As
    committees t_committee_members;
    
    Begin
      committees := committee_members (my_committee_cd => committee_RealEstCouncil);
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;

  -- AMP
  Function tbl_committee_AMP
    Return t_committee_members Pipelined As
    committees t_committee_members;
    
    Begin
      committees := committee_members (my_committee_cd => committee_AMP);
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;

  -- Trustees
  Function tbl_committee_trustee
    Return t_committee_members Pipelined As
    committees t_committee_members;
    
    Begin
      committees := committee_members (my_committee_cd => committee_trustee);
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;

    -- Healthcare
    Function tbl_committee_healthcare
      Return t_committee_members Pipelined As
      committees t_committee_members;
      
      Begin
        committees := committee_members (my_committee_cd => committee_healthcare);
        For i in 1..committees.count Loop
          Pipe row(committees(i));
        End Loop;
        Return;
      End;

    -- Women's leadership
    Function tbl_committee_WomensLeadership
      Return t_committee_members Pipelined As
      committees t_committee_members;
      
      Begin
        committees := committee_members (my_committee_cd => committee_WomensLeadership);
        For i in 1..committees.count Loop
          Pipe row(committees(i));
        End Loop;
        Return;
      End;
      
    -- Kellogg Admissions Leadership Council
    Function tbl_committee_KALC
      Return t_committee_members Pipelined As
      committees t_committee_members;
      
      Begin
        committees := committee_members (my_committee_cd => committee_KALC);
        For i in 1..committees.count Loop
          Pipe row(committees(i));
        End Loop;
        Return;
      End;
    
    -- Kellogg Inclusion Coalition
    Function tbl_committee_kic
      Return t_committee_members Pipelined As
      committees t_committee_members;
      
      Begin
        committees := committee_members (my_committee_cd => committee_kic);
        For i in 1..committees.count Loop
          Pipe row(committees(i));
        End Loop;
        Return;
      End;

End ksm_pkg;
/
