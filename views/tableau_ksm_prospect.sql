create or replace view tableau_ksm_prospect as 

--- Entity 

with entity as (select *
 From mv_entity e
 where e.is_deceased_indicator = 'N'
 ),
 
--- Degrees
 
d as (select d.donor_id,
       d.degrees_verbose,
       d.degrees_concat,
       d.first_ksm_grad_date,
       d.first_ksm_year,
       d.first_masters_year,
       d.last_masters_year,
       d.program,
       d.program_group
From mv_entity_ksm_degrees d),

--- Giving

give as (select g.household_id,
       g.household_account_name,
       g.household_primary_donor_id,
       g.household_primary_full_name,
       g.household_spouse_donor_id,
       g.household_spouse_full_name,
       g.household_last_masters_year,
       g.ngc_lifetime,
       g.ngc_lifetime_full_rec,
       g.ngc_lifetime_nonanon_full_rec,
       g.last_ngc_opportunity_type,
       g.last_ngc_designation_id,
       g.last_ngc_designation,
       g.last_ngc_recognition_credit
       --- Add in last gift date 
from mv_ksm_giving_summary g),

--- Contact Report

crf as (select d.constituent_donor_id,
       d.salutation,
       d.gender_identity,
       d.constituent_contact_report_count,
       d.constituent_contact_report_last_year_count,
       d.constituent_last_contact_report_record_id,
       d.constituent_last_contact_report_date,
       d.constituent_last_contact_primary_relationship_manager_date,
       d.constituent_last_contact_report_author,
       d.constituent_last_contact_report_purpose,
       d.constituent_last_contact_report_method,
       d.constituent_visit_count,
       d.constituent_visit_last_year_count,
       d.constituent_last_visit_date
       from DM_ALUMNI.DIM_CONSTITUENT d),
       
---- Dean Contact Last Report 

dcrf as (select d.constituent_donor_id,
       d.salutation,
       d.gender_identity,
       d.constituent_contact_report_count,
       d.constituent_contact_report_last_year_count,
       d.constituent_last_contact_report_record_id,
       d.constituent_last_contact_report_date,
       d.constituent_last_contact_primary_relationship_manager_date,
       d.constituent_last_contact_report_author,
       d.constituent_last_contact_report_purpose,
       d.constituent_last_contact_report_method,
       d.constituent_visit_count,
       d.constituent_visit_last_year_count,
       d.constituent_last_visit_date
       from DM_ALUMNI.DIM_CONSTITUENT d
       where d.constituent_last_contact_report_author like '%Francesca Cornelli%'),


       
--- assignment

assign as (Select a.household_id,
       a.donor_id,
       a.sort_name,
       a.prospect_manager_name,
       a.lagm_user_id,
       a.lagm_name,
       a.ksm_manager_flag,
       a.lagm_business_unit
From mv_assignments a),

--- employment 
       
employ as (select distinct
c.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C,
max (c.ap_is_primary_employment__c) keep (dense_rank First Order by c.ucinn_ascendv2__start_date__c desc) as primary_employ_ind,
max (c.ucinn_ascendv2__job_title__c) keep (dense_rank first order by c.ucinn_ascendv2__start_date__c desc) as primary_job_title,
max (c.UCINN_ASCENDV2__RELATED_ACCOUNT_NAME_FORMULA__C) keep (dense_rank first order by c.ucinn_ascendv2__start_date__c desc) as primary_employer
from stg_alumni.ucinn_ascendv2__Affiliation__c c
where c.ap_is_primary_employment__c = 'true'
group by c.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C),

--- c-suite flag 

