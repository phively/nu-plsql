With manual_dates As (
Select
  2020 AS pfy
  ,2021 AS cfy
  From DUAL
),

KSM_DEGREES AS (
 SELECT
   KD.ID_NUMBER
   ,KD.PROGRAM
   ,KD.PROGRAM_GROUP
   ,KD."CLASS_SECTION"
 FROM RPT_PBH634.V_ENTITY_KSM_DEGREES KD
 WHERE KD."PROGRAM" IN ('EMP', 'EMP-FL', 'EMP-IL', 'EMP-CAN', 'EMP-GER', 'EMP-HK', 'EMP-ISR', 'EMP-JAN', 'EMP-CHI', 'FT', 'FT-1Y', 'FT-2Y', 'FT-CB', 'FT-EB', 'FT-JDMBA', 'FT-MMGT', 'FT-MMM', 'TMP', 'TMP-SAT',
'TMP-SATXCEL', 'TMP-XCEL')
)

,KSM_REUNION AS (
SELECT
A.*
,GC.P_GEOCODE_Desc
FROM AFFILIATION A
CROSS JOIN manual_dates MD
INNER JOIN KSM_DEGREES KD
ON A.ID_NUMBER = KD."ID_NUMBER"
LEFT JOIN RPT_DGZ654.V_GEO_CODE GC
  ON A.ID_NUMBER = GC.ID_NUMBER
    AND GC.ADDR_PREF_IND = 'Y'
     AND GC.GEO_STATUS_CODE = 'A'
WHERE TO_NUMBER(NVL(TRIM(A.CLASS_YEAR),'1')) IN (MD.CFY-1, MD.CFY-5, MD.CFY-10, MD.CFY-15, MD.CFY-20, MD.CFY-25, MD.CFY-30, MD.CFY-35, MD.CFY-40,
  MD.CFY-45, MD.CFY-50, MD.CFY-51, MD.CFY-52, MD.CFY-53, MD.CFY-54, MD.CFY-55, MD.CFY-56, MD.CFY-57, MD.CFY-58, MD.CFY-59, MD.CFY-60)
AND A.AFFIL_CODE = 'KM'
AND A.AFFIL_LEVEL_CODE = 'RG'
),

GIVING_SUMMARY AS (
Select Distinct hh.id_number
    , hh.household_id
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year     And cru_flag = 'Y' Then hh_credit Else 0 End) As cru_cfy
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 1 And cru_flag = 'Y' Then hh_credit Else 0 End) As cru_pfy1
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 2 And cru_flag = 'Y' Then hh_credit Else 0 End) As cru_pfy2
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 3 And cru_flag = 'Y' Then hh_credit Else 0 End) As cru_pfy3
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 4 And cru_flag = 'Y' Then hh_credit Else 0 End) As cru_pfy4
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 5 And cru_flag = 'Y' Then hh_credit Else 0 End) As cru_pfy5
From rpt_pbh634.v_entity_ksm_households hh
  Cross Join rpt_pbh634.v_current_calendar cal
  Inner Join rpt_pbh634.v_ksm_giving_trans_hh gfts
    On gfts.household_id = hh.household_id
  Group By
    hh.id_number
    , hh.household_id
    , hh.household_rpt_name
    , hh.household_spouse_id
    , hh.household_spouse
    , hh.household_last_masters_year),

GIVING_TRANS AS
( SELECT HH.*
  FROM rpt_pbh634.v_ksm_giving_trans_hh HH
  INNER JOIN KSM_REUNION KR
  ON HH."ID_NUMBER" = KR.ID_NUMBER
),

KSM_GIVING_MOD as (select *
from v_ksm_reunion_giving_mod)

,SPOUSE_KSM AS (
SELECT
  E.ID_NUMBER
FROM ENTITY E
INNER JOIN KSM_DEGREES KD
ON E.ID_NUMBER = KD."ID_NUMBER"
)

,ASK3 AS (
 SELECT
   ID_NUMBER
   ,ASK3_ROUNDED
 FROM RPT_ABM1914.Reunion2020Ask
)

,REUNION_COMMITTEE AS (
 SELECT DISTINCT
    ID_NUMBER
 FROM COMMITTEE
 WHERE COMMITTEE_CODE = '227' AND COMMITTEE_STATUS_CODE = 'C'
)

