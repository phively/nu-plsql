--- Households
with h as (select  *
from rpt_pbh634.v_entity_ksm_households),

--- event table
event as (select *
from rpt_pbh634.v_nu_events),

--- participant table
ep as (select *
from EP_Participant),

--- Reunion 2018
REUNION_2018_PARTICIPANTS AS (
Select ep.id_number,
event.event_id
From event
Left Join ep
ON ep.event_id = event.event_id
where ep.event_id = '21792'
)
--- Reunion 2019
,REUNION_2019_PARTICIPANTS AS (
Select ep.id_number,
event.event_id
From event
Left Join ep
ON ep.event_id = event.event_id
where ep.event_id = '21120'
),
--- KSM Road To Reunion 2020 + 2021 #24751 Virtual 
REUNION_2021_PARTICIPANTS AS (
Select ep.id_number,
event.event_id
From event
Left Join ep
ON ep.event_id = event.event_id
where ep.event_id = '24751'
),
--- 2022 - Weekend One
REUNION_2022_PARTICIPANTS AS (
Select ep.id_number,
event.event_id
From event
Left Join ep
ON ep.event_id = event.event_id
where ep.event_id = '26358'
),

--- 2022 Weekend Two 

REUNION_2022_PARTICIPANTS AS (
Select ep.id_number,
event.event_id
From event
Left Join ep
ON ep.event_id = event.event_id
where ep.event_id = '26385'
),

-- Final Reunion - Avoiding left joins in my base 
R as (select entity.id_number,
case when R18.id_number is not null then 'Reunion 2018 Participant' end as Reunion_18_IND,
case when R19.id_number is not null then 'Reunion 2019 Participant' end as Reunion_19_IND,
case when R21.id_number is not null then 'Reunion 2021 Participant' end as Reunion_21_IND, 
case when R22W1.id_number is not null then 'Reunion 2022 Weekend 1 Participant' end as Reunion_22W1_IND,
case when R22W2.id_number is not null then 'Reunion 2022 Weekend 2 Participant' end as Reunion_22W2_IND

from entity
left join REUNION_2018_PARTICIPANTS R18 ON R18.id_number = entity.id_number
left join REUNION_2019_PARTICIPANTS R19 on R19.id_number = entity.id_number
left join REUNION_2021_PARTICIPANTS R21 on R21.id_number = entity.id_number
left join REUNION_2022_PARTICIPANTS R22W1 on R22W1.id_number = entity.id_number
left join REUNION_2022_PARTICIPANTS R22W2 on R22W2.id_number = entity.id_number
where (R18.id_number is not null
or R19.id_number is not null
or R21.id_number is not null
or R22W1.id_number is not null
or R22W2.id_number is not null)),

--- Faculty or Dean Event Past 5 Years 

F as (select ep.id_number,
event.event_id,
event.event_name,
event.start_fy_calc,
v.id_number as kellogg_faculty_staff_id,
v.first_name as kellogg_first_name,
v.last_name as kellogg_last_name
from event
cross join rpt_pbh634.v_current_calendar cal
inner join v_ksm_faculty_events v ON v.event_id = event.event_id
Inner Join ep
ON ep.event_id = event.event_id
--- Past 5 Years
where (cal.curr_fy = event.start_fy_calc + 5
or cal.curr_fy = event.start_fy_calc + 4
or cal.curr_fy = event.start_fy_calc + 3
or cal.curr_fy = event.start_fy_calc + 2
or cal.curr_fy = event.start_fy_calc + 1
or cal.curr_fy = event.start_fy_calc + 0)),

a as (select distinct assign.id_number,
assign.prospect_manager,
assign.lgos,
assign.managers
from rpt_pbh634.v_assignment_summary assign),

--- Lifetime Giving, NU Lifetime, CRU CFY, 
g as (select s.ID_NUMBER,
s.NGC_LIFETIME,
s.NU_MAX_HH_LIFETIME_GIVING,
s.CRU_CFY,
s.CRU_PFY1,
s.CRU_PFY2,
s.CRU_PFY3,
s.CRU_PFY4,
s.CRU_PFY5
from rpt_pbh634.v_ksm_giving_summary s),

