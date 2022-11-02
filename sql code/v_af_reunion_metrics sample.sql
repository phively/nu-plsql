--CREATE OR REPLACE VIEW RPT_ABM1914.V_AF_REUNION_METRICS AS
With manual_dates As (
Select
  2018 AS pfy
  ,2019 AS cfy
  From DUAL
),

KSM_DEGREES AS (
 SELECT
   KD.ID_NUMBER
   ,KD.PROGRAM
   ,KD.PROGRAM_GROUP
   ,KD."CLASS_SECTION"
 FROM RPT_PBH634.V_ENTITY_KSM_DEGREES KD
 WHERE KD."PROGRAM" IN ('EMP', 'EMP-FL', 'EMP-IL', 'FT', 'FT-1Y', 'FT-2Y', 'FT-CB', 'FT-EB', 'FT-JDMBA', 'FT-MMGT', 'FT-MMM', 'TMP', 'TMP-SAT',
'TMP-SATXCEL', 'TMP-XCEL')
),

KSM_REUNION AS (
SELECT
A.*
FROM AFFILIATION A
INNER JOIN KSM_DEGREES KD
ON A.ID_NUMBER = KD."ID_NUMBER"
CROSS JOIN manual_dates MD
WHERE TO_NUMBER(NVL(TRIM(A.CLASS_YEAR),'0')) IN (MD.CFY-1, MD.CFY-5, MD.CFY-10, MD.CFY-15, MD.CFY-20, MD.CFY-25, MD.CFY-30, MD.CFY-35,
  MD.CFY-40, MD.CFY-45, MD.CFY-50, MD.CFY-55)
AND A.AFFIL_CODE = 'KM'
AND A.AFFIL_LEVEL_CODE = 'RG'
),

SPOUSE_KSM AS (
SELECT
  E.ID_NUMBER
FROM ENTITY E
INNER JOIN KSM_DEGREES KD
ON E.ID_NUMBER = KD."ID_NUMBER"
),

COUNT_HH_ID AS (
SELECT
 HH.HOUSEHOLD_ID
 ,COUNT(HH.ID_NUMBER) AS COUNT_ID
FROM RPT_PBH634.V_ENTITY_KSM_HOUSEHOLDS HH
INNER JOIN KSM_REUNION KR
ON HH."ID_NUMBER" = KR.ID_NUMBER
GROUP BY HH.HOUSEHOLD_ID
),

COUNT_HH_ID_CY AS (
SELECT
  HH.HOUSEHOLD_ID
  ,KR.CLASS_YEAR
  ,COUNT(HH."ID_NUMBER") AS COUNT_CY_ID
FROM RPT_PBH634.V_ENTITY_KSM_HOUSEHOLDS HH
INNER JOIN KSM_REUNION KR
ON HH."ID_NUMBER" = KR.ID_NUMBER
GROUP BY HH.HOUSEHOLD_ID, KR.CLASS_YEAR
),

ALL_GIFTS AS (
  SELECT *
  FROM rpt_pbh634.v_ksm_giving_trans_hh
),

GT AS (
SELECT GT.*
  FROM ALL_GIFTS GT
  INNER JOIN KSM_REUNION KR
  ON GT.ID_NUMBER = KR.ID_NUMBER
  CROSS JOIN MANUAL_DATES MD
  WHERE GT."FISCAL_YEAR" IN (MD.PFY, MD.CFY)
),

GIVING_TRANS AS (
 SELECT GT.*
  FROM ALL_GIFTS GT
  INNER JOIN KSM_REUNION KR
  ON GT.ID_NUMBER = KR.ID_NUMBER
  CROSS JOIN MANUAL_DATES MD
  WHERE GT."FISCAL_YEAR" = MD.CFY
),

AF_PLEDGES AS (
SELECT
  GT.*
FROM GIVING_TRANS GT
CROSS JOIN MANUAL_DATES MD
WHERE GT.FISCAL_YEAR = MD.CFY
AND GT.TRANSACTION_TYPE NOT IN ('Bequest Expectancy', 'Grant Pledge', 'Payroll Deduction', 'Lead Trust Pledge', 'Life Insurance Expectancy')
AND GT.TX_GYPM_IND = 'P'
--AND GT.PLEDGE_STATUS = 'A'
AND (GT.AF_FLAG = 'Y' OR GT.CRU_FLAG = 'Y')
)

