Create or Replace View v_deans_travel as 

with p as (select *
from rpt_pbh634.VT_KSM_PRS_Pool p ),

G as (Select
gc.*
From table(rpt_pbh634.ksm_pkg_tmp.tbl_geo_code_primary) gc
Inner Join address
On address.id_number = gc.id_number
And address.xsequence = gc.xsequence),

CO as (select *
from RPT_PBH634.v_addr_continents),

--- Melanie wants primary address geo - it's not in prospect

prime as (Select DISTINCT
         a.Id_number
      ,  tms_address_type.short_desc AS primary_Address_Type
      ,  a.city as primary_city
      ,  a.state_code as primary_state_code
      ,  CO.country as primary_country
      ,  G.GEO_CODE_PRIMARY_DESC AS PRIMARY_GEO_CODE
      FROM address a
      LEFT JOIN tms_addr_status ON tms_addr_status.addr_status_code = a.addr_status_code
      LEFT JOIN tms_address_type ON tms_address_type.addr_type_code = a.addr_type_code
      LEFT JOIN tms_country ON tms_country.country_code = a.country_code
      LEFT JOIN CO ON CO.country_code = A.COUNTRY_CODE
      LEFT JOIN g ON g.id_number = A.ID_NUMBER
      AND g.xsequence = a.xsequence
      WHERE a.addr_status_code = 'A'
      --- Primary Country
      and a.addr_pref_IND = 'Y'),


--- Non Primary Business
Business As(Select DISTINCT
        a.Id_number
      ,  max(tms_address_type.short_desc) AS Address_Type
      ,  max(a.city) as business_city
      ,  max (a.state_code) as business_state_code
      ,  max (CO.country) as business_country
      ,  max (G.GEO_CODE_PRIMARY_DESC) AS BUSINESS_GEO_CODE
      FROM address a
      LEFT JOIN tms_addr_status ON tms_addr_status.addr_status_code = a.addr_status_code
      LEFT JOIN tms_address_type ON tms_address_type.addr_type_code = a.addr_type_code
      LEFT JOIN tms_country ON tms_country.country_code = a.country_code
      LEFT JOIN CO ON CO.country_code = A.COUNTRY_CODE
      LEFT JOIN g ON g.id_number = A.ID_NUMBER
      AND g.xsequence = a.xsequence
      WHERE (a.addr_status_code = 'A'
      and a.addr_pref_IND = 'N'
      AND a.addr_type_code = 'B')
      Group By a.id_number),


--- Assignment Revision: Now include the Office, so we will use this subquery for PM/LGOs
assign as (select assign.id_number,
assign.prospect_manager,
assign.lgos,
a.office_code,
assign.manager_ids,
assign.managers,
assign.curr_ksm_manager,
TMS_OFFICE.short_desc
from rpt_pbh634.v_assignment_summary assign
left join assignment a on a.id_number = assign.id_number 
left join TMS_OFFICE ON TMS_OFFICE.office_code = a.office_code 
),


--- employment general

em As (
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
  Where employment.primary_emp_ind = 'Y')
  
  ,

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
and cr.contact_type_code = 'V'),

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

--- Count of Dean Visits

dvisit as (select dean.id_number,
count (dean.report_id) as count_dean_visit 
from dean 
group by dean.id_number),


--- Dean Event 

de as (select e.id_number,
       e.first_name,
       e.last_name,
       e.Faculty_Job_Title,
       e.Faculty_Employer,
       e.faculty_job_status,
       e.faculty_start_date_employment,
       e.Volunteer_role_of_event,
       e.event_id,
       e.event_name,
       e.event_start_date,
       e.event_start_year,
       e.event_type_description,
       e.event_organizers
from v_ksm_faculty_events e 
where e.id_number = '0000804796'),

defin as (select distinct p.id_number,
       p.event_name,
       p.start_dt
from rpt_pbh634.v_nu_event_participants_fast p
inner join de on de.event_id = p.event_id), 

--- Count of Folks in Francesca Events 

fran as (select distinct defin.id_number,
count (defin.id_number) as count_dean_events
from defin 
group by defin.id_number),



/*

--- No Longer Needed 

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
*/


