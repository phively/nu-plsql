--- Create or Replace View Tableau_NU_Events

with v as (select 
event.id,
event.name,
event.conference360__organizer_account__c,
event.conference360__organizer_contact__c, 
--- Kellogg Event Flag 
case when event.name like '%KSM%'
or event.name like '%Kellogg%' 
or event.conference360__organizer_contact__c like '%Kellogg%'
or event.conference360__organizer_contact__c like '%KSM%'
then 'Y' end as KSM_Event,
event.conference360__status__c,
event.conference360__category__c,
event.conference360__event_end_date__c,
event.conference360__event_start_date__c,
event.conference360__event_url__c,
event.etl_create_date, 
event.etl_update_date,
event.conference360__venue_city__c,
event.conference360__venue_country__c,
event.conference360__venue_name__c,
event.conference360__venue_postal_code__c,
event.conference360__venue_state_province__c,
event.conference360__venue_status__c,
event.conference360__venue_street__c,
event.conference360__venue__c
from stg_alumni.conference360__event__c event)

/* 

Final Query 

Event ID Event Name, Date, Status, 
Category, Organizer, Location, URL,

*/ 

select 
v.id as salesforce_event_id,
v.name as event_name,
v.conference360__status__c as status,
v.conference360__category__c as event_category,
v.conference360__event_start_date__c as event_start_date,
v.conference360__event_end_date__c as event_end_date,
v.conference360__organizer_account__c as organizer_account,
v.conference360__organizer_contact__c as organizer_contact, 
v.KSM_Event,
v.conference360__event_url__c as url_link,
v.conference360__venue_name__c as venue_name,
v.conference360__venue_city__c as venue_city,
v.conference360__venue_country__c as venue_country,
v.conference360__venue_postal_code__c as venue_post_code,
v.etl_create_date as create_date, 
v.etl_update_date as update_date
from v 
