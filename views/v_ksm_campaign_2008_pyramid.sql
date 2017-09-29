Create Or Replace View v_ksm_campaign_2008_pyramid As

With

-- Current calendar
cal As (
  Select *
  From rpt_pbh634.v_current_calendar
),

-- Campaign goals
goals As (
  Select NULL As giving_level, NULL As dollars, NULL as donors From DUAL Where Null Is Not Null -- Column labels
  Union All Select  10, 140000000, 10 From DUAL
  Union All Select   5,  80000000, 15 From DUAL
  Union All Select   2,  60000000, 20 From DUAL
  Union All Select   1,  60000000, 50 From DUAL
  Union All Select 0.5,  40000000, 50 From DUAL
  Union All Select 0.1,  60000000, 300 From DUAL
  Union All Select   0,  60000000, NULL From DUAL
),

-- Campaign fundraising progress
giving As (
  Select household_id,
    sum(amount) As amount,
    Case -- Giving levels
      When sum(amount) >= 10000000 Then 10
      When sum(amount) >=  5000000 Then 5
      When sum(amount) >=  2000000 Then 2
      When sum(amount) >=  1000000 Then 1
      When sum(amount) >=   500000 Then 0.5
      When sum(amount) >=   100000 Then 0.1
      Else 0
    End As giving_level
  From v_ksm_campaign_2008_gifts
  Group By household_id
),
gave As (
  Select giving_level, sum(amount) As dollars, count(household_id) As donors, cal.curr_fy
  From giving
  Cross Join cal
  Group By giving_level, curr_fy
),

-- Open proposals from existing major giving view
all_props As (
  Select bin As giving_level, amount, 1 As nbr, cat
  From v_ksm_mg_fy_metrics
  Where src = 'Proposals'
),
proposals As (
  Select giving_level, sum(amount) As dollars, sum(nbr) As gifts, cat As src, cal.curr_fy
  From all_props
  Cross Join cal
  Group By giving_level, cat, curr_fy
)

-- Planned proposals from Top 500 coding

-- Main query
(
  -- Booked gifts
  Select giving_level, dollars, donors, NULL as gifts, 'Campaign Booked' As src, curr_fy
  From gave
) Union All (
  -- Campaign goals
  Select giving_level, dollars, donors, NULL, 'Goal' As src, cal.curr_fy
  From goals
  Cross Join cal
) Union All (
  -- Remainder
  Select gave.giving_level, goals.dollars - gave.dollars, goals.donors - gave.donors, goals.donors - gave.donors, 'Remainder' As src, curr_fy
  From gave
  Inner Join goals On goals.giving_level = gave.giving_level
) Union All (
  -- Proposals
  Select giving_level, dollars, NULL as donors, gifts, src, curr_fy
  From proposals
)
-- Add in planned proposals when done
