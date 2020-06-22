DROP VIEW rpt_abm1914.ksm_prs_pool;
Create Or Replace View rpt_abm1914.ksm_prs_pool As

With

/* v_ksm_prospect_pool with a few giving-related fields appended
   Also includes strategy and current proposals
   Fairly slow to refresh due to multiple views */

/* Geocoded data */
geocode As (
  Select *
  From rpt_pbh634.v_addr_geocoding
)

/* Proposal data */
, nu_proposal As (
  Select
    prospect_id
    , count(proposal_id) As open_proposals
  From rpt_pbh634.v_proposal_history_fast
  Where proposal_active_calc = 'Active'
  Group By prospect_id
)
, ksm_proposal As (
  Select
    prospect_id
    , count(proposal_id) As open_ksm_proposals
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
    , min(proposal_id)
      keep(dense_rank First Order By close_date Asc, hierarchy_order Desc, date_modified Desc, proposal_id Asc)
      As next_proposal_id
    , min(proposal_manager)
      keep(dense_rank First Order By close_date Asc, hierarchy_order Desc, date_modified Desc, proposal_id Asc)
      As next_proposal_manager
    , min(close_date)
      keep(dense_rank First Order By close_date Asc, hierarchy_order Desc, date_modified Desc, proposal_id Asc)
      As next_close_date
    , min(ksm_or_univ_ask)
      keep(dense_rank First Order By close_date Asc, hierarchy_order Desc, date_modified Desc, proposal_id Asc)
      As next_ksm_ask
    , min(ksm_or_univ_anticipated)
      keep(dense_rank First Order By close_date Asc, hierarchy_order Desc, date_modified Desc, proposal_id Asc)
      As next_ksm_anticipated
  From rpt_pbh634.v_proposal_history_fast
  Where proposal_in_progress = 'Y'
    And ksm_proposal_ind = 'Y'
  Group By prospect_id
)

/* Assignment IDs */
, assign As (
  Select Distinct
    ah.prospect_id
    , ah.id_number
    , ah.assignment_id_number
    , ah.assignment_report_name
  From rpt_pbh634.v_assignment_history ah
  Where ah.assignment_active_calc = 'Active' -- Active assignments only
    And assignment_type In
      -- Program Manager (PP), Prospect Manager (PM), Leadership Giving Officer (LG)
      -- Annual Fund Officer (AF) is defunct as of 2020-04-14; removed
      ('PP', 'PM', 'LG')
    And ah.assignment_report_name Is Not Null -- Real managers only
)

