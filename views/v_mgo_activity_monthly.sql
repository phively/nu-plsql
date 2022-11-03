/***********************************************************************************************
Tweak original v_mgo_goals_monthly to show activity even in months/years without a goal entered
***********************************************************************************************/

Create Or Replace View v_mgo_activity_monthly As

-- See package metrics_pkg for definitions of each table function

With

proposal_dates As (
  Select *
  From table(rpt_pbh634.metrics_pkg.tbl_proposal_dates)
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

/***********************************************************************************************
Goals table filled in with 0 for progress
***********************************************************************************************/

Create Or Replace View v_mgo_goals_placeholder As

With goals As (
  -- Goal 1
  Select
    goal.id_number
    , entity.report_name
    , 'MGC' As goal_type
    , 'MG Closes' As goal_desc
    , goal.year As cal_year
    , 1 As cal_month
    , goal.year As fiscal_year
    , 3 As fiscal_quarter
    , goal.year As perf_year
    , 1 As perf_quarter
    , goal_1 As fy_goal
    , goal_1 As py_goal
    , 0 As progress
    , 0 As adjusted_progress
    , NULL As addl_progress_detail
  From entity
  Inner Join goal
    On entity.id_number = goal.id_number
  Union All
  -- Goal 2
  Select
    goal.id_number
    , entity.report_name
    , 'MGS' As goal_type
    , 'MG Sols' As goal_desc
    , goal.year As cal_year
    , 1 As cal_month
    , goal.year As fiscal_year
    , 3 As fiscal_quarter
    , goal.year As perf_year
    , 1 As perf_quarter
    , goal_2 As fy_goal
    , goal_2 As py_goal
    , 0 As progress
    , 0 As adjusted_progress
    , NULL As addl_progress_detail
  From entity
  Inner Join goal
    On entity.id_number = goal.id_number
  Union All
  -- Goal 2 KSM
  Select
    goal.id_number
    , entity.report_name
    , 'KGS' As goal_type
    , 'KSM Sols' As goal_desc
    , goal.year As cal_year
    , 1 As cal_month
    , goal.year As fiscal_year
    , 3 As fiscal_quarter
    , goal.year As perf_year
    , 1 As perf_quarter
    , goal_2 As fy_goal
    , goal_2 As py_goal
    , 0 As progress
    , 0 As adjusted_progress
    , NULL As addl_progress_detail
  From entity
  Inner Join goal
    On entity.id_number = goal.id_number
  Union All
  -- Goal 3
  Select
    goal.id_number
    , entity.report_name
    , 'MGDR' As goal_type
    , 'MG Dollars Raised' As goal_desc
    , goal.year As cal_year
    , 1 As cal_month
    , goal.year As fiscal_year
    , 3 As fiscal_quarter
    , goal.year As perf_year
    , 1 As perf_quarter
    , goal_3 As fy_goal
    , goal_3 As py_goal
    , 0 As progress
    , 0 As adjusted_progress
    , NULL As addl_progress_detail
  From entity
  Inner Join goal
    On entity.id_number = goal.id_number
  Union All
  -- Goal 4
  Select
    goal.id_number
    , entity.report_name
    , 'NOV' as goal_type
    , 'Visits' As goal_desc
    , goal.year As cal_year
    , 1 As cal_month
    , goal.year As fiscal_year
    , 3 As fiscal_quarter
    , goal.year As perf_year
    , 1 As perf_quarter
    , goal_4 As fy_goal
    , goal_4 As py_goal
    , 0 As progress
    , 0 As adjusted_progress
    , NULL As addl_progress_detail
  From entity
  Inner Join goal
    On entity.id_number = goal.id_number
  Union All
  -- Goal 5
  Select
    goal.id_number
    , entity.report_name
    , 'NOQV' As goal_type
    , 'Qual Visits' As goal_desc
     , goal.year As cal_year
    , 1 As cal_month
    , goal.year As fiscal_year
    , 3 As fiscal_quarter
    , goal.year As perf_year
    , 1 As perf_quarter
    , goal_5 As fy_goal
    , goal_5 As py_goal
    , 0 As progress
    , 0 As adjusted_progress
    , NULL As addl_progress_detail
  From entity
  Inner Join goal
    On entity.id_number = goal.id_number
  Union All
  -- Goal 6
  Select
    goal.id_number
    , entity.report_name
    , 'PA' As goal_type
    , 'Proposal Assists' As goal_desc
     , goal.year As cal_year
    , 1 As cal_month
    , goal.year As fiscal_year
    , 3 As fiscal_quarter
    , goal.year As perf_year
    , 1 As perf_quarter
    , goal_6 As fy_goal
    , goal_6 As py_goal
    , 0 As progress
    , 0 As adjusted_progress
    , NULL As addl_progress_detail
  From entity
  Inner Join goal
    On entity.id_number = goal.id_number
)

Select
  id_number
  , report_name
  , goal_type
  , goal_desc
  , cal_year
  , cal_month
  , fiscal_year
  , fiscal_quarter
  , perf_year
  , perf_quarter
  , fy_goal
  , py_goal
  , progress
  , adjusted_progress
  , addl_progress_detail
From goals
Order By
  report_name Asc
  , cal_year Asc
  , cal_month Asc
;

/***********************************************************************************************
Goals view -- monthly refactored version of ADVANCE_NU.NU_GFT_V_OFFICER_METRICS
***********************************************************************************************/

Create Or Replace View v_mgo_goals_monthly As

Select
  id_number
  , report_name
  , goal_type
  , goal_desc
  , cal_year
  , cal_month
  , fiscal_year
  , fiscal_quarter
  , perf_year
  , perf_quarter
  , fy_goal
  , py_goal
  , progress
  , adjusted_progress
  , addl_progress_detail
From v_mgo_activity_monthly v
Where py_goal Is Not Null
-- Append placeholder rows so goals with 0 progress still appear
Union
Select
  id_number
  , report_name
  , goal_type
  , goal_desc
  , cal_year
  , cal_month
  , fiscal_year
  , fiscal_quarter
  , perf_year
  , perf_quarter
  , fy_goal
  , py_goal
  , progress
  , adjusted_progress
  , addl_progress_detail
From v_mgo_goals_placeholder
;
