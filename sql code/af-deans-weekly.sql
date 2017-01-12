-- Pull FY17 KSM AF gifts
-- Allocations tagged as Kellogg Annual Fund
With ksm_af_allocs As (
  Select Distinct allocation_code,
    allocation.short_name
  From advance.allocation
  Where annual_sw = 'Y'
    And alloc_school = 'KM'
)
-- Select needed fields
Select ksm_af_allocs.allocation_code, short_name, tx_number, fiscal_year, date_of_record, legal_amount, nwu_af_amount,
  -- Construct custom gift size bins column
  Case
    When nwu_af_amount >= 1000000 Then 'A: 1M+'
    When nwu_af_amount >= 100000 Then 'B: 100K+'
    When nwu_af_amount >= 50000 Then 'C: 50K+'
    When nwu_af_amount >= 2500 Then 'D: 2.5K+'
    Else 'E: <2.5K'
  End As nwu_af_bin,
  -- Construct year-to-date indicator
  fytd_indicator(date_of_record) As ind_ytd
From ksm_af_allocs, nu_gft_trp_gifttrans
-- Only use the KSM allocations
Where nu_gft_trp_gifttrans.allocation_code = ksm_af_allocs.allocation_code
  -- Only pull recent fiscal years
  And fiscal_year In (2016, 2017)
  -- Drop pledges
  And tx_gypm_ind != 'P';
