--- KSM 2026 Reunion 

Create or Replace View tableau_ksm_2026_reunion as 

With manual_dates As (
Select
  2025 AS pfy
  ,2026 AS cfy
  From DUAL
),

/* We will invite Full time, E&W, TMP (Part time),
JDMBA, MMM, MBAi, Business Undergrad (old program)*/

KSM_Degrees as (Select d.donor_id,
d.program,
d.program_group,
d.first_ksm_year,
d.first_masters_year,
d.degrees_verbose,
d.class_section
From mv_entity_ksm_degrees d),

--- Pull Kellogg Reunion Year 

d as (select c.id,
       c.ucinn_ascendv2__contact__c,
       c.ucinn_ascendv2__reunion_year__c,
       c.ap_school_reunion_year__c
from stg_alumni.ucinn_ascendv2__degree_information__c c
where c.ap_school_reunion_year__c like '%Kellogg%'
and c.ap_degree_type_from_degreecode__c != 'Certificate'
),

--- Reunion Year 
--- This is to get donor IDs that tie to the degree table 

reunion_year as (select a.ucinn_ascendv2__donor_id__c,
a.firstname,
a.lastname,
d.ucinn_ascendv2__reunion_year__c,
KD.program,
KD.program_group,
KD.first_ksm_year,
KD.first_masters_year,
KD.degrees_verbose,
KD.class_section
from stg_alumni.contact a
CROSS JOIN manual_dates MD
inner join d on d.ucinn_ascendv2__contact__c = a.id
inner join KSM_Degrees KD on KD.donor_id = a.ucinn_ascendv2__donor_id__c
where (TO_NUMBER(NVL(TRIM(d.ucinn_ascendv2__reunion_year__c),'1')) IN (MD.CFY-1, MD.CFY-5, MD.CFY-10, MD.CFY-15, MD.CFY-20, 
MD.CFY-25, MD.CFY-30, MD.CFY-35, MD.CFY-40,
MD.CFY-45, MD.CFY-50, MD.CFY-51, MD.CFY-52, 
MD.CFY-53, MD.CFY-54, MD.CFY-55, MD.CFY-56, 
MD.CFY-57, MD.CFY-58, MD.CFY-59, MD.CFY-60))

AND KD.PROGRAM IN (
 --- All EMBA
 'EMP', 'EMP-FL', 'EMP-IL', 'EMP-CAN', 'EMP-GER', 'EMP-HK', 'EMP-ISR', 'EMP-JAN', 'EMP-CHI', 
--- No PHDs for now. We don't directly invite them, but won't turn them down. Could be a one time ad-hoc if requested. 
--- Full Time 
 'FT', 'FT-1Y', 'FT-2Y', 'FT-JDMBA', 'FT-MMGT', 'FT-MMM',
--- Include MSMS (AKA MiM) and MBAi 
 'FT-MS', 'FT-MBAi', 
---- The old Undergrad programs - should be 50+ milestone Now
 'FT-CB', 'FT-EB',
 --- Evening and Weekend 
 'TMP', 'TMP-SAT','TMP-SATXCEL', 'TMP-XCEL')),

--- listag reunion
-- Some have more than 2 preferred KSM Reunions 

l as (select reunion_year.ucinn_ascendv2__donor_id__c,
Listagg (distinct reunion_year.ucinn_ascendv2__reunion_year__c, ';  ') Within Group (Order By reunion_year.ucinn_ascendv2__reunion_year__c)
As reunion_year_concat
from reunion_year
group by reunion_year.ucinn_ascendv2__donor_id__c
),

--- Final Reunion Subquery 

FR as (select l.ucinn_ascendv2__donor_id__c,
l.reunion_year_concat,
reunion_year.first_ksm_year,
reunion_year.program,
reunion_year.program_group,
reunion_year.class_section,
reunion_year.first_masters_year,
reunion_year.degrees_verbose
from l 
inner join KSM_Degrees on KSM_Degrees.donor_id = l.ucinn_ascendv2__donor_id__c
inner join reunion_year on reunion_year.ucinn_ascendv2__donor_id__c = l.ucinn_ascendv2__donor_id__c),