, GIVING_SUMMARY AS (
  SELECT
    ID_NUMBER
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year     And cru_flag = 'Y' Then hh_credit Else 0 End) As cru_cfy
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 1 And cru_flag = 'Y' Then hh_credit Else 0 End) As cru_pfy1
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 2 And cru_flag = 'Y' Then hh_credit Else 0 End) As cru_pfy2
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 3 And cru_flag = 'Y' Then hh_credit Else 0 End) As cru_pfy3
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 4 And cru_flag = 'Y' Then hh_credit Else 0 End) As cru_pfy4
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 5 And cru_flag = 'Y' Then hh_credit Else 0 End) As cru_pfy5
  FROM ALL_GIFTS
  CROSS JOIN RPT_PBH634.V_CURRENT_CALENDAR CAL
  GROUP BY ID_NUMBER
)

,ksm_pledges As (
Select Distinct
    *
From pledge
INNER JOIN AF_PLEDGES AP
  --ON AP.ID_NUMBER = PLEDGE.PLEDGE_DONOR_ID
 ON PLEDGE.PLEDGE_DONOR_ID = AP.ID_NUMBER
   AND PLEDGE.PLEDGE_PLEDGE_NUMBER = AP.TX_NUMBER
   AND PLEDGE.Pledge_Sequence = AP.TX_SEQUENCE
 WHERE pledge_program_code = 'KM'
)

, ksm_payments As (
  Select
    gft.tx_number
    , gft.tx_sequence
    , gft.pmt_on_pledge_number
    , gft.allocation_code
    , gft.date_of_record
    , gft.legal_amount
  From nu_gft_trp_gifttrans gft
  --Inner Join ALLOCATION A
 --   On A.allocation_code = gft.allocation_code
--    AND A.ALLOC_SCHOOL = 'KM'
  Inner Join ksm_pledges
    On ksm_pledges.pledge_pledge_number = gft.pmt_on_pledge_number
    AND KSM_PLEDGES.TX_SEQUENCE = GFT.TX_SEQUENCE
  Where gft.legal_amount > 0
  Order By
    pmt_on_pledge_number Asc
    , date_of_record Desc
)
, ksm_paid_amt As (
  Select
    pmt_on_pledge_number
    , allocation_code
    , sum(legal_amount)
      As total_paid
  From ksm_payments
  Group By pmt_on_pledge_number, allocation_code
)

