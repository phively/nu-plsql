create or replace package ksm_pkg_klc is

  -- Author  : ABM1914
  -- Created : 10/12/2023 12:17:20 PM
  -- Purpose : 
  
  -- Public constant declarations
pkg_name constant varchar2(64) := 'ksm_pkg_klc';

  -- Public type declarations
type klc_members_range is Record (
  id_number entity.id_number%type
  ,record_status_code varchar2(64)
  ,fiscal_yr number
  ,tot_kgifts number
  ,segment varchar2(64)
  ,KLC_lev_pfy varchar2(64)
  ,KLC_lev_cfy varchar2(64)
);  

/*************************************************************************
Public table declarations
*************************************************************************/

Type t_klc_members_range Is Table of klc_members_range;


/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

-- Return klc members by fiscal year
Function tbl_klc_members(
  fiscal_year  In number
) Return t_klc_members_range Pipelined; -- pbh634 change
--) Return t_klc_members Pipelined; -- original

Function tbl_klc_members_range(
  fiscal_year In number
  ,fiscal_year2 In number
) Return t_klc_members_range Pipelined;

End ksm_pkg_klc;
/
Create Or Replace Package Body ksm_pkg_klc Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

Cursor c_klc_member_range (fiscal_year_in In number, fiscal_year_in2 In number) Is
WITH 
/*only dates that need to be changed every year to reference
current FY and previous FY8*/
-- You should be able to edit this and it auto pulls everything correctly
fiscal_year AS (
SELECT 
 fiscal_year_in AS START_FY
 ,fiscal_year_in2 AS END_FY
FROM DUAL
)

, manual_dates As (
-- Goal: edit the 4 parameters here, and everything else updates correctly
SELECT
  FY.START_FY  
  ,FY.END_FY  
  ,rpt_pbh634.ksm_pkg_tmp.to_date2('09/01/'|| (FY.START_FY-1),'mm/dd/yyyy') AS CURR_FY_START
  ,rpt_pbh634.ksm_pkg_tmp.to_date2('08/31/'|| FY.END_FY, 'mm/dd/yyyy') AS CURR_FY_END
  ,CC.CURR_FY AS TRUE_CFY
FROM fiscal_year FY
CROSS JOIN RPT_PBH634.V_CURRENT_CALENDAR CC
)

,GIVING_TRANS AS -- Slow subquery
( SELECT GT.* 
  FROM rpt_pbh634.v_ksm_giving_trans GT
)

,GIFT_CLUB AS (
SELECT DISTINCT
  GC.GIFT_CLUB_ID_NUMBER
  ,GC.GIFT_CLUB_END_DATE
  ,RPT_PBH634.KSM_PKG_TMP.get_fiscal_year(GIFT_CLUB_END_DATE) AS FY
  ,GC.GIFT_CLUB_START_DATE
  ,GC.GIFT_CLUB_STATUS
  ,GC.GIFT_CLUB_CODE
  ,GC.GIFT_CLUB_GENERATED_ASGND
FROM GIFT_CLUBS GC
CROSS JOIN MANUAL_DATES
  WHERE GIFT_CLUB_CODE = 'LKM'
    AND GIFT_CLUB_GENERATED_ASGND = ' ' 
    AND (rpt_pbh634.ksm_pkg_tmp.to_date2(GIFT_CLUB_START_DATE,'YYYYMMDD') <= CURR_FY_END
      AND rpt_pbh634.ksm_pkg_tmp.to_date2(GIFT_CLUB_END_DATE,'YYYYMMDD') >= CURR_FY_START) 
UNION
SELECT DISTINCT
  GC.GIFT_CLUB_ID_NUMBER
  ,GC.GIFT_CLUB_END_DATE
  ,RPT_PBH634.KSM_PKG_TMP.get_fiscal_year(GIFT_CLUB_START_DATE) AS FY
  ,GC.GIFT_CLUB_START_DATE
  ,GC.GIFT_CLUB_STATUS
  ,GC.GIFT_CLUB_CODE
  ,GC.GIFT_CLUB_GENERATED_ASGND
FROM GIFT_CLUBS GC
CROSS JOIN MANUAL_DATES
  WHERE GIFT_CLUB_CODE = 'LKM'
    AND GIFT_CLUB_GENERATED_ASGND = ' ' 
    AND (rpt_pbh634.ksm_pkg_tmp.to_date2(GIFT_CLUB_START_DATE,'YYYYMMDD') <= CURR_FY_END
      AND rpt_pbh634.ksm_pkg_tmp.to_date2(GIFT_CLUB_END_DATE,'YYYYMMDD') >= CURR_FY_START) 
)

