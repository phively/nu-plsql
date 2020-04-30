create or replace view vt_ksm_phs as

With KSM_PHS AS (Select comm.id_number,
       comm.committee_code,
       comm.committee_status_code,
       comm.start_dt
From committee comm
Where comm.committee_code IN ('KPH')
And comm.committee_status_code = 'C')

Select house.ID_NUMBER,
       house.REPORT_NAME,
       KSM_PHS.committee_code,
       KSM_PHS.committee_status_code,
       KSM_PHS.start_dt,
       market.RECORD_STATUS_CODE,
       market.FIRST_KSM_YEAR,
       market.PROGRAM,
       market.PROGRAM_GROUP,
       market.Gender_Code,
       market.fld_of_work_code,
       market.fld_of_work,
       market.employer_name,
       market.job_title,
       market.HOUSEHOLD_CITY,
       market.HOUSEHOLD_STATE,
       market.HOUSEHOLD_ZIP,
       market.HOUSEHOLD_GEO_CODES,
       market.HOUSEHOLD_COUNTRY,
       market.HOUSEHOLD_CONTINENT,
       market.prospect_manager_id,
       market.prospect_manager,
       market.mgo_pr_score,
       market.mgo_pr_model,
       market.assignment_id_number,
       market.Leadership_Giving_Officer,
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
left join vt_alumni_market_sheet market on market.id_number = house.ID_NUMBER
inner Join KSM_PHS ON KSM_PHS.id_number = house.id_number
left join  rpt_pbh634.v_ksm_giving_summary give on give.ID_NUMBER = house.id_number
Order by house.REPORT_NAME ASC;
