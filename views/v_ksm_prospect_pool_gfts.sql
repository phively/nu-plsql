Create Or Replace View v_ksm_prospect_pool_gfts As

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
From v_ksm_prospect_pool prs
Left Join v_ksm_giving_summary gft On gft.id_number = prs.id_number
Left Join v_ksm_giving_campaign cmp On cmp.id_number = prs.id_number
Left Join ksm_proposal On ksm_proposal.prospect_id = prs.prospect_id
Left Join recent_contact On recent_contact.id_number = prs.id_number
Left Join recent_visit On recent_visit.id_number = prs.id_number
