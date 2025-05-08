With

-- FYTD indicator
-- Can tweak fiscal years and which day to use as previous day below
-- For example, for EOFY 2023 use:
/*
    2021 As prev_fy
    , 2023 As curr_fy
    , to_date('20230831', 'yyyymmdd') As prev_day
*/

cal As (
  Select
    curr_fy - 2 As prev_fy
    , curr_fy - 0 As curr_fy
    , yesterday As prev_day
  From v_current_calendar
)

, ytd_dts As (
  Select
    to_date('09/01/' || (cal.prev_fy - 1), 'mm/dd/yyyy') + rownum - 1 As dt
    -- If prev_day is EOFY (8/31) then ytd_ind should be 'Y' for all dates
    , Case
        When extract(month from cal.prev_day) = 8 And extract(day from cal.prev_day) = 31
          Then 'Y'
        Else ksm_pkg_calendar.fytd_indicator(to_date('09/01/' || (cal.prev_fy - 1), 'mm/dd/yyyy') + rownum - 1,
            - (trunc(sysdate) - cal.prev_day))
        End
      As ytd_ind
  From cal
  Connect By
    rownum <= (to_date('09/01/' || cal.curr_fy, 'mm/dd/yyyy') - to_date('09/01/' || (cal.prev_fy - 1), 'mm/dd/yyyy'))
)

, cash As (
  Select
    gft.opportunity_record_id
    , gft.donor_id
    , gft.full_name
    , gft.legacy_allocation_code
    , gft.designation_name
    , gft.gypm_ind
    , gft.opportunity_type
    , gft.fiscal_year
    , gft.credit_date
    , gft.hard_credit_amount
    , gft.cash_category
    , cal.curr_fy
    , cal.prev_fy
    , cal.prev_day
    , Case
        When gft.cash_category Not In ('KEC', 'Expendable', 'Hub Campaign Cash')
          Then 'Z-Other Cash'
        When gft.cash_category = 'Expendable'
          Then 'A-Expendable'
        When gft.cash_category = 'KEC'
          Then 'B-KEC'
        When gft.cash_category = 'Hub Campaign Cash'
          Then 'C-Hub Campaign Cash'
        Else gft.cash_category
        End
      As cash_type
From v_ksm_gifts_cash gft
Cross Join cal
Inner Join ytd_dts On trunc(ytd_dts.dt) = trunc(gft.credit_date)
  Where fiscal_year Between cal.prev_fy And cal.curr_fy
    And ytd_dts.ytd_ind = 'Y'
-- Manual exceptions
/* Need to redo
Union
  Select
    gt.opportunity_record_id
    , gt.credited_donor_id
    , gt.credited_donor_name
    , gt.designation_record_id
    , gt.designation_name
    , gt.gypm_ind
    , gt.opportunity_type
    , gt.fiscal_year
    , gt.credit_date
    , gt.hard_credit_amount
    , 'A-Expendable' As cash_category
    , cal.curr_fy
    , cal.prev_fy
    , cal.prev_day
    , 'A-Expendable' As cash_type
From mv_ksm_transactions gt
Cross Join cal
Inner Join ytd_dts On trunc(ytd_dts.dt) = trunc(gt.credit_date)
Where gt.fiscal_year Between cal.prev_fy And cal.curr_fy
  And ytd_dts.ytd_ind = 'Y'
  And (
    (
      gt.legacy_receipt_number = '0003012462' And gt.designation_name = 'KSM Fifteen Grp Real Estate 2'
    ) Or (
      gt.legacy_receipt_number = '0003084920' And gt.designation_name = 'KSM Fifteen Grp Real Estate 2'
    )
  )*/
)



Select
  cash_type
  , sum(Case When fiscal_year = curr_fy - 0 Then hard_credit_amount Else 0 End) As cfy_ytd_cash
  , sum(Case When fiscal_year = curr_fy - 1 Then hard_credit_amount Else 0 End) As pfy1_ytd_cash
  , sum(Case When fiscal_year = curr_fy - 2 Then hard_credit_amount Else 0 End) As pfy2_ytd_cash
  , prev_day As as_of
From cash
Group By cash_type, prev_day
Order By cash_type