--- Modified After Review with Paul (4/10/24)

-- Suggestion: defensive coding. We can clean up dirty data by deduping ahead of time, before the listagg
-- SELECT DISTINCT, then remove every field that is not used in your listagg() because the extra row might be creating dupes
m as (--SELECT h.prospect_id,
        SELECT DISTINCT
       h.id_number,
       --h.report_name,
       h.assignment_type,  
       h.assignment_report_name,
       h.office_desc
FROM rpt_pbh634.v_assignment_history h
WHERE assignment_active_calc = 'Active'),

-- prospect Manager

pm as (select *
from m
where m.assignment_type = 'PM'),

--- Lgo 
lgo as (select *
from m
where m.assignment_type = 'LG'),

--- Managers NOT PM and LGO

o as (select *
from m
where m.assignment_type NOT IN ('PM','LG')),

ostag as (select o.id_number,
Listagg (o.assignment_report_name, ';  ') 
       Within Group (Order By o.assignment_type) As assignment_report_name,
Listagg (o.assignment_type, ';  ') 
       Within Group (Order By o.assignment_type) As assignment_type,       
Listagg (o.office_desc, ';  ') 
       Within Group (Order By o.assignment_type) As office_desc
from o 
where o.id_number is not null 
group by o.id_number),

final_manage as (
select entity.id_number,
pm.assignment_report_name as prospect_manager,
pm.assignment_type as pm_assign_type,
pm.office_desc as office,
lgo.assignment_report_name as lgo,
lgo.assignment_type as lgo_assign_type,
lgo.office_desc as lgo_office,
ostag.assignment_report_name as other_manager,
ostag.assignment_type as other_assign_type,
ostag.office_desc as other_office
from entity 
left join pm on pm.id_number = entity.id_number
left join lgo on lgo.id_number = entity.id_number
left join ostag on ostag.id_number = entity.id_number),

tran as (select distinct HH.ID_NUMBER
FROM rpt_pbh634.v_ksm_giving_trans_hh HH
where HH.PLEDGE_STATUS = 'A'),


--- Melanie sent me a list of committees, zach had code for this already! 

 GAB as (
select gab.id_number
      ,'GAB' as GAB_indicator
from table(rpt_pbh634.ksm_pkg_tmp.tbl_committee_gab) gab
)

, REAC as (
select reac.id_number
      ,'REAC' as REAC_indicator
from table(rpt_pbh634.ksm_pkg_tmp.tbl_committee_realEstCouncil) reac
)

, AMP as (
select amp.id_number
     ,'AMP' as AMP_indicator
from table(rpt_pbh634.ksm_pkg_tmp.tbl_committee_amp) amp
)

, HCAK as (
select hcak.id_number
      ,'HCAK' as HCAK_indicator
from table(rpt_pbh634.ksm_pkg_tmp.tbl_committee_healthcare) hcak 
)

, PEAC as (
select peac.id_number
      ,'PEAC' as PEAC_indicator
from table(rpt_pbh634.ksm_pkg_tmp.tbl_committee_privateEquity) peac
)

, EBFA as (
select ebfa.id_number
       ,'EBFA' as EBFA_indicator
from table(rpt_pbh634.ksm_pkg_tmp.tbl_committee_asia) ebfa
)

, PEAC_ASIA as (
select peac_asia.id_number
      ,'PEAC_ASIA' as PEAC_ASIA_indicator
from table(rpt_pbh634.ksm_pkg_tmp.tbl_committee_pe_asia) peac_asia
)


