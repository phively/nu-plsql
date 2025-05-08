with cal As (
  Select
    curr_fy - 2 As prev_fy
    , curr_fy - 0 As curr_fy
    , yesterday As prev_day
  From TABLE(KSM_PKG_CALENDAR.tbl_current_calendar)
)

, ytd_dts As (
  Select
    to_date('09/01/' || (cal.prev_fy - 1), 'mm/dd/yyyy') + rownum - 1 As dt
    -- If prev_day is EOFY (8/31) then ytd_ind should be 'Y' for all dates
    , Case
        When extract(month from cal.prev_day) = 8 And extract(day from cal.prev_day) = 31
          Then 'Y'
        Else KSM_PKG_CALENDAR.fytd_indicator(to_date('09/01/' || (cal.prev_fy - 1), 'mm/dd/yyyy') + rownum - 1,
            - (trunc(sysdate) - cal.prev_day))
        End
      As ytd_ind
  From cal
  Connect By
    rownum <= (to_date('09/01/' || cal.curr_fy, 'mm/dd/yyyy') - to_date('09/01/' || (cal.prev_fy - 1), 'mm/dd/yyyy'))
)


, srcdnr As (
  Select
    gt.opportunity_record_id
    , gt.hard_credit_amount
    , gt.fiscal_year
    , gt.source_donor_id -- is this correct?
  From v_ksm_gifts_ngc gt
  Cross Join cal
  Inner Join ytd_dts
    On trunc(ytd_dts.dt) = trunc(gt.credit_date)
  Where gt.fiscal_year Between cal.prev_fy And cal.curr_fy
    And ytd_dts.ytd_ind = 'Y'
)

Select
  mv_entity.person_or_org
  , sum(Case When fiscal_year = curr_fy - 0 Then hard_credit_amount Else 0 End) As cfy_total_giving
  , sum(Case When fiscal_year = curr_fy - 1 Then hard_credit_amount Else 0 End) As pfy1_total_giving
  , sum(Case When fiscal_year = curr_fy - 2 Then hard_credit_amount Else 0 End) As pfy2_total_giving
From srcdnr
Cross Join cal
inner join mv_entity on mv_entity.donor_id = srcdnr.source_donor_id
group by mv_entity.person_or_org
