Create Or Replace View vt_ksm_mg_cash As

Select c.*
  , rpt_pbh634.ksm_pkg_calendar.get_performance_year(c.DATE_OF_RECORD)
    As performance_year
  , staff.team
  , staff.start_dt As staff_start_dt
  , staff.stop_dt As staff_stop_dt
From v_ksm_giving_cash c
Left Join rpt_pbh634.mv_past_ksm_gos staff
  On staff.id_number = c.primary_credited_mgr
Where c.primary_credited_mgr Is Not Null
;
