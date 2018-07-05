-- Based on "principal gifts checklist _20180316.sql"

create or replace view Pg_Cultivation as
/* Officer Rated Prospects */ 

WITH bi_entity as (
select
a.ID_NUMBER
,a.PRIMARY_RECORD_TYPE_DESC
,b.PRIMARY_RECORD_TYPE_DESC sp_record_type
,a.BIRTH_DT

  ,case when a.RECORD_STATUS_CODE = 'D' 
    then null else floor(months_between(sysdate,
       case when a.BIRTH_DATE_AGE_BASIS = a.BIRTH_DT
          and a.BIRTH_DT <>'00000000' then to_date(a.BIRTH_DT,'YYYYMMDD') else null end) / 12) end as AGE 

,a.PREF_CLASS_YEAR
,a.EMAIL_ADDRESS
,a.PHONE_AREA_CODE
,a.PHONE_NUMBER
,a.GIVING_AFFILIATION_DESC
,a.PREF_MAIL_NAME
,a.PREF_NAME_SORT
,a.PERSON_OR_ORG
,a.spouse_id_number

from dm_ard.dim_entity@catrackstobi a
left outer join dm_ard.dim_entity@catrackstobi b on (a.spouse_id_number = b.id_number) 
               and b.CURRENT_INDICATOR = 'Y' and b.deleted_flag = 'N'
where a.CURRENT_INDICATOR = 'Y' and a.deleted_flag = 'N'
and a.person_or_org='P' -- added 2/22/2018
and a.ID_NUMBER NOT IN ('0' , ' ', '-1')
)

,addresses as (



    SELECT address.ID_NUMBER,
         case when  address.country_code IN (' ', 'US') then   tms_states.short_desc else  tc.short_desc end as category
      
  FROM address
    INNER JOIN entity e on (e.id_number = address.id_number) and e.record_status_code = 'A'
    LEFT OUTER JOIN tms_states on tms_states.state_code = address.state_code
   LEFT OUTER JOIN tms_country tc on tc.country_code = address.country_code

   WHERE address.addr_status_code = 'A'
   and address.addr_pref_ind = 'Y'
)



, double_alum_HH as (

select id_number from bi_entity 
where primary_record_type_desc = 'Alumnus/Alumna'
and sp_record_type = 'Alumnus/Alumna'

)




,bi_prospects as (
          select coalesce(
          case when to_char(dp.prospect_id) = '0' then ' ' 
        --- else to_char(prospect_id) end ,' ')  prospect_id
             else to_char(dp.prospect_id) end ,' ')  prospect_id
             ,PROSPECT_NAME, PROSPECT_TEAM_DESC, RATING_DESC, RESEARCH_EVALUATION_DESC, QUALIFICATION_DESC
             ,LAST_CONTACT_REPORT_DATE, LAST_VISIT_DATE, VISIT_COUNT
             ,LAST_PLEDGE_DATE, LAST_PLEDGE_PAYMENT_DATE, PROSPECT_MANAGER_NAME, PROSPECT_MANAGER_ID_NUMBER, PROSPECT_MANAGED_FLAG, 
             ACTIVE_IND
             	,coalesce(RATING_DESC,' ') as UOR_RATING 
             ,ATHLETICS_PROG_FLAG
             ,BIENEN_PROG_FLAG,BLOCK_PROG_FLAG,CENTER_INST_PROG_FLAG,COMMUNICATION_PROG_FLAG ,FEINBERG_PROG_FLAG,KELLOGG_PROG_FLAG,LAW_PROG_FLAG,LIBRARY_PROG_FLAG,MCCORMICK_PROG_FLAG
             ,MCCORMICK_PROG_FLAG as MC
             ,MEDILL_PROG_FLAG ,NMH_PROG_FLAG,SCS_PROG_FLAG ,SESP_PROG_FLAG,STU_LIFE_PROG_FLAG ,TBD_PROG_FLAG,TGS_PROG_FLAG,UNIV_UNRS_PROG_FLAG,WEINBERG_PROG_FLAG
    
from
            DM_ARD.DIM_PROSPECT@CATRACKSTOBI dp
            join prospect_entity --added this and below lines on 2/24/2018
            on prospect_entity.prospect_id=dp.Prospect_id@CATRACKSTOBI
            join entity
            on entity.id_number=prospect_entity.id_number
           where deleted_flag = 'N'
           and current_indicator = 'Y'
           and active_ind = 'Y'   --this was previously commented out. changed 2/24/2018. Did not impact count 
          and dp.prospect_id > 0  
          and entity.person_or_org='P' 
          and prospect_entity.primary_ind='Y'   
)


