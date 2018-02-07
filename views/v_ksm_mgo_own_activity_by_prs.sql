Create Or Replace View v_ksm_mgo_own_activity_by_prs As

With

-- KSM active staff table
ksm_staff As (
  Select
    id_number
    , report_name
    , last_name
  From table(ksm_pkg.tbl_frontline_ksm_staff)
  Where former_staff Is Null
  Order By report_name Asc
)

-- Count of own visits in last 365 days
, ksm_visits As (
  Select
    last_name
    , v.credited
    , v.prospect_id
    , sum(Case When v.contact_date Between yesterday - 365 And yesterday Then 1 Else 0 End)
        As visits_last_365_days
    , sum(Case When v.contact_date Between yesterday - 365 And yesterday
        And v.visit_type = 'Qualification' Then 1 Else 0 End)
        As quals_last_365_days
  From ksm_staff
  Inner Join v_ksm_visits v On v.credited = ksm_staff.id_number
  Cross Join v_current_calendar
  Group By
    last_name
    , v.credited
    , v.prospect_id
)

-- Total value of own solicitations
, ksm_sols As (
  Select
    last_name
    , p.proposal_manager_id
    , p.prospect_id
    , count(Distinct (Case When p.proposal_in_progress = 'Y' Then p.proposal_id Else Null End))
        As total_open_proposals
    , sum(Case When p.proposal_in_progress = 'Y' Then total_ask_amt Else 0 End)
        As total_open_asks
    , sum(Case When p.proposal_in_progress = 'Y' Then ksm_or_univ_ask Else 0 End)
        As total_open_ksm_asks
    -- Current fiscal year amounts
    , sum(Case When close_fy = cal.curr_fy And p.proposal_in_progress = 'Y' And p.proposal_status_code <> '5' -- Approved by Donor
        Then ksm_or_univ_ask Else 0 End)
        As total_cfy_ksm_ant_ask
    , sum(Case When close_fy = cal.curr_fy And p.proposal_status_code = '5' -- Approved by Donor
        Then final_anticipated_or_ask_amt Else 0 End)
        As total_cfy_ksm_verbal
    , sum(Case When close_fy = cal.curr_fy And p.ksm_linked_amounts > 0 Then p.ksm_linked_amounts Else 0 End)
        As total_cfy_ksm_funded
    -- Current performance year amounts
    , sum(Case When close_date Between cal.curr_py_start And cal.next_py_start - 1 And p.proposal_in_progress = 'Y' And proposal_status_code <> '5'
        Then total_ask_amt Else 0 End)
        As total_cpy_ant_ask
    , sum(Case When close_date Between cal.curr_py_start And cal.next_py_start - 1 And proposal_status_code = '5'
        Then total_anticipated_amt Else 0 End)
        As total_cpy_verbal
    , sum(Case When close_date Between cal.curr_py_start And cal.next_py_start - 1 And p.nu_linked_amounts > 0 Then p.nu_linked_amounts Else 0 End)
        As total_cpy_funded
  From ksm_staff
  Inner Join v_ksm_proposal_history p On p.proposal_manager_id = ksm_staff.id_number
  Cross Join v_current_calendar cal
  Group By
    last_name
    , p.proposal_manager_id
    , p.prospect_id
)

-- Own prospect pool
, own_pool As (
  Select Distinct
    last_name
    , assignment_id_number
    , assignment.prospect_id
    , 'Y' As assigned
  From assignment
  Inner Join ksm_staff On ksm_staff.id_number = assignment.assignment_id_number
  Inner Join prospect_entity On prospect_entity.prospect_id = assignment.prospect_id
  Inner Join prospect On prospect.prospect_id = assignment.prospect_id
  Where assignment.active_ind = 'Y' -- Active assignments only
    And assignment_type In ('PP', 'PM', 'AF') -- Program Manager (PP), Prospect Manager (PM), Annual Fund Officer (AF)
    And prospect.active_ind = 'Y' -- Active prospects only
)

-- Full list deduped
, prs As (
  Select prospect_id, last_name From ksm_visits
  Union
  Select prospect_id, last_name From ksm_sols
  Union
  Select prospect_id, last_name From own_pool
)

-- Main query
Select
  prs.prospect_id
  , prs.last_name
  , op.assigned
  , vs.visits_last_365_days
  , vs.quals_last_365_days
  , sol.total_open_proposals
  , sol.total_open_asks
  , sol.total_open_ksm_asks
  , sol.total_cfy_ksm_ant_ask
  , sol.total_cfy_ksm_verbal
  , sol.total_cfy_ksm_funded
  , sol.total_cpy_ant_ask
  , sol.total_cpy_verbal
  , sol.total_cpy_funded
From prs
Left Join ksm_visits vs On prs.prospect_id = vs.prospect_id And prs.last_name = vs.last_name
Left Join ksm_sols sol On prs.prospect_id = sol.prospect_id And prs.last_name = sol.last_name
Left Join own_pool op On prs.prospect_id = op.prospect_id And prs.last_name = op.last_name
