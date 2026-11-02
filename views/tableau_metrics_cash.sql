Create Or Replace View tableau_metrics_cash As

Select c.*
  , ksm_pkg_calendar.get_performance_year(c.credit_date)
    As performance_year
  , staff.team
  , staff.start_dt As staff_start_dt
  , staff.stop_dt As staff_stop_dt
From v_ksm_gifts_cash c
Inner Join tbl_ksm_gos staff
  On staff.user_id = c.historical_credit_user_id
;
