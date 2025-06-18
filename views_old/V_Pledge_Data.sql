CREATE OR REPLACE VIEW RPT_ABM1914.V_PLEDGE_DATA AS

WITH
tms_trans As (
  (
    Select
      transaction_type_code
      , short_desc As transaction_type
    From tms_transaction_type
  ) Union All (
    Select
      pledge_type_code
      , short_desc
    From tms_pledge_type
  )
)

,ksm_af_allocs As (
  Select
    allocation_code
    , af_flag
  From table(rpt_pbh634.ksm_pkg_tmp.tbl_alloc_curr_use_ksm)
)


, ksm_pledges As (
  Select Distinct
    pledge.pledge_pledge_number
  From pledge
  Inner Join primary_pledge
    On primary_pledge.prim_pledge_number = pledge.pledge_pledge_number
  Left Join ksm_af_allocs
    On ksm_af_allocs.allocation_code = pledge.pledge_allocation_name
  Where --primary_pledge.prim_pledge_status = 'A'
   -- And (
      (ksm_af_allocs.allocation_code Is Not Null
      Or (
      -- KSM program code
       -- pledge_allocation_name In ('BE', 'LE') -- BE and LE discounted amounts
       -- And 
        pledge_program_code = 'KM'
      )
    )
)
, ksm_payments As (
  Select
    gft.tx_number
    , gft.tx_sequence
    , gft.pmt_on_pledge_number
    , gft.allocation_code
    ,gft.Alloc_Short_Name
    , gft.date_of_record
    , gft.legal_amount
  From nu_gft_trp_gifttrans gft
 -- Inner Join ksm_af_allocs
   -- On ksm_af_allocs.allocation_code = gft.allocation_code
  Inner Join ksm_pledges
    On ksm_pledges.pledge_pledge_number = gft.pmt_on_pledge_number
  Where gft.legal_amount > 0
  Order By
    pmt_on_pledge_number Asc
    , date_of_record Desc
)
, pledge_counts As (
  Select
    pledge.pledge_pledge_number
    ,pledge.pledge_allocation_name
    , max(plgd.prim_pledge_remaining_balance) As pledge_balance
    , sum(pledge.pledge_amount)
      As pledge_total
    , sum(Case When allocation.alloc_school = 'KM' Then pledge.pledge_amount Else 0 End)
      As pledge_total_ksm
    , count(Distinct pledge.pledge_allocation_name)
      As pledge_allocs
    , count(Distinct pledge.pledge_donor_id) - 1 -- Subtract 1 for the legal donor
      As pledge_addl_donors
  From pledge
  Inner Join ksm_pledges
    On ksm_pledges.pledge_pledge_number = pledge.pledge_pledge_number
  Inner Join allocation
    On allocation.allocation_code = pledge.pledge_allocation_name
  Inner Join table(RPT_PBH634.ksm_pkg_tmp.plg_discount) plgd
    On plgd.pledge_number = pledge.pledge_pledge_number
      AND plgd.pledge_sequence = pledge.pledge_sequence
  Group By pledge.pledge_pledge_number,pledge.pledge_allocation_name
)
, pay_sch As (
    Select
    ksm_pledges.pledge_pledge_number
    , psched.payment_schedule_status
    , psched.payment_schedule_date
    , rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(rpt_pbh634.ksm_pkg_tmp.to_date2(psched.payment_schedule_date, 'YYYYMMDD'))
      As pay_sch_fy
    --ADDED CASE TO USE MATERIALIZED VIEW FOR SPECIAL EXCEPTIONS REGARDING CUSTOM PAYMENT SCHEDULES
    , CASE WHEN KSM_PLEDGES.PLEDGE_PLEDGE_NUMBER IN (SELECT PLEDGE_NUMBER FROM RPT_ABM1914.MV_KSM_PLEDGE_PAY) THEN MV_PLG.AMOUNT 
         ELSE psched.payment_schedule_amount END AS PAYMENT_SCHEDULE_AMOUNT
    , psched.payment_schedule_balance
  From payment_schedule psched
  Inner Join ksm_pledges
    On ksm_pledges.pledge_pledge_number = psched.payment_schedule_pledge_nbr
  LEFT JOIN rpt_abm1914.mv_ksm_pledge_pay MV_PLG
    ON KSM_PLEDGES.PLEDGE_PLEDGE_NUMBER = MV_PLG.PLEDGE_NUMBER
    AND rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(rpt_pbh634.ksm_pkg_tmp.to_date2(psched.payment_schedule_date, 'YYYYMMDD')) = MV_PLG.FISCAL_YEAR
)


--Counts of Payments on Pledges
,Count_Payments AS (
  SELECT DISTINCT
    PS.PLEDGE_PLEDGE_NUMBER
    ,COUNT(PS.PAYMENT_SCHEDULE_DATE) AS PAYMENTS_TO_DATE
  FROM PAY_SCH PS
    WHERE PS.PAYMENT_SCHEDULE_STATUS = 'P'
    GROUP BY PS.PLEDGE_PLEDGE_NUMBER
)

--LAST_PAYMENT_INFO
,LAST_PAYMENTS AS (
    SELECT DISTINCT
      PMT_ON_PLEDGE_NUMBER
      ,ALLOCATION_CODE
      ,MAX(DATE_OF_RECORD) AS LAST_PAYMENT_DATE
      ,MAX(legal_amount) KEEP(DENSE_RANK FIRST ORDER BY DATE_OF_RECORD DESC) LAST_PAYMENT
    FROM ksm_payments
    GROUP BY PMT_ON_PLEDGE_NUMBER
      ,ALLOCATION_CODE
     
)

, plg As (
  Select
    p.pledge_donor_id As id
    , pp.prim_pledge_number As plg
    , pp.prim_pledge_amount_paid
    , pp.prim_pledge_original_amount
    , pp.prim_pledge_comment
    , p.pledge_allocation_name As alloc
    , AL.SHORT_NAME AS alloc_short_name
    , al.annual_sw As af
    ,CASE WHEN PP.PRIM_PLEDGE_AMOUNT = 0 THEN 0 ELSE  p.pledge_associated_credit_amt / pp.prim_pledge_amount
     END As prop
  From primary_pledge pp  
  Inner Join pledge p
    On p.pledge_pledge_number = pp.prim_pledge_number
  Inner Join allocation al
    On al.allocation_code = p.pledge_allocation_name
  Where al.alloc_school = 'KM'
    --And pp.prim_pledge_status = 'A'
)

--Next Payment Info
,NEXT_PAYMENT AS (
    SELECT
    plg.id
    ,PS.PLEDGE_PLEDGE_NUMBER
    ,plg.alloc
    ,MIN(PS.PAYMENT_SCHEDULE_DATE) AS NEXT_PAYMENT_DATE
    ,MIN(rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(rpt_pbh634.ksm_pkg_tmp.to_date2(ps.payment_schedule_date, 'YYYYMMDD')))AS NEXT_PAY_FY
    --changed this to split the amount owed to each allocation
    ,CASE WHEN PS.PLEDGE_PLEDGE_NUMBER IN (SELECT PLEDGE_NUMBER FROM RPT_ABM1914.MV_KSM_PLEDGE_PAY) 
         THEN MIN(MV_PLG.AMOUNT) KEEP(DENSE_RANK FIRST ORDER BY MV_PLG.FISCAL_YEAR ASC)
         ELSE MIN(plg.prop*PS.PAYMENT_SCHEDULE_AMOUNT) KEEP(DENSE_RANK FIRST ORDER BY PAYMENT_SCHEDULE_DATE ASC) END AS NEXT_PAYMENT_AMOUNT
   -- ,MIN(plg.prop*PS.PAYMENT_SCHEDULE_AMOUNT) KEEP(DENSE_RANK FIRST ORDER BY PAYMENT_SCHEDULE_DATE ASC) NEXT_PAYMENT_AMOUNT
  FROM PAY_SCH PS
   INNER JOIN PLG 
   ON PS.pledge_pledge_number = PLG.PLG
   LEFT JOIN rpt_abm1914.mv_ksm_pledge_pay MV_PLG
    ON PS.PLEDGE_PLEDGE_NUMBER = MV_PLG.PLEDGE_NUMBER
    AND rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(rpt_pbh634.ksm_pkg_tmp.to_date2(ps.payment_schedule_date, 'YYYYMMDD')) = MV_PLG.FISCAL_YEAR
   WHERE PS.PAYMENT_SCHEDULE_STATUS = 'U'
   GROUP BY plg.id,PS.PLEDGE_PLEDGE_NUMBER,plg.alloc
)

,PLEDGE_BAL AS (
  SELECT
    PC.PLEDGE_PLEDGE_NUMBER
    ,PC.PLEDGE_ALLOCATION_NAME
    ,MIN(PLG.PROP*PC.PLEDGE_BALANCE) AS NEW_PLEDGE_BALANCE
  FROM PLEDGE_COUNTS PC
  INNER JOIN PLG 
  ON PC.pledge_pledge_number = PLG.plg 
    AND PC.pledge_allocation_name = PLG.alloc
  GROUP BY PC.PLEDGE_PLEDGE_NUMBER
    ,PC.PLEDGE_ALLOCATION_NAME
)

,CFY_BAL AS (
  SELECT 
    PLG.ID
    ,PS.PLEDGE_PLEDGE_NUMBER
    ,PLG.ALLOC
    ,MIN(rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(rpt_pbh634.ksm_pkg_tmp.to_date2(ps.payment_schedule_date, 'YYYYMMDD')))AS NFY_PAY
    ,CASE WHEN PS.PLEDGE_PLEDGE_NUMBER IN (SELECT PLEDGE_NUMBER FROM RPT_ABM1914.MV_KSM_PLEDGE_PAY) 
         THEN MIN(MV_PLG.AMOUNT) KEEP(DENSE_RANK FIRST ORDER BY MV_PLG.FISCAL_YEAR ASC)
         ELSE sum(plg.prop * PS.payment_schedule_balance) --Else 0 End)
      END As balance_cfy
  FROM PAY_SCH PS
  INNER JOIN RPT_PBH634.v_Current_Calendar CAL
    ON rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(rpt_pbh634.ksm_pkg_tmp.to_date2(ps.payment_schedule_date, 'YYYYMMDD'))= CAL."CURR_FY"
   INNER JOIN PLG 
   ON PS.pledge_pledge_number = PLG.PLG
   LEFT JOIN rpt_abm1914.mv_ksm_pledge_pay MV_PLG
    ON PS.PLEDGE_PLEDGE_NUMBER = MV_PLG.PLEDGE_NUMBER
    AND MV_PLG.FISCAL_YEAR = CAL."CURR_FY"
   WHERE PS.PAYMENT_SCHEDULE_STATUS = 'U'
   GROUP BY plg.id,PS.PLEDGE_PLEDGE_NUMBER,plg.alloc
)