--- Current Linkedin Addresses
a as (select
stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__contact__c,
max (stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__url__c) keep (dense_rank first order by stg_alumni.ucinn_ascendv2__social_media__c.lastmodifieddate) as Linkedin_address
from stg_alumni.ucinn_ascendv2__social_media__c
where stg_alumni.ucinn_ascendv2__social_media__c.ap_status__c like '%Current%'
group BY stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__contact__c
),

-- max(linkedin_url) keep dense_rank first ...
--- Using Keep Dense Rank

linked as (select distinct c.ucinn_ascendv2__donor_id__c,
c.ucinn_ascendv2__first_and_last_name_formula__c,
a.linkedin_address
from stg_alumni.contact c
inner join a on c.id = a.ucinn_ascendv2__contact__c),


e as (select mv_entity.household_id,
       mv_entity.donor_id,
       mv_entity.full_name,
       mv_entity.first_name,
       mv_entity.last_name,
       mv_entity.is_deceased_indicator,
       mv_entity.primary_record_type,
       mv_entity.institutional_suffix,
       mv_entity.spouse_donor_id,
       mv_entity.spouse_name,
       mv_entity.spouse_institutional_suffix,
       mv_entity.preferred_address_status,
       mv_entity.preferred_address_type,
       mv_entity.preferred_address_line_1,
       mv_entity.preferred_address_line_2,
       mv_entity.preferred_address_line_3,
       mv_entity.preferred_address_line_4,
       mv_entity.preferred_address_city,
       mv_entity.preferred_address_state,
       mv_entity.preferred_address_postal_code,
       mv_entity.preferred_address_country
 From mv_entity
 where mv_entity.is_deceased_indicator = 'N'
 ),
 
--- Giving Summary

give as (select *
       from mv_ksm_giving_summary g),
       
--- employment 
       
employ as (select distinct
c.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C,
max (c.ap_is_primary_employment__c) keep (dense_rank First Order by c.ucinn_ascendv2__start_date__c desc) as primary_employ_ind,
max (c.ucinn_ascendv2__job_title__c) keep (dense_rank first order by c.ucinn_ascendv2__start_date__c desc) as primary_job_title,
max (c.UCINN_ASCENDV2__RELATED_ACCOUNT_NAME_FORMULA__C) keep (dense_rank first order by c.ucinn_ascendv2__start_date__c desc) as primary_employer
from stg_alumni.ucinn_ascendv2__Affiliation__c c
where c.ap_is_primary_employment__c = 'true'
group by c.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C),

--- Special Handling 

SH as (select  s.donor_id,
       s.no_contact,
       s.no_mail_ind,
       s.no_email_ind,
       s.no_phone_ind,
       s.never_engaged_forever,
       s.never_engaged_reunion
from mv_special_handling s),

--- email

email as (select  c.ucinn_ascendv2__donor_id__c,
c.email
from stg_alumni.contact c),

--- Phone

phone as (select c.ucinn_ascendv2__donor_id__c,
c.phone
from stg_alumni.contact c),

-- GAB

GAB as (Select *
From v_committee_gab),

--- KAC

kac as (select *
from v_committee_kac),

--- Trustee

trustee as (Select *
From v_committee_trustee),

--- Top Prospect

TP as (select C.CONSTITUENT_DONOR_ID,
c.constituent_university_overall_rating,
c.constituent_research_evaluation
from DM_ALUMNI.DIM_CONSTITUENT C ),

--- Asia exec board
asia as (Select *
From v_committee_asia),

--- Assignment

assign as (Select a.household_id,
       a.donor_id,
       a.sort_name,
       a.prospect_manager_name,
       a.lagm_user_id,
       a.lagm_name
From mv_assignments a),

--- Salutation + Contact Reports 

s as (select d.constituent_donor_id,
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
       from DM_ALUMNI.DIM_CONSTITUENT d ),
       
--- 2016 Reunion Attendees 

r16 as (SELECT r16.id_number
FROM ksm_2016_reunion r16),

--- 20 Reunion Attendees 

