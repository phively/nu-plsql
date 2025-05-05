CREATE OR REPLACE VIEW  RPT_ABM1914.V_KLC_MEMBERS AS

WITH 
/*only dates that need to be changed every year to reference
current FY and previous FY8*/
manual_dates As (
SELECT
  CURR_FY AS CFY
  ,CURR_FY - 1 AS PFY
  ,CURR_FY_START
  ,NEXT_FY_START-1 AS CURR_FY_END
FROM RPT_PBH634.V_CURRENT_CALENDAR
),

GIVING_TRANS AS -- Slow subquery
( SELECT * 
  FROM rpt_pbh634.v_ksm_giving_trans --WHERE ID_NUMBER IN ('0000414825','0000017911')
)

,GIFT_CLUB AS (
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
)

,GIVING_SUMMARY AS (
SELECT 
  ID_NUMBER
  ,sum(Case When tx_gypm_ind != 'P' And cal.cfy = fiscal_year  And cru_flag = 'Y' Then credit_amount Else 0 End) As cru_cfy
  ,sum(Case When tx_gypm_ind != 'P' And cal.pfy = fiscal_year And cru_flag = 'Y' Then credit_amount Else 0 End) As cru_pfy1
 FROM GIVING_TRANS
 CROSS JOIN MANUAL_DATES CAL
 GROUP BY ID_NUMBER
)
 
/*Helps identify when the entity/spouse graduated and the program they were in.  
Later used to identify if they are standard KLC or recent grad KLC.*/
,KSM_DEGREES AS (
SELECT
ID_NUMBER
,PROG
,RPT_PBH634.KSM_PKG_TMP.to_number2(YR) AS YR
FROM
(select ID_NUMBER, max(prog) prog, max(yr) yr from
((SELECT
   ID_NUMBER
   ,PROGRAM_GROUP AS PROG
   ,RPT_PBH634.KSM_PKG_TMP.to_number2(FIRST_KSM_YEAR) AS YR
 FROM rpt_pbh634.v_entity_ksm_degrees)
 UNION ALL
 (SELECT
   A.ID_NUMBER
   ,RT.SHORT_DESC AS PROG
   ,RPT_PBH634.KSM_PKG_TMP.to_number2(A.CLASS_YEAR) AS YR
   FROM AFFILIATION A
   LEFT JOIN TMS_RECORD_TYPE RT
   ON A.RECORD_TYPE_CODE = RT.record_type_code
   WHERE A.affil_level_code like 'A%'
     and   A.affil_status_code = 'E' 
     and   A.affil_code = 'KM'))
 group by ID_NUMBER)
)

,REUNION_YEAR AS (
  SELECT 
    ID_NUMBER
    ,RPT_PBH634.KSM_PKG_TMP.to_number2(CLASS_YEAR) AS CLASS_YEAR
  FROM AFFILIATION A
  WHERE A.AFFIL_CODE = 'KM'
AND A.AFFIL_LEVEL_CODE = 'RG'
)
  
,KGF_AMOUNTS AS (
  SELECT GT.ID_NUMBER,
         COUNT(GT.TX_NUMBER) KLIFE_GIFTS,
         SUM(GT.CREDIT_AMOUNT) KLIFE_GIV_AMT,
         count(distinct case when FISCAL_YEAR = MD.pfy then GT.TX_NUMBER end)       num_kgifts_pfy,
         count(distinct case when FISCAL_YEAR = MD.cfy then GT.TX_NUMBER end)       num_kgifts_cfy,
         sum(case when FISCAL_YEAR = MD.cfy and AF_FLAG = 'Y' then GT.CREDIT_AMOUNT else 0 end) kaftot_cfy,
            sum(case when FISCAL_YEAR = MD.cfy and AF_FLAG = 'Y' then 1 else 0 end)  kafct_cfy,
            sum(case when FISCAL_YEAR = MD.pfy and AF_FLAG = 'Y' then GT.CREDIT_AMOUNT else 0 end) kaftot_pfy,
            sum(case when FISCAL_YEAR = MD.pfy and AF_FLAG = 'Y' then 1 else 0 end)   kafct_pfy
  From GIVING_TRANS GT
  CROSS JOIN manual_dates MD
  Where tx_gypm_ind NOT IN ('P', 'M')
  GROUP BY ID_NUMBER -- Not using HHID, so could possibly use the non-householded gift_trans
)