,REUNION_15_COMMITTEE AS (
  SELECT DISTINCT
   ID_NUMBER
  FROM COMMITTEE
  WHERE COMMITTEE_CODE = '227' AND COMMITTEE_STATUS_CODE = 'F'
  AND START_DT = '20140901'
)


,REUNION_16_COMMITTEE AS (
  SELECT DISTINCT
   ID_NUMBER
  FROM COMMITTEE
  WHERE COMMITTEE_CODE = '227' AND COMMITTEE_STATUS_CODE = 'F'
  AND START_DT = '20150901'
)

,REUNION_20_COMMITTEE AS (
  SELECT DISTINCT
   ID_NUMBER
  FROM COMMITTEE
  WHERE COMMITTEE_CODE = '227' AND COMMITTEE_STATUS_CODE = 'F'
  AND START_DT = '20190901'
)

,REUNION_21_COMMITTEE AS (
  SELECT DISTINCT
   ID_NUMBER
  FROM COMMITTEE
  WHERE COMMITTEE_CODE = '227' AND COMMITTEE_STATUS_CODE = 'C'
  AND START_DT = '20200901'
)

,PAST_REUNION_COMMITTEE AS (SELECT DISTINCT
   ID_NUMBER
  FROM COMMITTEE
  WHERE COMMITTEE_CODE = '227' AND COMMITTEE_STATUS_CODE = 'F')


/*,CURRENT_DONOR AS (
 SELECT
   ID_NUMBER
 FROM RPT_ABM1914.T_CYD_REUNION
)*/

,CURRENT_DONOR AS (
  SELECT DISTINCT HH.ID_NUMBER
FROM GIVING_TRANS HH
WHERE HH.FISCAL_YEAR = '2021'
 AND HH.TX_GYPM_IND NOT IN ('P', 'M')
)

,ANON_DONOR AS (
SELECT
 ID_NUMBER
 ,ANONYMOUS_DONOR
From table(rpt_pbh634.ksm_pkg.tbl_special_handling_concat)
WHERE ANONYMOUS_DONOR = 'Y'
)

,KSM_STAFF AS (
  SELECT * FROM table(rpt_pbh634.ksm_pkg.tbl_frontline_ksm_staff) staff -- Historical Kellogg gift officers
  -- Join credited visit ID to staff ID number
 )

,ASSIGNED AS(
SELECT
  AH.ID_NUMBER AS ID_NUMBER
 ,AE.PREF_MAIL_NAME AS STAFF_NAME
FROM rpt_pbh634.v_assignment_history AH
INNER JOIN KSM_STAFF KST
ON AH.assignment_id_number = KST.ID_NUMBER
LEFT JOIN ENTITY AE
ON AH.assignment_id_number = AE.ID_NUMBER
Where ah.assignment_active_calc = 'Active'
  --And
  AND assignment_type In
      -- Prospect Assist (PP), Prospect Manager (PM), Proposal Manager(PA), Leadership Giving Officer (LG)
      ('LG')
)

,REUNION_2015_PARTICIPANTS AS (
Select ep_participant.id_number
From ep_event
Left Join EP_Participant
ON ep_participant.event_id = ep_event.event_id
Where ep_event.event_name Like '%KSM15 Reunion Weekend%'
)

,REUNION_2016_PARTICIPANTS AS (
Select ep_participant.id_number
From ep_event
Left Join EP_Participant
ON ep_participant.event_id = ep_event.event_id
Where ep_event.event_name Like '%KSM16 Reunion Weekend%'
)

,REUNION_2020_REGISTRANTS AS (
Select ep_participant.id_number
From ep_event
Left Join EP_Participant
ON ep_participant.event_id = ep_event.event_id
Where ep_event.event_name Like '%KSM20 Reunion Weekend%'
)

,KSM_ENGAGEMENT AS (--- Subquery to add into the 2021 Reunion Report. This will help user identify an alum's most recent attendance. 

Select DISTINCT event.id_number,
       max (start_dt_calc) keep (dense_rank First Order By start_dt_calc DESC) As Date_Recent_Event,
       max (event.event_id) keep (dense_rank First Order By start_dt_calc DESC) As Recent_Event_ID,
       max (event.event_name) keep(dense_rank First Order By start_dt_calc DESC) As Recent_Event_Name
from rpt_pbh634.v_nu_event_participants event
where event.ksm_event = 'Y'
and event.degrees_concat is not null
Group BY event.id_number
Order By Date_Recent_Event ASC)