,NFY_BAL AS (
   SELECT 
    PLG.ID
    ,PS.PLEDGE_PLEDGE_NUMBER
    ,PLG.ALLOC
    ,MIN(rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(rpt_pbh634.ksm_pkg_tmp.to_date2(ps.payment_schedule_date, 'YYYYMMDD')))AS NFY_PAY
    ,CASE WHEN PS.PLEDGE_PLEDGE_NUMBER IN (SELECT PLEDGE_NUMBER FROM RPT_ABM1914.MV_KSM_PLEDGE_PAY) 
         THEN MIN(MV_PLG.AMOUNT) KEEP(DENSE_RANK FIRST ORDER BY MV_PLG.FISCAL_YEAR ASC)
         ELSE sum(plg.prop * PS.payment_schedule_balance) --Else 0 End)
      END As balance_nfy
  FROM PAY_SCH PS
  INNER JOIN RPT_PBH634.v_Current_Calendar CAL
    ON rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(rpt_pbh634.ksm_pkg_tmp.to_date2(ps.payment_schedule_date, 'YYYYMMDD'))= CAL."CURR_FY"+1
   INNER JOIN PLG 
   ON PS.pledge_pledge_number = PLG.PLG
   LEFT JOIN rpt_abm1914.mv_ksm_pledge_pay MV_PLG
    ON PS.PLEDGE_PLEDGE_NUMBER = MV_PLG.PLEDGE_NUMBER
    AND MV_PLG.FISCAL_YEAR = CAL."CURR_FY"+1
   WHERE PS.PAYMENT_SCHEDULE_STATUS = 'U'
   GROUP BY plg.id,PS.PLEDGE_PLEDGE_NUMBER,plg.alloc
)

