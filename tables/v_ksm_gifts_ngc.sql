/*************************************************************************
New gifts and commitments (NGC) and source donor consolidated fields
*************************************************************************/

Create Or Replace View v_ksm_gifts_ngc As
-- New gifts and commitments to KSM, with YTD indicators

With

srcdonor As (
  Select
    mvs.tx_id
    , mvs.source_donor_id
    , mve.full_name
      As source_donor_name
  From mv_source_donor mvs
  Inner Join mv_entity mve
    On mve.donor_id = mvs.source_donor_id
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
  , nvl(srcdonor.source_donor_id, kt.opportunity_donor_id)
    As source_donor_id
  , nvl(srcdonor.source_donor_name, kt.opportunity_donor_name)
    As source_donor_name
  , kt.tribute_type
  , kt.tx_id
  , kt.opportunity_record_id
  , kt.anonymous_type
  , kt.legacy_receipt_number
  , kt.opportunity_stage
  , kt.opportunity_record_type
  , kt.opportunity_type
  , kt.adjusted_opportunity_ind
  , kt.opportunity_adjustment_type
  , kt.payment_adjustment_type
  , kt.source_type
  , kt.source_type_detail
  , kt.gypm_ind
  , kt.hard_and_soft_credit_salesforce_id
  , kt.credit_receipt_number
  , kt.matched_gift_record_id
  , kt.matching_gift_original_gift_receipt
  , kt.original_gift_credit_date
  , kt.original_gift_fy
  , kt.pledge_record_id
  , kt.payment_schedule
  , kt.linked_proposal_record_id
  , kt.historical_pm_name
  , kt.historical_pm_unit
  , kt.historical_prm_name
  , kt.historical_prm_unit
  , kt.historical_lagm_name
  , kt.historical_lagm_unit
  , kt.historical_credit_name
  , kt.historical_credit_assignment_type
  , kt.historical_credit_unit
  , kt.designation_record_id
  , kt.designation_status
  , kt.legacy_allocation_code
  , kt.designation_name
  , kt.fin_fund_id
  , kt.fin_department_id
  , kt.fin_project_id
  , kt.fin_activity
  , kt.campaign_code
  , kt.campaign_name
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
  , Case
      When unsplit.unsplit_amount Is Not Null
        Then unsplit.unsplit_amount
      Else kt.hard_credit_amount
      End
    As unsplit_amount
  , kt.tender_type
  , kt.hh_credited_donors
  , kt.hh_credit
  , kt.hh_recognition_credit
  , kt.max_etl_update_date
  , kt.mv_last_refresh
  , cal.today
From mv_ksm_transactions kt
Cross Join v_current_calendar cal
Inner Join mv_entity mve
  On mve.donor_id = kt.credited_donor_id
Left Join srcdonor
  On srcdonor.tx_id = kt.tx_id
Left Join table(ksm_pkg_gifts.tbl_unsplit_amounts) unsplit
  On unsplit.pledge_or_gift_record_id = kt.opportunity_record_id
Where kt.gypm_ind In ('G', 'P', 'M') -- Exclude pledge payments
  And kt.adjusted_opportunity_ind Is Null -- Exclude gift adjustment history
;
