create or replace view v_ksm_student_activities as 

with a as (select distinct stact.id_number,
                stact.stop_dt,
                stact.xsequence,
                stact.student_activity_code,
                stact.student_particip_code,
       trim (stact.activity_office_code) as office_code,
                stact.start_dt,
                stact.xcomment,
                stact.date_added,
                stact.date_modified,
                stact.operator_name,
                stact.user_group,
                stact.data_source_code,
                stact.location_id
  FROM  student_activity stact
inner join rpt_pbh634.v_entity_ksm_degrees
d on d.id_number = stact.id_number),

industry As (
  Select id_number
  , fow.short_desc As fld_of_work
  From employment
  Left Join tms_fld_of_work fow
       On fow.fld_of_work_code = employment.fld_of_work_code
  Where employment.primary_emp_ind = 'Y'
),

inter as (
select interest.id_number,
listagg (tms_interest.short_desc , ';  ') Within Group (Order By tms_interest.short_desc) as interest 
from interest
inner join v_industry_groups on v_industry_groups.fld_of_work_code = interest.interest_code
left join tms_interest on tms_interest.interest_code = interest.interest_code
group by interest.id_number)


select a.id_number,
d.REPORT_NAME,
d.FIRST_KSM_YEAR,
d.PROGRAM,
industry.fld_of_work as employment_industry,
inter.interest,
t.short_desc as student_club,
a.start_dt,
a.stop_dt,
tms_activity_office.short_desc as student_leadership,
a.office_code as student_leadership_code,
a.xcomment,
a.date_added,
a.date_modified
from a
inner join rpt_pbh634.v_entity_ksm_degrees d on d.id_number = a.id_number
left join tms_student_act t on t.student_activity_code = a.student_activity_code
left join industry on industry.id_number = a.id_number
left join tms_activity_office on tms_activity_office.activity_office_code = a.office_code
left join inter on inter.id_number = a.id_number
where a.office_code is not null
Order by a.date_modified DESC
