With manual_dates As (
Select
  2023 AS pfy
  ,2024 AS cfy
  From DUAL
)

,HOUSE AS (SELECT *
FROM rpt_pbh634.v_entity_ksm_households_fast H)

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
--- Let's have the geocode 100% tied to the primary address 
,GC.P_GEOCODE_Desc
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
FROM AFFILIATION A
CROSS JOIN manual_dates MD
Inner JOIN house ON House.ID_NUMBER = A.ID_NUMBER
Inner Join KSM_DEGREES d on d.id_number = a.id_number
LEFT JOIN RPT_DGZ654.V_GEO_CODE GC
ON A.ID_NUMBER = GC.ID_NUMBER
AND GC.ADDR_PREF_IND = 'Y'
AND GC.GEO_STATUS_CODE = 'A'
WHERE (TO_NUMBER(NVL(TRIM(A.CLASS_YEAR),'1')) IN (MD.CFY-1, MD.CFY-5, MD.CFY-10, MD.CFY-15, MD.CFY-20, MD.CFY-25, MD.CFY-30, MD.CFY-35, MD.CFY-40,
  MD.CFY-45, MD.CFY-50, MD.CFY-51, MD.CFY-52, MD.CFY-53, MD.CFY-54, MD.CFY-55, MD.CFY-56, MD.CFY-57, MD.CFY-58, MD.CFY-59, MD.CFY-60)
AND A.AFFIL_CODE = 'KM'
AND A.AFFIL_LEVEL_CODE = 'RG'))

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

,REUNION_19_COMMITTEE AS (
  SELECT DISTINCT
   ID_NUMBER
  FROM COMMITTEE
  WHERE COMMITTEE_CODE = '227' AND COMMITTEE_STATUS_CODE = 'F'
  AND START_DT = '20180901'
)

,REUNION_14_COMMITTEE AS (
  SELECT DISTINCT
   ID_NUMBER
  FROM COMMITTEE
  WHERE COMMITTEE_CODE = '227' AND COMMITTEE_STATUS_CODE = 'F'
  AND START_DT = '20130901'
)

,CURRENT_DONOR AS (
  SELECT DISTINCT HH.ID_NUMBER
FROM GIVING_TRANS HH
cross join rpt_pbh634.v_current_calendar cal
WHERE HH.FISCAL_YEAR = cal.CURR_FY
 AND HH.TX_GYPM_IND NOT IN ('P', 'M')
)

,REUNION_2014_PARTICIPANTS AS (
Select ep_participant.id_number,
ep_event.event_id
From ep_event
Left Join EP_Participant
ON ep_participant.event_id = ep_event.event_id
where ep_event.event_id = '9760'
)

