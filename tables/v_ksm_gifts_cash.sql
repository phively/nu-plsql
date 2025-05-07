/*************************************************************************
Cash and source donor consolidated fields
*************************************************************************/

Create Or Replace View v_ksm_gifts_cash As
-- New gifts and commitments to KSM, with YTD indicators

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
  , kt.linked_proposal_record_id
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
  , kt.etl_update_date
  , kt.mv_last_refresh
  , cal.today
From mv_ksm_transactions kt
Cross Join v_current_calendar cal
Inner Join mv_entity mve
  On mve.donor_id = kt.credited_donor_id
Where kt.gypm_ind In ('G', 'Y', 'M') -- Exclude pledges
  And kt.adjusted_opportunity_ind Is Null -- Exclude gift adjustment history
;
