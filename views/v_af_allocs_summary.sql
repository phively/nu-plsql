Create Or Replace View v_af_allocs_summary As

With

-- CRU allocations
cru As (
  Select *
  From table(rpt_pbh634.ksm_pkg.tbl_alloc_curr_use_ksm)
)

-- KSM CRU gifts
, gft_summary As (
  Select
    allocation_code As ac
    , count(tx_number) As total_gifts
    , sum(legal_amount) As total_giving
    , min(fiscal_year) As first_gift_year
    , max(fiscal_year) As last_gift_year
    , sum(Case When fiscal_year = cal.curr_fy - 0 Then legal_amount Else 0 End) As cfy_giving
    , count(Case When fiscal_year = cal.curr_fy - 0 Then tx_number Else NULL End) As cfy_gifts
    , sum(Case When fiscal_year = cal.curr_fy - 1 Then legal_amount Else 0 End) As pfy1_giving
    , count(Case When fiscal_year = cal.curr_fy - 1 Then tx_number Else NULL End) As pfy1_gifts
    , sum(Case When fiscal_year = cal.curr_fy - 2 Then legal_amount Else 0 End) As pfy2_giving
    , count(Case When fiscal_year = cal.curr_fy - 2 Then tx_number Else NULL End) As pfy2_gifts
    , sum(Case When fiscal_year = cal.curr_fy - 3 Then legal_amount Else 0 End) As pfy3_giving
    , count(Case When fiscal_year = cal.curr_fy - 3 Then tx_number Else NULL End) As pfy3_gifts
  From table(rpt_pbh634.ksm_pkg.tbl_gift_credit_ksm) gft
  Cross Join table(rpt_pbh634.ksm_pkg.tbl_current_calendar) cal
  Where cru_flag = 'Y' -- Current Use only
    And tx_gypm_ind <> 'P' -- Exclude pledges, i.e. cash only
    And legal_amount > 0 -- Actual gifts only, not credited
  Group By allocation_code
)

-- Main query
Select *
From cru
Left Join gft_summary On gft_summary.ac = cru.allocation_code
