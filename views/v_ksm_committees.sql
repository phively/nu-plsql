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
  , tms_chs.committee_selection_code
  , tms_chs.short_desc
    As committee_selection
  , tms_cs.committee_status_code
  , tms_cs.short_desc
    As committee_status
  -- Parse dates
  , committee.start_dt
  , ksm_pkg.date_parse(committee.start_dt, committee.date_added)
    As start_dt_calc
  , committee.stop_dt
  , ksm_pkg.date_parse(committee.stop_dt, committee.date_modified)
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

Create Or Replace View v_ksm_committees As
Select
  id_number
  , xsequence
  , committee_code
  , committee_desc
  , committee_type_code
  , committee_type
  , committee_selection_code
  , committee_selection
  , committee_status_code
  , committee_status
  , start_dt
  , start_dt_calc
  , stop_dt
  , stop_dt_calc
  , date_added
  , date_modified
  , committee_title
  , committee_role_code
  , committee_role
  , committee_role_xsequence
  , geo_code
  , xcomment
From v_nu_committees
Where upper(committee_desc) Like '%KSM%'
  Or upper(committee_desc) Like '%KELLOGG%'
;