--- Most Recent Contact Report

c as (/* Last Contact Report - Date, Author, Type, Subject 
(# Contact Reports - Contacts within FY and 5FYs
*/
select cr.id_number,
max (cr.credited) keep (dense_rank First Order By cr.contact_date DESC) as credited,
max (cr.credited_name) keep (dense_rank First Order By cr.contact_date DESC) as credited_name,
max (cr.contacted_name) keep (dense_rank First Order By cr.contact_date DESC) as contacted_name,
max (cr.contact_type) keep (dense_rank First Order By cr.contact_date DESC) as contact_type,
max (cr.contact_date) keep (dense_rank First Order By cr.contact_date DESC) as Max_Date,
max (cr.description) keep (dense_rank First Order By cr.contact_date DESC) as description_,
max (cr.summary) keep (dense_rank First Order By cr.contact_date DESC) as summary_
from rpt_pbh634.v_contact_reports_fast cr
group by cr.id_number
),

/* KLC Membership Queries
1. Establishing KLC Members
2. Separate Queries to Count Total KLC Years and for the last 5 */

--- Establishing KLC Membership: Date Functions to reflect years in gift club

KLC AS (Select distinct
       GIFT_CLUBS.GIFT_CLUB_ID_NUMBER,
       GIFT_CLUBS.GIFT_CLUB_CODE,
       TMS_GIFT_CLUB_TABLE.club_desc,
       ADVANCE_NU_RPT.ksm_pkg.get_fiscal_year (GIFT_CLUBS.GIFT_CLUB_END_DATE) as Club_END_DATE
FROM GIFT_CLUBS
LEFT JOIN TMS_GIFT_CLUB_TABLE ON TMS_GIFT_CLUB_TABLE.club_code = GIFT_CLUBS.GIFT_CLUB_CODE
Where GIFT_CLUB_CODE = 'LKM'),


KLC_Give_Ind As (select KLC.GIFT_CLUB_ID_NUMBER,
Max(Case When cal.curr_fy = Club_END_DATE Then 'Yes' Else NULL End) as KSM_donor_cfy,
Max(Case When cal.curr_fy = Club_END_DATE + 1 Then 'Yes' Else NULL End) as KSM_donor_pfy1
from KLC
cross join ADVANCE_NU_RPT.v_current_calendar cal
group BY KLC.GIFT_CLUB_ID_NUMBER),

--- Count Total KLC Years 

KLC_Count As (Select distinct KLC.GIFT_CLUB_ID_NUMBER,
Count (distinct Club_END_DATE) as klc_fy_count
from KLC
cross join ADVANCE_NU_RPT.v_current_calendar cal
GROUP BY KLC.GIFT_CLUB_ID_NUMBER),

--- Count of KLC Years, but in last 5

KLC5 AS (Select distinct KLC.GIFT_CLUB_ID_NUMBER,
Count (distinct Club_END_DATE) as klc_fy_count_5
from KLC
cross join ADVANCE_NU_RPT.v_current_calendar cal
Where (KLC.Club_END_DATE = cal.CURR_FY - 1
or KLC.Club_END_DATE = cal.CURR_FY - 2
or KLC.Club_END_DATE = cal.CURR_FY - 3 
or KLC.Club_END_DATE = cal.CURR_FY - 4
or KLC.Club_END_DATE = cal.CURR_FY - 5)
Group By KLC.GIFT_CLUB_ID_NUMBER),