,REUNION_2019_PARTICIPANTS AS (
Select ep_participant.id_number,
ep_event.event_id
From ep_event
Left Join EP_Participant
ON ep_participant.event_id = ep_event.event_id
where ep_event.event_id = '21120'
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
                 max(decode(rw,1,PLG_ACTIVE)) plgActive

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
     ,max(decode(RW,2,rcpt)) rcpt2
     ,max(decode(RW,2,dt)) gdt2
     ,max(decode(RW,2,amt))     gamt2
     ,max(decode(RW,2,match))   match2
     ,max(decode(RW,2,claim)) claim2
     ,max(decode(RW,2,acct))   gacct2
     ,max(decode(RW,3,rcpt)) rcpt3
     ,max(decode(RW,3,dt)) gdt3
     ,max(decode(RW,3,amt))     gamt3
     ,max(decode(RW,3,match))   match3
     ,max(decode(RW,3,claim)) claim3
     ,max(decode(RW,3,acct))   gacct3
     ,max(decode(RW,4,rcpt)) rcpt4
     ,max(decode(RW,4,dt)) gdt4
     ,max(decode(RW,4,amt))     gamt4
     ,max(decode(RW,4,match))   match4
     ,max(decode(RW,4,claim)) claim4
     ,max(decode(RW,4,acct))   gacct4
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

,KSM_TOTAL23 AS (
  SELECT
  GT.ID_NUMBER
  ,SUM(GT.CREDIT_AMOUNT) AS KSM_TOTAL
 FROM GIVING_TRANS GT
 CROSS JOIN MANUAL_DATES MD
 WHERE GT.TX_GYPM_IND NOT IN ('P','M')
   AND GT.FISCAL_YEAR = MD.PFY
 GROUP BY GT.ID_NUMBER
)

,KSM_MATCH_23 AS (
   SELECT DISTINCT
     GT.ID_NUMBER
   FROM GIVING_TRANS GT
   CROSS JOIN MANUAL_DATES MD
   WHERE GT.TX_GYPM_IND = 'M'
     AND GT.MATCHED_FISCAL_YEAR = MD.PFY
 )
 
,KSM_Total_Final as (
Select HOUSE.id_number
  ,KSMT.KSM_TOTAL
  ,KAFT.KSM_AF_TOTAL
  ,KSM_TOTAL23.KSM_TOTAL AS KSM_TOTAL23
  ,KSM_MATCH_23.ID_NUMBER AS KM23_ID_NUMBER
from HOUSE
LEFT JOIN KSM_TOTAL KSMT ON HOUSE.ID_NUMBER = KSMT.ID_NUMBER
LEFT JOIN KSM_AF_TOTAL KAFT ON HOUSE.ID_NUMBER = KAFT.ID_NUMBER
LEFT JOIN KSM_TOTAL23  ON HOUSE.ID_NUMBER = KSM_TOTAL23.ID_NUMBER
LEFT JOIN KSM_MATCH_23 ON HOUSE.ID_NUMBER = KSM_MATCH_23.ID_NUMBER)
 

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
  ,Case When P.ADDRESS_TYPE = 'Business' Then P.Street3 else P.Street2 End Street3 
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
       rpt_zrc8929.v_dean_salutation.P_Dean_Source
From rpt_zrc8929.v_dean_salutation),


KAC AS (select k.id_number,
       k.committee_code,
       k.short_desc,
       k.status
From table (rpt_pbh634.ksm_pkg_tmp.tbl_committee_kac) k),