,fcom as (
select e.id_number
      , listagg(GAB.GAB_indicator || Case When GAB.GAB_indicator Is Not Null Then ', ' End ||  
               REAC.REAC_indicator || Case When REAC.REAC_indicator Is Not Null Then ', ' End ||  
               AMP.AMP_indicator || Case When AMP.AMP_indicator Is Not Null Then ', ' End || 
               HCAK.HCAK_indicator || Case When HCAK.HCAK_indicator Is Not Null Then ', ' End ||  
               PEAC.PEAC_indicator || Case When PEAC.PEAC_indicator Is Not Null Then ', ' End ||  
               EBFA.EBFA_indicator || Case When EBFA.EBFA_indicator Is Not Null Then ', ' End ||  
               PEAC_ASIA.PEAC_ASIA_indicator) 
             within group ( order by e.id_number ) as list_agg_committees
from entity e
left join GAB on e.id_number = GAB.id_number
left join REAC on e.id_number = REAC.id_number
left join AMP on e.id_number = AMP.id_number
left join HCAK on e.id_number = HCAK.id_number
left join PEAC on e.id_number = PEAC.id_number
left join EBFA on e.id_number = EBFA.id_number
left join PEAC_Asia on e.id_number = PEAC_Asia.id_number
where GAB.GAB_indicator is not null
or REAC.REAC_indicator is not null
or AMP.AMP_indicator is not null 
or HCAK.HCAK_indicator is not null
or PEAC.PEAC_indicator is not null
or EBFA.EBFA_indicator is not null
or PEAC_ASIA.PEAC_ASIA_indicator is not null
group by e.id_number),


linked as (select distinct ec.id_number,
max(ec.start_dt) keep(dense_rank First Order By ec.start_dt Desc, ec.econtact asc) As Max_Date,
max (ec.econtact) keep(dense_rank First Order By ec.start_dt Desc, ec.econtact asc) as linkedin_address
from econtact ec
where  ec.econtact_status_code = 'A'
and  ec.econtact_type_code = 'L'
Group By ec.id_number),

ard as (
  Select
    vcrf.credited
    , vcrf.credited_name
    , vcrf.contact_credit_type
    , vcrf.contact_credit_desc
    , vcrf.job_title
    , vcrf.employer_unit
    , vcrf.contact_type_code
    , vcrf.contact_type
    , vcrf.contact_purpose
    , vcrf.report_id
    , vcrf.id_number
    , vcrf.contacted_name
    , vcrf.report_name
    , vcrf.prospect_id
    , vcrf.primary_ind
    , vcrf.prospect_name
    , vcrf.prospect_name_sort
    , vcrf.contact_date
    , vcrf.fiscal_year
    , vcrf.description
    , vcrf.summary
    , vcrf.officer_rating
    , vcrf.evaluation_rating
    , vcrf.university_strategy
    , vcrf.ard_staff
    , vcrf.frontline_ksm_staff
    , vcrf.contact_type_category
    , vcrf.visit_type
    , vcrf.rating_bin
    , vcrf.curr_fy
    , vcrf.prev_fy_start
    , vcrf.curr_fy_start
    , vcrf.next_fy_start
    , vcrf.yesterday
    , vcrf.ninety_days_ago
  From rpt_pbh634.v_contact_reports_fast vcrf
  Where ard_staff = 'Y'),

--- Final subquery since the propsect pool is slow

finals as (select distinct entity.id_number,
a.lgos,
csuite.job_title as c_suite_job_title,
csuite.employer_name as c_suite_employer_name,
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
b.business_city,
b.business_state_code, 
b.BUSINESS_GEO_CODE,
b.business_country,
csuite.job_title as csuite_job_title,
csuite.employer_name as csuite_employer_name,
csuite.fld_of_work as csuite_fld_of_work,
em.job_title,
em.employer_name,
em.fld_of_work,
linked.linkedin_address,
case when tran.id_number is not null then 'Y' else 'N' end as plg_active,
fcom.list_agg_committees,
prime.primary_address_type,
prime.primary_city,
prime.primary_state_code,
prime.primary_country,
prime.PRIMARY_GEO_CODE
---case when kfs.id_number is not null then 'KSM_Faculty_staff' end as KSM_Faculty_staff
from entity 
left join assign a on a.id_number = entity.id_number
left join em on em.id_number = entity.id_number
left join csuite on csuite.id_number = entity.id_number
left join armod on armod.id_number = entity.id_number
left join intr on intr.id_number = entity.id_number
left join c on c.id_number = entity.id_number
left join Business b on b.id_number = entity.id_number 
left join tran on tran.id_number = entity.id_number 
left join fcom on fcom.id_number = entity.id_number 
left join prime on prime.id_number = entity.id_number 
left join linked on linked.id_number = entity.id_number 
---left join KSM_Faculty_Staff kfs on kfs.id_number = entity.id_number
)




