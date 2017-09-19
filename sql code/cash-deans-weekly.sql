With

-- FYTD indicator
-- Can tweak fiscal years and which day to use as previous day below
cal As (
  Select curr_fy - 1 As prev_fy,
    curr_fy,
    yesterday As prev_day
  From v_current_calendar
),
ytd_dts As (
  Select to_date('09/01/' || (cal.prev_fy - 1), 'mm/dd/yyyy') + rownum - 1 As dt,
    ksm_pkg.fytd_indicator(to_date('09/01/' || (cal.prev_fy - 1), 'mm/dd/yyyy') + rownum - 1,
      - (trunc(sysdate) - cal.prev_day)) As ytd_ind
  From cal
  Connect By
    rownum <= (to_date('09/01/' || cal.curr_fy, 'mm/dd/yyyy') - to_date('09/01/' || (cal.prev_fy - 1), 'mm/dd/yyyy'))
),

-- Current cash transactions
cash As (
  Select cru.*, gft.*,
    cal.curr_fy, cal.prev_fy, cal.prev_day,
    Case
      When af_flag = 'Y' Then 'Annual Fund'
      When af_flag = 'N' Then 'Current Use Expendable'
      When af_flag Is Null Then 'Other Cash'
      Else 'ZZZ Error'
    End As cash_type
  From nu_gft_trp_gifttrans gft
  Cross Join cal
  Inner Join ytd_dts On trunc(ytd_dts.dt) = trunc(gft.date_of_record)
  Left Join table(rpt_pbh634.ksm_pkg.tbl_alloc_curr_use_ksm) cru On cru.allocation_code = gft.allocation_code
  Where alloc_school = 'KM'
    And fiscal_year In (cal.curr_fy, cal.prev_fy)
    And tx_gypm_ind <> 'P'
    And ytd_dts.ytd_ind = 'Y'
)

-- Main query
Select
  cash_type,
  sum(Case When fiscal_year = curr_fy Then legal_amount Else 0 End) As cfy_ytd_cash,
  sum(Case When fiscal_year = prev_fy Then legal_amount Else 0 End) As pfy_ytd_cash,
  prev_day As as_of
From cash
Group By cash_type, prev_day
Order By cash_type