PHS AS (Select p.id_number,
       p.short_desc,
       p.status
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

--- KSM/NU Staff Flag


KSM_Faculty_Staff  as (select aff.id_number,
       TMS_AFFIL_CODE.short_desc as affilation_code,
       tms_affiliation_level.short_desc as affilation_level
FROM  affiliation aff
LEFT JOIN TMS_AFFIL_CODE ON TMS_AFFIL_CODE.affil_code = aff.affil_code
Left JOIN tms_affiliation_level ON tms_affiliation_level.affil_level_code = aff.affil_level_code
 WHERE  aff.affil_code = 'KM'
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

FOUNDATION AS (SELECT
           GIVING_TRANS_DAF.ID_NUMBER,
max (ENTITY.REPORT_NAME) keep (dense_rank First Order By DATE_OF_RECORD DESC) as REPORT_NAME,           
max (associated_desc) keep (dense_rank First Order By DATE_OF_RECORD DESC) as associated_desc,
max (DATE_OF_RECORD) keep (dense_rank First Order By DATE_OF_RECORD DESC) as DATE_OF_RECORD,
max (TX_NUMBER) keep (dense_rank First Order By DATE_OF_RECORD DESC) as rcpt
          FROM GIVING_TRANS_DAF
          LEFT JOIN GIFT
          ON GIVING_TRANS_DAF.TX_NUMBER = GIFT.GIFT_RECEIPT_NUMBER
            --AND GIFT.GIFT_SEQUENCE = 1
          INNER JOIN ENTITY
          ON GIFT.GIFT_DONOR_ID = ENTITY.ID_NUMBER
          WHERE TX_GYPM_IND <> 'P'  AND GIFT.GIFT_SEQUENCE = 1
          GROUP BY GIVING_TRANS_DAF.ID_NUMBER),
          
--- Prospect as a Subquery (instead of left join and taking out another of Bill's Functions)

NP as (select TP.ID_NUMBER,
       TP.EVALUATION_RATING,
       TP.OFFICER_RATING
From nu_prs_trp_prospect TP),


final as (select  KSM_REUNION.id_number
  , S.ANONYMOUS_DONOR
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
  ,Case when CYD.id_number is not null then FOUNDATION.REPORT_NAME END AS FOUNDATION_CYD
  ,Case when CYD.id_number is not null then FOUNDATION.ASSOCIATED_DESC END AS FOUNDATION_DESC_CYD
  ,Case when CYD.id_number is not null then FOUNDATION.RCPT END AS FOUNDATION_RECPT_NUM_CYD
  ,Case when CYD.id_number is not null then FOUNDATION.DATE_OF_RECORD END AS FOUNDATION_DATE_OF_GIFT_CYD
  ,assign.LGOS
  ,assign.Prospect_Manager
  ,EM.JOB_TITLE AS JOB_TITLE
  ,EM.employer_name AS EMPLOYER
  ,EM.FLD_OF_WORK AS INDUSTRY
  ,NP.EVALUATION_RATING
  ,NP.OFFICER_RATING
from KSM_REUNION 
left join CURRENT_DONOR CYD on CYD.id_number = KSM_REUNION.id_number
left join GIVING_SUMMARY on GIVING_SUMMARY.id_number = KSM_REUNION.id_number
left join s on s.id_number = KSM_REUNION.id_number
left join foundation on foundation.id_number = KSM_Reunion.id_number
left join assign on assign.id_number = KSM_Reunion.id_number
left join em on em.id_number = KSM_Reunion.id_number
left join np on np.id_number = KSM_Reunion.id_number)

SELECT
   E.ID_NUMBER
  ,E.RECORD_STATUS_CODE
  ,E.GENDER_CODE
  ,E.REPORT_NAME
  ,E.pref_mail_name
  ,E.FIRST_NAME
  ,d.P_Dean_Salut
  ,E.last_name   
  --- Attending Reunion 2024 - I will add this once registratio opens
  ,KR.CLASS_YEAR
  ,KR.PROGRAM AS DEGREE_PROGRAM
  ,KR.PROGRAM_GROUP
  ,KR.CLASS_SECTION AS COHORT
  ,CASE WHEN RP19.ID_NUMBER IS NOT NULL THEN 'Y' END AS "ATTENDED_REUNION_2019"
  ,CASE WHEN RP14.ID_NUMBER IS NOT NULL THEN 'Y' END AS "ATTENDED_REUNION_2014"
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
  ,KR.P_GEOCODE_Desc
  ,KR.SPOUSE_ID_NUMBER
  ,KR.SPOUSE_PREF_MAIL_NAME
  ,KR.SPOUSE_SUFFIX
  ,KR.SPOUSE_FIRST_KSM_YEAR
  ,KR.SPOUSE_PROGRAM
  ,KR.SPOUSE_PROGRAM_GROUP
  ,CASE WHEN spouse_RY.SPOUSE_ID_NUMBER is not null then spouse_RY.CLASS_YEAR else '' End as Spouse_Reunion24_Classyr_IND
  ,final.LGOS
  ,final.Prospect_Manager
  ,final.CYD
  ,final.FOUNDATION_CYD
  ,final.FOUNDATION_DESC_CYD
  ,final.FOUNDATION_RECPT_NUM_CYD
  ,final.FOUNDATION_DATE_OF_GIFT_CYD
  ,CASE WHEN RC19.ID_NUMBER IS NOT NULL THEN 'Y' ELSE '' END AS "REUNION_2019_COMMITTEE"
  ,CASE WHEN PRC.ID_NUMBER IS NOT NULL THEN 'Y'  ELSE ''END AS "REUNION_2014_COMMITTEE"
  ,KCL.CLUB_TITLE AS CLUB_LEADERSHIP_CLUB
  ,KCL.Leadership_Title AS CLUB_LEADER
  ,final.GAB as GAB
  ,final.TRUSTEE
  ,final.ASIA_EXECUTIVE_BOARD
  ,KAC.SHORT_DESC AS KAC
  ,PHS.SHORT_DESC AS PHS
  ,final.NO_EMAIL
  ,final.NO_EMAIL_SOLICIT
  ,final.NO_MAIL_SOLICIT
  ,final.NO_PHONE_SOLICIT
  ,final.RESTRICTIONS
  ,final.NO_CONTACT
  ,final.JOB_TITLE
  ,final.EMPLOYER
  ,final.INDUSTRY
  ,CASE WHEN KFS.ID_NUMBER IS NOT NULL THEN 'NU Faculty/Staff' end as NU_faculty_staff_ind
  ,case when KFS.id_number is not null then KFS.affilation_level End as NU_Faculty_Staff_IND
  ,final.CRU_CFY
  ,final.CRU_PFY1
  ,final.CRU_PFY2
  ,final.CRU_PFY3
  ,final.CRU_PFY4
  ,final.CRU_PFY5
  , case when final.CRU_PFY1 > 0
  or final.CRU_PFY2 > 0 
  or final.CRU_PFY3 > 0
  or final.CRU_PFY4 > 0
  or final.CRU_PFY5 > 0 then 'Giver_Last_5'
  Else '' END as Giver_Last_5_Years
  ,KGM.modified_hh_gift_count_cfy
  ,KGM.modified_hh_gift_credit_pfy5
  ,KGM.pledge_modified_cfy
  ,KGM.pledge_modified_pfy5
  ,PR.last_plg_dt AS PLG_DATE
  ,PR.pacct1 AS PLG_ALLOC
  ,PR.pamt1 AS PLG_AMT
  ,PR.bal1 AS PLG_BALANCE
  ,PR.status1 AS PLG_STATUS
  ,rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(GI.GDT1) AS RECENT_FISAL_YEAR
  ,GI.GDT1 AS DATE1
  ,GI.GAMT1 AS AMOUNT1
  ,GI.GACCT1 AS ACC1
  ,GI.MATCH1 AS MATCH_AMOUNT1
  ,GI.CLAIM1 AS CLAIM_AMOUNT1
  ,GI.GDT2 AS DATE2
  ,GI.GAMT2 AS AMOUNT2
  ,GI.GACCT2 AS ACC2
  ,GI.MATCH2 AS MATCH_AMOUNT2
  ,GI.CLAIM2 AS CLAIM_AMOUNT2
  ,GI.GDT3 AS DATE3
  ,GI.GAMT3 AS AMOUNT3
  ,GI.GACCT3 AS ACC3
  ,GI.MATCH3 AS MATCH_AMOUNT3
  ,GI.CLAIM3 AS CLAIM_AMOUNT3
  ,GI.GDT4 AS DATE4
  ,GI.GAMT4 AS AMOUNT4
  ,GI.GACCT4 AS ACC4
  ,GI.MATCH4 AS MATCH_AMOUNT4
  ,GI.CLAIM4 AS CLAIM_AMOUNT4
  ,Final.ANONYMOUS_DONOR
  , final.Anonymous_cyd_cfy_flag
  , final.Anonymous_cyd_pfy1_flag
  , final.Anonymous_cyd_pfy2_flag
  , final.Anonymous_cyd_pfy3_flag
  , final.Anonymous_cyd_pfy4_flag
  , final.Anonymous_cyd_pfy5_flag
  , final.Anonymous_cyd_CFY
  , final.Anonymous_cyd_pfy1
  , final.Anonymous_cyd_pfy2
  , final.Anonymous_cyd_pfy3
  , final.Anonymous_cyd_pfy4
  , final.Anonymous_cyd_pfy5
  ,KTF.KSM_TOTAL
  ,KTF.KSM_AF_TOTAL
  ,KTF.KSM_TOTAL23
  ,CASE WHEN KTF.KM23_ID_NUMBER IS NOT NULL THEN 'Y' END AS MATCH_2023
  ,final.NU_MAX_HH_LIFETIME_GIVING
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
LEFT JOIN REUNION_2019_PARTICIPANTS RP19
ON E.ID_NUMBER = RP19.ID_NUMBER
LEFT JOIN REUNION_2014_PARTICIPANTS RP14
ON E.ID_NUMBER = RP14.ID_NUMBER
LEFT JOIN KSM_CLUB_LEADERS KCL
ON E.ID_NUMBER = KCL.ID_NUMBER
LEFT JOIN PLEDGE_ROWS PR
 ON E.ID_NUMBER = PR.ID
LEFT JOIN GIFTINFO GI
  ON E.ID_NUMBER = GI.ID_NUMBER
LEFT JOIN REUNION_14_COMMITTEE  PRC
ON E.ID_NUMBER = PRC.ID_NUMBER 
LEFT JOIN REUNION_19_COMMITTEE RC19
 ON RC19.ID_NUMBER = E.ID_NUMBER
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