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
  proposal_record_id mv_proposals.proposal_record_id%type
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

/*************************************************************************
Public table declarations
*************************************************************************/

Type proposals_data Is Table Of rec_proposals_data;
Type funded_credit Is Table Of rec_funded_credit;
Type funded_dollars Is Table Of rec_funded_dollars;
Type ask_assist_credit Is Table Of rec_ask_assist_credit;
Type contact_report Is Table Of rec_contact_report;
Type contact_count Is Table Of rec_contact_count;

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

-- Standardized proposal data table function
Function tbl_universal_proposals_data
  Return proposals_data Pipelined;
  
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
/*
Function tbl_assist_count
  Return ask_assist_credit Pipelined;
*/
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
    p.proposal_record_id
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

/*--------------------------------------
-- Refactor goal 6 subqueries in lines 1456-1489
-- 3 clones, at 1501-1534, 1546-1579, 1591-1624Cursor c_assist_count Is
  With
  -- Count for proposal assists goal 6
  proposal_assists_count As (
    -- Must be proposal assist; no dollar threshold
    Select *
    From table(tbl_universal_proposals_data)
    Where assignment_type = 'AS' -- Proposal Assist
  )
  , assist_count As (
      -- Any active proposals (1st priority)
        Select proposal_id
          , assignment_id_number
          , initial_contribution_date
          , proposal_stop_date
          , 1 As info_rank
        From proposal_assists_count
        Where assignment_active_ind = 'Y'
      Union
        Select proposal_id
          , assignment_id_number
          , initial_contribution_date
          , proposal_stop_date
          , 2 As info_rank
        From proposal_assists_count
        Where assignment_active_ind = 'N'
          And proposal_stop_date - assignment_stop_date <= 1
      Order By info_rank
    )
  Select proposal_id
    , assignment_id_number
    , min(initial_contribution_date) keep(dense_rank First Order By info_rank Asc)
      As initial_contribution_date
    -- Replace null initial_contribution_date with proposal_stop_date
    , min(nvl(initial_contribution_date, proposal_stop_date)) keep(dense_rank First Order By info_rank Asc)
      As ask_or_stop_dt
  From assist_count
  Group By proposal_id
    , assignment_id_number
;
*/

