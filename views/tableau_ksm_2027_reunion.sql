Create or Replace View tableau_ksm_2027_reunion as 

With manual_dates As (
Select
2027 AS cfy
  From DUAL
),


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


reunion_year as (select a.donor_id,
d.ucinn_ascendv2__reunion_year__c,
KD.program,
KD.program_group,
KD.first_ksm_year,
KD.first_masters_year,
KD.degrees_verbose,
KD.class_section
 from mv_entity a
CROSS JOIN manual_dates MD
inner join d on d.ucinn_ascendv2__contact__c = a.salesforce_id
inner join KSM_Degrees KD on KD.donor_id = a.donor_id 
where ((TO_NUMBER(NVL(TRIM(d.ucinn_ascendv2__reunion_year__c),'1')) 
IN (MD.CFY-1, MD.CFY-5, MD.CFY-10, MD.CFY-15, MD.CFY-20, 
MD.CFY-25, MD.CFY-30, MD.CFY-35, MD.CFY-40,
MD.CFY-45, MD.CFY-50, MD.CFY-51, MD.CFY-52, 
MD.CFY-53, MD.CFY-54, MD.CFY-55, MD.CFY-56, 
MD.CFY-57, MD.CFY-58, MD.CFY-59, MD.CFY-60)))

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

--- Listagg Reunion Years, some have more than 2 preferred KSM Reunions (self reported by alumnus) 

l as (
select reunion_year.donor_id,
Listagg (distinct reunion_year.ucinn_ascendv2__reunion_year__c, ';  ') Within Group (Order By reunion_year.ucinn_ascendv2__reunion_year__c)
As reunion_year_concat
from reunion_year
group by reunion_year.donor_id
),

--- Final Reunion Subquery 

FR as (
select l.donor_id,
l.reunion_year_concat,
reunion_year.first_ksm_year,
reunion_year.program,
reunion_year.program_group,
reunion_year.class_section,
reunion_year.first_masters_year,
reunion_year.degrees_verbose
from l 
inner join KSM_Degrees on KSM_Degrees.donor_id = l.donor_id
inner join reunion_year on reunion_year.donor_id = l.donor_id),

--- Spouse Reunion Year  - KELLOGG ONLY!
--- Salutation for folks that have a spouse, who is NOT a primary member of the household, AND has a Reunion 2027 year


spr as (select en.spouse_donor_id,
en.spouse_name,
en.spouse_institutional_suffix,
--- This should be Reunion for Spouses
FR.reunion_year_concat
from mv_entity en
inner join FR on FR.donor_id = en.spouse_donor_id
inner join KSM_Degrees on KSM_Degrees.donor_id = en.spouse_donor_id),

--- Contact Data
--- Linkedin, Address, Phone, Email, Accounts for Speical Handling 

contact as (select c.donor_id,
       c.sort_name,
       c.service_indicators_concat,
       c.linkedin_url,
       c.primary_geocodes_concat,
       c.address_preferred_type,
       c.preferred_address_line_1,
       c.preferred_address_line_2,
       c.preferred_address_line_3,
       c.preferred_address_line_4,
       c.preferred_address_city,
       c.preferred_address_state,
       c.preferred_address_postal_code,
       c.preferred_address_country,
       c.preferred_geocode_primary,
       c.preferred_geocodes_concat,
       c.preferred_address_latitude,
       c.preferred_address_longitude,
       c.home_address_line_1,
       c.home_address_line_2,
       c.home_address_line_3,
       c.home_address_line_4,
       c.home_address_city,
       c.home_address_state,
       c.home_address_postal_code,
       c.home_address_country,
       c.home_geocode_primary,
       c.home_geocodes_concat,
       c.home_address_latitude,
       c.home_address_longitude,
       c.business_address_line_1,
       c.business_address_line_2,
       c.business_address_line_3,
       c.business_address_line_4,
       c.business_address_city,
       c.business_address_state,
       c.business_address_postal_code,
       c.business_address_country,
       c.business_geocode_primary,
       c.business_geocodes_concat,
       c.business_address_latitude,
       c.business_address_longitude,
       c.email_preferred_type,
       c.email_preferred,
       c.email_personal,
       c.email_business,
       c.emails_concat,
       c.phone_preferred_type,
       c.phone_preferred,
       c.phone_mobile,
       c.phone_home,
       c.phone_business,
       c.max_etl_update_date,
       c.min_etl_update_date,
       c.mv_last_refresh
from mv_entity_contact_info c ),


--- Entity View: Will provide basic data points and also primary HH and Deceased Indicator (we will include deceased in raw data)
e as (select *
From mv_entity),
 
--- Giving Summary

give as (select *
from mv_ksm_giving_summary g),
       
--- Employment: Primary of Job Title, Employer,  
       
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
       s.service_indicators_concat,
       s.gab
from mv_special_handling s),

