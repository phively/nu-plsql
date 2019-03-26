/************************
Non-householded committees
************************/

Create Or Replace View v_nu_committees As

/* Historical NU committee membership */
Select
  id_number
  , xsequence
  , committee.committee_code
  , committee_header.short_desc
    As committee_desc
  , tms_cht.committee_type_code
  , tms_cht.short_desc
    As committee_type
  , Case
      When upper(committee_header.short_desc) Like '%KSM%'
        Or upper(committee_header.short_desc) Like '%KELLOGG%'
        Then 'Y'
      End
    As ksm_committee
  , tms_chs.committee_selection_code
  , tms_chs.short_desc
    As committee_selection
  , tms_cs.committee_status_code
  , tms_cs.short_desc
    As committee_status
  -- Parse dates
  , committee.start_dt
  -- Start date fallback is date added
  , ksm_pkg.date_parse(committee.start_dt, committee.date_added)
    As start_dt_calc
  , committee.stop_dt
  -- Stop date fallback is date modified for past committees, and end of the FY for current ones
  , Case
      When committee.committee_status_code Not In ('A', 'C')
        Then ksm_pkg.date_parse(committee.stop_dt, committee.date_modified)
      When committee.committee_status_code In ('A', 'C')
        Then ksm_pkg.date_parse(committee.stop_dt, cal.next_fy_start - 1)
      End
    As stop_dt_calc
  , trunc(committee.date_added)
    As date_added
  , trunc(committee.date_modified)
    As date_modified
  , committee_title
  , tms_cr.committee_role_code
  , tms_cr.short_desc
    As committee_role
  , committee_role_xsequence
  , geo_code
  , committee.xcomment
From committee
Cross Join rpt_pbh634.v_current_calendar cal
Inner Join committee_header
  On committee_header.committee_code = committee.committee_code
Left Join tms_committee_header_type tms_cht
  On tms_cht.committee_type_code = committee_header.committee_type_code
Left Join tms_committee_header_selection tms_chs
  On tms_chs.committee_selection_code = committee_header.committee_selection_code
Left Join tms_committee_role tms_cr
  On tms_cr.committee_role_code = committee.committee_role_code
Left Join tms_committee_status tms_cs
  On tms_cs.committee_status_code = committee.committee_status_code
;

/************************
Householded committees
************************/

Create Or Replace View v_nu_committees_hh As

Select
  hh.household_id
  , hh.report_name
  , nuc.*
From v_entity_ksm_households hh
Inner Join v_nu_committees nuc
  On nuc.id_number = hh.id_number
;
