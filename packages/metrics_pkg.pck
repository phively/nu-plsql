Create Or Replace Package metrics_pkg Is

/*************************************************************************
Author  : PBH634
Created : 2/13/2020 11:19:42 AM
  Initial CatConnect update 11/20/2025
Purpose : Consolidated gift officer metrics definitions to allow audit
  information to be easily pulled. Adapted from rpt_pbh634.v_mgo_activity_monthly
  and advance_nu.nu_gft_v_officer_metrics.
Dependencies: ksm_pkg_proposals (mv_proposals), ksm_pkg_contact_reports (mv_contact_reports)
*************************************************************************/

/*************************************************************************
Public constant declarations
*************************************************************************/

-- Thresholds for proposals to count toward MGO metrics
mg_ask_amt Constant number := 100E3; -- As of 2018-03-23. Minimum $ to count as ask
mg_ask_amt_ksm_outright Constant number := 100E3; -- As of 2021-05-01. Minimum KSM outright $ to count as ask.
mg_ask_amt_ksm_plg Constant number := 250E3; -- As of 2021-05-01. Minimum KSM pledge $ to count as ask.
mg_granted_amt Constant number := 48E3; -- As of 2018-03-23. Minimum $ to count as granted
mg_funded_count Constant number := 98E3; -- As of 2018-03-23. Minimum $ to count as funded

/*************************************************************************
Public type declarations
*************************************************************************/

--------------------------------------
Type rec_proposals_data Is Record (
  opportunity_salesforce_id mv_proposals.opportunity_salesforce_id%type
  , proposal_record_id mv_proposals.proposal_record_id%type
  , historical_pm_user_id mv_proposals.historical_pm_user_id%type
  , historical_pm_name mv_proposals.historical_pm_name%type
  , historical_pm_role mv_proposals.historical_pm_role%type
  , historical_pm_business_unit mv_proposals.historical_pm_business_unit%type
  , ksm_flag mv_proposals.ksm_flag%type
  , historical_pm_is_active mv_proposals.historical_pm_is_active%type
  , proposal_active_indicator mv_proposals.proposal_active_indicator%type
  , proposal_type mv_proposals.proposal_type%type
  , standard_proposal_flag varchar2(1)
  , proposal_submitted_amount mv_proposals.proposal_submitted_amount%type
  , proposal_funded_amount mv_proposals.proposal_funded_amount%type
  , proposal_stage mv_proposals.proposal_stage%type
  , proposal_created_date mv_proposals.proposal_created_date%type
  , proposal_submitted_date mv_proposals.proposal_submitted_date%type
  , proposal_close_date mv_proposals.proposal_close_date%type
  , cal_year integer
  , cal_month integer
  , fiscal_year integer
  , fiscal_quarter integer
  , perf_year integer
  , perf_quarter integer
);

--------------------------------------
Type rec_proposal_assist_data Is Record (
  opportunity_assignment_salesforce_id stg_alumni.opportunityteammember.id%type
  , opportunity_assignment_role stg_alumni.opportunityteammember.teammemberrole%type
  , opportunity_user_salesforce_id stg_alumni.opportunityteammember.userid%type
  , opportunity_user_name stg_alumni.opportunityteammember.name%type
  , assignment_is_active stg_alumni.opportunityteammember.ap_is_active__c%type
  , proposal_record_id mv_proposals.proposal_record_id%type
  , historical_pm_user_id mv_proposals.historical_pm_user_id%type
  , historical_pm_name mv_proposals.historical_pm_name%type
  , historical_pm_role mv_proposals.historical_pm_role%type
  , historical_pm_business_unit mv_proposals.historical_pm_business_unit%type
  , ksm_flag mv_proposals.ksm_flag%type
  , historical_pm_is_active mv_proposals.historical_pm_is_active%type
  , proposal_active_indicator mv_proposals.proposal_active_indicator%type
  , proposal_type mv_proposals.proposal_type%type
  , standard_proposal_flag varchar2(1)
  , proposal_submitted_amount mv_proposals.proposal_submitted_amount%type
  , proposal_funded_amount mv_proposals.proposal_funded_amount%type
  , proposal_stage mv_proposals.proposal_stage%type
  , proposal_created_date mv_proposals.proposal_created_date%type
  , proposal_submitted_date mv_proposals.proposal_submitted_date%type
  , proposal_close_date mv_proposals.proposal_close_date%type
  , cal_year integer
  , cal_month integer
  , fiscal_year integer
  , fiscal_quarter integer
  , perf_year integer
  , perf_quarter integer
);

--------------------------------------
Type rec_goals_data Is Record (
  work_plan_salesforce_id stg_alumni.ucinn_ascendv2__work_plan__c.id%type
  , work_plan_name stg_alumni.ucinn_ascendv2__work_plan__c.name%type
  , gift_officer_user_salesforce_id stg_alumni.ucinn_ascendv2__work_plan__c.ap_reporting_manager__c%type
  , gift_officer_user_name stg_alumni.user_tbl.name%type
  , gift_officer_donor_id stg_alumni.contact.ucinn_ascendv2__donor_id__c%type
  , gift_officer_sort_name varchar2(300)
  , gift_officer_type stg_alumni.ucinn_ascendv2__work_plan__c.ap_gift_officer_type__c%type
  , gift_officer_role stg_alumni.ucinn_ascendv2__work_plan__c.ucinn_ascendv2__role__c%type
  , gift_officer_status stg_alumni.ucinn_ascendv2__work_plan__c.ucinn_ascendv2__status__c%type
  , metric_performance_year integer
  , metric_effective_date stg_alumni.ucinn_ascendv2__work_plan__c.ucinn_ascendv2__effective_date__c%type
  , mg_commitments_goal stg_alumni.ucinn_ascendv2__work_plan__c.ap_major_gifts_commitments__c%type
  , mg_asks_goal stg_alumni.ucinn_ascendv2__work_plan__c.ucinn_ascendv2__total_major_gift_solicitations__c%type
  , mg_dollars_goal stg_alumni.ucinn_ascendv2__work_plan__c.ap_major_gifts_dollars_raised__c%type
  , visits_goal stg_alumni.ucinn_ascendv2__work_plan__c.ap_visits__c%type
  , qualifications_goal stg_alumni.ucinn_ascendv2__work_plan__c.ap_total_qualification_visits__c%type
  , contacts_goal stg_alumni.ucinn_ascendv2__work_plan__c.ap_non_visit_contacts__c%type
  , proposal_assist_goal stg_alumni.ucinn_ascendv2__work_plan__c.ap_proposal_assist_of_commitments__c%type
  , proposal_assist_dollars_goal stg_alumni.ucinn_ascendv2__work_plan__c.ap_proposal_assist_raised__c%type
  , etl_update_date stg_alumni.ucinn_ascendv2__work_plan__c.etl_update_date%type
);

