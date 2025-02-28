Create or Replace View V_KSM_25_REUNION AS

With manual_dates As (
Select
  2024 AS pfy
  ,2025 AS cfy
  From DUAL
)

,HOUSE AS (SELECT *
FROM rpt_pbh634.v_entity_ksm_households)

,KSM_DEGREES AS (
 SELECT
   KD.ID_NUMBER
   ,KD.PROGRAM
   ,KD.PROGRAM_GROUP
   ,KD.CLASS_SECTION
   ,KD.first_masters_year
 FROM RPT_PBH634.V_ENTITY_KSM_DEGREES KD
 WHERE KD."PROGRAM" IN ('EMP', 'EMP-FL', 'EMP-IL', 'EMP-CAN', 'EMP-GER', 'EMP-HK', 'EMP-ISR', 'EMP-JAN', 'EMP-CHI', 'FT', 'FT-1Y', 'FT-2Y', 'FT-CB', 'FT-EB', 'FT-JDMBA', 'FT-MMGT', 'FT-MMM', 'FT-MBAi', 'TMP', 'TMP-SAT',
'TMP-SATXCEL', 'TMP-XCEL')
)

,KSM_REUNION AS (
SELECT
A.*
,House.HOUSEHOLD_ID
,D.PROGRAM
,D.PROGRAM_GROUP
,D.CLASS_SECTION
,HOUSE.SPOUSE_ID_NUMBER
,HOUSE.SPOUSE_PREF_MAIL_NAME
,HOUSE.SPOUSE_SUFFIX
,HOUSE.SPOUSE_FIRST_KSM_YEAR
,HOUSE.SPOUSE_PROGRAM
,HOUSE.SPOUSE_PROGRAM_GROUP
,HOUSE.HOUSEHOLD_GEO_CODES
FROM AFFILIATION A
CROSS JOIN manual_dates MD
Inner JOIN house ON House.ID_NUMBER = A.ID_NUMBER
Inner Join KSM_DEGREES d on d.id_number = a.id_number
WHERE (TO_NUMBER(NVL(TRIM(A.CLASS_YEAR),'1')) IN (MD.CFY-1, MD.CFY-5, MD.CFY-10, MD.CFY-15, MD.CFY-20, MD.CFY-25, MD.CFY-30, MD.CFY-35, MD.CFY-40,
  MD.CFY-45, MD.CFY-50, MD.CFY-51, MD.CFY-52, MD.CFY-53, MD.CFY-54, MD.CFY-55, MD.CFY-56, MD.CFY-57, MD.CFY-58, MD.CFY-59, MD.CFY-60)
AND A.AFFIL_CODE = 'KM'
AND A.AFFIL_LEVEL_CODE = 'RG'))

--- Consideration of those with Mult Reunion Years from Our NU

,KR_YEAR_CONCAT AS (Select KR.id_number
,Listagg (KR.Class_Year, ';  ') Within Group (Order By KR.Class_Year) As ksm_reunion_year_concat
from KSM_REUNION KR 
group by KR.id_number)

,GIVING_SUMMARY AS (select s.ID_NUMBER,
       s.CRU_CFY,
       s.CRU_PFY1,
       s.CRU_PFY2,
       s.CRU_PFY3,
       s.CRU_PFY4,
       s.CRU_PFY5,
       s.anonymous_donor,
       s.anonymous_cfy_flag,
       s.anonymous_pfy1_flag,
       s.anonymous_pfy2_flag,
       s.anonymous_pfy3_flag,
       s.anonymous_pfy4_flag,
       s.anonymous_pfy5_flag,
       s.ANONYMOUS_CFY,
       s.ANONYMOUS_PFY1,
       s.ANONYMOUS_PFY2,
       s.ANONYMOUS_PFY3,
       s.ANONYMOUS_PFY4,
       s.ANONYMOUS_PFY5,
       s.STEWARDSHIP_CFY,
       s.STEWARDSHIP_PFY1,
       s.STEWARDSHIP_PFY2,
       s.STEWARDSHIP_PFY3,
       s.STEWARDSHIP_PFY4,
       s.STEWARDSHIP_PFY5,
       s.AF_CFY,
       s.AF_PFY1,
       s.AF_PFY2,
       s.AF_PFY3,
       s.AF_PFY4,
       s.AF_PFY5,
       s.NU_MAX_HH_LIFETIME_GIVING
from rpt_pbh634.v_ksm_giving_summary s)

,GIVING_TRANS AS
( SELECT HH.*
  FROM rpt_pbh634.v_ksm_giving_trans_hh HH
  INNER JOIN KSM_REUNION KR
  ON HH."ID_NUMBER" = KR.ID_NUMBER
)

-- 39 Seconds to run
,KSM_GIVING_MOD as (select *
from v_ksm_reunion_giving_mod) 

--- Spouse Reunion Year Only for 2024

,spouse_RY as (select house.SPOUSE_ID_NUMBER,
       KSM_REUNION.CLASS_YEAR
from house
inner join KSM_REUNION ON KSM_REUNION.ID_number = house.SPOUSE_ID_NUMBER)

,REUNION_20_COMMITTEE AS (
  SELECT DISTINCT
   ID_NUMBER
  FROM COMMITTEE
  WHERE COMMITTEE_CODE = '227' AND COMMITTEE_STATUS_CODE = 'F'
  AND START_DT = '20190901'
)

,REUNION_15_COMMITTEE AS (
  SELECT DISTINCT
   ID_NUMBER
  FROM COMMITTEE
  WHERE COMMITTEE_CODE = '227' AND COMMITTEE_STATUS_CODE = 'F'
  AND START_DT = '20140901'
)

,CURRENT_DONOR AS (
  SELECT DISTINCT HH.ID_NUMBER
FROM GIVING_TRANS HH
cross join rpt_pbh634.v_current_calendar cal
WHERE HH.FISCAL_YEAR = cal.CURR_FY
 AND HH.TX_GYPM_IND NOT IN ('P', 'M')
)


,REUNION_2015_PARTICIPANTS AS (
Select ep_participant.id_number,
ep_event.event_id
From ep_event
Left Join EP_Participant
ON ep_participant.event_id = ep_event.event_id
where ep_event.event_id = '12485'
)

--- Reunion Weekend 1 - This was the makeup weekend for 2020 

,REUNION_2022_PARTICIPANTS AS (
Select ep_participant.id_number,
ep_event.event_id
From ep_event
Left Join EP_Participant
ON ep_participant.event_id = ep_event.event_id
where ep_event.event_id = '26358'
)

,KSM_CLUB_LEADERS AS (select cl.id_Number
,Listagg (cl.Club_Title, ';  ') Within Group (Order By cl.Club_Title) As Club_Title
,Listagg (cl.Leadership_Title, ';  ') Within Group (Order By cl.Leadership_Title) As Leadership_Title
from v_ksm_club_leaders cl
group by cl.id_number) 

,PLG AS
(SELECT
   GT.ID_NUMBER
  ,count(distinct case when GT.TX_GYPM_IND = 'P'
         AND GT.PLEDGE_STATUS <> 'R'
         THEN GT.TX_NUMBER END) KSM_PLEDGES
  ,SUM(CASE WHEN GT.TX_GYPM_IND = 'P'
         AND GT.PLEDGE_STATUS <> 'R'
         THEN GT.CREDIT_AMOUNT END) KSM_PLG_TOT
   FROM GIVING_TRANS GT
GROUP BY GT.ID_NUMBER
)