--- A lot of Melanie's columns already in prospect pool 

select p.ID_NUMBER,
        p.REPORT_NAME,
       p.PREF_MAIL_NAME,
       p.RECORD_STATUS_CODE,
       --- p.DEGREES_CONCAT,
       p.FIRST_KSM_YEAR,
       p.PROGRAM,
       p.PROGRAM_GROUP,
       --- p.LAST_NONCERT_YEAR,
       p.INSTITUTIONAL_SUFFIX,
       p.SPOUSE_ID_NUMBER,
       p.SPOUSE_REPORT_NAME,
       p.SPOUSE_PREF_MAIL_NAME,
       p.SPOUSE_SUFFIX,
      --- p.SPOUSE_DEGREES_CONCAT,
       --p.SPOUSE_FIRST_KSM_YEAR,
       --p.SPOUSE_PROGRAM,
       --p.SPOUSE_PROGRAM_GROUP,
      /*  p.SPOUSE_LAST_NONCERT_YEAR,
       p.FMR_SPOUSE_ID,
       p.FMR_SPOUSE_NAME,
       p.FMR_MARITAL_STATUS,*/  
       p.HOUSEHOLD_ID,
       p.HOUSEHOLD_PRIMARY,
       --- p.HOUSEHOLD_RECORD,
       p.PERSON_OR_ORG,
       /* p.HOUSEHOLD_NAME,
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
       ---p.XSEQUENCE,*/
       p.HOUSEHOLD_CITY,
       p.HOUSEHOLD_STATE,
       p.HOUSEHOLD_ZIP,
       p.HOUSEHOLD_GEO_CODES,
       ---p.HOUSEHOLD_GEO_PRIMARY,
       p.HOUSEHOLD_GEO_PRIMARY_DESC,
       p.HOUSEHOLD_COUNTRY,
       p.HOUSEHOLD_CONTINENT,
       finals.job_title,
       finals.EMPLOYER_NAME,
       finals.linkedin_address,
       --- preferred 
       ---finals.primary_address_type,
       --finals.primary_city,
       finals.primary_state_code,
      -- finals.primary_country,
       finals.primary_geo_code,    
       finals.business_city,
       finals.business_state_code,
       finals.business_geo_code,
       finals.business_country,
       /* p.HOME_CITY,
       p.HOME_STATE,
       p.HOME_COUNTRY, */ 
       p.PROSPECT_ID,
       ---p.PRIMARY_IND,
       p.PROSPECT_NAME,
       ---p.PROSPECT_NAME_SORT,
       p.UNIVERSITY_STRATEGY,
       p.STRATEGY_SCHED_DATE,
       p.STRATEGY_RESPONSIBLE,
       p.DQ,
       ---p.DQ_DATE,
       --- p.PERMANENT_STEWARDSHIP,
       --p.DNS,
       p.EVALUATION_RATING,
       p.EVALUATION_DATE,
       --- p.OFFICER_RATING,
       p.UOR,
       p.UOR_DATE,
      --- p.UOR_EVALUATOR_ID,
       p.UOR_EVALUATOR,
       p.AF_10K_MODEL,
       p.AF_10K_SCORE,
       p.MGO_ID_MODEL,
       ---p.MGO_ID_SCORE,
       p.MGO_PR_MODEL,
       ---p.MGO_PR_SCORE,
       fm.prospect_manager,
       ---fm.pm_assign_type,
       ---fm.office,
       fm.lgo,
       ---fm.lgo_assign_type,
       ---fm.lgo_office,
       ---fm.other_manager,
       ---fm.other_assign_type,
       ---fm.other_office,
       /* Boards and Councils Melanie will send 7/11/24 */
       finals.list_agg_committees,      
       p.TEAM,
       p.PROSPECT_STAGE,
       p.CONTACT_DATE,
       p.CONTACT_AUTHOR,
       ---p.MANAGER_IDS,
       p.HH_PRIMARY,
       p.RATING_NUMERIC,
       p.RATING_BIN,
       p.EVAL_RATING_BIN,
       p.NU_LIFETIME_RECOGNITION,
       ---p.KSM_PROSPECT_INTEREST_FLAG,
       p.POOL_GROUP,
       p.CAMPAIGN_GIVING,
       p.CAMPAIGN_GIVING_RECOGNITION,
       p.KSM_LIFETIME_RECOGNITION,
       p.AF_STATUS,
       p.AF_CFY,
       p.AF_PFY1,
       --p.AF_PFY2,
       --p.AF_PFY3,
       --p.AF_PFY4,
       p.NGC_CFY,
       p.NGC_PFY1,
       ---p.NGC_PFY2,
       ---p.NGC_PFY3,
       ---p.NGC_PFY4,
       ---p.LAST_GIFT_TX_NUMBER,
       p.LAST_GIFT_DATE,
       p.LAST_GIFT_TYPE,
       p.LAST_GIFT_RECOGNITION_CREDIT,
       p.latitude,
       p.longitude,
       p.open_proposals,
       p.open_ksm_proposals,
       finals.plg_active, 
       /* p.total_asks,
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
       p.next_ksm_anticipated, */ 
       p.ard_visit_last_365_days,
       p.ard_contact_last_365_days,
       p.last_visit_credited_name,
       p.last_visit_credited_unit,
       p.last_visit_credited_ksm,
       ---p.last_visit_contact_type,
       ---p.last_visit_category,
       p.last_visit_date,
       ---p.last_visit_purpose,
       ---p.last_visit_type,
       p.last_visit_desc,
       p.last_credited_name,
       ---p.last_credited_unit,
       ---p.last_credited_ksm,
       p.last_contact_type,
       ---p.last_contact_category,
       p.last_contact_date,
       ---p.last_contact_purpose,
       p.last_contact_desc,
       /*p.last_assigned_credited_name,
       p.last_assigned_credited_unit,
       p.last_assigned_credited_ksm,
       p.last_assigned_contact_type,
       p.last_assigned_contact_category,
       p.last_assigned_contact_date,
       p.last_assigned_contact_purpose,
       p.last_assigned_contact_desc,
       p.tasks_open,
       p.tasks_open_ksm,
       p.tasks_open_ksm_outreach,*/
       ---p.task_outreach_next_id,
       ---p.task_outreach_sched_date,
       p.task_outreach_responsible,
       p.task_outreach_desc,
       ---p.yesterday,
       ---p.curr_fy,
       --- Melanie wants case a flag