/*used later to determine if a person is KLC or not.  Totals come from adding
CREDIT_AMOUNT from rpt_pbh634.v_ksm_giving_trans_hh
Matches and Claims*/
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
     AND GT.FISCAL_YEAR IN (MD.CFY, MD.PFY)
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
       AND GT.MATCHED_FISCAL_YEAR IN (MD.CFY, MD.PFY) 
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
        AND GT.FISCAL_YEAR IN (MD.CFY, MD.PFY)
      GROUP BY GT.ID_NUMBER, GT.TX_NUMBER, GT.ALLOCATION_CODE
)    

,KGF_REWORKED AS (
    select ID
    ,SUM(case when FY =  MD.PFY then AMT else 0 end) tot_kgifts_PFY  
    ,SUM(case when FY =  MD.CFY then AMT else 0 end) tot_kgifts_CFY
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
        WHERE HH.FISCAL_YEAR IN (MD.CFY,MD.PFY))
     CROSS JOIN MANUAL_DATES MD
      GROUP BY ID
)   

,PAYFY20 as
(select plg.id,
        sum(plg.prop * sc.payment_schedule_balance) pay,
        sum(case when plg.af = 'Y'
            then plg.prop * sc.payment_schedule_balance else 0 end) payaf         
 from payment_schedule sc
 CROSS JOIN MANUAL_DATES MD,
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
 and   rpt_pbh634.ksm_pkg_tmp.to_date2(sc.payment_schedule_date,'YYYYMMDD') between MD.CURR_FY_START
           and MD.CURR_FY_END
 group by plg.id) 

,ROWDATA AS(
SELECT
           g.ID_NUMBER
           ,ROW_NUMBER() OVER(PARTITION BY g.ID_NUMBER ORDER BY g.date_of_record DESC)RW
           ,g.credit_amount AS amt
           ,M.CREDIT_AMOUNT AS match
           ,c.claim
           ,g.date_of_record AS dt
           ,g.tx_number AS rcpt
           ,g.alloc_short_name as acct
           ,g.AF_FLAG
           ,g.FISCAL_YEAR
           FROM (SELECT * FROM GIVING_TRANS WHERE TX_GYPM_IND NOT IN ('M', 'P')) G
             LEFT JOIN (SELECT * FROM GIVING_TRANS WHERE TX_GYPM_IND = 'M') m 
                ON g.tx_number = m.matched_tx_number AND g.ID_NUMBER = m.ID_NUMBER -- I think there is a way to just get this from my giving view?
           LEFT JOIN (SELECT 
                KSMT.TX_NUMBER
                ,KSMT.ALLOCATION_CODE
                ,SUM(MC.CLAIM_AMOUNT) CLAIM
            FROM GIVING_TRANS KSMT
            INNER JOIN MATCHING_CLAIM MC
              ON KSMT."TX_NUMBER" = MC.CLAIM_GIFT_RECEIPT_NUMBER
              AND KSMT."TX_SEQUENCE" = MC.CLAIM_GIFT_SEQUENCE
              GROUP BY KSMT.TX_NUMBER, KSMT.ALLOCATION_CODE) C
              ON G.TX_NUMBER = C.TX_NUMBER
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
),
NUGIFT as
 (select g.gift_donor_id ID, 
        sum(g.gift_associated_credit_amt + nvl(mtch.mtch,0) +  nvl(clm.claim,0)) nulife_giv_amt,
        count(distinct g.gift_receipt_number) nulife_gifts
     from gift g,
          allocation al,
               (select g.gift_receipt_number rcpt,         -- only link by rcpt/alloc so all donors get credit
                       g.gift_associated_allocation alloc, -- mg and mc only link to one donor
                       sum(mg.match_gift_amount) mtch                       
                from gift g,
                     matching_gift mg
                where g.gift_receipt_number = mg.match_gift_matched_receipt
                and   g.gift_sequence = mg.match_gift_matched_sequence
                group by g.gift_receipt_number,g.gift_associated_allocation) mtch,
               (select g.gift_receipt_number rcpt,
                       g.gift_associated_allocation alloc,                
                       sum(mc.claim_amount) claim
                from gift g,
                     matching_claim mc
                where g.gift_receipt_number = mc.claim_gift_receipt_number
                and   g.gift_sequence = mc.claim_gift_sequence
                group by g.gift_receipt_number,g.gift_associated_allocation) clm
           where g.gift_associated_allocation = al.allocation_code  
           and   g.gift_receipt_number = mtch.rcpt(+)
           and   g.gift_associated_allocation = mtch.alloc(+)           
           and   g.gift_receipt_number = clm.rcpt(+)
           and   g.gift_associated_allocation = clm.alloc(+)
           group by g.gift_donor_id),