/* Contact data */
, ard_contacts As (
  Select
    vcrf.credited
    , vcrf.credited_name
    , vcrf.contact_credit_type
    , vcrf.contact_credit_desc
    , vcrf.job_title
    , vcrf.employer_unit
    , vcrf.contact_type_code
    , vcrf.contact_type
    , vcrf.contact_purpose
    , vcrf.report_id
    , vcrf.id_number
    , vcrf.contacted_name
    , vcrf.report_name
    , vcrf.prospect_id
    , vcrf.primary_ind
    , vcrf.prospect_name
    , vcrf.prospect_name_sort
    , vcrf.contact_date
    , vcrf.fiscal_year
    , vcrf.description
    , vcrf.summary
    , vcrf.officer_rating
    , vcrf.evaluation_rating
    , vcrf.university_strategy
    , vcrf.ard_staff
    , vcrf.frontline_ksm_staff
    , vcrf.contact_type_category
    , vcrf.visit_type
    , vcrf.rating_bin
    , vcrf.curr_fy
    , vcrf.prev_fy_start
    , vcrf.curr_fy_start
    , vcrf.next_fy_start
    , vcrf.yesterday
    , vcrf.ninety_days_ago
  From rpt_pbh634.v_contact_reports_fast vcrf
  Where ard_staff = 'Y'
)
, recent_contact As (
  Select
    id_number
    -- Outreach in last 365 days
    , sum(Case When contact_date Between yesterday - 365 And yesterday Then 1 Else 0 End)
        As ard_contact_last_365_days
    -- Outreach in last 3 years (amy) 
    , SUM(CASE WHEN CONTACT_DATE BETWEEN yesterday-1095 AND yesterday THEN 1 else 0 END)
        AS ard_contact_last_3_yrs
    -- Most recent contact report
    , min(credited_name) Keep(dense_rank First Order By contact_date Desc)
        As last_credited_name
    , min(employer_unit) Keep(dense_rank First Order By contact_date Desc)
        As last_credited_unit
    , min(frontline_ksm_staff) Keep(dense_rank First Order By contact_date Desc)
        As last_credited_ksm
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
  From ard_contacts
  Where contact_type <> 'Visit'
  Group By id_number
)
, recent_assn_contacts As (
  Select
    ac.id_number
    -- Most recent contact report from an assigned manager
    , min(credited_name) Keep(dense_rank First Order By contact_date Desc)
        As last_assigned_credited_name
    , min(employer_unit) Keep(dense_rank First Order By contact_date Desc)
        As last_assigned_credited_unit
    , min(frontline_ksm_staff) Keep(dense_rank First Order By contact_date Desc)
        As last_assigned_credited_ksm
    , min(contact_type) Keep(dense_rank First Order By contact_date Desc)
        As last_assigned_contact_type
    , min(contact_type_category) Keep(dense_rank First Order By contact_date Desc)
        As last_assigned_contact_category
    , min(contact_date) Keep(dense_rank First Order By contact_date Desc)
        As last_assigned_contact_date
    , min(contact_purpose) Keep(dense_rank First Order By contact_date Desc)
        As last_assigned_contact_purpose
    , min(description) Keep(dense_rank First Order By contact_date Desc)
        As last_assigned_contact_desc
  From ard_contacts ac
  Inner Join assign
    On assign.id_number = ac.id_number
    And assign.assignment_id_number = ac.credited
  Where contact_type <> 'Visit'
    And assign.assignment_id_number Is Not Null
  Group By ac.id_number       
)
, recent_visit As (
  Select
    id_number
    -- Visits in last 365 days
    , sum(Case When contact_date Between yesterday - 365 And yesterday Then 1 Else 0 End)
        As ard_visit_last_365_days
    -- VIsits in last 3 years (AMY)
    , SUM(CASE WHEN contact_date BETWEEN yesterday - 1095 AND Yesterday then 1 else 0 END)
        AS ard_visit_last_3_yrs
    -- Most recent contact report
    , min(credited_name) Keep(dense_rank First Order By contact_date Desc, visit_type Asc)
        As last_visit_credited_name
    , min(frontline_ksm_staff) Keep(dense_rank First Order By contact_date Desc)
        As last_visit_credited_ksm
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
  From ard_contacts
  Where contact_type = 'Visit'
  Group By id_number
)

/* Tasks from the current and previous FY (v_ksm_tasks) */
, tasks As (
  Select
    prospect_id
    -- Count of open tasks
    , count(Distinct task_id)
      As tasks_open
    -- Count of open tasks where responsible entity is a KSM GO
    , count(Distinct Case When current_mgo_ind = 'Y' Then task_id Else NULL End)
      As tasks_open_ksm
  From rpt_pbh634.v_ksm_tasks
  Where task_code <> 'ST' -- Exclude university overall strategy
    And active_task_ind = 'Y'
  Group By
    prospect_id
)
, next_outreach_task As (
  Select
    prospect_id
    -- Count of KSM GO outreach tasks
    , count(Distinct task_id)
      As tasks_open_ksm_outreach
    -- Next KSM GO outreach task
    , min(task_id) keep(dense_rank First Order By sched_date Asc, task_id Asc, task_responsible Asc)
      As task_outreach_next_id
    , min(sched_date) keep(dense_rank First Order By sched_date Asc, task_id Asc, task_responsible Asc)
      As task_outreach_sched_date
    , min(task_responsible) keep(dense_rank First Order By sched_date Asc, task_id Asc, task_responsible Asc)
      As task_outreach_responsible
    , min(task_description) keep(dense_rank First Order By sched_date Asc, task_id Asc, task_responsible Asc)
      As task_outreach_desc
  From rpt_pbh634.v_ksm_tasks
  Where task_code = 'CO'
    And active_task_ind = 'Y'
    And current_mgo_ind = 'Y'
  Group By
    prospect_id
)

-- Intermediate joins

, pp As (
  Select *
  From rpt_pbh634.v_ksm_prospect_pool
)

, prs As (
  Select
    pp.*
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
    , gft.last_gift_tx_number
    , gft.last_gift_date
    , gft.last_gift_type
    , gft.last_gift_recognition_credit
  From pp
  Left Join rpt_pbh634.v_ksm_giving_summary gft On gft.id_number = pp.id_number
  Left Join rpt_pbh634.v_ksm_giving_campaign cmp On cmp.id_number = pp.id_number
)