--------------------------------------
Type rec_funded_credit Is Record (
  proposal_record_id mv_proposals.proposal_record_id%type
  , historical_pm_user_id mv_proposals.historical_pm_user_id%type
  , historical_pm_name mv_proposals.historical_pm_name%type
  , historical_pm_role mv_proposals.historical_pm_role%type
  , historical_pm_business_unit mv_proposals.historical_pm_business_unit%type
  , ksm_flag mv_proposals.ksm_flag%type
);

--------------------------------------
Type rec_funded_dollars Is Record (
  proposal_record_id mv_proposals.proposal_record_id%type
  , historical_pm_user_id mv_proposals.historical_pm_user_id%type
  , historical_pm_name mv_proposals.historical_pm_name%type
  , historical_pm_role mv_proposals.historical_pm_role%type
  , historical_pm_business_unit mv_proposals.historical_pm_business_unit%type
  , ksm_flag mv_proposals.ksm_flag%type
  , rec_funded_credit_flag varchar2(1)
  , proposal_funded_amount number
);

--------------------------------------
Type rec_ask_assist_credit Is Record (
  proposal_record_id mv_proposals.proposal_record_id%type
  , historical_pm_user_id mv_proposals.historical_pm_user_id%type
  , historical_pm_name mv_proposals.historical_pm_name%type
  , historical_pm_role mv_proposals.historical_pm_role%type
  , historical_pm_business_unit mv_proposals.historical_pm_business_unit%type
  , ksm_flag mv_proposals.ksm_flag%type
  , proposal_submitted_date mv_proposals.proposal_submitted_date%type
  , ask_or_close_date mv_proposals.proposal_submitted_date%type
);

--------------------------------------
Type rec_contact_report Is Record (
  contact_report_salesforce_id mv_contact_reports.contact_report_salesforce_id%type
  , contact_report_record_id mv_contact_reports.contact_report_record_id%type
  , cr_credit_salesforce_id mv_contact_reports.cr_credit_salesforce_id%type
  , cr_credit_name mv_contact_reports.cr_credit_name%type
  , cr_relation_salesforce_id mv_contact_reports.cr_relation_salesforce_id%type
  , cr_relation_donor_id mv_contact_reports.cr_relation_donor_id%type
  , cr_relation_sort_name mv_contact_reports.cr_relation_sort_name%type
  , contact_report_purpose mv_contact_reports.contact_report_purpose%type
  , cal_year integer
  , cal_month integer
  , fiscal_year integer
  , fiscal_qtr integer
  , perf_quarter integer
  , perf_year integer
);

--------------------------------------
Type rec_contact_count Is Record (
  cr_credit_salesforce_id mv_contact_reports.cr_credit_salesforce_id%type
  , cr_credit_name mv_contact_reports.cr_credit_name%type
  , contact_report_record_id mv_contact_reports.contact_report_record_id%type
);