,KSM_CLUB_LEADERS AS (Select DISTINCT
entity.id_Number,
Listagg (committee_Header.short_desc, ';  ') Within Group (Order By committee_Header.short_desc) As Club_Titles,
Listagg (tms_committee_role.short_desc, ';  ') Within Group (Order By tms_committee_role.short_desc) As Leadership_Titles
From committee
Left Join Entity
ON Entity.Id_Number = committee.id_number
Left Join committee_header
ON committee_header.committee_code = committee.committee_code
Inner Join tms_committee_role
ON tms_committee_role.committee_role_code = committee.committee_role_code
Where
 (committee.committee_role_code = 'CL'
    OR  committee.committee_role_code = 'P'
    OR  committee.committee_role_code = 'I'
    OR  committee.committee_role_code = 'DIR'
    OR  committee.committee_role_code = 'S'
    OR  committee.committee_role_code = 'PE'
    OR  committee.committee_role_code = 'T'
    OR  committee.committee_role_code = 'E')
   AND  (committee.committee_status_code = 'C'
   And committee.committee_code != 'KACLE'
   And committee.Committee_Code != '535'
   And committee.committee_code != 'KCGC'
   And committee.committee_code != 'KWLC'
   And committee_header.short_desc != 'KSM Global Advisory Board')
   AND (committee_header.short_desc LIKE '%KSM%'
   Or committee_header.short_desc LIKE '%Kellogg%'
   Or committee_header.short_desc LIKE '%NU-%'
   Or committee_header.short_desc = 'NU Club of Switzerland')
Group By entity.id_number)

,KSM_NOTABLE_ALUMNI AS (
Select
 mailing_list.id_number
FROM  mailing_list
WHERE  mail_list_code = '100'
AND  UPPER(xcomment) LIKE 'KSM NOTABLE ALUMNI%'
)

,BUSINESS_EMAIL AS (
  SELECT
    EM.ID_NUMBER
    ,MAX(EM.EMAIL_ADDRESS) AS EMAIL_ADDRESS
  FROM EMAIL EM
  WHERE EM.EMAIL_TYPE_CODE = 'Y'
  AND EM.EMAIL_STATUS_CODE = 'A'
  GROUP BY EM.ID_NUMBER
)

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

,KSM_TOTAL20 AS (
  SELECT
  GT.ID_NUMBER
  ,SUM(GT.CREDIT_AMOUNT) AS KSM_TOTAL
 FROM GIVING_TRANS GT
 CROSS JOIN MANUAL_DATES MD
 WHERE GT.TX_GYPM_IND NOT IN ('P','M')
   AND GT.FISCAL_YEAR = MD.PFY
 GROUP BY GT.ID_NUMBER
)

,KSM_MATCH_20 AS (
   SELECT DISTINCT
     GT.ID_NUMBER
   FROM GIVING_TRANS GT
   CROSS JOIN MANUAL_DATES MD
   WHERE GT.TX_GYPM_IND = 'M'
     AND GT.MATCHED_FISCAL_YEAR = MD.PFY
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
 ,AF.DESCRIPTION
 ,AF.SCORE
FROM RPT_PBH634.V_KSM_MODEL_AF_10K AF
INNER JOIN KSM_REUNION KR
ON AF.ID_NUMBER = KR.ID_NUMBEr
)

--- ADDING ADDTIONAL MODEL SCORES

,KSM_Model as (select DISTINCT mg.id_number,
       mg.id_score,
       mg.pr_code,
       mg.pr_segment,
       mg.pr_score
From rpt_pbh634.v_ksm_model_mg mg)

--- ADDING ACTIVITIES (SPEAKERS AND CORPORATE RECRUITERS) 

--- KSM_SPEAKERS

,KSM_SPEAKERS AS (
SELECT DISTINCT ACT.ID_NUMBER,
       TMS_ACTIVITY_TABLE.short_desc,
       ACT.ACTIVITY_CODE,
       ACT.ACTIVITY_PARTICIPATION_CODE
FROM  activity act
LEFT JOIN TMS_ACTIVITY_TABLE ON TMS_ACTIVITY_TABLE.activity_code = ACT.ACTIVITY_CODE
WHERE  act.activity_code = 'KSP'
AND ACT.ACTIVITY_PARTICIPATION_CODE = 'P')


