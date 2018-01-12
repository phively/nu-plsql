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
From v_ksm_prospect_pool prs
Left Join v_ksm_giving_summary gft On gft.id_number = prs.id_number
Left Join v_ksm_giving_campaign cmp On cmp.id_number = prs.id_number
Left Join ksm_proposal On ksm_proposal.prospect_id = prs.prospect_id
