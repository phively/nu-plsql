Create Or Replace View tableau_mgo_progress As

With

-- Prospect manager portfolio counts (today)
pm As (
  Select
    ah.staff_user_salesforce_id
    , ah.staff_name
    , count(Distinct ah.household_id_ksm)
      As portfolio_count
  From mv_assignment_history ah
  Where
    ah.assignment_code = 'PRM'
    And ah.is_active_indicator = 'true'
    And ah.household_primary_ksm = 'Y'
  Group By
    ah.staff_user_salesforce_id
    , ah.staff_name
)

-- Staff table with descriptions
, staff As (
  Select Distinct
    mah.staff_user_salesforce_id
    , mah.staff_name
    , kgo.start_dt As ksm_start_dt
    , kgo.stop_dt As ksm_stop_dt
    , kgo.active_flag
      As current_ksm_staff
    , kgo.team As ksm_team
  From mv_assignment_history mah
  Left Join tbl_ksm_gos kgo
    On kgo.user_id = mah.staff_user_salesforce_id
)

-- MGO activity over time
, mgm As (
  Select *
  From table(metrics_pkg.tbl_mgo_activity_monthly)
)

Select Distinct
  mgm.historical_pm_user_id
  , mgm.historical_pm_name
  , mgm.gift_officer_donor_id
  , mgm.gift_officer_sort_name
  , s.ksm_start_dt
  , s.ksm_stop_dt
  , s.current_ksm_staff
  , s.ksm_team
  , mgm.goal_type
  , mgm.goal_desc
  , mgm.cal_year
  , mgm.cal_month
  , mgm.fiscal_year
  , mgm.fiscal_qtr
  , mgm.perf_year
  , mgm.perf_quarter
  , mgm.py_goal
  , mgm.fy_goal
  , mgm.progress
  , mgm.adjusted_progress
  , mgm.addl_progress_detail
  , cal.today
  , cal.yesterday
  , cal.ninety_days_ago
  , cal.curr_fy
  , cal.prev_fy_start
  , cal.curr_fy_start
  , cal.next_fy_start
  , cal.curr_py
  , cal.prev_py_start
  , cal.curr_py_start
  , cal.next_py_start
  , cal.prev_fy_today
  , cal.next_fy_today
  , cal.prev_week_start
  , cal.curr_week_start
  , cal.next_week_start
  , cal.prev_month_start
  , cal.curr_month_start
  , cal.next_month_start
  , Case
      When mgm.perf_year = cal.curr_py
      Then cal.yesterday - cal.curr_py_start
        Else 365
    End
    As py_prog_days
  , ''
    As ksm_region
  , pm.portfolio_count
From mgm
Cross Join v_current_calendar cal
Left Join pm
  On pm.staff_user_salesforce_id = mgm.historical_pm_user_id
Left Join staff s
  On s.staff_user_salesforce_id = mgm.historical_pm_user_id
Order By
  mgm.historical_pm_name
  , mgm.cal_year
  , mgm.cal_month
;
