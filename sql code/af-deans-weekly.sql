-- Pull CFY KSM AF gifts to compare year to year
/*********************************************************
 * EDIT THESE CONSTANTS!                                 *
 * Insert current and previous fiscal year numbers below *
 *********************************************************/
With fys As (
  Select
    curr_fy,
    curr_fy - 1 As prev_fy
  From rpt_pbh634.v_current_calendar
),
/*********************************************************
 * Do not edit below here                                *
 *********************************************************/
-- Allocations tagged as Kellogg Annual Fund
ksm_af_allocs As (
  Select allocation_code, short_name
  From table(rpt_pbh634.ksm_pkg.tbl_alloc_annual_fund_ksm)
),
-- Select needed fields from nu_gft_trp_gifttrans
ksm_gifts As (
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
    -- Only pull recent fiscal years
    And fiscal_year In (fys.curr_fy, fys.prev_fy)
    -- Drop pledges
    And tx_gypm_ind != 'P'
)
-- Final data is pulled from here down
  -- Informative header specifying the exact years pulled
(
  Select '--- Year ---' As af_bins, curr_fy, prev_fy
  From fys
) Union (
  -- Cross-tabulation step
  -- N.B. legal amount includes all gifts sitting in the chosen accounts; use nwu_af_amount to match CAT103
  Select ksm_af_bin,
    Sum(Case When fiscal_year = fys.curr_fy Then legal_amount Else 0 End) As curr_fy,
    Sum(Case When fiscal_year = fys.prev_fy Then legal_amount Else 0 End) As prev_fy
  From ksm_gifts, fys
  Where ind_ytd = 'Y'
  Group By ksm_af_bin
)
Order By af_bins
