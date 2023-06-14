--- Households
with h as (select  *
from rpt_pbh634.v_entity_ksm_households),

--- entity 

e as (select  *
from entity),

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

REUNION_2023_PARTICIPANTS AS (
Select ep.id_number,
event.event_id
From event
Left Join ep
ON ep.event_id = event.event_id
where ep.event_id = '28145'
),

-- Final Reunion - Avoiding left joins in my base 
R as (select e.id_number,
case when R18.id_number is not null then 'Reunion 2018 Participant' end as Reunion_18_IND,
case when R19.id_number is not null then 'Reunion 2019 Participant' end as Reunion_19_IND,
case when R21.id_number is not null then 'Reunion 2021 Participant' end as Reunion_21_IND, 
case when R22W1.id_number is not null then 'Reunion 2022 Weekend 1 Participant' end as Reunion_22W1_IND,
case when R22W2.id_number is not null then 'Reunion 2022 Weekend 2 Participant' end as Reunion_22W2_IND,
case when R23.id_number is not null then 'Reunion 2023 Participant' end as Reunion_23_IND
from e
left join REUNION_2018_PARTICIPANTS R18 ON R18.id_number = e.id_number
left join REUNION_2019_PARTICIPANTS R19 on R19.id_number = e.id_number
left join REUNION_2021_PARTICIPANTS R21 on R21.id_number = e.id_number
left join REUNION_2022_PARTICIPANTS R22W1 on R22W1.id_number = e.id_number
left join REUNION_2022_PARTICIPANTS R22W2 on R22W2.id_number = e.id_number
left join REUNION_2023_PARTICIPANTS R23 on R23.id_number = e.id_number
where (R18.id_number is not null
or R19.id_number is not null
or R21.id_number is not null
or R22W1.id_number is not null
or R22W2.id_number is not null)),

--- Faculty or Dean Event Past 5 Years 

F as (select distinct ep.id_number
-- dupes caused by above
from event
cross join rpt_pbh634.v_current_calendar cal
inner join v_ksm_faculty_events v ON v.event_id = event.event_id
Inner Join ep
ON ep.event_id = event.event_id
--- Past 5 Years
where
-- event.start_fy_calc Between cal.curr_fy - 5 And cal.curr_fy
(cal.curr_fy = event.start_fy_calc + 5
or cal.curr_fy = event.start_fy_calc + 4
or cal.curr_fy = event.start_fy_calc + 3
or cal.curr_fy = event.start_fy_calc + 2
or cal.curr_fy = event.start_fy_calc + 1
or cal.curr_fy = event.start_fy_calc + 0)),


a as (select distinct assign.prospect_id,
                assign.id_number,
                assign.prospect_manager,
                assign.lgos,
                assign.managers,
                assign.curr_ksm_manager
from rpt_pbh634.v_assignment_summary assign
---Central - All managers !!! Changes this 
),

--- Lifetime Giving, NU Lifetime, CRU CFY, 
g as (select s.ID_NUMBER,
s.NGC_LIFETIME,
s.NU_MAX_HH_LIFETIME_GIVING,
s.CRU_CFY,
s.CRU_PFY1,
s.CRU_PFY2,
s.CRU_PFY3,
s.CRU_PFY4,
s.CRU_PFY5,
--- Last gifts - Reccomendation from Melanie
s.LAST_GIFT_TX_NUMBER,
s.LAST_GIFT_DATE,
s.LAST_GIFT_TYPE,
s.LAST_GIFT_ALLOC_CODE,
s.LAST_GIFT_ALLOC,
s.LAST_GIFT_RECOGNITION_CREDIT,
s.MAX_GIFT_DATE_OF_RECORD,
s.MAX_GIFT_CREDIT
from rpt_pbh634.v_ksm_giving_summary s),

---- Eval and Officer Ratings - Reccomendation from Melanie 

P as (Select distinct TP.ID_NUMBER,
TP.EVALUATION_DATE,
TP.EVALUATION_RATING,
TP.OFFICER_RATING
From nu_prs_trp_prospect TP),

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