,NFY_BAL1 AS (
   SELECT 
    PLG.ID
    ,PS.PLEDGE_PLEDGE_NUMBER
    ,PLG.ALLOC
    ,MIN(rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(rpt_pbh634.ksm_pkg_tmp.to_date2(ps.payment_schedule_date, 'YYYYMMDD')))AS NFY_PAY
    ,CASE WHEN PS.PLEDGE_PLEDGE_NUMBER IN (SELECT PLEDGE_NUMBER FROM RPT_ABM1914.MV_KSM_PLEDGE_PAY) 
         THEN MIN(MV_PLG.AMOUNT) KEEP(DENSE_RANK FIRST ORDER BY MV_PLG.FISCAL_YEAR ASC)
         ELSE sum(plg.prop * PS.payment_schedule_balance) --Else 0 End)
      END As balance_nfy1
  FROM PAY_SCH PS
  INNER JOIN RPT_PBH634.v_Current_Calendar CAL
    ON rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(rpt_pbh634.ksm_pkg_tmp.to_date2(ps.payment_schedule_date, 'YYYYMMDD'))= CAL."CURR_FY"+2
   INNER JOIN PLG 
   ON PS.pledge_pledge_number = PLG.PLG
   LEFT JOIN rpt_abm1914.mv_ksm_pledge_pay MV_PLG
    ON PS.PLEDGE_PLEDGE_NUMBER = MV_PLG.PLEDGE_NUMBER
    AND MV_PLG.FISCAL_YEAR = CAL."CURR_FY"+2
   WHERE PS.PAYMENT_SCHEDULE_STATUS = 'U'
   GROUP BY plg.id,PS.PLEDGE_PLEDGE_NUMBER,plg.alloc
)

,NFY_BAL2 AS (
   SELECT 
    PLG.ID
    ,PS.PLEDGE_PLEDGE_NUMBER
    ,PLG.ALLOC
    ,MIN(rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(rpt_pbh634.ksm_pkg_tmp.to_date2(ps.payment_schedule_date, 'YYYYMMDD')))AS NFY_PAY
    ,CASE WHEN PS.PLEDGE_PLEDGE_NUMBER IN (SELECT PLEDGE_NUMBER FROM RPT_ABM1914.MV_KSM_PLEDGE_PAY) 
         THEN MIN(MV_PLG.AMOUNT) KEEP(DENSE_RANK FIRST ORDER BY MV_PLG.FISCAL_YEAR ASC)
         ELSE sum(plg.prop * PS.payment_schedule_balance) --Else 0 End)
      END As balance_nfy2
  FROM PAY_SCH PS
  INNER JOIN RPT_PBH634.v_Current_Calendar CAL
    ON rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(rpt_pbh634.ksm_pkg_tmp.to_date2(ps.payment_schedule_date, 'YYYYMMDD'))= CAL."CURR_FY"+3
   INNER JOIN PLG 
   ON PS.pledge_pledge_number = PLG.PLG
   LEFT JOIN rpt_abm1914.mv_ksm_pledge_pay MV_PLG
    ON PS.PLEDGE_PLEDGE_NUMBER = MV_PLG.PLEDGE_NUMBER
    AND MV_PLG.FISCAL_YEAR = CAL."CURR_FY"+3
   WHERE PS.PAYMENT_SCHEDULE_STATUS = 'U'
   GROUP BY plg.id,PS.PLEDGE_PLEDGE_NUMBER,plg.alloc
)