-- GAB

GAB as (Select *
From v_committee_gab),

--- KAC

kac as (select *
from v_committee_kac),

--- Trustee

trustee as (Select *
From v_committee_trustee),


--- Peac 

peac as (Select *
From v_committee_privateequity),

--- HCAK

hcak as (Select *
From v_committee_healthcare),

--- REAC 

reac as (Select *
From v_committee_realestcouncil),


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
       from DM_ALUMNI.DIM_CONSTITUENT d),

--- Preferred Mail Name - From Amy
MN as (SELECT ME.DONOR_ID,
INDNAMESAL.UCINN_ASCENDV2__CONSTRUCTED_NAME_FORMULA__C as preferred_mail_name
FROM stg_alumni.ucinn_ascendv2__contact_name__c  INDNAMESAL
Inner Join mv_entity ME
ON ME.SALESFORCE_ID = INDNAMESAL.UCINN_ASCENDV2__CONTACT__C
AND INDNAMESAL.ucinn_ascendv2__type__c = 'Full Name'),

--- spouse preferred mail name 

SMN as (select en.donor_id,
MN.preferred_mail_name as spouse_pref_mail_name
from mv_entity en
inner join MN on MN.donor_ID = en.spouse_donor_id),

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

--- 2017 Reunion committee 

rc17 as (select i.constituent_donor_id,
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
and i.involvement_start_date BETWEEN TO_DATE('09/01/2016', 'MM/DD/YYYY')
AND TO_DATE('08/31/2017', 'MM/DD/YYYY')),

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
--- update: 10/24/25 Zach's new Salutation code 

Dean as (Select e.donor_id,
       e.dean_salut,
       e.dean_source
From V_ENTITY_SALUTATIONS_INDIVIDUAL e),

--- household Dean Salutation 
--- Use this for Joint Salutations and Spouse 

hhdean as (select e.household_id_ksm,
       e.Spouse_Dean_Salut,
       e.spouse_full_name,
       e.Spouse_Dean_Source,
       e.joint_dean_salut,
       e.joint_fullname
  from V_ENTITY_SALUTATIONS_HOUSEHOLD e),

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
),

ROWDATA AS (
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
GROUP BY CREDITED_DONOR_ID),
  
mods as (select m.donor_id,
       m.household_id,
       m.household_primary,
       m.household_id_ksm,
       m.household_primary_ksm,
       m.sort_name,
       m.primary_record_type,
       m.institutional_suffix,
       m.mg_id_code,
       m.mg_id_description,
       m.mg_id_score,
       m.mg_pr_code,
       m.mg_pr_description,
       m.mg_pr_score,
       m.mg_probability,
       m.af_10k_code,
       m.af_10k_description,
       m.af_10k_score,
       m.alumni_engagement_code,
       m.alumni_engagement_description,
       m.alumni_engagement_score,
       m.student_supporter_code,
       m.student_supporter_description,
       m.student_supporter_score,
       m.etl_update_date,
       m.mv_last_refresh
  From mv_ksm_models m),
  
---Amy's Pledge Code 
  
