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
, committees As (
  Select
    c.*
    , Case When c.committee_code = 'TBOT' Then 'Y' End As trustee
    , Case When c.committee_code In ('KGAB', 'U') Then 'Y' End As gab
    , Case When c.committee_type_code In ('AR', 'AN') Then 'Y' End As alumni_club
    , cal.next_fy_start - 1
      As cfy_end
  From v_nu_committees c
  Cross Join cal
  Where
  -- Was in committee in current or previous FY
    -- Start date in time period
    c.start_dt_calc Between cal.prev_fy_start And (cal.next_fy_start - 1)
    -- Stop date in time period
    Or c.stop_dt_calc Between cal.prev_fy_start And (cal.next_fy_start - 1)
    -- PFY time period between start and stop date
    Or cal.prev_fy_start Between c.start_dt_calc and c.stop_dt_calc
    -- NFY time period between start and stop date
    Or (cal.next_fy_start - 1) Between c.start_dt_calc And c.stop_dt_calc
)

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
(
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
    , to_char(report_id)
      As engagement_id
    , contact_date
      As engagement_date
    , fiscal_year
      As engagement_fy
  From visits
)
-- Committees
Union (
  Select  
    committees.id_number
    , 'Committee'
      As engagement_type
    , Case
        When trustee = 'Y'
          Then 'Trustee'
        When gab = 'Y'
          Then 'KSM GAB'
        When alumni_club = 'Y'
          Then 'Alumni Clubs'
        Else 'Other Committee'
        End
      As engagement_type_detail
    , committee_type
      As type_detail
    , Case
        When ksm_committee = 'Y'
          Then 'Kellogg committee'
        End
      As engagement_responsible
    , committee_desc
      As engagement_detail
    , id_number || '-' || xsequence
      As engagement_id
    -- Dates based on stop_dt_calc, or current FY if that is in the future
    , Case
        When stop_dt_calc > cfy_end
          Then cfy_end
        Else stop_dt_calc
        End
      As engagement_date
    , Case
        When stop_dt_calc > cfy_end
          Then ksm_pkg.get_fiscal_year(cfy_end)
        Else ksm_pkg.get_fiscal_year(stop_dt_calc)
        End
      As engagement_fy
  From committees
  Where alumni_club Is Null -- Exclude the alumni clubs
)
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