,NFY_BAL3 AS (
   SELECT 
    PLG.ID
    ,PS.PLEDGE_PLEDGE_NUMBER
    ,PLG.ALLOC
    ,MIN(rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(rpt_pbh634.ksm_pkg_tmp.to_date2(ps.payment_schedule_date, 'YYYYMMDD')))AS NFY_PAY
    ,CASE WHEN PS.PLEDGE_PLEDGE_NUMBER IN (SELECT PLEDGE_NUMBER FROM RPT_ABM1914.MV_KSM_PLEDGE_PAY) 
         THEN MIN(MV_PLG.AMOUNT) KEEP(DENSE_RANK FIRST ORDER BY MV_PLG.FISCAL_YEAR ASC)
         ELSE sum(plg.prop * PS.payment_schedule_balance) --Else 0 End)
      END As balance_nfy3
  FROM PAY_SCH PS
  INNER JOIN RPT_PBH634.v_Current_Calendar CAL
    ON rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(rpt_pbh634.ksm_pkg_tmp.to_date2(ps.payment_schedule_date, 'YYYYMMDD'))= CAL."CURR_FY"+4
   INNER JOIN PLG 
   ON PS.pledge_pledge_number = PLG.PLG
   LEFT JOIN rpt_abm1914.mv_ksm_pledge_pay MV_PLG
    ON PS.PLEDGE_PLEDGE_NUMBER = MV_PLG.PLEDGE_NUMBER
    AND MV_PLG.FISCAL_YEAR = CAL."CURR_FY"+4
   WHERE PS.PAYMENT_SCHEDULE_STATUS = 'U'
   GROUP BY plg.id,PS.PLEDGE_PLEDGE_NUMBER,plg.alloc
)

,NFY_BAL4 AS (
   SELECT 
    PLG.ID
    ,PS.PLEDGE_PLEDGE_NUMBER
    ,PLG.ALLOC
    ,MIN(rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(rpt_pbh634.ksm_pkg_tmp.to_date2(ps.payment_schedule_date, 'YYYYMMDD')))AS NFY_PAY
    ,CASE WHEN PS.PLEDGE_PLEDGE_NUMBER IN (SELECT PLEDGE_NUMBER FROM RPT_ABM1914.MV_KSM_PLEDGE_PAY) 
         THEN MIN(MV_PLG.AMOUNT) KEEP(DENSE_RANK FIRST ORDER BY MV_PLG.FISCAL_YEAR ASC)
         ELSE sum(plg.prop * PS.payment_schedule_balance) --Else 0 End)
      END As balance_nfy4
  FROM PAY_SCH PS
  INNER JOIN RPT_PBH634.v_Current_Calendar CAL
    ON rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(rpt_pbh634.ksm_pkg_tmp.to_date2(ps.payment_schedule_date, 'YYYYMMDD'))= CAL."CURR_FY"+5
   INNER JOIN PLG 
   ON PS.pledge_pledge_number = PLG.PLG
   LEFT JOIN rpt_abm1914.mv_ksm_pledge_pay MV_PLG
    ON PS.PLEDGE_PLEDGE_NUMBER = MV_PLG.PLEDGE_NUMBER
    AND MV_PLG.FISCAL_YEAR = CAL."CURR_FY"+5
   WHERE PS.PAYMENT_SCHEDULE_STATUS = 'U'
   GROUP BY plg.id,PS.PLEDGE_PLEDGE_NUMBER,plg.alloc
)

,NFY_BAL5 AS (
   SELECT 
    PLG.ID
    ,PS.PLEDGE_PLEDGE_NUMBER
    ,PLG.ALLOC
    ,MIN(rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(rpt_pbh634.ksm_pkg_tmp.to_date2(ps.payment_schedule_date, 'YYYYMMDD')))AS NFY_PAY
    ,CASE WHEN PS.PLEDGE_PLEDGE_NUMBER IN (SELECT PLEDGE_NUMBER FROM RPT_ABM1914.MV_KSM_PLEDGE_PAY) 
         THEN MIN(MV_PLG.AMOUNT) KEEP(DENSE_RANK FIRST ORDER BY MV_PLG.FISCAL_YEAR ASC)
         ELSE sum(plg.prop * PS.payment_schedule_balance) --Else 0 End)
      END As balance_nfy5
  FROM PAY_SCH PS
  INNER JOIN RPT_PBH634.v_Current_Calendar CAL
    ON rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(rpt_pbh634.ksm_pkg_tmp.to_date2(ps.payment_schedule_date, 'YYYYMMDD'))= CAL."CURR_FY"+6
   INNER JOIN PLG 
   ON PS.pledge_pledge_number = PLG.PLG
   LEFT JOIN rpt_abm1914.mv_ksm_pledge_pay MV_PLG
    ON PS.PLEDGE_PLEDGE_NUMBER = MV_PLG.PLEDGE_NUMBER
    AND MV_PLG.FISCAL_YEAR = CAL."CURR_FY"+6
   WHERE PS.PAYMENT_SCHEDULE_STATUS = 'U'
   GROUP BY plg.id,PS.PLEDGE_PLEDGE_NUMBER,plg.alloc
)