KSM_PAYMENTS AS (
SELECT DISTINCT
  --KT.CREDITED_DONOR_ID
  KT.CREDIT_RECEIPT_NUMBER
  ,KT.HARD_AND_SOFT_CREDIT_SALESFORCE_ID
  ,KT.OPPORTUNITY_RECORD_ID
  ,KT.DESIGNATION_NAME
  ,KT.DESIGNATION_RECORD_ID
  ,KT.CREDIT_DATE
  ,KT.HARD_CREDIT_AMOUNT
FROM MV_KSM_TRANSACTIONS KT
WHERE KT.HARD_CREDIT_AMOUNT >0
  AND KT.GYPM_IND = 'Y'
),

GIVING_TRANS as (select *
from MV_KSM_TRANSACTIONS),
 
 
PLEDGEINFO AS (
SELECT DISTINCT
MKT.CREDITED_DONOR_ID
,MKT.CREDIT_DATE
,MKT.OPPORTUNITY_STAGE
,MKT.OPPORTUNITY_RECORD_ID
,MKT.DESIGNATION_RECORD_ID
,MAX(DD.UCINN_ASCENDV2__AMOUNT_PAID_TO_DATE_ROLL_UP__C) AS PLEDGE_AMOUNT_PAID_TO_DATE
,MAX(DD.UCINN_ASCENDV2__AMOUNT__C) AS PLEDGE_TOTAL_KSM
,MAX(DD.UCINN_ASCENDV2__REMAINING_AMOUNT_DUE_FORMULA__C) AS PLEDGE_BALANCE
FROM GIVING_TRANS MKT
INNER JOIN dm_alumni.dim_opportunity DO
ON MKT.OPPORTUNITY_RECORD_ID = DO.OPPORTUNITY_RECORD_ID
AND MKT.OPPORTUNITY_DONOR_ID = DO.OPPORTUNITY_DONOR_ID
INNER JOIN stg_alumni.ucinn_ascendv2__designation_detail__c DD
ON DO.OPPORTUNITY_DONOR_ID = DD.UCINN_ASCENDV2__DONOR_ID_FORMULA__C
AND DO.OPPORTUNITY_RECORD_ID = DD.UCINN_ASCENDV2__PLEDGE_ID_FORMULA__C
AND MKT.DESIGNATION_NAME = DD.UCINN_ASCENDV2__ACKNOWLEDGEMENT_DESCRIPTION_FORMULA__C
WHERE MKT.SOURCE_TYPE_DETAIL IN ('Pledge', 'Recurring Gift')   -- ADDED RECURRING GIFT AS TYPE on 2/9
Group By MKT.CREDITED_DONOR_ID,MKT.CREDIT_DATE,MKT.OPPORTUNITY_STAGE,MKT.OPPORTUNITY_RECORD_ID, MKT.DESIGNATION_RECORD_ID),

NEW_PLEDGE_INFO AS (
SELECT
KT.CREDITED_DONOR_ID AS ID
,ROW_NUMBER() OVER(PARTITION BY KT.CREDITED_DONOR_ID ORDER BY KT.CREDIT_DATE DESC)RW
,KT.OPPORTUNITY_RECORD_ID AS PLG
,KT.OPPORTUNITY_STAGE AS STAT
,KT.CREDIT_DATE AS DT
,KT.DESIGNATION_RECORD_ID AS ACCT
,KT.PLEDGE_TOTAL_KSM AS AMT
,KT.PLEDGE_AMOUNT_PAID_TO_DATE
,KT.PLEDGE_BALANCE AS BAL
FROM PLEDGEINFO KT
),
 
--- Final Pledge Code
 
amy_pledge_code as (select ID,
max(decode(rw,1,dt)) last_plg_dt,
max(decode(rw,1,stat)) status1,
max(decode(rw,1,plg)) plg1,
max(decode(rw,1,amt)) pamt1,
max(decode(rw,1,PLEDGE_AMOUNT_PAID_TO_DATE)) paid1,
max(decode(rw,1,acct)) pacct1,
max(decode(rw,1,bal)) bal1
from NEW_PLEDGE_INFO
group by NEW_PLEDGE_INFO.id),

--- KSM Faculty or Staff

