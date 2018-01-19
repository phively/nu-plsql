-- Create Or Replace View vt_prospect_activity_lanes As

With

/* Tableau view to show prospect activity by type/"swim lane" */

-- Current calendar
-- Return data from beginning of previous FY (bofy_prev) to end of next FY (eofy_next)
cal As (
  Select
    prev_fy_start As bofy_prev
    , add_months(next_fy_start, 12) - 1 As eofy_next
  From v_current_calendar
)

-- Prospect data
, prospects As (
  Select
    prospect_id
    , id_number
    , report_name
    , primary_ind
    , type
    , NULL As additional_desc
    , 'Prospect' As category
    , id
    -- Dates for debugging
/*  , start_date
    , stop_date
    , date_added
    , date_modified */
    -- Use date_added as start_date if unavailable
    , Case
        When start_date Is Not Null Then start_date
        Else date_added
      End As start_date
    -- Use date_modified as start_date if unavailable, but only for inactive/completed status
    , Case
        When stop_date Is Not Null Then stop_date
        When lower(status) Like '%inactive%' Or lower(status) Like '%completed%' Then date_modified
        Else Null
      End As stop_date
    , status
    , owner_id
    , owner_report_name
    , description
  From v_ard_prospect_timeline
  Cross Join cal
  Where start_date Between cal.bofy_prev And cal.eofy_next
    Or stop_date Between cal.bofy_prev And cal.eofy_next
)

-- ARD contact report data
, contacts As (
  Select
    prospect_id
    , id_number
    , contacted_name
    , primary_ind
    , contact_type_category
    , visit_type As additional_desc
    , 'Contact' As category
    , report_id
    , contact_date
    , NULL As stop_date
    , contact_purpose
    , credited
    , credited_name
    , description
  From v_ard_contact_reports
  Cross Join cal
  Where contact_date Between cal.bofy_prev And cal.eofy_next
)

-- Historical KSM proposal data
, ksm_proposals As (
  Select
    prp.prospect_id
    , prospect_entity.id_number
    , entity.report_name
    , prospect_entity.primary_ind
    , proposal_status
    , ksm_or_univ_orig_ask
    , total_original_ask_amt
    , ksm_or_univ_ask
    , total_ask_amt
    , ksm_or_univ_anticipated
    , total_anticipated_amt
    , ksm_linked_amounts
    , 'Proposal' As category
    , proposal_id
    , start_date
    , ask_date
    , close_date
    , prop_purposes
    , proposal_manager_id
    , proposal_manager
    , initiatives
  From v_ksm_proposal_history prp
  Cross Join cal
  Inner Join prospect_entity On prospect_entity.prospect_id = prp.prospect_id
  Inner Join entity On entity.id_number = prospect_entity.id_number
  Where start_date Between cal.bofy_prev And cal.eofy_next
    Or ask_date Between cal.bofy_prev And cal.eofy_next
    Or close_date Between cal.bofy_prev And cal.eofy_next
)
, proposal_starts As (
  Select
    prospect_id
    , id_number
    , report_name
    , primary_ind
    , 'Proposal Start' As type
    , Case
        When ksm_or_univ_orig_ask > 0 Then to_char(ksm_or_univ_orig_ask, '$999,999,999,999')
        Else to_char(ksm_or_univ_ask, '$999,999,999,999')
      End As original_ask
    , category
    , proposal_id
    , start_date
    , NULL
    , proposal_status
    , proposal_manager_id
    , proposal_manager
    , initiatives
  From ksm_proposals
)
, proposal_asks As (
  Select
    prospect_id
    , id_number
    , report_name
    , primary_ind
    , 'Proposal Ask' As type
    , to_char(ksm_or_univ_ask, '$999,999,999,999') As ask
    , category
    , proposal_id
    , ask_date
    , NULL
    , proposal_status
    , proposal_manager_id
    , proposal_manager
    , initiatives
  From ksm_proposals
)
, proposal_closes As (
  Select
    prospect_id
    , id_number
    , report_name
    , primary_ind
    , 'Proposal Close' As type
    , to_char(ksm_linked_amounts, '$999,999,999,999') As closed
    , category
    , proposal_id
    , close_date
    , NULL
    , proposal_status
    , proposal_manager_id
    , proposal_manager
    , initiatives
  From ksm_proposals
)

-- Main query
Select * From prospects
Union
Select * From contacts
Union
Select * From proposal_starts
Union
Select * From proposal_asks
Union
Select * From proposal_closes
