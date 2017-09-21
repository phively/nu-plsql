-- Linked gifts
With
link_plg As (
  Select *
  From primary_pledge
  Where proposal_id <> 0
),
link_gft As (
  Select *
  From primary_gift
  Where proposal_id <> 0
)

Select
  proposal.proposal_id,
  prospect_id,
  proposal.proposal_status_code,
  Case
    When proposal.proposal_status_code = 'B' Then 'Submitted' -- Letter of Inquiry Submitted
    Else tms_ps.short_desc
  End As proposal_status,
  start_date,
  stop_date,
  original_ask_amt,
  ask_amt,
  anticipated_amt,
  granted_amt
From proposal
Inner Join tms_proposal_status tms_ps On tms_ps.proposal_status_code = proposal.proposal_status_code
Inner Join (Select proposal_id From proposal_purpose Where program_code = 'KM') purp On purp.proposal_id = proposal.proposal_id
