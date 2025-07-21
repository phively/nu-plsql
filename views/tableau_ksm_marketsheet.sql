--- Employment - primary
--- Also use keep dense rank function to pull most recent employee start date

with employ as (select distinct
c.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C,
max (c.ap_is_primary_employment__c) keep (dense_rank First Order by c.ucinn_ascendv2__start_date__c desc) as primary_employ_ind,
max (c.ucinn_ascendv2__job_title__c) keep (dense_rank first order by c.ucinn_ascendv2__start_date__c desc) as primary_job_title,
max (c.UCINN_ASCENDV2__RELATED_ACCOUNT_NAME_FORMULA__C) keep (dense_rank first order by c.ucinn_ascendv2__start_date__c desc) as primary_employer
from stg_alumni.ucinn_ascendv2__Affiliation__c c
where c.ap_is_primary_employment__c = 'true'
group by c.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C),

/* 

Wait on Geocode 

geocode as (select distinct g.ap_address_relation_record_type__c,
                        g.ap_address_relation__c,
                        g.ap_constituent__c,
                        g.ap_end_date__c,
                        g.ap_geocode_value_description__c,
                        g.ap_geocode_value_end_zip_formula__c,
                        g.ap_geocode_value_start_zip_formula__c,
                        g.ap_geocode_value_type__c,
                        g.ap_geocode_value__c,
                        g.ap_is_active__c,
                        g.ap_is_constituent_address_relation__c,
                        g.ap_is_patient_only__c,
                        g.ap_notes__c,
                        g.ap_organization__c,
                        g.ap_start_date__c,
                        g.ap_zone__c,
                        g.createdbyid,
                        g.createddate,
                        g.geocode_value_type_description__c,
                        g.id,
                        g.isdeleted,
                        g.lastactivitydate,
                        g.lastmodifiedbyid,
                        g.lastmodifieddate,
                        g.lastreferenceddate,
                        g.lastvieweddate,
                        g.name,
                        g.ownerid,
                        g.recordtypeid,
                        g.systemmodstamp,
                        g.etl_create_date,
                        g.etl_update_date
from stg_alumni.ap_geocode__c g
where g.ap_is_active__c = 'true'),

fa as (select geocode.id,
s.firstname,
s.lastname,
s.ucinn_ascendv2__donor_id__c,
       geocode.ap_geocode_value_description__c,
       a.ucinn_ascendv2__address__c,
       a.ucinn_ascendv2__account__c,
       a.ucinn_ascendv2__address_relation_name_auto_number__c,
       a.ucinn_ascendv2__contact__c,
       a.ucinn_ascendv2__data_source__c,
       a.ucinn_ascendv2__end_date__c,
       a.ucinn_ascendv2__in_care_of__c,
       a.ucinn_ascendv2__is_preferred__c,
       a.ucinn_ascendv2__seasonal_end_day__c,
       a.ucinn_ascendv2__seasonal_end_month__c,
       a.ucinn_ascendv2__seasonal_end_year__c,
       a.ucinn_ascendv2__seasonal_start_day__c,
       a.ucinn_ascendv2__seasonal_start_month__c,
       a.ucinn_ascendv2__seasonal_start_year__c,
       a.ucinn_ascendv2__source__c,
       a.ucinn_ascendv2__start_date__c,
       a.ucinn_ascendv2__status__c,
       a.ucinn_ascendv2__type__c,
       a.ucinn_ascendv2__address_city_formula__c,
       a.ucinn_ascendv2__address_postal_code_formula__c,
       a.ucinn_ascendv2__address_state_formula__c,
       a.ucinn_ascendv2__address_street_formula__c,
       a.ucinn_ascendv2__full_address_formula__c,
       a.ucinn_ascendv2__is_active_seasonal_address__c,
       a.ap_is_campus__c,
       a.ap_number_of_times_returned__c,
       a.etl_create_date,
       a.etl_update_date,
       
from stg_alumni.ucinn_ascendv2__address_relation__c a
inner join geocode on geocode.ap_address_relation__c = a.id
left join stg_alumni.contact s on s.id = a.ucinn_ascendv2__contact__c
left join fa on fa.ucinn_ascendv2__donor_id__c = e.donor_id

where a.ucinn_ascendv2__is_preferred__c = 'true'

),

*/

