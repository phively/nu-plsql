Create Or Replace View tableau_retention_expendable_cash As

With

hhf As (
  Select
    hh.household_id
    , hh.donor_id
    , hh.full_name
    , hh.sort_name
    , deg.degrees_concat
    , hh.household_primary
    , hh.household_suffix
    , hh.household_first_ksm_year
    , hh.household_program_group
  From mv_households hh
  Left Join mv_entity_ksm_degrees deg
    On deg.donor_id = hh.donor_id
)

, fy_totals As (
  Select
    nvl(hhf.household_id, 'NA')
      As household_id
    , cash.fiscal_year
    , max(cash.credit_date)
      As max_gift_dt
    , sum(nvl(cash.cash_countable_amount, 0))
      As total_countable_amount
    ,  max(Case When cash.fytd_indicator = 'Y' Then cash.credit_date End)
      As ytd_max_gift_dt
    , sum(Case When cash.fytd_indicator = 'Y' Then cash.cash_countable_amount Else 0 End)
      As ytd_countable_amount
  From v_ksm_gifts_cash cash
  Left Join hhf
    On hhf.donor_id = cash.source_donor_id
  Where cash.cash_category = 'Expendable'
  Group By
    hhf.household_id
    , cash.fiscal_year
)

, multiyear As (
  Select
    nvl(hhf.household_id, 'NA')
      As household_id
    , hhf.donor_id
    , hhf.full_name
    , hhf.sort_name
    , hhf.degrees_concat
    , fyt.fiscal_year
      As fiscal_year
    , fyt.max_gift_dt
      As cfy_max_gift_dt
    , ng.max_gift_dt
      As nfy_next_gift_dt
    , ng2.max_gift_dt
      As nfy2_next_gift_dt
    , pg.total_countable_amount
      As pfy_total_countable_amount
    , fyt.total_countable_amount
      As cfy_total_countable_amount
    , ng.total_countable_amount
      As nfy_total_countable_amount
    , ng2.total_countable_amount
      As nfy2_total_countable_amount
    , fyt.ytd_countable_amount
      As cfy_ytd_countable_amount
    , fyt.ytd_max_gift_dt
      As cfy_ytd_max_gift_dt
    , ng.ytd_countable_amount
      As nfy_ytd_countable_amount
    , ng.ytd_max_gift_dt
      As nfy_ytd_max_gift_dt
    , cal.curr_fy
  From fy_totals fyt
  Cross Join v_current_calendar cal
  Left Join hhf
    On hhf.household_id = fyt.household_id
    And hhf.household_primary = 'Y'
  -- Check if gift made previous year
  Left Join fy_totals pg
    On pg.household_id = fyt.household_id
    And pg.fiscal_year = (fyt.fiscal_year - 1)
  -- Check if gift made following year
  Left Join fy_totals ng
    On ng.household_id = fyt.household_id
    And ng.fiscal_year = (fyt.fiscal_year + 1)
  -- Check if gift made nfy2 year
  Left Join fy_totals ng2
    On ng2.household_id = fyt.household_id
    And ng2.fiscal_year = (fyt.fiscal_year + 2)
)

, merged As (
  (
  Select
    household_id
    , donor_id
    , sort_name
    , degrees_concat
    , fiscal_year
    , cfy_max_gift_dt
    , nfy_next_gift_dt
    , pfy_total_countable_amount
    , cfy_total_countable_amount
    , nfy_total_countable_amount
    , cfy_ytd_countable_amount
    , cfy_ytd_max_gift_dt
  From multiyear
  ) Union All (
  -- Add in dummy 0 rows for LYBUNT churn
  Select
    household_id
    , donor_id
    , sort_name
    , degrees_concat
    , fiscal_year + 1
      As fiscal_year
    , nfy_next_gift_dt
      As cfy_max_gift_dt
    , nfy2_next_gift_dt
      As nfy_next_gift_dt
    , cfy_total_countable_amount
      As pfy_total_countable_amount
    , nfy_total_countable_amount
      As cfy_total_countable_amount
    , nfy2_total_countable_amount
      As nfy_total_countable_amount
    , nfy_ytd_countable_amount
      As cfy_ytd_countable_amount
    , nfy_ytd_max_gift_dt
      As cfy_ytd_max_gift_dt
  From multiyear
  Where nfy_total_countable_amount Is Null
  )
)

Select
  merged.*
  , Case
      When pfy_total_countable_amount >= 10E3
        Or cfy_total_countable_amount >= 10E3
        Then 'Y'
      End
    As pfy_or_cfy_10k
  , Case
      -- Churn
      When cfy_total_countable_amount Is Null
        And pfy_total_countable_amount > 0
        Then 'Churn'
      -- Acquisition
      When cfy_total_countable_amount > 0
        And pfy_total_countable_amount Is Null
        Then 'New'
      -- Retention
      When cfy_total_countable_amount > 0
        And pfy_total_countable_amount = cfy_total_countable_amount
        Then 'Retain'
      -- Upgrade
      When cfy_total_countable_amount > 0
        And pfy_total_countable_amount < cfy_total_countable_amount
        Then 'Upgrade'
      -- Downgrade
      When cfy_total_countable_amount > 0
        And pfy_total_countable_amount > cfy_total_countable_amount
        Then 'Downgrade'
      End
    As cfy_segment
    , Case
      -- Churn
      When cfy_ytd_countable_amount Is Null
        And pfy_total_countable_amount > 0
        Then 'Churn'
      -- Acquisition
      When cfy_ytd_countable_amount > 0
        And pfy_total_countable_amount Is Null
        Then 'New'
      -- Retention
      When cfy_ytd_countable_amount > 0
        And pfy_total_countable_amount = cfy_ytd_countable_amount
        Then 'Retain'
      -- Upgrade
      When cfy_ytd_countable_amount > 0
        And pfy_total_countable_amount < cfy_ytd_countable_amount
        Then 'Upgrade'
      -- Downgrade
      When cfy_ytd_countable_amount > 0
        And pfy_total_countable_amount > cfy_ytd_countable_amount
        Then 'Downgrade'
      End
    As cfy_ytd_segment
    , cal.curr_fy
From merged
Cross Join v_current_calendar cal
;
