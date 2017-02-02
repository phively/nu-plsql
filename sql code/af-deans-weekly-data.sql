-- Pull CFY KSM AF gifts to compare year to year
/*********************************************************
 * EDIT THESE CONSTANTS!                                 *
 * Insert current and previous fiscal year numbers below *
 *********************************************************/
With fys As (
  Select
    2017 As cur_fy, -- edit this
    2016 As prev_fy -- edit this
  From DUAL -- null table
),
/*********************************************************
 * Do not edit below here                                *
 *********************************************************/
-- Allocations tagged as Kellogg Annual Fund
ksm_af_allocs As (
  Select Distinct allocation_code,
    allocation.short_name
  From advance.allocation
  Where annual_sw = 'Y'
    And alloc_school = 'KM'
)
-- Select needed fields from nu_gft_trp_gifttrans
Select ksm_af_allocs.allocation_code, short_name, tx_number, fiscal_year, date_of_record, legal_amount, nwu_af_amount,
    -- Construct custom gift size bins column
    -- N.B. legal amount includes all gifts sitting in the chosen accounts; use nwu_af_amount to match CAT103
  Case
    When legal_amount >= 1000000 Then 'A: 1M+'
    When legal_amount >= 100000 Then 'B: 100K+'
    When legal_amount >= 50000 Then 'C: 50K+'
    When legal_amount >= 2500 Then 'D: 2.5K+'
    Else 'E: <2.5K'
  End As ksm_af_bin,
  -- Construct year-to-date indicator
  advance.fytd_indicator(date_of_record) As ind_ytd
From ksm_af_allocs, nu_gft_trp_gifttrans, fys
-- Only use the KSM allocations
Where nu_gft_trp_gifttrans.allocation_code = ksm_af_allocs.allocation_code
  -- Only pull specified fiscal years
  And fiscal_year In (fys.cur_fy, fys.prev_fy)
  -- Drop pledges
  And tx_gypm_ind != 'P';
