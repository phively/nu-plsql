/* 

The Objective of this view is to identify KSM Faculty Events 

Create or replace view v_ksm_faculty_events  

*/

Create or replace view v_ksm_faculty_events as

--- Using affiliation to identify KSM Faculty members
--- School code KM = Kellogg School of Management 
--- EF Code = Faculty 

with a as (select aff.id_number,
       TMS_AFFIL_CODE.short_desc as affilation_code,
       tms_affiliation_level.short_desc as affilation_level
FROM  affiliation aff
LEFT JOIN TMS_AFFIL_CODE ON TMS_AFFIL_CODE.affil_code = aff.affil_code
LEFT JOIN tms_affiliation_level ON tms_affiliation_level.affil_level_code = aff.affil_level_code
WHERE  aff.affil_code = 'KM'
   AND aff.affil_level_code = 'EF'
),

/* 

Pulling Employment:

There are many different types of faculty members
There are also faculty members whose primary job is NOT Northwestern and/or Kellogg!!!

*/

ksm As (Select employment.id_number
  , employment.job_title
  , employment.employer_name1
  , employment.job_status_code
  , employment.start_dt
  ,
    Case
      When employer_id_number Is Not Null And employer_id_number != ' ' Then (
        Select pref_mail_name
        From entity
        Where id_number = employer_id_number)
      Else trim(employer_name1 || ' ' || employer_name2)
    End As employer_name
  From employment
  --- To get faculty levels
left join tms_position_level 
on tms_position_level.position_level_code = employment.position_level_code 
inner join a on a.id_number = employment.id_number
--- We Want NU Employees and Faculty 
  Where employment.employer_id_number = '0000439808'
  and tms_position_level.short_desc like '%Faculty%'
),

--- Most recent employment to being an NU Faculty Member

fe as (select ksm.id_number,
max (ksm.job_title) keep (dense_rank first order by ksm.start_dt DESC) as Faculty_Job_Title,
max (ksm.employer_name) keep (dense_rank first order by ksm.start_dt DESC) as Faculty_Employer,
max (ksm.start_dt) keep (dense_rank first order by ksm.start_dt DESC) as Faculty_start_dt,
max (ksm.job_status_code) keep (dense_rank first order by ksm.start_dt DESC) as Faculty_job_status_code
from ksm 
group by ksm.id_number)

select s.id_number,
       entity.first_name,
       entity.last_name,
       fe.Faculty_Job_Title,
       fe.Faculty_Employer,
       fe.Faculty_job_status_code as faculty_job_status,
       rpt_pbh634.ksm_pkg_tmp.to_date2(fe.Faculty_start_dt, 'YYYYMMDD') as faculty_start_date_employment,     
       tms_event_role.short_desc as Volunteer_role_of_event,
       n.event_id,
       n.event_name,
       n.start_fy_calc as event_start_year,
       n.start_dt_calc as event_start_date,
       n.event_type_desc as event_type_description,
       n.event_organizers 
from RPT_PBH634.V_NU_EVENTS n
/* EP Staff is imbedded in the events table, which has volunteers and staff IDs */ 
left join ep_staff s on s.event_id = n.event_id
left join tms_event_role on tms_event_role.event_role_code = s.role_code
inner join fe on fe.id_number = s.id_number
inner join entity on entity.id_number = s.id_number
where n.ksm_event = 'Y'
order by n.start_fy_calc asc