--- KSM CORPORATE RECRUITERS 

,KSM_CORPORATE_RECRUITERS AS (
SELECT DISTINCT ACT.ID_NUMBER,
       TMS_ACTIVITY_TABLE.short_desc,
       ACT.ACTIVITY_CODE,
       ACT.ACTIVITY_PARTICIPATION_CODE
FROM  activity act
LEFT JOIN TMS_ACTIVITY_TABLE ON TMS_ACTIVITY_TABLE.activity_code = ACT.ACTIVITY_CODE
WHERE  act.activity_code = 'KCR'
AND ACT.ACTIVITY_PARTICIPATION_CODE = 'P')




SELECT DISTINCT
  E.ID_NUMBER
  ,' ' AS "Ask Strategy"
  ,AFASK.ASK3_ROUNDED AS "Ask Amount"
  ,' ' AS "Attending Reunion"
  ,CASE WHEN RC15.ID_NUMBER IS NOT NULL THEN 'Y' ELSE '' END AS "REUNION_2015_COMMITTEE"
  ,CASE WHEN RC16.ID_NUMBER IS NOT NULL THEN 'Y' ELSE '' END AS "REUNION_2016_COMMITTEE"
  ,CASE WHEN RC20.ID_NUMBER IS NOT NULL THEN 'Y' ELSE '' END AS "REUNION_2020_COMMITTEE"
  ,CASE WHEN RC21.ID_NUMBER IS NOT NULL THEN 'Y' ELSE '' END AS "REUNION_2021_COMMITTEE"
  ,CASE WHEN PRC.ID_NUMBER IS NOT NULL THEN 'Y'  ELSE ''END AS "PAST_REUNION_COMMITEE"
  ,' ' AS "Assigned to a Gift Officer"
  ,CASE WHEN CYD.ID_NUMBER IS NOT NULL THEN 'Y' END AS "CYD"
  ,ANON.ANONYMOUS_DONOR
  ,E.RECORD_STATUS_CODE
  ,E.GENDER_CODE
  ,E.PREFIX AS PREFIX_1
  ,E.FIRST_NAME AS FIRST_NAME_1
  ,E.MIDDLE_NAME AS MIDDLE_NAME_1
  ,E.LAST_NAME AS LAST_NAME_1
  ,WT0_PKG.GetMaidenLast(E.ID_NUMBER) MAIDEN_1
  ,SALUTATION_FIRST(E.ID_NUMBER,
                        DECODE(TRIM(E.PREF_MAIL_NAME),
                               NULL, ' ',
                               E.SPOUSE_ID_NUMBER)) FIRST_NAME_SAL
  ,WT0_PKG.GetDeansSal(E.ID_NUMBER, 'KM') DEANS_SALUTATION
  ,KR.CLASS_YEAR
  ,KD."CLASS_SECTION"
  ,KD."PROGRAM" AS DEGREE_PROGRAM
  ,KD."PROGRAM_GROUP"
  ,WT0_PKG.GetAnyUndergradProgram(E.ID_NUMBER) UNDERGRAD
  ,CASE WHEN KR.CLASS_YEAR = SPKR.CLASS_YEAR THEN 'Y' ELSE ' ' END AS SPOUSE_SAME_YEAR
  ,CASE WHEN E.SPOUSE_ID_NUMBER = SK.ID_NUMBER THEN 'Y' ELSE ' ' END AS SPOUSE_MBA
  ,SP.ID_NUMBER AS SPOUSE_ID
  ,SP.PREFIX AS PREFIX_2
  ,SP.FIRST_NAME AS FIRST_NAME_2
  ,SP.MIDDLE_NAME AS MIDDLE_NAME_2
  ,SP.LAST_NAME AS LAST_NAME_2
  ,WT0_PKG.GetDeansSal(SP.ID_NUMBER, 'KM') DEANS_SALUTATION2
  ,SKD."PROGRAM" AS DEGREE_PROGRAM2
  ,SKD."FIRST_MASTERS_YEAR" AS CLASS_YEAR2
  ,NP.PROSPECT_MANAGER
  ,WT0_PKG.GetProspectManagers(E.ID_NUMBER, 'KM', 'X') PROG_PROSP_MGRS
  ,LGOA.STAFF_NAME AS LGO
  ,SH.NO_EMAIL_IND AS NO_EMAIL
  ,SH.NO_MAIL_SOL_IND AS NO_MAIL_SOLICIT
  ,SH.NO_PHONE_SOL_IND AS NO_PHONE_SOLICIT
  ,SH.NO_EMAIL_SOL_IND AS NO_EMAIL_SOLICIT
  ,SH.SPECIAL_HANDLING_CONCAT AS RESTRICTIONS
  ,CASE WHEN WT0_PKG.GetGAB(E.ID_NUMBER) = 'TRUE' THEN 'GAB'
       WHEN WT0_PKG.GetGAB(E.SPOUSE_ID_NUMBER) = 'TRUE' THEN 'Spouse GAB' ELSE ' ' END GAB
  ,CASE WHEN WT0_PKG.GetKAC(E.ID_NUMBER) = 'TRUE' THEN 'KAC'
     WHEN WT0_PKG.GetKAC(E.SPOUSE_ID_NUMBER) = 'TRUE' THEN 'Spouse KAC' ELSE ' ' END KAC
  ,CASE WHEN WT0_PKG.GetPeteHenderson(E.ID_NUMBER) = 'Y' THEN 'PHS'
     WHEN WT0_PKG.GetPeteHenderson(E.SPOUSE_ID_NUMBER) = 'Y' THEN 'Spouse PHS' ELSE ' ' END PHS
  ,CASE WHEN WT0_PKG.IsCurrentTrustee(E.ID_NUMBER) = 'TRUE' THEN 'Trustee'
     WHEN WT0_PKG.IsCurrentTrustee(E.SPOUSE_ID_NUMBER) = 'TRUE' THEN 'Spouse Trustee' ELSE ' ' END TRUSTEE
  ,CASE WHEN R20.ID_NUMBER IS NOT NULL THEN 'Y' END AS "REGISTERED FOR 2020 REUNION"
       ---- 2015 + 2016 Reunion Attendance
  ,CASE WHEN R6P.ID_NUMBER IS NOT NULL THEN 'Y' END AS "ATTENDED_REUNION_2016"
  ,CASE WHEN R5P.ID_NUMBER IS NOT NULL THEN 'Y' END AS "ATTENDED_REUNION_2015"
        --- Almost Removed Reunion first time because 2020 was Postponed
  ,KSM_ENGAGEMENT.Date_Recent_Event
  ,KSM_ENGAGEMENT.Recent_Event_ID
  ,KSM_ENGAGEMENT.Recent_Event_Name
  ,KSM_SPEAKERS.SHORT_DESC AS ACTIVITY_KSM_SPEAKERS
  ,KSM_CORPORATE_RECRUITERS.SHORT_DESC AS KSM_CORPORATE_RECRUITERS
  ,KCL.CLUB_TITLES AS CLUB_LEADERSHIP_CLUB
  ,KCL.Leadership_Titles AS LEADERSHIP_TITLE
  ,CASE WHEN KNA.ID_NUMBER IS NOT NULL THEN 'Y' END AS "NOTABLE_ALUMNI"
  ,CASE WHEN SH.SPECIAL_HANDLING_CONCAT LIKE '%No Email Solicitation%' THEN 'No Email Solicitation'
     WHEN SH.SPECIAL_HANDLING_CONCAT LIKE '%No Email%' THEN 'No Email'
     WHEN EM.EMAIL_ADDRESS IS NULL THEN ' '
     ELSE '(' || TEM.SHORT_DESC || ')' END AS EMAIL_USAGE_1
  ,' ' AS PREF_EMAIL_1
  ,PA.ADDR_TYPE_CODE AS ADDR_TYPE
  ,PA.STREET1
  ,PA.STREET2
  ,PA.STREET3
  ,PA.CITY
  ,PA.STATE_CODE AS STATE
  ,PA.ZIPCODE AS ZIP
  ,PC.SHORT_DESC AS COUNTRY
  ,HA.STREET1 AS HM_STREET1
  ,HA.STREET2 AS HM_STREET2
  ,HA.STREET3 AS HM_STREET3
  ,HA.CITY AS HM_CITY
  ,HA.STATE_CODE AS HM_STATE
  ,HA.ZIPCODE AS HM_ZIP
  ,HC.short_desc AS HM_COUNTRY
  ,WT0_PKG.GetPrefPhoneType(E.ID_NUMBER) PREF_PHONE_TYPE
  ,WT0_PKG.GetPrefPhone(E.ID_NUMBER) PREF_PHONE
  ,WT0_PKG.GetPrefPhoneInd(E.ID_NUMBER) PREF_PHONE_STATUS
  ,HEM.EMAIL_ADDRESS AS HM_EMAIL
  ,BA.STREET1 AS BS_STREET1
  ,BA.STREET2 AS BS_STREET2
  ,BA.STREET3 AS BS_STREET3
  ,BA.CITY AS BS_CITY
  ,BA.STATE_CODE AS BS_STATE
  ,BA.ZIPCODE AS BS_ZIP
  ,BC.short_desc AS BS_COUNTRY
  ,WT0_PKG.GetPhone(E.ID_NUMBER, 'B') BS_PHONE
  ,BEM.EMAIL_ADDRESS AS BS_EMAIL
  ,EMPL.EMPLOYER_NAME1 AS EMPLOYER
  ,EMPL.JOB_TITLE AS BS_POSITION
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
  ,FW.short_desc AS FLD_OF_WORK
  ,PR.last_plg_dt AS PLG_DATE
  ,PR.pacct1 AS PLG_ALLOC
  ,PR.pamt1 AS PLG_AMT
  ,PR.bal1 AS PLG_BALANCE
  ,PR.status1 AS PLG_STATUS
  ,PR.plgActive AS PLG_ACTIVE
  ,RPT_PBH634.KSM_PKG.get_fiscal_year(GI.GDT1) AS RECENT_FISAL_YEAR
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
  ,WT0_GIFTS2.HasAnonymousGift(E.ID_NUMBER, '1900', '2020') ANON_GIFT1
  ,WT0_GIFTS2.IsAnonymousDonor(E.ID_NUMBER) ANON_DONOR1
  ,WT0_GIFTS2.HasAnonymousGift(E.SPOUSE_ID_NUMBER, '1900', '2020') ANON_GIFT2
  ,WT0_GIFTS2.IsAnonymousDonor(E.SPOUSE_ID_NUMBER) ANON_DONOR2
  ,KSMT.KSM_TOTAL
  ,KAFT.KSM_AF_TOTAL
  ,KSM20.KSM_TOTAL AS KSM_TOTAL_2020
  ,CASE WHEN KM20.ID_NUMBER IS NOT NULL THEN 'Y' END AS MATCH_2020
  ,NP.OFFICER_RATING
  ,REPLACE(WT0_PKG.GetRecentRating(E.ID_NUMBER, 'PR'), ';;') RESEARCH_RATING
  ,KR.P_GEOCODE_DESC AS GEO_AREA
  --,WT0_PKG.Get_Prime_Geo_Area_From_Zip(PA.ZIPCODE) AS GEO_AREA
  ,WT0_PARSE(PROPOSAL_STATUS, 1,  '^') PROPOSAL_STATUS
  ,WT0_PARSE(PROPOSAL_STATUS, 2,  '^') PROPOSAL_START_DATE
  ,WT0_PARSE(PROPOSAL_STATUS, 3,  '^') PROPOSAL_ASK_AMT
  ,WT0_PARSE(PROPOSAL_STATUS, 4,  '^') ANTICIPATED_AMT
  ,WT0_PARSE(PROPOSAL_STATUS, 5,  '^') GRANTED_AMT
  ,WT0_PARSE(PROPOSAL_STATUS, 6,  '^') STOP_DATE
  ,WT0_PARSE(PROPOSAL_STATUS, 7,  '^') PROPOSAL_TITLE
  ,WT0_PARSE(PROPOSAL_STATUS, 8,  '^') PROPOSAL_DESCRIPTION
  ,WT0_PARSE(PROPOSAL_STATUS, 9,  '^') PROGRAM
  ,WT0_PARSE(PROPOSAL_STATUS, 10, '^') PROPOSAL_ID
  ,AFS.DESCRIPTION AS AF_10K_MODEL_TIER
  ,AFS.SCORE AS AF_10K_MODEL_SCORE
  ,KSM_MODEL.id_score
  ,KSM_MODEL.pr_segment
  ,KSM_MODEL.pr_score
  ,KGM.pledge_modified_cfy
  ,KGM.pledge_modified_pfy1
  ,KGM.pledge_modified_pfy2
  ,KGM.pledge_modified_pfy3
  ,KGM.pledge_modified_pfy4
  ,KGM.pledge_modified_pfy5
  ,KGM.modified_hh_credit_cfy
  ,KGM.modified_hh_gift_count_cfy
  ,KGM.modified_hh_gift_credit_pfy1
  ,KGM.modified_hh_gift_count_pfy1
  ,KGM.modified_hh_gift_credit_pfy2
  ,KGM.modified_hh_gift_count_pfy2
  ,KGM.modified_hh_gift_credit_pfy3
  ,KGM.modified_hh_gift_count_pfy3
  ,KGM.modified_hh_gift_credit_pfy4
  ,KGM.modified_hh_gift_count_pfy4
  ,KGM.modified_hh_gift_credit_pfy5
  ,KGM.modified_hh_gift_count_pfy5