,KSM_DEGREES AS (
SELECT
ID_NUMBER
,PROGRAM_GROUP AS PROG
,RPT_PBH634.KSM_PKG_TMP.to_number2(FIRST_KSM_YEAR) AS YR
FROM rpt_pbh634.v_entity_ksm_degrees d
)

,CASH_ONLY AS (
   SELECT 
     GT.ID_NUMBER 
     ,GT.TX_NUMBER 
     ,GT.FISCAL_YEAR 
     ,GT.ALLOCATION_CODE
     ,GT.CREDIT_AMOUNT
   FROM GIVING_TRANS GT -- Not using HHID
   CROSS JOIN MANUAL_DATES MD
   WHERE GT.TX_GYPM_IND NOT IN ('P','M')
     AND (GT.AF_FLAG = 'Y' OR GT.CRU_FLAG = 'Y')
     AND GT.FISCAL_YEAR BETWEEN MD.START_FY-1 AND MD.END_FY
)

,MATCHES AS (
   SELECT 
   GT."ID_NUMBER"
   ,GT."MATCHED_TX_NUMBER" RCPT
   ,GT.ALLOCATION_CODE ALLOC
   ,SUM(GT."CREDIT_AMOUNT") MTCH
    FROM GIVING_TRANS GT -- Not using HHID
    CROSS JOIN MANUAL_DATES MD
     WHERE GT.TX_GYPM_IND = 'M'
       AND (GT.AF_FLAG = 'Y' OR GT.CRU_FLAG = 'Y')
       AND GT.MATCHED_FISCAL_YEAR BETWEEN MD.START_FY-1 AND MD.END_FY
   GROUP BY GT."ID_NUMBER", GT."MATCHED_TX_NUMBER", GT.ALLOCATION_CODE
)


,CLAIMS AS (
    SELECT
      GT.ID_NUMBER 
      ,GT."TX_NUMBER" RCPT
      ,GT.ALLOCATION_CODE ALLOC
      ,SUM(MC.CLAIM_AMOUNT) CLAIM
      FROM GIVING_TRANS GT -- Not using HHID
      CROSS JOIN MANUAL_DATES MD
      LEFT JOIN MATCHING_CLAIM MC
        ON GT.TX_NUMBER = MC.CLAIM_GIFT_RECEIPT_NUMBER
        AND GT.ALLOCATION_CODE = MC.ALLOCATION_CODE
      WHERE (GT.AF_FLAG = 'Y' OR GT.CRU_FLAG = 'Y')
        AND GT.FISCAL_YEAR BETWEEN MD.START_FY-1 AND MD.END_FY
      GROUP BY GT.ID_NUMBER, GT.TX_NUMBER, GT.ALLOCATION_CODE
) 

,KGF_REWORKED AS (
    select ID
    ,FY
    ,SUM(AMT) tot_kgifts 
    FROM (
       SELECT 
        HH.ID_NUMBER ID
       ,HH.TX_NUMBER RCPT
       ,HH.FISCAL_YEAR FY
       ,(HH.CREDIT_AMOUNT+ nvl(MTC.mtch,0)+ nvl(clm.claim,0)) AMT 
       FROM CASH_ONLY HH
       CROSS JOIN MANUAL_DATES MD
       LEFT JOIN MATCHES MTC
        ON HH."ID_NUMBER" = MTC.ID_NUMBER 
        AND HH."TX_NUMBER" = MTC.RCPT 
        AND HH.ALLOCATION_CODE = MTC.ALLOC
       LEFT JOIN CLAIMS CLM
        ON HH."ID_NUMBER" = CLM.ID_NUMBER 
        AND HH."TX_NUMBER" = CLM.RCPT
        AND HH."ALLOCATION_CODE" = CLM.ALLOC
        WHERE HH.FISCAL_YEAR BETWEEN MD.START_FY-1 AND MD.END_FY)
     CROSS JOIN MANUAL_DATES MD
      GROUP BY ID, FY
)  