/*--------------------------------------
-- Gift officer activity aggregated by month
Cursor c_mgo_activity_monthly Is

With

proposal_dates As (
  Select *
  From table(rpt_pbh634.metrics_pkg.tbl_proposal_dates)
)

, ksm_cash As (
  Select
    mgc.primary_credited_mgr As id_number
    , mgc.primary_credited_mgr_name As report_name
    , 'KGC' As goal_type
    , 'KSM Cash' As goal_desc
    , extract(year From mgc.date_of_record) As cal_year
    , extract(month From mgc.date_of_record) As cal_month
    , mgc.fiscal_year
    , rpt_pbh634.ksm_pkg_tmp.get_quarter(mgc.date_of_record, 'fisc') As fiscal_quarter
    , rpt_pbh634.ksm_pkg_tmp.get_performance_year(mgc.date_of_record) As perf_year
    , rpt_pbh634.ksm_pkg_tmp.get_quarter(mgc.date_of_record, 'perf') As perf_quarter
    , 0 As fy_goal
    , 0 As py_goal
    , legal_amount
  From vt_ksm_mg_cash mgc
  Where
    -- Expendable only
    mgc.cash_category = 'Expendable'
    -- Exclude pledge payments
    And mgc.tx_gypm_ind <> 'Y'
)

----- Main query goal 1, equivalent to lines 4-511 in nu_gft_v_officer_metrics -----
Select fcd.assignment_id_number As id_number
  , e.report_name
  , 'MGC' As goal_type
  , 'MG Closes' As goal_desc
  , extract(year From pd.date_of_record) As cal_year
  , extract(month From pd.date_of_record) As cal_month
  , rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(pd.date_of_record) As fiscal_year
  , rpt_pbh634.ksm_pkg_tmp.get_quarter(pd.date_of_record, 'fisc') As fiscal_quarter
  , rpt_pbh634.ksm_pkg_tmp.get_performance_year(pd.date_of_record) As perf_year
  , rpt_pbh634.ksm_pkg_tmp.get_quarter(pd.date_of_record, 'perf') As perf_quarter
  , g.goal_1 As fy_goal
  , pyg.goal_1 As py_goal
  , Count(Distinct fcd.proposal_id) As progress
  , Count(Distinct fcd.proposal_id) As adjusted_progress
  , NULL As addl_progress_detail
From table(rpt_pbh634.metrics_pkg.tbl_funded_count) fcd
Inner Join entity e On e.id_number = fcd.assignment_id_number
Inner Join proposal_dates pd
  On pd.proposal_id = fcd.proposal_id
-- Fiscal year goals
Left Join goal g
  On fcd.assignment_id_number = g.id_number
    And g.year = rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(pd.date_of_record)
-- Performance year goals
Left Join goal pyg
  On fcd.assignment_id_number = pyg.id_number
    And pyg.year = rpt_pbh634.ksm_pkg_tmp.get_performance_year(pd.date_of_record)
Group By rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(pd.date_of_record)
  , fcd.assignment_id_number
  , e.report_name
  , extract(year From pd.date_of_record)
  , extract(month From pd.date_of_record)
  , rpt_pbh634.ksm_pkg_tmp.get_quarter(pd.date_of_record, 'fisc')
  , rpt_pbh634.ksm_pkg_tmp.get_quarter(pd.date_of_record, 'perf')
  , rpt_pbh634.ksm_pkg_tmp.get_performance_year(pd.date_of_record)
  , g.goal_1
  , pyg.goal_1
Union
----- Main query goal 2, equivalent to lines 512-847 in nu_gft_v_officer_metrics -----
Select acr.assignment_id_number As id_number
  , e.report_name
  , 'MGS' As goal_type
  , 'MG Sols' As goal_desc
  , extract(year From acr.ask_or_stop_dt) As cal_year
  , extract(month From acr.ask_or_stop_dt) As cal_month
  , rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(acr.ask_or_stop_dt) As fiscal_year
  , rpt_pbh634.ksm_pkg_tmp.get_quarter(acr.ask_or_stop_dt, 'fisc') As fiscal_quarter
  , rpt_pbh634.ksm_pkg_tmp.get_performance_year(acr.ask_or_stop_dt) As perf_year
  , rpt_pbh634.ksm_pkg_tmp.get_quarter(acr.ask_or_stop_dt, 'perf') As perf_quarter
  , g.goal_2 As fy_goal
  , pyg.goal_2 As py_goal
  -- Original definition: count only if ask date is filled in
  , Count(Distinct Case When acr.initial_contribution_date Is Not Null Then acr.proposal_id End)
    As progress
  -- Alternate definition: count if either ask date or stop date is filled in
  , Count(Distinct acr.proposal_id) As adjusted_progress
  , NULL As addl_progress_detail
From table(rpt_pbh634.metrics_pkg.tbl_asked_count) acr
Inner Join entity e On e.id_number = acr.assignment_id_number
-- Fiscal year goals
Left Join goal g
  On acr.assignment_id_number = g.id_number
    And g.year = rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(acr.ask_or_stop_dt)
-- Performance year goals
Left Join goal pyg
  On acr.assignment_id_number = pyg.id_number
    And pyg.year = rpt_pbh634.ksm_pkg_tmp.get_performance_year(acr.ask_or_stop_dt)
Group By rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(acr.ask_or_stop_dt)
  , acr.assignment_id_number
  , e.report_name
  , extract(year From acr.ask_or_stop_dt)
  , extract(month From acr.ask_or_stop_dt)
  , rpt_pbh634.ksm_pkg_tmp.get_quarter(acr.ask_or_stop_dt, 'fisc')
  , rpt_pbh634.ksm_pkg_tmp.get_quarter(acr.ask_or_stop_dt, 'perf')
  , rpt_pbh634.ksm_pkg_tmp.get_performance_year(acr.ask_or_stop_dt)
  , g.goal_2
  , pyg.goal_2
Union
----- KSM supplement - Kellogg asks
Select ack.assignment_id_number As id_number
  , e.report_name
  , 'KGS' As goal_type
  , 'KSM Sols' As goal_desc
  , extract(year From ack.ask_or_stop_dt) As cal_year
  , extract(month From ack.ask_or_stop_dt) As cal_month
  , rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(ack.ask_or_stop_dt) As fiscal_year
  , rpt_pbh634.ksm_pkg_tmp.get_quarter(ack.ask_or_stop_dt, 'fisc') As fiscal_quarter
  , rpt_pbh634.ksm_pkg_tmp.get_performance_year(ack.ask_or_stop_dt) As perf_year
  , rpt_pbh634.ksm_pkg_tmp.get_quarter(ack.ask_or_stop_dt, 'perf') As perf_quarter
  , g.goal_2 As fy_goal
  , pyg.goal_2 As py_goal
  -- Original definition: count only if ask date is filled in
  , Count(Distinct Case When ack.initial_contribution_date Is Not Null Then ack.proposal_id End)
    As progress
  -- Alternate definition: count if either ask date or stop date is filled in
  , Count(Distinct ack.proposal_id) As adjusted_progress
  , NULL As addl_progress_detail
From table(rpt_pbh634.metrics_pkg.tbl_asked_count_ksm) ack
Inner Join entity e On e.id_number = ack.assignment_id_number
-- Fiscal year goals
Left Join goal g
  On ack.assignment_id_number = g.id_number
    And g.year = rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(ack.ask_or_stop_dt)
-- Performance year goals
Left Join goal pyg
  On ack.assignment_id_number = pyg.id_number
    And pyg.year = rpt_pbh634.ksm_pkg_tmp.get_performance_year(ack.ask_or_stop_dt)
Group By rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(ack.ask_or_stop_dt)
  , ack.assignment_id_number
  , e.report_name
  , extract(year From ack.ask_or_stop_dt)
  , extract(month From ack.ask_or_stop_dt)
  , rpt_pbh634.ksm_pkg_tmp.get_quarter(ack.ask_or_stop_dt, 'fisc')
  , rpt_pbh634.ksm_pkg_tmp.get_quarter(ack.ask_or_stop_dt, 'perf')
  , rpt_pbh634.ksm_pkg_tmp.get_performance_year(ack.ask_or_stop_dt)
  , g.goal_2
  , pyg.goal_2
Union
----- KSM supplement - expendable cash from non-pledge payments
Select
  ksm_cash.id_number
  , ksm_cash.report_name
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
  , trunc(sum(legal_amount), 2) As progress
  , trunc(sum(legal_amount), 2) As adjusted_progress
  , trunc(sum(legal_amount), 2) As addl_progress_detail
From ksm_cash
Group By
  ksm_cash.id_number
  , ksm_cash.report_name
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
Select fr.assignment_id_number As id_number
  , e.report_name
  , 'MGDR' As goal_type
  , 'MG Dollars Raised' As goal_desc
  , extract(year From pd.date_of_record) As cal_year
  , extract(month From pd.date_of_record) As cal_month
  , rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(pd.date_of_record) As fiscal_year
  , rpt_pbh634.ksm_pkg_tmp.get_quarter(pd.date_of_record, 'fisc') As fiscal_quarter
  , rpt_pbh634.ksm_pkg_tmp.get_performance_year(pd.date_of_record) As perf_year
  , rpt_pbh634.ksm_pkg_tmp.get_quarter(pd.date_of_record, 'perf') As perf_quarter
  , g.goal_3 As fy_goal
  , pyg.goal_3 As py_goal
  , sum(Case When funded_credit_flag = 'Y' Then fr.granted_amt End) As progress
  , sum(Case When funded_credit_flag = 'Y' Then fr.granted_amt End) As adjusted_progress
  , sum(fr.granted_amt) As addl_progress_detail
From table(rpt_pbh634.metrics_pkg.tbl_funded_dollars) fr
Inner Join entity e On e.id_number = fr.assignment_id_number
Inner Join proposal_dates pd
  On pd.proposal_id = fr.proposal_id
-- Fiscal year goals
Left Join goal g
  On fr.assignment_id_number = g.id_number
    And g.year = rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(pd.date_of_record)
-- Performance year goals
Left Join goal pyg
  On fr.assignment_id_number = pyg.id_number
    And pyg.year = rpt_pbh634.ksm_pkg_tmp.get_performance_year(pd.date_of_record)
Group By rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(pd.date_of_record)
  , fr.assignment_id_number
  , e.report_name
  , extract(year From pd.date_of_record)
  , extract(month From pd.date_of_record)
  , rpt_pbh634.ksm_pkg_tmp.get_quarter(pd.date_of_record, 'fisc')
  , rpt_pbh634.ksm_pkg_tmp.get_quarter(pd.date_of_record, 'perf')
  , rpt_pbh634.ksm_pkg_tmp.get_performance_year(pd.date_of_record)
  , g.goal_3
  , pyg.goal_3
Union
----- Main query goal 4, equivalent to lines 1392-1419 in nu_gft_v_officer_metrics -----
Select Distinct cr.id_number As id_number
  , e.report_name
  , 'NOV' as goal_type
  , 'Visits' As goal_desc
  , c.cal_year
  , c.cal_month
  , c.fiscal_year
  , c.fiscal_qtr As fiscal_quarter
  , c.perf_year
  , c.perf_quarter
  , g.goal_4 As fy_goal
  , pyg.goal_4 As py_goal
  , count(Distinct c.report_id) As progress
  , count(Distinct c.report_id) As adjusted_progress
  , NULL As addl_progress_detail
From table(rpt_pbh634.metrics_pkg.tbl_contact_count) cr
Inner Join entity e On e.id_number = cr.id_number
Inner Join table(rpt_pbh634.metrics_pkg.tbl_contact_reports) c
  On cr.report_id = c.report_id
-- Fiscal year goals
Left Join goal g
  On g.id_number = cr.id_number
    And g.year = c.fiscal_year
-- Performance year goals
Left Join goal pyg
  On pyg.id_number = cr.id_number
    And pyg.year = c.perf_year
Group By c.fiscal_year
  , cr.id_number
  , e.report_name
  , c.cal_year
  , c.cal_month
  , c.fiscal_qtr
  , c.perf_quarter
  , c.perf_year
  , g.goal_4
  , pyg.goal_4
Union
----- Main query goal 5, equivalent to lines 1420-1448 in nu_gft_v_officer_metrics -----
Select Distinct cr.id_number As id_number
  , e.report_name
  , 'NOQV' As goal_type
  , 'Qual Visits' As goal_desc
  , c.cal_year
  , c.cal_month
  , c.fiscal_year
  , c.fiscal_qtr As fiscal_quarter
  , c.perf_year
  , c.perf_quarter
  , g.goal_5 As fy_goal
  , pyg.goal_5 As py_goal
  , count(Distinct c.report_id) As progress
  , count(Distinct c.report_id) As adjusted_progress
  , NULL As addl_progress_detail
From table(rpt_pbh634.metrics_pkg.tbl_contact_count) cr
Inner Join entity e On e.id_number = cr.id_number
Inner Join table(rpt_pbh634.metrics_pkg.tbl_contact_reports) c
  On cr.report_id = c.report_id
-- Fiscal year goals
Left Join goal g
  On g.id_number = cr.id_number
    And g.year = c.fiscal_year
-- Performance year goals
Left Join goal pyg
  On pyg.id_number = cr.id_number
    And pyg.year = c.perf_year
Where c.contact_purpose_code = '1' -- Only count qualification visits
Group By c.fiscal_year
  , cr.id_number
  , e.report_name
  , c.cal_year
  , c.cal_month
  , c.fiscal_qtr
  , c.perf_quarter
  , c.perf_year
  , g.goal_5
  , pyg.goal_5
Union
----- Main query goal 6, equivalent to lines 1449-1627 in nu_gft_v_officer_metrics -----
Select acr.assignment_id_number As id_number
  , e.report_name
  , 'PA' As goal_type
  , 'Proposal Assists' As goal_desc
  , extract(year From acr.ask_or_stop_dt) As cal_year
  , extract(month From acr.ask_or_stop_dt) As cal_month
  , rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(acr.ask_or_stop_dt) As fiscal_year
  , rpt_pbh634.ksm_pkg_tmp.get_quarter(acr.ask_or_stop_dt, 'fisc') As fiscal_quarter
  , rpt_pbh634.ksm_pkg_tmp.get_performance_year(acr.ask_or_stop_dt) As perf_year
  , rpt_pbh634.ksm_pkg_tmp.get_quarter(acr.ask_or_stop_dt, 'perf') As perf_quarter
  , g.goal_6 As fy_goal
  , pyg.goal_6 As py_goal
  -- Original definition: count only if ask date is filled in
  , Count(Distinct Case When acr.initial_contribution_date Is Not Null Then acr.proposal_id End)
    As progress
  -- Alternate definition: count if either ask date or stop date is filled in
  , Count(Distinct acr.proposal_id) As adjusted_progress
  , NULL As addl_progress_detail
From table(rpt_pbh634.metrics_pkg.tbl_assist_count) acr
Inner Join entity e On e.id_number = acr.assignment_id_number
-- Fiscal year goals
Left Join goal g
  On acr.assignment_id_number = g.id_number
    And g.year = rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(acr.ask_or_stop_dt) -- initial_contribution_date is 'ask_date'
-- Performance year goals
Left Join goal pyg
  On acr.assignment_id_number = pyg.id_number
    And pyg.year = rpt_pbh634.ksm_pkg_tmp.get_performance_year(acr.ask_or_stop_dt)
Group By rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(acr.ask_or_stop_dt)
  , acr.assignment_id_number
  , e.report_name
  , extract(year From acr.ask_or_stop_dt)
  , extract(month From acr.ask_or_stop_dt)
  , rpt_pbh634.ksm_pkg_tmp.get_quarter(acr.ask_or_stop_dt, 'fisc')
  , rpt_pbh634.ksm_pkg_tmp.get_quarter(acr.ask_or_stop_dt, 'perf')
  , rpt_pbh634.ksm_pkg_tmp.get_performance_year(acr.ask_or_stop_dt)
  , g.goal_6
  , pyg.goal_6
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

/*--------------------------------------
-- Pipelined function returning proposal assists data
Function tbl_assist_count
  Return ask_assist_credit Pipelined As
    -- Declarations
    pd ask_assist_credit;

  Begin
    Open c_assist_count; -- Annual Fund allocations cursor
      Fetch c_assist_count Bulk Collect Into pd;
    Close c_assist_count;
    -- Pipe out the data
    For i in 1..(pd.count) Loop
      Pipe row(pd(i));
    End Loop;
    Return;
  End;
*/
End metrics_pkg;
/