,active_proposals as (

select unique
prospect_id
from proposal p
where p.active_ind = 'Y'


)

,active_proposals1m as (

select unique
prospect_id
from proposal p
where p.active_ind = 'Y'
and p.ask_amt > 1000000 --changed from $2m to $1m 2/22/2018

)

--- giving data

,bi_gift_transactions as (

SELECT
    entity_id_number as id_number,
    gift_credit_amount
    ,trans_id_number
    ,to_date( (DAY_MM_S_DD_S_YYYY_DATE ) , 'mm/dd/yyyy' ) as date_of_record
    ,year_of_giving
    ,trans.TRANSACTION_SUB_GROUP_CODE
    ,annual_sw
    ,MATCHING_GIFT_CREDIT_AMOUNT + PLEDGE_CREDIT_DISC_AMOUNT + case when TRANSACTION_GROUP_CODE = 'G' then GIFT_CREDIT_AMOUNT else 0 end as NCG
    ,year_of_giving yr
FROM
    DM_ARD.FACT_GIVING_TRANS@catrackstobi gv
LEFT OUTER JOIN DM_ARD.DIM_DATE@catrackstobi dt on dt.day_date_key = date_of_record_key
LEFT OUTER JOIN DM_ARD.DIM_Transaction_group@catrackstobi trans on trans.TRANSACTION_GROUP_SID = gv.TRANSACTION_GROUP_SID
LEFT OUTER JOIN dm_ard.dim_allocation@catrackstobi alloc on (alloc.allocation_sid = gv.ALLOCATION_SID)
 and  alloc.DELETED_FLAG='N' and alloc.CURRENT_INDICATOR='Y'
INNER JOIN entity e
      on (e.id_number = gv.entity_id_number) and e.record_status_code IN ('A')
where TRANSACTION_SUB_GROUP_CODE IN ('GC', 'YC', 'PC', 'MC')


)

, bi_gift_transactions_single as (

---Completed major gift of $250K or more 
---(can include either an outright gift or a pledge, but the pledge must be paid in full) 


select unique ID_NUMBER from (
SELECT
    entity_id_number as id_number,
    gift_credit_amount
    ,trans_id_number
    ,to_date( (DAY_MM_S_DD_S_YYYY_DATE ) , 'mm/dd/yyyy' ) as date_of_record
    ,year_of_giving
    ,trans.TRANSACTION_SUB_GROUP_CODE
    ,annual_sw
    ,MATCHING_GIFT_CREDIT_AMOUNT + PLEDGE_CREDIT_DISC_AMOUNT + case when TRANSACTION_GROUP_CODE = 'G' then GIFT_CREDIT_AMOUNT else 0 end as NCG
    ,year_of_giving yr
    ,alloc.alloc_short_name
    ,p.pledge_status_code
   
FROM
    DM_ARD.FACT_GIVING_TRANS@catrackstobi gv
LEFT OUTER JOIN DM_ARD.DIM_DATE@catrackstobi dt on dt.day_date_key = date_of_record_key
LEFT OUTER JOIN DM_ARD.DIM_Transaction_group@catrackstobi trans on trans.TRANSACTION_GROUP_SID = gv.TRANSACTION_GROUP_SID
LEFT OUTER JOIN dm_ard.dim_allocation@catrackstobi alloc on (alloc.allocation_sid = gv.ALLOCATION_SID)
 and  alloc.DELETED_FLAG='N' and alloc.CURRENT_INDICATOR='Y'
left outer join dm_ard.dim_primary_pledge@catrackstobi p on trans_id_number = p.pledge_number

INNER JOIN entity e
      on (e.id_number = gv.entity_id_number) and e.record_status_code IN ('A')
where TRANSACTION_SUB_GROUP_CODE IN ('GC', 'PC') --- outright gifts & pledges
) where (NCG > 250000
and transaction_sub_group_code = 'GC')

or (NCG > 250000
and transaction_sub_group_code = 'PC'
and pledge_status_code = 'P')








)



,distinct_years as (

select id_number, count(distinct yr) ct
from bi_gift_transactions
group by id_number

)


,distinct_years_last_3 as (

select id_number, count(distinct year_of_giving) ct
from bi_gift_transactions
where year_of_giving IN ('2018' , '2017', '2016') --removed 2015 on 2/22/2018
group by id_number


)


