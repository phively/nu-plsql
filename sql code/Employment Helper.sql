--- pulling linkedin

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
a.linkedin_address
from stg_alumni.contact c
inner join a on c.id = a.ucinn_ascendv2__contact__c),

--- Employment - primary
--- Also use keep dense rank function to pull most recent employee start date

employ as (select distinct
c.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C as id_number,
c.ucinn_ascendv2__status__c as status,
c.ap_is_primary_employment__c as primary_employ_ind,
c.ucinn_ascendv2__job_title__c as job_title,
c.UCINN_ASCENDV2__RELATED_ACCOUNT_NAME_FORMULA__C as employer,
c.ucinn_ascendv2__constituent_role__c as consitutent_role,
c.ucinn_ascendv2__data_source__c as data_source,
c.ucinn_ascendv2__start_date__c as start_date,
c.ucinn_ascendv2__end_date__c as end_date,
c.etl_update_date,
c.etl_create_date,
c.ucinn_ascendv2__notes__c as notes
from stg_alumni.ucinn_ascendv2__Affiliation__c c),

--- C-Suite Flag
--- Employment with Senior Titles

csuite as (select
employ.id_number
from employ
where   ((job_title like '%Vice President%'
or job_title like '%VP%'
or job_title like '%Owner%'
or job_title like '%Founder%'
or job_title like '%Managing Director%'
or job_title like '%Executive%'
or job_title like '%Partner%'
or job_title like '%President%'
or job_title like '%Principal%'
or job_title like '%Head%'
---or job_title like '%Senior%'
or job_title like '%Chief%'
or job_title like '%Board%'
---- Check Abbreviations too 
or job_title like '%CEO%'
--- Chief Finance Officer
or job_title like '%CFO%'
--- Chief Marketing Officer
or job_title like '%CMO%'
--- Chief Information Officer
or job_title like '%CIO%'
--- Chiefer Operating Office
or job_title like '%COO%'
--- Chief Tech Officer
or job_title like '%CTO%'
--- Chief Compliance officer
or job_title like '%CCO%'



)

--- take out assistants/associates/advisors, not actual senior titles

and (job_title not like '%Assistant%'
and job_title not like '%Asst%'
and job_title not like '%Associate%'
and job_title not like '%Assoc%'
and job_title not like '%Advisor%'
and job_title not like '%Workspace Product Partnerships%')))

select e.donor_id,
employ.status,
employ.primary_employ_ind,
employ.job_title,
employ.employer,
case when csuite.id_number is not null then 'Y' end as csuite_ind,
--- Start and End Dates
employ.start_date,
employ.end_date,
employ.consitutent_role,
employ.data_source,
--- Create and Updated Date in CATConnect
employ.etl_update_date,
employ.etl_create_date,
employ.notes
from mv_entity e
inner join employ on employ.id_number = e.donor_id
left join csuite on csuite.id_number = e.donor_id