,PLEDGE_ROWS AS
 (select ID,
                 max(decode(rw,1,dt)) last_plg_dt,
                 max(decode(rw,1,stat)) status1,
                 max(decode(rw,1,plg)) plg1,
                 max(decode(rw,1,amt)) pamt1,
                 max(decode(rw,1,acct)) pacct1,
                 max(decode(rw,1,bal)) bal1,
                 max(decode(rw,1,PLG_ACTIVE)) plgActive,
                 max(decode(rw,1,TRANSACTION_TYPE)) TRANSACTION_TYPE

          FROM
             (SELECT
                 ID
                 ,ROW_NUMBER() OVER(PARTITION BY ID ORDER BY DT DESC)RW
                 ,DT
                 ,PLG
                 ,AMT
                 ,ACCT
                 ,STAT
                 ,PLG_ACTIVE
                 ,TRANSACTION_TYPE
                 ,case when (bal * prop) < 0 then 0
                          else round(bal * prop,2) end bal
                FROM


       (SELECT
                      HH.ID_NUMBER ID
                      ,HH.TX_NUMBER AS PLG
                      ,HH.TRANSACTION_TYPE
                      ,HH.TX_GYPM_IND
                      ,HH.ALLOC_SHORT_NAME AS ACCT
                      ,CASE WHEN HH."PLEDGE_STATUS" = 'A' THEN 'Y' END AS PLG_ACTIVE
                      ,PS.SHORT_DESC AS STAT
                      ,HH.DATE_OF_RECORD AS DT
                      ,HH.CREDIT_AMOUNT
                      ,PP.PRIM_PLEDGE_AMOUNT AS AMT
                      ,PP.PRIM_PLEDGE_ORIGINAL_AMOUNT
                      ,PP.PRIM_PLEDGE_AMOUNT_PAID
                      ,p.pledge_associated_credit_amt
                      ,pp.prim_pledge_amount
                      ,CASE WHEN p.pledge_associated_credit_amt > pp.prim_pledge_amount THEN 1
                         ELSE p.pledge_associated_credit_amt / pp.prim_pledge_amount END PROP
                      ,PP.PRIM_PLEDGE_AMOUNT - pp.prim_pledge_amount_paid as BAL
                   FROM GIVING_TRANS HH
                   LEFT JOIN TMS_PLEDGE_STATUS PS
                   ON HH."PLEDGE_STATUS" = PS.pledge_status_code
                   INNER JOIN PLEDGE P
                   ON HH."ID_NUMBER" = P.PLEDGE_DONOR_ID
                       AND HH."TX_NUMBER" = P.PLEDGE_PLEDGE_NUMBER
                   LEFT JOIN PRIMARY_PLEDGE PP
                   ON P.PLEDGE_PLEDGE_NUMBER = PP.PRIM_PLEDGE_NUMBER
                   WHERE pp.prim_pledge_amount > 0
                   ))
             GROUP BY ID
)

,MYDATA AS (
         SELECT
           ID_NUMBER
           ,CREDIT_AMOUNT amt
           ,TX_GYPM_IND
           ,DATE_OF_RECORD dt
           ,TX_NUMBER rcpt
           ,MATCHED_TX_NUMBER m_rcpt
           ,ALLOC_SHORT_NAME acct
           ,AF_FLAG AF
           ,FISCAL_YEAR FY
           ,ASSOCIATED_CODE
           ,ASSOCIATED_DESC
          FROM GIVING_TRANS
          WHERE TX_GYPM_IND <> 'P'
)

,ROWDATA AS(
SELECT
           g.ID_NUMBER
           ,ROW_NUMBER() OVER(PARTITION BY g.ID_NUMBER ORDER BY g.dt DESC)RW
           ,g.amt
           ,m.amt match
           ,c.claim
           ,g.dt
           ,g.rcpt
           ,g.acct
           ,g.AF
           ,g.FY
           ,g.ASSOCIATED_CODE
           ,g.ASSOCIATED_DESC
           FROM (SELECT * FROM MYDATA WHERE TX_GYPM_IND <> 'M') g
           LEFT JOIN (SELECT * FROM MYDATA WHERE TX_GYPM_IND = 'M') m
                ON g.rcpt = m.m_rcpt AND g.ID_NUMBER = m.ID_NUMBER
           LEFT JOIN (SELECT
                KSMT.TX_NUMBER
                ,KSMT.ALLOCATION_CODE
                ,SUM(MC.CLAIM_AMOUNT) CLAIM
            FROM GIVING_TRANS KSMT
            INNER JOIN MATCHING_CLAIM MC
              ON KSMT."TX_NUMBER" = MC.CLAIM_GIFT_RECEIPT_NUMBER
              AND KSMT."TX_SEQUENCE" = MC.CLAIM_GIFT_SEQUENCE
              GROUP BY KSMT.TX_NUMBER, KSMT.ALLOCATION_CODE) C
              ON G.RCPT = C.TX_NUMBER
)

,GIFTINFO AS (
    SELECT
     ID_NUMBER
     ,max(decode(RW,1,rcpt))   rcpt1
     ,max(decode(RW,1,dt))       gdt1
     ,max(decode(RW,1,amt))     gamt1
     ,max(decode(RW,1,match))   match1
     ,max(decode(RW,1,claim)) claim1
     ,max(decode(RW,1,acct))   gacct1
     ,max(decode(RW,1,ASSOCIATED_CODE))   ASSOCIATED_CODE1
     ,max(decode(RW,1,ASSOCIATED_DESC))   ASSOCIATED_DESC1     
     ,max(decode(RW,2,rcpt)) rcpt2
     ,max(decode(RW,2,dt)) gdt2
     ,max(decode(RW,2,amt))     gamt2
     ,max(decode(RW,2,match))   match2
     ,max(decode(RW,2,claim)) claim2
     ,max(decode(RW,2,acct))   gacct2
     ,max(decode(RW,2,ASSOCIATED_CODE))   ASSOCIATED_CODE2
     ,max(decode(RW,2,ASSOCIATED_DESC))   ASSOCIATED_DESC2
     ,max(decode(RW,3,rcpt)) rcpt3
     ,max(decode(RW,3,dt)) gdt3
     ,max(decode(RW,3,amt))     gamt3
     ,max(decode(RW,3,match))   match3
     ,max(decode(RW,3,claim)) claim3
     ,max(decode(RW,3,acct))   gacct3
     ,max(decode(RW,3,ASSOCIATED_CODE))   ASSOCIATED_CODE3
     ,max(decode(RW,3,ASSOCIATED_DESC))   ASSOCIATED_DESC3
     ,max(decode(RW,4,rcpt)) rcpt4
     ,max(decode(RW,4,dt)) gdt4
     ,max(decode(RW,4,amt))     gamt4
     ,max(decode(RW,4,match))   match4
     ,max(decode(RW,4,claim)) claim4
     ,max(decode(RW,4,acct))   gacct4
     ,max(decode(RW,4,ASSOCIATED_CODE))   ASSOCIATED_CODE4
     ,max(decode(RW,4,ASSOCIATED_DESC))   ASSOCIATED_DESC4     
    FROM ROWDATA
    GROUP BY ID_NUMBER
)

,KSM_TOTAL AS (
 SELECT
  GT.ID_NUMBER
  ,SUM(GT.CREDIT_AMOUNT) AS KSM_TOTAL
 FROM GIVING_TRANS GT
 WHERE GT.TX_GYPM_IND NOT IN ('P','M')
 GROUP BY GT.ID_NUMBER
)

,KSM_AF_TOTAL AS (
  SELECT
    GT.ID_NUMBER
    ,SUM(GT.CREDIT_AMOUNT) AS KSM_AF_TOTAL
  FROM GIVING_TRANS GT
  WHERE GT.TX_GYPM_IND NOT IN ('P', 'M')
    AND (GT.AF_FLAG = 'Y' OR GT.CRU_FLAG = 'Y')
  GROUP BY GT.ID_NUMBER
)

,KSM_TOTAL24 AS (
  SELECT
  GT.ID_NUMBER
  ,SUM(GT.CREDIT_AMOUNT) AS KSM_TOTAL
 FROM GIVING_TRANS GT
 CROSS JOIN MANUAL_DATES MD
 WHERE GT.TX_GYPM_IND NOT IN ('P','M')
   AND GT.FISCAL_YEAR = MD.PFY
 GROUP BY GT.ID_NUMBER
)

--- Need to change this when we hit FY 25


,KSM_TOTAL25 AS (
  SELECT
  GT.ID_NUMBER
  ,SUM(GT.CREDIT_AMOUNT) AS KSM_TOTAL
 FROM GIVING_TRANS GT
 CROSS JOIN MANUAL_DATES MD
 WHERE GT.TX_GYPM_IND NOT IN ('P','M')
 --- CFY for 2024 !!! 
   AND GT.FISCAL_YEAR = MD.CFY
 GROUP BY GT.ID_NUMBER
)

--- Need to change this when we hit FY 25


,KSM_MATCH_24 AS (
   SELECT DISTINCT
     GT.ID_NUMBER
   FROM GIVING_TRANS GT
   CROSS JOIN MANUAL_DATES MD
   WHERE GT.TX_GYPM_IND = 'M'
     AND GT.MATCHED_FISCAL_YEAR = MD.PFY
 )
 
 --- Need to change this when we hit FY 25

 
