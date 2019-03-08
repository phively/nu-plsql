Create or replace view v_Task_Report_Stewardship as

WITH 

Cal As (
                Select
                   today
                   , prev_fy_start
                From rpt_pbh634.v_current_calendar cal
),
--Task_detail shows people responsible for prospect level tasks, with scheduled or completed dates in the current FY and previous FY
Task_Detail AS(

                SELECT Task.Task_ID, task.Prospect_ID As prospect_id2, task.program_code, task.proposal_ID, task.task_code, task.task_status_code, task.task_priority_code,
                       task.sched_date, task.completed_date, task.original_sched_date, task.task_purpose_code, task.task_description,
                       task.source_id_number, task.owner_id_number, tr.Id_number AS Task_responsible_ID
                       , trunc(task.date_added) As date_added
                       , task.date_modified, task.operator_name
                FROM Task
                Cross Join cal
                Inner Join task_responsible tr
                ON tr.task_id = task.task_id
                WHERE ((sched_date > TO_DATE('08/31/2017', 'MM/DD/YYYY')) 
                      OR (completed_date > TO_DATE('08/31/2017', 'MM/DD/YYYY')))
                      AND task.proposal_ID IS Null
                      AND task.task_code = 'STW'
),

P_Geo_code AS(
                Select Distinct
                VGC.Id_number
                , P_Geocode_Desc
                FROM v_Geo_Code VGC
                INNER JOIN nu_prs_trp_prospect p
                ON p.id_number = VGC.id_number
                INNER JOIN Task_Detail td
                ON td.prospect_id2 = p.prospect_id
                WHERE Geo_status_code = 'A'
                AND VGC.Addr_pref_Ind = 'Y'
),

Contact_reports AS(
                Select 
                credited
                , credited_name
                , contact_type
                , report_ID
                , prospect_ID
                , contact_date
                FROM rpt_pbh634.v_contact_reports_fast
                -- The v_ksm_contact_reports view filters dates -- only current and previous FY
                --Group By credited, credited_name, contact_type, report_ID, prospect_ID, contact_date
),

Contact_counts AS(
               Select task_ID
               , task_responsible_ID
               --, max(contact_reports.contact_date) AS Latest_Contact
               , Count(Distinct
                               Case When contact_date between task_detail.date_added
                                 AND task_detail.sched_date AND task_code = 'CO' AND task_status_code IN ('1', '2')
                               Then report_id else NULL END
                           ) As contacts_during_task
               , Count(Distinct
                               Case When contact_date between task_detail.date_added 
                                 AND task_detail.sched_date AND task_code = 'CO' AND task_status_code IN ('1', '2') and contact_type <> 'Visit'
                               Then report_id else NULL END
                           ) As nonvisit_contacts_during_task
               , Count(Distinct
                               Case When contact_date > task_detail.date_added AND contact_type = 'Visit' 
                                 then report_id else NULL END
                           ) As total_visits     
               From Task_detail
               Inner Join Contact_reports CR
               ON CR.prospect_id = task_detail.prospect_ID2
               And cR.credited = task_detail.task_responsible_ID
               Group by task_ID, task_responsible_ID
),

Latest_Contact AS(
               Select Distinct 
               p.prospect_ID
               , max(CR.contact_date) As latest_contact
               From prospect P
               Left Join contact_reports CR
               ON CR.prospect_ID = P.prospect_ID
               Group By p.prospect_id
),

Disqualified AS( SELECT 
                 p.prospect_ID
                 , p.stage_code
                 , tms.short_desc
                 , p.start_date
                 , Count(Distinct
                         Case When p.start_date > TO_DATE('08/31/2017', 'MM/DD/YYYY') and p.stage_code = '7' then p.prospect_id else NULL END
                           ) As total_disqual     
                 FROM prospect P
                 INNER JOIN tms_stage TMS
                 ON P.stage_code = TMS.stage_code
                 WHERE p.stage_code = '7' AND p.start_date > TO_DATE('08/31/2017', 'MM/DD/YYYY')
                 GROUP BY p.prospect_ID, p.stage_code, tms.short_desc, p.start_date
                 
),

cat As (
    SELECT *
    FROM prospect_category
    WHERE prospect_category_code IN('KT3','KT1')
)

SELECT distinct
pp.id_number
, p.prospect_id
, p.prospect_name
, pr.program_code
, pp.record_status_code
, pp.record_type_code
, pp.employer_name1
, pp.employer_name2
, pp.evaluation_rating
, pp.evaluation_date
, pp.officer_rating
, MGO.id_segment
, MGO.id_score
, MGO.pr_segment
, MGO.pr_score
, pp.prospect_stage
, pp.prospect_type
, pp.team
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
, GC.P_geocode_desc
, task_detail.task_ID
, task_detail.task_code
, tms_task.short_desc AS Task_Code_Desc
, task_detail.date_added
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
, task_detail.proposal_ID
, lr.latest_contact
, nvl(cc.nonvisit_contacts_during_task, 0) AS nonvisit_contacts_during_task
, nvl(cc.total_visits, 0) As total_visits
, nvl(d.total_disqual, 0) As total_disqual
, case when task_detail.task_status_code In('1','2','3') then 'Y' else 'N'
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
INNER JOIN Program_Prospect pr
ON PR.prospect_id = PP.prospect_id
Inner Join Task_Detail
ON Task_Detail.prospect_ID2 = pp.prospect_ID
AND P.ACTIVE_IND = 'Y'
AND PE.PRIMARY_IND = 'Y'
Left join cat
on cat.prospect_id = pp.prospect_ID
Left Join table(rpt_pbh634.ksm_pkg.tbl_frontline_ksm_staff) KSM_staff
On KSM_staff.id_number = task_detail.task_responsible_ID
Left Join entity e
ON e.ID_number = task_detail.owner_ID_number
Left Join entity e2
ON e2.ID_number = task_detail.source_ID_number
Left Join entity e3
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
Left Join latest_contact LR
ON LR.prospect_ID = P.Prospect_ID
Left join contact_counts cc
On cc.task_responsible_ID = task_detail.task_responsible_ID
AND cc.task_ID = task_detail.task_ID
Left Join P_geo_code GC
ON GC.ID_number = PP.ID_Number
Left Join Disqualified D
ON D.prospect_id = P.prospect_ID
Left Join rpt_pbh634.v_ksm_model_mg MGO
ON MGO.ID_Number = PP.ID_number
WHERE PR.program_code = 'KM'
And task_detail.source_ID_number = '0000292130'
