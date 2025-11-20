create or replace view tableau_ksm_prospect as 

--- Entity 

with entity as (select *
From mv_entity e
where e.is_deceased_indicator = 'N'),
 
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
       g.expendable_cfy,
       g.expendable_pfy1,
       g.expendable_pfy2,
       g.expendable_pfy3,
       g.expendable_pfy4,
       g.expendable_pfy5,
       g.ngc_lifetime_nonanon_full_rec,
       g.last_ngc_opportunity_type,
       g.last_ngc_designation_id,
       g.last_ngc_designation,
       g.last_ngc_recognition_credit,
       g.expendable_status,
       g.expendable_status_fy_start,
       g.expendable_status_pfy1_start,
       g.last_ngc_date, 
       g.last_cash_date
       --- Add in last gift date 
from mv_ksm_giving_summary g),

--- Last Contact Report
--- Edit: 11/13/25 This is good to use to get the visit counts too

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
       ---- use counts later on
       d.constituent_visit_count,
       d.constituent_visit_last_year_count,
       d.constituent_last_visit_date,
       ---- last visit author
       case when d.constituent_last_contact_report_method = 'Visit' then
        d.constituent_last_contact_report_author end as last_visit_author
       from DM_ALUMNI.DIM_CONSTITUENT d),       
                  
---- DEAN Visits - Using Paul's Views

de as (select c.cr_relation_donor_id,
       c.cr_credit_name,
       c.contact_report_type,
       c.cr_credit_type,
       c.contact_report_visit_flag,
       c.contact_report_date,
       c.contact_report_description      
from mv_contact_reports c 
),

--- last Author and Visit for Everyone Else (Not Dean Cornelli) 

la as (select de.cr_relation_donor_id,
max (de.cr_credit_name) keep (dense_rank First Order By de.contact_report_date DESC) as last_visit_credit_name,
max (de.contact_report_type) keep (dense_rank First Order By de.contact_report_date DESC) as last_visit_report_type,
max (de.contact_report_visit_flag) keep (dense_rank First Order By de.contact_report_date DESC) as last_visit_visit_flag,
max (de.contact_report_date) keep (dense_rank First Order By de.contact_report_date DESC) as last_visit_report_date,
max (de.contact_report_description) keep (dense_rank First Order By de.contact_report_date DESC) as last_visit_description
from de
where de.cr_credit_type = 'Author'
and de.contact_report_type = 'Visit'
group by de.cr_relation_donor_id
),


--- Dean's Last Visit Using Paul's View

dcrf as (select de.cr_relation_donor_id,
max (de.cr_credit_name) keep (dense_rank First Order By de.contact_report_date DESC) as credited,
max (de.contact_report_type) keep (dense_rank First Order By de.contact_report_date DESC) as contact_report_type,
max (de.contact_report_date) keep (dense_rank First Order By de.contact_report_date DESC) as contact_date,
max (de.contact_report_description) keep (dense_rank First Order By de.contact_report_date DESC) as descripton 
from  de
where de.cr_credit_name like '%Francesca Cornelli%'
and de.contact_report_type like '%Visit%'
group by de.cr_relation_donor_id),
       
--- assignment