,KSM_Total_Final as (
Select HOUSE.id_number
  ,KSMT.KSM_TOTAL
  ,KAFT.KSM_AF_TOTAL
  ,KSM_TOTAL24.KSM_TOTAL AS KSM_TOTAL24
  ,KSM_MATCH_24.ID_NUMBER AS KM24_ID_NUMBER
  --- Adding in KSM_Total 24 Now (4/18/24 - Honor Role - Andy Requested)
  ,KSM_TOTAL25.KSM_TOTAL as KSM_TOTAL25
from HOUSE
LEFT JOIN KSM_TOTAL KSMT ON HOUSE.ID_NUMBER = KSMT.ID_NUMBER
LEFT JOIN KSM_AF_TOTAL KAFT ON HOUSE.ID_NUMBER = KAFT.ID_NUMBER
LEFT JOIN KSM_TOTAL24  ON HOUSE.ID_NUMBER = KSM_TOTAL24.ID_NUMBER
LEFT JOIN KSM_MATCH_24 ON HOUSE.ID_NUMBER = KSM_MATCH_24.ID_NUMBER
LEFT JOIN KSM_TOTAL25 ON HOUSE.ID_NUMBER = KSM_TOTAL25.ID_NUMBER 
)
 

,PROPOSALS AS
(
SELECT
  ID_NUMBER
  ,WT0_PKG.GetProposal2(ID_NUMBER,NULL) PROPOSAL_STATUS
FROM KSM_REUNION
)

,AF_SCORES AS (
SELECT
 AF.ID_NUMBER
 ,max(AF.DESCRIPTION) as AF_10K_MODEL_TIER
 ,max(AF.SCORE) as AF_10K_MODEL_SCORE
FROM RPT_PBH634.V_KSM_MODEL_AF_10K AF
GROUP BY AF.ID_NUMBER
)

,p as (Select
         a.Id_number
      ,  tms_addr_status.short_desc AS Address_Status
      ,  tms_address_type.short_desc AS Address_Type
      ,  a.care_of
      ,  a.addr_type_code
      ,  a.addr_pref_ind
      ,  a.company_name_1
      ,  a.company_name_2
      ,  a.business_title
      ,  a.street1
      ,  a.street2
      ,  a.street3
      ,  a.foreign_cityzip
      ,  a.city
      ,  a.state_code
      ,  a.zipcode
      ,  tms_country.short_desc AS Country
      FROM address a
      INNER JOIN tms_addr_status ON tms_addr_status.addr_status_code = a.addr_status_code
      LEFT JOIN tms_address_type ON tms_address_type.addr_type_code = a.addr_type_code
      LEFT JOIN tms_country ON tms_country.country_code = a.country_code
      WHERE a.addr_pref_IND = 'Y'
      AND a.addr_status_code IN('A','K'))
      
,pfin as (select p.id_number
  ,Case When P.Address_type = 'Business'  Then P.Address_type Else P.Address_type End Address_Type
  ,Case When P.Address_type = 'Business'  Then P.care_of ELSE P.care_of End care_of
  ,Case When P.Address_type = 'Business'  Then P.Company_Name_1 End Business_Name
  ,Case When P.Address_type = 'Business'  Then P.Company_Name_2 End Business_Name_2
  ,Case When P.Address_type = 'Business'  Then P.business_title Else P.business_title End business_title
  ,Case When P.ADDRESS_TYPE = 'Business' Then P.Street1 else P.Street1 End Street1
  ,Case When P.ADDRESS_TYPE = 'Business' Then P.Street2 else P.Street2 End Street2
  ,Case When P.ADDRESS_TYPE = 'Business' Then P.Street3 else P.Street3 End Street3 
  ,Case When P.ADDRESS_TYPE = 'Business' Then P.City else P.City End City  
  ,Case When P.ADDRESS_TYPE = 'Business' Then P.State_code else P.State_code End State_code
  ,Case When P.ADDRESS_TYPE = 'Business' Then P.Zipcode else P.Zipcode End Zipcode
  ,Case When P.ADDRESS_TYPE = 'Business' Then P.country else P.Country End Country
  from p) 
      
,s as (Select spec.ID_NUMBER,
       spec.SPOUSE_ID_NUMBER,
       spec.SPECIAL_HANDLING_CONCAT,
       spec.SPEC_HND_CODES,
       spec.MAILING_LIST_CONCAT,
       spec.ML_CODES,
       spec.RECORD_STATUS_CODE,
       spec.GAB,
       spec.TRUSTEE,
       spec.EBFA,
       spec.NO_CONTACT,
       spec.NO_SOLICIT,
       spec.NO_RELEASE,
       spec.ACTIVE_WITH_RESTRICTIONS,
       spec.NEVER_ENGAGED_FOREVER,
       spec.NEVER_ENGAGED_REUNION,
       spec.HAS_OPT_INS_OPT_OUTS,
       spec.ANONYMOUS_DONOR,
       spec.EXC_ALL_COMM,
       spec.EXC_ALL_SOLS,
       spec.EXC_SURVEYS,
       spec.LAST_SURVEY_DT,
       spec.NO_SURVEY_IND,
       spec.NO_PHONE_IND,
       spec.NO_PHONE_SOL_IND,
       spec.NO_EMAIL_IND,
       spec.NO_EMAIL_SOL_IND,
       spec.NO_MAIL_IND,
       spec.NO_MAIL_SOL_IND,
       spec.NO_TEXTS_IND,
       spec.NO_TEXTS_SOL_IND,
       spec.KSM_STEWARDSHIP_ISSUE
From rpt_pbh634.v_entity_special_handling spec)

,assign as (select assign.id_number,
       assign.prospect_manager,
       assign.lgos,
       assign.managers,
       assign.curr_ksm_manager
from rpt_pbh634.v_assignment_summary assign)

--- Dean Salutation 
,dean as (Select rpt_zrc8929.v_dean_salutation.ID_NUMBER,
       rpt_zrc8929.v_dean_salutation.P_Dean_Salut,
       rpt_zrc8929.v_dean_salutation.P_Dean_Source,
       rpt_zrc8929.v_dean_salutation.Spouse_Dean_Salut
From rpt_zrc8929.v_dean_salutation),


KAC AS (select k.id_number,
       k.committee_code,
       k.short_desc,
       k.status
From table (rpt_pbh634.ksm_pkg_tmp.tbl_committee_kac) k),

PHS AS (Select p.id_number,
       p.short_desc,
       p.status,
       p.spouse_ID_Number
From table(rpt_pbh634.ksm_pkg_tmp.tbl_committee_phs) P),

--- My Employment Table

em As (
  Select id_number
  , job_title
  , employment.fld_of_work_code
  , fow.short_desc As fld_of_work
  , employer_name1,
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

--- KSM FACULTY/STAFF FLAG 


KSM_Faculty_Staff  as (select aff.id_number,
       aff.affil_status_code,
       TMS_AFFIL_CODE.short_desc as affilation_code,
       tms_affiliation_level.short_desc as affilation_level
FROM  affiliation aff
LEFT JOIN TMS_AFFIL_CODE ON TMS_AFFIL_CODE.affil_code = aff.affil_code
Left JOIN tms_affiliation_level ON tms_affiliation_level.affil_level_code = aff.affil_level_code
 WHERE  aff.affil_code = 'KM'
   AND  aff.affil_status_code = 'C'
   AND (aff.affil_level_code = 'ES'
    OR  aff.affil_level_code = 'EF')),
    
--- ALL NU FACULTY STAFF FLAG 
    
NU_Faculty_Staff as (select aff.id_number,
       aff.affil_status_code,
       TMS_AFFIL_CODE.short_desc as affilation_code,
       tms_affiliation_level.short_desc as affilation_level
FROM  affiliation aff
LEFT JOIN TMS_AFFIL_CODE ON TMS_AFFIL_CODE.affil_code = aff.affil_code
Left JOIN tms_affiliation_level ON tms_affiliation_level.affil_level_code = aff.affil_level_code
 WHERE  aff.affil_status_code = 'C'
 AND (aff.affil_level_code = 'ES'
    OR  aff.affil_level_code = 'EF')),

    
---32)  CYD gift made through DAF or Foundation (add – check with Amy on this) - 14 seconds to run 

GIVING_TRANS_DAF AS (SELECT *
  FROM rpt_pbh634.v_ksm_giving_trans GT
  INNER JOIN GIFT G
  ON GT."TX_NUMBER" = G.GIFT_RECEIPT_NUMBER
   AND GT."TX_SEQUENCE" = G.GIFT_SEQUENCE
  WHERE G.GIFT_ASSOCIATED_CODE IN ('D', 'C')
   AND (GT."AF_FLAG" = 'Y' OR GT."CRU_FLAG" = 'Y')
),

--- Need to change this when we hit FY 25


