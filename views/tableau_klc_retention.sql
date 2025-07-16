Create Or Replace View tableau_klc_retention As

Select
  Null household_id
  , Null id_number
  , Null report_name
  , Null degrees_concat
  , Null fiscal_yr
  , Null max_gift_dt
  , Null next_fy_gift
  , Null retained_lfy
  , Null retained_nfy
  , cal.curr_fy
From DUAL
Cross Join v_current_calendar cal
;

/*
-- Pull multiple years of ksm_pkg_klc.tbl_klc_members
With

klc As (
  Select
    id_number
    , fiscal_yr
  From table(rpt_abm1914.ksm_pkg_klc.tbl_klc_members_range(2020, 2025))
)

, last_ksm_gft As (
  Select Distinct
    gt.household_id
    , gt.fiscal_year
    , max(gt.date_of_record)
      As max_gift_dt
    , sum(gt.legal_amount)
      As total_legal_amount
  From rpt_pbh634.v_ksm_giving_trans_hh gt
  Where gt.credit_amount > 0
    And gt.tx_gypm_ind <> 'P'
    And gt.fiscal_year >= 2020
  Group By
    gt.household_id
    , gt.fiscal_year
)

Select
  hhf.household_id
  , klc.id_number
  , hhf.report_name
  , hhf.degrees_concat
  , klc.fiscal_yr
    As fiscal_year
  , lg.max_gift_dt
  , ng.max_gift_dt
    As next_fy_gift
  , Case
      When lg.max_gift_dt Is Not Null
        Then 'Y'
      End
    As retained_lfy
  , Case
      When lg.max_gift_dt Is Not Null
        And ng.max_gift_dt Is Not Null
        Then 'Y'
      End
    As retained_nfy
  , cal.curr_fy
From klc
Cross Join rpt_pbh634.v_current_calendar cal
Inner Join rpt_pbh634.v_entity_ksm_households_fast hhf
  On hhf.id_number = klc.id_number
Left Join last_ksm_gft lg
  On lg.household_id = hhf.household_id
  And lg.fiscal_year = klc.fiscal_yr
  -- Check if gift made following year
Left Join last_ksm_gft ng
  On ng.household_id = hhf.household_id
  And ng.fiscal_year = (klc.fiscal_yr + 1)
*/
