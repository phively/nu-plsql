create or replace view vt_alumni_market_sheet as

With
-- Employment table subquery
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

--- Use BG - Business Geo Code

BG as (Select
gc.*
From table(rpt_pbh634.ksm_pkg_tmp.tbl_geo_code_primary) gc
Inner Join address
On address.id_number = gc.id_number
And address.xsequence = gc.xsequence
Where address.addr_type_code = 'B'),

BusinessAddress AS( 
      Select
         a.Id_number
      ,  tms_addr_status.short_desc AS Address_Status
      ,  tms_address_type.short_desc AS Address_Type
      ,  a.addr_pref_ind
      ,  a.street1
      ,  a.street2
      ,  a.street3
      ,  a.foreign_cityzip
      ,  a.city
      ,  a.state_code
      ,  a.zipcode
      ,  tms_country.short_desc AS Country
      ,  BG.GEO_CODE_PRIMARY_DESC AS BUSINESS_GEO_CODE
      FROM address a
      INNER JOIN tms_addr_status ON tms_addr_status.addr_status_code = a.addr_status_code
      LEFT JOIN tms_address_type ON tms_address_type.addr_type_code = a.addr_type_code
      LEFT JOIN tms_country ON tms_country.country_code = a.country_code
      INNER JOIN BG 
      ON BG.ID_NUMBER = A.ID_NUMBER
      AND BG.xsequence = a.xsequence
      WHERE a.addr_type_code = 'B'
      AND a.addr_status_code IN('A','K')
),

p as (select  TP.ID_NUMBER,
       TP.EVALUATION_RATING,
       TP.OFFICER_RATING
From nu_prs_trp_prospect TP),

--- Prospect 1Mil + - Used for Ben's New Map (4/7/2021)

Prospect_1M_Plus AS (
Select distinct P.ID_NUMBER,
       P.EVALUATION_RATING,
       P.OFFICER_RATING

From P

Where P.EVALUATION_RATING IN ('A7 $1M - $1.9M','A6 $2M - $4.9M','A5 $5M - $9.9M',

'A4 $10M - $24.9M','A3 $25M - $49.9M')

Or

P.OFFICER_RATING IN ('A7 $1M - $1.9M',

'A6 $2M - $4.9M', 'A5 $5M - $9.9M', 'A4 $10M - $24.9M', 'A3 $25M - $49.9M')),

--- KSM Assignments: LGO, PM, Manager

ksm_assignment as (select distinct assign.id_number,
assign.prospect_manager,
assign.lgos,
assign.managers
from rpt_pbh634.v_assignment_summary assign),

--- KSM Emails (To build email flag in marketsheet) 

KSM_Email AS (select email.id_number,
       email.email_address
From email
Inner Join rpt_pbh634.v_entity_ksm_degrees deg on deg.ID_NUMBER = email.id_number
Where email.preferred_ind = 'Y'),

--- KSM Spec (To indicate Special Handling)

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


APR AS (

--- This will pull all events type coded Reunion, but takes away the Reunion Events that are a sub event of
--- the actual Reunion, so we will have only the Reunion Event Pulled by Year
Select distinct 
EP_Participant.Id_Number,
rpt_pbh634.v_nu_events.event_name,
rpt_pbh634.v_nu_events.event_id,
rpt_pbh634.v_nu_events.start_dt,
rpt_pbh634.v_nu_events.start_dt_calc,
rpt_pbh634.v_nu_events.start_fy_calc
From ep_event
Left Join EP_Participant
ON ep_participant.event_id = ep_event.event_id
Inner Join rpt_pbh634.v_nu_events on rpt_pbh634.v_nu_events.event_id = ep_event.event_id
Where ep_event.event_type = '02'
and rpt_pbh634.v_nu_events.kellogg_organizers = 'Y'
and ep_event.event_id not IN ('21637','21121','22657','18819','20926','25896','17739','18982','21264',
'6897','8358')
Order by rpt_pbh634.v_nu_events.event_name DESC
),