FROM ENTITY E
INNER JOIN KSM_REUNION KR
ON E.ID_NUMBER = KR.ID_NUMBER
LEFT JOIN ASK3 AFASK
ON E.ID_NUMBER = AFASK.ID_NUMBER
LEFT JOIN REUNION_COMMITTEE RC
ON E.ID_NUMBER = RC.ID_NUMBER
LEFT JOIN REUNION_15_COMMITTEE RC15
ON E.ID_NUMBER = RC15.ID_NUMBER
LEFT JOIN REUNION_16_COMMITTEE RC16
ON E.ID_NUMBER = RC16.ID_NUMBER
LEFT JOIN REUNION_20_COMMITTEE RC20
ON E.ID_NUMBER = RC20.ID_NUMBER
LEFT JOIN REUNION_21_COMMITTEE RC21
ON E.ID_NUMBER = RC21.ID_NUMBER
LEFT JOIN PAST_REUNION_COMMITTEE PRC
ON E.ID_NUMBER = PRC.ID_NUMBER
LEFT JOIN CURRENT_DONOR CYD
ON E.ID_NUMBER = CYD.ID_NUMBER
LEFT JOIN ANON_DONOR ANON
ON E.ID_NUMBER = ANON.ID_NUMBER
LEFT JOIN RPT_PBH634.V_ENTITY_KSM_DEGREES KD
ON E.ID_NUMBER = KD.ID_NUMBER
LEFT JOIN KSM_REUNION SPKR
ON E.SPOUSE_ID_NUMBER = SPKR.ID_NUMBER
LEFT JOIN SPOUSE_KSM SK
ON E.SPOUSE_ID_NUMBER = SK.ID_NUMBER
LEFT JOIN ENTITY SP
ON E.SPOUSE_ID_NUMBER = SP.ID_NUMBER
LEFT JOIN RPT_PBH634.V_ENTITY_KSM_DEGREES SKD
ON E.SPOUSE_ID_NUMBER = SKD."ID_NUMBER"
LEFT JOIN NU_PRS_TRP_PROSPECT NP
ON E.ID_NUMBER = NP.ID_NUMBER
LEFT JOIN ASSIGNED LGOA
ON E.ID_NUMBER = LGOA.ID_NUMBER
LEFT JOIN table(rpt_pbh634.ksm_pkg.tbl_special_handling_concat) SH
ON E.ID_NUMBER = SH.ID_NUMBER
LEFT JOIN REUNION_2015_PARTICIPANTS R5P
ON E.ID_NUMBER = R5P.ID_NUMBER
LEFT JOIN REUNION_2016_PARTICIPANTS R6P
ON E.ID_NUMBER = R6P.ID_NUMBER
LEFT JOIN REUNION_2020_REGISTRANTS R20
ON E.ID_NUMBER = R20.ID_NUMBER
LEFT JOIN KSM_CLUB_LEADERS KCL
ON E.ID_NUMBER = KCL.ID_NUMBER
LEFT JOIN KSM_NOTABLE_ALUMNI KNA
ON E.ID_NUMBER = KNA.ID_NUMBER
LEFT JOIN EMAIL EM
ON E.ID_NUMBER = EM.ID_NUMBER
  AND EM.EMAIL_STATUS_CODE = 'A'
  AND EM.PREFERRED_IND = 'Y'