--- Top Prospect

TP as (select C.CONSTITUENT_DONOR_ID,
c.constituent_university_overall_rating,
c.constituent_research_evaluation
from DM_ALUMNI.DIM_CONSTITUENT C ),


--- Special Handling

S as (select  
       s.donor_id,
       s.no_contact,
       s.no_email_ind,
       s.gab,
       s.trustee,
       s.ebfa,
       s.no_solicit,
       s.no_phone_sol_ind,
       s.no_email_sol_ind,
       s.no_mail_sol_ind,
       s.no_texts_sol_ind
from mv_special_handling s),

--- Giving Summary

give as (select g.household_id,
g.household_primary_donor_id,
       g.ngc_lifetime,
       g.ngc_cfy,
       g.ngc_pfy1,
       g.ngc_pfy2,
       g.ngc_pfy3,
       g.ngc_pfy4,
       g.ngc_pfy5
from mv_ksm_giving_summary g),

d as (select d.donor_id,
       d.full_name,
       d.sort_name,
       d.degrees_verbose,
       d.degrees_concat,
       d.first_ksm_grad_date,
       d.first_ksm_year,
       d.first_masters_year,
       d.last_masters_year,
       d.last_noncert_year,
       d.program,
       d.program_group,
       d.program_group_rank,
       d.class_section,
       d.majors_concat,
       d.etl_update_date,
       d.mv_last_refresh
from mv_entity_ksm_degrees d),

a as (select
stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__contact__c,
max (stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__url__c) keep (dense_rank first order by stg_alumni.ucinn_ascendv2__social_media__c.lastmodifieddate) as Linkedin_address
from stg_alumni.ucinn_ascendv2__social_media__c
where stg_alumni.ucinn_ascendv2__social_media__c.ap_status__c like '%Current%'
and stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__platform__c = 'LinkedIn'
group BY stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__contact__c
),

-- max(linkedin_url) keep dense_rank first ...
--- Using Keep Dense Rank

l as (select distinct c.ucinn_ascendv2__donor_id__c,
c.ucinn_ascendv2__first_and_last_name_formula__c,
a.linkedin_address
from stg_alumni.contact c
inner join a on c.id = a.ucinn_ascendv2__contact__c)


select e.person_or_org,
       e.household_primary,
       e.donor_id,
       e.full_name,
       e.institutional_suffix,
       e.preferred_address_city,
       e.preferred_address_state,
       e.preferred_address_country,
       d.full_name,
       d.sort_name,
       d.degrees_verbose,
       d.degrees_concat,
       d.first_ksm_grad_date,
       d.first_ksm_year,
       d.first_masters_year,
       d.last_masters_year,
       d.last_noncert_year,
       d.program,
       d.program_group,
       d.program_group_rank,
       d.class_section,
       employ.primary_employer,
       employ.primary_job_title,
       l.linkedin_address,
       give.ngc_lifetime,
       give.ngc_cfy,
       give.ngc_pfy1,
       give.ngc_pfy2,
       give.ngc_pfy3,
       give.ngc_pfy4,
       give.ngc_pfy5,
       e.university_overall_rating,
       e.research_evaluation,
       e.research_evaluation_date,
       s.donor_id,
       s.no_contact,
       s.no_email_ind,
       s.gab,
       s.trustee,
       s.ebfa,
       s.no_solicit,
       s.no_phone_sol_ind,
       s.no_email_sol_ind,
       s.no_mail_sol_ind,
       s.no_texts_sol_ind
       
from mv_entity e
inner join d on d.donor_id = e.donor_id 
--- empoloyment
left join employ on employ.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C = e.donor_id
--- giving
left join give on give.household_primary_donor_id = e.donor_id
--- Linkedin 
left join l on l.ucinn_ascendv2__donor_id__c = e.donor_id
--- Special handling
left join s on s.donor_id = e.donor_id