--- Current Donors (Use Amy's View) 

amyklc as (select k.ID_NUMBER
from RPT_ABM1914.V_KLC_MEMBERS k),


KLC_Final As (Select distinct KLC.GIFT_CLUB_ID_NUMBER,
--- Entity's in Amy's KLC report
case when aklc.id_number is not null then 'Current KLC Member' end as KLC_Current_IND, 
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
left join amyklc aklc on aklc.id_number = KLC.GIFT_CLUB_ID_NUMBER
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
From rpt_pbh634.v_entity_special_handling),

--- Employers and Industry - Primary Employer/Fld of Work

employ As (
  Select id_number
  , job_title
  , employment.fld_of_work_code
  , fow.short_desc As fld_of_work
  , employer_name1,
    -- If there's an employer ID filled in, use the entity name
    Case
      When employer_id_number Is Not Null And employer_id_number != ' ' Then (
        Select pref_mail_name
        From entity
        Where id_number = employer_id_number)
      -- Otherwise use the write-in field
      Else trim(employer_name1 || ' ' || employer_name2)
    End As employer_name
  From employment
  Left Join tms_fld_of_work fow
       On fow.fld_of_work_code = employment.fld_of_work_code
  Where employment.primary_emp_ind = 'Y'
),

--- speaker - flag for speaker and most recent speaking event

speak as (select Activity.Id_Number,
max (Activity.Start_Dt) keep (dense_rank First Order By Activity.Start_Dt DESC) as last_speak_date,
max (Activity.Xcomment) keep (dense_rank First Order By Activity.Start_Dt DESC) as last_speak_detail
from Activity
--- KSP = Kellogg Speakers
where Activity.Activity_Code = 'KSP'
group by Activity.Id_Number),


--- Kellogg Alumni Admission Callers
kaac as(select distinct committee.id_number
from committee
where committee.committee_code = 'KAAC'
and committee.committee_status_code = 'C'),

--- Kellogg Alumni Admissions Organization
kacao as(select distinct committee.id_number
from committee
where committee.committee_code = 'KACAO'
and committee.committee_status_code = 'C'),

--- Adding Kellogg interviewers, student activities, event hosts from Liam's engagement model 

--- K Interviewers
K_Interviewers as (
SELECT distinct comm.id_number
From committee comm
Inner Join tms_committee_table tmscomm
      On comm.committee_code = tmscomm.committee_code
Inner Join tms_committee_status tmscommstat
      On comm.committee_status_code = tmscommstat.committee_status_code
Where comm.committee_code = 'KOCCI'
Group By comm.id_number
),

--- Student Activities

KStuAct as (
SELECT distinct sa.id_number
From student_activity sa
Inner Join tms_student_act tmssp
      On tmssp.student_activity_code = sa.student_activity_code
Where sa.student_activity_code In ('DAK', 'IKC', 'KSMT', 'KDKJS', 'KTC', 'KR', 'FFKDC', 'KSA36', 'KSB3', 'KSB33', 'KSA44', 'KSA51', 'KSA18', 'KSA93', 'KSB49', 'KSA98', 'KSB12', 'KSA54', 'KSB52', 'KSB25', 'KSB6', 'KSB51', 'KSA52', 'KSB56', 'KSA73', 'KSA74', 'KSB57', 'KSB40', 'KMSSA', 'KSA58', 'KSB41', 'KSB61', 'KSA86', 'KSA45', 'KSC', 'KSA84', 'KSB30', 'KVA', 'KSB81', 'KSA23', 'KSB14')
),

--- event hosts
Event_Host as (
SELECT distinct act.id_number
From activity act
Inner join tms_activity_table tmsat
      On tmsat.activity_code = act.activity_code
Where act.activity_code = 'KEH'
And act.activity_participation_code = 'P'
),

--- Kellogg Alumni Club Leader  
leader as(select distinct v_ksm_club_leaders.id_number
from v_ksm_club_leaders)

select d.id_number,
d.RECORD_STATUS_CODE,
e.gender_code,
d.REPORT_NAME,
d.FIRST_KSM_YEAR,
d.PROGRAM,
d.PROGRAM_GROUP,
employ.job_title,
employ.employer_name,
employ.fld_of_work,
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
R.Reunion_23_IND,
P.EVALUATION_DATE,
P.EVALUATION_RATING,
P.OFFICER_RATING,
a.prospect_manager,
a.lgos,
a.managers,
a.curr_ksm_manager,
c.credited,
c.credited_name,
c.contact_type,
c.Max_Date,
c.description_,
c.summary_,
speak.last_speak_date,
speak.last_speak_detail,
case when f.id_number is not null then 'Faculty_event_last_5' end as KSM_faculty_event_last5,
case when kaac.id_number is not null then 'Kellogg Alumni Admission Caller' end as KSM_AL_Admission_Caller, 
case when kacao.id_number is not null then 'Kellogg Alumni Admissions Organization ' end as KSM_AL_Admission_Org,
case when leader.id_number is not null then 'Kellogg club Leader' end as KSM_Club_Leader,
case when k.id_number is not null then 'Kellogg On Campus Career Interviewers' End as KSM_Career_Interviewers, 
case when KStuAct.id_number is not null then 'Kellogg Student Activity' End as KSM_Student_Activities, 
case when e.id_number is not null then 'Event Host' End as Event_Host, 
g.NGC_LIFETIME,
case when g.NGC_LIFETIME > 0 then 'KSM Donor' end as Donor_NGC_Lifetime_IND, 
g.MAX_GIFT_DATE_OF_RECORD,
g.MAX_GIFT_CREDIT,
g.CRU_CFY,
g.CRU_PFY1,
g.CRU_PFY2,
g.CRU_PFY3,
g.CRU_PFY4,
g.CRU_PFY5,
g.LAST_GIFT_DATE,
g.LAST_GIFT_TYPE,
g.LAST_GIFT_ALLOC,
g.LAST_GIFT_RECOGNITION_CREDIT,
--max_gift.DATE_OF_RECORD as date_of_record_max_gift,
--max_gift.max_credit as max_gift_credit,
g.max_gift_date_of_record,
g.max_gift_credit,
KLC.KLC_Current_IND, 
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
inner join e on e.id_number = d.id_number
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
--- Max Gift
--left join max_gift on max_gift.id_number = d.id_number 
--- Prospect Ratings
left join p on p.id_number = d.id_number 
--- employment
left join employ on employ.id_number = d.id_number
--- Speakers and last speaking engagement 
left join speak on speak.id_number = d.id_number
--- Kellogg Alumni Admission Callers
left join kaac on kaac.id_number = d.id_number
--- Kellogg Alumni Admission Organization
left join kacao on kacao.id_number = d.id_number
--- Club Leader
left join leader on leader.id_number = d.id_number
--- K Interviewers
left join K_Interviewers k on k.id_number = d.id_number
--- Student Activities 
left join KStuAct on KStuAct.id_number = d.id_number
--- Event Host
left Join Event_Host e on e.id_number = d.id_number
