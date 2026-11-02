Create Or Replace View tableau_metrics_ngc As

With

metrics As (
  Select
    metrics_pkg.get_numeric_constant('mg_ask_amt') As mg_ask_amt
    , metrics_pkg.get_numeric_constant('mg_ask_amt_ksm_outright') As mg_ask_amt_ksm_outright
    , metrics_pkg.get_numeric_constant('mg_ask_amt_ksm_plg') As mg_ask_amt_ksm_plg
    , metrics_pkg.get_numeric_constant('mg_granted_amt') As mg_granted_amt
    , metrics_pkg.get_numeric_constant('mg_funded_count') As mg_funded_count
  From DUAL
)

, credit_date As (
  Select Distinct
    opportunity_record_id
    , min(credit_date)
      As first_credit_date
  From mv_transactions
  Group By opportunity_record_id
)

Select
  mvp.opportunity_salesforce_id
  , mvp.proposal_record_id
  , mvp.household_id_ksm
  , mvp.household_primary_ksm
  , mvp.prospect_name
  , mvp.donor_id
  , mvp.sort_name
  , mve.institutional_suffix
  , mve.preferred_address_city
  , mve.preferred_address_state
  , mve.preferred_address_country
  , mvp.historical_pm_user_id
  , mvp.historical_pm_name
  , mvp.historical_pm_role
  , mvp.historical_pm_business_unit
  , mvp.ksm_flag
  , mvp.proposal_active_indicator
  , upd.standard_proposal_flag
  , mvp.proposal_type
  , mvp.proposal_anticipated_amount
  , mvp.proposal_submitted_amount
  , mvp.proposal_funded_amount
  , mvp.proposal_stage
  , mvp.proposal_created_date
  , mvp.proposal_submitted_date
  , mvp.proposal_close_date
  , mvp.proposal_first_linked_gift_pledge_id
  , cd.first_credit_date
  , upd.cal_year
  , upd.cal_month
  , upd.fiscal_year
  , upd.fiscal_quarter
  , upd.perf_year
  , upd.perf_quarter
  , ksm_pkg_calendar.get_performance_year(upd.proposal_submitted_date)
    As ask_perf_year
  , ksm_pkg_calendar.get_quarter(upd.proposal_submitted_date, 'performance')
    As ask_perf_quarter
  , ksm_pkg_calendar.get_performance_year(cd.first_credit_date)
    As funded_perf_year
  -- MG dollars raised criteria
  , Case
      When mvp.proposal_submitted_amount >= mg_ask_amt
        And mvp.proposal_funded_amount >= mg_granted_amt
        And mvp.proposal_stage = 'Funded'
      Then 'Y'
      End
    As mg_dollars_raised
  -- MG gifts closed criteria
  , Case
      When mvp.proposal_submitted_amount >= mg_ask_amt
        And mvp.proposal_funded_amount >= mg_funded_count
        And mvp.proposal_stage = 'Funded'
      Then 'Y'
      End
    As mg_gifts_closed
  -- KSM sols criteria: $250K+ ask, or $100K+ outright ask
  , Case
      When mvp.proposal_submitted_amount >= mg_ask_amt_ksm_plg
        Or (
          mvp.proposal_submitted_amount >= mg_ask_amt_ksm_outright
          And upd.standard_proposal_flag = 'Y'
        )
      Then 'Y'
      End
    As ksm_gifts_solicited
From table(metrics_pkg.tbl_universal_proposals_data) upd
Cross Join metrics
Inner Join mv_proposals mvp
  On mvp.proposal_record_id = upd.proposal_record_id
Inner Join mv_entity mve
  On mve.donor_id = mvp.donor_id
Left Join credit_date cd
  On cd.opportunity_record_id = mvp.proposal_first_linked_gift_pledge_id
;
