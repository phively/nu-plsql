Create Or Replace View vt_prospect_activity_lanes As

With

/* Tableau view to show prospect activity by type/"swim lane" */

-- Current calendar
-- Return data from beginning of previous FY (bofy_prev) to end of next FY (eofy_next)
cal As (
  Select
    prev_fy_start As bofy_prev
    , curr_fy_start As bofy_curr
    , next_fy_start As bofy_next
    , add_months(next_fy_start, 12) - 1 As eofy_next
    , yesterday
    , ninety_days_ago
  From v_current_calendar
)

-- Householding
, hh As (
  Select
    id_number
    , household_id
    , household_rpt_name
  From table(ksm_pkg.tbl_entity_households_ksm)
)

-- Prospect data
, prospects As (
  Select
    prospect_id
    , hh.household_id
    , hh.household_rpt_name
    , tl.id_number
    , report_name
    , primary_ind
    , rpt_pbh634.ksm_pkg.get_prospect_rating_bin(tl.id_number) As rating_bin
    -- Data point description
    , type
    -- Additional description detail
    , NULL As additional_desc
    -- Category summary
    , 'Prospect' As category
    -- Tableau color field
    , type As color
    -- Unique identifier
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
    -- Use date_modified as stop_date if unavailable, but only for inactive/completed status
    , Case
        When stop_date Is Not Null Then stop_date
        When lower(status) Like '%inactive%' Or lower(status) Like '%completed%' Then date_modified
        Else Null
      End As stop_date
    -- Status detail
    , status
    -- Credited entity
    , owner_id
    , owner_report_name
    -- Summary text detail
    , description
    -- Symbol to use in Tableau; first letter
    , substr(type, 1, 1) As symbol
    -- Uniform calendar dates for axis alignment
    , cal.*
  From v_ard_prospect_timeline tl
  Cross Join cal
  Inner Join hh On hh.id_number =  tl.id_number
  Where start_date Between cal.bofy_prev And cal.eofy_next
)

-- ARD contact report data
, contacts As (
  Select
    prospect_id
    , hh.household_id
    , hh.household_rpt_name
    , cr.id_number
    , report_name
    , primary_ind
    , rating_bin
    -- Data point description
    , contact_type_category
    -- Additional description detail
    , visit_type As additional_desc
    -- Category summary
    , 'Contact'
    -- Tableau color field
    , contact_type_category As color
    -- Unique identifier
    , report_id
    -- Uniform start date for axis alignment
    , contact_date
    -- Uniform stop date for axis alignment
    , NULL
    -- Status detail
    , contact_purpose
    -- Credited entity
    , credited
    , credited_name
    -- Summary text detail
    , description
    -- Tableau symbol
    , substr(contact_type_category, 1, 1) As symbol
    -- Uniform calendar dates for axis alignment
    , cal.*
  From v_ard_contact_reports cr
  Cross Join cal
  Inner Join hh On hh.id_number =  cr.id_number
  Where contact_date Between cal.bofy_prev And cal.eofy_next
)