LEFT JOIN TMS_EMAIL_TYPE TEM
ON EM.EMAIL_TYPE_CODE = TEM.email_type_code
LEFT JOIN ADDRESS PA
ON E.ID_NUMBER = PA.ID_NUMBER
  AND PA.ADDR_STATUS_CODE = 'A'
  AND PA.ADDR_PREF_IND = 'Y'
LEFT JOIN TMS_COUNTRY PC
ON PA.COUNTRY_CODE = PC.COUNTRY_CODE
LEFT JOIN ADDRESS HA
ON E.ID_NUMBER = HA.ID_NUMBER
  AND HA.ADDR_STATUS_CODE = 'A'
  AND HA.ADDR_TYPE_CODE = 'H'
LEFT JOIN TMS_COUNTRY HC
ON HA.COUNTRY_CODE = HC.country_code
LEFT JOIN EMAIL HEM
ON E.ID_NUMBER = HEM.ID_NUMBER
 AND HEM.EMAIL_STATUS_CODE = 'A'
 AND HEM.EMAIL_TYPE_CODE = 'X'
 AND HEM.PREFERRED_IND = 'Y'
LEFT JOIN ADDRESS BA
ON E.ID_NUMBER = BA.ID_NUMBER
  AND BA.ADDR_STATUS_CODE = 'A'
  AND BA.ADDR_TYPE_CODE = 'B'