--------------------------------------
Type rec_mgo_activity_monthly Is Record (
  historical_pm_user_id mv_contact_reports.cr_credit_salesforce_id%type
  , historical_pm_name mv_contact_reports.cr_credit_name%type 
  , gift_officer_donor_id stg_alumni.contact.ucinn_ascendv2__donor_id__c%type
  , gift_officer_sort_name varchar2(300)
  , goal_type varchar2(8)
  , goal_desc varchar2(32)
  , cal_year integer
  , cal_month integer
  , fiscal_year integer
  , fiscal_qtr integer
  , perf_year integer
  , perf_quarter integer
  , py_goal integer
  , fy_goal integer
  , progress integer
  , adjusted_progress integer
  , addl_progress_detail integer
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type proposals_data Is Table Of rec_proposals_data;
Type proposal_assist_data Is Table Of rec_proposal_assist_data;
Type goals_data Is Table Of rec_goals_data;
Type funded_credit Is Table Of rec_funded_credit;
Type funded_dollars Is Table Of rec_funded_dollars;
Type ask_assist_credit Is Table Of rec_ask_assist_credit;
Type contact_report Is Table Of rec_contact_report;
Type contact_count Is Table Of rec_contact_count;
Type mgo_activity_monthly Is Table Of rec_mgo_activity_monthly;

/*************************************************************************
Public function declarations
*************************************************************************/

-- Function to return public/private constants
Function get_numeric_constant(
  const_name In varchar2 -- Name of constant to retrieve
) Return number Deterministic;

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
From table(rpt_pbh634.ksm_pkg_tmp.tbl_alloc_annual_fund_ksm) ksm_af;
Select cal.*
From table(rpt_pbh634.ksm_pkg_tmp.tbl_current_calendar) cal;
*************************************************************************/

-- Standardized proposal data table functions
Function tbl_universal_proposals_data
  Return proposals_data Pipelined;

Function tbl_proposal_assist_data
  Return proposal_assist_data Pipelined;

-- Standardized goals data table function
Function tbl_goals_data
  Return goals_data Pipelined;
  
-- Table functions for each of the MGO metrics
Function tbl_funded_count(
    ask_amt number default metrics_pkg.mg_ask_amt
    , funded_count number default metrics_pkg.mg_funded_count
  )
  Return funded_credit Pipelined;

Function tbl_funded_dollars(
    ask_amt number default metrics_pkg.mg_ask_amt
    , granted_amt number default metrics_pkg.mg_granted_amt
  )
  Return funded_dollars Pipelined;

Function tbl_asked_count(
    ask_amt number default metrics_pkg.mg_ask_amt
  )
  Return ask_assist_credit Pipelined;

Function tbl_asked_count_ksm(
    ask_amt_ksm_plg number default metrics_pkg.mg_ask_amt_ksm_plg
    , ask_amt_ksm_outright number default metrics_pkg.mg_ask_amt_ksm_outright
  )
  Return ask_assist_credit Pipelined;

Function tbl_contact_reports
  Return contact_report Pipelined;

Function tbl_contact_count
  Return contact_count Pipelined;

Function tbl_assist_count(
    ask_amt number default metrics_pkg.mg_ask_amt
  )
  Return ask_assist_credit Pipelined;

Function tbl_mgo_activity_monthly
  Return mgo_activity_monthly Pipelined;

Function tbl_mgo_activity_placeholders
  Return mgo_activity_monthly Pipelined;

End metrics_pkg;
/
Create Or Replace Package Body metrics_pkg Is

/*************************************************************************
Private cursor tables -- data definitions; update indicated sections as needed
*************************************************************************/

--------------------------------------
-- Universal proposals data, originally adapted from v_mgo_activity_monthly
-- All fields needed to recreate proposals subqueries appearing throughout the original file
Cursor c_universal_proposals_data Is
  Select
    p.opportunity_salesforce_id
    , p.proposal_record_id
    , p.historical_pm_user_id
    , p.historical_pm_name
    , p.historical_pm_role
    , p.historical_pm_business_unit
    , p.ksm_flag
    , p.historical_pm_is_active
    , p.proposal_active_indicator
    , p.proposal_type
    , Case When p.proposal_type = 'Standard' Then 'Y' End
      As standard_proposal_flag
    , p.proposal_submitted_amount
    , p.proposal_funded_amount
    , p.proposal_stage
    , p.proposal_created_date
    , p.proposal_submitted_date
    , p.proposal_close_date
    , extract(year From p.proposal_close_date) As cal_year
    , extract(month From p.proposal_close_date) As cal_month
    , ksm_pkg_calendar.get_fiscal_year(p.proposal_close_date) As fiscal_year
    , ksm_pkg_calendar.get_quarter(p.proposal_close_date, 'fisc') As fiscal_quarter
    , ksm_pkg_calendar.get_performance_year(p.proposal_close_date) As perf_year
    , ksm_pkg_calendar.get_quarter(p.proposal_close_date, 'perf') As perf_quarter
  From mv_proposals p
  Where p.historical_pm_name Is Not Null
    And p.proposal_stage In (
      'Submitted', 'Approved by Donor', 'Declined', 'Funded'
    )
;

--------------------------------------
-- Proposal assists data, disaggregated for multiple assists
Cursor c_proposal_assist_data Is
  Select
    pa.opportunity_assignment_salesforce_id
    , pa.opportunity_assignment_role
    , pa.opportunity_user_salesforce_id
      As proposal_assist_user_id
    , pa.opportunity_user_name
      As proposal_assist_name
    , pa.assignment_is_active
      As proposal_assist_is_active
    , p.proposal_record_id
    , p.historical_pm_user_id
    , p.historical_pm_name
    , p.historical_pm_role
    , p.historical_pm_business_unit
    , p.ksm_flag
    , p.historical_pm_is_active
    , p.proposal_active_indicator
    , p.proposal_type
    , p.standard_proposal_flag
    , p.proposal_submitted_amount
    , p.proposal_funded_amount
    , p.proposal_stage
    , p.proposal_created_date
    , p.proposal_submitted_date
    , p.proposal_close_date
    , p.cal_year
    , p.cal_month
    , p.fiscal_year
    , p.fiscal_quarter
    , p.perf_year
    , p.perf_quarter
  From table(dw_pkg_base.tbl_proposal_assignment) pa
  Inner Join table(metrics_pkg.tbl_universal_proposals_data) p
    On p.opportunity_salesforce_id = pa.opportunity_salesforce_id
  Where pa.opportunity_assignment_role = 'Proposal Assist'
;

--------------------------------------
-- Combined goals data
Cursor c_goals_data Is
  Select
    wp.work_plan_salesforce_id
    , wp.work_plan_name
    , wp.gift_officer_user_salesforce_id
    , usr.user_name
      As gift_officer_user_name
    , usr.staff_donor_id
      As gift_officer_donor_id
    , usr.staff_sort_name
      As gift_officer_sort_name
    , wp.gift_officer_type
    , Case
        When wp.gift_officer_role Is Not Null
          Then wp.gift_officer_role
        Else usr.user_title
        End
      As gift_officer_role
    , wp.gift_officer_status
    , wp.metric_performance_year
    , wp.metric_effective_date
    , wp.mg_commitments_goal
    , wp.mg_asks_goal
    , wp.mg_dollars_goal
    , wp.visits_goal
    , wp.qualifications_goal
    , wp.contacts_goal
    , wp.proposal_assist_goal
    , wp.proposal_assist_dollars_goal
    , wp.etl_update_date
  From table(dw_pkg_base.tbl_work_plan) wp
  Inner Join table(dw_pkg_base.tbl_users) usr
    On usr.user_salesforce_id = wp.gift_officer_user_salesforce_id
;

--------------------------------------
-- Credit for asked & funded proposals
-- Count for funded proposal goal 1
Cursor c_funded_count(
    ask_amt_in In number
    , funded_count_in In number
  ) Is
    
  With
  
  proposals_funded_count As (
    -- Must be proposal manager, funded status, and above the ask & funded credit thresholds
    Select *
    From table(metrics_pkg.tbl_universal_proposals_data) upd
    Where historical_pm_role = 'Proposal Manager'
      And proposal_submitted_amount >= ask_amt_in
      And proposal_funded_amount >= funded_count_in
      And proposal_stage = 'Funded'
  )
  
  Select Distinct
    proposal_record_id
    , historical_pm_user_id
    , historical_pm_name
    , historical_pm_role
    , historical_pm_business_unit
    , ksm_flag
  From proposals_funded_count
;

--------------------------------------
-- Gift credit for funded proposal goal 3
Cursor c_rec_funded_dollars(
    ask_amt_in In number
    , granted_amt_in In number
  ) Is
  
  With
  
  proposals_funded_cr As (
    Select
      upd.*
      -- Must be proposal manager, funded status, and above the ask & granted amount thresholds
      , Case
          When proposal_submitted_amount >= ask_amt_in
            And proposal_funded_amount >= granted_amt_in
            Then 'Y'
          Else 'N'
        End
        As rec_funded_credit_flag
    From table(metrics_pkg.tbl_universal_proposals_data) upd
    Where historical_pm_role = 'Proposal Manager'
      And proposal_funded_amount > 0
      And proposal_stage = 'Funded'
  )
  
  Select Distinct
    proposal_record_id
    , historical_pm_user_id
    , historical_pm_name
    , historical_pm_role
    , historical_pm_business_unit
    , ksm_flag
    , rec_funded_credit_flag
    , proposal_funded_amount
  From proposals_funded_cr
;

--------------------------------------
-- Count for asked proposal goal 2
Cursor c_asked_count(
    ask_amt_in In number
  ) Is
  
  -- Must be proposal manager and above the ask credit threshold
  With
  
  proposals_asked_count As (
    Select *
    From table(metrics_pkg.tbl_universal_proposals_data)
    Where historical_pm_role = 'Proposal Manager'
      And proposal_submitted_amount >= ask_amt_in
  )
  
  Select
    proposal_record_id
    , historical_pm_user_id
    , historical_pm_name
    , historical_pm_role
    , historical_pm_business_unit
    , ksm_flag
    , proposal_submitted_date
    -- Replace null submitted date with close date
    , nvl(proposal_submitted_date, proposal_close_date)
      As ask_or_close_date
  From proposals_asked_count
;

--------------------------------------
-- KSM asked count: asks must be for an outright gift >= mg_ask_amt_ksm_outright
-- or for a pledge >= mg_ask_amt_ksm_plg
Cursor c_asked_count_ksm(
    ask_amt_ksm_plg_in In number
    , ask_amt_ksm_outright_in In number
  ) Is
  
  -- Must be proposal manager and above the ask credit threshold
  With
  
  proposals_asked_count As (
    Select *
    From table(metrics_pkg.tbl_universal_proposals_data)
    Where historical_pm_role = 'Proposal Manager'
      And (
        -- Any gift type above overall threshold
        proposal_submitted_amount >= 250E3--ask_amt_ksm_plg_in
        -- Outright asks above outright threshold
        Or (
          proposal_submitted_amount >= 100E3--ask_amt_ksm_outright_in
          And standard_proposal_flag = 'Y'
        )
      )
  )
  
  Select
    proposal_record_id
    , historical_pm_user_id
    , historical_pm_name
    , historical_pm_role
    , historical_pm_business_unit
    , ksm_flag
    , proposal_submitted_date
    -- Replace null submitted date with close date
    , nvl(proposal_submitted_date, proposal_close_date)
      As ask_or_close_date
  From proposals_asked_count
;

--------------------------------------
-- Contact report data
-- Fields to recreate contact report calculations used in goals 4 and 5
-- Corresponds to subqueries in lines 1392-1448
Cursor c_contact_reports Is
  Select Distinct
    contact_report_salesforce_id
    , contact_report_record_id
    , cr_credit_salesforce_id
    , cr_credit_name
    , cr_relation_salesforce_id
    , cr_relation_donor_id
    , cr_relation_sort_name
    , contact_report_purpose
    , extract(year From contact_report_date)
      As cal_year
    , extract(month From contact_report_date)
      As cal_month
    , ksm_pkg_calendar.get_fiscal_year(contact_report_date)
      As fiscal_year
    , ksm_pkg_calendar.get_quarter(contact_report_date, 'fisc')
      As fiscal_qtr
    , ksm_pkg_calendar.get_quarter(contact_report_date, 'perf')
      As perf_quarter
    , ksm_pkg_calendar.get_performance_year(contact_report_date)
      As perf_year -- performance year
  From mv_contact_reports cr
  Where contact_report_visit_flag = 'Y' -- Only count visits
    And cr_credit_type = 'Staff Credit'
;

--------------------------------------  
-- Deduped contact report credit and author IDs
Cursor c_contact_count Is
  Select Distinct
    cr_credit_salesforce_id
    , cr_credit_name
    , contact_report_record_id
  From table(metrics_pkg.tbl_contact_reports)
;

--------------------------------------
-- Proposal assist credit
-- Corresponds to old goal 6 subqueries in lines 1456-1489
Cursor c_assist_count(
    ask_amt_in In number
  ) Is
  
  -- Must be proposal manager and above the ask credit threshold
  With
  
  assist_asked_count As (
    Select *
    From table(metrics_pkg.tbl_proposal_assist_data)
    Where proposal_submitted_amount >= 100E3 --ask_amt_in
  )
  
  Select
    proposal_record_id
    , opportunity_user_salesforce_id
      As proposal_assist_user_id
    , opportunity_user_name
      As proposal_assist_name
    , opportunity_assignment_role
      As opportunity_user_role
    , historical_pm_business_unit
    , ksm_flag
    , proposal_submitted_date
    -- Replace null submitted date with close date
    , nvl(proposal_submitted_date, proposal_close_date)
      As ask_or_close_date
  From assist_asked_count
;

--------------------------------------
-- Gift officer activity aggregated by month
-- !!! Match columns to c_mgo_activity_placeholders, below !!!
Cursor c_mgo_activity_monthly Is

  With

  proposal_dates As (
    Select
      proposal_record_id
      , proposal_submitted_date
      , proposal_close_date
      , cal_year
      , cal_month
      , fiscal_year
      , fiscal_quarter
      , perf_year
      , perf_quarter
      , extract(year From proposal_submitted_date)
        As ask_cal_year
      , extract(month From proposal_submitted_date)
        As ask_cal_month
      , ksm_pkg_calendar.get_fiscal_year(proposal_submitted_date)
        As ask_fiscal_year
      , ksm_pkg_calendar.get_quarter(proposal_submitted_date, 'fisc')
        As ask_fiscal_quarter
      , ksm_pkg_calendar.get_performance_year(proposal_submitted_date)
        As ask_perf_year
      , ksm_pkg_calendar.get_quarter(proposal_submitted_date, 'perf')
        As ask_perf_quarter
    From table(metrics_pkg.tbl_universal_proposals_data)
  )
  
  , ksm_cash As (
    Select
      gos.donor_id
      , gos.sort_name
      , 'KGC' As goal_type
      , 'KSM Cash' As goal_desc
      , extract(year From c.credit_date) As cal_year
      , extract(month From c.credit_date) As cal_month
      , c.fiscal_year
      , ksm_pkg_calendar.get_quarter(c.credit_date, 'fisc') As fiscal_quarter
      , ksm_pkg_calendar.get_performance_year(c.credit_date) As perf_year
      , ksm_pkg_calendar.get_quarter(c.credit_date, 'perf') As perf_quarter
      , 0 As fy_goal
      , 0 As py_goal
      , c.cash_countable_amount
    From v_ksm_gifts_cash c
    Inner Join tbl_ksm_gos gos
      On gos.user_id = c.historical_credit_user_id
    Where
      -- Expendable only
      c.cash_category = 'Expendable'
      -- Exclude pledge payments
      And c.gypm_ind <> 'Y'
  )
  
  , goal As (
    Select *
    From table(metrics_pkg.tbl_goals_data)
  )

  ----- Main query goal 1, equivalent to lines 4-511 in nu_gft_v_officer_metrics -----
  Select
    fcd.historical_pm_user_id
    , fcd.historical_pm_name
    , g.gift_officer_donor_id
    , g.gift_officer_sort_name
    , 'MGC' As goal_type
    , 'MG Closes' As goal_desc
    , pd.cal_year
    , pd.cal_month
    , pd.fiscal_year
    , pd.fiscal_quarter
    , pd.perf_year
    , pd.perf_quarter
    , g.mg_commitments_goal As fy_goal
    , pyg.mg_commitments_goal As py_goal
    , Count(Distinct fcd.proposal_record_id) As progress
    , Count(Distinct fcd.proposal_record_id) As adjusted_progress
    , NULL As addl_progress_detail
  From table(metrics_pkg.tbl_funded_count) fcd
  Inner Join proposal_dates pd
    On pd.proposal_record_id = fcd.proposal_record_id
  -- Fiscal year goals
  Left Join goal g
    On fcd.historical_pm_user_id = g.gift_officer_user_salesforce_id
      And g.metric_performance_year = pd.fiscal_year
  -- Performance year goals
  Left Join goal pyg
    On fcd.historical_pm_user_id = pyg.gift_officer_user_salesforce_id
      And pyg.metric_performance_year = pd.perf_year
  Group By
    fcd.historical_pm_user_id
    , fcd.historical_pm_name
    , g.gift_officer_donor_id
    , g.gift_officer_sort_name
    , pd.cal_year
    , pd.cal_month
    , pd.fiscal_year
    , pd.fiscal_quarter
    , pd.perf_year
    , pd.perf_quarter
    , g.mg_commitments_goal
    , pyg.mg_commitments_goal
  Union
  ----- Main query goal 2, equivalent to lines 512-847 in nu_gft_v_officer_metrics -----
  Select
    acr.historical_pm_user_id
    , acr.historical_pm_name
    , g.gift_officer_donor_id
    , g.gift_officer_sort_name
    , 'MGS' As goal_type
    , 'MG Sols' As goal_desc
    , pd.ask_cal_year
    , pd.ask_cal_month
    , pd.ask_fiscal_year
    , pd.ask_fiscal_quarter
    , pd.ask_perf_year
    , pd.ask_perf_quarter
    , g.mg_asks_goal As fy_goal
    , pyg.mg_asks_goal As py_goal
    -- Original definition: count only if ask date is filled in
    , Count(Distinct Case When acr.ask_or_close_date Is Not Null Then acr.proposal_record_id End)
      As progress
    -- Alternate definition: count if either ask date or stop date is filled in
    , Count(Distinct acr.proposal_record_id) As adjusted_progress
    , NULL As addl_progress_detail
  From table(metrics_pkg.tbl_asked_count) acr
  Inner Join proposal_dates pd
    On pd.proposal_record_id = acr.proposal_record_id
  -- Fiscal year goals
  Left Join goal g
    On acr.historical_pm_user_id = g.gift_officer_user_salesforce_id
      And g.metric_performance_year = pd.fiscal_year
  -- Performance year goals
  Left Join goal pyg
    On acr.historical_pm_user_id = pyg.gift_officer_user_salesforce_id
      And pyg.metric_performance_year = pd.perf_year
  Group By
    acr.historical_pm_user_id
    , acr.historical_pm_name
    , g.gift_officer_donor_id
    , g.gift_officer_sort_name
    , pd.ask_cal_year
    , pd.ask_cal_month
    , pd.ask_fiscal_year
    , pd.ask_fiscal_quarter
    , pd.ask_perf_year
    , pd.ask_perf_quarter
    , g.mg_asks_goal
    , pyg.mg_asks_goal
  Union
  ----- KSM supplement - Kellogg asks
  Select
    ack.historical_pm_user_id
    , ack.historical_pm_name
    , g.gift_officer_donor_id
    , g.gift_officer_sort_name
    , 'KGS' As goal_type
    , 'KSM Sols' As goal_desc
    , pd.ask_cal_year
    , pd.ask_cal_month
    , pd.ask_fiscal_year
    , pd.ask_fiscal_quarter
    , pd.ask_perf_year
    , pd.ask_perf_quarter
    , g.mg_asks_goal As fy_goal
    , pyg.mg_asks_goal As py_goal
    -- Original definition: count only if ask date is filled in
    , Count(Distinct Case When ack.ask_or_close_date Is Not Null Then ack.proposal_record_id End)
      As progress
    -- Alternate definition: count if either ask date or stop date is filled in
    , Count(Distinct ack.proposal_record_id) As adjusted_progress
    , NULL As addl_progress_detail
  From table(metrics_pkg.tbl_asked_count_ksm) ack
  Inner Join proposal_dates pd
    On pd.proposal_record_id = ack.proposal_record_id
  -- Fiscal year goals
  Left Join goal g
    On ack.historical_pm_user_id = g.gift_officer_user_salesforce_id
      And g.metric_performance_year = pd.fiscal_year
  -- Performance year goals
  Left Join goal pyg
    On ack.historical_pm_user_id = pyg.gift_officer_user_salesforce_id
      And pyg.metric_performance_year = pd.perf_year
  Group By
    ack.historical_pm_user_id
    , ack.historical_pm_name
    , g.gift_officer_donor_id
    , g.gift_officer_sort_name
    , pd.ask_cal_year
    , pd.ask_cal_month
    , pd.ask_fiscal_year
    , pd.ask_fiscal_quarter
    , pd.ask_perf_year
    , pd.ask_perf_quarter
    , g.mg_asks_goal
    , pyg.mg_asks_goal
  Union
  ----- KSM supplement - expendable cash from non-pledge payments
  Select
    u.user_salesforce_id
    , u.user_name
    , ksm_cash.donor_id
    , ksm_cash.sort_name
    , ksm_cash.goal_type
    , ksm_cash.goal_desc
    , ksm_cash.cal_year
    , ksm_cash.cal_month
    , ksm_cash.fiscal_year
    , ksm_cash.fiscal_quarter
    , ksm_cash.perf_year
    , ksm_cash.perf_quarter
    , ksm_cash.fy_goal
    , ksm_cash.py_goal
    , trunc(sum(cash_countable_amount), 2) As progress
    , trunc(sum(cash_countable_amount), 2) As adjusted_progress
    , trunc(sum(cash_countable_amount), 2) As addl_progress_detail
  From ksm_cash
  Left Join table(dw_pkg_base.tbl_users) u
    On u.staff_donor_id = ksm_cash.donor_id
  Group By
    u.user_salesforce_id
    , u.user_name
    , ksm_cash.donor_id
    , ksm_cash.sort_name
    , ksm_cash.goal_type
    , ksm_cash.goal_desc
    , ksm_cash.cal_year
    , ksm_cash.cal_month
    , ksm_cash.fiscal_year
    , ksm_cash.fiscal_quarter
    , ksm_cash.perf_year
    , ksm_cash.perf_quarter
    , ksm_cash.fy_goal
    , ksm_cash.py_goal
  Union
  ----- Main query goal 3, equivalent to lines 848-1391 in nu_gft_v_officer_metrics -----
  Select
    fr.historical_pm_user_id
    , fr.historical_pm_name
    , g.gift_officer_donor_id
    , g.gift_officer_sort_name
    , 'MGDR' As goal_type
    , 'MG Dollars Raised' As goal_desc
    , pd.cal_year
    , pd.cal_month
    , pd.fiscal_year
    , pd.fiscal_quarter
    , pd.perf_year
    , pd.perf_quarter
    , g.mg_dollars_goal As fy_goal
    , pyg.mg_dollars_goal As py_goal
    , sum(Case When rec_funded_credit_flag = 'Y' Then fr.proposal_funded_amount End) As progress
    , sum(Case When rec_funded_credit_flag = 'Y' Then fr.proposal_funded_amount End) As adjusted_progress
    , sum(fr.proposal_funded_amount) As addl_progress_detail
  From table(metrics_pkg.tbl_funded_dollars) fr
  Inner Join proposal_dates pd
    On pd.proposal_record_id = fr.proposal_record_id
  -- Fiscal year goals
  Left Join goal g
    On fr.historical_pm_user_id = g.gift_officer_user_salesforce_id
      And g.metric_performance_year = pd.fiscal_year
  -- Performance year goals
  Left Join goal pyg
    On fr.historical_pm_user_id = pyg.gift_officer_user_salesforce_id
      And pyg.metric_performance_year = pd.perf_year
  Group By
    fr.historical_pm_user_id
    , fr.historical_pm_name
    , g.gift_officer_donor_id
    , g.gift_officer_sort_name
    , pd.cal_year
    , pd.cal_month
    , pd.fiscal_year
    , pd.fiscal_quarter
    , pd.perf_year
    , pd.perf_quarter
    , g.mg_dollars_goal
    , pyg.mg_dollars_goal
  Union
  ----- Main query goal 4, equivalent to lines 1392-1419 in nu_gft_v_officer_metrics -----
  Select Distinct
    cr.cr_credit_salesforce_id
    , cr.cr_credit_name
    , g.gift_officer_donor_id
    , g.gift_officer_sort_name
    , 'NOV' as goal_type
    , 'Visits' As goal_desc
    , c.cal_year
    , c.cal_month
    , c.fiscal_year
    , c.fiscal_qtr As fiscal_quarter
    , c.perf_year
    , c.perf_quarter
    , g.visits_goal As fy_goal
    , pyg.visits_goal As py_goal
    , count(Distinct c.contact_report_record_id) As progress
    , count(Distinct c.contact_report_record_id) As adjusted_progress
    , NULL As addl_progress_detail
  From table(metrics_pkg.tbl_contact_count) cr
  Inner Join table(metrics_pkg.tbl_contact_reports) c
    On cr.contact_report_record_id = c.contact_report_record_id
  -- Fiscal year goals
  Left Join goal g
    On cr.cr_credit_salesforce_id = g.gift_officer_user_salesforce_id
      And g.metric_performance_year = c.fiscal_year
  -- Performance year goals
  Left Join goal pyg
    On cr.cr_credit_salesforce_id = pyg.gift_officer_user_salesforce_id
      And pyg.metric_performance_year = c.perf_year
  Group By
    cr.cr_credit_salesforce_id
    , cr.cr_credit_name
    , g.gift_officer_donor_id
    , g.gift_officer_sort_name
    , c.cal_year
    , c.cal_month
    , c.fiscal_year
    , c.fiscal_qtr
    , c.perf_year
    , c.perf_quarter
    , g.visits_goal
    , pyg.visits_goal
  Union
  ----- Main query goal 5, equivalent to lines 1420-1448 in nu_gft_v_officer_metrics -----
  Select Distinct
    cr.cr_credit_salesforce_id
    , cr.cr_credit_name
    , g.gift_officer_donor_id
    , g.gift_officer_sort_name
    , 'NOQV' As goal_type
    , 'Qual Visits' As goal_desc
    , c.cal_year
    , c.cal_month
    , c.fiscal_year
    , c.fiscal_qtr As fiscal_quarter
    , c.perf_year
    , c.perf_quarter
    , g.qualifications_goal As fy_goal
    , pyg.qualifications_goal As py_goal
    , count(Distinct c.contact_report_record_id) As progress
    , count(Distinct c.contact_report_record_id) As adjusted_progress
    , NULL As addl_progress_detail
  From table(metrics_pkg.tbl_contact_count) cr
  Inner Join table(metrics_pkg.tbl_contact_reports) c
    On cr.contact_report_record_id = c.contact_report_record_id
  -- Fiscal year goals
  Left Join goal g
    On c.cr_credit_salesforce_id = g.gift_officer_user_salesforce_id
      And g.metric_performance_year = c.fiscal_year
  -- Performance year goals
  Left Join goal pyg
    On cr.cr_credit_salesforce_id = pyg.gift_officer_user_salesforce_id
      And pyg.metric_performance_year = c.perf_year
  Where c.contact_report_purpose = 'Qualification' -- Only count qualification visits
  Group By
    cr.cr_credit_salesforce_id
    , cr.cr_credit_name
    , g.gift_officer_donor_id
    , g.gift_officer_sort_name
    , c.cal_year
    , c.cal_month
    , c.fiscal_year
    , c.fiscal_qtr
    , c.perf_year
    , c.perf_quarter
    , g.qualifications_goal
    , pyg.qualifications_goal
  Union
  ----- Main query goal 6, equivalent to lines 1449-1627 in nu_gft_v_officer_metrics -----
    Select
    aca.historical_pm_user_id
    , aca.historical_pm_name
    , g.gift_officer_donor_id
    , g.gift_officer_sort_name
    , 'PA' As goal_type
    , 'Proposal Assists' As goal_desc
    , pd.ask_cal_year
    , pd.ask_cal_month
    , pd.ask_fiscal_year
    , pd.ask_fiscal_quarter
    , pd.ask_perf_year
    , pd.ask_perf_quarter
    , g.proposal_assist_goal As fy_goal
    , pyg.proposal_assist_goal As py_goal
    -- Original definition: count only if ask date is filled in
    , Count(Distinct Case When aca.ask_or_close_date Is Not Null Then aca.proposal_record_id End)
      As progress
    -- Alternate definition: count if either ask date or stop date is filled in
    , Count(Distinct aca.proposal_record_id) As adjusted_progress
    , NULL As addl_progress_detail
  From table(metrics_pkg.tbl_assist_count) aca
  Inner Join proposal_dates pd
    On pd.proposal_record_id = aca.proposal_record_id
  -- Fiscal year goals
  Left Join goal g
    On aca.historical_pm_user_id = g.gift_officer_user_salesforce_id
      And g.metric_performance_year = pd.fiscal_year
  -- Performance year goals
  Left Join goal pyg
    On aca.historical_pm_user_id = pyg.gift_officer_user_salesforce_id
      And pyg.metric_performance_year = pd.perf_year
  Group By
    aca.historical_pm_user_id
    , aca.historical_pm_name
    , g.gift_officer_donor_id
    , g.gift_officer_sort_name
    , pd.ask_cal_year
    , pd.ask_cal_month
    , pd.ask_fiscal_year
    , pd.ask_fiscal_quarter
    , pd.ask_perf_year
    , pd.ask_perf_quarter
    , g.proposal_assist_goal
    , pyg.proposal_assist_goal
;

--------------------------------------
-- Placeholder 0 progress rows to force Tableau to populate all goals
-- !!! Match columns to c_mgo_activity_monthly, above !!!
Cursor c_mgo_activity_placeholders Is
  
  With
  
  usr As (
    Select *
    From table(dw_pkg_base.tbl_users)
  )
  
  , goal As (
    Select *
    From table(metrics_pkg.tbl_goals_data)
  )
  
  -- Goal 1
  Select
    goal.gift_officer_user_salesforce_id
    , goal.gift_officer_user_name
    , goal.gift_officer_donor_id
    , goal.gift_officer_sort_name
    , 'MGC' As goal_type
    , 'MG Closes' As goal_desc
    , goal.metric_performance_year As cal_year
    , 1 As cal_month
    , goal.metric_performance_year As fiscal_year
    , 3 As fiscal_quarter
    , goal.metric_performance_year As perf_year
    , 1 As perf_quarter
    , goal.mg_commitments_goal As fy_goal
    , goal.mg_commitments_goal As py_goal
    , 0 As progress
    , 0 As adjusted_progress
    , NULL As addl_progress_detail
  From usr
  Inner Join goal
    On usr.user_salesforce_id = goal.gift_officer_user_salesforce_id
  Union All
  -- Goal 2
  Select
    goal.gift_officer_user_salesforce_id
    , goal.gift_officer_user_name
    , goal.gift_officer_donor_id
    , goal.gift_officer_sort_name
    , 'MGS' As goal_type
    , 'MG Sols' As goal_desc
    , goal.metric_performance_year As cal_year
    , 1 As cal_month
    , goal.metric_performance_year As fiscal_year
    , 3 As fiscal_quarter
    , goal.metric_performance_year As perf_year
    , 1 As perf_quarter
    , mg_asks_goal As fy_goal
    , mg_asks_goal As py_goal
    , 0 As progress
    , 0 As adjusted_progress
    , NULL As addl_progress_detail
  From usr
  Inner Join goal
    On usr.user_salesforce_id = goal.gift_officer_user_salesforce_id
  Union All
  -- Goal 2 KSM
  Select
    goal.gift_officer_user_salesforce_id
    , goal.gift_officer_user_name
    , goal.gift_officer_donor_id
    , goal.gift_officer_sort_name
    , 'KGS' As goal_type
    , 'KSM Sols' As goal_desc
    , goal.metric_performance_year As cal_year
    , 1 As cal_month
    , goal.metric_performance_year As fiscal_year
    , 3 As fiscal_quarter
    , goal.metric_performance_year As perf_year
    , 1 As perf_quarter
    , mg_asks_goal As fy_goal
    , mg_asks_goal As py_goal
    , 0 As progress
    , 0 As adjusted_progress
    , NULL As addl_progress_detail
  From usr
  Inner Join goal
    On usr.user_salesforce_id = goal.gift_officer_user_salesforce_id
  Union All
  -- Goal 3
  Select
    goal.gift_officer_user_salesforce_id
    , goal.gift_officer_user_name
    , goal.gift_officer_donor_id
    , goal.gift_officer_sort_name
    , 'MGDR' As goal_type
    , 'MG Dollars Raised' As goal_desc
    , goal.metric_performance_year As cal_year
    , 1 As cal_month
    , goal.metric_performance_year As fiscal_year
    , 3 As fiscal_quarter
    , goal.metric_performance_year As perf_year
    , 1 As perf_quarter
    , mg_asks_goal As fy_goal
    , mg_asks_goal As py_goal
    , 0 As progress
    , 0 As adjusted_progress
    , NULL As addl_progress_detail
  From usr
  Inner Join goal
    On usr.user_salesforce_id = goal.gift_officer_user_salesforce_id
  Union All
  -- Goal 3 cash version
  -- KSM Cash
  Select
    goal.gift_officer_user_salesforce_id
    , goal.gift_officer_user_name
    , goal.gift_officer_donor_id
    , goal.gift_officer_sort_name
    , 'KGC' As goal_type
    , 'KSM Cash' As goal_desc
    , goal.metric_performance_year As cal_year
    , 1 As cal_month
    , goal.metric_performance_year As fiscal_year
    , 3 As fiscal_quarter
    , goal.metric_performance_year As perf_year
    , 1 As perf_quarter
    , 0 As fy_goal
    , 0 As py_goal
    , 0 As progress
    , 0 As adjusted_progress
    , NULL As addl_progress_detail
  From usr
  Inner Join goal
    On usr.user_salesforce_id = goal.gift_officer_user_salesforce_id
  Union All
  -- Goal 4
  Select
    goal.gift_officer_user_salesforce_id
    , goal.gift_officer_user_name
    , goal.gift_officer_donor_id
    , goal.gift_officer_sort_name
    , 'NOV' as goal_type
    , 'Visits' As goal_desc
    , goal.metric_performance_year As cal_year
    , 1 As cal_month
    , goal.metric_performance_year As fiscal_year
    , 3 As fiscal_quarter
    , goal.metric_performance_year As perf_year
    , 1 As perf_quarter
    , visits_goal As fy_goal
    , visits_goal As py_goal
    , 0 As progress
    , 0 As adjusted_progress
    , NULL As addl_progress_detail
  From usr
  Inner Join goal
    On usr.user_salesforce_id = goal.gift_officer_user_salesforce_id
  Union All
  -- Goal 5
  Select
    goal.gift_officer_user_salesforce_id
    , goal.gift_officer_user_name
    , goal.gift_officer_donor_id
    , goal.gift_officer_sort_name
    , 'NOQV' As goal_type
    , 'Qual Visits' As goal_desc
     , goal.metric_performance_year As cal_year
    , 1 As cal_month
    , goal.metric_performance_year As fiscal_year
    , 3 As fiscal_quarter
    , goal.metric_performance_year As perf_year
    , 1 As perf_quarter
    , qualifications_goal As fy_goal
    , qualifications_goal As py_goal
    , 0 As progress
    , 0 As adjusted_progress
    , NULL As addl_progress_detail
  From usr
  Inner Join goal
    On usr.user_salesforce_id = goal.gift_officer_user_salesforce_id
  Union All
  -- Goal 6
  Select
    goal.gift_officer_user_salesforce_id
    , goal.gift_officer_user_name
    , goal.gift_officer_donor_id
    , goal.gift_officer_sort_name
    , 'PA' As goal_type
    , 'Proposal Assists' As goal_desc
     , goal.metric_performance_year As cal_year
    , 1 As cal_month
    , goal.metric_performance_year As fiscal_year
    , 3 As fiscal_quarter
    , goal.metric_performance_year As perf_year
    , 1 As perf_quarter
    , proposal_assist_goal As fy_goal
    , proposal_assist_goal As py_goal
    , 0 As progress
    , 0 As adjusted_progress
    , NULL As addl_progress_detail
  From usr
  Inner Join goal
    On usr.user_salesforce_id = goal.gift_officer_user_salesforce_id
;

/*************************************************************************
Functions
*************************************************************************/

Function get_numeric_constant(const_name In varchar2)
  Return number Deterministic Is
  -- Declarations
  val number;
  var varchar2(100);
  
  Begin
    -- If const_name doesn't include metrics_pkg, prepend it
    If substr(lower(const_name), 1, 12) <> 'metrics_pkg.'
      Then var := 'metrics_pkg.' || const_name;
    Else
      var := const_name;
    End If;
    -- Run command
    Execute Immediate
      'Begin :val := ' || var || '; End;'
      Using Out val;
      Return val;
  End;

/*************************************************************************
Pipelined functions
*************************************************************************/

--------------------------------------
-- Pipelined function returning consolidated proposals data
Function tbl_universal_proposals_data
  Return proposals_data Pipelined As
  -- Declarations
  pd proposals_data;

  Begin
    Open c_universal_proposals_data;
      Fetch c_universal_proposals_data Bulk Collect Into pd;
    Close c_universal_proposals_data;
    For i in 1..(pd.count) Loop
      Pipe row(pd(i));
    End Loop;
    Return;
  End;

--------------------------------------
-- Pipelined function returning disaggregated proposal assists
Function tbl_proposal_assist_data
  Return proposal_assist_data Pipelined As
  -- Declarations
  pa proposal_assist_data;

  Begin
    Open c_proposal_assist_data;
      Fetch c_proposal_assist_data Bulk Collect Into pa;
    Close c_proposal_assist_data;
    For i in 1..(pa.count) Loop
      Pipe row(pa(i));
    End Loop;
    Return;
  End;

--------------------------------------
-- Pipelined function returning goals
Function tbl_goals_data
  Return goals_data Pipelined As
  -- Declarations
  gd goals_data;

  Begin
    Open c_goals_data;
      Fetch c_goals_data Bulk Collect Into gd;
    Close c_goals_data;
    For i in 1..(gd.count) Loop
      Pipe row(gd(i));
    End Loop;
    Return;
  End;

--------------------------------------
-- Pipelined function returning proposal funded data
Function tbl_funded_count(
    ask_amt number default metrics_pkg.mg_ask_amt
    , funded_count number default metrics_pkg.mg_funded_count
  )
  Return funded_credit Pipelined As
  -- Declarations
  pd funded_credit;

  Begin
    Open c_funded_count(
      ask_amt_in => ask_amt
      , funded_count_in => funded_count
    );
    Fetch c_funded_count Bulk Collect Into pd;
    Close c_funded_count;
    -- Pipe out the data
    For i in 1..(pd.count) Loop
      Pipe row(pd(i));
    End Loop;
    Return;
  End;

--------------------------------------
-- Pipelined function returning proposal funded amounts data
Function tbl_funded_dollars(
    ask_amt number default metrics_pkg.mg_ask_amt
    , granted_amt number default metrics_pkg.mg_granted_amt
  )
  Return funded_dollars Pipelined As
  -- Declarations
  pd funded_dollars;

  Begin
    Open c_rec_funded_dollars(
      ask_amt_in => ask_amt
      , granted_amt_in => granted_amt
    );
    Fetch c_rec_funded_dollars Bulk Collect Into pd;
    Close c_rec_funded_dollars;
    -- Pipe out the data
    For i in 1..(pd.count) Loop
      Pipe row(pd(i));
    End Loop;
    Return;
  End;

--------------------------------------
-- Pipelined function returning proposal asked data
Function tbl_asked_count(
    ask_amt number default metrics_pkg.mg_ask_amt
  )
  Return ask_assist_credit Pipelined As
  -- Declarations
  pd ask_assist_credit;

  Begin
    Open c_asked_count(
      ask_amt_in => ask_amt
    );
    Fetch c_asked_count Bulk Collect Into pd;
    Close c_asked_count;
    -- Pipe out the data
    For i in 1..(pd.count) Loop
      Pipe row(pd(i));
    End Loop;
    Return;
  End;

--------------------------------------
Function tbl_asked_count_ksm(
    ask_amt_ksm_plg number default metrics_pkg.mg_ask_amt_ksm_plg
    , ask_amt_ksm_outright number default metrics_pkg.mg_ask_amt_ksm_outright
  )
  Return ask_assist_credit Pipelined As
  -- Declarations
  pd ask_assist_credit;

  Begin
    Open c_asked_count_ksm(
      ask_amt_ksm_plg_in => ask_amt_ksm_plg
      , ask_amt_ksm_outright_in => ask_amt_ksm_outright
    );
    Fetch c_asked_count_ksm Bulk Collect Into pd;
    Close c_asked_count_ksm;
    -- Pipe out the data
    For i in 1..(pd.count) Loop
      Pipe row(pd(i));
    End Loop;
    Return;
  End;

--------------------------------------
-- Pipelined function returning visits data
Function tbl_contact_reports
  Return contact_report Pipelined As
    -- Declarations
    cd contact_report;

  Begin
    Open c_contact_reports; -- Annual Fund allocations cursor
      Fetch c_contact_reports Bulk Collect Into cd;
    Close c_contact_reports;
    -- Pipe out the data
    For i in 1..(cd.count) Loop
      Pipe row(cd(i));
    End Loop;
    Return;
  End;

--------------------------------------
-- Pipelined function returning visits data
Function tbl_contact_count
  Return contact_count Pipelined As
    -- Declarations
    cd contact_count;

  Begin
    Open c_contact_count; -- Annual Fund allocations cursor
      Fetch c_contact_count Bulk Collect Into cd;
    Close c_contact_count;
    -- Pipe out the data
    For i in 1..(cd.count) Loop
      Pipe row(cd(i));
    End Loop;
    Return;
  End;

--------------------------------------
-- Pipelined function returning proposal assists data
Function tbl_assist_count(
    ask_amt number default metrics_pkg.mg_ask_amt
  )
  Return ask_assist_credit Pipelined As
    -- Declarations
    ac ask_assist_credit;

  Begin
    Open c_assist_count(
      ask_amt_in => ask_amt
    );
      Fetch c_assist_count Bulk Collect Into ac;
    Close c_assist_count;
    -- Pipe out the data
    For i in 1..(ac.count) Loop
      Pipe row(ac(i));
    End Loop;
    Return;
  End;

--------------------------------------
-- Pipelined function returning consolidated GO activity
Function tbl_mgo_activity_monthly
  Return mgo_activity_monthly Pipelined As
    -- Declarations
    ma mgo_activity_monthly;

  Begin
    Open c_mgo_activity_monthly; -- Annual Fund allocations cursor
      Fetch c_mgo_activity_monthly Bulk Collect Into ma;
    Close c_mgo_activity_monthly;
    -- Pipe out the data
    For i in 1..(ma.count) Loop
      Pipe row(ma(i));
    End Loop;
    Return;
  End;

Function tbl_mgo_activity_placeholders
  Return mgo_activity_monthly Pipelined As
    -- Declarations
    ma mgo_activity_monthly;

  Begin
    Open c_mgo_activity_placeholders; -- Annual Fund allocations cursor
      Fetch c_mgo_activity_placeholders Bulk Collect Into ma;
    Close c_mgo_activity_placeholders;
    -- Pipe out the data
    For i in 1..(ma.count) Loop
      Pipe row(ma(i));
    End Loop;
    Return;
  End;

End metrics_pkg;
/
