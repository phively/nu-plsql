With

-- Primary employment
prim_emp As (
  Select
    id_number
    , job_title
    , trim(employer_name1 || ' ' || employer_name2) As employer_name
    , self_employ_ind
    , matching_status_ind
    , tms_pl.short_desc As position_level
    , tms_fld.short_desc As fld_of_work
    , tms_spec1.short_desc As fld_of_spec1
    , tms_spec2.short_desc As fld_of_spec2
    , tms_spec3.short_desc As fld_of_spec3
  From employment
  Left Join tms_position_level tms_pl On tms_pl.position_level_code = employment.position_level_code
  Left Join tms_fld_of_work tms_fld On tms_fld.fld_of_work_code = employment.fld_of_work_code
  Left Join tms_fld_of_spec tms_spec1 On tms_spec1.fld_of_spec_code = employment.fld_of_spec_code1
  Left Join tms_fld_of_spec tms_spec2 On tms_spec2.fld_of_spec_code = employment.fld_of_spec_code2
  Left Join tms_fld_of_spec tms_spec3 On tms_spec3.fld_of_spec_code = employment.fld_of_spec_code3
  Where primary_emp_ind = 'Y'
  And job_status_code = 'C'
)

-- Main query
Select
  ml.id_number
  , deg.report_name
  , prs.business_title
  , trim(prs.employer_name1 || ' ' || prs.employer_name2) As business_name
  , prim_emp.job_title
  , prim_emp.employer_name
  , deg.degrees_concat
  , entity.institutional_suffix
  , prs.prospect_manager
  , prs.pref_city
  , prs.pref_state
  , v_addr_continents.country As pref_country
  , tms_mlc.short_desc As mailing_list
  , ml.mail_list_status_code As mailing_list_status
  , ml.mail_list_src_code
From mailing_list ml
Inner Join tms_mail_list_code tms_mlc
  On tms_mlc.mail_list_code_code = ml.mail_list_code
Inner Join entity
  On entity.id_number = ml.id_number
Inner Join nu_prs_trp_prospect prs
  On prs.id_number = ml.id_number
Left Join v_entity_ksm_degrees deg
  On deg.id_number = ml.id_number
Left Join v_addr_continents
  On v_addr_continents.country_code = prs.preferred_country
Left Join prim_emp
  On prim_emp.id_number = prs.id_number
Where mail_list_code = '100'
  And (
    -- Put in by KSM staff
    mail_list_src_code = 'KSM'
    -- Has a KSM degree
    Or deg.degrees_concat Is Not Null
  )
