-- All activities
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
  , activity.activity_code
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
Inner Join v_entity_ksm_households hh
  On hh.id_number = activity.id_number
Inner Join tms_activity_table tms_at
  On tms_at.activity_code = activity.activity_code
