Create Or Replace View v_ksm_proposal_history As

With

-- Gifts with linked proposals
linked As (
  Select proposal_id,
    Listagg(tx_number, '; ') Within Group (Order By tx_number Asc) As linked_receipts,
    sum(legal_amount) As linked_amounts
  From v_ksm_giving_trans
  Where proposal_id Is Not Null
    And legal_amount > 0
  Group By proposal_id
),

-- Current calendar
cal As (
  Select *
  From table(rpt_pbh634.ksm_pkg.tbl_current_calendar)
),

-- Proposal purpose
purp As (
  Select pp.proposal_id,
    Listagg(tms_pp.short_desc, '; ') Within Group (Order By pp.xsequence Asc) As prop_purpose,
    Listagg(tms_pi.short_desc, '; ') Within Group (Order By pp.xsequence Asc) prospect_interest,
    sum(pp.ask_amt) As program_ask,
    sum(pp.original_ask_amt) As program_orig_ask,
    sum(pp.granted_amt) As program_anticipated
  From proposal_purpose pp
  Left Join tms_prop_purpose tms_pp On tms_pp.prop_purpose_code = pp.prop_purpose_code
  Left Join tms_prospect_interest tms_pi On tms_pi.prospect_interest_code = pp.prospect_interest_code
  Where program_code = 'KM'
  Group By pp.proposal_id
),

-- Proposal assignments
assn As (
  Select assignment.proposal_id,
    Listagg(entity.report_name, '; ') Within Group (Order By assignment.start_date Desc NULLS Last, assignment.date_modified Desc) As proposal_manager
  From assignment
  Inner Join purp On purp.proposal_id = assignment.proposal_id
  Inner Join entity On entity.id_number = assignment.assignment_id_number
  Where assignment.assignment_type = 'PA' -- Proposal Manager (PM is taken by Prospect Manager)
  Group By assignment.proposal_id
)

-- Main query
Select
  proposal.prospect_id,
  prs.prospect_name,
  proposal.proposal_id,
  assn.proposal_manager,
  proposal.proposal_status_code,
  tms_ps.hierarchy_order,
  Case
    When proposal.proposal_status_code = 'B' Then 'Submitted' -- Letter of Inquiry Submitted
    When proposal.proposal_status_code = '5' Then 'Verbal' -- Approved by Donor
    Else tms_ps.short_desc
  End As proposal_status,
  Case When tms_ps.hierarchy_order < 70 Then 'Y' End As proposal_active,
  Case When proposal.proposal_status_code In ('A', 'B', 'C', '5') Then 'Y' End As proposal_in_progress, -- Anticipated, Submitted, Submitted, Verbal
  purp.prop_purpose,
  purp.prospect_interest,
  trunc(start_date) As start_date,
  ksm_pkg.get_fiscal_year(start_date) As start_fy,
  trunc(initial_contribution_date) As ask_date,
  ksm_pkg.get_fiscal_year(initial_contribution_date) As ask_fy,
  trunc(stop_date) As close_date,
  ksm_pkg.get_fiscal_year(stop_date) As close_fy,
  trunc(date_modified) As date_modified,
  linked.linked_receipts,
  linked.linked_amounts,
  original_ask_amt,
  ask_amt,
  anticipated_amt,
  purp.program_ask,
  purp.program_anticipated,
  granted_amt,
  -- Use anticipated amount if available, else ask amount
  Case When anticipated_amt > 0 Then anticipated_amt Else ask_amt End As amt,
  -- Anticipated bin: use anticipated amount if available, otherwise fall back to ask amount
  Case
    When anticipated_amt >= 10000000 Then 10
    When anticipated_amt >=  5000000 Then 5
    When anticipated_amt >=  2000000 Then 2
    When anticipated_amt >=  1000000 Then 1
    When anticipated_amt >=   500000 Then 0.5
    When anticipated_amt >=   100000 Then 0.1
    When anticipated_amt >         0 Then 0 -- Not an error, should be > not >= so we keep going if anticipated is 0
    When ask_amt         >= 10000000 Then 10
    When ask_amt         >=  5000000 Then 5
    When ask_amt         >=  2000000 Then 2
    When ask_amt         >=  1000000 Then 1
    When ask_amt         >=   500000 Then 0.5
    When ask_amt         >=   100000 Then 0.1
    Else 0
  End As bin
From proposal
Cross Join cal
Inner Join tms_proposal_status tms_ps On tms_ps.proposal_status_code = proposal.proposal_status_code
-- Only KSM proposals
Inner Join purp On purp.proposal_id = proposal.proposal_id
Left Join assn On assn.proposal_id = proposal.proposal_id
-- Prospect info
Left Join (Select prospect_id, prospect_name From prospect) prs On prs.prospect_id = proposal.prospect_id
-- Linked gift info
Left Join linked On linked.proposal_id = proposal.proposal_id
