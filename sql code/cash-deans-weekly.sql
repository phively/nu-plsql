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
    gft.tx_number
    , gft.id_number
    , gft.primary_donor_report_name
    , gft.allocation_code
    , gft.alloc_short_name
    , gft.tx_gypm_ind
    , gft.transaction_type
    , to_char(gft.fiscal_year)
      As fiscal_year
    , gft.date_of_record
    , gft.legal_amount
    , gft.cash_category
    , cal.curr_fy
    , cal.prev_fy
    , cal.prev_day
    , Case
      When gft.cash_category Not In ('KEC', 'Expendable', 'Hub Campaign Cash')
        Then 'Other Cash'
      Else gft.cash_category
      End
      As cash_type
  From rpt_pbh634.v_ksm_giving_cash gft
  Cross Join cal
  Inner Join ytd_dts On trunc(ytd_dts.dt) = trunc(gft.date_of_record)
  Where fiscal_year In (cal.curr_fy, cal.prev_fy)
    And ytd_dts.ytd_ind = 'Y'
  -- Manual exceptions
  Union
  Select
    g.tx_number
    , g.id_number
    , entity.report_name
    , g.allocation_code
    , g.alloc_short_name
    , g.tx_gypm_ind
    , g.transaction_type
    , g.fiscal_year
    , g.date_of_record
    , g.legal_amount
    , 'Expendable'
      As cash_category
    , cal.curr_fy
    , cal.prev_fy
    , cal.prev_day
    , 'Expendable'
      As cash_type
  From nu_gft_trp_gifttrans g
  Inner Join entity
    On entity.id_number = g.id_number
  Cross Join cal
  Inner Join ytd_dts On trunc(ytd_dts.dt) = trunc(g.date_of_record)
  Where g.fiscal_year In (cal.curr_fy, cal.prev_fy)
    And ytd_dts.ytd_ind = 'Y'
    And (
      g.tx_number = 3012462 And g.tx_sequence = 2
    )
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
