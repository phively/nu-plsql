-- Create Or Replace View vt_engagement_detail

-- Visits
Select Distinct
  v.*
  , Case When ah.assignment_report_name Is Not Null Then 'Y' End As pm_visit
From v_nu_visits v
Cross Join v_current_calendar cal
Left Join v_assignment_history ah
  On v.credited = ah.assignment_id_number
  And v.prospect_id = ah.prospect_id
  And assignment_type = 'PM'
  And v.contact_date Between ah.start_dt_calc And nvl(ah.stop_dt_calc, cal.next_fy_start)