r22 as (SELECT r22.id_number
FROM ksm_2022_weekend1_reunion r22)

 
select distinct e.household_id,
       e.donor_id,
       e.is_deceased_indicator,
       e.primary_record_type,
       s.gender_identity,
       s.salutation,
       e.full_name,
       e.first_name,
       e.last_name,
       e.institutional_suffix,
       e.spouse_donor_id,
       e.spouse_name,
       e.spouse_institutional_suffix,
       FR.reunion_year_concat,
       FR.first_ksm_year,
       FR.first_masters_year,
       FR.degrees_verbose,
       FR.program,
       FR.program_group,
       FR.class_section,
       case when r16.id_number is not null then 'Reunion 2016 Attendee' end as Reunion_16_Attendee,
       case when r22.id_number is not null then 'Reunion 2022 Attendee' end as Reunion_22_Attendee,
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
       g.household_id,
       g.household_primary_donor_id,
       g.ngc_fy_giving_first_yr,
       g.cash_fy_giving_first_yr,
       g.ngc_lifetime,
       g.ngc_cfy,
       g.ngc_pfy1,
       g.ngc_pfy2,
       g.ngc_pfy3,
       g.ngc_pfy4,
       g.ngc_pfy5,
       g.ngc_lifetime,
       g.cash_lifetime,
       g.expendable_cfy,
       g.expendable_pfy1,
       g.expendable_pfy2,
       g.expendable_pfy3,
       g.expendable_pfy4,
       g.expendable_pfy5,
       g.last_cash_tx_id,
       g.last_cash_date,
       g.last_cash_opportunity_type,
       g.last_cash_designation_id,
       g.last_cash_designation,
       g.last_cash_recognition_credit,
       g.last_pledge_tx_id,
       g.last_pledge_date,
       g.last_pledge_opportunity_type,
       g.last_pledge_designation_id,
       g.last_pledge_designation,
       g.last_pledge_recognition_credit,
       g.expendable_status,
       g.expendable_status_fy_start,
       g.expendable_status_pfy1_start,
       linked.linkedin_address,
       employ.primary_employ_ind,
       employ.primary_job_title,
       employ.primary_employer,
       case when sh.no_email_ind is null and sh.no_contact is null then email.email end as email,
       case when sh.no_phone_ind is null and sh.no_contact is null then phone.phone end as phone,
       phone.phone,
       sh.no_contact,
       sh.no_mail_ind,
       sh.no_email_ind,
       sh.never_engaged_forever,
       sh.never_engaged_reunion,
       gab.involvement_name as gab,
       trustee.involvement_name as trustee,
       kac.involvement_name as kac,
       asia.involvement_name as asia_exec_board,
       tp.constituent_university_overall_rating,
       tp.constituent_research_evaluation,
       s.constituent_contact_report_count,
       s.constituent_contact_report_last_year_count,
       s.constituent_last_contact_report_record_id,
       s.constituent_last_contact_report_date,
       s.constituent_last_contact_primary_relationship_manager_date,
       s.constituent_last_contact_report_author,
       s.constituent_last_contact_report_purpose,
       s.constituent_last_contact_report_method,
       s.constituent_visit_count,
       s.constituent_visit_last_year_count,
       s.constituent_last_visit_date
      
from e 
inner join FR on FR.ucinn_ascendv2__donor_id__c = e.donor_id 
left join give g on g.household_primary_donor_id = e.donor_id 
left join linked on linked.ucinn_ascendv2__donor_id__c = e.donor_id 
left join employ on employ.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C = e.donor_id
left join SH on SH.donor_id = e.donor_id 
left join email on email.ucinn_ascendv2__donor_id__c = e.donor_id
left join phone on phone.ucinn_ascendv2__donor_id__c = e.donor_id 
left join gab on gab.constituent_donor_id = e.donor_id 
left join trustee on trustee.constituent_donor_id = e.donor_id
left join asia on asia.constituent_donor_id = e.donor_id
left join kac on kac.constituent_donor_id = e.donor_id
left join TP on TP.CONSTITUENT_DONOR_ID = e.donor_id
left join assign on assign.donor_id = e.donor_id
left join s on s.constituent_donor_id = e.donor_id 
left join r16 on r16.id_number = e.donor_id 
left join r22 on r22.id_number = e.donor_id