--, pledge_counts As (
,PLEDGE_INFO AS (
Select
    pledge.pledge_donor_id
    ,ROW_NUMBER() OVER(PARTITION BY pledge.pledge_donor_id ORDER BY PLEDGE.PLEDGE_DATE_OF_RECORD DESC)RW
    ,PLEDGE.PLEDGE_DATE_OF_RECORD
    ,pledge.pledge_pledge_number
    -----,sum(pledge.pledge_amount)
   --- As CREDIT_AMOUNT
     ,pledge.pledge_associated_credit_amt
      As CREDIT_AMOUNT
    ,A.SHORT_NAME AS ALLOC_SHORT_NAME
    ,KSM_PLEDGES.PLEDGE_STATUS
    ,nvl(ksm_paid_amt.total_paid, 0) As ALLOC_TOTAL_PAID
    ,max(
        pledge.pledge_associated_credit_amt - nvl(ksm_paid_amt.total_paid, 0)
        ) As PLEDGE_BALANCE
   /* , sum(pledge.pledge_amount)
      As pledge_total*/
From pledge
  Inner Join ksm_pledges
    ON KSM_PLEDGES.PLEDGE_DONOR_ID = PLEDGE.PLEDGE_DONOR_ID
      AND ksm_pledges.pledge_pledge_number = pledge.pledge_pledge_number
      AND KSM_PLEDGES.TX_SEQUENCE = PLEDGE.PLEDGE_SEQUENCE
   LEFT JOIN  ksm_paid_amt
    On ksm_paid_amt.pmt_on_pledge_number = pledge.pledge_pledge_number
     And ksm_paid_amt.allocation_code = pledge.pledge_allocation_name
  LEFT JOIN ALLOCATION A
  ON PLEDGE.PLEDGE_ALLOCATION_NAME = A.ALLOCATION_CODE
  WHERE A.ALLOC_SCHOOL = 'KM'
Group By pledge.pledge_donor_id, PLEDGE.PLEDGE_DATE_OF_RECORD,  pledge.pledge_pledge_number, pledge.pledge_associated_credit_amt,
     A.SHORT_NAME, KSM_PLEDGES.PLEDGE_STATUS, ksm_paid_amt.total_paid
)

,PLEDGE_ROWS AS (
 select pledge_donor_id,
                 max(decode(rw,1,PLEDGE_DATE_OF_RECORD)) last_plg_dt,
                 max(decode(rw,1,pledge_pledge_number)) plg1,
                 max(decode(rw,1,CREDIT_AMOUNT)) pamt1,
                 max(decode(rw,1,ALLOC_SHORT_NAME)) pacct1,
                 max(decode(rw,1,alloc_total_paid)) paid1,
                 max(decode(rw,1,pledge_balance)) bal1,
                 max(decode(rw,2,PLEDGE_DATE_OF_RECORD)) pdt2,
                 max(decode(rw,2,pledge_pledge_number)) plg2,
                 max(decode(rw,2,CREDIT_AMOUNT)) pamt2,
                 max(decode(rw,2,ALLOC_SHORT_NAME)) pacct2,
                 max(decode(rw,2,alloc_total_paid)) paid2,
                 max(decode(rw,2,pledge_balance)) bal2,
                 max(decode(rw,3,PLEDGE_DATE_OF_RECORD)) pdt3,
                 max(decode(rw,3,pledge_pledge_number)) plg3,
                 max(decode(rw,3,CREDIT_AMOUNT)) pamt3,
                 max(decode(rw,3,ALLOC_SHORT_NAME)) pacct3,
                 max(decode(rw,3,alloc_total_paid)) paid3,
                 max(decode(rw,3,pledge_balance)) bal3,
                 max(decode(rw,4,PLEDGE_DATE_OF_RECORD)) pdt4,
                 max(decode(rw,4,pledge_pledge_number)) plg4,
                 max(decode(rw,4,CREDIT_AMOUNT)) pamt4,
                 max(decode(rw,4,ALLOC_SHORT_NAME)) pacct4,
                 max(decode(rw,4,alloc_total_paid)) paid4,
                 max(decode(rw,4,pledge_balance)) bal4
          FROM PLEDGE_INFO GROUP BY pledge_donor_id
)

,PLEDGE_SUM AS (
SELECT
  PI.pledge_donor_id
  ,SUM(PI.CREDIT_AMOUNT) AS TOTAL_PLG_AMT
  ,SUM(PLEDGE_BALANCE) AS TOTAL_PLG_BALANCE
  ,SUM(ALLOC_TOTAL_PAID) AS TOTAL_PLG_PAID_AMT
FROM PLEDGE_INFO PI
GROUP BY PI.PLEDGE_DONOR_ID
),

GIVING_TRANS_ALLOCS AS (
SELECT GT.*
  FROM GIVING_TRANS GT
  INNER JOIN RPT_PBH634.V_ALLOC_CURR_USE ALLOC
  ON GT."ALLOCATION_CODE" = ALLOC."ALLOCATION_CODE"
  CROSS JOIN MANUAL_DATES MD
  WHERE GT."FISCAL_YEAR" = MD.CFY
  AND GT.TRANSACTION_TYPE <> 'Bequest Received'
),

GIVING_TRANS_KLC AS (
SELECT GT.*
  FROM GT GT
  INNER JOIN RPT_PBH634.V_ALLOC_CURR_USE ALLOC
  ON GT."ALLOCATION_CODE" = ALLOC."ALLOCATION_CODE"
  CROSS JOIN MANUAL_DATES MD
  WHERE GT."FISCAL_YEAR" IN (MD.CFY, MD.PFY)
),

GIFT_CLUB AS
(
SELECT * FROM GIFT_CLUBS
  WHERE (GIFT_CLUB_CODE = 'LKM'
  AND GIFT_CLUB_STATUS = 'A'
  AND OPERATOR_NAME = 'lrb324')
  OR (GIFT_CLUB_CODE = 'LKM'
  AND GIFT_CLUB_STATUS = 'A'
  AND OPERATOR_NAME = 'abm1914')--added myself on 11/15 after adding someone for Bridget
  OR (GIFT_CLUB_CODE = 'LKM'
  AND GIFT_CLUB_STATUS = 'A'
  AND GIFT_CLUB_REASON = 'KLC Recurring Gift Pledge')
),

PAYFY19 as
(select plg.id,
        sum(plg.prop * sc.payment_schedule_balance) pay,
        sum(case when plg.af = 'Y'
            then plg.prop * sc.payment_schedule_balance else 0 end) payaf
 from payment_schedule sc,
 (select p.pledge_donor_id ID,
         pp.prim_pledge_number plg,
         p.pledge_allocation_name alloc,
         al.annual_sw AF,
         p.pledge_associated_credit_amt / pp.prim_pledge_amount prop
  from primary_pledge pp,
       pledge p,
       allocation al
  where p.pledge_pledge_number = pp.prim_pledge_number
  and   p.pledge_allocation_name = al.allocation_code
  and   al.alloc_school = 'KM'
  and   pp.prim_pledge_status = 'A') plg
 where plg.plg = sc.payment_schedule_pledge_nbr
 and   sc.payment_schedule_status = 'U'
 and   sc.payment_schedule_date between '20180901' and '20190831'
 group by plg.id),

KGF_REWORKED AS
(
select ID,
        SUM(case when FY =  '2018' then AMT else 0 end) tot_kgifts_FY18,
        SUM(case when FY =  '2019' then AMT else 0 end) tot_kgifts_FY19
  FROM (
SELECT
   HH.ID_NUMBER ID
   ,HH.TX_NUMBER RCPT
   ,HH.FISCAL_YEAR FY
   ,(HH.CREDIT_AMOUNT + nvl(mtch.mtch,0) + nvl(clm.claim,0)) AMT
FROM GIVING_TRANS_KLC HH,
  (SELECT
    HH."ID_NUMBER"
   ,HH."MATCHED_TX_NUMBER" RCPT
   ,HH.ALLOCATION_CODE ALLOC
   ,SUM(HH."CREDIT_AMOUNT") MTCH
    FROM GIVING_TRANS_KLC HH
     WHERE HH.TX_GYPM_IND = 'M'
    GROUP BY HH."ID_NUMBER", HH."MATCHED_TX_NUMBER", HH.ALLOCATION_CODE)mtch,
   (SELECT
      HH.ID_NUMBER
      ,HH."TX_NUMBER" RCPT
      ,HH.ALLOCATION_CODE ALLOC
      ,SUM(MC.CLAIM_AMOUNT) CLAIM
      FROM GIVING_TRANS_KLC HH
      LEFT JOIN MATCHING_CLAIM MC
        ON HH.TX_NUMBER = MC.CLAIM_GIFT_RECEIPT_NUMBER
        AND HH.ALLOCATION_CODE = MC.ALLOCATION_CODE
        AND HH.TX_SEQUENCE = MC.CLAIM_GIFT_SEQUENCE
      GROUP BY HH.ID_NUMBER, HH.TX_NUMBER, HH.ALLOCATION_CODE)CLM
     WHERE HH."FISCAL_YEAR" IN ('2018', '2019')
     AND HH."ID_NUMBER" = MTCH.ID_NUMBER (+)
     AND HH."TX_NUMBER" = MTCH.RCPT (+)
     AND HH.ALLOCATION_CODE = MTCH.ALLOC (+)
     AND HH."ID_NUMBER" = CLM.ID_NUMBER (+)
     AND HH."TX_NUMBER" = CLM.RCPT (+)
     AND HH."ALLOCATION_CODE" = CLM.ALLOC (+)
     AND HH."TX_GYPM_IND" NOT IN ('P','M'))
     GROUP BY ID
),

MYDATA AS (
         SELECT
           ID_NUMBER
           ,CREDIT_AMOUNT amt
           ,HH_CREDIT hh_amt
           ,TX_GYPM_IND
           ,DATE_OF_RECORD dt
           ,TX_NUMBER rcpt
           ,TX_SEQUENCE
           ,MATCHED_TX_NUMBER m_rcpt
           ,ALLOC_SHORT_NAME acct
           ,AF_FLAG AF
           ,FISCAL_YEAR FY
          FROM GIVING_TRANS_ALLOCS
          WHERE TX_GYPM_IND <> 'P'
),

MYDATA_KELLOGG AS (
 SELECT
           ID_NUMBER
           ,CREDIT_AMOUNT amt
           ,HH_CREDIT hh_amt
           ,TX_GYPM_IND
           ,DATE_OF_RECORD dt
           ,TX_NUMBER rcpt
           ,TX_SEQUENCE
           ,MATCHED_TX_NUMBER m_rcpt
           ,ALLOC_SHORT_NAME acct
           ,AF_FLAG AF
           ,FISCAL_YEAR FY
          FROM GIVING_TRANS
          WHERE TX_GYPM_IND <> 'P'
),

ROWDATA AS(
SELECT
           g.ID_NUMBER
           ,ROW_NUMBER() OVER(PARTITION BY g.ID_NUMBER ORDER BY g.dt DESC)RW
           ,g.amt
           ,g.hh_amt
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
                ,MC.CLAIM_GIFT_SEQUENCE
                ,KSMT.ALLOCATION_CODE
                ,SUM(MC.CLAIM_AMOUNT) CLAIM
            FROM GIVING_TRANS_ALLOCS KSMT
            INNER JOIN MATCHING_CLAIM MC
              ON KSMT."TX_NUMBER" = MC.CLAIM_GIFT_RECEIPT_NUMBER
              AND KSMT."TX_SEQUENCE" = MC.CLAIM_GIFT_SEQUENCE
              GROUP BY KSMT.TX_NUMBER,MC.CLAIM_GIFT_SEQUENCE, KSMT.ALLOCATION_CODE) C
              ON G.RCPT = C.TX_NUMBER
              AND G."TX_SEQUENCE" = C.CLAIM_GIFT_SEQUENCE

),

