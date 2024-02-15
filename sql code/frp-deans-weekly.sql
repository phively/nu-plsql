-- FYTD indicator
-- Can tweak fiscal years and which day to use as previous day below
-- For example, for EOFY 2023 use:
/*
    2021 As prev_fy
    , 2023 As curr_fy
    , to_date('20230831', 'yyyymmdd') As prev_day
*/

With

cal As (
  Select
    curr_fy - 2 As prev_fy
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

, srcdnr As (
  Select
    gt.tx_number
    , gt.legal_amount
    , gt.fiscal_year
    , rpt_pbh634.ksm_pkg_tmp.get_gift_source_donor_ksm(gt.tx_number) As src_donor_id
  From rpt_pbh634.v_ksm_giving_trans gt
  Cross Join cal
  Inner Join ytd_dts
    On trunc(ytd_dts.dt) = trunc(gt.date_of_record)
  Where gt.fiscal_year Between cal.prev_fy And cal.curr_fy
    And gt.tx_gypm_ind <> 'Y'
    And ytd_dts.ytd_ind = 'Y'
)

Select
  entity.person_or_org
  , sum(Case When fiscal_year = curr_fy - 0 Then legal_amount Else 0 End) As cfy_total_giving
  , sum(Case When fiscal_year = curr_fy - 1 Then legal_amount Else 0 End) As pfy1_total_giving
  , sum(Case When fiscal_year = curr_fy - 2 Then legal_amount Else 0 End) As pfy2_total_giving
From srcdnr
Cross Join cal
Inner Join entity
  On entity.id_number = srcdnr.src_donor_id
Group By
  entity.person_or_org
