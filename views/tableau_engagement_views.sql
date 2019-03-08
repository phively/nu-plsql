/* Current and previous fiscal year engagement details */
-- Create Or Replace View vt_engagement_detail As

With

-- Current calendar
cal As (
  Select
    yesterday
    , curr_fy
    , prev_fy_start
    , curr_fy_start
    , next_fy_start
  From v_current_calendar cal
)

-- Visits
, visits As (
  Select Distinct
    v.*
    , Case When ah.assignment_report_name Is Not Null Then 'Y' End As pm_visit
  From v_nu_visits v
  Cross Join cal
  Left Join v_assignment_history ah
    On v.credited = ah.assignment_id_number
    And v.prospect_id = ah.prospect_id
    And assignment_type = 'PM'
    And v.contact_date Between ah.start_dt_calc And nvl(ah.stop_dt_calc, cal.next_fy_start)
  Where v.fiscal_year Between cal.curr_fy - 1 And cal.curr_fy
)

-- Committees
--v_nu_committees

-- Events
--v_nu_event_participants

-- Activities
--v_nu_activities
-- KSM only

-- Giving
--v_ksm_giving_trans_hh

-- Contact reports???

-- Merged pull
-- Visits
Select
  visits.id_number
  , 'Visit'
    As engagement_type
  , Case
      When president_visit = 'Y'
        Then 'President Visit'
      When ksm_dean_visit = 'Y'
        Then 'Dean Visit'
      When pm_visit = 'Y'
        Then 'PM Visit'
      Else 'Other Visit'
      End
    As engagement_type_detail
  , visit_type
    As type_detail
  , credited_name
    As engagement_responsible
  , description
    As engagement_detail
  , report_id
    As engagement_id
  , contact_date
    As engagement_date
  , fiscal_year
    As engagement_fy
From visits
-- Committees
---- GAB, BOT, Other
-- Events
---- KSM, NU
-- Activities
---- KSM only
-- Giving
---- KSM gift/pledge/pay, NU NGC only

-- Final pull
-- id_number
-- , report_name
-- , degrees_concat
-- , inst_suffix
-- , PM
