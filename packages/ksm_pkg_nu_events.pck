Create Or Replace Package ksm_pkg_nu_events Is

/*************************************************************************
Author  : SSH5552
Created : 9-14-2026
Purpose : Used to pull nu events, identify KSM events and event details
Dependencies: stg_alumni.conference360__event__c, ksm_pkg_entity (mv_entity)

Suggested naming conventions:
  Pure functions: [function type]_[description]
  Row-by-row retrieval (slow): get_[object type]_[action or description] e.g.
  Table or cursor retrieval (fast): tbl_[object type]_[action or description]
*************************************************************************/

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_nu_events';

/*************************************************************************
Public type declarations
*************************************************************************/

Type rec_nu_events Is Record (
salesforce_event_id   stg_alumni.conference360__event__c.id%type 
,event_name           stg_alumni.conference360__event__c.name%type
,status               stg_alumni.conference360__event__c.conference360__status__c%type
,event_start_date     stg_alumni.conference360__event__c.conference360__event_start_date__c%type
,event_end_date       stg_alumni.conference360__event__c.conference360__event_end_date__c%type
,event_category       stg_alumni.conference360__event__c.conference360__category__c%type
,organizer_account    stg_alumni.conference360__event__c.conference360__organizer_account__c%type
,organizer_name       mv_entity.sort_name%type
,KSM_Event            varchar2(10)
,url_link             stg_alumni.conference360__event__c.conference360__event_url__c%type
,venue_name           stg_alumni.conference360__event__c.conference360__venue_name__c%type               
,venue_city           stg_alumni.conference360__event__c.conference360__venue_city__c%type
,venue_state          stg_alumni.conference360__event__c.conference360__venue_state_province__c%type
,venue_country        stg_alumni.conference360__event__c.conference360__venue_country__c%type
,create_date          stg_alumni.conference360__event__c.etl_create_date%type
,update_date          stg_alumni.conference360__event__c.etl_update_date%type 
);

Type rec_nu_participants Is Record (

household_id              mv_entity.household_id%type 
,household_id_ksm         mv_entity.household_id_ksm%type
,donor_id                 mv_entity.donor_id%type
,full_name                mv_entity.full_name%type
,sort_name                mv_entity.sort_name%type
,person_or_org            mv_entity.person_or_org%type
,household_primary        mv_entity.household_primary%type
,household_primary_ksm    mv_entity.household_primary_ksm%type
,institutional_suffix     mv_entity.institutional_suffix%type
,event_id                 stg_alumni.conference360__attendee__c.conference360__event_id__c%type
,event_name               stg_alumni.conference360__attendee__c.CONFERENCE360__EVENT_NAME__C%type
,organizer_name           stg_alumni.conference360__attendee__c.conference360__event_organizer_name__c%type
--- KSM Event Flag 
,KSM_Event                varchar2(1) 
,start_date               stg_alumni.conference360__attendee__c.CONFERENCE360__EVENT_START_DATE__C%type
,end_date                 stg_alumni.conference360__attendee__c.conference360__event_end_date__c%type
,registration_status      stg_alumni.conference360__attendee__c.conference360__registration_status__c%type
,attendance_status        stg_alumni.conference360__attendee__c.conference360__attendance_status__c%type 
,create_date              stg_alumni.conference360__attendee__c.etl_create_date%type
,etl_update_date           stg_alumni.conference360__attendee__c.etl_update_date%type
);


/*************************************************************************
Public table declarations
*************************************************************************/

Type nu_events Is Table Of rec_nu_events;
Type nu_participants Is Table Of rec_nu_participants;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

-- Return pipelined events
Function tbl_nu_events
    Return nu_events Pipelined;

Function tbl_nu_participants
Return nu_participants Pipelined;

/*********************** About pipelined functions ***********************
Q: What is a pipelined function?

A: Pipelined functions are used to return the results of a cursor row by row.
This is an efficient way to re-use a cursor between multiple programs. Pipelined
tables can be queried in SQL exactly like a table when embedded in the table()
function. My experience has been that thanks to the magic of the Oracle compiler,
joining on a table() function scales hugely better than running a function once
on each element of a returned column. Note that the exact columns returned need
to be specified as a public type, which I did in the type and table declarations
above, or the pipelined function can't be run in pure SQL. Alternately, the
pipelined function could return a generic table, but the columns would still need
to be individually named.
*************************************************************************/

End ksm_pkg_nu_events;
/
Create Or Replace Package Body ksm_pkg_nu_events Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

