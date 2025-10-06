create or replace view tableau_ksm_prospect as 

with entity as (select e.person_or_org,
       e.salesforce_id,
       e.household_id,
       e.household_primary,
       e.donor_id,
       e.full_name,
       e.sort_name,
       e.salutation,
       e.first_name,
       e.middle_name,
       e.last_name,
       e.is_deceased_indicator,
       e.lost_indicator,
       e.donor_advised_fund_indicator,
       e.primary_record_type,
       e.institutional_suffix,
       e.spouse_donor_id,
       e.spouse_name,
       e.spouse_institutional_suffix,
       e.org_ult_parent_donor_id,
       e.org_ult_parent_name,
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
       e.gender_identity,
       e.citizenship,
       e.ethnicity,
       e.university_overall_rating,
       e.research_evaluation,
       e.research_evaluation_date,
       e.etl_update_date,
       e.mv_last_refresh
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
       g.af_young_alum,
       g.af_young_alum1,
       g.af_young_alum2,
       g.af_young_alum3,
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

--- Listagg this

l as (select a.ucinn_ascendv2__donor_id__c,
Listagg (a.ap_contact_report_author_name_formula__c, ';  ') Within Group (Order By a.ucinn_ascendv2__date__c) As author_name,
Listagg (a.ucinn_ascendv2__contact_method__c, ';  ') Within Group (Order By a.ucinn_ascendv2__date__c) As contact_type,
Listagg (a.ucinn_ascendv2__date__c, ';  ') Within Group (Order By a.ucinn_ascendv2__date__c) As cr_date,
Listagg (a.ucinn_ascendv2__description__c, ';  ') Within Group (Order By a.ucinn_ascendv2__date__c) As ucinn_ascendv2__description__c
from a
group by a.ucinn_ascendv2__donor_id__c),

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
from mv_involvement i),

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
From mv_entity_contact_info c)


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
       g.af_young_alum,
       g.af_young_alum1,
       g.af_young_alum2,
       g.af_young_alum3,
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
       i.involvement_name,
       crf.constituent_last_contact_report_date,
       crf.constituent_last_contact_primary_relationship_manager_date,
       crf.constituent_last_contact_report_author,
       crf.constituent_last_contact_report_purpose,
       crf.constituent_last_contact_report_method,
       crf.constituent_visit_count,
       crf.constituent_visit_last_year_count,
       crf.constituent_last_visit_date
from entity e 
inner join d d on d.donor_id = e.donor_id 
left join give g on g.household_primary_donor_id = e.donor_id 
left join employ on employ.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C = e.donor_id
left join assign a on a.donor_id = e.donor_id
left join crf on crf.constituent_donor_id = e.donor_id
left join l on l.ucinn_ascendv2__donor_id__c = e.donor_id
left join i on i.constituent_donor_id = e.donor_id
left join co on co.donor_id = e.donor_id
