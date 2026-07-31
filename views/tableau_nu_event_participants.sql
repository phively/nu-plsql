--- Create or Replace tableau_nu_event_participants as 

with event as (select  
a.NU_DONOR_ID__C  as donor_id,
a.CONFERENCE360__ATTENDEE_FULL_NAME__C as full_name ,
a.CONFERENCE360__EVENT_NAME__C  as event_name,
a.CONFERENCE360__EVENT_START_DATE__C as start_date,
a.conference360__event_end_date__c as end_date,
a.conference360__event_organizer_name__c as organizer_name,
a.conference360__registration_status__c as registration_status,
a.conference360__attendance_status__c as attendance_status,
a.conference360__event_id__c as event_id,
case when a.CONFERENCE360__EVENT_NAME__C like '%KSM%'
or a.CONFERENCE360__EVENT_NAME__C like '%Kellogg%' 
or a.conference360__event_organizer_name__c like '%Kellogg%'
or a.conference360__event_organizer_name__c like '%KSM%'
then 'Y' end as KSM_Event
from stg_alumni.conference360__attendee__c a 
where a.NU_DONOR_ID__C  is not null
and a.CONFERENCE360__EVENT_NAME__C is not null),

--- Entity 

e as (select *
from mv_entity e)

--- Raw Data Cleaned 

select  
e.household_id,
e.household_id_ksm,
e.donor_id,
e.full_name,
e.sort_name,
e.person_or_org,
e.household_primary,
e.household_primary_ksm,
e.institutional_suffix,
event.event_id, 
event.event_name,
event.organizer_name,
event.KSM_Event,
event.start_date,
event.end_date, 
event.registration_status,
event.attendance_status
from event
inner join e on event.donor_id = e.donor_id
order by event.start_date asc 
