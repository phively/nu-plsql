Create Or Replace View v_ksm_proposal_history As

-- Gifts with linked proposals
With
linked As (
  Select proposal_id,
    Listagg(tx_number, ', ') Within Group (Order By tx_number Asc) As linked_receipts,
    sum(legal_amount) As linked_amounts
  From v_ksm_giving_trans
  Where proposal_id Is Not Null
    And legal_amount > 0
  Group By proposal_id
)

Select
  proposal.proposal_id,
  proposal.prospect_id,
  prs.pref_mail_name,
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
  Case
    When anticipated_amt >= 10000000 Then 10
    When anticipated_amt >=  5000000 Then 5
    When anticipated_amt >=  2000000 Then 2
    When anticipated_amt >=  1000000 Then 1
    When anticipated_amt >=   500000 Then 0.5
    When anticipated_amt >=   100000 Then 0.1
    Else 0
  End As anticipated_bin
From proposal
Inner Join tms_proposal_status tms_ps On tms_ps.proposal_status_code = proposal.proposal_status_code
-- Only KSM proposals
Inner Join (Select proposal_id From proposal_purpose Where program_code = 'KM') purp On purp.proposal_id = proposal.proposal_id
-- Prospect info
Left Join nu_prs_trp_prospect prs On prs.prospect_id = proposal.prospect_id
-- Linked gift info
Left Join linked On linked.proposal_id = proposal.proposal_id