csuite as (select
employ.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C as donor_id,
employ.primary_job_title,
employ.primary_employer
from employ
where   ((employ.primary_job_title like '%Vice President%'
or employ.primary_job_title like '%VP%'
or employ.primary_job_title like '%Owner%'
or employ.primary_job_title like '%Founder%'
or employ.primary_job_title like '%Managing Director%'
or employ.primary_job_title like '%Executive%'
or employ.primary_job_title like '%Partner%'
or employ.primary_job_title like '%Principal%'
or employ.primary_job_title like '%Head%'
or employ.primary_job_title like '%Senior%'
or employ.primary_job_title like '%Chief%'
or employ.primary_job_title like '%Board%'
---- Check Abbreviations too 
or employ.primary_job_title like '%CEO%'
--- Chief Finance Officer
or employ.primary_job_title like '%CFO%'
--- Chief Marketing Officer
or employ.primary_job_title like '%CMO%'
--- Chief Information Officer
or employ.primary_job_title like '%CIO%'
--- Chiefer Operating Office
or employ.primary_job_title like '%COO%'
--- Chief Tech Officer
or employ.primary_job_title like '%CTO%'
--- Chief Compliance officer
or employ.primary_job_title like '%CCO%')

--- take out assistants/associates/advisors, not actual senior titles

and (primary_job_title not like '%Assistant%'
and primary_job_title not like '%Asst%'
and primary_job_title not like '%Associate%'
and primary_job_title not like '%Assoc%'
and primary_job_title not like '%Advisor%'))),

--- Dean's Last Visit 

a as (select
distinct co.ucinn_ascendv2__donor_id__c,
co.firstname,
co.lastname,
c.ap_contact_report_author_name_formula__c,
c.ucinn_ascendv2__contact_method__c,
c.ucinn_ascendv2__date__c,
c.ucinn_ascendv2__description__c,
c.ucinn_ascendv2__contact_report_body__c
from stg_alumni.ucinn_ascendv2__contact_report__c c
left join stg_alumni.contact co on co.id = c.ucinn_ascendv2__contact__c
where c.ap_contact_report_author_name_formula__c = 'Francesca Cornelli'
and c.ucinn_ascendv2__contact_method__c = 'Visit'
order by c.ucinn_ascendv2__date__c ASC),

--- Listagg Dean's Contact Report

l as (select a.ucinn_ascendv2__donor_id__c,
Listagg (a.ap_contact_report_author_name_formula__c, ';  ') Within Group (Order By a.ucinn_ascendv2__date__c) As author_name,
Listagg (a.ucinn_ascendv2__contact_method__c, ';  ') Within Group (Order By a.ucinn_ascendv2__date__c) As contact_type,
Listagg (a.ucinn_ascendv2__date__c, ';  ') Within Group (Order By a.ucinn_ascendv2__date__c) As cr_date,
Listagg (a.ucinn_ascendv2__description__c, ';  ') Within Group (Order By a.ucinn_ascendv2__date__c) As ucinn_ascendv2__description__c
from a
group by a.ucinn_ascendv2__donor_id__c),

--- Involvements 

i as (select i.constituent_donor_id,
       i.constituent_name,
       i.involvement_record_id,
       i.involvement_code,
       i.involvement_name,
       i.involvement_status,
       i.involvement_type,
       i.involvement_role,
       i.involvement_business_unit,
       i.involvement_start_date,
       i.involvement_end_date,
       i.involvement_comment,
       i.etl_update_date,
       i.mv_last_refresh
from mv_involvement i
where i.involvement_status = 'Current'
and (i.involvement_name like '%KSM%'
or i.involvement_name like '%Kellogg%')
),

--- listagg involvements 

involve as (select i.constituent_donor_id,
Listagg (i.involvement_name, ';  ') Within Group (Order By i.involvement_name) As involvement_name
from i
group by i.constituent_donor_id),


--- contact 

co as (Select c.donor_id,
       c.sort_name,
       c.service_indicators_concat,
       c.linkedin_url,
       c.address_preferred_type,
       c.preferred_address_line_1,
       c.preferred_address_line_2,
       c.preferred_address_line_3,
       c.preferred_address_line_4,
       c.preferred_address_city,
       c.preferred_address_state,
       c.preferred_address_postal_code,
       c.preferred_address_country,
       c.preferred_address_latitude,
       c.preferred_address_longitude,
       c.home_address_line_1,
       c.home_address_line_2,
       c.home_address_line_3,
       c.home_address_line_4,
       c.home_address_city,
       c.home_address_state,
       c.home_address_postal_code,
       c.home_address_country,
       c.home_address_latitude,
       c.home_address_longitude,
       c.business_address_line_1,
       c.business_address_line_2,
       c.business_address_line_3,
       c.business_address_line_4,
       c.business_address_city,
       c.business_address_state,
       c.business_address_postal_code,
       c.business_address_country
From mv_entity_contact_info c),

--- KSM Model Scores and AF 10K- Temp Table from Paul 
--- TBL_KSM_MG

