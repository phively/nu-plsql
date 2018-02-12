/****************************************
KSM Campaign gifts booked and open proposals in one view
****************************************/

Create Or Replace View vt_ksm_mg_fy_metrics As

With
cal As (
  Select *
  From rpt_pbh634.v_current_calendar
)

/* Proposal status and year-to-date new gifts and commitments for KSM MG metrics */
(
  -- Gift data
  Select amount, to_number(year_of_giving) As fiscal_year, cal.curr_fy, ytd_ind,
    Case
      When amount >= 10000000 Then 10
      When amount >=  5000000 Then 5
      When amount >=  2000000 Then 2
      When amount >=  1000000 Then 1
      When amount >=   500000 Then 0.5
      When amount >=   100000 Then 0.1
      Else 0
    End As bin,
    'Booked' As cat, 'Campaign Giving' As src
  From v_ksm_giving_campaign_ytd
  Cross Join cal
  Where year_of_giving Between 2007 And 2020 -- FY 2007 and 2020 as first and last campaign gift dates
    And amount > 0
) Union All (
  -- Proposal data
  -- Includes proposals expected to close in current and previous fiscal year as current fiscal year
  Select final_anticipated_or_ask_amt, cal.curr_fy As fiscal_year, cal.curr_fy, 'Y',
    ksm_bin, proposal_status As cat, 'Proposals' As src
  From rpt_pbh634.v_ksm_proposal_history
  Cross Join cal
  Where proposal_in_progress = 'Y'
    And close_fy Between cal.curr_fy - 1 And cal.curr_fy -- Do not include historical proposal data which is not helpful
)
;

/****************************************
Kellogg prospect pool definition plus giving,
proposal, etc. fields
****************************************/

Create Or Replace View vt_ksm_prs_pool As

With

/* v_ksm_prospect_pool with a few giving-related fields appended
   Also includes strategy and current proposals
   Fairly slow to refresh due to multiple views */

/* Proposal data */
ksm_proposal As (
  Select
    prospect_id
    , count(proposal_id) As open_proposals
    , sum(total_ask_amt) As total_asks
    , sum(total_anticipated_amt) As total_anticipated
    , sum(ksm_or_univ_ask) As total_ksm_asks
    , sum(ksm_or_univ_anticipated) As total_ksm_anticipated
    , min(proposal_id)
      keep(dense_rank First Order By hierarchy_order Desc, date_modified Desc, proposal_id Asc)
      As most_recent_proposal_id
    , min(proposal_manager)
      keep(dense_rank First Order By hierarchy_order Desc, date_modified Desc, proposal_id Asc)
      As recent_proposal_manager
    , min(proposal_assist)
      keep(dense_rank First Order By hierarchy_order Desc, date_modified Desc, proposal_id Asc)
      As recent_proposal_assist
    , min(proposal_status)
      keep(dense_rank First Order By hierarchy_order Desc, date_modified Desc, proposal_id Asc)
      As recent_proposal_status
    , min(start_date)
      keep(dense_rank First Order By hierarchy_order Desc, date_modified Desc, proposal_id Asc)
      As recent_start_date
    , min(ask_date)
      keep(dense_rank First Order By hierarchy_order Desc, date_modified Desc, proposal_id Asc)
      As recent_ask_date
    , min(close_date)
      keep(dense_rank First Order By hierarchy_order Desc, date_modified Desc, proposal_id Asc)
      As recent_close_date
    , min(date_modified)
      keep(dense_rank First Order By hierarchy_order Desc, date_modified Desc, proposal_id Asc)
      As recent_date_modified
    , min(ksm_or_univ_ask)
      keep(dense_rank First Order By hierarchy_order Desc, date_modified Desc, proposal_id Asc)
      As recent_ksm_ask
    , min(ksm_or_univ_anticipated)
      keep(dense_rank First Order By hierarchy_order Desc, date_modified Desc, proposal_id Asc)
      As recent_ksm_anticipated
  From v_ksm_proposal_history
  Where proposal_in_progress = 'Y'
    And ksm_proposal_ind = 'Y'
  Group By prospect_id
)

