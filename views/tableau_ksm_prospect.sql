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
       
--- assignment

assign as (Select a.household_id,
       a.donor_id,
       a.sort_name,
       a.prospect_manager_name,
       a.lagm_user_id,
       a.lagm_name,
       a.ksm_manager_flag
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

K as (Select a.donor_id,
       a.segment_year,
       a.segment_month,
       a.segment_code,
       a.description,
       a.score
From tbl_ksm_model_af_10k a),

mods as (Select m.donor_id,
       m.segment_year,
       m.segment_month,
       m.id_code,
       m.id_segment,
       m.id_score,
       m.pr_code,
       m.pr_segment,
       m.pr_score,
       m.est_probability
From tbl_ksm_model_mg m),

--- Kellogg Model Engagement Score

kmes as (select ae.id_number,
       ae.segment_code,
       ae.segment_name,
       ae.segment_year,
       ae.segment_month,
       ae.xcomment
from tbl_ksm_model_ae ae),

--- Kellogg Alumni Engagement Student Supporter Score

kmss as (select s.id_number,
       s.segment_code,
       s.segment_name,
       s.segment_year,
       s.segment_month,
       s.xcomment
from tbl_ksm_model_ss s),

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
group by event.NU_DONOR_ID__C)


select  distinct 
       e.donor_id,
       e.household_id,
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
       co.home_address_line_4,
       co.home_address_city,
       co.home_address_state,
       co.home_address_postal_code,
       co.home_address_country,
       co.business_address_line_1,
       co.business_address_line_2,
       co.business_address_line_3,
       co.business_address_line_4,
       co.business_address_city,
       co.business_address_state,
       co.business_address_postal_code,
       co.business_address_country,
       e.university_overall_rating,
       e.research_evaluation,
       e.research_evaluation_date,
       d.degrees_verbose,
       d.degrees_concat,
       d.first_ksm_grad_date,
       d.first_ksm_year,
       d.first_masters_year,
       d.last_masters_year,
       d.program,
       d.program_group,
       employ.primary_employ_ind,
       employ.primary_job_title,
       employ.primary_employer,
       g.household_id,
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
       g.last_ngc_recognition_credit,
       a.prospect_manager_name,
       a.lagm_user_id,
       a.lagm_name,
       a.ksm_manager_flag,
       crf.constituent_last_contact_report_record_id,
       l.author_name,
       l.contact_type,
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
       mods.segment_year,
       mods.segment_month,
       mods.id_code,
       mods.id_segment,
       mods.id_score,
       mods.pr_code,
       mods.pr_segment,
       mods.pr_score,
       mods.est_probability,
       K.segment_year as K_segment_year,
       K.segment_month as K_segment_month,
       K.segment_code as K_segment_code,
       K.description as K_segment_description,
       K.score as K_score,
       kmes.segment_code as ksm_engagement_score_code,
       kmes.segment_name as ksm_engagement_score_name,
       kmes.segment_year as ksm_engagement_score_year,
       kmes.segment_month as ksm_engagement_score_month,
       kmes.xcomment as ksm_engagement_score_comment,
       kmss.segment_code as ksm_engage_stu_score_code,
       kmss.segment_name as ksm_engage_stu_score_name,
       kmss.segment_year as ksm_engage_stu_score_year,
       kmss.segment_month as ksm_engage_stu_score_month,
       kmss.xcomment as ksm_enage_stu_score_comment,
       event_count.count_events,
       ---- i think I should listagg this????       
       el.event_name,
       el.event_start_date,
       el.event_attendance_status
from entity e 
--- Inner join degrees 
inner join d on d.donor_id = e.donor_id
--- giving info  
left join give g on g.household_primary_donor_id = e.donor_id 
--- employment
left join employ on employ.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C = e.donor_id
--- assingment
left join assign a on a.donor_id = e.donor_id
--- last contact report
left join crf on crf.constituent_donor_id = e.donor_id
--- francesca's contact report 
left join l on l.ucinn_ascendv2__donor_id__c = e.donor_id
--- involvements
left join involve on involve.constituent_donor_id = e.donor_id
--- contacts
left join co on co.donor_id = e.donor_id
--- 10K 
left join K on K.donor_id = e.donor_id
--- model
left join mods on mods.donor_id = e.donor_id
--- kellogg engagement score
left join kmes on kmes.id_number = e.donor_id
--- kellog alumni student engagement score
left join kmss on kmss.id_number = e.donor_id
--- event data
left join el on el.NU_DONOR_ID__C = e.donor_id
--- count of evnet
left join event_count on event_count.NU_DONOR_ID__C = e.donor_id
