Create Or Replace View rpt_dgz654.v_mgo_progress As

With

prospect_manager As (
  Select
    assignment_id_number
    , count(prospect_id) AS portfolio_count
  From assignment
  Where assignment_type = 'PM'
    And active_ind = 'Y'
  Group By assignment_id_number
)

, all_activity As (
  Select *
  From rpt_pbh634.v_mgo_goals_monthly
)

Select Distinct
  e.pref_mail_name
  , mgm.id_number
  , mgm.report_name
  , mgm.goal_type
  , mgm.goal_desc
  , mgm.cal_year
  , mgm.cal_month
  , mgm.fiscal_year
  , mgm.fiscal_quarter
  , mgm.perf_year
  , mgm.perf_quarter
  , mgm.fy_goal
  , mgm.py_goal
  , mgm.progress
  , mgm.adjusted_progress
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
  , Case
      When mgm.id_number In ('0000549376', '0000562459', '0000776709')
        Then 'Midwest'
      When mgm.id_number In ('0000642888', '0000561243')
        Then 'East'
      When mgm.id_number In ('0000565742', '0000220843', '0000779347')
        Then 'West'
      When mgm.id_number = '0000772028'
        Then 'All'
      Else 'Non-KSM'
    End
    As ksm_region
  , pm.portfolio_count
From all_activity mgm
Left Join entity e
  On e.id_number = mgm.id_number
Left Join prospect_manager pm
  On pm.assignment_id_number = mgm.id_number
Cross Join rpt_pbh634.v_current_calendar cal
Order By
  mgm.report_name
  , mgm.cal_year
  , mgm.cal_month
;