GIFTINFO AS (
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
),

TOTAL_GIFTS AS (
SELECT
  G.ID_NUMBER
  ,SUM(G.AMT) AS SUM_GFT_AMT
  ,SUM(G.HH_AMT) AS SUM_HH_GFT
  ,NVL(SUM(M.AMT),0) AS TOTAL_MATCH_AMT
  ,NVL(SUM(c.claim),0) AS TOTAL_CLAIM_AMT
  ,SUM(G.AMT)+NVL(SUM(M.AMT),0)+NVL(SUM(C.CLAIM),0) AS TOTAL_GIFT_AMT
  ,SUM(G.HH_AMT)+NVL(SUM(M.AMT),0)+NVL(SUM(C.CLAIM),0) AS TOTAL_HH_GFT_AMT
FROM (SELECT * FROM MYDATA WHERE TX_GYPM_IND <> 'M') g
           LEFT JOIN (SELECT * FROM MYDATA WHERE TX_GYPM_IND = 'M') m
                ON g.rcpt = m.m_rcpt AND g.ID_NUMBER = m.ID_NUMBER
           LEFT JOIN (SELECT
                KSMT.TX_NUMBER
                ,MC.CLAIM_GIFT_SEQUENCE
                ,KSMT.ALLOCATION_CODE
                ,SUM(MC.CLAIM_AMOUNT) CLAIM
            FROM GIVING_TRANS_ALLOCS KSMT
            INNER JOIN MATCHING_CLAIM MC
              ON KSMT."TX_NUMBER" = MC.CLAIM_GIFT_RECEIPT_NUMBER
              AND KSMT."TX_SEQUENCE" = MC.CLAIM_GIFT_SEQUENCE
              GROUP BY KSMT.TX_NUMBER,MC.CLAIM_GIFT_SEQUENCE, KSMT.ALLOCATION_CODE) C
              ON G.RCPT = C.TX_NUMBER
              AND G."TX_SEQUENCE" = C.CLAIM_GIFT_SEQUENCE
     GROUP BY G.ID_NUMBER
),