,PAYCFY as (
select plg.id,
    MD.TRUE_CFY,
        sum(plg.prop * sc.payment_schedule_balance) pay,
        sum(case when plg.af = 'Y'
            then plg.prop * sc.payment_schedule_balance else 0 end) payaf         
 from payment_schedule sc
 CROSS JOIN MANUAL_DATES MD,
 (select DISTINCT p.pledge_donor_id ID,
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
 and   (rpt_pbh634.ksm_pkg_tmp.to_date2(sc.payment_schedule_date,'YYYYMMDD') between CURR_FY_START
           and CURR_FY_END)
     AND RPT_PBH634.Ksm_Pkg_Tmp.get_fiscal_year(sc.payment_schedule_date) = TRUE_CFY
 group by plg.id, MD.TRUE_CFY
 ) 
 
,UNION_YRS AS (
 -- actually gave
 SELECT ID AS ID_NUMBER
 , FY
 FROM KGF_REWORKED
 UNION
 -- manual add
 SELECT GIFT_CLUB_ID_NUMBER AS ID_NUMBER
 , FY
 FROM GIFT_CLUB
 UNION
 -- actually gave in FY, add FY+1
 SELECT ID AS ID_NUMBER
 , FY+1 AS FY
 FROM KGF_REWORKED
 --PLEDGE PAYMENT 
 UNION
 SELECT
   id as ID_NUMBER
   ,TRUE_CFY AS FY
 FROM PAYCFY
)

SELECT DISTINCT
  E.ID_NUMBER
  ,E.RECORD_STATUS_CODE
  ,UY.FY AS FISCAL_YR
  ,KGFR.tot_kgifts
  ,CASE WHEN NVL(KGFR.tot_kgifts,0) >=2500 OR
          NVL(KGFR.tot_kgifts,0)+nvl(PCFY.payaf,0) >= 2500 OR
          NVL(KGFRPFY.tot_kgifts,0) >= 2500
       THEN 'Standard KLC Member' 
      WHEN (KD."YR" between UY.FY-5 AND UY.FY
           AND NVL(KGFR.tot_kgifts,0) >= 1000)  OR
           (KD."YR" between UY.FY-6 AND UY.FY AND NVL(KGFRPFY.tot_kgifts,0) >= 1000) THEN 'Recent Grad KLC Member'
      WHEN (KD."YR" between UY.FY-5 AND UY.FY AND
             nvl(KGFR.tot_kgifts,0)+nvl(PCFY.payaf,0) >= 1000) THEN 'Recent Grad KLC Member'
      WHEN E.ID_NUMBER = GC.GIFT_CLUB_ID_NUMBER AND 
       -- (GC.GC_START_FY <= MD.END_FY
        --   AND GC.GC_END_FY >= MD.START_FY) THEN 'Manual Add KLC Member' END AS SEGMENT   
        ((rpt_pbh634.ksm_pkg_tmp.to_date2(GIFT_CLUB_START_DATE,'YYYYMMDD')<= MD.CURR_FY_END
           AND (rpt_pbh634.ksm_pkg_tmp.to_date2(GIFT_CLUB_END_DATE,'YYYYMMDD')>= MD.CURR_FY_START))) THEN 'Manual Add KLC Member' END SEGMENT      
   ,case when nvl(KGFRPFY.tot_kgifts,0) = 0 then ' ' 
            when KGFRPFY.tot_kgifts >= 1000  and KGFRPFY.tot_kgifts < 2500  
                and (KD."YR" between UY.FY-6 AND UY.FY) then ' $1,000-$2,499'
            when KGFRPFY.tot_kgifts >= 2500  and KGFRPFY.tot_kgifts < 5000   then ' $2,500-$4,999'
            when KGFRPFY.tot_kgifts >= 5000  and KGFRPFY.tot_kgifts < 10000  then ' $5,000-$9,999'
            when KGFRPFY.tot_kgifts >= 10000 and KGFRPFY.tot_kgifts < 25000  then '$10,000-$24,999'
            when KGFRPFY.tot_kgifts >= 25000 and KGFRPFY.tot_kgifts < 50000  then '$25,000-$49,999'
            WHEN KGFRPFY.tot_kgifts >= 50000 AND KGFRPFY.tot_kgifts < 100000 THEN '$50,000-$99,999'
            when KGFRPFY.tot_kgifts >= 100000                                 then '$100,000+' 
            else ' ' end        KLC_lev_pfy
    ,case when nvl(KGFR.tot_kgifts,0)+nvl(PCFY.payaf,0)  = 0 then ' ' 
            when nvl(KGFR.tot_kgifts,0)+nvl(PCFY.payaf,0)  >= 1000  and nvl(KGFR.tot_kgifts,0)+nvl(PCFY.payaf,0)  < 2500   
                and (KD."YR" between UY.FY-5 AND UY.FY) then ' $1,000-$2,499'
            when nvl(KGFR.tot_kgifts,0)+nvl(PCFY.payaf,0)  >= 2500  and nvl(KGFR.tot_kgifts,0)+nvl(PCFY.payaf,0)  < 5000  
                                                                               then ' $2,500-$4,999'
            when nvl(KGFR.tot_kgifts,0)+nvl(PCFY.payaf,0)  >= 5000  and nvl(KGFR.tot_kgifts,0)+nvl(PCFY.payaf,0)  < 10000 
                                                                               then ' $5,000-$9,999'
            when nvl(KGFR.tot_kgifts,0)+nvl(PCFY.payaf,0)  >= 10000 and nvl(KGFR.tot_kgifts,0)+nvl(PCFY.payaf,0)  < 25000  
                                                                               then '$10,000-$24,999'
            when nvl(KGFR.tot_kgifts,0)+nvl(PCFY.payaf,0)  >= 25000 and nvl(KGFR.tot_kgifts,0)+nvl(PCFY.payaf,0)  < 50000  
                                                                               then '$25,000-49,999'
             WHEN NVL(KGFR.tot_kgifts,0)+nvl(PCFY.payaf,0)  >= 50000 AND NVL(KGFR.tot_kgifts,0)+nvl(PCFY.payaf,0)  < 100000 THEN '$50,000-$99,999'
            when NVL(KGFR.tot_kgifts,0)+nvl(PCFY.payaf,0)  >= 100000                                 then '$100,000+' 
            else ' ' end                         KLC_lev_cfy 
FROM ENTITY E
-- Add these
INNER JOIN UNION_YRS UY
ON E.ID_NUMBER = UY.ID_NUMBER
CROSS JOIN MANUAL_DATES MD
LEFT JOIN KGF_REWORKED KGFR
ON E.ID_NUMBER = KGFR.ID
    AND KGFR.FY = UY.FY
-- KGFR offset by 1 year
LEFT JOIN KGF_REWORKED KGFRPFY
ON e.ID_NUMBER = KGFRPFY.ID
    AND KGFRPFY.FY = (UY.FY - 1)
LEFT JOIN KSM_DEGREES KD
ON E.ID_NUMBER = KD.ID_NUMBER
LEFT JOIN PAYCFY PCFY
ON E.ID_NUMBER = PCFY.ID
  AND PCFY.TRUE_CFY = UY.FY
LEFT JOIN GIFT_CLUB GC
ON E.ID_NUMBER = GC.GIFT_CLUB_ID_NUMBER
  and GC.FY =  UY.FY
WHERE (E.person_or_org = 'P'
  AND E.record_status_code not in ('I','X')
  AND UY.FY BETWEEN MD.START_FY AND MD.END_FY
  AND ((nvl(KGFR.tot_kgifts,0) >= 2500) or -- Gave $2500 last year
       (nvl(KGFRPFY.tot_kgifts,0) >= 2500) or -- Gave $2500 last-1 year
      (nvl(KGFR.tot_kgifts,0)+nvl(PCFY.payaf,0) >= 2500) or -- Gave $2500 this year, including future pledge payments
      (KD."YR" between UY.FY-6 AND UY.FY -- previous fiscal year young alumni
           AND NVL(KGFRPFY.tot_kgifts,0) >= 1000) OR
      (nvl(KGFRPFY.tot_kgifts,0)+nvl(PCFY.payaf,0) >= 1000 and KD.YR between UY.FY-5 AND UY.FY)OR -- prev FY young alumn
      (KD."YR" between UY.FY-5 AND UY.FY
           AND NVL(KGFR.tot_kgifts,0) >= 1000) OR -- Young alumni
      (nvl(KGFR.tot_kgifts,0)+nvl(PCFY.payaf,0) >= 1000 and KD.YR between UY.FY-5 AND UY.FY)OR -- Young alumni plus future pledge payment
--      (E.ID_NUMBER IN GC.GIFT_CLUB_ID_NUMBER))
      (GC.GIFT_CLUB_ID_NUMBER IS NOT NULL))
  )