,NFY_BAL_FUTURE AS (
   SELECT 
    PLG.ID
    ,PS.PLEDGE_PLEDGE_NUMBER
    ,PLG.ALLOC
    ,MIN(rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(rpt_pbh634.ksm_pkg_tmp.to_date2(ps.payment_schedule_date, 'YYYYMMDD')))AS NFY_PAY
    ,MAX(rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(rpt_pbh634.ksm_pkg_tmp.to_date2(ps.payment_schedule_date, 'YYYYMMDD')))AS NFY_LAST_PAY
    ,CASE WHEN PS.PLEDGE_PLEDGE_NUMBER IN (SELECT PLEDGE_NUMBER FROM RPT_ABM1914.MV_KSM_PLEDGE_PAY) -- Not sure what this does, may leaed to issues
         THEN SUM(CASE WHEN mv_plg.fiscal_year >= CAL."CURR_FY" + 7 THEN MV_PLG.AMOUNT ELSE 0 END)
         ELSE sum(plg.prop * PS.payment_schedule_balance) --Else 0 End)
      END As balance_nfy_future
  FROM PAY_SCH PS
  CROSS JOIN RPT_PBH634.v_Current_Calendar CAL
   INNER JOIN PLG 
   ON PS.pledge_pledge_number = PLG.PLG
   LEFT JOIN rpt_abm1914.mv_ksm_pledge_pay MV_PLG
    ON PS.PLEDGE_PLEDGE_NUMBER = MV_PLG.PLEDGE_NUMBER
    AND MV_PLG.FISCAL_YEAR >= CAL."CURR_FY"+7
   WHERE PS.PAYMENT_SCHEDULE_STATUS = 'U'
    AND rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(rpt_pbh634.ksm_pkg_tmp.to_date2(ps.payment_schedule_date, 'YYYYMMDD'))>= (CAL."CURR_FY"+7)
   GROUP BY plg.id,PS.PLEDGE_PLEDGE_NUMBER,plg.alloc
)

,PFY_BAL AS (
   SELECT 
    PLG.ID
    ,PS.PLEDGE_PLEDGE_NUMBER
    ,PLG.ALLOC
    ,MIN(rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(rpt_pbh634.ksm_pkg_tmp.to_date2(ps.payment_schedule_date, 'YYYYMMDD')))AS NFY_PAY
    ,CASE WHEN PS.PLEDGE_PLEDGE_NUMBER IN (SELECT PLEDGE_NUMBER FROM RPT_ABM1914.MV_KSM_PLEDGE_PAY) 
         THEN MIN(MV_PLG.AMOUNT) KEEP(DENSE_RANK FIRST ORDER BY MV_PLG.FISCAL_YEAR ASC)
         ELSE sum(plg.prop * PS.payment_schedule_balance) --Else 0 End)
      END As balance_pfy1
  FROM PAY_SCH PS
  INNER JOIN RPT_PBH634.v_Current_Calendar CAL
    ON rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(rpt_pbh634.ksm_pkg_tmp.to_date2(ps.payment_schedule_date, 'YYYYMMDD'))= CAL."CURR_FY"-1
   INNER JOIN PLG 
   ON PS.pledge_pledge_number = PLG.PLG
   LEFT JOIN rpt_abm1914.mv_ksm_pledge_pay MV_PLG
    ON PS.PLEDGE_PLEDGE_NUMBER = MV_PLG.PLEDGE_NUMBER
    AND MV_PLG.FISCAL_YEAR = CAL."CURR_FY"-1
   WHERE PS.PAYMENT_SCHEDULE_STATUS = 'U'
   GROUP BY plg.id,PS.PLEDGE_PLEDGE_NUMBER,plg.alloc
)