/*K as (Select a.donor_id,
       a.segment_year,
       a.segment_month,
       a.segment_code,
       a.description,
       a.score
From tbl_ksm_model_af_10k a),*/

--- Use Paul's Model Score Now

mods as (select m.donor_id,
       m.household_id,
       m.household_primary,
       m.household_id_ksm,
       m.household_primary_ksm,
       m.sort_name,
       m.primary_record_type,
       m.institutional_suffix,
       m.mg_id_code,
       m.mg_id_description,
       m.mg_id_score,
       m.mg_pr_code,
       m.mg_pr_description,
       m.mg_pr_score,
       m.mg_probability,
       m.af_10k_code,
       m.af_10k_description,
       m.af_10k_score,
       m.alumni_engagement_code,
       m.alumni_engagement_description,
       m.alumni_engagement_score,
       m.student_supporter_code,
       m.student_supporter_description,
       m.student_supporter_score,
       m.etl_update_date,
       m.mv_last_refresh
  From mv_ksm_models m ),

--- Kellogg Model Engagement Score

/* kmes as (select ae.donor_id,
       ae.segment_year,
       ae.segment_month,
       ae.id_code,
       ae.id_segment,
       ae.id_score,
       ae.pr_code,
       ae.pr_segment,
       ae.pr_score,
       ae.est_probability
from tbl_ksm_model_mg ae),*/


event as (select  
a.NU_DONOR_ID__C  ,
a.CONFERENCE360__ATTENDEE_FULL_NAME__C  ,
a.CONFERENCE360__EVENT_NAME__C  ,
a.CONFERENCE360__EVENT_START_DATE__C  ,
a.conference360__attendance_status__c
from stg_alumni.conference360__attendee__c a 
where a.NU_DONOR_ID__C  is not null
and a.conference360__attendance_status__c = 'Attended'
and a.CONFERENCE360__EVENT_NAME__C is not null),

--- event listag

el as (
select event.NU_DONOR_ID__C,
Listagg (event.CONFERENCE360__EVENT_NAME__C, ';  ') Within Group (Order By event.CONFERENCE360__EVENT_START_DATE__C) As event_name,
Listagg (event.CONFERENCE360__EVENT_START_DATE__C, ';  ') Within Group (Order By event.CONFERENCE360__EVENT_START_DATE__C) As event_start_date,
Listagg (event.conference360__attendance_status__c, ';  ') Within Group (Order By event.CONFERENCE360__EVENT_START_DATE__C) As event_attendance_status
from event
group by event.NU_DONOR_ID__C),

event_count as (select event.NU_DONOR_ID__C,
count (event.CONFERENCE360__EVENT_NAME__C) as count_events
from event 
group by event.NU_DONOR_ID__C),

prop as (select p.opportunity_salesforce_id,
       p.proposal_record_id,
       p.proposal_legacy_id,
       p.proposal_strategy_record_id,
       p.household_id,
       p.household_primary,
       p.household_id_ksm,
       p.household_primary_ksm,
       p.prospect_name,
       p.donor_id,
       p.full_name,
       p.sort_name,
       p.institutional_suffix,
       p.is_deceased_indicator,
       p.person_or_org,
       p.primary_record_type,
       p.proposal_active_indicator,
       p.proposal_stage,
       p.proposal_type,
       p.proposal_name,
       p.proposal_description,
       p.proposal_funding_interests,
       p.proposal_probability,
       p.proposal_amount,
       p.proposal_submitted_amount,
       p.proposal_anticipated_amount,
       p.proposal_funded_amount,
       p.proposal_linked_gift_pledge_ids,
       p.proposal_created_date,
       p.proposal_submitted_date,
       p.proposal_submitted_fy,
       p.proposal_submitted_py,
       p.proposal_close_date,
       p.proposal_close_fy,
       p.propsal_close_py,
       p.proposal_stage_date,
       p.proposal_days_in_current_stage,
       p.proposal_payment_schedule,
       p.proposal_designation_units,
       p.ksm_flag,
       p.active_proposal_manager_salesforce_id,
       p.active_proposal_manager_donor_id,
       p.active_proposal_manager_name,
       p.active_proposal_manager_unit,
       p.active_proposal_manager_team,
       p.historical_pm_user_id,
       p.historical_proposal_manager_donor_id,
       p.historical_pm_name,
       p.historical_pm_role,
       p.historical_pm_business_unit,
       p.historical_proposal_manager_team,
       p.historical_pm_is_active,
       p.etl_update_date,
       p.mv_last_refresh
from mv_proposals p),