f as (SELECT DISTINCT 
D.CONSTITUENT_DONOR_ID,
d.constituent_type
FROM DM_ALUMNI.DIM_CONSTITUENT d 
WHERE CONSTITUENT_TYPE LIKE '%Faculty/Staff%'),

 --- spouse program
sp as (
select 
e.spouse_donor_id,
e.spouse_name,
d.first_ksm_year,
d.program,
d.program_group
from mv_entity e 
inner join mv_entity_ksm_degrees d on d.donor_id = e.spouse_donor_id),

--- Honor Roll 

HR as (select c.id,
       mv_entity.donor_id,
       c.ucinn_ascendv2__first_name__c,
       c.ucinn_ascendv2__last_name__c,
       c.ucinn_ascendv2__type__c,
       c.ucinn_ascendv2__constructed_name_formula__c,
       c.ucinn_ascendv2__Data_Source__c,
       c.etl_create_date,
       c.etl_update_date
from STG_ALUMNI.UCINN_ASCENDV2__CONTACT_NAME__C c 
inner join mv_entity on mv_entity.donor_id = c.ucinn_ascendv2__contact__c
where c.ucinn_ascendv2__type__c = 'Honor Roll Name'
and  c.ucinn_ascendv2__Data_Source__c like '%Annual Giving%'),


--- anonymous donor

anon as (Select household_id
, household_primary_donor_id
, s.household_primary_full_name
, 'Y' As has_anon_giving_ksm
, s.ngc_lifetime_full_rec
, s.ngc_lifetime_nonanon_full_rec
From mv_ksm_giving_summary s
Where ngc_lifetime_full_rec <> ngc_lifetime_nonanon_full_rec
Order By ngc_lifetime_full_rec Desc),

--- For Honor Roll Report - Andy 
--- Data Points in Anniversary report from Amy 
--- Edit: 4/20/26

an as (select 
a.DONOR_ID,
a.HOUSEHOLD_ID_KSM,
a.last_plg_dt as last_pledge_date_hr,
a.status1 as status_hr,
a.type1 as pledge_type_hr,
a.plg1 as pg1_hr,
a.pamt1 as pamtl_hr,
a.pacct1 as pacct1_hr,
a.bal1 as ball_hr,
a.NU_$,
a.KSM_$,
a.KSM_CRU_$,
a.KSM_#_2025,
a.KSM_$_2025,
a.KSM_MATCH_2025,
a.KSM_#_2024,
a.KSM_$_2024,
a.KSM_MATCH_2024,
a.KSM_#_2023,
a.KSM_$_2023,
a.KSM_MATCH_2023,
a.KSM_#_2022,
a.KSM_$_2022,
a.KSM_MATCH_2022
from TABLEAU_AF_FIELDS a),

--- andy wants to add the name tag field 

nametag as (select n.donor_id,
       n.full_name,
       n.primary_constituent_type,
       n.salutation,
       n.first_name,
       n.middle_name,
       n.last_name,
       n.dean_salut,
       n.dean_source,
       n.institutional_suffix,
       n.degrees_verbose,
       n.degrees_concat,
       n.first_ksm_year,
       n.first_masters_year,
       n.last_masters_year,
       n.program,
       n.program_group,
       n.class_section,
       n.degree_levels,
       n.nu_degrees_string,
       n.family
from tableau_nametags n),

--- Zach's AF Model Scores View

zaf as (select distinct 
        m.household_id_ksm,
        m.donor_id,
        m.af_pr_code,
        m.af_pr_description,
        m.af_pr_score
from mv_ksm_models m),

--- Anonymous Flag - Most recent gift - trying to find if they made one in 2026 

--- Code is from Amy's Tableau Report - Amy does NOT have anon giving in her Tableau AF report, so made it here instead. 

--- We will take her code, but adjust filters on Transactions to anon giving 

--- Anon flag from Special Handling

sanon as (Select h.household_id_ksm
From mv_special_handling h
where h.anonymous_donor Is Not Null

UNION 

Select t.household_id_ksm
From mv_ksm_transactions t
Where t.fiscal_year = 2026
And t.anonymous_type = 'Completely anonymous'),