recent_reunion AS (--- Subquery to add into the 2021 Reunion Report. This will help user identify an alum's most recent attendance. 

Select DISTINCT apr.id_number,
       max (apr.start_dt_calc) keep (dense_rank First Order By apr.start_dt_calc DESC) As Date_Recent_Event,
       max (apr.event_id) keep (dense_rank First Order By apr.start_dt_calc DESC) As Recent_Event_ID,
       max (apr.event_name) keep(dense_rank First Order By apr.start_dt_calc DESC) As Recent_Event_Name
from apr
Group BY apr.id_number
Order By Date_Recent_Event ASC),

birth as (select  entity.id_number,
(substr (birth_dt, 1, 4)) as birth_year,
entity.birth_dt
from entity),

--- Committee Membership: Concats membership in a KSM Committee - Marketsheets can extend to affinty/groups

club as (select  c.id_number,
Listagg (c.committee_desc, ';  ') Within Group (Order By c.committee_desc) As committee_desc
        from ADVANCE_NU_RPT.v_nu_committees c
where c.ksm_committee = 'Y'
and c.committee_status_code = 'C'
Group By c.id_number),
-- Annual Fund wants last gift date information 

give as (
select 
s.ID_NUMBER,
s.NU_MAX_HH_LIFETIME_GIVING,
s.CRU_CFY,
s.CRU_PFY1,
s.CRU_PFY2,
s.CRU_PFY3,
s.CRU_PFY4,
s.CRU_PFY5,
s.LAST_GIFT_DATE,
s.LAST_GIFT_ALLOC,
s.LAST_GIFT_RECOGNITION_CREDIT
from rpt_pbh634.v_ksm_giving_summary s),

AF_SCORES AS (
SELECT
 AF.ID_NUMBER
 ,max(AF.DESCRIPTION) as AF_10K_MODEL_TIER
 ,max(AF.SCORE) as AF_10K_MODEL_SCORE
FROM RPT_PBH634.V_KSM_MODEL_AF_10K AF
GROUP BY AF.ID_NUMBER
),

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
)

--- Degree Fields

Select Distinct
rpt_pbh634.v_entity_ksm_degrees.ID_NUMBER,

rpt_pbh634.v_entity_ksm_degrees.REPORT_NAME,

rpt_pbh634.v_entity_ksm_degrees.RECORD_STATUS_CODE,

rpt_pbh634.v_entity_ksm_degrees.FIRST_KSM_YEAR,

rpt_pbh634.v_entity_ksm_degrees.PROGRAM,

rpt_pbh634.v_entity_ksm_degrees.PROGRAM_GROUP,

rpt_pbh634.v_entity_ksm_degrees.CLASS_SECTION,

birth.birth_year,

--- Gender Code

Entity.Gender_Code,

--- Employment

Employ.fld_of_work_code,

Employ.fld_of_work,

Employ.employer_name,

Employ.job_title,

--- City, State, Zip, Geo Codes By Household

rpt_pbh634.v_entity_ksm_households.HOUSEHOLD_CITY,

rpt_pbh634.v_entity_ksm_households.HOUSEHOLD_STATE,

rpt_pbh634.v_entity_ksm_households.HOUSEHOLD_ZIP,

rpt_pbh634.v_entity_ksm_households.HOUSEHOLD_GEO_CODES,

rpt_pbh634.v_entity_ksm_households.HOUSEHOLD_COUNTRY,

rpt_pbh634.v_entity_ksm_households.HOUSEHOLD_CONTINENT,

BusinessAddress.city as business_city,

BusinessAddress.state_code as business_state_code ,

BusinessAddress.zipcode as business_zipcode,

BusinessAddress.Country as business_country,

BusinessAddress.BUSINESS_GEO_CODE,

ksm_assignment.prospect_manager,

ksm_assignment.lgos,

ksm_assignment.managers,

P.EVALUATION_RATING,

P.OFFICER_RATING,

Prospect_1M_Plus.EVALUATION_RATING,

Prospect_1M_Plus.OFFICER_RATING,