LEFT JOIN TMS_COUNTRY BC
ON BA.COUNTRY_CODE = BC.country_code
LEFT JOIN BUSINESS_EMAIL BEM
ON E.ID_NUMBER = BEM.ID_NUMBER
LEFT JOIN EMPLOYMENT EMPL
ON E.ID_NUMBER = EMPL.ID_NUMBER
  AND EMPL.JOB_STATUS_CODE = 'C'
  AND EMPL.PRIMARY_EMP_IND = 'Y'
LEFT JOIN TMS_FLD_OF_WORK FW
ON EMPL.FLD_OF_WORK_CODE = FW.fld_of_work_code
LEFT JOIN PLEDGE_ROWS PR
 ON E.ID_NUMBER = PR.ID
LEFT JOIN GIFTINFO GI
  ON E.ID_NUMBER = GI.ID_NUMBER
LEFT JOIN KSM_TOTAL KSMT
 ON E.ID_NUMBER = KSMT.ID_NUMBER
LEFT JOIN KSM_AF_TOTAL KAFT
  ON E.ID_NUMBER = KAFT.ID_NUMBER
LEFT JOIN KSM_TOTAL20 KSM20
  ON E.ID_NUMBER = KSM20.ID_NUMBER
LEFT JOIN KSM_MATCH_20 KM20
  ON E.ID_NUMBER = KM20.ID_NUMBER
LEFT JOIN NU_PRS_TRP_PROSPECT NP
  ON E.ID_NUMBER = NP.ID_NUMBER
LEFT JOIN PROPOSALS PROP
  ON E.ID_NUMBER = PROP.ID_NUMBER
LEFT JOIN AF_SCORES AFS
  ON E.ID_NUMBER = AFS.ID_NUMBER
LEFT JOIN KSM_MODEL
     ON KSM_MODEL.ID_NUMBER = E.ID_NUMBER
LEFT JOIN KSM_ENGAGEMENT
     ON KSM_ENGAGEMENT.ID_NUMBER = E.ID_NUMBER
LEFT JOIN KSM_SPEAKERS
     ON KSM_SPEAKERS.ID_NUMBER = E.ID_NUMBER
LEFT JOIN KSM_CORPORATE_RECRUITERS
     ON KSM_CORPORATE_RECRUITERS.ID_NUMBER = E.ID_NUMBER
LEFT JOIN GIVING_SUMMARY
     ON GIVING_SUMMARY.id_number = KR.ID_NUMBER
LEFT JOIN KSM_GIVING_MOD KGM
        ON KGM.household_id = E.ID_NUMBER
ORDER BY E.LAST_NAME
;