-- Historical KSM proposal data
, ksm_proposals As (
  Select
    prp.prospect_id
    , hh.household_id
    , hh.household_rpt_name
    , prospect_entity.id_number
    , entity.report_name
    , prospect_entity.primary_ind
    , rpt_pbh634.ksm_pkg.get_prospect_rating_bin(prospect_entity.id_number) As rating_bin
    -- Data point description
    , proposal_status
    , ksm_or_univ_orig_ask
    , total_original_ask_amt
    , ksm_or_univ_ask
    , total_ask_amt
    , ksm_or_univ_anticipated
    , total_anticipated_amt
    , ksm_linked_amounts
    , 'Proposal' As category
    -- Tableau color field
    , 'Proposal' As color
    -- Unique identifier
    , proposal_id
    , start_date
    , ask_date
    , close_date
    , prop_purposes
    , proposal_manager_id
    , proposal_manager
    , initiatives
    -- Uniform calendar dates for axis alignment
    , cal.*
  From v_ksm_proposal_history prp
  Cross Join cal
  Inner Join prospect_entity On prospect_entity.prospect_id = prp.prospect_id
  Inner Join hh On hh.id_number = prospect_entity.id_number
  Inner Join entity On entity.id_number = prospect_entity.id_number
  Where start_date Between cal.bofy_prev And cal.eofy_next
    Or ask_date Between cal.bofy_prev And cal.eofy_next
    Or close_date Between cal.bofy_prev And cal.eofy_next
)
, proposal_starts As (
  Select
    prospect_id
    , hh.household_id
    , hh.household_rpt_name
    , prp.id_number
    , report_name
    , primary_ind
    , rating_bin
    -- Data point description
    , 'Proposal Start' As type
    -- Additional description detail
    , Case
        When ksm_or_univ_orig_ask > 0 Then to_char(ksm_or_univ_orig_ask, '$999,999,999,999')
        Else to_char(ksm_or_univ_ask, '$999,999,999,999')
      End As original_ask
    -- Category summary
    , category
    -- Tableau color field
    , color
    -- Unique identifier
    , proposal_id
    -- Uniform start date for axis alignment
    , start_date
    -- Uniform stop date for axis alignment
    , NULL
    -- Status detail
    , proposal_status
    -- Credited entity
    , proposal_manager_id
    , proposal_manager
    -- Summary text detail
    , initiatives
    -- Tableau symbol
    , '+' As symbol
    -- Uniform calendar dates for axis alignment
    , cal.*
  From ksm_proposals prp
  Cross Join cal
  Inner Join hh On hh.id_number =  prp.id_number
  Where start_date Between cal.bofy_prev And cal.eofy_next
)
, proposal_asks As (
  Select
    prospect_id
    , household_id
    , household_rpt_name
    , id_number
    , report_name
    , primary_ind
    , rating_bin
    -- Data point description
    , 'Proposal Ask' As type
    -- Additional description detail
    , to_char(ksm_or_univ_ask, '$999,999,999,999') As ask
    -- Category summary
    , category
    -- Tableau color field
    , color
    -- Unique identifier
    , proposal_id
    -- Uniform start date for axis alignment
    , ask_date
    -- Uniform stop date for axis alignment
    , NULL
    -- Status detail
    , proposal_status
    -- Credited entity
    , proposal_manager_id
    , proposal_manager
    -- Summary text detail
    , initiatives
    -- Tableau symbol
    , 'a' As symbol
    -- Uniform calendar dates for axis alignment
    , cal.*
  From ksm_proposals
  Cross Join cal
  Where ask_date Between cal.bofy_prev And cal.eofy_next
)
, proposal_closes As (
  Select
    prospect_id
    , household_id
    , household_rpt_name
    , id_number
    , report_name
    , primary_ind
    , rating_bin
    -- Data point description
    , 'Proposal Close' As type
    -- Additional description detail
    , to_char(ksm_linked_amounts, '$999,999,999,999') As closed
    -- Category summary
    , category
    -- Tableau color field
    , color
    -- Unique identifier
    , proposal_id
    -- Uniform start date for axis alignment
    , close_date
    -- Uniform stop date for axis alignment
    , NULL
    -- Status detail
    , proposal_status
    -- Credited entity
    , proposal_manager_id
    , proposal_manager
    -- Summary text detail
    , initiatives
    -- Tableau symbol
    , 'x' As symbol
    -- Uniform calendar dates for axis alignment
    , cal.*
  From ksm_proposals
  Cross Join cal
  Where close_date Between cal.bofy_prev And cal.eofy_next
)

