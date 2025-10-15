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
and c.ap_degree_type_from_degreecode__c Not In ('Certificate', 'Doctorate Degree')
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
 'FT-MS', 'FT-MBAi', 'FT-MIM', 
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

--- Spouse Reunion Year  - KELLOGG ONLY!
--- Salutation for folks that have a spouse, who is NOT a primary member of the household, AND has a Reunion 2026 year


spr as (select en.spouse_donor_id,
en.spouse_name,
en.spouse_institutional_suffix,
--- This should be Reunion for Spouses
FR.reunion_year_concat
from mv_entity en
inner join FR on FR.ucinn_ascendv2__donor_id__c = en.spouse_donor_id
inner join KSM_Degrees on KSM_Degrees.donor_id = en.spouse_donor_id),


--- Current Linkedin Addresses
a as (select
stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__contact__c,
max (stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__url__c) keep (dense_rank first order by stg_alumni.ucinn_ascendv2__social_media__c.lastmodifieddate) as Linkedin_address
from stg_alumni.ucinn_ascendv2__social_media__c
where stg_alumni.ucinn_ascendv2__social_media__c.ap_status__c like '%Current%'
and stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__platform__c = 'LinkedIn'
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
       mv_entity.household_primary,
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
 --- Edit: We will include deceased records (9/11/2025) 
--- where mv_entity.is_deceased_indicator = 'N'
 --- household primary
 --- Edit: 9/9/25 - Team wants the report not filter to primary household 
 ---and mv_entity.household_primary = 'Y'
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
       s.never_engaged_reunion,
       s.no_solicit,
       s.service_indicators_concat
from mv_special_handling s),

--- email

email as (select  c.ucinn_ascendv2__donor_id__c,
c.email
from stg_alumni.contact c),

--- Phone

phone as (select c.ucinn_ascendv2__donor_id__c,
c.ucinn_ascendv2__preferred_phone_type__c,
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
FROM ksm_2022_weekend1_reunion r22),

--- Preferred Mail Name - From Amy
MN as (SELECT ME.DONOR_ID,
INDNAMESAL.UCINN_ASCENDV2__CONSTRUCTED_NAME_FORMULA__C as preferred_mail_name
FROM stg_alumni.ucinn_ascendv2__contact_name__c  INDNAMESAL
Inner Join mv_entity ME
ON ME.SALESFORCE_ID = INDNAMESAL.UCINN_ASCENDV2__CONTACT__C
AND INDNAMESAL.ucinn_ascendv2__type__c = 'Full Name'),

--- Join Salutation for folks that have a spouse, who is NOT a primary member of the household, AND has a Reunion 2026 year

Salutation as (Select
        mv_entity.donor_id
      , stgc.UCINN_ASCENDV2__SALUTATION_TYPE__c As Salutation_Type
      , stgc.ucinn_ascendv2__salutation_record_type_formula__c As Ind_or_Joint
      , stgc.ucinn_ascendv2__inside_salutation__c As Salutation
      , stgc.lastmodifieddate
      , stgc.ucinn_ascendv2__author_title__c As Sal_Author
      , stgc.isdeleted
From stg_alumni.ucinn_ascendv2__salutation__c stgc
Left Join mv_entity
     On mv_entity.salesforce_id = stgc.ucinn_ascendv2__contact__c
Where  stgc.isdeleted = 'false'
And stgc.ucinn_ascendv2__salutation_record_type_formula__c = 'Joint'
--- formal
and stgc.UCINN_ASCENDV2__SALUTATION_TYPE__c = 'Formal'
),

--- Pulling Involvement, which will pull club leaders

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

--- Club Leaders of KSM

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

--- 2016 Reunion committee 

rc16 as (select i.constituent_donor_id,
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
from i 
where i.involvement_name like '%KSM Reunion Committee%' 
and i.involvement_start_date BETWEEN TO_DATE('09/01/2015', 'MM/DD/YYYY')
AND TO_DATE('08/31/2016', 'MM/DD/YYYY')),

--- assignment

assign as (Select a.household_id,
       a.donor_id,
       a.sort_name,
       a.prospect_manager_name,
       a.lagm_user_id,
       a.lagm_name,
       a.ksm_manager_flag
From mv_assignments a),

--- Dean Salutation 

Dean as (Select e.donor_id,
       e.P_Dean_Salut,
       e.P_Dean_Source
From v_entity_salutations e),

--- Pull KLC

klc as (Select k.DONOR_ID,
k.segment
from tableau_klc_members k),