FOUNDATION AS (SELECT
           GIVING_TRANS_DAF.ID_NUMBER,
max (ENTITY.REPORT_NAME) keep (dense_rank First Order By DATE_OF_RECORD DESC) as REPORT_NAME,           
max (associated_desc) keep (dense_rank First Order By DATE_OF_RECORD DESC) as associated_desc,
max (DATE_OF_RECORD) keep (dense_rank First Order By DATE_OF_RECORD DESC) as DATE_OF_RECORD,
max (rpt_pbh634.ksm_pkg_tmp.get_fiscal_year (DATE_OF_RECORD)) keep (dense_rank First Order By DATE_OF_RECORD DESC) as YEAR_OF_RECORD,
max (TX_NUMBER) keep (dense_rank First Order By DATE_OF_RECORD DESC) as rcpt
          FROM GIVING_TRANS_DAF
          LEFT JOIN GIFT
          ON GIVING_TRANS_DAF.TX_NUMBER = GIFT.GIFT_RECEIPT_NUMBER
            --AND GIFT.GIFT_SEQUENCE = 1
          INNER JOIN ENTITY
          ON GIFT.GIFT_DONOR_ID = ENTITY.ID_NUMBER
          WHERE TX_GYPM_IND <> 'P'  AND GIFT.GIFT_SEQUENCE = 1
          and rpt_pbh634.ksm_pkg_tmp.get_fiscal_year (DATE_OF_RECORD) in ('2024','2025')
          GROUP BY GIVING_TRANS_DAF.ID_NUMBER),
          