--added 2/23/2018
,annual_25k as (

select entity_key
from dm_ard.fact_donor_summary@catrackstobi
where annual_fund_flag='Y'
and reporting_area='NA'
and (max_fyear_giftcredit >=25000 OR max_fyear_pledgecredit >=25000)
--and entity_key='0000020852' just for testing
---and entity_key='0000202258' just for testing

)

/*Removed 2/23/2018

, annual_fund_sum as (
/* Soft Credit New Gifts and Commitments 
select id_number, sum(ncg) as ngc, sum(gift_credit_amount) as gc from ( 
select id_number, trans_id_number, ncg, gift_credit_amount from bi_gift_transactions
where annual_sw = 'Y'
and date_of_record >= sysdate - (365 *3)
)
group by id_number

)*/

/*  Total Unique Years of Giving */

,bi_gift_transactions_summary as (

select
   id_number
   ,gift_credit_amount
   ,trans_id_number
   ,date_of_record
   ,year_of_giving
   ,ROW_NUMBER() OVER (PARTITION BY id_number ORDER BY date_of_record desc) rownumber
   ,count(distinct year_of_giving) over (partition by id_number) yr_count
from
bi_gift_transactions
)


, giving_lifetime as (
   
    /* overall giving summaries, aggregated */

    /*FY should be set to current fy, per BI logic*/
    select
    entity_key as id_number
    ,LIFETIME_GIFT_CREDIT_AMOUNT
    ,to_char(LAST_GIFT_YEAR) as LAST_GIFT_YEAR
    ,GIFT_CREDIT_YRS_IN_PREV5
    ,PREVYEARS_GIFTCREDIT_1000
    ,LIFETIME_NEWGIFT_CMIT_W_SPOUSE
    ,CAMPAIGN_NEWGIFT_CMIT_CREDIT
    ,active_pledge_balance
    from dm_ard.fact_donor_summary@catrackstobi
    where
    annual_fund_flag = 'N'
    and REPORTING_AREA = 'NA'
)



,NU_degrees as (

     SELECT ID_NUMBER,
                   /* tms_school.short_desc || ' (' || degree_year || ')' */ 
                   
                   tms_school.short_desc as degree_school,
                   degree_year,
                   degree_code
                
                   ---tm.short_desc major_code1,
                   ---tm2.short_desc major_code2
                   
     FROM degrees
              left outer join tms_school on tms_school.school_code = degrees.school_code
              left outer join tms_majors tm on tm.major_code = degrees.major_code1
              left outer join tms_majors tm2 on tm2.major_code = degrees.major_code2
     WHERE (degrees.INSTITUTION_CODE = '31173' OR LOCAL_IND = 'Y') ---- NU grads code
     AND degrees.degree_year != ' '
     
 

)

,all_NU_degrees as (

    SELECT ID_NUMBER,
     ---listagg(degree_school || ' , ' || major_code1 || ' , ' || degree_code || ' , ' || degree_year ,  ' ; ' ) within GROUP(ORDER BY NU_degrees.ID_NUMBER) as schoolslist
     listagg(degree_school || ' , ' || degree_code || ', ' || degree_year ,  ' ; ' ) within GROUP(ORDER BY NU_degrees.ID_NUMBER) as schoolslist
    
    FROM NU_degrees
    GROUP BY ID_NUMBER

)



,contact_reports as (
    select
    contact_report.id_number
    ,e.pref_mail_name
    ,contact_date
    ,contact_type
    ,p.short_desc as contact_purpose
    ,contact_report.author_id_number
    from contact_report
    left outer join entity e on e.id_number = contact_report.author_id_number
    left outer join tms_contact_rpt_purpose p on p.contact_purpose_code = contact_report.contact_purpose_code
    ----inner join prospect p on (p.prospect_id = pe.prospect_id) and p.active_ind = 'Y'
    where contact_report.id_number <> ' '

    union all

    select
    contact_report.id_number_2
    ,e.pref_mail_name
    ,contact_date
    ,contact_type
    ,p.short_desc as contact_purpose
    ,contact_report.author_id_number
    from contact_report
    left outer join entity e on e.id_number = contact_report.author_id_number
    left outer join tms_contact_rpt_purpose p on p.contact_purpose_code = contact_report.contact_purpose_code
    where contact_report.id_number_2 <> ' '
)

, lastContactReport as (

  select id_number
  ,max(contact_date) last_contact_date
  from contact_reports
  group by id_number


)


, lastContactReportV as (

  select id_number
  ,max(contact_date) last_contact_date
  from contact_reports
  where contact_type = 'V'
  group by id_number


)


, contactRptCount as (
  select
  id_number
  ,count(*) id_count
  from contact_reports
  group by id_number

)