-- Historical KSM gifts, including pledges/payments
, ksm_giving As (
  Select
    pe.prospect_id
    , gft.household_id
    , hh.household_rpt_name
    , gft.id_number
    , entity.report_name
    , pe.primary_ind
    , rpt_pbh634.ksm_pkg.get_prospect_rating_bin(pe.prospect_id) As rating_bin
    , gft.transaction_type As type
    , to_char(gft.recognition_credit, '$999,999,999,999') As recognition_credit
    , gft.tx_gypm_ind
    , 'Gift' As category
    , 'Gift' As color
    -- Unique identifier
    , to_number(gft.tx_number) As tx_number
    , gft.date_of_record
    , tms_ps.short_desc As pledge_status
    , gft.transaction_type
    , trim(gft.alloc_short_name || ' (' || gft.allocation_code || ')
      ' || gft.gift_comment) As description
    , gft.proposal_id
  From v_ksm_giving_trans_hh gft
  Cross Join cal
  Inner Join hh On hh.id_number =  gft.id_number
  Inner Join prospect_entity pe On pe.id_number = gft.id_number
  Inner Join entity On entity.id_number = gft.id_number
  Left Join tms_pledge_status tms_ps On tms_ps.pledge_status_code = gft.pledge_status
  Where gft.date_of_record Between cal.bofy_prev And cal.eofy_next
)
, ksm_gift As (
  Select
    prospect_id
    , household_id
    , household_rpt_name
    , id_number
    , report_name
    , primary_ind
    , rating_bin
    -- Data point description
    , 'Gift' As type
    -- Additional description detail
    , recognition_credit
    -- Category summary
    , category
    -- Tableau color field
    , color
    -- Unique identifier
    , tx_number
    -- Uniform start date for axis alignment
    , date_of_record
    -- Uniform stop date for axis alignment
    , NULL
    -- Status detail
    , transaction_type As status
    -- Credited entity
    , NULL
    , NULL
    -- Summary text detail
    , description
    -- Tableau symbol
    , '$' As symbol
    -- Uniform calendar dates for axis alignment
    , cal.*
  From ksm_giving
  Cross Join cal
  Where ksm_giving.tx_gypm_ind = 'G'
)
, ksm_payment As (
  Select
    prospect_id
    , household_id
    , household_rpt_name
    , id_number
    , report_name
    , primary_ind
    , rating_bin
    -- Data point description
    , 'Payment' As type
    -- Additional description detail
    , recognition_credit
    -- Category summary
    , category
    -- Tableau color field
    , color
    -- Unique identifier
    , tx_number
    -- Uniform start date for axis alignment
    , date_of_record
    -- Uniform stop date for axis alignment
    , NULL
    -- Status detail
    , transaction_type As status
    -- Credited entity
    , NULL
    , NULL
    -- Summary text detail
    , description
    -- Tableau symbol
    , 'Y' As symbol
    -- Uniform calendar dates for axis alignment
    , cal.*
  From ksm_giving
  Cross Join cal
  Where ksm_giving.tx_gypm_ind = 'Y'
)
, ksm_match As (
  Select
    prospect_id
    , household_id
    , household_rpt_name
    , id_number
    , report_name
    , primary_ind
    , rating_bin
    -- Data point description
    , 'Match' As type
    -- Additional description detail
    , recognition_credit
    -- Category summary
    , category
    -- Tableau color field
    , color
    -- Unique identifier
    , tx_number
    -- Uniform start date for axis alignment
    , date_of_record
    -- Uniform stop date for axis alignment
    , NULL
    -- Status detail
    , transaction_type As status
    -- Credited entity
    , NULL
    , NULL
    -- Summary text detail
    , description
    -- Tableau symbol
    , 'M' As symbol
    -- Uniform calendar dates for axis alignment
    , cal.*
  From ksm_giving
  Cross Join cal
  Where ksm_giving.tx_gypm_ind = 'M'
)
, ksm_plg As (
  Select
    prospect_id
    , household_id
    , household_rpt_name
    , id_number
    , report_name
    , primary_ind
    , rating_bin
    -- Data point description
    , 'Pledge' As type
    -- Additional description detail
    , recognition_credit
    -- Category summary
    , category
    -- Tableau color field
    , color
    -- Unique identifier
    , tx_number
    -- Uniform start date for axis alignment
    , date_of_record
    -- Uniform stop date for axis alignment
    , NULL
    -- Status detail
    , transaction_type || ' (' || pledge_status || ')' As status
    -- Credited entity
    , NULL
    , NULL
    -- Summary text detail
    , description
    -- Tableau symbol
    , 'P' As symbol
    -- Uniform calendar dates for axis alignment
    , cal.*
  From ksm_giving
  Cross Join cal
  Where ksm_giving.tx_gypm_ind = 'P'
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
Union
Select * From ksm_gift
Union
Select * From ksm_payment
Union
Select * From ksm_match
Union
Select * From ksm_plg