Cursor c_nu_events Is

with v as (select 
event.id,
event.name,
event.conference360__organizer_account__c,
--- Kellogg Organizer Name
e.sort_name, 
--- Kellogg Event Flag 
case when event.name like '%KSM%'
or event.name like '%Kellogg%' 
or e.sort_name like '%Kellogg%'
or e.sort_name like '%KSM%'
then 'Y' end as KSM_Event,
--- Status, Category, Start/End Dates, SF URL
event.conference360__status__c,
event.conference360__category__c,
event.conference360__event_end_date__c,
event.conference360__event_start_date__c,
event.conference360__event_url__c,
event.etl_create_date, 
event.etl_update_date,
--- Venue Details 
event.conference360__venue_city__c,
event.conference360__venue_country__c,
event.conference360__venue_name__c,
event.conference360__venue_postal_code__c,
event.conference360__venue_state_province__c,
event.conference360__venue_status__c,
event.conference360__venue_street__c,
event.conference360__venue__c
from stg_alumni.conference360__event__c event
left join mv_entity e on e.salesforce_id = event.conference360__organizer_account__c 
)

select 
v.id as salesforce_event_id
,v.name as event_name,
v.conference360__status__c as status,
v.conference360__event_start_date__c as event_start_date,
v.conference360__event_end_date__c as event_end_date,
v.conference360__category__c as event_category,
v.conference360__organizer_account__c as organizer_account,
v.sort_name as organizer_name
,v.KSM_Event,
v.conference360__event_url__c as url_link,
v.conference360__venue_name__c as venue_name,
v.conference360__venue_city__c as venue_city,
v.conference360__venue_state_province__c as venue_state,
v.conference360__venue_country__c as venue_country,
v.etl_create_date as create_date, 
v.etl_update_date as update_date
from v 

;

Cursor c_nu_participants Is

--- Create a subquery to pull event participant data from STG tables 

with event as (select  
a.NU_DONOR_ID__C  as donor_id,
a.CONFERENCE360__ATTENDEE_FULL_NAME__C as full_name ,
a.CONFERENCE360__EVENT_NAME__C  as event_name,
a.CONFERENCE360__EVENT_START_DATE__C as start_date,
a.conference360__event_end_date__c as end_date,
--- Organizer Name - Clubs, Boards/Councils or Kellogg (Kellogg Event Admin)
a.conference360__event_organizer_name__c as organizer_name,
--- Registration and Attendee Status
--- We usually don't collect real attendee status, so adding in both. 
a.conference360__registration_status__c as registration_status,
a.conference360__attendance_status__c as attendance_status,
a.conference360__event_id__c as event_id,
--- A Flag for Kellogg Events: Contains KSM, Kellogg OR Organizer Code is KSM or Kellogg
case when a.CONFERENCE360__EVENT_NAME__C like '%KSM%'
or a.CONFERENCE360__EVENT_NAME__C like '%Kellogg%' 
or a.conference360__event_organizer_name__c like '%Kellogg%'
or a.conference360__event_organizer_name__c like '%KSM%'
then 'Y' end as KSM_Event,
a.etl_create_date, 
a.etl_update_date
from stg_alumni.conference360__attendee__c a 
where a.NU_DONOR_ID__C  is not null
and a.CONFERENCE360__EVENT_NAME__C is not null),

--- Entity 

e as (select *
from mv_entity e)

--- Final Query - ID, Name, Event ID, Organizer, Time, Registration and Kellogg Flag 

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
event.attendance_status,
event.etl_create_date, 
event.etl_update_date
from event
inner join e on event.donor_id = e.donor_id
order by event.start_date asc 
;

/*************************************************************************
Pipelined functions
*************************************************************************/

-- Concatenated Nu Events
Function tbl_nu_events
Return nu_events Pipelined As
-- Declarations
nev nu_events;
Begin
Open c_nu_events;
Fetch c_nu_events Bulk Collect Into nev;
Close c_nu_events;
For i in 1..(nev.count) Loop
Pipe row(nev(i));
End Loop;
Return;
End;

-- Concatenated nu participants
Function tbl_nu_participants
Return nu_participants Pipelined As
-- Declarations
nup nu_participants;
Begin
Open c_nu_participants;
Fetch c_nu_participants Bulk Collect Into nup;
Close c_nu_participants;
For i in 1..(nup.count) Loop
Pipe row(nup(i));
End Loop;
Return;
End;

End ksm_pkg_nu_events;
/
