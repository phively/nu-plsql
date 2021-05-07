-- All activities
Create Or Replace View v_nu_activities_fast As

Select
  entity.id_number
  , entity.report_name
  , entity.person_or_org
  , entity.institutional_suffix
  , deg.degrees_concat
  , deg.first_ksm_year
  , deg.program_group
  , activity.activity_code
  , activity.xsequence
  , tms_at.short_desc
    As activity_desc
  , Case When tms_at.short_desc Like '%KSM%' Then 'Y' End
    As ksm_activity
  , activity.activity_participation_code
  , ksm_pkg.to_date2(activity.start_dt)
    As start_dt
  , ksm_pkg.to_date2(activity.stop_dt)
    As stop_dt
  , trunc(activity.date_added)
    As date_added
  , trunc(activity.date_modified)
    As date_modified
  -- FY is based on start/stop date if available, else date added
  , Case
      When ksm_pkg.to_date2(activity.start_dt) Is Not Null
        Then ksm_pkg.get_fiscal_year(ksm_pkg.to_date2(activity.start_dt))
      Else ksm_pkg.get_fiscal_year(activity.date_added)
      End
    As start_fy_calc
  , Case
      When ksm_pkg.to_date2(activity.stop_dt) Is Not Null
        Then ksm_pkg.get_fiscal_year(ksm_pkg.to_date2(activity.stop_dt))
      Else ksm_pkg.get_fiscal_year(activity.date_added)
      End
    As stop_fy_calc
  , activity.xcomment
From activity
Inner Join entity
  On entity.id_number = activity.id_number
Left Join v_entity_ksm_degrees deg
  On deg.id_number = activity.id_number
Inner Join tms_activity_table tms_at
  On tms_at.activity_code = activity.activity_code
;

-- All activities householded
Create Or Replace View v_nu_activities As

Select
  hh.household_id
  , hh.household_rpt_name
  , hh.household_primary
  , hh.id_number
  , hh.report_name
  , hh.person_or_org
  , hh.institutional_suffix
  , hh.degrees_concat
  , hh.first_ksm_year
  , hh.program_group
  , naf.activity_code
  , naf.xsequence
  , naf.activity_desc
  , naf.ksm_activity
  , naf.activity_participation_code
  , naf.start_dt
  , naf.stop_dt
  , naf.date_added
  , naf.date_modified
  -- FY is based on start/stop date if available, else date added
  , naf.start_fy_calc
  , naf.stop_fy_calc
  , naf.xcomment
From v_nu_activities_fast naf
Inner Join v_entity_ksm_households hh
  On hh.id_number = naf.id_number
;

-- Student activities
Create Or Replace View v_nu_student_activities As

Select 
  entity.id_number
  , entity.report_name
  , entity.person_or_org
  , entity.institutional_suffix
  , deg.degrees_concat
  , deg.first_ksm_year
  , deg.program_group
  , sa.student_activity_code
  , sa.xsequence
  , tsa.short_desc
    As student_activity_desc
  , tsa.owner_usergroup
  , Case When tsa.owner_usergroup = 'KO' Then 'Y' End
    As ksm_student_activity
  , sa.student_particip_code
  , ksm_pkg.to_date2(sa.start_dt)
    As start_dt
  , ksm_pkg.to_date2(sa.stop_dt)
    As stop_dt
  , trunc(sa.date_added)
    As date_added
  , trunc(sa.date_modified)
    As date_modified
  -- FY is based on start/stop date if available, else date added
  , Case
      When ksm_pkg.to_date2(sa.start_dt) Is Not Null
        Then ksm_pkg.get_fiscal_year(ksm_pkg.to_date2(sa.start_dt))
      Else ksm_pkg.get_fiscal_year(sa.date_added)
      End
    As start_fy_calc
  , Case
      When ksm_pkg.to_date2(sa.stop_dt) Is Not Null
        Then ksm_pkg.get_fiscal_year(ksm_pkg.to_date2(sa.stop_dt))
      Else ksm_pkg.get_fiscal_year(sa.date_added)
      End
    As stop_fy_calc
  , sa.xcomment
From entity
Inner Join student_activity sa
  On sa.id_number = entity.id_number
Inner Join tms_student_act tsa
  On tsa.student_activity_code = sa.student_activity_code
Left Join v_entity_ksm_degrees deg
  On deg.id_number = entity.id_number
;
