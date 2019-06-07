Create Or Replace View v_Task_Report As

With

-- Task_detail shows people responsible for prospect level tasks, with scheduled or completed dates in the current FY and previous FY
task_detail As (
  Select
    task.task_id
    , task.prospect_id As prospect_id2
    , task.program_code
    , task.proposal_id
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
    , trunc(task.date_added) As date_added
    , task.date_modified
    , task.operator_name
  From task
  Cross Join rpt_pbh634.v_current_calendar cal
  Inner Join task_responsible tr
    On tr.task_id = task.task_id
  Where
    task.proposal_id Is Null
    And task.task_code = 'CO'
    And (
      sched_date > to_date('08/31/2017', 'MM/DD/YYYY')
      Or completed_date >= to_date('08/31/2017', 'MM/DD/YYYY')
    )
)

, p_geo_code As (
  Select Distinct
    vgc.id_number
    , p_geocode_desc
  From rpt_dgz654.v_geo_code vgc
  Inner Join nu_prs_trp_prospect p
    On p.id_number = vgc.id_number
  Inner Join task_detail td
    On td.prospect_id2 = p.prospect_id
  Where geo_status_code = 'A'
  And vgc.addr_pref_ind = 'Y'
)

, contact_reports As (
  Select 
    credited
    , credited_name
    , contact_type
    , report_id
    , prospect_id
    , contact_date
  From rpt_pbh634.v_contact_reports_fast
  -- The v_ksm_visits view filters dates -- only current and previous FY
)

, contact_counts As (
  Select
    task_ID
    , task_responsible_ID
    , Count(Distinct
        Case
          When contact_date Between task_detail.date_added And task_detail.sched_date
            And task_code = 'CO'
            And task_status_code In ('1', '2')
            Then report_id
          End
      ) As contacts_during_task
    , Count(Distinct
        Case
          When contact_date Between task_detail.date_added And task_detail.sched_date
            And task_code = 'CO'
            And task_status_code In ('1', '2')
            And contact_type <> 'Visit'
            Then report_id
          End
      ) As nonvisit_contacts_during_task
    , Count(Distinct
        Case
          When contact_date > task_detail.date_added
            And contact_type = 'Visit'
            Then report_id
          End
      ) As total_visits
  From task_detail
  Inner Join contact_reports cr
    On cr.prospect_id = task_detail.prospect_id2
  And cr.credited = task_detail.task_responsible_id
  Group By
    task_ID
    , task_responsible_ID
)

, latest_contact As (
  Select Distinct 
    p.prospect_id
    , max(cr.contact_date) As latest_contact
  From prospect p
  Left Join contact_reports cr
    On cr.prospect_id = p.prospect_id
  Group By p.prospect_id
)

, disqualified As (
  Select
    p.prospect_id
    , p.stage_code
    , tms.short_desc
    , p.start_date
    , Count(Distinct
        Case
          When p.start_date > to_date('08/31/2017', 'MM/DD/YYYY')
            And p.stage_code = '7'
            Then p.prospect_id
          End
      ) As total_disqual
    From prospect p
    Inner Join tms_stage tms
    On p.stage_code = tms.stage_code
    Where p.stage_code = '7'
      And p.start_date > to_date('08/31/2017', 'MM/DD/YYYY')
    Group By
      p.prospect_id
      , p.stage_code
      , tms.short_desc
      , p.start_date
)

, cat As (
  Select *
  From prospect_category
  Where prospect_category_code In ('KT3','KT1')
)

-- Main query
Select Distinct
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
  , mgo.id_segment
  , mgo.id_score
  , mgo.pr_segment
  , mgo.pr_score
  , pp.prospect_stage
  , pp.prospect_type
  , pp.team
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
  , gc.p_geocode_desc
  , task_detail.task_id
  , task_detail.task_code
  , tms_task.short_desc As task_code_desc
  , task_detail.date_added
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
  , task_detail.proposal_id
  , lr.latest_contact
  , nvl(cc.nonvisit_contacts_during_task, 0)
    As nonvisit_contacts_during_task
  , nvl(cc.total_visits, 0)
    As total_visits
  , nvl(d.total_disqual, 0)
    As total_disqual
  , Case
      When task_detail.task_status_code In ('1','2','3')
        Then 'Y'
      Else 'N'
      End
    As act_task_ind
  , Case
      When cat.prospect_category_code In ('KT3','KT1')
        Then 'Y'
      Else 'N'
      End 
    As "150_300_IND"
  , Case
      When ksm_staff.former_staff Is Null
        And ksm_staff.id_number Is Not Null
        Then 'Y'
      Else 'N'
      End
    As current_mgo_ind
From prospect p
Inner Join prospect_entity pe
  On p.prospect_id = pe.prospect_id
Inner Join nu_prs_trp_prospect pp
  On pe.id_number = pp.id_number
Inner Join program_prospect pr
  On pr.prospect_id = pp.prospect_id
Inner Join task_detail
  On task_detail.prospect_id2 = pp.prospect_id
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
Left Join latest_contact lr
  On lr.prospect_id = p.prospect_id
Left Join contact_counts cc
  On cc.task_responsible_id = task_detail.task_responsible_id
  And cc.task_id = task_detail.task_id
Left Join p_geo_code gc
On gc.id_number = pp.id_number
Left Join disqualified d
  On d.prospect_id = p.prospect_id
Left Join rpt_pbh634.v_ksm_model_mg mgo
  On mgo.id_number = pp.id_number
Where pr.program_code = 'KM'
;
