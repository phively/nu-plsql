With

plg_credit As (
  Select Distinct
    gc.opportunity_record_id
    , min(gc.managed_hierarchy) -- This works because Unmanaged is alphabetically last
      As managed_hierarchy
  From v_ksm_gifts_cash gc
  Where trim(gc.opportunity_record_id) Is Not Null
  Group By
    gc.opportunity_record_id
)

, plg As (
  Select
    pd.*
    , cash.cash_category
    , Case
        -- On schedule & payment due this FY
        When nvl(months_overdue1, 0) = 0
          And nvl(balance_cfy, 0) > 0
          Then Case
            -- First payment due this FY
            When nvl(paid_cfy, 0) = 0
              Then 'OnSched1stDue'
            -- On schedule, already made a payment this FY
            When nvl(paid_cfy, 0) > 0
              Then 'OnSched1stPaid'
            End
        -- Discount overdue
        When months_overdue1 > 12
          Then 'Overdue13+'
        When months_overdue1 > 6
          Then 'Overdue7-12'
        When months_overdue1 > 0
          Then 'Overdue1-6'
        -- Fallback
        Else 'Fallback'
        End
      As plg_status_desc
  From tableau_pledge_data pd
  Inner Join mv_ksm_designation cash
    On cash.designation_record_id = pd.designation_record_id
  Where pd.BALANCE_CFY > 0
    And cash.cash_category = 'Expendable'
)

Select
  pd.donor_id
  , vas.prospect_manager_name
  , vas.lagm_name
  , pd.PREF_MAIL_NAME
  , pd.OPPORTUNITY_RECORD_ID
  , pd.CREDIT_DATE
  , pd.designation_record_id
  , pd.DESIGNATION_NAME
  , pd.cash_category
  , plg_credit.managed_hierarchy
  , pd.FISCAL_YEAR
  , pd.paid_cfy
  , pd.balance_cfy
  , Case
      When plg_status_desc = 'OnSched1stDue'
        Then 1.0
      When plg_status_desc = 'OnSched1stPaid'
        Then 0.5
      When plg_status_desc = 'Overdue13+'
        Then 0.0
      When plg_status_desc = 'Overdue7-12'
        Then 0.5
      When plg_status_desc = 'Overdue1-6'
        Then 0.8
      When plg_status_desc = 'Fallback'
        Then 0.5
      End
    As recommended_discount_to
  , NULL
    As expected_cash
  , pd.MONTHS_OVERDUE1
  , pd.NEW_MONTHS_OVERDUE
  , pd.pledge_original_amount
  , pd.pledge_ksm_total
  , pd.next_payment_date
  , pd.next_payment_amount
  , pd.last_payment_date
  , pd.last_payment_amount
From plg pd
Left Join mv_assignments vas
  On vas.donor_id = pd.donor_id
Left Join plg_credit
  On plg_credit.opportunity_record_id = pd.OPPORTUNITY_RECORD_ID
--  And plg_credit.fiscal_year = pd.fiscal_year
Order By balance_cfy Desc Nulls Last