--- Transactions for anonymous in 2026
--- Need to change this when we get into 2027

t as (Select t.household_id_ksm,
t.tx_id,
t.credit_date,
t.fiscal_year,
t.credit_amount, 
t.hard_credit_amount,
t.designation_status, 
t.designation_name,
t.anonymous_type
From mv_ksm_transactions t
Where t.fiscal_year = 2026
And t.anonymous_type = 'Completely anonymous'),

--- 2026 Anonymous Gifts
--- Need to change this when we get into 2027

anons as (select t.household_id_ksm,
Listagg (t.tx_id, ';  ') Within Group (Order By t.tx_id) As anon_tx_id_fy_26,
Listagg (t.credit_date, ';  ') Within Group (Order By t.tx_id) As anon_credit_date_fy_26,
Listagg (t.fiscal_year, ';  ') Within Group (Order By t.tx_id) As anon_fiscal_year_fy_26,
Listagg (t.credit_amount, ';  ') Within Group (Order By t.tx_id) As anon_credit_amount_fy_26,
Listagg (t.hard_credit_amount, ';  ') Within Group (Order By t.tx_id) As anon_hard_credit_amount_fy_26,
Listagg (t.designation_status, ';  ') Within Group (Order By t.tx_id) As anon_designation_status_fy_26,
Listagg (t.designation_name, ';  ') Within Group (Order By t.tx_id) As anon_designation_name_fy_26
---Listagg (anon.anonymous_type, ';  ') Within Group (Order By anon.tx_id) As anonymous_type
from t 
group by t.household_id_ksm)
      
 
select distinct e.household_id,
     e.household_id_ksm,
     e.donor_id,
     e.household_primary,
     g.household_primary_donor_id,
     e.is_deceased_indicator,
     s.gender_identity,
     MN.preferred_mail_name,
     e.full_name,
     dean.dean_salut,
     e.first_name,
     e.last_name,
     e.institutional_suffix,
     FR.reunion_year_concat,
     KSM_Degrees.first_ksm_year,
     KSM_Degrees.first_masters_year,
     KSM_Degrees.program,
     KSM_Degrees.program_group,
     KSM_Degrees.class_section,
     e.spouse_donor_id,
     e.spouse_name,
     e.spouse_institutional_suffix,   
     sp.first_ksm_year as spouse_first_year,
     sp.program as spouse_program,
     sp.program_group as spouse_program_group, 
     hhdean.Spouse_Dean_Salut,
     hhdean.spouse_full_name,
     SMN.spouse_pref_mail_name,
     hhdean.spouse_Dean_Source,
     hhdean.joint_dean_salut, 
     hhdean.joint_fullname,    
     spr.reunion_year_concat as spouse_ksm_reunion_year,
     case when spr.reunion_year_concat is not null then hhdean.joint_dean_salut end as joint_dean_salut_reunion,
     case when spr.reunion_year_concat is not null then hhdean.Spouse_Dean_Source end as Spouse_Dean_Source_reunion,
       contact.address_preferred_type,
       contact.preferred_address_line_1,
       contact.preferred_address_line_2,
       contact.preferred_address_line_3,
       contact.preferred_address_line_4,
       contact.preferred_address_city,
       contact.preferred_address_state,
       contact.preferred_address_postal_code,
       contact.preferred_address_country,
       contact.preferred_geocode_primary,
       contact.preferred_geocodes_concat,
     klc.segment as KLC,
     case when g.ngc_fy_giving_first_yr is not null then g.ngc_fy_giving_first_yr else 0 end as ngc_fy_giving_first_yr,
     case when g.cash_fy_giving_first_yr is not null then g.cash_fy_giving_first_yr else 0 end as cash_fy_giving_first_yr,
     case when g.ngc_lifetime is not null then g.ngc_lifetime else 0 end as ngc_lifetime,
     case when g.cash_cfy > 0 Or g.ngc_cfy > 0  then 'Y' end as CYD_Flag, 
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
     anon.has_anon_giving_ksm,
     anon.ngc_lifetime_full_rec,
     anon.ngc_lifetime_nonanon_full_rec,
     g.last_cash_tx_id,
     g.last_cash_date,
     g.last_cash_opportunity_type,
     g.last_cash_designation,
     case when g.last_cash_recognition_credit is not null then g.last_cash_recognition_credit else 0 end as last_cash_recognition_credit,
     g.last_pledge_tx_id,
     g.last_pledge_date,
     g.last_pledge_opportunity_type,
     g.last_pledge_designation,
     case when  g.last_pledge_recognition_credit is not null then g.last_pledge_recognition_credit end as last_pledge_recognition_credit,
     apc.last_plg_dt,
     apc.status1,
     apc.plg1,
     apc.pamt1,
     apc.paid1,
     apc.pacct1,
     apc.bal1,    
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
     contact.linkedin_url,
     employ.primary_employ_ind,
     employ.primary_job_title,
     employ.primary_employer,
     case when f.CONSTITUENT_DONOR_ID is not null then 'Y' end as faculty_staff_flag, 
     assign.prospect_manager_name,
     assign.lagm_name,      
     contact.email_preferred,
     contact.phone_preferred,
     sh.no_contact,
     sh.no_mail_ind,
     sh.no_email_ind,
     sh.never_engaged_forever,
     sh.never_engaged_reunion,
     sh.no_solicit,
     sh.service_indicators_concat,
     gab.involvement_name as gab,
     trustee.involvement_name as trustee,
     kac.involvement_name as kac,
     asia.involvement_name as asia_exec_board,
     peac.involvement_name as peac, 
     reac.involvement_name as reac,
     hcak.involvement_name as hcak,  
     club.involvement_name as club_leader,
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
     s.constituent_last_visit_date,
     mods.mg_id_code,
     mods.mg_id_description,
     mods.mg_id_score,
     mods.mg_pr_code,
     mods.mg_pr_description,
     mods.mg_pr_score,
     mods.mg_probability,
     mods.af_10k_code,
     mods.af_10k_description,
     mods.af_10k_score,
     mods.alumni_engagement_code,
     mods.alumni_engagement_description,
     mods.alumni_engagement_score,
     mods.student_supporter_code,
     mods.student_supporter_description,
     mods.student_supporter_score,
     mods.etl_update_date,
     mods.mv_last_refresh,
     HR.ucinn_ascendv2__first_name__c as Honor_Roll_First_Name,
     HR.ucinn_ascendv2__last_name__c as Honor_Roll_Last_Name,
     HR.ucinn_ascendv2__type__c as Honor_Roll_Type,
     HR.ucinn_ascendv2__constructed_name_formula__c as Honor_Roll_Name_Formula,
     HR.ucinn_ascendv2__Data_Source__c as Honor_Roll_Data_Source,
     an.last_pledge_date_hr,
     an.status_hr,
     an.pledge_type_hr,
     an.pg1_hr,
     an.pamtl_hr,
     an.pacct1_hr,
     an.ball_hr,
     an.NU_$,
     an.KSM_$,
     an.KSM_CRU_$,
     an.KSM_#_2025,
     an.KSM_$_2025,
     an.KSM_MATCH_2025,
     an.KSM_#_2024,
     an.KSM_$_2024,
     an.KSM_MATCH_2024,
     an.KSM_#_2023,
     an.KSM_$_2023,
     an.KSM_MATCH_2023,
     an.KSM_#_2022,
     an.KSM_$_2022,
     an.KSM_MATCH_2022,
     nametag.first_name as nametag_first_name,
     nametag.middle_name as nametag_middle_name,
     nametag.last_name as nametag_last_name,
     nametag.dean_salut as nametag_dean_salut,
     nametag.nu_degrees_string as nametag_deg_string,
     nametag.family as nametag_family, 
     zaf.af_pr_code,
     zaf.af_pr_description,
     zaf.af_pr_score,
     case when gab2.CONSTITUENT_DONOR_ID is not null then 'Spouse GAB' end as gab_spouse,
     case when reac2.CONSTITUENT_DONOR_ID is not null then 'REAC Spouse' end as REAC_Spouse,
     case when hcak2.CONSTITUENT_DONOR_ID is not null then 'HCAK Spouse' end as HCAK_Spouse,
     case when peac2.CONSTITUENT_DONOR_ID is not null then 'PEAC Spouse' end as PEAC_Spouse,
     case when trustee2.CONSTITUENT_DONOR_ID is not null then 'Trustee Spouse' end as Trustee_Spouse,
     case when sanon.household_id_ksm is not null then 'Y' end as anonymous_26,
     anons.anon_tx_id_fy_26,
     anons.anon_credit_date_fy_26,
     anons.anon_fiscal_year_fy_26,
     anons.anon_credit_amount_fy_26,
     anons.anon_hard_credit_amount_fy_26,
     anons.anon_designation_status_fy_26,
     anons.anon_designation_name_fy_26
     from e 
