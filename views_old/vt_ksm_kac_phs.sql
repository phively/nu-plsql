create or replace view vt_ksm_kac_phs as
With KSM_Spec AS (Select comm.id_number,
       comm.committee_code,
       comm.committee_status_code,
       comm.start_dt
From committee comm
Where comm.committee_code IN ('KPH', 'KACNA')
And comm.committee_status_code = 'C'),

employ As (
  Select id_number
  , job_title
  , employment.fld_of_work_code
  , fow.short_desc As fld_of_work
  , employer_name1,
    -- If there's an employer ID filled in, use the entity name
    Case
      When employer_id_number Is Not Null And employer_id_number != ' ' Then (
        Select pref_mail_name
        From entity
        Where id_number = employer_id_number)
      -- Otherwise use the write-in field
      Else trim(employer_name1 || ' ' || employer_name2)
    End As employer_name
  From employment
  Left Join tms_fld_of_work fow
       On fow.fld_of_work_code = employment.fld_of_work_code
  Where employment.primary_emp_ind = 'Y'
)

Select house.ID_NUMBER,
       house.REPORT_NAME,
       KSM_spec.committee_code,
       KSM_spec.committee_status_code,
       KSM_spec.start_dt,
       entity.record_type_code,
       entity.record_status_code,
       house.FIRST_KSM_YEAR,
       house.PROGRAM,
       house.PROGRAM_GROUP,
       entity.gender_code,
       Employ.fld_of_work,
       Employ.employer_name,
       Employ.job_title,
       house.HOUSEHOLD_CITY,
       house.HOUSEHOLD_STATE,
       house.HOUSEHOLD_ZIP,
       house.HOUSEHOLD_GEO_CODES,
       house.HOUSEHOLD_COUNTRY,
       house.HOUSEHOLD_CONTINENT,
       assignment.prospect_manager,
       assignment.lgos,
       rpt_pbh634.v_ksm_prospect_pool.mgo_pr_score,
       rpt_pbh634.v_ksm_prospect_pool.mgo_pr_model,
       give.NGC_LIFETIME,
       give.NGC_CFY,
       give.NGC_PFY1,
       give.NGC_PFY2,
       give.NGC_PFY3,
       give.NGC_PFY4,
       give.NGC_PFY5,
       give.AF_CFY,
       give.AF_PFY1,
       give.AF_PFY2,
       give.AF_PFY3,
       give.AF_PFY4,
       give.AF_PFY5,
       give.LAST_GIFT_DATE,
       give.LAST_GIFT_TYPE,
       give.LAST_GIFT_ALLOC_CODE
From rpt_pbh634.v_entity_ksm_households house
inner Join KSM_spec ON KSM_spec.id_number = house.id_number
left join entity on entity.id_number = house.ID_NUMBER
left join rpt_pbh634.v_assignment_summary assignment on assignment.id_number = house.ID_NUMBER
left join employ on employ.id_number = house.ID_NUMBER
left join rpt_pbh634.v_ksm_prospect_pool on rpt_pbh634.v_ksm_prospect_pool.ID_NUMBER = house.ID_NUMBER
left join  rpt_pbh634.v_ksm_giving_summary give on give.ID_NUMBER = house.id_number
Order by house.REPORT_NAME ASC
;