assign as (Select *
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

--- C-Suite Flag 
--- Take a look at Paul's Senior Titles

csuite as (select
employ.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C as donor_id,
employ.primary_job_title,
employ.primary_employer
from employ
where   ((employ.primary_job_title like '%EVP%'
or employ.primary_job_title like '%Owner%'
or employ.primary_job_title like '%Founder%'
or employ.primary_job_title like '%Managing Director%'
or employ.primary_job_title like '%Executive%'
or employ.primary_job_title like '%Partner%'
or employ.primary_job_title like '%President%'
or employ.primary_job_title like '%Principal%'
or employ.primary_job_title like '%Head%'
or employ.primary_job_title like '%Senior%'
or employ.primary_job_title like '%Chief%'
or employ.primary_job_title like '%Board%'
or employ.primary_job_title like '%Chairman%'
or employ.primary_job_title like '%Chairwoman%'
or employ.primary_job_title like '%Chairperson%'
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
or (employ.primary_job_title like '%CTO%'
        AND employ.primary_job_title not like '%DOCTOR%')
--- Chief Compliance officer
or employ.primary_job_title like '%CCO%')
--- take out assistants/associates/advisors, not actual senior titles
and (primary_job_title not like '%Assistant%'
and primary_job_title not like '%Asst%'
and primary_job_title not like '%Associate%'
and primary_job_title not like '%Assoc%'
and primary_job_title not like '%Advisor%'))),

--- Involvements 

i as (select distinct i.constituent_donor_id,
       i.constituent_name,
       i.involvement_name,
       i.involvement_type,
       i.involvement_business_unit,
       i.mv_last_refresh
from mv_involvement i
where i.involvement_status = 'Current'
and (i.involvement_name like '%KSM%'
or i.involvement_name like '%Kellogg%')),

--- Listagg Involvements 

involve as (select i.constituent_donor_id,
Listagg (i.involvement_name, ';  ') Within Group (Order By i.involvement_name) As involvement_name,
Listagg (I.INVOLVEMENT_TYPE, ';  ') Within Group (Order By i.involvement_name) As INVOLVEMENT_TYPE,
Listagg (I.INVOLVEMENT_BUSINESS_UNIT, ';  ') Within Group (Order By i.involvement_name) As  INVOLVEMENT_BUSINESS_UNIT
from i
group by i.constituent_donor_id),

--- Contact Data

---- 11/19/25 ---- use contact for geo e.g. home_geocode_primary and home_geocode_concat

co as (select c.donor_id,
       c.primary_geocodes_concat,
       c.address_preferred_type,
       c.preferred_address_line_1,
       c.preferred_address_line_2,
       c.preferred_address_line_3,
       c.preferred_address_line_4,
       c.preferred_address_city,
       c.preferred_address_state,
       c.preferred_address_postal_code,
       c.preferred_address_country,
       c.preferred_geocode_primary,
       c.preferred_geocodes_concat,
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
       c.home_geocode_primary,
       c.home_geocodes_concat,
       c.home_address_latitude,
       c.home_address_longitude,
       c.business_address_line_1,
       c.business_address_line_2,
       c.business_address_line_3,
       c.business_address_line_4,
       c.business_address_city,
       c.business_address_state,
       c.business_address_postal_code,
       c.business_address_country,
       c.business_geocode_primary,
       c.business_geocodes_concat
From mv_entity_contact_info c),

--- Use Paul's Model Score Now, Not Liam's Tables

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
  From mv_ksm_models m),

--- Event Data 
--- Campaign Data Only! Asked Melanie and the naming convention will have "Campaign" 

event as (select  
a.NU_DONOR_ID__C  ,
a.CONFERENCE360__ATTENDEE_FULL_NAME__C  ,
a.CONFERENCE360__EVENT_NAME__C  ,
a.CONFERENCE360__EVENT_START_DATE__C  ,
a.conference360__attendance_status__c
from stg_alumni.conference360__attendee__c a 
where a.NU_DONOR_ID__C  is not null
and a.conference360__attendance_status__c = 'Attended'
and a.CONFERENCE360__EVENT_NAME__C is not null
---- Campaign Asked Melanie if this was okay 
and a.CONFERENCE360__EVENT_NAME__C like '%Campaign%'),

--- Events Listagg

el as (select event.NU_DONOR_ID__C,
Listagg (event.CONFERENCE360__EVENT_NAME__C, ';  ') Within Group (Order By event.CONFERENCE360__EVENT_START_DATE__C) As event_name,
Listagg (event.CONFERENCE360__EVENT_START_DATE__C, ';  ') Within Group (Order By event.CONFERENCE360__EVENT_START_DATE__C) As event_start_date,
Listagg (event.conference360__attendance_status__c, ';  ') Within Group (Order By event.CONFERENCE360__EVENT_START_DATE__C) As event_attendance_status
from event
group by event.NU_DONOR_ID__C),

--- Event Counts 

event_count as (select event.NU_DONOR_ID__C,
count (event.CONFERENCE360__EVENT_NAME__C) as count_events
from event 
group by event.NU_DONOR_ID__C),

--- Proposal View

prop as (select *
from mv_proposals p),

--- Count of Active Proposals 

cprop as (select p.donor_id, 
count (p.proposal_active_indicator) as count_active_proposals
from prop p
group by p.donor_id),

--- Tableau Activity - Pulls Melanie's Requested Data Points

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
from Tableau_KSM_Activity t),

--- Tableau Task Report

ttr as (select 
       t.DONOR_ID,
       t.CASE_OWNER_ID,
       t.CASE_OWNER,
       t.STATUS,
       t.SUBJECT,
       t.DESCRIPTION,
       t.NONVISIT_CONTACT_DURING_TASK,
       t.TOTAL_VISITS,
       t."Unresponsive",
       t."Disqualified"
from TABLEAU_TASK_REPORT t),