TOTAL_KELLOGG_GIFTS AS (
SELECT
  G.ID_NUMBER
  ,SUM(G.AMT) AS SUM_GFT_AMT
  ,NVL(SUM(M.AMT),0) AS TOTAL_MATCH_AMT
  ,NVL(SUM(c.claim),0) AS TOTAL_CLAIM_AMT
  ,SUM(G.AMT)+NVL(SUM(M.AMT),0)+NVL(SUM(C.CLAIM),0) AS TOTAL_GIFT_AMT
FROM (SELECT * FROM MYDATA_KELLOGG WHERE TX_GYPM_IND <> 'M') g
           LEFT JOIN (SELECT * FROM MYDATA_KELLOGG WHERE TX_GYPM_IND = 'M') m
                ON g.rcpt = m.m_rcpt AND g.ID_NUMBER = m.ID_NUMBER
           LEFT JOIN (SELECT
                KSMT.TX_NUMBER
                ,MC.CLAIM_GIFT_SEQUENCE
                ,KSMT.ALLOCATION_CODE
                ,SUM(MC.CLAIM_AMOUNT) CLAIM
            FROM GIVING_TRANS_ALLOCS KSMT
            INNER JOIN MATCHING_CLAIM MC
              ON KSMT."TX_NUMBER" = MC.CLAIM_GIFT_RECEIPT_NUMBER
              AND KSMT."TX_SEQUENCE" = MC.CLAIM_GIFT_SEQUENCE
              GROUP BY KSMT.TX_NUMBER,MC.CLAIM_GIFT_SEQUENCE, KSMT.ALLOCATION_CODE) C
              ON G.RCPT = C.TX_NUMBER
              AND G."TX_SEQUENCE" = C.CLAIM_GIFT_SEQUENCE
     GROUP BY G.ID_NUMBER
)

