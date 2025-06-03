/*************************************************************************
Cash and source donor consolidated fields
*************************************************************************/

Create Or Replace View v_ksm_gifts_cash As
-- New gifts and commitments to KSM, with YTD indicators

With

-- Cash counting exceptions
-- Add additional entries as a new Union All section
override As (
  Select
    NULL As tx_id
    , NULL As amt
  From DUAL
  -- Fifteen Grp
  Union All
  Select 'T2529734', 199031.52 * 2
  From DUAL
  Union All
  Select 'T2536547', 200000.00 * 2
  From DUAL
)

, ksm_mgrs As (
  Select
    user_id
    , user_name
    , donor_id
    , sort_name
    , team
    , start_dt
    , nvl(stop_dt, to_date('99990101', 'yyyymmdd'))
      As stop_dt
  From tbl_ksm_gos
)

Select
  kt.credited_donor_audit
  , mve.donor_id
  , mve.full_name
  , mve.sort_name
  , mve.institutional_suffix
  , mve.household_id
  , mve.household_primary
  , mve.person_or_org
  , mve.primary_record_type
  , mve.is_deceased_indicator
  , kt.opportunity_donor_id
    As source_donor_id
  , kt.opportunity_donor_name
    As source_donor_name
  , kt.tribute_type
  , kt.tx_id
  , kt.opportunity_record_id
  , kt.anonymous_type
  , kt.legacy_receipt_number
  , kt.opportunity_stage
  , kt.opportunity_record_type
  , kt.opportunity_type
  , kt.source_type
  , kt.source_type_detail
  , kt.gypm_ind
  , kt.hard_and_soft_credit_salesforce_id
  , kt.credit_receipt_number
  , kt.matched_gift_record_id
  , kt.pledge_record_id
  , kt.payment_schedule
  , kt.linked_proposal_record_id
  , kt.historical_pm_name
  , kt.historical_pm_unit
  , kt.historical_prm_name
  , kt.historical_prm_unit
  , kt.historical_lagm_name
  , kt.historical_lagm_unit
  , kt.historical_credit_user_salesforce_id
  , kt.historical_credit_name
  , kt.historical_credit_assignment_type
  , kt.historical_credit_unit
  , Case
      -- Unmanaged
      When historical_credit_name Is Null
        Then 'Unmanaged'
      -- Active KSM MGOs
      When historical_credit_name In (
        Select user_name
        From ksm_mgrs
        Where team = 'MG'
          And kt.credit_date Between start_dt And stop_dt
      ) Then 'MGO'
      -- Any KSM LGO
      When historical_credit_name In (
        Select user_name
        From ksm_mgrs
        Where team = 'AF'
          And kt.credit_date Between start_dt And stop_dt
      ) Then 'LGO'
      -- Any other KSM staff
      When historical_credit_name In (
        Select user_name
        From ksm_mgrs
        Where team Not In ('AF', 'MG')
          And kt.credit_date Between start_dt And stop_dt
      ) Then 'KSM'
      -- NU assignments
      When historical_credit_unit Like '%Corporate%'
        Or historical_credit_unit Like '%Foundation%'
        Then 'CFR'
      End
    As managed_hierarchy
  , kt.designation_record_id
  , kt.designation_status
  , kt.legacy_allocation_code
  , kt.designation_name
  , kt.ksm_af_flag
  , kt.ksm_cru_flag
  , kt.cash_category
  , kt.full_circle_campaign_priority
  , kt.credit_date
  , kt.fiscal_year
  , ksm_pkg_calendar.fytd_indicator(kt.credit_date)
    As fytd_indicator
  , kt.entry_date
  , kt.credit_type
  , kt.credit_amount
  , kt.hard_credit_amount
  , kt.recognition_credit
  , kt.hh_credit
  , kt.hh_recognition_credit
  -- Cash counting logic and exceptions
  , Case
      -- Skip soft credit
      When kt.hard_credit_amount = 0
        Then 0
      -- Overrides
      When override.amt Is Not Null
        Then override.amt
      -- Default fallback
      Else kt.hard_credit_amount
      End
    As cash_countable_amount
  , Case
      When override.amt Is Not Null
        Then override.amt / kt.hh_credited_donors
      Else kt.hh_credit
      End
    As hh_countable_credit
  , kt.tender_type
  , kt.max_etl_update_date
  , kt.mv_last_refresh
  , cal.today
From mv_ksm_transactions kt
Cross Join v_current_calendar cal
Inner Join mv_entity mve
  On mve.donor_id = kt.credited_donor_id
Left Join override
  On override.tx_id = kt.tx_id
Where kt.gypm_ind In ('G', 'Y', 'M') -- Exclude pledges
  And kt.adjusted_opportunity_ind Is Null -- Exclude gift adjustment history
;