--- Ratings from the Alumni Donor Table
--- Need the Date for Eval and UOR

rating as (Select d.donor_id,
       d.research_evaluation,
       d.research_evaluation_date,
       d.university_overall_rating,
       d.university_overall_rating_entry_date
From DM_ALUMNI.DIM_DONOR d),

--- Stage of Readiness

stage as (select 
stg_alumni.contact.ucinn_ascendv2__donor_id__c,
stg_alumni.contact.ucinn_ascendv2__stage_of_readiness_last_modified_date__c, 
stg_alumni.contact.ucinn_ascendv2__stage_of_readiness__c
from stg_alumni.contact),

c as (select stg_alumni.contact.id, 
stg_alumni.contact.ucinn_ascendv2__donor_id__c 
from stg_alumni.contact),

strategy as (select *
from stg_alumni.ucinn_ascendv2__strategy__c s
left join c on c.id = s.ucinn_ascendv2__contact__c
--- Active Only
where s.ap_is_active__c = 'true'
),

r as (select 

e.donor_id,
e.household_id_ksm,
e.sort_name,
a.ap_constituent__c,
a.ap_is_active_formula__c,
a.ap_is_primary_prospect_formula__c,
a.ap_is_primary_strategy__c,
a.name
from stg_alumni.ap_strategy_relation__c a 
left join  mv_entity e on e.salesforce_id = a.ap_constituent__c
where e.household_id_ksm = '0001318929'),



sr as (select r.household_id_ksm
, Listagg (r.sort_name, ';  ') Within Group (Order By r.sort_name) As strategy_relation_name_concat 
, Listagg (r.name, ';  ') Within Group (Order By r.name) As Strategy_Relation_concat
from r 
group by r.household_id_ksm)


select  distinct 
       e.donor_id,
       --- person or org added
       e.person_or_org,
       --- Let's use Household KSM 
       e.household_id_ksm,       
       e.salesforce_id,
       e.household_primary_ksm,
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
       co.preferred_address_line_1,
       co.preferred_address_line_2,
       co.preferred_address_line_3,
       co.preferred_address_line_4,
       co.preferred_address_city as preferred_city,
       co.preferred_address_state as preferred_state,
       co.preferred_address_postal_code,
       co.preferred_address_country as preferred_country,
       --- primary geocodes 
       co.primary_geocodes_concat,
       co.preferred_geocode_primary,             
       co.home_address_city,
       co.home_address_state,
       co.home_address_postal_code,
       co.home_address_country,
       --- home geocodes 
       co.home_geocode_primary,
       co.home_geocodes_concat, 
       co.business_address_city,
       co.business_address_state,
       co.business_address_postal_code,
       co.business_address_country,   
       --- business geocodes 
       co.business_geocode_primary,
       co.business_geocodes_concat,
       --- Strategy ID AKA: Prospect ID, Prospect Name (Proposal View)
       prop.proposal_strategy_record_id,
       prop.prospect_name, 
       cprop.count_active_proposals,
       rating.research_evaluation,
       rating.research_evaluation_date,
       rating.university_overall_rating,
       rating.university_overall_rating_entry_date,
       --- Stage of Readiness - timeline - Does it work?????  ---- Check Strategy      
       tka."STAGE OF READINESS", 
       tka.TEAM,
       tka.MANAGER, 
       tka."MANAGER START DATE",  
       d.first_ksm_year,
       d.program,
       d.program_group,
       employ.primary_job_title,
       employ.primary_employer,
       --- C Suite Flag
       case when csuite.donor_id is not null then 'Y' end as c_suite_flag,
       g.ngc_lifetime,      
       ---11/13 ksm lifetime recgoniton   
       ---g.ngc_lifetime_full_rec,     
       g.last_ngc_opportunity_type,
       g.last_ngc_designation,
       g.last_ngc_recognition_credit,
       g.expendable_status,
       --- Annual Fund 
       g.expendable_cfy,
       g.expendable_pfy1,
       --- Last Gift 
       g.last_ngc_date, 
       g.last_cash_date,     
       strategy.ap_prospect_id__c,
       strategy.ap_prospect_name__c,
       strategy.ap_is_active__c,      
       ---- The team for prospect manager and LAGM ("Business Unit") 
       assign.prospect_manager_name,
       assign.prospect_manager_business_unit,      
       ---- 11/13/25 prospect manager ID and Business unit     
       assign.lagm_user_id,
       assign.lagm_name,
       assign.ksm_manager_flag,
       --- Add Business Unit
       assign.lagm_business_unit,             
       --- Last Contact Report           
       crf.constituent_last_contact_report_date,
       crf.constituent_last_contact_primary_relationship_manager_date,
       crf.constituent_last_contact_report_author,
       crf.constituent_last_contact_report_purpose,
       crf.constituent_last_contact_report_method,
       crf.constituent_visit_count,
       crf.constituent_visit_last_year_count,   
        la.last_visit_credit_name,
        la.last_visit_report_type,
        la.last_visit_visit_flag,
        la.last_visit_report_date,
        la.last_visit_description,                     