left join KSM_Degrees on KSM_Degrees.donor_id = e.donor_id
--- Reunion eligible
inner join FR on FR.donor_id = e.donor_id 
--- giving info
--- edit - use household KSM - Created Reunion a while ago, but now should use household ksm 
left join give g on g.donor_id = e.donor_id
--- employment
left join employ on employ.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C = e.donor_id
--- special handling
left join SH on SH.donor_id = e.donor_id 
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
--- preferred mail name
left join MN on MN.DONOR_ID = e.donor_id 
---left join Salutation on Salutation.donor_id = e.spouse_donor_id
--- spouse reunion year
left join spr on spr.spouse_donor_id = e.spouse_donor_id
--- Club Leaders
left join club on club.constituent_donor_id = e.donor_id 
--- Dean indiv Salutation
left join Dean on Dean.donor_id = e.donor_id 
--- Dean Joint Salutation 
left join hhdean on hhdean.household_id_ksm = e.household_id 
--- KLC 
left join klc on klc.donor_id = e.donor_id 
--- last 4 gifts
left join GIFTINFO gi on gi.CREDITED_DONOR_ID = e.donor_id
--- spouse preferred name
left join SMN on SMN.donor_id = e.donor_id 
--- AR Mod
left join mods on mods.donor_id = e.donor_id
--- Amy Pledge Code
left join amy_pledge_code apc on apc.id = e.donor_id
--- faculty or staff
left join f on f.CONSTITUENT_DONOR_ID = e.donor_id
--- spouse program
left join sp on sp.spouse_donor_id = e.spouse_donor_id
--- Honor Roll 
left join HR on HR.donor_id = e.donor_id
--- anon donor
left join anon on anon.household_id = e.household_id_ksm
--- Anniversary Report 
left join an on an.donor_id = e.donor_id
--- peac 
left join peac on peac.constituent_donor_id = e.donor_id 
--- hcak
left join hcak on hcak.constituent_donor_id = e.donor_id
--- reac
left join reac on reac.constituent_donor_id = e.donor_id
--- nametag
left join nametag on nametag.donor_id = e.donor_id 
--- Zach AF 
left join zaf on zaf.donor_id = e.donor_id
--- GAB Spouse IND 
left join gab gab2 on gab2.CONSTITUENT_DONOR_ID = e.spouse_donor_id
--- REAC Spouse IND
left join REAC reac2 on reac2.CONSTITUENT_DONOR_ID = e.spouse_donor_id
--- HCAK Spouse IND
left join HCAK hcak2 on hcak2.CONSTITUENT_DONOR_ID = e.spouse_donor_id
--- PEAC Spouse IND
left join PEAC peac2 on peac2.CONSTITUENT_DONOR_ID = e.spouse_donor_id 
--- Trustee Spouse IND
left join trustee trustee2 on trustee2.CONSTITUENT_DONOR_ID = e.spouse_donor_id
--- anon gift summed in 2026
left join sanon on sanon.household_id_ksm = e.household_id_ksm
--- 2026 Anonymous gifts
left join anons on anons.household_id_ksm = e.household_id_ksm
--- contact 
left join contact on contact.donor_id = e.donor_id