--- Prospect as a Subquery (instead of left join and taking out another of Bill's Functions)

NP as (select TP.ID_NUMBER,
       TP.EVALUATION_RATING,
       TP.OFFICER_RATING
From nu_prs_trp_prospect TP),

c as (/* Last Contact Report - Date, Author, Type, Subject 
(# Contact Reports - Contacts within FY and 5FYs
*/
select cr.id_number,
max (cr.credited) keep (dense_rank First Order By cr.contact_date DESC) as credited,
max (cr.credited_name) keep (dense_rank First Order By cr.contact_date DESC) as credited_name,
max (cr.contacted_name) keep (dense_rank First Order By cr.contact_date DESC) as contacted_name,
max (cr.contact_type) keep (dense_rank First Order By cr.contact_date DESC) as contact_type,
max (cr.contact_date) keep (dense_rank First Order By cr.contact_date DESC) as contact_Date,
max (cr.contact_purpose) keep (dense_rank First Order By cr.contact_date DESC) as contact_purpose,
max (cr.description) keep (dense_rank First Order By cr.contact_date DESC) as description_,
max (cr.summary) keep (dense_rank First Order By cr.contact_date DESC) as summary_
from rpt_pbh634.v_contact_reports_fast cr
group by cr.id_number
),

--- Major Gift Model Scores

md as (select mg.id_number,
       mg.segment_year,
       mg.segment_month,
       mg.id_code,
       mg.id_segment,
       mg.id_score,
       mg.pr_code,
       mg.pr_segment,
       mg.pr_score,
       mg.est_probability
from rpt_pbh634.v_ksm_model_mg mg),

--- Need to change this when we hit FY 25
--- How will this be used next year????? New VFT ???? 


V as (SELECT DISTINCT
   ID_NUMBER,
   case when committee.id_number is not null then 'Reunion VFT Volunteer' end as Reunion_Volunteer
  FROM COMMITTEE
  WHERE COMMITTEE.COMMITTEE_CODE IN ('KRE1','K5RC','KRE10','KRE15','KRE20',
  'KRE25','KRE30','K35RC','KRE40','KRE45','KRE50')
  AND COMMITTEE.COMMITTEE_STATUS_CODE = 'C'),
  
  
 sol as (select id_number
,listagg(solicitor_name, '; ') within group (order by solicitor_name) solicitor_name
from
(select distinct a.id_number
,a.assignment_id_number
--,a.xcomment
,e.first_name || ' ' || e.last_name solicitor_name
from assignment a
join entity e
on e.id_number=a.assignment_id_number
where a.assignment_type='VS'
and a.active_ind='Y'
and (lower(a.xcomment) LIKE ('%ksm%1st%reunion%')
    or lower(a.xcomment) LIKE ('%ksm%5th%reunion%')
    or lower(a.xcomment) LIKE ('%ksm%10th%reunion%')
    or lower(a.xcomment) LIKE ('%ksm%15th%reunion%')
    or lower(a.xcomment) LIKE ('%ksm%20th%reunion%')
    or lower(a.xcomment) LIKE ('%ksm%25th%reunion%')
    or lower(a.xcomment) LIKE ('%ksm%30th%reunion%')
    or lower(a.xcomment) LIKE ('%ksm%35th%reunion%')
    or lower(a.xcomment) LIKE ('%ksm%40th%reunion%')
    or lower(a.xcomment) LIKE ('%ksm%45th%reunion%')
    or lower(a.xcomment) LIKE ('%ksm%50th%reunion%')
    or lower(a.xcomment) LIKE ('%ksm%55th%reunion%')
    or lower(a.xcomment) LIKE ('%ksm%60th%reunion%')
    or lower(a.xcomment) LIKE LOWER('%KSM E%W Reunion Committee%')
    or lower(a.xcomment) LIKE LOWER('%KSM EMBA Reunion Committee%')))
    group by id_number),

vs as (select sol.id_number,
sol.solicitor_name
from sol),
 
 
--- Anon Donor Honor Role 

/* Parameters -- update this each year
  Also look for <UPDATE THIS> comment */
params_cfy As (
  Select
    cfy As params_cfy
    --2024 As params_cfy -- <UPDATE THIS>
  --From DUAL
  From manual_dates
)
, params As (
  Select
    params_cfy
    , params_cfy - 1 As params_pfy1
    , params_cfy - 2 As params_pfy2
    , params_cfy - 3 As params_pfy3
    , params_cfy - 4 As params_pfy4
    , params_cfy - 5 As params_pfy5
    , params_cfy - 6 As params_pfy6
    , params_cfy - 7 As params_pfy7
    , params_cfy - 8 As params_pfy8
    , params_cfy - 9 As params_pfy9
    , params_cfy - 10 As params_pfy10
  From params_cfy
)

/* Honor roll names
  CATracks honor roll names, where available */
, hr_names As (
  Select
    id_number
    , trim(pref_name) As honor_roll_name
    , Case
        -- If prefix is at start of name then remove it
        When pref_name Like (prefix || '%')
          Then trim(
            regexp_replace(pref_name, prefix, '', 1) -- Remove first occurrence only
          )
        Else pref_name
        End
      As honor_roll_name_no_prefix
     , xcomment
  From name
  Where name_type_code = 'HR'
)

/* IR names
  FY19 IR names, if available */
, ir_names As (
  Select
    id_number
    , ir21_name --<UPDATE THIS>
    , first_name
    , middle_name
    , last_name
    , suffix
    -- Check whether suffix is a class year
    , Case
        When regexp_like(suffix, '''[0-9]+') -- valid examples: '00 '92 '11 '31
          Then 'Y'
        End
      As replace_year_flag
  From rpt_pbh634.tbl_ir_FY22_approved_names ian --<UPDATE THIS>
)


/* Degree strings
  Kellogg and NU strings, according to the updated FY21 degree format.
  Years and degree types are listed in chronological order and de-duped (listagg) */
, degs As (
  Select
    id_number
    ,pref_mail_name
    ,pref_first_name
    ,last_name
    ,nu_degrees_string As yrs
  From rpt_pbh634.v_entity_nametags
)

/* Household data
  Household IDs and definitions as defined by ksm_pkg_tmp. Names are based on primary name and personal suffix. */
, hhs As (
  Select hh.*, degs.yrs
  From table(rpt_pbh634.ksm_pkg_tmp.tbl_entity_households_ksm) hh
  Left Join degs
    On degs.id_number = hh.id_number
)
, hh_name As (
  Select
    hhs.id_number
    , entity.gender_code
    , entity.record_status_code
    , entity.jnt_gifts_ind
    , trim(entity.last_name)
      As entity_last_name
    -- First Middle Last Suffix 'YY
    -- Primary name
    , trim(
        trim(
          trim(
            -- Choose last year's name or honor roll name
            Case
              When ir_names.first_name Is Not Null
                Then
                  trim(
                    trim(
                      trim(ir_names.first_name) || ' ' || trim(ir_names.middle_name)
                    ) || ' ' || trim(ir_names.last_name)
                  ) || ' ' || ir_names.suffix
              Else
              -- Choose honor roll name or constructed name
              Case
                When hr_names.honor_roll_name_no_prefix Is Not Null
                  Then hr_names.honor_roll_name_no_prefix
                Else
                  trim(
                    trim(
                      trim(entity.first_name) || ' ' || trim(entity.middle_name)
                    ) || ' ' || trim(entity.last_name)
                  ) || ' ' || entity.pers_suffix
                End
              End
          )
          -- Add class year if replace_year_flag is null
          || ' ' || (Case When ir_names.replace_year_flag Is Null Then hhs.yrs End)
        -- Check for deceased status
        ) || (Case When entity.record_status_code = 'D' Then '<DECEASED>' End)
      )
      As primary_name
    -- How was the primary_name constructed?
    , Case
        When ir_names.first_name Is Not Null
          Then 'PFY IR'
        When hr_names.honor_roll_name_no_prefix Is Not Null
          Then 'NU HR name'
        Else 'Constructed'
        End
      As primary_name_source
    -- Constructed name
    , trim(
        trim(
          trim(
            trim(
              trim(
                trim(entity.first_name) || ' ' || trim(entity.middle_name)
              ) || ' ' || trim(entity.last_name)
            ) || ' ' || entity.pers_suffix
          ) || ' ' || hhs.yrs
        ) || (Case When entity.record_status_code = 'D' Then '<DECEASED>' End)
      )
      As constructed_name
    , ir_names.ir21_name --<UPDATE THIS>
    , hhs.yrs
    , Case
        When entity.record_status_code = 'D'
          And trunc(entity.status_change_date) Between cal.prev_fy_start And cal.today
          Then 'Y'
        End
      As deceased_past_year
  From hhs
  Inner Join entity
    On entity.id_number = hhs.id_number
  Cross Join rpt_pbh634.v_current_calendar cal
  Left Join hr_names
    On hr_names.id_number = hhs.id_number
  Left Join ir_names
    On ir_names.id_number = hhs.id_number
)
, hh As (
  Select
    hhs.*
    , hh_name.gender_code As gender
    , hh_name_s.gender_code As gender_spouse
    , hh_name.record_status_code As record_status
    , hh_name_s.record_status_code As record_status_spouse
    , hh_name.deceased_past_year
    -- Is either spouse no joint gifts?
    , Case
        When hhs.household_spouse_rpt_name Is Not Null
          And (hh_name.jnt_gifts_ind = 'N' Or hh_name_s.jnt_gifts_ind = 'N')
          Then 'Y'
        End
      As no_joint_gifts_flag
    -- First Middle Last Suffix 'YY
    , hh_name.primary_name
    , hh_name.constructed_name
    , hh_name.primary_name_source
    , hh_name_s.primary_name As primary_name_spouse
    , hh_name_s.constructed_name As constructed_name_spouse
    , hh_name_s.primary_name_source As primary_name_source_spouse
    , hh_name.yrs As yrs_self
    , hh_name_s.yrs As yrs_spouse
    -- Check for entity last name
    , Case
        When hh_name.primary_name Not Like '%' || hh_name.entity_last_name || '%'
          And hh_name.primary_name Not Like '%Anonymous%'
          Then 'Y'
        End
      As check_primary_lastname
    , Case
        When hh_name_s.primary_name Not Like '%' || hh_name_s.entity_last_name || '%'
          And hh_name_s.primary_name Not Like '%Anonymous%'
          Then 'Y'
        End
      As check_primary_lastname_spouse  
  From hhs hhs
  -- Names and strings for formatting
  Inner Join hh_name
    On hh_name.id_number = hhs.household_id
  Left Join hh_name hh_name_s
    On hh_name_s.id_number = hhs.household_spouse_id
  -- Exclude purgable entities
  Where hhs.record_status_code <> 'X'
)

/* Anonymous
  Anonymous special handling indicator; entity should be anonymous for ALL gifts. Overrides the transaction-level anon flag.
  Also mark as anonymous people whose names last year were Anonymous. */
, anon_dat As (
  (
  Select
    hhs.household_id
    , tms.short_desc As anon
  From handling
  Inner Join hhs
    On hhs.id_number = handling.id_number
  Inner Join tms_handling_type tms
    On tms.handling_type = handling.hnd_type_code
  Where hnd_type_code = 'AN' -- Anonymous
    And hnd_status_code = 'A' -- Active only
  ) Union (
  Select
    hhs.household_id
    , 'Anonymous IR Name' As anon
  From hhs
  Inner Join ir_names
    On ir_names.id_number = hhs.id_number
  Where ir_names.first_name = 'Anonymous'
  )),
 
anon_dw as (Select
    household_id
    , min(anon) As anon -- min() results in the order Anonymous, Anonymous Donor, Anonymous IR Name
  From anon_dat
  Group By household_id),
  
--- Any other Reunions Attended

--- Last Reunions Attended
last_reunion as (select f.id_number,
listagg (f.event_id, ';  ') Within Group (order by f.start_dt_calc) as last_reunion_event_id,
listagg (f.event_name, ';  ') Within Group (order by f.start_dt_calc) as last_reunion_event_name,
listagg (f.start_dt_calc, ';  ') Within Group (order by f.start_dt_calc) as last_reunion_start_dt
from rpt_pbh634.v_nu_event_participants_fast f
where f.Event_Id IN ('9760',
'7914',
'7904',
'7885',
'7883',
'7882',
'7879',
'8482',
'9760',
'12485',
'14583',
'21791',
'21792',
'21120',
'22429',
'26358',
'26385',
'28145',
'30185'
)
group by f.id_number),

--- 2025 Reunion Committee Members 

c25 as (SELECT DISTINCT
   ID_NUMBER
  FROM COMMITTEE
  WHERE COMMITTEE_CODE = '227' AND COMMITTEE_STATUS_CODE = 'C'),
 
  
final as (select  KSM_REUNION.id_number,
--- Anonymous donor check: giving summary, honor role and special handling 
case when anon_dw.anon is not null 
or GIVING_SUMMARY.ANONYMOUS_DONOR is not null
or s.ANONYMOUS_DONOR is not null then 'Y' end as ANONYMOUS_DONOR
  , GIVING_SUMMARY.anonymous_cfy_flag
  , GIVING_SUMMARY.anonymous_pfy1_flag
  , GIVING_SUMMARY.anonymous_pfy2_flag
  , GIVING_SUMMARY.anonymous_pfy3_flag
  , GIVING_SUMMARY.anonymous_pfy4_flag
  , GIVING_SUMMARY.anonymous_pfy5_flag
  , GIVING_SUMMARY.ANONYMOUS_CFY
  , GIVING_SUMMARY.ANONYMOUS_PFY1
  , GIVING_SUMMARY.ANONYMOUS_PFY2
  , GIVING_SUMMARY.ANONYMOUS_PFY3
  , GIVING_SUMMARY.ANONYMOUS_PFY4
  , GIVING_SUMMARY.ANONYMOUS_PFY5
  , Case when CYD.id_number is not null and (GIVING_SUMMARY.anonymous_cfy_flag is not null or S.ANONYMOUS_DONOR is not null) then 'Y' End as Anonymous_cyd_cfy_flag
  , Case when CYD.id_number is not null and (GIVING_SUMMARY.anonymous_pfy1_flag is not null or S.ANONYMOUS_DONOR is not null) then  'Y' End as Anonymous_cyd_pfy1_flag
  , Case when CYD.id_number is not null and (GIVING_SUMMARY.anonymous_pfy2_flag is not null or S.ANONYMOUS_DONOR is not null) then 'Y' End as Anonymous_cyd_pfy2_flag
  , Case when CYD.id_number is not null and (GIVING_SUMMARY.anonymous_pfy3_flag is not null or S.ANONYMOUS_DONOR is not null) then 'Y' End as Anonymous_cyd_pfy3_flag
  , Case when CYD.id_number is not null and (GIVING_SUMMARY.anonymous_pfy4_flag is not null or S.ANONYMOUS_DONOR is not null) then 'Y' End as Anonymous_cyd_pfy4_flag
  , Case when CYD.id_number is not null and (GIVING_SUMMARY.anonymous_pfy5_flag is not null or S.ANONYMOUS_DONOR is not null) then 'Y' End as Anonymous_cyd_pfy5_flag
  , Case when CYD.id_number is not null and (GIVING_SUMMARY.anonymous_cfy_flag  is not null or S.ANONYMOUS_DONOR is not null) then GIVING_SUMMARY.ANONYMOUS_CFY End as Anonymous_cyd_cfy
  , Case when CYD.id_number is not null and (GIVING_SUMMARY.anonymous_pfy1_flag is not null or S.ANONYMOUS_DONOR is not null) then GIVING_SUMMARY.ANONYMOUS_PFY1 End as Anonymous_cyd_pfy1
  , Case when CYD.id_number is not null and (GIVING_SUMMARY.anonymous_pfy2_flag is not null or S.ANONYMOUS_DONOR is not null) then GIVING_SUMMARY.ANONYMOUS_PFY2 End as Anonymous_cyd_pfy2
  , Case when CYD.id_number is not null and (GIVING_SUMMARY.anonymous_pfy3_flag is not null or S.ANONYMOUS_DONOR is not null) then GIVING_SUMMARY.ANONYMOUS_PFY3 End as Anonymous_cyd_pfy3
  , Case when CYD.id_number is not null and (GIVING_SUMMARY.anonymous_pfy4_flag is not null or S.ANONYMOUS_DONOR is not null) then GIVING_SUMMARY.ANONYMOUS_PFY4 End as Anonymous_cyd_pfy4
  , Case when CYD.id_number is not null and (GIVING_SUMMARY.anonymous_pfy5_flag is not null or S.ANONYMOUS_DONOR is not null) then GIVING_SUMMARY.ANONYMOUS_PFY5 End as Anonymous_cyd_pfy5
  ,CASE WHEN CYD.ID_NUMBER IS NOT NULL THEN 'Y' END AS CYD
  ,GIVING_SUMMARY.CRU_CFY
  ,GIVING_SUMMARY.CRU_PFY1
  ,GIVING_SUMMARY.CRU_PFY2
  ,GIVING_SUMMARY.CRU_PFY3
  ,GIVING_SUMMARY.CRU_PFY4
  ,GIVING_SUMMARY.CRU_PFY5
  , case when GIVING_SUMMARY.CRU_PFY1 > 0
  or GIVING_SUMMARY.CRU_PFY2 > 0 
  or GIVING_SUMMARY.CRU_PFY3 > 0
  or GIVING_SUMMARY.CRU_PFY4 > 0
  or GIVING_SUMMARY.CRU_PFY5 > 0 then 'Giver_Last_5'
  Else '' END as Giver_Last_5_Years
  ,GIVING_SUMMARY.NU_MAX_HH_LIFETIME_GIVING
  ,S.NO_EMAIL_IND AS NO_EMAIL
  ,S.NO_EMAIL_SOL_IND AS NO_EMAIL_SOLICIT
  ,S.NO_MAIL_SOL_IND AS NO_MAIL_SOLICIT
  ,S.NO_PHONE_SOL_IND AS NO_PHONE_SOLICIT
  ,S.SPECIAL_HANDLING_CONCAT AS RESTRICTIONS
  ,S.NO_CONTACT
  ,S.EBFA as Asia_Executive_Board
  ,S.Trustee
  ,S.GAB
  ,S.NO_SOLICIT
  
  --- Need to change this when we hit FY 25

  
  --- AF WANTS TO SEE CURRENT FISCAL YEAR
  ,Case when CYD.id_number is not null AND FOUNDATION.YEAR_OF_RECORD = '2025' then FOUNDATION.REPORT_NAME END AS FOUNDATION_CYD_CFY
  ,Case when CYD.id_number is not null AND FOUNDATION.YEAR_OF_RECORD = '2025' then FOUNDATION.ASSOCIATED_DESC END AS FOUNDATION_DESC_CYD_CFY
  ,Case when CYD.id_number is not null AND FOUNDATION.YEAR_OF_RECORD = '2025' then FOUNDATION.RCPT END AS FOUNDATION_RECPT_NUM_CYD_CFY
  ,Case when CYD.id_number is not null AND FOUNDATION.YEAR_OF_RECORD = '2025' then FOUNDATION.DATE_OF_RECORD END AS FOUNDATION_DATE_GIFT_CYD_CFY
  ,Case when CYD.id_number is not null AND FOUNDATION.YEAR_OF_RECORD = '2025' THEN FOUNDATION.YEAR_OF_RECORD END AS FOUNDATION_CFY_OF_GIFT_CYD
  
  
  --- Need to change this when we hit FY 25

  
  --- AF WANTS TO SEE CURRENT FISCAL YEAR, BUT WE NEED TO ADJUST FOR WHEN CALENDAR YEAR CHANGES. SO THIS IS 2024
  ,Case when CYD.id_number is not null AND FOUNDATION.YEAR_OF_RECORD = '2024' then FOUNDATION.REPORT_NAME END AS FOUNDATION_CYD_PFY
  ,Case when CYD.id_number is not null AND FOUNDATION.YEAR_OF_RECORD = '2024' then FOUNDATION.ASSOCIATED_DESC END AS FOUNDATION_DESC_CYD_PFY
  ,Case when CYD.id_number is not null AND FOUNDATION.YEAR_OF_RECORD = '2024' then FOUNDATION.RCPT END AS FOUNDATION_RECPT_NUM_CYD_PFY
  ,Case when CYD.id_number is not null AND FOUNDATION.YEAR_OF_RECORD = '2024' then FOUNDATION.DATE_OF_RECORD END AS FOUNDATION_DATE_GIFT_CYD_PFY
  ,Case when CYD.id_number is not null AND FOUNDATION.YEAR_OF_RECORD = '2024' THEN FOUNDATION.YEAR_OF_RECORD END AS FOUNDATION_OF_GIFT_CYD_PFY
  ,assign.LGOS
  ,assign.Prospect_Manager
  ,EM.JOB_TITLE AS JOB_TITLE
  ,EM.employer_name AS EMPLOYER
  ,EM.FLD_OF_WORK AS INDUSTRY
  ,NP.EVALUATION_RATING
  ,NP.OFFICER_RATING
  ,case when v.id_number is not null then 'Y' end as Reunion_volunteer
  ,KYCC.ksm_reunion_year_concat AS CLASS_YEAR_CONCAT 
  ,VS.solicitor_name
   ,GIVING_SUMMARY.STEWARDSHIP_CFY
   ,GIVING_SUMMARY.STEWARDSHIP_PFY1
   ,GIVING_SUMMARY.STEWARDSHIP_PFY2
   ,GIVING_SUMMARY.STEWARDSHIP_PFY3
   ,GIVING_SUMMARY.STEWARDSHIP_PFY4
   ,GIVING_SUMMARY.STEWARDSHIP_PFY5
   ,GIVING_SUMMARY.AF_CFY
   ,GIVING_SUMMARY.AF_PFY1
   ,GIVING_SUMMARY.AF_PFY2
   ,GIVING_SUMMARY.AF_PFY3
   ,GIVING_SUMMARY.AF_PFY4
   ,GIVING_SUMMARY.AF_PFY5
   ,degs.pref_first_name
   ,degs.last_name
   ,degs.yrs
   ,degs.pref_mail_name
   ,hr_names.honor_roll_name
   ,hr_names.honor_roll_name_no_prefix
   ,hr_names.xcomment
   ,lr.last_reunion_event_id
   ,lr.last_reunion_event_name
   ,lr.last_reunion_start_dt
   ,case when c25.id_number is not null then '2025 Reunion Volunteer' end as Reunion_2025_volunteer
from KSM_REUNION 
left join CURRENT_DONOR CYD on CYD.id_number = KSM_REUNION.id_number
left join GIVING_SUMMARY on GIVING_SUMMARY.id_number = KSM_REUNION.id_number
left join s on s.id_number = KSM_REUNION.id_number
left join foundation on foundation.id_number = KSM_Reunion.id_number
left join assign on assign.id_number = KSM_Reunion.id_number
left join em on em.id_number = KSM_Reunion.id_number
left join np on np.id_number = KSM_Reunion.id_number
left join v on v.id_number = KSM_Reunion.id_number
Left JOIN KR_YEAR_CONCAT KYCC ON KYCC.ID_NUMBER = KSM_Reunion.id_number
left join vs on vs.id_number = KSM_Reunion.id_number
left join hr_names on hr_names.id_number = KSM_Reunion.id_number
left join anon_dw on anon_dw.household_id = KSM_Reunion.id_number
left join degs on degs.id_number = KSM_Reunion.id_number
left join last_reunion lr on lr.id_number = KSM_REUNION.id_number
left join c25 on c25.id_number = KSM_REUNION.id_number
)

SELECT DISTINCT 
   E.ID_NUMBER
  ,E.RECORD_STATUS_CODE
  ,E.GENDER_CODE
  ,E.REPORT_NAME
  ,E.pref_mail_name
  ,E.FIRST_NAME
  ,E.institutional_suffix
  ,d.P_Dean_Salut
  ,E.pers_suffix
  ,E.last_name   
  --- Attending Reunion 2024 - I will add this once registratio opens
  ,KR.CLASS_YEAR
  ,case when KR.class_year = '1975' then '50th Milestone'
  when KR.class_year = '1980' then '45th Milestone'
    when KR.class_year = '1985' then '40th Milestone'
      when KR.class_year = '1990' then '35th Milestone'
        when KR.class_year = '1995' then '30th Milestone'
          when KR.class_year = '2000' then '25th Milestone'
            when KR.class_year = '2005' then '20th Milestone'
              when KR.class_year = '2010' then '15th Milestone'
                when KR.class_year = '2015' then '10th Milestone'
                  when KR.class_year = '2020' then '5th Milestone'
                    when KR.class_year = '2024' then '1st Milestone' end as Reunion_Milestone
  ,FINAL.CLASS_YEAR_CONCAT 
  ,KR.PROGRAM AS DEGREE_PROGRAM
  ,KR.PROGRAM_GROUP
  ,KR.CLASS_SECTION AS COHORT
  ,CASE WHEN RP15.ID_NUMBER IS NOT NULL THEN 'Y' END AS ATTENDED_REUNION_2015
  ,CASE WHEN RP22.ID_NUMBER IS NOT NULL THEN 'Y' END AS ATTENDED_REUNION_2022
  ,final.last_reunion_event_id
  ,final.last_reunion_event_name
  ,final.last_reunion_start_dt
  ,pfin.Address_Type
  ,pfin.care_of
  ,pfin.Business_Name
  ,pfin.Business_Name_2
  ,pfin.business_title
  ,pfin.Street1
  ,pfin.Street2
  ,pfin.Street3 
  ,pfin.City  
  ,pfin.State_code
  ,pfin.Zipcode
  ,pfin.Country
  ,KR.HOUSEHOLD_GEO_CODES
  ,KR.SPOUSE_ID_NUMBER
  ,KR.SPOUSE_PREF_MAIL_NAME
  ,D.Spouse_Dean_Salut
  ,KR.SPOUSE_SUFFIX
  ,KR.SPOUSE_FIRST_KSM_YEAR
  ,KR.SPOUSE_PROGRAM
  ,KR.SPOUSE_PROGRAM_GROUP
  ,KR.CLASS_SECTION
  ,CASE WHEN spouse_RY.SPOUSE_ID_NUMBER is not null then spouse_RY.CLASS_YEAR else '' End as Spouse_Reunion24_Classyr_IND
  ,final.LGOS
  ,final.Prospect_Manager
  --- CYD Flag 
  ,final.CYD
  --- AF WANTS TO SEE CURRENT FISCAL YEAR
  ,FINAL.FOUNDATION_CYD_CFY AS FOUNDATION_CYD_FY25
  ,FINAL.FOUNDATION_DESC_CYD_CFY AS FOUNDATION_DESC_CYD_FY25
  ,FINAL.FOUNDATION_RECPT_NUM_CYD_CFY AS FOUNDATION_RECPT_NUM_CYD_FY25
  ,FINAL.FOUNDATION_DATE_GIFT_CYD_CFY AS FOUNDATION_DATE_GIFT_CYD_FY25
  ,nvl(FINAL.FOUNDATION_CFY_OF_GIFT_CYD,'0') AS FOUNDATION_OF_GIFT_CYD_FY25
  --- AF WANTS TO SEE CURRENT FISCAL YEAR, BUT WE NEED TO ADJUST FOR WHEN CALENDAR YEAR CHANGES. SO THIS IS 2023
  ,FINAL.FOUNDATION_CYD_PFY AS FOUNDATION_CYD_FY24
  ,FINAL.FOUNDATION_DESC_CYD_PFY AS FOUNDATION_DESC_CYD_FY24
  ,FINAL.FOUNDATION_RECPT_NUM_CYD_PFY AS FOUNDATION_RECPT_NUM_CYD_FY24
  ,trunc (FINAL.FOUNDATION_DATE_GIFT_CYD_PFY) AS FOUNDATION_DATE_GIFT_CYD_FY24
  ,nvl(FINAL.FOUNDATION_OF_GIFT_CYD_PFY,'0') AS FOUNDATION_OF_GIFT_CYD_FY24
  ,FINAL.Reunion_volunteer
  ,FINAL.solicitor_name as volunteer_solicitor
  ,CASE WHEN RC20.ID_NUMBER IS NOT NULL THEN 'Y' ELSE '' END AS "REUNION_2020_COMMITTEE"
  ,CASE WHEN PRC.ID_NUMBER IS NOT NULL THEN 'Y'  ELSE ''END AS "REUNION_2015_COMMITTEE"
  ,KCL.CLUB_TITLE AS CLUB_LEADERSHIP_CLUB
  ,KCL.Leadership_Title AS CLUB_LEADER
  ,final.GAB as GAB
  ,final.TRUSTEE
  ,final.ASIA_EXECUTIVE_BOARD
  ,KAC.SHORT_DESC AS KAC
  ,PHS.SHORT_DESC AS PHS
  ,Case when phs.spouse_ID_Number is not null then KR.SPOUSE_PREF_MAIL_NAME End as PHS_Spouse
  ,final.NO_EMAIL
  ,final.NO_EMAIL_SOLICIT
  ,final.NO_MAIL_SOLICIT
  ,final.NO_PHONE_SOLICIT
  ,final.RESTRICTIONS
  ,final.NO_CONTACT
  ,final.NO_SOLICIT
  ,final.JOB_TITLE
  ,final.EMPLOYER
  ,final.INDUSTRY
  --- Update: Team is okay with just NU Staff, BUT I do get requests to exclude KSM staff that alumni. Take off Tableau instead.  
  ,CASE WHEN KFS.ID_NUMBER IS NOT NULL THEN 'KSM Faculty/Staff' end as KSM_faculty_staff_ind
  ,CASE WHEN NFS.ID_NUMBER IS NOT NULL THEN 'NU Faculty/Staff' end as NU_faculty_staff_ind
  ,CASE WHEN NFS.ID_NUMBER IS NOT NULL THEN NFS.affilation_code end as NU_faculty_staff_school_ind
  ,nvl(final.CRU_CFY,'0')CRU_CFY
  ,nvl(final.CRU_PFY1,'0')CRU_PFY1
  ,nvl(final.CRU_PFY2,'0')CRU_PFY2
  ,nvl(final.CRU_PFY3,'0')CRU_PFY3
  ,nvl(final.CRU_PFY4,'0')CRU_PFY4
  ,nvl(final.CRU_PFY5,'0')CRU_PFY5
  , case when final.CRU_PFY1 > 0
  or final.CRU_PFY2 > 0 
  or final.CRU_PFY3 > 0
  or final.CRU_PFY4 > 0
  or final.CRU_PFY5 > 0 then 'Giver_Last_5'
  Else '' END as Giver_Last_5_Years
  ---,nvl(final.modified_hh_gift_count_cfy,'0')modified_hh_gift_count_cfy
  ---,nvl(final.modified_hh_gift_credit_pfy5,'0')modified_hh_gift_credit_pfy5
 --- ,nvl(final.pledge_modified_cfy,'0')pledge_modified_cfy
  ---,nvl(final.pledge_modified_pfy5,'0')pledge_modified_pfy5
  ,trunc (PR.last_plg_dt) AS PLG_DATE
  ,PR.TRANSACTION_TYPE AS Pledge_Transaction_Type
  ,PR.pacct1 AS PLG_ALLOC
  ,nvl(PR.pamt1,'0') AS PLG_AMT
  ,nvl(PR.bal1, '0') AS PLG_BALANCE
  ,PR.status1 AS PLG_STATUS
  --- recent pledge fiscal year
  ,rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(GI.GDT1) AS RECENT_PLEDGE_FISCAL_YEAR
  ,trunc (GI.GDT1) AS DATE1
  ,nvl(GI.GAMT1,'0') AS AMOUNT1
  ,GI.GACCT1 AS ACC1
  ,nvl(GI.MATCH1, '0') AS MATCH_AMOUNT1
  ,nvl(GI.CLAIM1, '0') AS CLAIM_AMOUNT1
  ,GI.ASSOCIATED_CODE1
  ,GI.ASSOCIATED_DESC1
  ,trunc (GI.GDT2) AS DATE2
  ,nvl(GI.GAMT2, '0') AS AMOUNT2
  ,GI.GACCT2 AS ACC2
  ,nvl(GI.MATCH2, '0') AS MATCH_AMOUNT2
  ,nvl(GI.CLAIM2, '0') AS CLAIM_AMOUNT2
  ,GI.ASSOCIATED_CODE2
  ,GI.ASSOCIATED_DESC2
  ,trunc (GI.GDT3) AS DATE3
  ,nvl(GI.GAMT3, '0') AS AMOUNT3
  ,GI.GACCT3 AS ACC3
  ,nvl(GI.MATCH3, '0') AS MATCH_AMOUNT3
  ,nvl(GI.CLAIM3, '0') AS CLAIM_AMOUNT3
  ,GI.ASSOCIATED_CODE3
  ,GI.ASSOCIATED_DESC3
  ,trunc (GI.GDT4) AS DATE4
---  ,nvl(GI.MATCH4, '0') AS MATCH_AMOUNT4
--  ,nvl(GI.GAMT4, '0') AS AMOUNT4
  ,GI.GACCT4 AS ACC4
  ,nvl(GI.MATCH4, '0') AS MATCH_AMOUNT4
  ,nvl(GI.CLAIM4, '0') AS CLAIM_AMOUNT4
  ,GI.ASSOCIATED_CODE4
  ,GI.ASSOCIATED_DESC4
  ,Final.anonymous_cfy_flag
  ,Final.anonymous_pfy1_flag
  ,Final.anonymous_pfy2_flag
  ,Final.anonymous_pfy3_flag
  ,Final.anonymous_pfy4_flag
  ,Final.anonymous_pfy5_flag
  ,nvl(Final.ANONYMOUS_CFY,'0')ANONYMOUS_CFY
  ,nvl(Final.ANONYMOUS_PFY1,'0')ANONYMOUS_PFY1
  ,nvl(Final.ANONYMOUS_PFY2,'0')ANONYMOUS_PFY2
  ,nvl(Final.ANONYMOUS_PFY3,'0')ANONYMOUS_PFY3
  ,nvl(Final.ANONYMOUS_PFY4,'0')ANONYMOUS_PFY4
  ,nvl(Final.ANONYMOUS_PFY5,'0')ANONYMOUS_PFY5
  , final.Anonymous_cyd_cfy_flag
  , final.Anonymous_cyd_pfy1_flag
  , final.Anonymous_cyd_pfy2_flag
  , final.Anonymous_cyd_pfy3_flag
  , final.Anonymous_cyd_pfy4_flag
  , final.Anonymous_cyd_pfy5_flag 
  ,nvl(final.Anonymous_cyd_CFY,'0')Anonymous_cyd_CFY
  ,nvl(final.Anonymous_cyd_pfy1,'0')Anonymous_cyd_pfy1
  ,nvl(final.Anonymous_cyd_pfy2,'0')Anonymous_cyd_pfy2
  ,nvl(final.Anonymous_cyd_pfy3,'0')Anonymous_cyd_pfy3
  ,nvl(final.Anonymous_cyd_pfy4,'0')Anonymous_cyd_pfy4
  ,nvl(final.Anonymous_cyd_pfy5,'0')Anonymous_cyd_pfy5
  ,nvl(KTF.KSM_TOTAL, '0')KSM_Total
  ,nvl(KTF.KSM_AF_TOTAL, '0')KSM_AF_TOTAL
  ,nvl(KTF.KSM_TOTAL24, '0')KSM_TOTAL24
  ,nvl(KTF.KSM_TOTAL25, '0')KSM_TOTAL25
  ,CASE WHEN KTF.KM24_ID_NUMBER IS NOT NULL THEN 'Y' END AS MATCH_2024
  ,nvl(final.NU_MAX_HH_LIFETIME_GIVING, '0')NU_MAX_HH_LIFETIME_GIVNG
  ,FINAL.EVALUATION_RATING
  ,FINAL.OFFICER_RATING
  ,WT0_PARSE(PROPOSAL_STATUS, 1,  '^') PROPOSAL_STATUS
  ,WT0_PARSE(PROPOSAL_STATUS, 2,  '^') PROPOSAL_START_DATE
  ,WT0_PARSE(PROPOSAL_STATUS, 3,  '^') PROPOSAL_ASK_AMT
  ,WT0_PARSE(PROPOSAL_STATUS, 4,  '^') ANTICIPATED_AMT
  ,WT0_PARSE(PROPOSAL_STATUS, 5,  '^') GRANTED_AMT
  ,WT0_PARSE(PROPOSAL_STATUS, 6,  '^') STOP_DATE
  ,WT0_PARSE(PROPOSAL_STATUS, 7,  '^') PROPOSAL_TITLE
  ,AFS.AF_10K_MODEL_TIER 
  ,MD.ID_CODE
  ,MD.id_segment
  ,MD.id_score
  ,MD.pr_code
  ,MD.pr_segment
  ,MD.pr_score
  ,MD.est_probability
  ,C.credited
  ,C.contact_purpose
  ,C.credited_name
  ,C.contacted_name
  ,C.contact_type
  ,trunc (C.contact_Date) as contact_date
  ,C.description_
  ,C.summary_
  --- Honor role data -Stewardship, AF, CRU (Had in org code), Anon Donor
  ,Final.ANONYMOUS_DONOR
,nvl(final.STEWARDSHIP_CFY,'0')STEWARDSHIP_CFY
,nvl(final.STEWARDSHIP_PFY1,'0')STEWARDSHIP_PFY1
,nvl(final.STEWARDSHIP_PFY2,'0')STEWARDSHIP_PFY2
,nvl(final.STEWARDSHIP_PFY3,'0')STEWARDSHIP_PFY3
,nvl(final.STEWARDSHIP_PFY4,'0')STEWARDSHIP_PFY4
,nvl(final.STEWARDSHIP_PFY5,'0')STEWARDSHIP_PFY5
,nvl(final.AF_CFY,'0')AF_CFY
,nvl(final.AF_PFY1,'0')AF_PFY1
,nvl(final.AF_PFY2,'0')AF_PFY2
,nvl(final.AF_PFY3,'0')AF_PFY3
,nvl(final.AF_PFY4,'0')AF_PFY4
,nvl(final.AF_PFY5,'0')AF_PFY5

 --- Nametags for Honor Role (Honor Role from CATracks, Name Tag Names, Give Andy all options)
  ,final.honor_roll_name
  ,final.honor_roll_name_no_prefix
  ,final.xcomment as honor_role_name_xcomment
  ,final.pref_mail_name as name_tag_pref_name
  ,final.pref_first_name as name_tag_first_name
  ,final.last_name as name_tag_last_name
  ,final.yrs as name_tag_yrs
  ,final.Reunion_2025_volunteer

FROM ENTITY E
INNER JOIN KSM_REUNION KR
ON E.ID_NUMBER = KR.ID_NUMBER
Left Join final
ON final.id_number = E.id_number
LEFT JOIN pfin  
 ON pfin.id_number = e.id_number
LEFT JOIN KSM_Total_Final KTF
ON E.ID_NUMBER = KTF.ID_NUMBER 
LEFT JOIN KSM_GIVING_MOD KGM
ON KGM.household_id = KR.HOUSEHOLD_ID
LEFT JOIN PROPOSALS PROP
ON E.ID_NUMBER = PROP.ID_NUMBER
LEFT JOIN AF_SCORES AFS
ON E.ID_NUMBER = AFS.ID_NUMBER
LEFT JOIN REUNION_2022_PARTICIPANTS RP22
ON E.ID_NUMBER = RP22.ID_NUMBER
LEFT JOIN REUNION_2015_PARTICIPANTS RP15
ON E.ID_NUMBER = RP15.ID_NUMBER
LEFT JOIN KSM_CLUB_LEADERS KCL
ON E.ID_NUMBER = KCL.ID_NUMBER
LEFT JOIN PLEDGE_ROWS PR
 ON E.ID_NUMBER = PR.ID
LEFT JOIN GIFTINFO GI
  ON E.ID_NUMBER = GI.ID_NUMBER
LEFT JOIN REUNION_15_COMMITTEE  PRC
ON E.ID_NUMBER = PRC.ID_NUMBER 
LEFT JOIN REUNION_20_COMMITTEE RC20
 ON RC20.ID_NUMBER = E.ID_NUMBER
Left Join spouse_RY
on spouse_RY.SPOUSE_ID_NUMBER = KR.SPOUSE_ID_NUMBER
LEFT JOIN DEAN d
on d.id_number = e.id_number
LEFT JOIN phs 
ON PHS.ID_NUMBER = E.ID_NUMBER
LEFT JOIN KAC
ON KAC.ID_NUMBER = E.ID_NUMBER
Left Join KSM_Faculty_Staff KFS
ON KFS.ID_NUMBER = E.ID_NUMBER
Left Join NU_Faculty_Staff NFS
ON NFS.ID_NUMBER = E.ID_NUMBER
LEFT JOIN MD
ON MD.ID_NUMBER = E.ID_NUMBER
LEFT JOIN C 
ON C.ID_NUMBER = E.ID_NUMBER