, contactRptCountV as (
  select
  id_number
  ,count(*) id_count
  from contact_reports
  where contact_type = 'V'
  group by id_number

)


, contactRptCtLastYr as (
  select
  id_number
  ,count(*) id_count
  from contact_reports
  where contact_date >= sysdate - (365)
  group by id_number

)

, contactRptCtLastYrV as (
  select
  id_number
  ,count(*) id_count
  from contact_reports
  where contact_date >= sysdate - (365)
  and contact_type = 'V'
  group by id_number

)



, contacts as (

select

    id_number
    ,pref_mail_name
    ,contact_date
    ,contact_type
    ,contact_purpose
    ,author_id_number
    ,row_number() OVER (PARTITION BY id_number, AUTHOR_ID_NUMBER ORDER BY CONTACT_DATE DESC) as rownumber
    ,row_number() OVER (PARTITION BY id_number, AUTHOR_ID_NUMBER, CONTACT_TYPE ORDER BY CONTACT_DATE DESC) as rownumber2
    ,row_number() OVER (PARTITION BY id_number, contact_type ORDER BY CONTACT_DATE DESC) as rownumber3
from contact_reports

)

,MOS_visit as (

select id_number
,count(*) as visit_ct
from contact_reports
where author_id_number = '0000573302'
and contact_type = 'V'
group by id_number

)


,
parents as
 (
  select unique id_number
             from affiliation
             left outer join tms_affil_code tac on tac.affil_code = affiliation.affil_code
   where affil_level_code = 'PR'
     and affil_status_code IN ('C' , 'P')

  )


, committees as (

select distinct id_number from (

select distinct id_number from committee
where committee.committee_status_code IN ('C' , 'F')
and committee.committee_code IN (
    select committee_code
    from committee_header
    where committee_type_code IN ('TB' , 'AB')
    and status_code = 'A'
)

union 

select id_number
from affiliation
where affiliation.affil_code = 'TR'
and affiliation.affil_status_code IN ('C' , 'P')
)
)

--updated season tickets locgic 2/22/2018. Now looks for people who have 3+ years of season tickets
,seasontickets as (


  select distinct id_number
  from activity
  where activity_code in ('BBSEA','FBSEA')
  having count (distinct substr(start_dt,1,4)) > 2
  group by id_number 

  ) 


, affinity_score_all_rows as
(
select segment.id_number
, segment_code
, case when nvl(length(trim(translate(xcomment, '0123456789.-',' '))),0) = 0
  then round(to_number(rtrim(ltrim(xcomment)))) else null end affinity_score
, case when nvl(length(trim(translate(xcomment, '0123456789.-',' '))),0) = 0
  then to_number(rtrim(ltrim(xcomment))) else null end affinity_score_detail
from segment
where segment.segment_code like 'AFF__'
)

-- entity merges can create multiple rows for same entity
, affinity_score_value as
(
select id_number
, max(segment_code) affinity_segment
, max(affinity_score) affinity_score
, max(affinity_score_detail) affinity_score_detail
from affinity_score_all_rows
group by id_number
)

--chicago_home added 2/22/2018. 

, chi_t1_home as
(

    select address.id_number
    from address
    join address_geo
    on ADDRESS.ID_NUMBER=ADDRESS_GEO.ID_NUMBER and ADDRESS.XSEQUENCE=ADDRESS_GEO.XSEQUENCE 
    join geo_code
    on ADDRESS_GEO.GEO_CODE=GEO_CODE.GEO_CODE
    where address.addr_type_code='H'
    and address.addr_status_code='A'
    and ADDRESS_GEO.Geo_Code='T1CH'
    --)
)

select 
 

 be.id_number as "Primary Entity ID"
,p.prospect_id as "Prospect ID"
,p.prospect_name as "Prospect Name"
,p.QUALIFICATION_DESC as "Qualification Level"

, a.category as "Pref State US/ Country (Int)"
, nvl(all_nu_degrees.schoolslist, ' ') as "All NU Degrees"
, nvl(nu_deg_spouse.schoolslist, ' ') as "All NU Degrees Spouse" 


, case when ap.prospect_id is not null then 1 else 0 end as "Active Prop Indicator"

--- Y/N inds

, case when be.age > 59 then 1 else 0 end as Age
, case when c_v_prmgr.contact_date > sysdate - (2 * 365) then 1 else 0 end as "PM Visit Last 2Yrs"
, case when contactRptCountV.id_count > = 5 then 1 else 0 end as "5 + Visits C Rpts"
, case when annual_25k.entity_key is not null then 1 else 0 end as "25K To Annual"
, case when (dy.ct >= 10 and dy3.ct >=1) then 1 else 0 end as "10+ Dist Yrs 1 Gft in Last 3"


