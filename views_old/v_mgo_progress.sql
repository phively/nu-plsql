Create Or Replace View rpt_dgz654.v_mgo_progress As

With

-- Prospect manager portfolio counts (today)
prospect_manager As (
  Select
    assignment_id_number
    , count(prospect_id) AS portfolio_count
  From assignment
  Where assignment_type = 'PM'
    And active_ind = 'Y'
  Group By assignment_id_number
)

-- Staff table with descriptions
, ard_staff As (
  Select
    staff.id_number
    , entity.report_name
    , staff.name
    , staff.active_ind
    , staff.senior_staff
    , senior.report_name As senior_staff_name
    , sys_connect_by_path(staff.senior_staff, ';')
      As senior_staff_hierarchy_ids
    , sys_connect_by_path(trim(senior.report_name), '; ')
      As senior_staff_hierarchy
    , staff.office_code
    , tmso.short_desc As office_desc
    , staff.staff_type_code
    , ksm_gos.start_dt As ksm_start_dt
    , ksm_gos.stop_dt As ksm_stop_dt
    , Case
        When ksm_gos.stop_dt Is Null
          And ksm_gos.start_dt Is Not Null
          Then 'Y'
        End
      As current_ksm_staff
    , ksm_gos.team As ksm_team
    , tst.short_desc As staff_type_desc
    , staff.start_date
    , staff.stop_date
    , staff.date_added
    , staff.date_modified
  From staff
  Inner Join entity
    On entity.id_number = staff.id_number
  Left Join tms_office tmso
    On tmso.office_code = staff.office_code
  Left Join tms_staff_type tst
    On tst.staff_type_code = staff.staff_type_code
  Left Join entity senior
    On senior.id_number = staff.senior_staff
  Left Join rpt_pbh634.mv_past_ksm_gos ksm_gos
    On ksm_gos.id_number = staff.id_number
  Start With trim(senior_staff) Is Null
  Connect By Prior staff.id_number = staff.senior_staff
)

-- MGO activity over time
, all_activity As (
  Select *
  From rpt_pbh634.v_mgo_goals_monthly
)

Select Distinct
  e.pref_mail_name
  , mgm.id_number
  , mgm.report_name
  , s.office_desc
  , s.staff_type_desc
  , s.senior_staff_name
  , s.senior_staff_hierarchy
  , s.active_ind
  , s.start_date
  , s.stop_date
  , s.ksm_start_dt
  , s.ksm_stop_dt
  , s.current_ksm_staff
  , s.ksm_team
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
Cross Join rpt_pbh634.v_current_calendar cal
Left Join entity e
  On e.id_number = mgm.id_number
Left Join prospect_manager pm
  On pm.assignment_id_number = mgm.id_number
Left Join ard_staff s
  On s.id_number = mgm.id_number
Order By
  mgm.report_name
  , mgm.cal_year
  , mgm.cal_month
;