--- Last 4 Gifts

MYDATA AS (
SELECT
    KT.CREDITED_DONOR_ID
   ,CASE WHEN A.AP_DONOR_ADVISED_FUND__C = 'true' THEN KT.OPPORTUNITY_DONOR_NAME ELSE ' ' END AS OPPORTUNITY_DONOR_NAME
   ,KT.FISCAL_YEAR
   ,KT.CREDIT_DATE
   ,KT.CREDIT_AMOUNT
   ,KT.DESIGNATION_NAME
   ,KT.OPPORTUNITY_TYPE
   ,KT.CAMPAIGN_CODE
  FROM MV_KSM_TRANSACTIONS KT
  LEFT JOIN dm_alumni.DIM_OPPORTUNITY DOP
  ON KT.OPPORTUNITY_RECORD_ID = DOP.OPPORTUNITY_RECORD_ID
  LEFT JOIN stg_alumni.account A
  ON KT.OPPORTUNITY_DONOR_ID = A.UCINN_ASCENDV2__DONOR_ID__C
  WHERE KT.GYPM_IND NOT IN ('P', 'M')
)
 
,ROWDATA AS (
  SELECT
    CREDITED_DONOR_ID
    ,ROW_NUMBER() OVER(PARTITION BY CREDITED_DONOR_ID ORDER BY CREDIT_DATE DESC) RW
    ,OPPORTUNITY_DONOR_NAME
    ,CREDIT_AMOUNT
    ,CREDIT_DATE
    ,DESIGNATION_NAME
    ,FISCAL_YEAR
    ,OPPORTUNITY_TYPE
    ,CAMPAIGN_CODE
  FROM MYDATA
),
 