, count_pledges As (
  Select
    plg.id
    , plg.plg
    ,plg.alloc
    ,MIN(PLG.PROP*PLG.prim_pledge_amount_paid )AS PRIM_PLEDGE_AMOUNT_PAID
    , count(Case When sc.pay_sch_fy = cal.curr_fy Then sc.payment_schedule_date End)
      As scheduled_payments_cfy
    , SUM(plg.prop * CASE WHEN SC.PAYMENT_SCHEDULE_STATUS = 'P' AND SC.PAY_SCH_FY = CAL.CURR_FY THEN SC.PAYMENT_SCHEDULE_AMOUNT ELSE 0 END) AS PAID_CFY
    ,CB.balance_cfy
    , count(Case When sc.pay_sch_fy = cal.curr_fy + 1 Then sc.payment_schedule_date End)
      As scheduled_payments_nfy
    , SUM(plg.prop * CASE WHEN SC.PAYMENT_SCHEDULE_STATUS = 'P' AND SC.PAY_SCH_FY = CAL.CURR_FY+1 THEN SC.PAYMENT_SCHEDULE_AMOUNT ELSE 0 END)
         As paid_nfy
    ,NFB.balance_nfy     
    , count(Case When sc.pay_sch_fy = cal.curr_fy + 2 Then sc.payment_schedule_date End)
      As scheduled_payments_nfy1
    , SUM(plg.prop * CASE WHEN SC.PAYMENT_SCHEDULE_STATUS = 'P' AND SC.PAY_SCH_FY = CAL.CURR_FY+2 THEN SC.PAYMENT_SCHEDULE_AMOUNT ELSE 0 END)
        As paid_nfy1
    ,NFB1.balance_nfy1    
    , count(Case When sc.pay_sch_fy = cal.curr_fy + 3 Then sc.payment_schedule_date End)
      As scheduled_payments_nfy2
    , SUM(plg.prop * CASE WHEN SC.PAYMENT_SCHEDULE_STATUS = 'P' AND SC.PAY_SCH_FY = CAL.CURR_FY+3 THEN SC.PAYMENT_SCHEDULE_AMOUNT ELSE 0 END)
        As paid_nfy2
    ,NFB2.balance_nfy2        
    , count(Case When sc.pay_sch_fy = cal.curr_fy + 4 Then sc.payment_schedule_date End)
      As scheduled_payments_nfy3
    , SUM(plg.prop * CASE WHEN SC.PAYMENT_SCHEDULE_STATUS = 'P' AND SC.PAY_SCH_FY = CAL.CURR_FY+4 THEN SC.PAYMENT_SCHEDULE_AMOUNT ELSE 0 END)
        As paid_nfy3
    , NFB3.balance_nfy3       
    , count(Case When sc.pay_sch_fy = cal.curr_fy + 5 Then sc.payment_schedule_date End)
      As scheduled_payments_nfy4
    , SUM(plg.prop * CASE WHEN SC.PAYMENT_SCHEDULE_STATUS = 'P' AND SC.PAY_SCH_FY = CAL.CURR_FY+5 THEN SC.PAYMENT_SCHEDULE_AMOUNT ELSE 0 END)
      As paid_nfy4
    , NFB4.balance_nfy4
    , count(Case When sc.pay_sch_fy = cal.curr_fy + 6 Then sc.payment_schedule_date End)
      As scheduled_payments_nfy5
    , SUM(plg.prop * CASE WHEN SC.PAYMENT_SCHEDULE_STATUS = 'P' AND SC.PAY_SCH_FY = CAL.CURR_FY+6 THEN SC.PAYMENT_SCHEDULE_AMOUNT ELSE 0 END)
      As paid_nfy5
    , NFB5.balance_nfy5
    , count(Case When sc.pay_sch_fy >= cal.curr_fy + 6 Then sc.payment_schedule_date End)
      As scheduled_payments_nfy_future
    , NFBF.balance_nfy_future 
    , count(Case When sc.pay_sch_fy = cal.curr_fy - 1 Then sc.payment_schedule_date End)
      As scheduled_payments_pfy1
    , SUM(plg.prop * CASE WHEN SC.PAYMENT_SCHEDULE_STATUS = 'P' AND SC.PAY_SCH_FY = CAL.CURR_FY-1 THEN SC.PAYMENT_SCHEDULE_AMOUNT ELSE 0 END)
      As paid_pfy1
    , PFYB.balance_pfy1
  From pay_sch sc
  Cross Join RPT_PBH634.v_current_calendar cal
  Inner Join plg
    On plg.plg = sc.pledge_pledge_number
  LEFT JOIN CFY_BAL CB
    ON PLG.ID = CB.ID
    AND PLG.PLG = CB.PLEDGE_PLEDGE_NUMBER
    AND PLG.ALLOC = CB.ALLOC
  LEFT JOIN NFY_BAL NFB
    ON PLG.ID = NFB.ID
    AND PLG.PLG = NFB.PLEDGE_PLEDGE_NUMBER
    AND PLG.ALLOC = NFB.ALLOC
  LEFT JOIN NFY_BAL1 NFB1
    ON PLG.ID = NFB1.ID
    AND PLG.PLG = NFB1.PLEDGE_PLEDGE_NUMBER
    AND PLG.ALLOC = NFB1.ALLOC
  LEFT JOIN NFY_BAL2 NFB2
    ON PLG.ID = NFB2.ID
    AND PLG.PLG = NFB2.PLEDGE_PLEDGE_NUMBER
    AND PLG.ALLOC = NFB2.ALLOC
  LEFT JOIN NFY_BAL3 NFB3
    ON PLG.ID = NFB3.ID
    AND PLG.PLG = NFB3.PLEDGE_PLEDGE_NUMBER
    AND PLG.ALLOC = NFB3.ALLOC
  LEFT JOIN NFY_BAL4 NFB4
    ON PLG.ID = NFB4.ID
    AND PLG.PLG = NFB4.PLEDGE_PLEDGE_NUMBER
    AND PLG.ALLOC = NFB4.ALLOC
  LEFT JOIN NFY_BAL5 NFB5
    ON PLG.ID = NFB5.ID
    AND PLG.PLG = NFB5.PLEDGE_PLEDGE_NUMBER
    AND PLG.ALLOC = NFB5.ALLOC
  LEFT JOIN NFY_BAL_FUTURE NFBF
    ON PLG.ID = NFBF.ID
    AND PLG.PLG = NFBF.PLEDGE_PLEDGE_NUMBER
    AND PLG.ALLOC = NFBF.ALLOC
  LEFT JOIN PFY_BAL PFYB
    ON PLG.ID = PFYB.ID
    AND PLG.PLG = PFYB.PLEDGE_PLEDGE_NUMBER
    AND PLG.ALLOC = PFYB.ALLOC
  Group By
    plg.id
    , plg.plg
    ,plg.alloc
    ,CB.balance_cfy
    ,NFB.BALANCE_NFY
    ,NFB1.BALANCE_NFY1
    ,NFB2.BALANCE_NFY2
    ,NFB3.BALANCE_NFY3
    ,NFB4.BALANCE_NFY4
    ,NFB5.balance_nfy5
    ,NFBF.balance_nfy_future 
    ,PFYB.BALANCE_PFY1
)