/* Contact data */
, recent_contact As (
  Select
    id_number
    -- Outreach in last 365 days
    , sum(Case When contact_date Between yesterday - 365 And yesterday Then 1 Else 0 End)
        As ard_contact_last_365_days
    -- Most recent contact report
    , min(credited_name) Keep(dense_rank First Order By contact_date Desc)
        As last_credited_name
    , min(employer_unit) Keep(dense_rank First Order By contact_date Desc)
        As last_credited_unit
    , min(contact_type) Keep(dense_rank First Order By contact_date Desc)
        As last_contact_type
    , min(contact_type_category) Keep(dense_rank First Order By contact_date Desc)
        As last_contact_category
    , min(contact_date) Keep(dense_rank First Order By contact_date Desc)
        As last_contact_date
    , min(contact_purpose) Keep(dense_rank First Order By contact_date Desc)
        As last_contact_purpose
    , min(description) Keep(dense_rank First Order By contact_date Desc)
        As last_contact_desc
  From v_ard_contact_reports
  Where contact_type <> 'Visit'
  Group By id_number
)
, recent_visit As (
  Select
    id_number
    -- Visits in last 365 days
    , sum(Case When contact_date Between yesterday - 365 And yesterday Then 1 Else 0 End)
        As ard_visit_last_365_days
    -- Most recent contact report
    , min(credited_name) Keep(dense_rank First Order By contact_date Desc, visit_type Asc)
        As last_visit_credited_name
    , min(employer_unit)  Keep(dense_rank First Order By contact_date Desc, visit_type Asc)
        As last_visit_credited_unit
    , min(contact_type) Keep(dense_rank First Order By contact_date Desc, visit_type Asc)
        As last_visit_contact_type
    , min(contact_type_category) Keep(dense_rank First Order By contact_date Desc, visit_type Asc)
        As last_visit_category
    , min(contact_date)  Keep(dense_rank First Order By contact_date Desc, visit_type Asc)
        As last_visit_date
    , min(contact_purpose) Keep(dense_rank First Order By contact_date Desc, visit_type Asc)
        As last_visit_purpose
    , min(visit_type)  Keep(dense_rank First Order By contact_date Desc, visit_type Asc)
        As last_visit_type
    , min(description) Keep(dense_rank First Order By contact_date Desc, visit_type Asc)
        As last_visit_desc
  From v_ard_contact_reports
  Where contact_type = 'Visit'
  Group By id_number
)

/* Main query */
Select
  prs.*
  -- Campaign giving fields
  , cmp.campaign_giving
  , cmp.campaign_steward_giving As campaign_giving_recognition
  -- Giving summary fields
  , gft.ngc_lifetime_full_rec As ksm_lifetime_recognition
  , gft.af_status
  , gft.af_cfy
  , gft.af_pfy1
  , gft.af_pfy2
  , gft.af_pfy3
  , gft.af_pfy4
  , gft.ngc_cfy
  , gft.ngc_pfy1
  , gft.ngc_pfy2
  , gft.ngc_pfy3
  , gft.ngc_pfy4
  -- Proposal history fields
  , ksm_proposal.open_proposals
  , ksm_proposal.total_asks
  , ksm_proposal.total_anticipated
  , ksm_proposal.total_ksm_asks
  , ksm_proposal.total_ksm_anticipated
  , ksm_proposal.most_recent_proposal_id
  , ksm_proposal.recent_proposal_manager
  , ksm_proposal.recent_proposal_assist
  , ksm_proposal.recent_proposal_status
  , ksm_proposal.recent_start_date
  , ksm_proposal.recent_ask_date
  , ksm_proposal.recent_close_date
  , ksm_proposal.recent_date_modified
  , ksm_proposal.recent_ksm_ask
  , ksm_proposal.recent_ksm_anticipated
  -- Recent contact data
  , recent_visit.ard_visit_last_365_days
  , recent_contact.ard_contact_last_365_days
  , recent_visit.last_visit_credited_name
  , recent_visit.last_visit_credited_unit
  , recent_visit.last_visit_contact_type
  , recent_visit.last_visit_category
  , recent_visit.last_visit_date
  , recent_visit.last_visit_purpose
  , recent_visit.last_visit_type
  , recent_visit.last_visit_desc
  , recent_contact.last_credited_name
  , recent_contact.last_credited_unit
  , recent_contact.last_contact_type
  , recent_contact.last_contact_category
  , recent_contact.last_contact_date
  , recent_contact.last_contact_purpose
  , recent_contact.last_contact_desc
  -- Current calendar
  , cal.yesterday
  , cal.curr_fy
From v_ksm_prospect_pool prs
Cross Join v_current_calendar cal
Left Join v_ksm_giving_summary gft On gft.id_number = prs.id_number
Left Join v_ksm_giving_campaign cmp On cmp.id_number = prs.id_number
Left Join ksm_proposal On ksm_proposal.prospect_id = prs.prospect_id
Left Join recent_contact On recent_contact.id_number = prs.id_number
Left Join recent_visit On recent_visit.id_number = prs.id_number;

