Create Or Replace View vt_ksm_cornerstone As

With

hhf As (
  Select *
  From rpt_pbh634.v_entity_ksm_households_fast
)

, cornerstone As (
  Select
    gc.gift_club_id_number
      As id_number
    , gc.gift_club_code
    , tms_gct.club_desc
      As gift_club_desc
    , gc.gift_club_status
    , tms_gcs.short_desc
      As gift_club_status_desc
    , tms_mem.level_code
      As role_code
    , tms_mem.short_desc
      As role_desc
    , rpt_pbh634.ksm_pkg_tmp.to_date2(gc.gift_club_start_date, 'YYYYMMDD')
      As gift_club_start_date
    , rpt_pbh634.ksm_pkg_tmp.to_date2(gc.gift_club_end_date, 'YYYYMMDD')
      As gift_club_end_date
    , gc.gift_club_comment
    , gc.gift_club_partner_id
    , trunc(gc.date_added)
      As date_added
    , trunc(gc.date_modified)
      As date_modified
    , gc.operator_name
  From gift_clubs gc
  Inner Join tms_gift_club_table tms_gct
    On tms_gct.club_code = gc.gift_club_code
  Left Join tms_gift_club_status tms_gcs
    On tms_gcs.gift_club_status_code = gc.gift_club_status
  Left Join nu_mem_v_tmsclublevel tms_mem
    On tms_mem.level_code = gc.school_code
  Where gift_club_code = 'KCD'
)

, cash_giving As (
  Select Distinct
    hhf.household_id
    , cash.*
  From rpt_pbh634.v_ksm_giving_cash cash
  Inner Join hhf
    On hhf.id_number = cash.id_number
  Inner Join cornerstone
    On cornerstone.id_number = cash.id_number
  Where cash.fiscal_year Between cash.curr_fy - 3 And cash.curr_fy
)

, cash_agg As (
  Select
    cg.household_id
    , cg.cash_category
    , sum(Case When cg.fiscal_year = cg.curr_fy - 0 Then cg.legal_amount Else 0 End)
      As giving_cfy
    , sum(Case When cg.fiscal_year = cg.curr_fy - 1 Then cg.legal_amount Else 0 End)
      As giving_pfy1
    , sum(Case When cg.fiscal_year = cg.curr_fy - 2 Then cg.legal_amount Else 0 End)
      As giving_pfy2
    , sum(Case When cg.fiscal_year = cg.curr_fy - 3 Then cg.legal_amount Else 0 End)
      As giving_pfy3
    , sum(Case When cg.fiscal_year = cg.curr_fy - 1 And cg.fytd_ind = 'Y' Then cg.legal_amount Else 0 End)
      As giving_pfy1_ytd
    , sum(Case When cg.fiscal_year = cg.curr_fy - 2 And cg.fytd_ind = 'Y' Then cg.legal_amount Else 0 End)
      As giving_pfy2_ytd
    , sum(Case When cg.fiscal_year = cg.curr_fy - 3 And cg.fytd_ind = 'Y' Then cg.legal_amount Else 0 End)
      As giving_pfy3_ytd
  From cash_giving cg
  Group By cg.household_id
    , cg.cash_category
)

Select
  hhf.household_id
  , hhf.household_rpt_name
  , hhf.household_primary
  , cornerstone.id_number
  , hhf.report_name
  , hhf.institutional_suffix
  , hhf.spouse_id_number
  , hhf.spouse_report_name
  , hhf.spouse_suffix
  , cornerstone.gift_club_code
  , cornerstone.gift_club_desc
  , cornerstone.gift_club_status
  , cornerstone.gift_club_status_desc
  , cornerstone.role_code
  , cornerstone.role_desc
  , rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(cornerstone.gift_club_end_date)
    As cornerstone_end_fy
  , cornerstone.gift_club_start_date
  , cornerstone.gift_club_end_date
  , cornerstone.gift_club_comment
  , cornerstone.gift_club_partner_id
  , cornerstone.date_added
  , cornerstone.date_modified
  , cornerstone.operator_name
  , expendable.giving_cfy
    As expendable_cfy
  , expendable.giving_pfy1
    As expendable_pfy1
  , expendable.giving_pfy2
    As expendable_pfy2
  , expendable.giving_pfy3
    As expendable_pfy3
  , expendable.giving_pfy1_ytd
    As expendable_pfy1_ytd
  , expendable.giving_pfy2_ytd
    As expendable_pfy2_ytd
  , expendable.giving_pfy3_ytd
    As expendable_pfy3_ytd
  , cal.curr_fy
From cornerstone
Cross Join rpt_pbh634.v_current_calendar cal
Inner Join hhf
  On hhf.id_number = cornerstone.id_number
Left Join cash_agg expendable
  On expendable.household_id = hhf.household_id
  And expendable.cash_category = 'Expendable'