tka as (select t.DONOR_ID,
       t.UOR,
       t.SALESFORCE_ID,
       t."UOR DATE" as uor_date,
       t."EVALUATION RATING" as Evaluation_rating,
       t."EVALUATION RATING DATE" as evaluation_rating_date,
       t."STAGE OF READINESS", 
       t.TEAM,
       t.PROPOSAL_MANAGER_KSM_STAFF,
       t.MANAGER, 
       t."MANAGER START DATE"
from Tableau_KSM_Activity t )


select  distinct 
       e.donor_id,
       --- Use Paul's defintion 
       e.household_id,
       tka.SALESFORCE_ID,
       e.household_primary,
       e.full_name,
       e.sort_name,
       e.salutation,
       e.gender_identity,
       e.first_name,
       e.middle_name,
       e.last_name,
       e.is_deceased_indicator,
       e.primary_record_type,
       e.institutional_suffix,
       e.spouse_donor_id,
       e.spouse_name,
       e.spouse_institutional_suffix,
     /*    
     --- Melanie does not need this in her report
       e.preferred_address_status,
       e.preferred_address_type,
       e.preferred_address_line_1,
       e.preferred_address_line_2,
       e.preferred_address_line_3,
       e.preferred_address_line_4,
       e.preferred_address_city,
       e.preferred_address_state,
       e.preferred_address_postal_code,
       e.preferred_address_country, 
       co.home_address_line_1,
       co.home_address_line_2,
       co.home_address_line_3,
       co.home_address_line_4,*/              
       co.home_address_city,
       co.home_address_state,
       co.home_address_postal_code,
       co.home_address_country,
       /*  --- Melanie does not need this in her report       
       co.business_address_line_1,
       co.business_address_line_2,
       co.business_address_line_3,
       co.business_address_line_4, */ 
       co.business_address_city,
       co.business_address_state,
       co.business_address_postal_code,
       co.business_address_country,       
       --- Strategy ID AKA: Prospect ID, Prospect Name (Proposal View)
       prop.proposal_strategy_record_id,
       prop.household_id_ksm,
       prop.prospect_name,
       prop.proposal_active_indicator,
       prop.proposal_stage,
       prop.proposal_type,
       prop.proposal_name,
       prop.proposal_description,
       prop.proposal_funding_interests,
       prop.proposal_probability,
       prop.proposal_amount,
       prop.proposal_submitted_amount,
       prop.proposal_anticipated_amount,
       prop.proposal_funded_amount,
       prop.proposal_linked_gift_pledge_ids,
       prop.proposal_created_date,
       prop.proposal_submitted_date,
       prop.proposal_submitted_fy,
       prop.proposal_submitted_py,
       prop.proposal_close_date,
       prop.proposal_close_fy,
       prop.propsal_close_py,
       prop.proposal_stage_date,
       prop.proposal_days_in_current_stage,
       prop.proposal_payment_schedule,
