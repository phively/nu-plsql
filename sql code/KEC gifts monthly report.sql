Select
  Case
    When kt.gypm_ind = 'P'
      Then 'commitment'
    When kt.gypm_ind = 'Y'
      Then 'payment/cash'
    Else 'cash'
    End
    As transaction_category
  , kt.credited_donor_id
  , kt.credited_donor_sort_name
  , kt.tx_id
  , kt.opportunity_record_id
  , kt.opportunity_record_type
  , kt.opportunity_type
  , kt.gypm_ind
  , kt.credit_date
  , kt.fiscal_year
  , kt.hard_credit_amount
  , kt.pledge_record_id
  , kt.tender_type
  , kt.designation_record_id
  , kt.designation_name
  , kt.fin_fund_id
  , kt.fin_department_id
  , kt.fin_project_id
  , kt.fin_activity
  , kt.cash_category
  , kt.full_circle_campaign_priority
From mv_ksm_transactions kt
Where
  kt.hard_credit_amount > 0
  And (
  -- KEC only
  kt.full_circle_campaign_priority = 'KEC'
  Or kt.cash_category = 'KEC'
  Or kt.designation_record_id = 'N3024035'
  )
Order By kt.credit_date Desc
