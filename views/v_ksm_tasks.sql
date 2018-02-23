/*********************
All tasks falling in the previous or current fiscal year
*********************/

Create Or Replace View v_ksm_tasks As

With

-- Calendar objects
cal As (
  Select
    prev_fy_start
    , (next_fy_start - 1) As this_fy_end
  From rpt_pbh634.v_current_calendar cal
)

-- Task table fields
, task_detail As (
  Select
    task.task_id
    , task.prospect_id
    , task.program_code
    , task.task_code
    , task.task_status_code
    , task.task_priority_code
    , task.sched_date
    , task.completed_date
    , task.original_sched_date
    , task.task_purpose_code
    , task.task_description
    , task.source_id_number
    , task.owner_id_number
    , tr.id_number As task_responsible_id
    , task.date_added
    , task.date_modified
    , task.operator_name
  From task
  Cross Join cal
  Inner Join task_responsible tr
    On tr.task_id = task.task_id
  Where sched_date Between cal.prev_fy_start And cal.this_fy_end
    Or completed_date Between cal.prev_fy_start And cal.this_fy_end
)

-- Prospect categories
, cat As (
  Select *
  From prospect_category
  Where prospect_category_code In ('KT3','KT1')
)

-- Main query
Select
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
  , pp.prospect_manager_id
  , pp.prospect_manager
  , ksm_staff.former_staff
  , cat.prospect_category_code
  , tms_prospect_category.short_desc As prospect_cat
  , pp.interest
  , pp.giving_affiliation
  , pp.pref_city
  , pp.pref_state
  , pp.pref_zip
  , pp.preferred_country
  , tms_country.short_desc As pref_country_name
  , task_detail.task_id
  , task_detail.task_code
  , tms_task.short_desc As task_code_desc
  , task_detail.original_sched_date
  , task_detail.sched_date
  , task_detail.completed_date
  , task_detail.owner_id_number
  , e.report_name As owner_name
  , task_detail.task_responsible_id
  , e3.report_name As task_responsible
  , task_detail.source_id_number
  , e2.report_name As source_name
  , task_detail.task_priority_code
  , tms_task_priority.short_desc As task_priority
  , task_detail.task_purpose_code
  , tms_task_purpose.short_desc As task_purpose
  , task_detail.task_status_code
  , tms_task_status.short_desc As task_status
  , task_detail.task_description
  , Case When task_detail.task_status_code In ('1', '2') Then 'Y' Else 'N' End
    As act_task_ind
  , Case When cat.prospect_category_code In ('KT3','KT1') Then 'Y' Else 'N' End
    As "150_300_IND"
  , Case When ksm_staff.former_staff Is Null And ksm_staff.id_number Is Not Null Then 'Y' Else 'N' End
    As Current_MGO_Ind
From prospect p
Inner Join prospect_entity pe
  On p.prospect_id = pe.prospect_id
Inner Join nu_prs_trp_prospect pp
  On pe.id_number = pp.id_number
Inner Join task_detail
  On task_detail.prospect_id = pp.prospect_id
  And p.active_ind = 'Y'
  And pe.primary_ind = 'Y'
Left Join cat
  On cat.prospect_id = pp.prospect_id
Left Join table(rpt_pbh634.ksm_pkg.tbl_frontline_ksm_staff) ksm_staff
  On ksm_staff.id_number = task_detail.task_responsible_id
Left Join entity e
  On e.id_number = task_detail.owner_id_number
Left Join entity e2
  On e2.id_number = task_detail.source_id_number
Left Join entity e3
  On e3.id_number = task_detail.task_responsible_id
Left Join tms_country
  On tms_country.country_code = pp.preferred_country
Left Join tms_task_priority
  On tms_task_priority.task_priority_code = task_detail.task_priority_code
Left Join tms_task_purpose
  On tms_task_purpose.task_purpose = task_detail.task_purpose_code
Left Join tms_task_status
  On tms_task_status.task_status_code = task_detail.task_status_code
Left Join tms_prospect_category
  On tms_prospect_category.prospect_category_code = cat.prospect_category_code
Left Join tms_task
  On tms_task.task_code = task_detail.task_code
;