--e.university_overall_rating, e.research_evaluation, e.research_evaluation_date,ADD UOR DATE        
       tka.UOR,
       tka.uor_date,
       tka.Evaluation_rating,
       tka.evaluation_rating_date,
       tka."STAGE OF READINESS", 
       tka.TEAM,
       tka.PROPOSAL_MANAGER_KSM_STAFF,
       tka.MANAGER, 
       tka."MANAGER START DATE",
       --- Melanie does not need this in her report
       --d.degrees_verbose,
       --d.degrees_concat,
       --d.first_ksm_grad_date,
       d.first_ksm_year,
       --- Melanie does not need this in her report
       --d.first_masters_year,
       ---d.last_masters_year,
       d.program,
       d.program_group,
       ---employ.primary_employ_ind,
       employ.primary_job_title,
       employ.primary_employer,
       --- C Suite Flag
       case when csuite.donor_id is not null then 'Y' end as c_suite_flag,
       /*
        --- Melanie does not need this in her report
       g.household_id,
       g.household_account_name,
       g.household_primary_donor_id,
       g.household_primary_full_name,
       g.household_spouse_donor_id,
       g.household_spouse_full_name,
       g.household_last_masters_year,*/
       g.ngc_lifetime,
       /*
       g.ngc_lifetime_full_rec,
       g.ngc_lifetime_nonanon_full_rec,*/
       g.last_ngc_opportunity_type,
       ---g.last_ngc_designation_id,
       g.last_ngc_designation,
       g.last_ngc_recognition_credit,
       ---- The team for prospect manager and LAGM ("Business Unit") 
       assign.prospect_manager_name,
       assign.lagm_user_id,
       assign.lagm_name,
       assign.ksm_manager_flag,
       --- Add Business Unit
       assign.lagm_business_unit,
      /* --- Melanie needs most recent, not concat - use a max function 
      She would like the most recent, but a count of visits total for Francesca 
       crf.constituent_last_contact_report_record_id,
       l.author_name,
       l.contact_type,
       */        
       --- Renaming CR fields - "Dean Last Visit"        
       l.cr_date,
       l.ucinn_ascendv2__description__c,
       involve.involvement_name,       
       crf.constituent_last_contact_report_date,
       crf.constituent_last_contact_primary_relationship_manager_date,
       crf.constituent_last_contact_report_author,
       crf.constituent_last_contact_report_purpose,
       crf.constituent_last_contact_report_method,
       crf.constituent_visit_count,
       crf.constituent_visit_last_year_count,
       crf.constituent_last_visit_date,  
       --- Dean Last Contact Report
       dcrf.constituent_last_contact_report_record_id,
       dcrf.constituent_last_contact_report_date,
       dcrf.constituent_last_contact_report_author,
       dcrf.constituent_last_contact_report_purpose,
       dcrf.constituent_last_contact_report_method,
       dcrf.constituent_visit_count,
       dcrf.constituent_visit_last_year_count,
       dcrf.constituent_last_visit_date,      
       --- Melanie - Needs the ID segment, PR Segment, Est Probability 
       mods.mg_id_code,
       mods.mg_id_description,
       mods.mg_id_score,
       mods.mg_pr_code,
       mods.mg_pr_description,
       mods.mg_pr_score,
       mods.mg_probability,
       mods.af_10k_code,
       mods.af_10k_description,
       mods.af_10k_score,
       mods.alumni_engagement_code,
       mods.alumni_engagement_description,
       mods.alumni_engagement_score,
       mods.student_supporter_code,
       mods.student_supporter_description,
       mods.student_supporter_score,
       mods.etl_update_date,
       mods.mv_last_refresh,
       event_count.count_events,
       ---- i think I should listagg this????   
       --- Campaign Name is okay 
       el.event_name,
       el.event_start_date,
       el.event_attendance_status
       --- Add in Case manager- Where we are saving the Gift Officer New Leads 
       --- case owner, case number, Where the type is referral and status is new or in progress     
       --- AF Status - Tableau_KSM_Activity       
       --- Stage of Readiness - timeline - Does it work?????  ---- Check Strategy 
       
       --- Salesforce ID        
from entity e 
--- Inner join degrees 
inner join d on d.donor_id = e.donor_id
--- giving info  
left join give g on g.household_primary_donor_id = e.donor_id 
--- employment
left join employ on employ.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C = e.donor_id
--- assingment
left join assign assign on assign.donor_id = e.donor_id
--- last contact report
left join crf on crf.constituent_donor_id = e.donor_id
--- francesca's contact report 
left join l on l.ucinn_ascendv2__donor_id__c = e.donor_id
--- involvements
left join involve on involve.constituent_donor_id = e.donor_id
--- contacts
left join co on co.donor_id = e.donor_id
--- 10K 
--left join K on K.donor_id = e.donor_id
--- model
left join mods on mods.donor_id = e.donor_id
--- kellogg engagement score
--- left join kmes on kmes.donor_id = e.donor_id
--- event data
left join el on el.NU_DONOR_ID__C = e.donor_id
--- count of evnet
left join event_count on event_count.NU_DONOR_ID__C = e.donor_id
--- proposal
left join prop on prop.donor_id = e.donor_id
--- Activity 
left join tka on tka.donor_id = e.donor_id
--- c suite
left join csuite on csuite.donor_id = e.donor_id
--- Dean Contact Report 
left join dcrf on dcrf.constituent_donor_id = e.donor_id 
