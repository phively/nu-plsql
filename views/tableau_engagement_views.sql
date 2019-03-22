/*********************************************************
Current and previous fiscal year engagement details
*********************************************************/

Create Or Replace View vt_engagement_detail As

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
, events As (
  Select ep.*
  From v_nu_event_participants ep
  Cross Join cal
  Where ep.start_fy_calc Between cal.curr_fy - 1 And cal.curr_fy
    Or ep.stop_fy_calc Between cal.curr_fy - 1 And cal.curr_fy
)

-- Activities
, activities As (
  Select *
  From v_nu_activities
  Cross Join cal
  Where
    -- Kellogg only
    ksm_activity = 'Y'
    -- Must be in suitable time range
    And (
      start_fy_calc Between cal.curr_fy - 1 And cal.curr_fy
      Or stop_fy_calc Between cal.curr_fy - 1 And cal.curr_fy
    )
)

-- Giving
, giving As (
  Select
    gthh.*
  From v_ksm_giving_trans_hh gthh
  Cross Join cal
  Where gthh.fiscal_year Between cal.curr_fy - 1 And cal.curr_fy
)

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
    , NULL
      As engagement_dollars
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
    , NULL
      As engagement_dollars
    , to_char(xsequence)
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
Union (
  Select
    events.id_number
    , 'Event'
      As engagement_type
    , Case
        When ksm_event = 'Y'
          Then 'KSM Event'
        Else 'Other Event'
        End
      As engagement_type_detail
    , event_type
      As type_detail
    , NULL
      As engagement_responsible
    , event_name
      As engagement_detail
    , NULL
      As engagement_dollars
    , to_char(event_id)
      As engagement_id
    , start_dt
      As engagement_date
    , start_fy_calc
      As engagement_fy
  From events
)
-- Activities
Union (
  Select
    activities.id_number
    , 'Activity'
      As engagement_type
    , 'All'
      As engagement_type_detail
    , activity_desc
      As type_detail
    , NULL
      As engagement_responsible
    , xcomment
      As engagement_detail
    , NULL
      As engagement_dollars
    , to_char(xsequence)
      As engagement_id
    , start_dt
      As engagement_date
    , start_fy_calc
      As engagement_fy
  From activities
)
-- Giving
Union (
 Select
    giving.id_number
    , 'Giving'
      As engagement_type
    , Case
        When tx_gypm_ind = 'G'
          Then 'Gift'
        When tx_gypm_ind = 'Y'
          Then 'Payment'
        When tx_gypm_ind = 'P'
          Then 'Pledge'
        When tx_gypm_ind = 'M'
          Then 'Match'
        End
      As engagement_type_detail
    , transaction_type
      As type_detail
    , NULL
      As engagement_responsible
    , alloc_short_name
      As engagement_detail
    , recognition_credit
      As engagement_dollars
    , tx_number || '-' || tx_sequence
      As engagement_id
    , date_of_record
      As engagement_date
    , fiscal_year
      As engagement_fy
  From giving
)
;

/*********************************************************
Summarized engagement details
*********************************************************/
/* Create Or Replace View vt_engagement_summary As

With

agg As (
  Select
  From vt_engagement_detail
  Group By
)

Select
  prs.id_number
  , prs.report_name
  , prs.institutional_suffix
  , prs.degrees_concat
  , prs.program_group
  , prs.business_title
  , prs.employer_name
  , prs.prospect_id
  , prs.prospect_manager_id
  , prs.prospect_manager
  , prs.managers
  , prs.curr_ksm_manager
  , prs.prospect_stage
  , prs.evaluation_rating
  , prs.evaluation_date
  , prs.uor
  , prs.uor_date
  , prs.mgo_id_model
  , prs.mgo_id_score
  , prs.mgo_pr_model
  , prs.mgo_pr_score
From v_ksm_prospect_pool prs
*/