KLC_Final As (Select distinct KLC.GIFT_CLUB_ID_NUMBER,
--- KLC FY Donor This Year
KLC_Give_Ind.KSM_donor_cfy,
--- KLC FY Donor Last Year 
KLC_Give_Ind.KSM_donor_pfy1,
--- KLC Total Years on Record 
KLC_Count.klc_fy_count,
--- KLC Total Years in the Last 5
KLC5.klc_fy_count_5
from KLC
left join KLC_Count on KLC_Count.GIFT_CLUB_ID_NUMBER = KLC.GIFT_CLUB_ID_NUMBER
left join KLC5 ON KLC5.GIFT_CLUB_ID_NUMBER = KLC.GIFT_CLUB_ID_NUMBER 
left join KLC_Give_Ind on KLC_Give_Ind.GIFT_CLUB_ID_NUMBER = KLC.GIFT_CLUB_ID_NUMBER
cross join ADVANCE_NU_RPT.v_current_calendar cal),

Spec AS (Select rpt_pbh634.v_entity_special_handling.ID_NUMBER,
       rpt_pbh634.v_entity_special_handling.GAB,
       rpt_pbh634.v_entity_special_handling.TRUSTEE,
       rpt_pbh634.v_entity_special_handling.NO_CONTACT,
       rpt_pbh634.v_entity_special_handling.NO_SOLICIT,
       rpt_pbh634.v_entity_special_handling.NO_PHONE_IND,
       rpt_pbh634.v_entity_special_handling.NO_EMAIL_IND,
       rpt_pbh634.v_entity_special_handling.NO_MAIL_IND,
       rpt_pbh634.v_entity_special_handling.SPECIAL_HANDLING_CONCAT,
       rpt_pbh634.v_entity_special_handling.EBFA
From rpt_pbh634.v_entity_special_handling)

select d.id_number,
d.RECORD_STATUS_CODE,
entity.gender_code,
d.REPORT_NAME,
d.FIRST_KSM_YEAR,
d.PROGRAM,
d.PROGRAM_GROUP,
h.HOUSEHOLD_CITY,
h.HOUSEHOLD_STATE,
h.HOUSEHOLD_ZIP,
h.HOUSEHOLD_GEO_CODES,
h.HOUSEHOLD_GEO_PRIMARY,
h.HOUSEHOLD_GEO_PRIMARY_DESC,
h.HOUSEHOLD_COUNTRY,
h.HOUSEHOLD_CONTINENT,
R.Reunion_18_IND,
R.Reunion_19_IND,
R.Reunion_21_IND,
R.Reunion_22W1_IND,
R.Reunion_22W2_IND,
a.prospect_manager,
a.lgos,
c.credited,
c.credited_name,
c.contact_type,
c.Max_Date,
c.description_,
c.summary_,
g.NGC_LIFETIME,
case when g.NGC_LIFETIME > 0 then 'KSM Donor' end as Donor_NGC_Lifetime_IND, 
g.NU_MAX_HH_LIFETIME_GIVING,
case when g.NU_MAX_HH_LIFETIME_GIVING > 0 then 'NU Donor' end as NU_HH_LIFETIME_GIVING_IND,
g.CRU_CFY,
g.CRU_PFY1,
g.CRU_PFY2,
g.CRU_PFY3,
g.CRU_PFY4,
g.CRU_PFY5,
KLC.KSM_donor_cfy,
KLC.KSM_donor_pfy1,
KLC.klc_fy_count,
KLC.klc_fy_count_5,
spec.NO_CONTACT,
spec.NO_SOLICIT,
spec.NO_PHONE_IND,
spec.NO_EMAIL_IND,
spec.NO_MAIL_IND,
spec.GAB,
spec.TRUSTEE,
spec.EBFA,
spec.SPECIAL_HANDLING_CONCAT
from rpt_pbh634.v_entity_ksm_degrees d
--- inner join house - to get geocodes/location
inner join h on h.id_number = d.id_number
--- entity
inner join entity on entity.id_number = d.id_number
--- Reunion
left join r on r.id_number = d.id_number
--- Assignments
left join a on a.id_number = d.id_number
--- Contact Reports
left join c on c.id_number = d.id_number
--- faculty or dean event
left join f on f.id_number = d.id_number
--- giving
left join g on g.id_number = d.id_number
--- KLC
left join KLC_FINAL KLC on KLC.GIFT_CLUB_ID_NUMBER = d.id_number
--- Special Handling
left join Spec on Spec.id_number = d.id_number