, case when bi_gift_transactions_single.id_number is not null then 1 else 0 end as "MG $250000 or more"

, case when MOS_visit.visit_ct >0 then 1 else 0 end as "Morty Visit"
, case when committees.id_number is not null then 1 else 0 end as "Trustee or Advisory BD"
, case when p2.id_number is not null then 1 else 0 end as "Past or Current Parent"
, case when be.primary_record_type_desc = 'Alumnus/Alumna' then 1 else 0 end as "Alumnus"
, case when be.primary_record_type_desc = 'Alumnus/Alumna' and sp_record_type = 'Alumnus/Alumna' then 1 else 0 end as "Double-Alum"
, case when st.id_number is not null then 1 else 0 end as "3 Year Season-Ticket Holder"
, case when chi_t1_home.id_number is not null then 1 else 0 end as chiacgo_home
, p.prospect_manager_name as "Prospect Manager"
, af.affinity_score as "Affinity Score"
, gl.CAMPAIGN_NEWGIFT_CMIT_CREDIT
, gl.ACTIVE_PLEDGE_BALANCE
, be.pref_name_sort
, pias.multi_or_single_interest
, pias.potential_interest_areas
from bi_prospects p
left outer join prospect_entity pe on (pe.prospect_id = p.prospect_id) and pe.primary_ind = 'Y'
left outer join bi_entity be on be.id_number = pe.id_number
left outer join active_proposals ap on ap.prospect_id = p.prospect_id
left outer join chi_t1_home on chi_t1_home.id_number = be.id_number  --added 2/22/2018

left outer join annual_25k on annual_25k.entity_key=be.id_number --added 2/22/2018
--left outer join annual_fund_sum on annual_fund_sum.id_number = be.id_number  removed 2/22/2018

left outer join distinct_years dy on dy.id_number = be.id_number


left outer join contactRptCountV on (be.id_number = contactRptCountV.id_number) 

left outer join MOS_visit on MOS_visit.id_number = be.id_number
left outer join double_alum_HH on (double_alum_HH.id_number = be.id_number)
left outer join committees on committees.id_number = be.id_number
left outer join parents p2 on p2.id_number = be.id_number
left outer join seasontickets st on st.id_number = be.id_number
left outer join bi_gift_transactions_single on bi_gift_transactions_single.id_number = be.id_number
left outer join distinct_years_last_3 dy3 on dy3.id_number = be.id_number
left outer join addresses a on a.id_number = be.id_number
left outer join all_NU_Degrees on all_NU_Degrees.id_number = be.id_number
left outer join all_NU_Degrees nu_deg_spouse on nu_deg_spouse.id_number = be.spouse_id_number
left outer join affinity_score_value af on af.id_number = be.id_number 
left outer join giving_lifetime gl on gl.id_number = be.id_number
left outer join advance_nu_rpt.prospect_interest_area_summary pias on pias.prospect_id=p.prospect_id --added 3/16/2018 

left outer join contacts c on (

                           /* last contact by prospect manager */

                           c.id_number = be.id_number

                           and

                           c.rownumber = 1

                           and (c.author_id_number = p.prospect_manager_id_number)

                           )
                           
                           
left outer join contacts c_v_prmgr on /* last visit by prospect manager */

                            c_v_prmgr.id_number = be.id_number

                            and

                            c_v_prmgr.rownumber2 = 1

                            and

                            c_v_prmgr.contact_type = 'V'

                            and (c_v_prmgr.author_id_number = p.prospect_manager_id_number)
                            
                            
                            
where 
(
(p.QUALIFICATION_DESC IN ('A1 $100M+' , 'A2 $50M - 99.9M' , 'A3 $25M - $49.9M' , 'A4 $10M - $24.9M', 'A5 $5M - $9.9M', 'A6 $2M - $4.9M', 'A7 $1M - $1.9M') --updated 2/22/2018 to include $1M +
and p.active_IND = 'Y') or (p.prospect_id >0 and p.prospect_id in (select prospect_id from active_proposals1m)))

and p.prospect_name not like  '%Anonymous%'

---below removed on 2/23/2018
--and p.prospect_name <> 'Northwestern Memorial HealthCare'
--and p.prospect_name <> 'Northwestern Memorial Fdn'
--and be.id_number <> '0000267298' 