---- Note 11.13.25
--- Melanie wants last dean visit description, use Paul's new Mv Contact Report View as a solution         
        dcrf.credited as dean_visit_credited,
        dcrf.contact_report_type as dean_visit_cr_type,
        dcrf.contact_date as dean_visit_contact_date,
        dcrf.descripton as dean_visit_descripton,
        --- Count of Dean Visits 
        case when crf.constituent_last_contact_report_author like '%Francesca Cornelli%'
        and crf.constituent_last_contact_report_method like '%Visit%' then crf.constituent_visit_count end as dean_visit_count,
--- Melanie - Needs the ID segment, PR Segment, Est Probability 
       mods.mg_id_description,
       mods.mg_id_score,
       mods.mg_pr_description,
       mods.mg_pr_score,
       mods.mg_probability,
       mods.af_10k_description,
       mods.af_10k_score,
       mods.alumni_engagement_score,
       mods.student_supporter_score,
       mods.etl_update_date,
       mods.mv_last_refresh,      
       ---- Campaign Events! 
       event_count.count_events as campaign_event_count,
       --- Campaign Name is okay 
       el.event_name as campaign_event_name_concat,
       el.event_start_date as campagin_event_start_date,
       el.event_attendance_status as campaign_event_status,
--- Add in Case manager- Where we are saving the Gift Officer New Leads. Amy Has a Tableau Veiws for Case Manager, Case Owner, Case Date      
       ttr.CASE_OWNER_ID,
       ttr.CASE_OWNER,
       involve.involvement_name,
       involve.INVOLVEMENT_TYPE,
       involve.INVOLVEMENT_BUSINESS_UNIT,
       --- Stage of Readiness
       stage.ucinn_ascendv2__stage_of_readiness__c,
       stage.ucinn_ascendv2__stage_of_readiness_last_modified_date__c,
       sr.strategy_relation_name_concat,
       sr.strategy_Relation_concat      
from entity e 
--- Inner join degrees 
inner join d on d.donor_id = e.donor_id
--- giving info  
left join give g on g.household_id = e.household_id_ksm
--- employment
left join employ on employ.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C = e.donor_id
--- c suite flag
left join csuite on csuite.donor_id = e.donor_id
--- assingment
left join assign assign on assign.donor_id = e.donor_id
--- last contact report
left join crf on crf.constituent_donor_id = e.donor_id
--- last visit
left join la on la.cr_relation_donor_id = e.donor_id
--- Francesca Last Visit 
left join dcrf on dcrf.cr_relation_donor_id = e.donor_id 
--- involvements
left join involve on involve.constituent_donor_id = e.donor_id
--- Contacts
left join co on co.donor_id = e.donor_id
--- Model Scores
left join mods on mods.donor_id = e.donor_id
--- event data
left join el on el.NU_DONOR_ID__C = e.donor_id
--- count of evnet
left join event_count on event_count.NU_DONOR_ID__C = e.donor_id
--- proposal
left join prop on prop.household_id_ksm = e.household_id_ksm
--- activity 
left join tka on tka.donor_id = e.donor_id
--- tableau task report
left join ttr on ttr.donor_id = e.donor_id
--- ratings
left join rating on rating.donor_id = e.donor_id
--- Stage
left join stage on stage.ucinn_ascendv2__donor_id__c = e.donor_id
--- Strategy
left join strategy on strategy.ucinn_ascendv2__donor_id__c = e.donor_id
--- Count proposals
left join cprop on cprop.donor_id = e.donor_id
--- strategy relation
left join sr on sr.household_id_ksm = e.household_id_ksm
 