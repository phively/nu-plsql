-- Gifts with linked proposals
With
linked As (
  Select proposal_id,
    Listagg(tx_number, ', ') Within Group (Order By tx_number Asc) As linked_receipts,
    sum(credit_amount) As linked_amounts
  From v_ksm_giving_trans
  Where proposal_id Is Not Null
  Group By proposal_id
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
  linked.linked_receipts,
  linked.linked_amounts,
  original_ask_amt,
  ask_amt,
  anticipated_amt,
  granted_amt,
From proposal
Inner Join tms_proposal_status tms_ps On tms_ps.proposal_status_code = proposal.proposal_status_code
-- Only KSM proposals
Inner Join (Select proposal_id From proposal_purpose Where program_code = 'KM') purp On purp.proposal_id = proposal.proposal_id
-- Linked gift info
Left Join linked On linked.proposal_id = proposal.proposal_id
