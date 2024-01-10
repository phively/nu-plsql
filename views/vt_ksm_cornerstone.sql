Create Or Replace View vt_ksm_cornerstone As

With

cornerstone As (
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
  , cal.curr_fy
From cornerstone
Cross Join rpt_pbh634.v_current_calendar cal
Inner Join rpt_pbh634.v_entity_ksm_households_fast hhf
  On hhf.id_number = cornerstone.id_number
-- Role is apparently saved under school_code; don't ask