GEO_CODE AS (
Select
  address.id_number
  , address.xsequence
  , addr_type_code
  , gcp.geo_code_primary_desc
From address
Inner Join RPT_PBH634.v_geo_code_primary gcp
  On gcp.id_number = address.id_number
  And gcp.xsequence = address.xsequence
),

PLG AS 
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
),
PLEDGE_ROWS AS
 (select ID,
                 max(decode(rw,1,dt)) last_plg_dt,
                 max(decode(rw,1,stat)) status1,
                 max(decode(rw,1,plg)) plg1,
                 max(decode(rw,1,amt)) pamt1,
                 max(decode(rw,1,acct)) pacct1,
                 max(decode(rw,1,bal)) bal1,
                 max(decode(rw,2,dt)) pdt2,
                 max(decode(rw,2,stat)) status2,
                 max(decode(rw,2,plg)) plg2,
                 max(decode(rw,2,amt)) pamt2,
                 max(decode(rw,2,acct)) pacct2,
                 max(decode(rw,2,bal)) bal2,
                 max(decode(rw,3,dt)) pdt3,
                 max(decode(rw,3,stat)) status3,
                 max(decode(rw,3,plg)) plg3,
                 max(decode(rw,3,amt)) pamt3,
                 max(decode(rw,3,acct)) pacct3,
                 max(decode(rw,3,bal)) bal3,
                 max(decode(rw,4,dt)) pdt4,
                 max(decode(rw,4,stat)) status4,
                 max(decode(rw,4,plg)) plg4,
                 max(decode(rw,4,amt)) pamt4,
                 max(decode(rw,4,acct)) pacct4,
                 max(decode(rw,4,bal)) bal4
          FROM
             (SELECT
                 ID
                 ,ROW_NUMBER() OVER(PARTITION BY ID ORDER BY DT DESC)RW
                 ,DT
                 ,PLG
                 ,AMT
                 ,ACCT
                 ,STAT                                     
                 ,case when (bal * prop) < 0 then 0
                          else round(bal * prop,2) end bal
                FROM 


       (SELECT
                      HH.ID_NUMBER ID
                      ,HH.TX_NUMBER AS PLG
                      ,HH.TRANSACTION_TYPE
                      ,HH.TX_GYPM_IND
                      ,HH.ALLOC_SHORT_NAME AS ACCT
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

,recent_contact AS(
  SELECT
    C.ID_NUMBER
    ,MAX(C.CONTACT_DATE) KEEP (DENSE_RANK FIRST ORDER BY C.CONTACT_DATE DESC) AS CONTACT_DATE
    ,MAX(C.CREDITED_NAME) KEEP (DENSE_RANK FIRST ORDER BY C.CONTACT_DATE DESC) AS CONTACT_AUTHOR
    ,MAX(C.CONTACT_TYPE) KEEP (DENSE_RANK FIRST ORDER BY C.CONTACT_DATE DESC) AS CONTACT_TYPE
    ,MAX(C.DESCRIPTION) KEEP (DENSE_RANK FIRST ORDER BY C.CONTACT_DATE DESC) AS CONTACT_DESCRIPTION
  FROM RPT_PBH634.V_CONTACT_REPORTS_FAST C
  GROUP BY C.ID_NUMBER
)

,prop as
    (SELECT pe.id_number ID,              
           MAX(DECODE(p.rw, 1, p.proposal_id)) prop1_id,
           MAX(DECODE(p.rw, 1, p.initial_contribution_date)) prop1_ask_dt,
           MAX(DECODE(p.rw, 1, p.stop_date)) prop1_close_dt,
           MAX(DECODE(p.rw, 1, p.proposalmanagers)) prop1_managers,
           MAX(DECODE(p.rw, 1, p.ask_amt)) prop1_ask_amt,
           MAX(DECODE(p.rw, 1, p.anticipated_amt)) prop1_antic_commit,
           MAX(DECODE(p.rw, 1, p.status)) prop1_status,
           MAX(DECODE(p.rw, 2, p.proposal_id)) prop2_id,
           MAX(DECODE(p.rw, 2, p.initial_contribution_date)) prop2_ask_dt,
           MAX(DECODE(p.rw, 2, p.stop_date)) prop2_close_dt,
           MAX(DECODE(p.rw, 2, p.proposalmanagers)) prop2_managers,
           MAX(DECODE(p.rw, 2, p.ask_amt)) prop2_ask_amt,
           MAX(DECODE(p.rw, 2, p.anticipated_amt)) prop2_antic_commit,
           MAX(DECODE(p.rw, 2, p.status)) prop2_status
     FROM prospect_entity pe,
     (SELECT row_number() OVER(PARTITION BY pr.prospect_id ORDER BY pr.date_modified desc) rw, 
                  pr.prospect_id,
                  pr.proposal_id,
                  pr.initial_contribution_date,
                  pr.stop_date,
                  pm.proposalmanagers,
                  pr.ask_amt,
                  pr.anticipated_amt,
                  ts.short_desc status,
                  CASE
                    WHEN pr.proposal_title <> ' ' THEN
                     to_char(round(pr.ask_amt), '$999,999,999,999,999') ||
                     ' - ' || pr.proposal_title
                    ELSE
                     to_char(round(pr.ask_amt), '$999,999,999,999,999')
                  END  prop_info
             FROM proposal pr, proposal_purpose pp, tms_proposal_status ts,
            (select proposal_id, LISTAGG(entity.pref_mail_name, ',') WITHIN GROUP (order by entity.pref_mail_name) as proposalmanagers from assignment 
             left outer join entity on entity.id_number = assignment.assignment_id_number
             where assignment.assignment_type = 'PA' and assignment.active_ind ='Y' 
             group by assignment.proposal_id ) pm
            WHERE pr.proposal_id = pp.proposal_id
            and   pr.proposal_status_code = ts.proposal_status_code(+)
            AND   pr.proposal_id = pm.proposal_id(+)
            AND pr.active_ind = 'Y'
            AND pp.program_code = 'KM' -- ~~~~~~~ only KSM proposals ~~~~~
       ) p
    where p.prospect_id = pe.prospect_id 
    GROUP BY pe.id_number)  
    
,KSM_STAFF AS (
SELECT * FROM table(rpt_pbh634.ksm_pkg_tmp.tbl_frontline_ksm_staff) staff -- Historical Kellogg gift officers
  -- Join credited visit ID to staff ID number
  WHERE staff.former_staff Is Null 
)

,LGO AS(
SELECT 
  AH.ID_NUMBER AS ID_NUMBER
  ,AH.report_name AS REPORT_NAME
    ,AH.prospect_id AS PROSPECT_ID
  ,AH.assignment_id_number AS STAFF_ID
  --,ah.assignment_report_name as staff_name
  ,AE.PREF_MAIL_NAME AS STAFF_NAME
FROM rpt_pbh634.v_assignment_history AH
INNER JOIN KSM_STAFF KST
ON AH.assignment_id_number = KST.ID_NUMBER
LEFT JOIN ENTITY AE
ON AH.assignment_id_number = AE.ID_NUMBER
Where ah.assignment_active_calc = 'Active'
  And assignment_type In
      -- Prospect Assist (PP), Prospect Manager (PM), Proposal Manager(PA), Leadership Giving Officer (LG)
      ('LG')   
)
   
SELECT DISTINCT
  E.ID_NUMBER
  ,HH.HOUSEHOLD_ID
  ,HH.HOUSEHOLD_PRIMARY
  ,E.Pref_Mail_Name
  ,KD.YR AS FIRST_KSM_YEAR
  ,RY.CLASS_YEAR AS PREF_GRAD_YR
  ,KD.PROG AS PROGRAM_GROUP
  ,E.SPOUSE_ID_NUMBER
  ,SP.PREF_MAIL_NAME AS SPOUSE_PREF_MAIL_NAME
  ,SALUTATION_LAST(E.ID_NUMBER,
                       DECODE(TRIM(E.PREF_MAIL_NAME),
                              NULL, ' ',
                              E.SPOUSE_ID_NUMBER)) SALUTATION
  ,WT0_PKG.GetSalutationFirst(E.ID_NUMBER,
                                  DECODE(TRIM(E.PREF_MAIL_NAME),
                                         NULL, ' ',
                                         E.SPOUSE_ID_NUMBER), 'KM') FIRST_NAME_DEANS
  ,SALUTATION_FIRST(E.ID_NUMBER,
                        DECODE(TRIM(E.PREF_MAIL_NAME),
                               NULL, ' ',
                               E.SPOUSE_ID_NUMBER)) FIRST_NAME_SAL
  ,WT0_PKG.GetDeansSal(E.ID_NUMBER, 'KM') DEANS_SAL_1
  ,WT0_PKG.GetDeansSal(E.SPOUSE_ID_NUMBER, 'KM') DEANS_SAL_2
 -- ,SALUTATION_FIRST(E.ID_NUMBER,
  --                      DECODE(TRIM(E.PREF_MAIL_NAME),
   --                            NULL, ' ')) FIRST_NAME_SAL
  ,SKD."FIRST_KSM_YEAR" AS SPOUSE_KSM_YR
  ,SKD."PROGRAM_GROUP" AS SPOUSE_KSM_PROG
  ,case when exists
           (select c.id_number
            from committee c
            where c.id_number = e.id_number
            and   c.committee_code = 'U'
            and   c.committee_status_code in ('A','C'))            
              then 'Y'
              else case when exists
           (select c.id_number
            from committee c
            where c.id_number = e.spouse_id_number
            and   c.committee_code = 'U'
            and   c.committee_status_code in ('A','C'))   
              then 'S' else ' ' end  end GAB,
        case when exists
         (select af.id_number 
          from affiliation af
          where af.id_number = e.id_number 
          and   af.affil_code = 'TR' and af.affil_status_code = 'C')
              then 'Y' else
          case when exists    
         (select af.id_number 
          from affiliation af
          where af.id_number = e.spouse_id_number 
          and   af.affil_code = 'TR' and af.affil_status_code = 'C')
               then 'S' else ' ' end end trustee,
       case when exists
           (select c.id_number
            from committee c
            where c.id_number = e.id_number
            and   c.committee_code = 'PHS'
            and   c.committee_status_code in ('A','C'))            
              then 'Y'
              else case when exists
           (select c.id_number
            from committee c
            where c.id_number = e.spouse_id_number
            and   c.committee_code = 'PHS'
            and   c.committee_status_code in ('A','C'))   
              then 'S' else ' ' end  end PHS,
       case when exists
           (select c.id_number
            from committee c
            where c.id_number = e.id_number
            and   c.committee_code = 'KACNA'
            and   c.committee_status_code in ('A','C'))            
              then 'Y'
              else case when exists
           (select c.id_number
            from committee c
            where c.id_number = e.spouse_id_number
            and   c.committee_code = 'KACNA'
            and   c.committee_status_code in ('A','C'))   
              then 'S' else ' ' end  end KAC
   ,case when nvl(KGFR.tot_kgifts_pfy,0) >= 2500 or
                (nvl(KGFR.tot_kgifts_cfy,0)+nvl(pay20.payaf,0) >= 2500)
            then 'Standard KLC Member'
         when (KD."YR" between '2017' and '2022' OR  KD.PROG = 'Student') AND 
             nvl(KGFR.tot_kgifts_pfy,0) >= 1000 THEN 'Recent Grad KLC Member'
         WHEN (KD."YR" between '2018' and '2023' OR  KD.PROG = 'Student') AND
             nvl(KGFR.tot_kgifts_cfy,0) >= 1000 THEN 'Recent Grad KLC Member'
         WHEN E.ID_NUMBER = GC.GIFT_CLUB_ID_NUMBER THEN 'Manual Add KLC Member'
            end segment
   ,case when nvl(KGFR.tot_kgifts_pfy,0) = 0 then ' ' 
            when KGFR.tot_kgifts_pfy >= 1000  and KGFR.tot_kgifts_pfy < 2500  
                and (KD."YR" between '2017' and '2022' OR KD.PROG = 'Student') then ' $1,000-$2,499'
            when KGFR.tot_kgifts_pfy >= 2500  and KGFR.tot_kgifts_pfy < 5000   then ' $2,500-$4,999'
            when KGFR.tot_kgifts_pfy >= 5000  and KGFR.tot_kgifts_pfy < 10000  then ' $5,000-$9,999'
            when KGFR.tot_kgifts_pfy >= 10000 and KGFR.tot_kgifts_pfy < 25000  then '$10,000-$24,999'
            when KGFR.tot_kgifts_pfy >= 25000 and KGFR.tot_kgifts_pfy < 50000  then '$25,000-$49,999'
            WHEN KGFR.TOT_KGIFTS_PFY >= 50000 AND KGFR.TOT_KGIFTS_PFY < 100000 THEN '$50,000-$99,999'
            when KGFR.tot_kgifts_pfy >= 100000                                 then '$100,000+' 
            else ' ' end        KLC_lev_pfy
   ,case when nvl(KGFR.tot_kgifts_cfy,0) = 0 then ' ' 
            when nvl(KGFR.tot_kgifts_cfy,0) >= 1000  and nvl(KGFR.tot_kgifts_cfy,0) < 2500   
                and (KD."YR" between '2018' and '2023' OR KD.PROG = 'Student') then ' $1,000-$2,499'
            when nvl(KGFR.tot_kgifts_cfy,0) >= 2500  and nvl(KGFR.tot_kgifts_cfy,0) < 5000  
                                                                               then ' $2,500-$4,999'
            when nvl(KGFR.tot_kgifts_cfy,0) >= 5000  and nvl(KGFR.tot_kgifts_cfy,0) < 10000 
                                                                               then ' $5,000-$9,999'
            when nvl(KGFR.tot_kgifts_cfy,0) >= 10000 and nvl(KGFR.tot_kgifts_cfy,0) < 25000  
                                                                               then '$10,000-$24,999'
            when nvl(KGFR.tot_kgifts_cfy,0) >= 25000 and nvl(KGFR.tot_kgifts_cfy,0) < 50000  
                                                                               then '$25,000-49,999'
             WHEN KGFR.tot_kgifts_cfy >= 50000 AND KGFR.tot_kgifts_cfy < 100000 THEN '$50,000-$99,999'
            when KGFR.tot_kgifts_cfy >= 100000                                 then '$100,000+' 
            else ' ' end                         KLC_lev_cfy
   
 ,GC.geo_code_primary_desc
   ,E.JNT_MAILINGS_IND
   ,ADT.short_desc AS ADDR_TYPE
   ,AD.COMPANY_NAME_1
   ,AD.COMPANY_NAME_2
   ,AD.STREET1
   ,AD.STREET2
   ,AD.STREET3
   ,AD.CITY
   ,AD.STATE_CODE AS STATE
   ,AD.ZIPCODE AS ZIP
   ,AD.COUNTRY_CODE AS COUNTRY
   ,CON.continent
   ,KGF.num_kgifts_PFY
   ,KGFR.tot_kgifts_PFY
   ,GS.CRU_PFY1 -- Compute this from v_ksm_giving_trans
   ,KGF.num_kgifts_CFY
   ,KGFR.tot_kgifts_CFY
   ,GS.CRU_CFY
   ,pay20.pay expected_payments_cfy
   ,pay20.payaf CFY_exp_af
   ,KGF.KAFCT_pfy
   ,KGF.KAFTOT_pfy
   ,KGF.KAFCT_cfy
   ,KGF.KAFTOT_cfy
   ,GI.GDT1 AS LAST_KSM_GFT
   ,GI.GAMT1
   ,GI.MATCH1
   ,GI.CLAIM1
   ,GI.GACCT1   
   ,GI.GDT2
   ,GI.GAMT2
   ,GI.MATCH2
   ,GI.CLAIM2
   ,GI.GACCT2
   ,GI.gdt3
   ,GI.gamt3
   ,GI.match3
   ,GI.CLAIM3
   ,GI.gacct3
   ,GI.gdt4
   ,GI.gamt4
   ,GI.match4
   ,GI.CLAIM4
   ,GI.gacct4
   ,P.KSM_PLEDGES
   ,P.KSM_PLG_TOT 
   ,PR.last_plg_dt
   ,PR.status1
   ,PR.plg1
   ,PR. pamt1
   ,PR.pacct1
   ,PR.bal1
   ,PR.pdt2
   ,PR.status2
   ,PR.plg2
   ,PR.pamt2
   ,PR.pacct2
   ,PR.bal2
   ,PR.pdt3
   ,PR.status3
   ,PR.plg3
   ,PR.pamt3
   ,PR.pacct3
   ,PR.bal3
   ,PR.pdt4
   ,PR.status4
   ,PR.plg4
   ,PR.pamt4
   ,PR.pacct4
   ,PR.bal4
   ,RC.CONTACT_DATE
   ,RC.CONTACT_AUTHOR
   ,RC.CONTACT_TYPE
   ,RC.CONTACT_DESCRIPTION
   ,prop.prop1_ask_dt
   ,prop.prop1_close_dt
   ,prop.prop1_managers
   ,prop.prop1_ask_amt
   ,prop.prop1_antic_commit
   ,prop.prop1_status     
   ,prop.prop2_ask_dt
   ,prop.prop2_close_dt
   ,prop.prop2_managers
   ,prop.prop2_ask_amt
   ,prop.prop2_antic_commit
   ,prop.prop2_status 
   ,pros.Prospect_Manager
   ,L.STAFF_NAME AS LGO
   ,E.REPORT_NAME AS SORTNAME
FROM ENTITY E
CROSS JOIN MANUAL_DATES MD
  LEFT JOIN RPT_PBH634.V_ENTITY_KSM_HOUSEHOLDS HH
  ON E.ID_NUMBER = HH.ID_NUMBER
  LEFT JOIN KSM_DEGREES KD
  ON E.ID_NUMBER = KD.ID_NUMBER
  LEFT JOIN ENTITY SP
  ON E.SPOUSE_ID_NUMBER = SP.ID_NUMBER
  LEFT JOIN rpt_pbh634.v_entity_ksm_degrees SKD
  ON SP.ID_NUMBER = SKD."ID_NUMBER"
  LEFT JOIN REUNION_YEAR RY
  ON E.ID_NUMBER = RY.ID_NUMBER
  LEFT JOIN KGF_AMOUNTS KGF
  ON E.ID_NUMBER = KGF.ID_NUMBER
  LEFT JOIN KGF_REWORKED KGFR
  ON E.ID_NUMBER = KGFR.ID
  LEFT JOIN GIVING_SUMMARY GS
  ON E.ID_NUMBER = GS.ID_NUMBER
  LEFT JOIN PAYFY20 PAY20
  ON E.ID_NUMBER = PAY20.ID
  LEFT JOIN NUGIFT NUG
  ON E.ID_NUMBER = NUG.ID
  LEFT JOIN ADDRESS AD
  ON E.ID_NUMBER = AD.ID_NUMBER
     AND AD.ADDR_PREF_IND = 'Y'
     AND AD.ADDR_STATUS_CODE = 'A'
  LEFT JOIN GEO_CODE GC
  ON AD.ID_NUMBER = GC.ID_NUMBER
    AND AD.XSEQUENCE = GC.XSEQUENCE
  LEFT JOIN TMS_ADDRESS_TYPE ADT
  ON AD.ADDR_TYPE_CODE = ADT.addr_type_code
  LEFT JOIN RPT_PBH634.V_ADDR_CONTINENTS CON
  ON AD.COUNTRY_CODE = CON.country_code
  LEFT JOIN GIFTINFO GI
  ON E.ID_NUMBER = GI.ID_NUMBER
  LEFT JOIN PLG P
  ON E.ID_NUMBER = P.ID_NUMBER
  LEFT JOIN PLEDGE_ROWS PR
  ON E.ID_NUMBER = PR.ID
  LEFT JOIN RECENT_CONTACT RC
  ON E.ID_NUMBER = RC.ID_NUMBER
  LEFT JOIN PROP
  ON E.ID_NUMBER = PROP.ID
  LEFT JOIN nu_prs_trp_prospect PROS
  ON E.ID_NUMBER = PROS.ID_NUMBER
  LEFT JOIN GIFT_CLUB GC
  ON E.ID_NUMBER = GC.GIFT_CLUB_ID_NUMBER
  LEFT JOIN LGO L
  ON E.ID_NUMBER = L.ID_NUMBER
WHERE (E.person_or_org = 'P'
  AND E.record_status_code not in ('I','X','D') -- No inactive, purgable, or deceased
  AND ((nvl(KGFR.tot_kgifts_PFY,0) >= 2500) or -- Gave $2500 last year
      (nvl(KGFR.tot_kgifts_CFY,0) >= 2500) or -- Gave $2500 this year, including future pledge payments
      (nvl(KGFR.tot_kgifts_PFY,0)>= 1000 AND KD.YR BETWEEN MD.PFY-5 AND MD.PFY) OR -- Young alumni
      (nvl(KGFR.tot_kgifts_PFY,0)>= 1000 AND KD.PROG = 'Student')OR -- Current students
      (nvl(KGFR.tot_kgifts_CFY,0) >= 1000 and KD.YR between MD.CFY-5 and MD.CFY)OR -- Young alumni plus future pledge payment
      (nvl(KGFR.tot_kgifts_CFY,0) >= 1000 AND KD.PROG = 'Student')))
  OR (E.ID_NUMBER IN GC.GIFT_CLUB_ID_NUMBER) -- Current students plus future payments
ORDER BY SEGMENT, e.report_name
