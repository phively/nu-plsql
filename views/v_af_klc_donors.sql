Create Or Replace View v_af_klc_donors As

/* Pulls KLC donors using the ksm_pkg definition, and appends AF and Current Use giving */

Select Distinct
  -- KLC table data
  klc.*,
  -- Summarized current use giving data
  af.cru_curr_fy, af.cru_prev_fy1, af.cru_prev_fy2, af.cru_prev_fy3,
  -- Current year CRU and AF data
  Case
    When klc.fiscal_year = cal.curr_fy - 0 Then af.ksm_af_curr_fy
    When klc.fiscal_year = cal.curr_fy - 1 Then af.ksm_af_prev_fy1
    When klc.fiscal_year = cal.curr_fy - 2 Then af.ksm_af_prev_fy2
    When klc.fiscal_year = cal.curr_fy - 3 Then af.ksm_af_prev_fy3
    Else NULL
  End As fy_af,
  Case
    When klc.fiscal_year = cal.curr_fy - 0 Then af.cru_curr_fy
    When klc.fiscal_year = cal.curr_fy - 1 Then af.cru_prev_fy1
    When klc.fiscal_year = cal.curr_fy - 2 Then af.cru_prev_fy2
    When klc.fiscal_year = cal.curr_fy - 3 Then af.cru_prev_fy3
    Else NULL
  End As fy_cru,
  -- Current calendar fields
  cal.curr_fy, cal.yesterday
From table(ksm_pkg.tbl_klc_history) klc
Cross Join v_current_calendar cal
Left Join v_af_donors_5fy_summary af On klc.household_id = af.id_hh_src_dnr
;
