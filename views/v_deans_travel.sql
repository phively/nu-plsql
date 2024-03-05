Create or Replace View v_deans_travel as 

with p as (select *
from rpt_pbh634.VT_KSM_PRS_Pool),


--- Assigned LGOS
assign as (select assign.id_number,
       assign.lgos
from rpt_pbh634.v_assignment_summary assign),

--- C Suite Alumni

csuite As (
  Select id_number
  , job_title
  , employment.fld_of_work_code
  , fow.short_desc As fld_of_work
  , employer_name1,
    Case
      When employer_id_number Is Not Null And employer_id_number != ' ' Then (
        Select pref_mail_name
        From entity
        Where id_number = employer_id_number)
      Else trim(employer_name1 || ' ' || employer_name2)
    End As employer_name
  From employment
  Left Join tms_fld_of_work fow
       On fow.fld_of_work_code = employment.fld_of_work_code
  Where employment.primary_emp_ind = 'Y'
  And (UPPER(employment.job_title) LIKE '%CHIEF%'
    OR  UPPER(employment.job_title) LIKE '%CMO%'
    OR  UPPER(employment.job_title) LIKE '%CEO%'
    OR  UPPER(employment.job_title) LIKE '%CFO%'
    OR  UPPER(employment.job_title) LIKE '%COO%'
    OR  UPPER(employment.job_title) LIKE '%CIO%')
),

--- Liam's Model Score
armod as (Select en.ID_NUMBER,
en.AE_MODEL_SCORE
From rpt_pbh634.v_ksm_model_alumni_engagement en),

--- Interest Listagged
intr as (select interest.id_number,
Listagg (TMS_INTEREST.short_desc, ';  ') Within Group (Order By TMS_INTEREST.short_desc) As short_desc
from interest
left join tms_interest on tms_interest.interest_code = interest.interest_code
group by interest.id_number),

--- Dean Basic Subquery First

dean as (select cr.credited,
       cr.credited_name,
       cr.contact_credit_type,
       cr.contact_credit_desc,
       cr.job_title,
       cr.employer_unit,
       cr.contact_type_code,
       cr.contact_type,
       cr.contact_purpose,
       cr.report_id,
       cr.id_number,
       cr.contacted_name,
       cr.report_name,
       cr.prospect_id,
       cr.primary_ind,
       cr.prospect_name,
       cr.prospect_name_sort,
       cr.contact_date,
       cr.fiscal_year,
       cr.description,
       cr.summary,
       cr.officer_rating,
       cr.evaluation_rating,
       cr.university_strategy,
       cr.ard_staff,
       cr.frontline_ksm_staff,
       cr.contact_type_category,
       cr.visit_type,
       cr.rating_bin,
       cr.curr_fy,
       cr.prev_fy_start,
       cr.curr_fy_start,
       cr.next_fy_start,
       cr.yesterday,
       cr.ninety_days_ago
from rpt_pbh634.v_contact_reports_fast cr
where cr.credited = '0000804796'
and cr.contact_type_code IN ('V','E')),

--- Recent Dean VISITS
c as (select
    dean.id_number,
    max (dean.credited) keep (dense_rank first order by contact_date desc) as credited_ID,
    max (dean.credited_name) keep (dense_rank first order by contact_date desc) as credited_name,
    max (dean.contact_type) keep (dense_rank first order by contact_date desc) as contact_type,
    max (dean.contact_purpose) keep (dense_rank first order by contact_date desc) as contact_purpose,
    max (dean.contacted_name) keep (dense_rank first order by contact_date desc) as contact_name,
    max (dean.prospect_name) keep (dense_rank first order by contact_date desc) as prospect_name,
    max (dean.contact_date) keep (dense_rank first order by contact_date desc) as contact_date,
    max (dean.description) keep (dense_rank first order by contact_date desc) as description_,
    max (dean.summary) keep (dense_rank first order by contact_date desc) as summary
from dean 
where dean.contact_type_code = 'V'
group by dean.id_number),


---Finding Additonal Faculty and Staff (Outside of KSM ARD)
KSM_Faculty_Staff as (select aff.id_number,
       TMS_AFFIL_CODE.short_desc as affilation_code,
       tms_affiliation_level.short_desc as affilation_level
FROM  affiliation aff
LEFT JOIN TMS_AFFIL_CODE ON TMS_AFFIL_CODE.affil_code = aff.affil_code
Left JOIN tms_affiliation_level ON tms_affiliation_level.affil_level_code = aff.affil_level_code
--- Staff that are KSM Alumni
inner join rpt_pbh634.v_entity_ksm_degrees d on d.ID_NUMBER = aff.id_number
 WHERE  aff.affil_code = 'KM'
   AND (aff.affil_level_code = 'ES'
    OR  aff.affil_level_code = 'EF')),

     

