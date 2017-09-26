Create Or Replace View v_ksm_mg_fy_metrics As

With
cal As (
  Select *
  From rpt_pbh634.v_current_calendar
)

/* Proposal status and year-to-date new gifts and commitments for KSM MG metrics */
(
  -- Gift data
  Select amount, to_number(year_of_giving) As fiscal_year, cal.curr_fy,
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
  From v_ksm_giving_campaign_trans
  Cross Join cal
  Where year_of_giving Between cal.curr_fy - 1 And cal.curr_fy
    And amount > 0
) Union All (
  -- Proposal data
  Select amt, cal.curr_fy As fiscal_year, cal.curr_fy,
    bin, proposal_status As cat, 'Proposals' As src
  From rpt_pbh634.v_ksm_proposal_history
  Cross Join cal
  Where proposal_in_progress = 'Y'
)
  -- Fake data to make sure all bins are represented
  Union All Select NULL, NULL, cal.curr_fy, 0, NULL, 'Spacer' From DUAL Cross Join cal
  Union All Select NULL, NULL, cal.curr_fy, 0.1, NULL, 'Spacer' From DUAL Cross Join cal
  Union All Select NULL, NULL, cal.curr_fy, 0.5, NULL, 'Spacer' From DUAL Cross Join cal
  Union All Select NULL, NULL, cal.curr_fy, 1, NULL, 'Spacer' From DUAL Cross Join cal
  Union All Select NULL, NULL, cal.curr_fy, 2, NULL, 'Spacer' From DUAL Cross Join cal
  Union All Select NULL, NULL, cal.curr_fy, 5, NULL, 'Spacer' From DUAL Cross Join cal
  Union All Select NULL, NULL, cal.curr_fy, 10, NULL, 'Spacer' From DUAL Cross Join cal
