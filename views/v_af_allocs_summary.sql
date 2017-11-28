Create Or Replace View v_af_allocs_summary As

With

-- AF allocation purpose definitions
purposes As (
  Select
    purpose_code
    , short_desc
    , Case
        When lower(short_desc) Like '%scholar%' Or lower(short_desc) Like '%fellow%' Then 'Scholarships'
        When lower(short_desc) Like '%mainten%' Then 'Facilities'
        When lower(short_desc) Like '%research%' Then 'Research'
        Else 'Other Unrestricted'
      End As purpose
  From tms_purpose
)

-- CRU allocations
, cru As (
  Select
    alloc.*
    , Case
        When alloc.allocation_code = '3303000891301GFT' Then 'Annual Fund'
        When purposes.purpose Is Not Null Then purposes.purpose
        Else 'Other Unrestricted'
      End As alloc_categorizer
  From table(rpt_pbh634.ksm_pkg.tbl_alloc_curr_use_ksm) alloc
  Inner Join allocation On allocation.allocation_code = alloc.allocation_code
  Left Join purposes On purposes.purpose_code = allocation.alloc_purpose
)

-- KSM CRU gifts
, gft_summary As (
  Select
    allocation_code As alloc
    , fiscal_year
    , cal.curr_fy
    , count(tx_number) As total_gifts
    , sum(legal_amount) As total_cash_giving
    , count(Case When rpt_pbh634.ksm_pkg.fytd_indicator(date_of_record) = 'Y' Then tx_number Else NULL End) As ytd_gifts
    , sum(Case When rpt_pbh634.ksm_pkg.fytd_indicator(date_of_record) = 'Y' Then legal_amount Else 0 End) As ytd_cash_giving
  From table(rpt_pbh634.ksm_pkg.tbl_gift_credit_ksm) gft
  Cross Join table(rpt_pbh634.ksm_pkg.tbl_current_calendar) cal
  Where cru_flag = 'Y' -- Current Use only
    And tx_gypm_ind <> 'P' -- Exclude pledges, i.e. cash only
    And legal_amount > 0 -- Actual gifts only, not credited
  Group By
    allocation_code
    , fiscal_year
    , cal.curr_fy
)

-- Main query
Select *
From cru
Left Join gft_summary On gft_summary.alloc = cru.allocation_code