--- Final subquery since the propsect pool is slow

final as (select entity.id_number,
a.lgos,
csuite.job_title,
csuite.employer_name,
armod.AE_MODEL_SCORE,
intr.short_desc as interest,
c.credited_ID,
c.credited_name,
c.contact_type,
c.contact_purpose,
c.contact_name,
c.contact_date,
c.description_,
c.summary,
case when kfs.id_number is not null then 'KSM_Faculty_staff' end as KSM_Faculty_staff
from entity 
left join assign a on a.id_number = entity.id_number
left join csuite on csuite.id_number = entity.id_number
left join armod on armod.id_number = entity.id_number
left join intr on intr.id_number = entity.id_number
left join c on c.id_number = entity.id_number
left join KSM_Faculty_Staff kfs on kfs.id_number = entity.id_number)



--- A lot of Melanie's columns already in prospect pool 

select p.ID_NUMBER,
       p.REPORT_NAME,
       p.PREF_MAIL_NAME,
       p.RECORD_STATUS_CODE,
       p.DEGREES_CONCAT,
       p.FIRST_KSM_YEAR,
       p.PROGRAM,
       p.PROGRAM_GROUP,
       p.LAST_NONCERT_YEAR,
       p.INSTITUTIONAL_SUFFIX,
       p.SPOUSE_ID_NUMBER,
       p.SPOUSE_REPORT_NAME,
       p.SPOUSE_PREF_MAIL_NAME,
       p.SPOUSE_SUFFIX,
       p.SPOUSE_DEGREES_CONCAT,
       p.SPOUSE_FIRST_KSM_YEAR,
       p.SPOUSE_PROGRAM,
       p.SPOUSE_PROGRAM_GROUP,
       p.SPOUSE_LAST_NONCERT_YEAR,
       p.FMR_SPOUSE_ID,
       p.FMR_SPOUSE_NAME,
       p.FMR_MARITAL_STATUS,
       p.HOUSEHOLD_ID,
       p.HOUSEHOLD_PRIMARY,
       p.HOUSEHOLD_RECORD,
       p.PERSON_OR_ORG,
       p.HOUSEHOLD_NAME,
       p.HOUSEHOLD_RPT_NAME,
       p.HOUSEHOLD_SPOUSE_ID,
       p.HOUSEHOLD_SPOUSE,
       p.HOUSEHOLD_SPOUSE_RPT_NAME,
       p.HOUSEHOLD_LIST_FIRST,
       p.HOUSEHOLD_LIST_SECOND,
       p.HOUSEHOLD_SUFFIX,
       p.HOUSEHOLD_SPOUSE_SUFFIX,
       p.HOUSEHOLD_KSM_YEAR,
       p.HOUSEHOLD_MASTERS_YEAR,
       p.HOUSEHOLD_LAST_MASTERS_YEAR,
       p.HOUSEHOLD_PROGRAM,
       p.HOUSEHOLD_PROGRAM_GROUP,
       p.XSEQUENCE,
       p.HOUSEHOLD_CITY,
       p.HOUSEHOLD_STATE,
       p.HOUSEHOLD_ZIP,
       p.HOUSEHOLD_GEO_CODES,
       p.HOUSEHOLD_GEO_PRIMARY,
       p.HOUSEHOLD_GEO_PRIMARY_DESC,
       p.HOUSEHOLD_COUNTRY,
       p.HOUSEHOLD_CONTINENT,
       p.BUSINESS_TITLE,
       p.EMPLOYER_NAME,
       p.PREF_ADDR_TYPE,
       p.PREF_CITY,
       p.PREF_STATE,
       p.PREFERRED_COUNTRY,
       p.BUSINESS_CITY,
       p.BUSINESS_STATE,
       p.BUSINESS_COUNTRY,
       p.HOME_CITY,
       p.HOME_STATE,
       p.HOME_COUNTRY,
       p.PROSPECT_ID,
       p.PRIMARY_IND,
       p.PROSPECT_NAME,
       p.PROSPECT_NAME_SORT,
       p.UNIVERSITY_STRATEGY,
       p.STRATEGY_SCHED_DATE,
       p.STRATEGY_RESPONSIBLE,
       p.DQ,
       p.DQ_DATE,
       p.PERMANENT_STEWARDSHIP,
       p.DNS,
       p.EVALUATION_RATING,
       p.EVALUATION_DATE,
       p.OFFICER_RATING,
       p.UOR,
       p.UOR_DATE,
       p.UOR_EVALUATOR_ID,
       p.UOR_EVALUATOR,
       p.AF_10K_MODEL,
       p.AF_10K_SCORE,
       p.MGO_ID_MODEL,
       p.MGO_ID_SCORE,
       p.MGO_PR_MODEL,
       p.MGO_PR_SCORE,
       p.PROSPECT_MANAGER_ID,
       p.PROSPECT_MANAGER,
       p.TEAM,
       p.PROSPECT_STAGE,
       p.CONTACT_DATE,
       p.CONTACT_AUTHOR,
       p.MANAGER_IDS,
       p.MANAGERS,
       p.CURR_KSM_MANAGER,
       p.HH_PRIMARY,
       p.RATING_NUMERIC,
       p.RATING_BIN,
       p.EVAL_RATING_BIN,
       p.NU_LIFETIME_RECOGNITION,
       p.KSM_PROSPECT_INTEREST_FLAG,
       p.POOL_GROUP,
       p.CAMPAIGN_GIVING,
       p.CAMPAIGN_GIVING_RECOGNITION,
       p.KSM_LIFETIME_RECOGNITION,
       p.AF_STATUS,
       p.AF_CFY,
       p.AF_PFY1,
       p.AF_PFY2,
       p.AF_PFY3,
       p.AF_PFY4,
       p.NGC_CFY,
       p.NGC_PFY1,
       p.NGC_PFY2,
       p.NGC_PFY3,
       p.NGC_PFY4,
       p.LAST_GIFT_TX_NUMBER,
       p.LAST_GIFT_DATE,
       p.LAST_GIFT_TYPE,
       p.LAST_GIFT_RECOGNITION_CREDIT,
       p.latitude,
       p.longitude,
       p.open_proposals,
       p.open_ksm_proposals,
       p.total_asks,
       p.total_anticipated,
       p.total_ksm_asks,
       p.total_ksm_anticipated,
       p.most_recent_proposal_id,
       p.recent_proposal_manager,
       p.recent_proposal_assist,
       p.recent_proposal_status,
       p.recent_start_date,
       p.recent_ask_date,
       p.recent_close_date,
       p.recent_date_modified,
       p.recent_ksm_ask,
       p.recent_ksm_anticipated,
       p.next_proposal_id,
       p.next_proposal_manager,
       p.next_close_date,
       p.next_ksm_ask,
       p.next_ksm_anticipated,
       p.ard_visit_last_365_days,
       p.ard_contact_last_365_days,
       p.last_visit_credited_name,
       p.last_visit_credited_unit,
       p.last_visit_credited_ksm,
       p.last_visit_contact_type,
       p.last_visit_category,
       p.last_visit_date,
       p.last_visit_purpose,
       p.last_visit_type,
       p.last_visit_desc,
       p.last_credited_name,
       p.last_credited_unit,
       p.last_credited_ksm,
       p.last_contact_type,
       p.last_contact_category,
       p.last_contact_date,
       p.last_contact_purpose,
       p.last_contact_desc,
       p.last_assigned_credited_name,
       p.last_assigned_credited_unit,
       p.last_assigned_credited_ksm,
       p.last_assigned_contact_type,
       p.last_assigned_contact_category,
       p.last_assigned_contact_date,
       p.last_assigned_contact_purpose,
       p.last_assigned_contact_desc,
       p.tasks_open,
       p.tasks_open_ksm,
       p.tasks_open_ksm_outreach,
       p.task_outreach_next_id,
       p.task_outreach_sched_date,
       p.task_outreach_responsible,
       p.task_outreach_desc,
       p.yesterday,
       p.curr_fy,
       final.lgos,
final.job_title as c_suite_job_title,
final.employer_name as c_suite_employer_name,
final.AE_MODEL_SCORE,
final.interest,
final.credited_ID,
final.credited_name,
final.contact_type,
final.contact_purpose,
final.contact_name,
final.contact_date,
final.description_,
final.summary,
final.KSM_Faculty_staff
from p
inner join final on final.id_number = p.id_number 
