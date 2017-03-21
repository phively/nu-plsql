Create Or Replace View v_ksm_campaign_2008_gifts As

With 
/* KSM-specific campaign new gifts & commitments definition */
ksm_data As (
  (
  -- Kellogg campaign new gifts & commitments
  Select id_number, record_type_code, person_or_org, birth_dt, category_code, rcpt_or_plg_number, xsequence,
    credited_amount, amount, prim_amount,
    year_of_giving, date_of_record, alloc_code, alloc_school, alloc_purpose, annual_sw, restrict_code,
    transaction_type, pledge_status, gift_pledge_or_match, matched_donor_id, matched_receipt_number,
    this_date, first_processed_date, std_area, zipcountry
  From nu_rpt_t_cmmt_dtl_daily daily
  Where daily.alloc_school = 'KM'
  ) Union All (
  -- Internal transfer; 344303 is 50%
  Select id_number, record_type_code, person_or_org, birth_dt, category_code, rcpt_or_plg_number, xsequence,
    344303 As credited_amount, 344303 As amount, 344303 As prim_amount,
    year_of_giving, date_of_record, alloc_code, alloc_school, alloc_purpose, annual_sw, restrict_code,
    transaction_type, pledge_status, gift_pledge_or_match, matched_donor_id, matched_receipt_number,
    this_date, first_processed_date, std_area, zipcountry
  From nu_rpt_t_cmmt_dtl_daily daily
  Where daily.rcpt_or_plg_number = '0002275766'
  )
),
/* Allocation-priority assignment, taken from RPT_BTAYLOR_WT09931_EXTRACTTRANSACTIONS */
priorities As (
  Select field01 As allocation_code, field02 As priority
  From WT099030_ALLOCATIONS_20111130 wt
),
/* Additional KSM-specific derived fields */
ksm_campaign As (
  Select ksm_data.*,
    -- Fiscal year-to-date indicator
    ksm_pkg.fytd_indicator(date_of_record) As ftyd_ind,
    -- Calendar objects
    cal.curr_fy,
    -- Giving bin
    Case
      When amount >= 1000000 Then 'A $1M+'
      When amount >= 100000  Then 'B $100K-$999.9K'
      When amount >= 50000   Then 'C $50K-$99.9K'
      When amount >= 2500    Then 'D $2.5K-$49.9K'
      When amount <  2500    Then 'E <$2.5K'
    End As giving_band,
    -- Campaign priority coding
    -- Logic copied from function RPT_BTAYLOR.WT09931_EXTRACTTRANSACTIONS
    Case
      When alloc_code In ('BE', 'LE') Then 'Educational Mission Unrestricted'
      When date_of_record >= to_date('20100901', 'YYYYMMDD') And annual_sw = 'Y'
        Then 'Global Innovation'
      When alloc_code = '3303000882101GFT' Then 'Global Hub'
      Else priorities.priority
    End As ksm_campaign_category,
    -- Replace null ksm_source_donor with id_number
    NVL(ksm_pkg.get_gift_source_donor_ksm(rcpt_or_plg_number), id_number) As ksm_source_donor
  From v_current_calendar cal, ksm_data
    Left Join priorities On priorities.allocation_code = ksm_data.alloc_code
)

/* Main query */
Select ksm_campaign.*,
  hh.household_id, hh.household_name, hh.household_spouse, hh.household_ksm_year, hh.household_program_group,
  -- Record type
  Case
    When household_record = 'ST' Then '3 Students'
    When household_record In ('AL', 'FA') Then '1 Alumni'
    When household_record In ('NA', 'FN') Then '2 Non-Alumni'
    When household_record In ('CP', 'CF') Then '4 Corporations'
    When household_record = 'FP' Then '5 Foundations'
    Else '6 Other Organizations'
  End As hh_source_ksm
From ksm_campaign
  Inner Join table(ksm_pkg.tbl_entity_households_ksm) hh On ksm_campaign.ksm_source_donor = hh.id_number