, visits As (
  Select
    pp.id_number
    -- Recent contact data
    , recent_visit.ard_visit_last_365_days
    , recent_visit.ard_visit_last_3_yrs -- Added by Amy
    , recent_contact.ard_contact_last_365_days
    , recent_contact.ard_contact_last_3_yrs -- Added by Amy
    , recent_visit.last_visit_credited_name
    , recent_visit.last_visit_credited_unit
    , recent_visit.last_visit_credited_ksm
    , recent_visit.last_visit_contact_type
    , recent_visit.last_visit_category
    , recent_visit.last_visit_date
    , recent_visit.last_visit_purpose
    , recent_visit.last_visit_type
    , recent_visit.last_visit_desc
    , recent_contact.last_credited_name
    , recent_contact.last_credited_unit
    , recent_contact.last_credited_ksm
    , recent_contact.last_contact_type
    , recent_contact.last_contact_category
    , recent_contact.last_contact_date
    , recent_contact.last_contact_purpose
    , recent_contact.last_contact_desc
    , recent_assn_contacts.last_assigned_credited_name
    , recent_assn_contacts.last_assigned_credited_unit
    , recent_assn_contacts.last_assigned_credited_ksm
    , recent_assn_contacts.last_assigned_contact_type
    , recent_assn_contacts.last_assigned_contact_category
    , recent_assn_contacts.last_assigned_contact_date
    , recent_assn_contacts.last_assigned_contact_purpose
    , recent_assn_contacts.last_assigned_contact_desc
  From pp
  Left Join recent_contact On recent_contact.id_number = pp.id_number
  Left Join recent_assn_contacts On recent_assn_contacts.id_number = pp.id_number
  Left Join recent_visit On recent_visit.id_number = pp.id_number
)

/* Main query */
Select Distinct
  prs.*
  -- Latitude/longitude
  , geocode.latitude
  , geocode.longitude
  -- Proposal history fields
  , nu_proposal.open_proposals
  , ksm_proposal.open_ksm_proposals
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
  , ksm_proposal.next_proposal_id
  , ksm_proposal.next_proposal_manager
  , ksm_proposal.next_close_date
  , ksm_proposal.next_ksm_ask
  , ksm_proposal.next_ksm_anticipated
  -- Recent contact data
  , visits.ard_visit_last_365_days
  , visits.ard_visit_last_3_yrs -- added by Amy
  , visits.ard_contact_last_365_days
  , visits.ard_contact_last_3_yrs -- added by Amy
  , visits.last_visit_credited_name
  , visits.last_visit_credited_unit
  , visits.last_visit_credited_ksm
  , visits.last_visit_contact_type
  , visits.last_visit_category
  , visits.last_visit_date
  , visits.last_visit_purpose
  , visits.last_visit_type
  , visits.last_visit_desc
  , visits.last_credited_name
  , visits.last_credited_unit
  , visits.last_credited_ksm
  , visits.last_contact_type
  , visits.last_contact_category
  , visits.last_contact_date
  , visits.last_contact_purpose
  , visits.last_contact_desc
  , visits.last_assigned_credited_name
  , visits.last_assigned_credited_unit
  , visits.last_assigned_credited_ksm
  , visits.last_assigned_contact_type
  , visits.last_assigned_contact_category
  , visits.last_assigned_contact_date
  , visits.last_assigned_contact_purpose
  , visits.last_assigned_contact_desc
  -- Tasks data
  , tasks.tasks_open
  , tasks.tasks_open_ksm
  , next_outreach_task.tasks_open_ksm_outreach
  , next_outreach_task.task_outreach_next_id
  , next_outreach_task.task_outreach_sched_date
  , next_outreach_task.task_outreach_responsible
  , next_outreach_task.task_outreach_desc
  -- Current calendar
  , cal.yesterday
  , cal.curr_fy
From prs
Cross Join rpt_pbh634.v_current_calendar cal
Inner Join visits On visits.id_number = prs.id_number
Left Join geocode On geocode.id_number = prs.id_number
  And geocode.xsequence = prs.xsequence
Left Join nu_proposal On nu_proposal.prospect_id = prs.prospect_id
Left Join ksm_proposal On ksm_proposal.prospect_id = prs.prospect_id
Left Join tasks On tasks.prospect_id = prs.prospect_id
Left Join next_outreach_task On next_outreach_task.prospect_id = prs.prospect_id
;