GIFTINFO AS (
  SELECT
    CREDITED_DONOR_ID
    ,MAX(DECODE(RW,1,FISCAL_YEAR)) YR1
    ,max(decode(RW,1,CREDIT_DATE)) CREDIT_DATE1
    ,MAX(DECODE(RW,1,CREDIT_AMOUNT)) CREDIT_AMT1
    ,MAX(DECODE(RW,1,OPPORTUNITY_DONOR_NAME)) DAF_1
    ,MAX(DECODE(RW,1,DESIGNATION_NAME)) DESIGNATION1
    ,MAX(DECODE(RW,1,OPPORTUNITY_TYPE)) OPPORTUNITY_TYPE1
    ,MAX(DECODE(RW,1,CAMPAIGN_CODE)) CAMPAIGN_MOTIVATION_CODE_1
    ,MAX(DECODE(RW,2,FISCAL_YEAR)) YR2
    ,max(decode(RW,2,CREDIT_DATE)) CREDIT_DATE2
    ,MAX(DECODE(RW,2,CREDIT_AMOUNT)) CREDIT_AMT2
    ,MAX(DECODE(RW,2,OPPORTUNITY_DONOR_NAME)) DAF_2
    ,MAX(DECODE(RW,2,DESIGNATION_NAME)) DESIGNATION2
    ,MAX(DECODE(RW,2,OPPORTUNITY_TYPE)) OPPORTUNITY_TYPE2
    ,MAX(DECODE(RW,2,CAMPAIGN_CODE)) CAMPAIGN_MOTIVATION_CODE_2    
    ,MAX(DECODE(RW,3,FISCAL_YEAR)) YR3
    ,max(decode(RW,3,CREDIT_DATE)) CREDIT_DATE3
    ,MAX(DECODE(RW,3,CREDIT_AMOUNT)) CREDIT_AMT3
    ,MAX(DECODE(RW,3,OPPORTUNITY_DONOR_NAME)) DAF_3
    ,MAX(DECODE(RW,3,DESIGNATION_NAME)) DESIGNATION3
    ,MAX(DECODE(RW,3,OPPORTUNITY_TYPE)) OPPORTUNITY_TYPE3
    ,MAX(DECODE(RW,3,CAMPAIGN_CODE)) CAMPAIGN_MOTIVATION_CODE_3
    ,MAX(DECODE(RW,4,FISCAL_YEAR)) YR4
    ,max(decode(RW,4,CREDIT_DATE)) CREDIT_DATE4
    ,MAX(DECODE(RW,4,CREDIT_AMOUNT)) CREDIT_AMT4
    ,MAX(DECODE(RW,4,OPPORTUNITY_DONOR_NAME)) DAF_4
    ,MAX(DECODE(RW,4,DESIGNATION_NAME)) DESIGNATION4
    ,MAX(DECODE(RW,4,OPPORTUNITY_TYPE)) OPPORTUNITY_TYPE4
    ,MAX(DECODE(RW,4,CAMPAIGN_CODE)) CAMPAIGN_MOTIVATION_CODE_4
FROM ROWDATA
GROUP BY CREDITED_DONOR_ID)

 
select distinct e.household_id,
     e.donor_id,
     e.household_primary,
     g.household_primary_donor_id,
     e.is_deceased_indicator,
     s.gender_identity,
     MN.preferred_mail_name,
     e.full_name,
     e.first_name,
     dean.P_Dean_Salut,
     e.last_name,
     e.institutional_suffix,
     FR.reunion_year_concat,
     FR.first_ksm_year,
     FR.first_masters_year,
     FR.program,
     FR.program_group,
     FR.class_section,
     e.spouse_donor_id,
     e.spouse_name,
     e.spouse_institutional_suffix,
     case when r16.id_number is not null then 'Reunion 2016 Attendee' end as Reunion_16_Attendee,
     case when r22.id_number is not null then 'Reunion 2022 Attendee' end as Reunion_22_Attendee,
     ---- need to create temp table for 2026
     spr.reunion_year_concat as spouse_ksm_reunion_year,
     case when spr.reunion_year_concat is not null then salutation.salutation end as joint_salutation,
     case when spr.reunion_year_concat is not null then salutation.Salutation_Type end as joint_salutation_type,
     case when spr.reunion_year_concat is not null then salutation.Ind_or_Joint end as ind_joint,
     e.preferred_address_type,
     e.preferred_address_line_1,
     e.preferred_address_line_2,
     e.preferred_address_line_3,
     e.preferred_address_line_4,
     e.preferred_address_city,
     e.preferred_address_state,
     e.preferred_address_postal_code,
     e.preferred_address_country,
     klc.segment as KLC,
     case when g.ngc_fy_giving_first_yr is not null then g.ngc_fy_giving_first_yr else 0 end as ngc_fy_giving_first_yr,
     case when g.cash_fy_giving_first_yr is not null then g.cash_fy_giving_first_yr else 0 end as cash_fy_giving_first_yr,
     --- Write down expendable, cash, ngc explanations for team
     --- edit 9/16/25 - add zeros if blanks 
     case when g.ngc_lifetime is not null then g.ngc_lifetime else 0 end as ngc_lifetime,
     case when g.ngc_cfy is not null then g.ngc_cfy else 0 end as ngc_cfy,
     case when g.ngc_pfy1 is not null then g.ngc_pfy1 else 0 end as ngc_pfy1,
     case when g.ngc_pfy2 is not null then g.ngc_pfy2 else 0 end as ngc_pfy2,
     case when g.ngc_pfy3 is not null then g.ngc_pfy3 else 0 end as ngc_pfy3,
     case when g.ngc_pfy4 is not null then g.ngc_pfy4 else 0 end as ngc_pfy4,
     case when g.ngc_pfy5 is not null then g.ngc_pfy5 else 0 end as ngc_pfy5,
     case when g.cash_lifetime is not null then g.cash_lifetime else 0 end as cash_lifetime,
     case when g.expendable_cfy is not null then g.expendable_cfy else 0 end as expendable_cfy,
     case when g.expendable_pfy1 is not null then g.expendable_pfy1 else 0 end as expendable_pfy1,
     case when g.expendable_pfy2 is not null then g.expendable_pfy2 else 0 end as expendable_pfy2,
     case when g.expendable_pfy3 is not null then g.expendable_pfy3 else 0 end as expendable_pfy3,
     case when g.expendable_pfy4 is not null then g.expendable_pfy4 else 0 end as expendable_pfy4,
     case when g.expendable_pfy5 is not null then g.expendable_pfy5 else 0 end as expendable_pfy5,
     ---- Pull last 4 Gifts per Kellogg Fund 
     g.last_cash_tx_id,
     g.last_cash_date,
     g.last_cash_opportunity_type,
     g.last_cash_designation_id,
     g.last_cash_designation,
     case when g.last_cash_recognition_credit is not null then g.last_cash_recognition_credit else 0 end as last_cash_recognition_credit,
     g.last_pledge_tx_id,
     g.last_pledge_date,
     g.last_pledge_opportunity_type,
     g.last_pledge_designation_id,
     g.last_pledge_designation,
     case when  g.last_pledge_recognition_credit is not null then g.last_pledge_recognition_credit end as last_pledge_recognition_credit,
     g.expendable_status,
     g.expendable_status_fy_start,
     g.expendable_status_pfy1_start,
     gi.YR1,
     gi.CREDIT_DATE1,
     gi.CREDIT_AMT1,
     gi.DAF_1,
     gi.DESIGNATION1,
     gi.OPPORTUNITY_TYPE1,
     gi.CAMPAIGN_MOTIVATION_CODE_1,
     gi.YR2,
     gi.CREDIT_DATE2,
     gi.CREDIT_AMT2,
     gi.DAF_2,
     gi.DESIGNATION2,
     gi.OPPORTUNITY_TYPE2,
     gi.CAMPAIGN_MOTIVATION_CODE_2,    
     gi.YR3,
     gi.CREDIT_DATE3,
     gi.CREDIT_AMT3,
     gi.DAF_3,
     gi.DESIGNATION3,
     gi.OPPORTUNITY_TYPE3,
     gi.CAMPAIGN_MOTIVATION_CODE_3,
     gi.YR4,
     gi.CREDIT_DATE4,
     gi.CREDIT_AMT4,
     gi.DAF_4,
     gi.DESIGNATION4,
     gi.OPPORTUNITY_TYPE4,
     gi.CAMPAIGN_MOTIVATION_CODE_4,
     linked.linkedin_address,
     employ.primary_employ_ind,
     employ.primary_job_title,
     employ.primary_employer,
     assign.prospect_manager_name,
     assign.lagm_name,      
     case when sh.no_email_ind is null and sh.no_contact is null then email.email end as email,
     case when sh.no_phone_ind is null and sh.no_contact is null then phone.phone end as phone,
     phone.ucinn_ascendv2__preferred_phone_type__c as phone_type,
     sh.no_contact,
     sh.no_mail_ind,
     sh.no_email_ind,
     sh.never_engaged_forever,
     sh.never_engaged_reunion,
     sh.no_solicit,
     sh.service_indicators_concat,
     rc16.involvement_name as reunion_16_committee,
     rc16.involvement_start_date as reunion_16_start_dt,
     rc16.involvement_end_date as reunion_16_end_st, 
     gab.involvement_name as gab,
     trustee.involvement_name as trustee,
     kac.involvement_name as kac,
     asia.involvement_name as asia_exec_board,
     --- I will probably need to listag club leader - check data first
     club.involvement_name as club_leader,
     --- NU/KSM KSM
     --- Given in Last 5 Years
     --- 0s or Null in the Blanks
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
--- Reunion eligible
inner join FR on FR.ucinn_ascendv2__donor_id__c = e.donor_id 
--- giving info
left join give g on g.household_primary_donor_id = e.donor_id 
--- linkedin
left join linked on linked.ucinn_ascendv2__donor_id__c = e.donor_id 
--- employment
left join employ on employ.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C = e.donor_id
--- special handling
left join SH on SH.donor_id = e.donor_id 
--- email
left join email on email.ucinn_ascendv2__donor_id__c = e.donor_id
--- phone
left join phone on phone.ucinn_ascendv2__donor_id__c = e.donor_id 
--- gab
left join gab on gab.constituent_donor_id = e.donor_id 
--- trustee
left join trustee on trustee.constituent_donor_id = e.donor_id
--- Executive asia
left join asia on asia.constituent_donor_id = e.donor_id
--- KAC
left join kac on kac.constituent_donor_id = e.donor_id
--- Prospect view
left join TP on TP.CONSTITUENT_DONOR_ID = e.donor_id
--- assignment
left join assign on assign.donor_id = e.donor_id
--- contact reports
left join s on s.constituent_donor_id = e.donor_id 
--- Reunion 16 Attendee
left join r16 on r16.id_number = e.donor_id 
--- Reunion 22 Attendee
left join r22 on r22.id_number = e.donor_id
--- preferred mail name
left join MN on MN.DONOR_ID = e.donor_id 
--- Salutation
left join Salutation on Salutation.donor_id = e.spouse_donor_id
--- spouse reunion year
left join spr on spr.spouse_donor_id = e.spouse_donor_id
--- Club Leaders
left join club on club.constituent_donor_id = e.donor_id 
--- Dean Salutation
left join Dean on Dean.donor_id = e.donor_id 
--- KLC 
left join klc on klc.donor_id = e.donor_id 
--- Reunion Committee 16 
left join rc16 on rc16.constituent_donor_id = e.donor_id
--- last 4 gifts
left join GIFTINFO gi on gi.CREDITED_DONOR_ID = e.donor_id