/****************************************
Only vt_ksm_prs_pool rows where a KSM GO has been active
****************************************/

Create Or Replace View vt_ksm_prs_pool_gos As

/* Assigned v_ksm_prospect_pool joined with KSM current frontline staff activity
per prospect */

Select
  pool.*
  , mgo.gift_officer
  , mgo.assigned
  -- Only fill in metrics for the primary prospect
  , Case When pool.primary_ind = 'Y' Then mgo.visits_last_365_days End
      As visits_last_365_days
  , Case When pool.primary_ind = 'Y' Then mgo.quals_last_365_days End
      As quals_last_365_days
  , Case When pool.primary_ind = 'Y' Then mgo.visits_this_py End
      As visits_this_py
  , Case When pool.primary_ind = 'Y' Then mgo.quals_this_py End
      As quals_this_py
  , Case When pool.primary_ind = 'Y' Then mgo.total_open_proposals End
      As total_open_proposals
  , Case When pool.primary_ind = 'Y' Then mgo.total_open_asks End
      As total_open_asks
  , Case When pool.primary_ind = 'Y' Then mgo.total_open_ksm_asks End
      As total_open_ksm_asks
  , Case When pool.primary_ind = 'Y' Then mgo.total_cfy_ksm_ant_ask End
      As total_cfy_ksm_ant_ask
  , Case When pool.primary_ind = 'Y' Then mgo.total_cfy_ksm_verbal End
      As total_cfy_ksm_verbal
  , Case When pool.primary_ind = 'Y' Then mgo.total_cfy_ksm_funded End
      As total_cfy_ksm_funded
  , Case When pool.primary_ind = 'Y' Then mgo.total_cpy_ant_ask End
      As total_cpy_ant_ask
  , Case When pool.primary_ind = 'Y' Then mgo.total_cpy_verbal End
      As total_cpy_verbal
  , Case When pool.primary_ind = 'Y' Then mgo.total_cpy_funded End
      As total_cpy_funded
From vt_ksm_prs_pool pool
Inner Join v_ksm_mgo_own_activity_by_prs mgo On mgo.prospect_id = pool.prospect_id;

/****************************************
ARD prospect assignments and university strategy updates
****************************************/

Create Or Replace View vt_ard_prospect_timeline As

With
/* Prospect assignments and strategies over time */

-- PM assignments
assignments As (
  Select
    assignment.prospect_id
    , prospect_entity.id_number
    , entity.report_name
    , prospect_entity.primary_ind
    , 'Assignment' As type
    , assignment.assignment_id As id
    , assignment.start_date
    , assignment.stop_date
    , trunc(assignment.date_added) As date_added
    , trunc(assignment.date_modified) As date_modified
    , Case When assignment.active_ind = 'Y' Then 'Active' Else 'Inactive' End As status
    , assignment.assignment_id_number As owner_id
    , assignee.report_name As owner_report_name
    , assignment.xcomment As description
  From assignment
  Inner Join entity assignee On assignee.id_number = assignment.assignment_id_number
  Inner Join prospect_entity On prospect_entity.prospect_id = assignment.prospect_id
  Inner Join entity On entity.id_number = prospect_entity.id_number
  Where assignment_type In ('PP', 'PM', 'AF') -- Program Manager (PP), Prospect Manager (PM), Annual Fund Officer (AF)
)

-- University strategies
, strategies As (
  Select
    task.prospect_id
    , prospect_entity.id_number
    , entity.report_name
    , prospect_entity.primary_ind
    , 'Strategy' As type
    , task.task_id
    , task.sched_date
    , task.completed_date
    , trunc(task.date_added) As date_added
    , trunc(task.date_modified) As date_modified
    , tms_ts.short_desc As status
    , task.owner_id_number
    , owner.report_name As owner_report_name
    , task_description
  From task
  Inner Join tms_task_status tms_ts On tms_ts.task_status_code = task.task_status_code
  Inner Join prospect_entity On prospect_entity.prospect_id = task.prospect_id
  Inner Join entity On entity.id_number = prospect_entity.id_number
  Inner Join entity owner On owner.id_number = task.owner_id_number
  Where task_code = 'ST' -- University Overall Strategy
    And task.task_status_code <> 5 -- Not Cancelled (5) status
)

-- Main query
Select assignments.* From assignments
Union
Select strategies.* From strategies
;

/****************************************
Prospect activity "swim lanes"
****************************************/

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
    , 'Prospect' As color
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
  From vt_ard_prospect_timeline tl
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
