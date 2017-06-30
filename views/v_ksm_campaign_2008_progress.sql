Create Or Replace View v_ksm_campaign_2008_progress As

With

/* Calendar objects */
cal As (
  Select yesterday
  From v_current_calendar
),

/* Pull campaign transactions */
campaign As (
  Select rcpt_or_plg_number, amount, 'Raised' As field,
    -- Campaign category grouper
    Case
      When ksm_campaign_category Like 'Education%' Then 'Educational Mission'
      When ksm_campaign_category Like 'Global Innovation%' Then 'Global Innovation'
      Else ksm_campaign_category
    End As priority
  From v_ksm_campaign_2008_gifts
  Where amount > 0
),

/* Campaign goals */
goals As (
  (
  Select 'Educational Mission' As priority, 'Goal' As field,
    60000000 As amount
  From DUAL
  ) Union All (
  Select 'Global Innovation', 'Goal',
    30000000
  From DUAL
  ) Union All (
  Select 'Global Hub', 'Goal',
    220000000
  From DUAL
  ) Union All (
  Select 'Thought Leadership', 'Goal',
    40000000
  From DUAL
  )
)

/* Summed and binned results */
(
-- Raised to date
Select campaign.priority, campaign.field, sum(campaign.amount) As amount, sum(campaign.amount) As overall,
  goals.amount As goal_amt, yesterday
From campaign
Cross Join cal
Inner Join goals On campaign.priority = goals.priority
Group By campaign.priority, campaign.field, goals.amount, yesterday
) Union All (
-- Goals
Select priority, field, amount, NULL, NULL, yesterday
From goals, cal
)