SELECT DISTINCT
  E.ID_NUMBER
  ,KHH."HOUSEHOLD_ID"
  ,KHH."HOUSEHOLD_PRIMARY"
  ,FAID.other_id AS FASIS_ID
  ,AD.OTHER_ID AS ADID
  --TO_NUMBER(NVL(TRIM(A.YEAR1),'0'))
  ,E.RECORD_STATUS_CODE
  ,case when nvl(kgfr.tot_kgifts_FY18,0) >= 2500 or
                (nvl(kgfr.tot_kgifts_fy19,0)+nvl(pay19.payAF,0) >= 2500)
            then 'Standard KLC Member'
         when (KR.CLASS_YEAR between '2013' and '2018') AND
             nvl(kgfr.tot_kgifts_FY18,0) >= 1000 THEN 'Recent Grad KLC Member'
         WHEN (KR.CLASS_YEAR between '2014' and '2018') AND
             (nvl(kgfr.tot_kgifts_FY18,0) >= 1000 OR (nvl(kgfr.tot_kgifts_FY19,0) >= 1000))
             THEN 'Recent Grad KLC Member'
         WHEN E.ID_NUMBER = GC.GIFT_CLUB_ID_NUMBER THEN 'Manual Add KLC Member'
            end AS "KLC Segment"
   ,kgfr.tot_kgifts_fy18
   ,case when nvl(kgfr.tot_kgifts_fy18,0) = 0 then ' '
            when kgfr.tot_kgifts_FY18 >= 1000  and kgfr.tot_kgifts_fy18 < 2500
                and (KR.CLASS_YEAR between '2013' and '2018') then ' $1,000-$2,499'
            when kgfr.tot_kgifts_fy18 >= 2500  and kgfr.tot_kgifts_fy18 < 5000   then ' $2,500-$4,999'
            when kgfr.tot_kgifts_fy18 >= 5000  and kgfr.tot_kgifts_fy18 < 10000  then ' $5,000-$9,999'
            when kgfr.tot_kgifts_fy18 >= 10000 and kgfr.tot_kgifts_fy18 < 25000  then '$10,000-$24,999'
            when kgfr.tot_kgifts_fy18 >= 25000 and kgfr.tot_kgifts_fy18 < 50000  then '$25,000-49,999'
            when kgfr.tot_kgifts_fy18 >= 50000                                  then '$50,000+'
            else ' ' end        KLC_LEVEL_PFY
   ,kgfr.tot_kgifts_fy19
   ,pay19.payAF
   ,nvl(kgfr.tot_kgifts_fy19,0)+nvl(pay19.payAF,0) AS TOTAL_FY19
   ,case when nvl(kgfr.tot_kgifts_fy19,0)+nvl(pay19.payAF,0) = 0 then ' '
            when nvl(kgfr.tot_kgifts_FY19,0)+nvl(pay19.payAF,0) >= 1000  and nvl(kgfr.tot_kgifts_fy19,0)+nvl(pay19.payAF,0) < 2500
                and (KR.CLASS_YEAR between '2014' and '2018') then '$1,000-$2,499'
            when nvl(kgfr.tot_kgifts_fy19,0)+nvl(pay19.payAF,0) >= 2500 then '$2,500-$4,999'
            when nvl(kgfr.tot_kgifts_fy19,0)+nvl(pay19.payAF,0) >= 5000 then '$5,000-$9,999'
            when nvl(kgfr.tot_kgifts_fy19,0)+nvl(pay19.payAF,0) >= 10000 then '$10,000-$24,999'
            when nvl(kgfr.tot_kgifts_fy19,0)+nvl(pay19.payAF,0) >= 25000 then '$25,000-49,999'
            when nvl(kgfr.tot_kgifts_fy19,0)+nvl(pay19.payAF,0) >= 50000 then '$50,000+'
            else ' ' end                         KLC_LEVEL_CFY
  ,E.PREFIX AS PREFIX_1
  ,E.FIRST_NAME AS FIRST_NAME_1
  ,E.MIDDLE_NAME AS MIDDLE_NAME_1
  ,E.LAST_NAME AS LAST_NAME_1
  ,WT0_PKG.GetMaidenLast(E.ID_NUMBER) MAIDEN_1
  ,WT0_PKG.GetDeansSal(E.ID_NUMBER, 'KM') DEANS_SALUTATION
  ,SK.ID_NUMBER AS SPOUSE_ID
  ,KR.CLASS_YEAR
  ,KD."CLASS_SECTION"
  ,SH.NO_EMAIL_IND AS NO_EMAIL
  ,SH.NO_MAIL_SOL_IND AS NO_MAIL_SOLICIT
  ,SH.NO_PHONE_SOL_IND AS NO_PHONE_SOLICIT
  ,SH.NO_EMAIL_SOL_IND AS NO_EMAIL_SOLICIT
  ,CASE WHEN KR.CLASS_YEAR = SPKR.CLASS_YEAR THEN 'Y' ELSE ' ' END AS SPOUSE_SAME_YEAR
  ,CASE WHEN E.SPOUSE_ID_NUMBER = SK.ID_NUMBER THEN 'Y' ELSE ' ' END AS SPOUSE_MBA
  ,SH.SPECIAL_HANDLING_CONCAT AS RESTRICTIONS
  ,SH.ANONYMOUS_DONOR
  ,CASE WHEN WT0_PKG.GetGAB(E.ID_NUMBER) = 'TRUE' THEN 'GAB'
     WHEN WT0_PKG.GetGAB(SK.ID_NUMBER) = 'TRUE' THEN 'Spouse GAB' ELSE ' ' END GAB
  ,CASE WHEN WT0_PKG.GetKAC(E.ID_NUMBER) = 'TRUE' THEN 'KAC'
     WHEN WT0_PKG.GetKAC(SK.ID_NUMBER) = 'TRUE' THEN 'Spouse KAC' ELSE ' ' END KAC
  ,CASE WHEN WT0_PKG.GetPeteHenderson(E.ID_NUMBER) = 'Y' THEN 'PHS'
     WHEN WT0_PKG.GetPeteHenderson(SK.ID_NUMBER) = 'Y' THEN 'Spouse PHS' ELSE ' ' END PHS
  ,CASE WHEN WT0_PKG.IsCurrentTrustee(E.ID_NUMBER) = 'TRUE' THEN 'Trustee'
     WHEN WT0_PKG.IsCurrentTrustee(SK.ID_NUMBER) = 'TRUE' THEN 'Spouse Trustee' ELSE ' ' END TRUSTEE
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
  ,EMPL.EMPLOYER_NAME1 AS EMPLOYER
  ,EMPL.JOB_TITLE AS BS_POSITION
  ,SALUTATION_FIRST(E.ID_NUMBER, DECODE(WT0_PKG.IsKelloggAlum(SK.ID_NUMBER),
                                        'TRUE', SK.ID_NUMBER,
                                        ' ')) FIRST_NAME_SAL
  ,SALUTATION_LAST(E.ID_NUMBER,
                      DECODE(TRIM(E.PREF_MAIL_NAME),
                              NULL, ' ',
                              SK.ID_NUMBER)) SALUTATION
  ,PR.last_plg_dt
  ,PR.plg1
  ,PR. pamt1
  ,PR.pacct1
  ,PR.paid1
  ,PR.bal1
  ,PR.pdt2
  ,PR.plg2
  ,PR.pamt2
  ,PR.pacct2
  ,PR.paid2
  ,PR.bal2
  ,PR.pdt3
  ,PR.plg3
  ,PR.pamt3
  ,PR.pacct3
  ,PR.paid3
  ,PR.bal3
  ,PR.pdt4
  ,PR.plg4
  ,PR.pamt4
  ,PR.pacct4
  ,PR.paid4
  ,PR.bal4
 -- ,NVL(PS.TOTAL_PLG_HH_AMT,0) AS TOTAL_PLG_HH_AMT
