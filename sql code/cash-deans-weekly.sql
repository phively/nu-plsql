With

-- FYTD indicator
-- Can tweak fiscal years and which day to use as previous day below
-- For example, for EOFY 2023 use:
/*
    2022 As prev_fy
    , 2023 As curr_fy
    , to_date('20230831', 'yyyymmdd') As prev_day
*/
cal As (
  Select
    curr_fy - 1 As prev_fy
    , curr_fy - 0 As curr_fy
    , yesterday As prev_day
  From rpt_pbh634.v_current_calendar
)
, ytd_dts As (
  Select
    to_date('09/01/' || (cal.prev_fy - 1), 'mm/dd/yyyy') + rownum - 1 As dt
    -- If prev_day is EOFY (8/31) then ytd_ind should be 'Y' for all dates
    , Case
        When extract(month from cal.prev_day) = 8 And extract(day from cal.prev_day) = 31
          Then 'Y'
        Else rpt_pbh634.ksm_pkg_tmp.fytd_indicator(to_date('09/01/' || (cal.prev_fy - 1), 'mm/dd/yyyy') + rownum - 1,
            - (trunc(sysdate) - cal.prev_day))
        End
      As ytd_ind
  From cal
  Connect By
    rownum <= (to_date('09/01/' || cal.curr_fy, 'mm/dd/yyyy') - to_date('09/01/' || (cal.prev_fy - 1), 'mm/dd/yyyy'))
)

-- Current cash transactions
, cash As (
  Select
    cru.*
    , gft.*
    , cal.curr_fy
    , cal.prev_fy
    , cal.prev_day
    , Case
      When gft.allocation_code = '3203006213301GFT' Then 'Kellogg Education Center'
      When gft.payment_type = 3 Then 'Other Cash'
      When gft.allocation_code In (
        '3303002283701GFT' -- Kellogg Envision Campaign
        , '3303002280601GFT' -- Kellogg Building Fund
        , '3203004284701GFT' -- Donald P. Jacobs Wing
      ) Then 'Expendable Cash'
      When af_flag Is Not Null Then 'Expendable Cash'
      When af_flag Is Null Then 'Other Cash'
      Else 'ZZZ Error'
      End
      As cash_type
  From nu_gft_trp_gifttrans gft
  Cross Join cal
  Inner Join ytd_dts On trunc(ytd_dts.dt) = trunc(gft.date_of_record)
  Left Join table(rpt_pbh634.ksm_pkg_tmp.tbl_alloc_curr_use_ksm) cru On cru.allocation_code = gft.allocation_code
  Where alloc_school = 'KM'
    And fiscal_year In (cal.curr_fy, cal.prev_fy)
    And tx_gypm_ind <> 'P'
    And ytd_dts.ytd_ind = 'Y'
)

-- Main query
Select
  cash_type
  , sum(Case When fiscal_year = curr_fy Then legal_amount Else 0 End) As cfy_ytd_cash
  , sum(Case When fiscal_year = prev_fy Then legal_amount Else 0 End) As pfy_ytd_cash
  , prev_day As as_of
From cash
Group By cash_type, prev_day
Order By cash_type
