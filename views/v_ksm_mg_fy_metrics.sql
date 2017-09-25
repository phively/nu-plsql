Create Or Replace View v_ksm_mg_fy_metrics As

/* Visits, proposal status, and year-to-date new gifts and commitments for KSM MG metrics */

(
  -- Visit data
  Select 0 As amt, 1 As count, fiscal_year, rating_bin As bin, visit_type As cat,'visit' As src
  From rpt_pbh634.v_ksm_visits
) Union All (
  -- Proposal data
  Select anticipated_amt, 1 As count, cal.curr_fy As fiscal_year, anticipated_bin, proposal_status As cat, 'proposal' As src
  From rpt_pbh634.v_ksm_proposal_history
  Cross Join rpt_pbh634.v_current_calendar cal
  Where proposal_status_code In ('5', 'A', 'B', 'C') -- Only active proposals
) Union All (
  -- Gift data
  Select amount, 1 As count, to_number(year_of_giving) As fiscal_year,
    Case
      When amount >= 10000000 Then 10
      When amount >=  5000000 Then 5
      When amount >=  2000000 Then 2
      When amount >=  1000000 Then 1
      When amount >=   500000 Then 0.5
      When amount >=   100000 Then 0.1
      Else 0
    End As bin,
    'Campaign Giving' As cat, 'giving' As src
  From v_ksm_giving_campaign_trans
  Cross Join v_current_calendar cal
  Where year_of_giving Between cal.curr_fy - 1 And cal.curr_fy
    And amount > 0
)