;

/*************************************************************************
Functions
*************************************************************************/
-- Return klc members by fiscal year
Function tbl_klc_members(
  fiscal_year  In number
) Return t_klc_members_range Pipelined -- pbh634 change
 As
  -- Declarations
  klc_members t_klc_members_range; -- pbh634 change
  Begin
      Open c_klc_member_range( -- pbh634 change
        fiscal_year_in => fiscal_year
        , fiscal_year_in2 => fiscal_year -- pbh634 change
        );
      Fetch c_klc_member_range Bulk Collect Into klc_members; -- pbh634 change
      For i in 1..klc_members.count Loop
        Pipe row(klc_members(i));
      End Loop;
    Close c_klc_member_range;-- pbh634 change
    Return;
    End;
    
Function tbl_klc_members_range(
  fiscal_year In number
  , fiscal_year2 In number
) Return t_klc_members_range Pipelined
 As
  klc_members_range t_klc_members_range;
  Begin
    Open c_klc_member_range(fiscal_year_in => fiscal_year
      , fiscal_year_in2 => fiscal_year2
    );
    Fetch c_klc_member_range Bulk Collect Into klc_members_range;
    For i in 1..klc_members_range.count Loop
      Pipe row(klc_members_range(i));
    End Loop;
    Close c_klc_member_range;
  Return;
  End;
    
End ksm_pkg_klc;
/
