Create Or Replace View v_ksm_mg_fy_metrics As

With
cal As (
  Select *
  From rpt_pbh634.v_current_calendar
)

/* Proposal status and year-to-date new gifts and commitments for KSM MG metrics */
(
  -- Gift data
  Select amount, to_number(year_of_giving) As fiscal_year, cal.curr_fy, ytd_ind,
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
  From v_ksm_giving_campaign_ytd
  Cross Join cal
  Where year_of_giving Between 2007 And 2020 -- FY 2007 and 2020 as first and last campaign gift dates
    And amount > 0
) Union All (
  -- Proposal data
  Select amt, cal.curr_fy As fiscal_year, cal.curr_fy, 'Y',
    bin, proposal_status As cat, 'Proposals' As src
  From rpt_pbh634.v_ksm_proposal_history
  Cross Join cal
  Where proposal_in_progress = 'Y'
)