--  ,NVL(PS.TOTAL_PLG_PAID_HH_AMT,0) AS TOTAL_PLG_PAID_HH_AMT
--  ,NVL(PS.TOTAL_PLG_HH_BALANCE,0) AS TOTAL_PLG_HH_BALANCE
  ,NVL(PSS.TOTAL_PLG_AMT,0) AS PLG_AMT
  ,NVL(PSS.TOTAL_PLG_BALANCE,0) AS PLG_BALANCE
  ,NVL(PSS.TOTAL_PLG_BALANCE,0)/CI.COUNT_ID AS OVERALL_PLG_BALANCE
  ,GI.GDT1 AS LAST_KSM_GFT
  ,GI.RCPT1
  ,GI.GAMT1
  ,GI.MATCH1
  ,GI.CLAIM1
  ,GI.GACCT1
  ,GI.RCPT2
  ,GI.GDT2
  ,GI.GAMT2
  ,GI.MATCH2
  ,GI.CLAIM2
  ,GI.GACCT2
  ,GI.gdt3
  ,GI.rcpt3
  ,GI.gamt3
  ,GI.match3
  ,GI.CLAIM3
  ,GI.gacct3
  ,GI.gdt4
  ,GI.rcpt4
  ,GI.gamt4
  ,GI.match4
  ,GI.CLAIM4
  ,GI.gacct4
  ,CI.COUNT_ID
  ,NVL(TG.TOTAL_GIFT_AMT,0) AS TOTAL_AF_GIFT
  ,NVL(TG.TOTAL_GIFT_AMT,0)/CI.COUNT_ID AS OVERALL_AF_GIFT
 -- ,CYI.COUNT_CY_ID
 -- ,NVL(TG.TOTAL_GIFT_AMT,0)/CYI.COUNT_CY_ID AS CY_AF_GIFT
  --,NVL(TG.TOTAL_HH_GFT_AMT,0) AS TOTAL_AF_HH_GFT
  ,NVL(TKG.TOTAL_GIFT_AMT,0) AS TOTAL_KG_GIFT
  ,NVL(TKG.TOTAL_GIFT_AMT,0)/CI.COUNT_ID AS OVERALL_KG_GIFT
  , GS.cru_cfy
  , GS.cru_pfy1
  , GS.cru_pfy2
  , GS.cru_pfy3
  , GS.cru_pfy4
  , GS.cru_pfy5
