Create or Replace View tableau_ksm_marketsheet as 

with employ as (select distinct
c.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C,
max (c.ap_is_primary_employment__c) keep (dense_rank First Order by c.ucinn_ascendv2__start_date__c desc) as primary_employ_ind,
max (c.ucinn_ascendv2__job_title__c) keep (dense_rank first order by c.ucinn_ascendv2__start_date__c desc) as primary_job_title,
max (c.UCINN_ASCENDV2__RELATED_ACCOUNT_NAME_FORMULA__C) keep (dense_rank first order by c.ucinn_ascendv2__start_date__c desc) as primary_employer
from stg_alumni.ucinn_ascendv2__Affiliation__c c
where c.ap_is_primary_employment__c = 'true'
group by c.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C),


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

select 
       e.donor_id,
       e.person_or_org,
       e.household_primary,
       e.full_name,
       e.institutional_suffix,
       e.preferred_address_city,
       e.preferred_address_state,
       e.preferred_address_country,
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
--- giving 
       give.ngc_lifetime,
       give.ngc_cfy,
       give.ngc_pfy1,
       give.ngc_pfy2,
       give.ngc_pfy3,
       give.ngc_pfy4,
       give.ngc_pfy5,
--- ratings 
       e.university_overall_rating,
       e.research_evaluation,
       e.research_evaluation_date,
--- special handling and gab, trustee, ebfa flags 
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
