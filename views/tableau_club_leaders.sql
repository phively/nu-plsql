create or replace view tableau_club_leaders as 

--- Current Linkedin Addresses
with a as (select
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
inner join a on c.id = a.ucinn_ascendv2__contact__c),

--- Assignment

assign as (Select a.donor_id,
       a.prospect_manager_name,
       a.lagm_name
From mv_assignments a),


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

--- clubs

club as (select i.constituent_donor_id,
       i.constituent_name,
       i.involvement_name,
       i.involvement_status,
       i.involvement_type,
       i.involvement_role,
       i.involvement_business_unit,
       i.involvement_start_date
from i
where (i.involvement_role IN ('Club Leader',
'President','President-Elect','Director',
'Secretary','Treasurer','Executive')
--- Current will suffice for the date
and i.involvement_status = 'Current'
and (i.involvement_name  like '%Kellogg%'
or i.involvement_name  like '%KSM%'))),

--- Listagging because someone could be multiple club leader

cl as (select club.constituent_donor_id,
        Listagg (club.involvement_name, ';  ') Within Group (Order By club.involvement_name) As involvement_name,
        Listagg (club.involvement_status, ';  ') Within Group (Order By club.involvement_status) As involvement_status,
        Listagg (club.involvement_type, ';  ') Within Group (Order By club.involvement_type) As involvement_type,
        Listagg (club.involvement_role, ';  ') Within Group (Order By club.involvement_role) As involvement_role
 from club
 group by club.constituent_donor_id)

select distinct
       e.donor_id,
       e.household_id,
       e.sort_name,
       e.primary_record_type,
       e.institutional_suffix,    
       e.preferred_address_city,
       e.preferred_address_state,
       e.preferred_address_country,
       cl.involvement_name,
       cl.involvement_status,
       cl.involvement_type,
       cl.involvement_role,
       assign.prospect_manager_name,
       assign.lagm_name,
       l.linkedin_address    
from mv_entity e
--- Needs to be a club leader
inner join cl on cl.constituent_donor_id = e.donor_id 
--- linkedin
left join l on l.ucinn_ascendv2__donor_id__c = e.donor_id
--- assign
left join assign on assign.donor_id = e.donor_id
order by cl.involvement_name
