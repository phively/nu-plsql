--- pulling linkedin

with l as (select i.donor_id, i.linkedin_url
from mv_entity_contact_info i
),

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
from stg_alumni.ucinn_ascendv2__Affiliation__c c)

select e.donor_id,
employ.status,
employ.primary_employ_ind,
employ.job_title,
employ.employer,
case when (employ.job_title = 'EVP'
or employ.job_title = 'Owner'
or employ.job_title = 'Founder'
or employ.job_title = 'Partner'
or employ.job_title = 'Principal')
or (employ.job_title like '%President%'
and employ.job_title not like '%Vice%')
or 
(employ.job_title like '%Chief%'
and employ.job_title not like '%Advisor%'
and employ.job_title not like '%Assist%'
and employ.job_title not like '%Associate%'
and employ.job_title not like '%Aide%')
or 
(employ.job_title = 'Board Chair'
or  employ.job_title = 'Board Member'
or  employ.job_title = 'Board Dirs'
or  employ.job_title = 'Board of Directors%'
or  employ.job_title = 'Chairwoman'
or employ.job_title = 'Chairman')
---- Check Abbreviations too 
or (employ.job_title = 'CEO'
--- Chief Finance Officer
or employ.job_title = 'CFO'
--- Chief Marketing Officer
or employ.job_title = 'CMO'
--- Chief Information Officer
or employ.job_title ='CIO'
--- Chiefer Operating Office
or employ.job_title = 'COO'
--- Chief Tech Officer
or employ.job_title = 'CTO'
--- Chief Compliance officer
or employ.job_title = 'CCO'
--- Chief Human Resources officer
or employ.job_title = 'CHRO'
--- Chief Legal Officer
or employ.job_title = 'CLO'
--- Chief Data Officer
or employ.job_title = 'CDO'
--- Chief Information Security Officer
or employ.job_title = 'CISO'
--- Chief Strategy Officer
or employ.job_title = 'CSO'
)  then 'Y' end as csuite_ind,
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
left join l on l.donor_id = e.donor_id
