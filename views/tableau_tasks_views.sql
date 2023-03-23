-- Task details used in the KSM Prospect Task Dashboard
Create Or Replace View rpt_dgz654.v_task_report As

With

params As (
  Select
    -- Only include tasks etc. on or after this date
    to_date('20160901', 'yyyymmdd')
      As start_dt
  From DUAL
)

-- Task_detail shows people responsible for prospect level tasks, with scheduled or completed dates in the current FY and previous FY
, task_detail As (
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
  Cross Join params
  Inner Join task_responsible tr
    On tr.task_id = task.task_id
  Where
    task.proposal_id Is Null
    And task.task_code = 'CO'
    And (
      sched_date >= params.start_dt
      Or completed_date >= params.start_dt
    )
)

, contact_reports As (
  Select 
    credited
    , credited_name
    , contact_type
    , report_id
    , prospect_id
    , id_number
    , contact_date
  From rpt_pbh634.v_contact_reports_fast
)

, contact_counts As (
  Select
    task_id
    , task_responsible_id
    , count(Distinct
        Case
          When contact_date Between task_detail.date_added And task_detail.sched_date
            And task_code = 'CO'
            And task_status_code In ('1', '2')
            Then report_id
          End
      ) As contacts_during_task
    , count(Distinct
        Case
          When contact_date Between task_detail.date_added And task_detail.sched_date
            And task_code = 'CO'
            And task_status_code In ('3', '4', '5')
            Then report_id
          End
    ) As contacts_during_task_inactive
    , count(Distinct
        Case
          When contact_date Between task_detail.date_added And task_detail.sched_date
            And task_code = 'CO'
            And task_status_code In ('1', '2')
            And contact_type <> 'Visit'
            Then report_id
          End
      ) As nonvisit_contacts_during_task
    , count(Distinct
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
    cr.id_number
    , max(cr.contact_date) As latest_contact
  From contact_reports cr
  Group By cr.id_number
)

, disqualified As (
  Select
    p.prospect_id
    , p.stage_code
    , tms.short_desc
    , p.start_date
    , Count(Distinct
        Case
          When p.start_date >= params.start_dt
            And p.stage_code = '7'
            Then p.prospect_id
          End
      ) As total_disqual
    From prospect p
    Cross Join params
    Inner Join tms_stage tms
    On p.stage_code = tms.stage_code
    Where p.stage_code = '7'
      And p.start_date >= params.start_dt
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
  entity.id_number
  , entity.report_name
  , p.prospect_id
  , p.prospect_name
  , pr.program_code
  , entity.record_status_code
  , entity.record_type_code
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
  , hh.household_city As pref_city
  , hh.household_state As pref_state
  , hh.household_zip As pref_zip
  , hh.household_country As pref_country_name
  , hh.household_geo_primary_desc As p_geocode_desc
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
  , nvl(cc.contacts_during_task_inactive, 0)
    As contacts_during_task_inactive
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
Inner Join entity
  On entity.id_number = pe.id_number
Inner Join rpt_pbh634.v_entity_ksm_households hh
  On hh.id_number = pe.id_number
Left Join nu_prs_trp_prospect pp
  On pe.id_number = pp.id_number
Left Join program_prospect pr
  On pr.prospect_id = p.prospect_id
Inner Join task_detail
  On task_detail.prospect_id2 = p.prospect_id
  And pe.primary_ind = 'Y'
Left Join cat
  On cat.prospect_id = pp.prospect_id -- Keep as pp.prospect_id, not p.prospect_id; DQed prospects should not be in top 150/300
Left Join table(rpt_pbh634.ksm_pkg_tmp.tbl_frontline_ksm_staff) ksm_staff
  On ksm_staff.id_number = task_detail.task_responsible_id
Left Join entity e
  On e.id_number = task_detail.owner_id_number
Left Join entity e2
  On e2.id_number = task_detail.source_id_number
Left Join entity e3
  On e3.id_number = task_detail.task_responsible_id
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
  On lr.id_number = pe.id_number
Left Join contact_counts cc
  On cc.task_responsible_id = task_detail.task_responsible_id
  And cc.task_id = task_detail.task_id
Left Join disqualified d
  On d.prospect_id = p.prospect_id
Left Join rpt_pbh634.v_ksm_model_mg mgo
  On mgo.id_number = pp.id_number
--Where pr.program_code = 'KM'
;

-- Outreach tasks view used in the KSM Prospect Task Dashboard
Create Or Replace View rpt_dgz654.v_outreach_90 As

With

--Selects a master outreach task per task responsible
da As (
  Select
    vt.task_responsible_id
    , vt.id_number
    , max(vt.task_id) keep(dense_rank First Order By vt.date_added Asc, vt.task_id Asc)
      As outreach_task_id
    , max(vt.date_added) keep(dense_rank First Order By vt.date_added Asc, vt.task_id Asc)
      As outreach_date_added
    , max(vt.sched_date) keep(dense_rank First Order By vt.date_added Asc, vt.task_id Asc)
      As outreach_date_scheduled
  From rpt_dgz654.v_task_report vt
  Group By
    vt.task_responsible_id
    , vt.id_number
)

-- New leads that have been assigned an outreach task for over 90 days, that have not been disqualified
--Includes active and inactive tasks so we capture outreach to new leads that have been assigned as LGO or PM
, new_leads As (
  Select Distinct
    vt.task_responsible_id
    , vt.task_responsible
    , da.outreach_task_id
    , vt.task_status_code
    , vt.task_status
    , vt.id_number
    , vt.prospect_id
    , vt.prospect_name
    , vt.total_disqual
    , cal.today
    , da.outreach_date_added
    , da.outreach_date_scheduled
    , cal.today - da.outreach_date_added
      As days_assigned
  From rpt_dgz654.v_task_report vt
  Cross Join rpt_pbh634.v_current_calendar cal
  Inner Join da
    On da.outreach_task_id = vt.task_id
  Where cal.today - da.outreach_date_added > 90
    And vt.total_disqual = 0
  Order By vt.id_number Asc
)

-- All contact reports
, cr As (
  Select
    cf.report_id
    , cf.credited
    , cf.credited_name
    , cf.contact_type
    , cf.id_number
    , cf.prospect_id
    , cf.contacted_name
    , cf.report_name
    , cf.contact_date
  From rpt_pbh634.v_contact_reports_fast cf
  Inner Join new_leads nld
    On nld.id_number = cf.id_number
)

-- This is where we actually do the summarizing, and what is joined at the end
, cr_summary As (
  Select
    cr.id_number
    , cr.credited
    , count(Distinct report_id)
      As contact_reports
    , sum(Case When nld.outreach_date_added <= contact_date Then 1 Else 0 End)
      As outreach_post_assignment
    , max(cr.contact_date)
      As latest_contact
  From cr
  Inner Join new_leads nld
    On cr.id_number = nld.id_number
  And cr.credited = nld.task_responsible_id
  Group By
    cr.id_number
    , cr.credited
  Order By cr.id_number Asc
)

-- Staff view
, sta As (
  Select
    st.*
    , Case
        When st.former_staff Is Null
          Then 'Y'
        Else NULL
        End
      As ksm_current_staff
  From table(rpt_pbh634.ksm_pkg_tmp.tbl_frontline_ksm_staff) st
)

Select Distinct
  nld.task_responsible_id
  , nld.task_responsible
  , nld.task_status_code
  , nld.task_status
  , nvl(sta.ksm_current_staff, 'N')
    As ksm_current_staff
  , nld.outreach_date_added
  , nld.outreach_date_scheduled
  , nld.days_assigned
  , nld.id_number
  , e.pref_mail_name
  , nld.prospect_id
  , nld.prospect_name
  , mgo.id_segment
  , mgo.id_score
  , mgo.pr_segment
  , mgo.pr_score
  , nvl(cr_summary.contact_reports, 0)
    As all_outreach
  , nvl(cr_summary.outreach_post_assignment, 0)
    As outreach_post_assignment
  , cr_summary.latest_contact
  , cal.today - cr_summary.latest_contact
    As days_since_last_contact
--, CR.Contact_Date
From new_leads nld
Cross Join rpt_pbh634.v_current_calendar cal
Inner Join entity e
  On e.id_number = nld.id_number
Left Join cr_summary
  On cr_summary.id_number = nld.id_number
  And cr_summary.credited = nld.task_responsible_id
Left Join rpt_pbh634.v_ksm_model_mg mgo
  On mgo.id_number = nld.id_number
Left Join sta
  On sta.id_number = nld.task_responsible_id
;