,KSM_SUMMARY AS (
  SELECT
    ID_NUMBER
    ,LAST_GIFT_DATE
    ,LAST_GIFT_ALLOC
    ,LAST_GIFT_TYPE
    ,LAST_GIFT_RECOGNITION_CREDIT
   FROM RPT_PBH634.V_KSM_GIVING_SUMMARY
)

,KSM_LAST_GIFT AS (
   SELECT DISTINCT 
     KGS.ID_NUMBER
     ,KGS.LAST_GIFT_DATE
     ,KGS.LAST_GIFT_ALLOC
     ,KGS.LAST_GIFT_TYPE
     ,KGS.LAST_GIFT_RECOGNITION_CREDIT
   FROM KSM_SUMMARY KGS
   INNER JOIN PLEDGE P
   ON KGS.ID_NUMBER = P.PLEDGE_DONOR_ID
)

SELECT DISTINCT
  E.ID_NUMBER
  ,E.PREF_MAIL_NAME
  ,E.INSTITUTIONAL_SUFFIX
  ,CASE WHEN CT.ID_NUMBER IS NOT NULL THEN 'Y' ELSE 'N' END AS TRUSTEE
  , p.pledge_pledge_number As PLEDGE_NUMBER
  , pp.prim_pledge_date_of_record As DATE_OF_RECORD 
  ,AL.SHORT_NAME AS ALLOCATION_NAME  
  ,P.PLEDGE_ALLOCATION_NAME AS ALLOCATION_CODE
  ,tps.short_desc AS PLEDGE_STATUS  
  ,tms_trans.transaction_type AS TRANSACTION_TYPE
  , pp.prim_pledge_year_of_giving As FISCAL_YEAR   
 -- , pledge_counts.pledge_total AS PLEDGE_TOTAL
  , pledge_counts.pledge_total_ksm AS PLEDGE_KSM_TOTAL
  ,PP.PRIM_PLEDGE_ORIGINAL_AMOUNT AS PLEDGE_ORIGINAL_AMOUNT  
 -- ,PP.PRIM_PLEDGE_AMOUNT_PAID AS PLEDGE_AMOUNT_PAID  
  ,CP.PRIM_PLEDGE_AMOUNT_PAID AS PLEDGE_AMOUNT_PAID
 -- , pledge_counts.pledge_balance AS PLEDGE_BALANCE   
  ,PB.NEW_PLEDGE_BALANCE AS PLEDGE_BALANCE
  ,PF.short_desc AS PAYMENT_FREQUENCY
  ,CASE WHEN pp.prim_PLEDGE_STATUS = 'A' AND RPT_PBH634.ksm_pkg_tmp.to_date2(NP.NEXT_PAYMENT_DATE,'YYYYMMDD') > CC."TODAY" THEN 0 
     WHEN pp.prim_PLEDGE_STATUS = 'A' AND RPT_PBH634.ksm_pkg_tmp.to_date2(NP.NEXT_PAYMENT_DATE,'YYYYMMDD') < CC."TODAY" 
       THEN ROUND(MONTHS_BETWEEN(CC.TODAY,RPT_PBH634.ksm_pkg_tmp.to_date2(NP.NEXT_PAYMENT_DATE,'YYYYMMDD'))) END AS MONTHS_OVERDUE1
  ,CASE WHEN pp.prim_PLEDGE_STATUS = 'A' AND RPT_PBH634.ksm_pkg_tmp.to_date2(NP.NEXT_PAYMENT_DATE,'YYYYMMDD') > CC."TODAY" THEN 0
        WHEN pp.prim_PLEDGE_STATUS = 'A' THEN ROUND(MONTHS_BETWEEN(CC.TODAY, LP.LAST_PAYMENT_DATE)) END AS NEW_MONTHS_OVERDUE      
  ,RPT_PBH634.ksm_pkg_tmp.to_date2(NP.NEXT_PAYMENT_DATE,'YYYYMMDD') AS NEXT_PAYMENT_DATE         
  ,NP.NEXT_PAYMENT_AMOUNT       
  ,LP.LAST_PAYMENT_DATE
  ,LP.LAST_PAYMENT AS LAST_PAYMENT_AMOUNT
  ,CPAY.PAYMENTS_TO_DATE  
  , pp.prim_pledge_comment AS PLEDGE_COMMENTS  
  , ASUM.prospect_manager AS PROSPECT_MANAGER
  , ASUM.managers  
  , SH.SPECIAL_HANDLING_CONCAT      
  ,E.FIRST_NAME
  ,E.LAST_NAME
  , E.REPORT_NAME AS SORT_NAME
  , cp.scheduled_payments_pfy1
  , cp.paid_pfy1
  , cp.balance_pfy1
  , cp.scheduled_payments_cfy
  , cp.paid_cfy
  , cp.balance_cfy
  , cp.scheduled_payments_nfy
  , cp.paid_nfy
  , cp.balance_nfy
  , cp.scheduled_payments_nfy1
  , cp.paid_nfy1
  , cp.balance_nfy1
  , cp.scheduled_payments_nfy2
  , cp.paid_nfy2
  , cp.balance_nfy2
  , cp.scheduled_payments_nfy3
  , cp.paid_nfy3
  , cp.balance_nfy3
  , cp.scheduled_payments_nfy4
  , cp.paid_nfy4
  , cp.balance_nfy4
  , cp.scheduled_payments_nfy5
  , cp.paid_nfy5
  , cp.balance_nfy5
  , cp.scheduled_payments_nfy_future
  , cp.balance_nfy_future
  , KGS.LAST_GIFT_DATE
  , KGS.LAST_GIFT_ALLOC
  , KGS.LAST_GIFT_TYPE
  , KGS.LAST_GIFT_RECOGNITION_CREDIT
