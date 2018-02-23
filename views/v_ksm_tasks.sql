Create or replace view v_ksm_tasks as

WITH 

Cal As (
    Select
       prev_fy_start
       , (next_fy_start - 1) As this_fy_end
    From rpt_pbh634.v_current_calendar cal
),

Task_Detail AS(
SELECT Task.Task_ID, task.Prospect_ID As prospect_id2, task.program_code, task.task_code, task.task_status_code, task.task_priority_code,
       task.sched_date, task.completed_date, task.original_sched_date, task.task_purpose_code, task.task_description,
       task.source_id_number, task.owner_id_number, tr.Id_number AS Task_responsible_ID, task.date_added, task.date_modified, task.operator_name
FROM Task
Cross Join cal
Inner Join task_responsible tr
ON tr.task_id = task.task_id
WHERE (sched_date Between cal.prev_fy_start And cal.this_fy_end
      OR completed_date Between cal.prev_fy_start And cal.this_fy_end)     
),

cat As (
    SELECT *
    FROM prospect_category
    WHERE prospect_category_code IN('KT3','KT1')
)

SELECT
pp.id_number
, p.prospect_id
, p.prospect_name
, pp.record_status_code
, pp.record_type_code
, pp.employer_name1
, pp.employer_name2
, pp.evaluation_rating
, pp.evaluation_date
, pp.officer_rating
, pp.prospect_stage
, pp.prospect_type
, pp.prospect_manager_ID
, pp.prospect_manager
, KSM_staff.former_staff
, cat.prospect_category_code
, tms_prospect_category.short_desc AS Prospect_Cat
, pp.interest
, pp.giving_affiliation
, pp.pref_city
, pp.pref_state
, pp.pref_zip
, pp.preferred_country
, tms_country.short_desc As pref_country_name
, task_detail.task_ID
, task_detail.task_code
, tms_task.short_desc AS Task_Code_Desc
, task_detail.original_sched_date
, task_detail.sched_date
, task_detail.completed_date
, task_detail.owner_id_number
, e.report_name AS Owner_Name
, task_detail.task_responsible_ID
, e3.report_name AS Task_Responsible
, task_detail.source_ID_number
, e2.report_name AS source_name
, task_detail.task_priority_code
, tms_task_priority.short_desc As Task_Priority
, task_detail.task_purpose_code
, tms_task_purpose.short_desc AS Task_Purpose
, task_detail.task_status_code
, tms_task_status.short_desc AS Task_Status
, task_detail.task_description
, case when task_detail.task_status_code In('1','2') then 'Y' else 'N'
         END Act_Task_Ind
, case when cat.prospect_category_code IN('KT3','KT1') then 'Y' else 'N'
         END "150_300_IND"
, case when KSM_staff.former_staff Is Null And KSM_staff.id_number Is Not Null
    then 'Y'
    else 'N'
         END Current_MGO_Ind
FROM PROSPECT P
INNER JOIN PROSPECT_ENTITY PE
ON P.PROSPECT_ID = PE.PROSPECT_ID
INNER JOIN nu_prs_trp_prospect PP
ON PE.ID_NUMBER = PP.ID_NUMBER
Inner Join Task_Detail
ON Task_Detail.prospect_ID2 = pp.prospect_ID
AND P.ACTIVE_IND = 'Y'
AND PE.PRIMARY_IND = 'Y'
Left join cat
on cat.prospect_id = pp.prospect_ID
Left Join table(rpt_pbh634.ksm_pkg.tbl_frontline_ksm_staff) KSM_staff
On KSM_staff.id_number = task_detail.task_responsible_ID
LEFT Join entity e
ON e.ID_number = task_detail.owner_ID_number
LEFT Join entity e2
ON e2.ID_number = task_detail.source_ID_number
LEFT Join entity e3
ON e3.ID_number = task_detail.task_responsible_ID
Left Join tms_country
On tms_country.country_code = pp.preferred_country
Left Join tms_task_priority
On tms_task_priority.task_priority_code = task_detail.task_priority_code
Left Join tms_task_purpose
ON tms_task_purpose.task_purpose = task_detail.task_purpose_code
Left Join tms_task_status
ON tms_task_status.task_status_code = task_detail.task_status_code
Left Join tms_prospect_category
ON tms_prospect_category.prospect_category_code = cat.prospect_category_code
Left join tms_task
ON tms_task.task_code = task_detail.task_code
;