FROM ENTITY E
INNER JOIN KSM_REUNION KR
ON E.ID_NUMBER = KR.ID_NUMBER
LEFT JOIN RPT_PBH634.V_ENTITY_KSM_HOUSEHOLDS KHH
ON E.ID_NUMBER = KHH."ID_NUMBER"
LEFT JOIN IDS FAID
ON E.ID_NUMBER = FAID.id_number
  AND FAID.ids_type_code = 'FAS'
LEFT JOIN COUNT_HH_ID CI
ON KHH."HOUSEHOLD_ID" = CI.HOUSEHOLD_ID
LEFT JOIN COUNT_HH_ID_CY CYI
ON KHH."HOUSEHOLD_ID" = CYI.HOUSEHOLD_ID
LEFT JOIN IDS AD
ON E.ID_NUMBER = AD.id_number
  AND AD.ids_type_code = 'KAD'
LEFT JOIN KGF_REWORKED KGFR
  ON E.ID_NUMBER = KGFR.ID
LEFT JOIN PAYFY19 PAY19
  ON E.ID_NUMBER = PAY19.ID
LEFT JOIN GIFT_CLUB GC
  ON E.ID_NUMBER = GC.GIFT_CLUB_ID_NUMBER
LEFT JOIN table(rpt_pbh634.ksm_pkg.tbl_special_handling_concat) SH
ON E.ID_NUMBER = SH.ID_NUMBER
LEFT JOIN KSM_DEGREES KD
ON E.ID_NUMBER = KD."ID_NUMBER"
LEFT JOIN KSM_REUNION SPKR
ON E.SPOUSE_ID_NUMBER = SPKR.ID_NUMBER
LEFT JOIN SPOUSE_KSM SK
ON E.SPOUSE_ID_NUMBER = SK.ID_NUMBER
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
LEFT JOIN EMPLOYMENT EMPL
ON E.ID_NUMBER = EMPL.ID_NUMBER
  AND EMPL.JOB_STATUS_CODE = 'C'
  AND EMPL.PRIMARY_EMP_IND = 'Y'
LEFT JOIN PLEDGE_ROWS PR
  ON E.ID_NUMBER = PR.pledge_donor_id
LEFT JOIN PLEDGE_SUM PSS
 ON E.ID_NUMBER = PSS.pledge_donor_id
LEFT JOIN GIFTINFO GI
  ON E.ID_NUMBER = GI.ID_NUMBER
LEFT JOIN TOTAL_GIFTS TG
  ON E.ID_NUMBER = TG.ID_NUMBER
LEFT JOIN TOTAL_KELLOGG_GIFTS TKG
  ON E.ID_NUMBER = TKG.ID_NUMBER
LEFT JOIN GIVING_SUMMARY GS
  ON GS.ID_NUMBER = E.ID_NUMBER
;