From entity e
CROSS JOIN RPT_PBH634.V_CURRENT_CALENDAR CC
LEFT JOIN TABLE(RPT_PBH634.ksm_pkg_tmp.tbl_committee_trustee) CT
ON E.ID_NUMBER = CT.ID_NUMBER
Inner Join pledge p
  On e.id_number = p.pledge_donor_id
  And p.pledge_associated_code In ('P', 'S')
  And p.pledge_alloc_school = 'KM'
-- Pledge summary
Inner Join primary_pledge pp 
  On pp.prim_pledge_number = p.pledge_pledge_number
LEFT JOIN TMS_PLEDGE_STATUS TPS
  ON PP.PRIM_PLEDGE_STATUS = TPS.pledge_status_code
Inner Join pledge_counts
  On pledge_counts.pledge_pledge_number = p.pledge_pledge_number
  AND pledge_counts.pledge_allocation_name = p.pledge_allocation_name
Inner Join tms_trans 
  On tms_trans.transaction_type_code = pp.prim_pledge_type
Inner Join count_pledges cp
  On e.id_number = cp.id
  And p.pledge_pledge_number = cp.plg
  AND P.PLEDGE_ALLOCATION_NAME = cp.alloc
LEFT JOIN allocation al
  On al.allocation_code = p.pledge_allocation_name
LEFT JOIN PLEDGE_BAL PB
  ON P.PLEDGE_PLEDGE_NUMBER = PB.PLEDGE_PLEDGE_NUMBER
  AND P.PLEDGE_ALLOCATION_NAME = PB.PLEDGE_ALLOCATION_NAME
LEFT JOIN TMS_PAYMENT_FREQUENCY PF
  ON PP.PRIM_PLEDGE_PAYMENT_FREQ = PF.payment_frequency_code
LEFT JOIN NEXT_PAYMENT NP
 ON P.PLEDGE_PLEDGE_NUMBER = NP.PLEDGE_PLEDGE_NUMBER
 AND P.PLEDGE_ALLOCATION_NAME = NP.ALLOC
LEFT JOIN Count_Payments CPAY
 ON P.PLEDGE_PLEDGE_NUMBER = CPAY.PLEDGE_PLEDGE_NUMBER
LEFT JOIN LAST_PAYMENTS LP
 ON P.PLEDGE_PLEDGE_NUMBER = LP.PMT_ON_PLEDGE_NUMBER
 AND P.PLEDGE_ALLOCATION_NAME = LP.ALLOCATION_CODE
LEFT JOIN RPT_PBH634.V_ASSIGNMENT_SUMMARY ASUM
 ON E.ID_NUMBER = ASUM.ID_NUMBER
LEFT JOIN TABLE(RPT_PBH634.ksm_pkg_tmp.tbl_special_handling_concat) SH
ON E.ID_NUMBER = SH.ID_NUMBER
LEFT JOIN  KSM_LAST_GIFT KGS
ON E.ID_NUMBER = KGS.ID_NUMBER
Where --e.record_status_code Not In ('I','X','D')
  -- Recurring gift, straight pledge, NBI, grant pledge only
  transaction_type_code In ('RC', 'ST', 'NB', /*'GP',*/'TF')
  ORDER BY ID_NUMBER, PLEDGE_NUMBER
;