case when finals.c_suite_job_title is not null then 'Y' end as c_suite_job_title_ind,
---finals.employer_name as c_suite_employer_name,
finals.AE_MODEL_SCORE,
finals.fld_of_work,---- finals.interest, We want fld of work 7/11/24  
fran.count_dean_events,
dvisit.count_dean_visit,
--- Dean Last Visit (Rename)
---finals.credited_ID as credited_ID_dean_LV,
---finals.credited_name as credited_name_dean_LV,
---finals.contact_type as contact_type_dean_LV,
---finals.contact_purpose as contact_purpose_dean_LV,
---finals.contact_name as contact_name_dean_LV,
finals.contact_date as contact_date_dean_LV,
finals.description_ as description_dean_LV,
/*
      ard.credited
    , ard.credited_name
    , ard.contact_credit_type
    , ard.contact_credit_desc
    , ard.job_title
    , ard.employer_unit
    , ard.contact_type_code
    , ard.contact_type
    , ard.contact_purpose
    , ard.report_id
    , ard.id_number
    , ard.contacted_name
    , ard.report_name
    , ard.prospect_id
    , ard.primary_ind
    , ard.prospect_name
    , ard.prospect_name_sort
    , ard.contact_date
    , ard.fiscal_year
    , ard.description
    , ard.summary
    , ard.officer_rating
    , ard.evaluation_rating
    , ard.university_strategy
    , ard.ard_staff
    , ard.frontline_ksm_staff
    , ard.contact_type_category
    , ard.visit_type  */


---finals.summary as summary_dean_LV
--- final.KSM_Faculty_staff
from p
inner join finals on finals.id_number = p.id_number 
left join fran on fran.id_number = p.id_number 
left join dvisit on dvisit.id_number = p.id_number 
left join final_manage fm on fm.id_number = p.id_number 
----left join ard on ard.id_number = p.id_number 