case when KSM_Email.email_address is not null then 'Y' Else 'N' END As pref_email_ind, 

spec.GAB,

spec.TRUSTEE,

spec.EBFA, 

spec.NO_CONTACT,

spec.NO_SOLICIT,

spec.NO_PHONE_IND,

spec.NO_EMAIL_IND,

spec.NO_MAIL_IND,

spec.SPECIAL_HANDLING_CONCAT,

give.NU_MAX_HH_LIFETIME_GIVING,

give.CRU_CFY,

give.CRU_PFY1,

give.CRU_PFY2,

give.CRU_PFY3,

give.CRU_PFY4,

give.CRU_PFY5,

give.LAST_GIFT_DATE,

give.LAST_GIFT_ALLOC,

give.LAST_GIFT_RECOGNITION_CREDIT,

AF_SCORES.AF_10K_MODEL_TIER,

AF_SCORES.AF_10K_MODEL_SCORE,

c.credited,

c.credited_name,

c.contact_type,

c.Max_Date,

c.description_,

c.summary_,

case when APR.id_number is not null then 'Attended Previous Reunion' Else '' END As Attended_Previous_Reunion,
  
recent_reunion.Date_Recent_Event,

recent_reunion.Recent_Event_ID,

recent_reunion.Recent_Event_Name,

club.committee_desc as ksm_committee_concat


From rpt_pbh634.v_entity_ksm_degrees

---- Join Entity --- For Gender Code

Inner Join Entity on rpt_pbh634.v_entity_ksm_degrees.ID_NUMBER = Entity.Id_Number

---- Join Households --- For Address

Left Join rpt_pbh634.v_entity_ksm_households On rpt_pbh634.v_entity_ksm_degrees.ID_NUMBER = rpt_pbh634.v_entity_ksm_households.ID_NUMBER

---- Join Employment

Left Join Employ On rpt_pbh634.v_entity_ksm_degrees.ID_NUMBER = Employ.Id_Number

---- Join Assignment

Left Join ksm_assignment on ksm_assignment.id_number = rpt_pbh634.v_entity_ksm_degrees.ID_NUMBER

--- AF Model

Left Join AF_SCORES on AF_SCORES.id_number = rpt_pbh634.v_entity_ksm_degrees.ID_NUMBER

--- Contact report

Left Join C on C.id_number = rpt_pbh634.v_entity_ksm_degrees.ID_NUMBER

--- Just prospect 

Left Join P on P.id_number = rpt_pbh634.v_entity_ksm_degrees.ID_NUMBER

--- Join 1 Mil Prospect Plus 

Left Join Prospect_1M_Plus on Prospect_1M_Plus.id_number = rpt_pbh634.v_entity_ksm_degrees.ID_NUMBER

--- Email Flags

Left Join KSM_Email on KSM_Email.id_number = rpt_pbh634.v_entity_ksm_degrees.id_number

--- Include Business Address 

Left Join BusinessAddress on BusinessAddress.id_number = rpt_pbh634.v_entity_ksm_degrees.id_number

--- Special Handling Code

Left Join SPEC ON Spec.id_number = rpt_pbh634.v_entity_ksm_degrees.ID_NUMBER

---- Active Alumni
--- *** Revised 10/5/2021 *** We will now include lost records and create a filter for them on Tableau 

--- Join Attended Past Reunion As

Left Join apr on apr.id_number = rpt_pbh634.v_entity_ksm_degrees.ID_NUMBER

--- Join Last Reunion Attended As

Left Join recent_reunion on recent_reunion.id_number = rpt_pbh634.v_entity_ksm_degrees.ID_NUMBER

Left Join birth on birth.id_number = rpt_pbh634.v_entity_ksm_degrees.id_number

Left Join club on club.id_number = rpt_pbh634.v_entity_ksm_degrees.id_number

Left Join give on give.id_number = rpt_pbh634.v_entity_ksm_degrees.id_number

Where rpt_pbh634.v_entity_ksm_degrees.Record_Status_Code IN ('A','L')
;
