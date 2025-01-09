CREATE OR REPLACE VIEW RPT_PBH634.VT_STEWARDSHIP_DAILY_GIFT_LOG AS
With

/* Date range to use */
dts As (
--  Select prev_month_start As dt1, yesterday As dt2, curr_fy
  /* Alternate date ranges for debugging */
  Select
    cal.prev_fy_start-365 As dt1
    , yesterday As dt2
    , curr_fy
  From rpt_pbh634.v_current_calendar cal
)

/* KSM degrees and programs */
, ksm_deg As ( -- Defined in ksm_pkg
  SELECT
    ID_NUMBER
    ,DEGREES_CONCAT
    ,LAST_NONCERT_YEAR
    ,PROGRAM_GROUP
  FROM RPT_PBH634.V_ENTITY_KSM_DEGREES
)

/* KSM Current Use */
, ksm_cu As (
  Select *
  From table(rpt_pbh634.ksm_pkg_tmp.tbl_alloc_curr_use_ksm)
)

/* GAB indicator */
--Per Lola, no life GAB members included on 9/21/20
, gab As ( -- GAB membership defined by ksm_pkg
  Select
    id_number
    , trim(status || ' ' || role) As gab_role
  From table(rpt_pbh634.ksm_pkg_tmp.tbl_committee_gab)
  WHERE ROLE NOT LIKE '%Life%'
)
, gab_ind As ( -- Include all receipts where at least one GAB member is associated
  Select
    gft.tx_number
    , gab.gab_role
  From nu_gft_trp_gifttrans gft
  Inner Join gab On gab.id_number = gft.id_number
)

,kac AS (
  SELECT
    id_number
    ,trim(status || ' '|| role) AS kac_role
  FROM table(rpt_pbh634.ksm_pkg_tmp.tbl_committee_kac)
)

,trustee as (
   SELECT
     ID_NUMBER
     ,trim(status || ' '|| role) AS trustee_role
   FROM table(rpt_pbh634.ksm_pkg_tmp.tbl_committee_trustee)
)

,keba as (
   SELECT
     ID_NUMBER
     ,trim(status || ' ' || role) as keba_role
   FROM TABLE(rpt_pbh634.ksm_pkg_tmp.tbl_committee_asia)
)

,boards AS (
  SELECT c.id_number
      ,listagg(ct.full_desc, ', ') Within Group (order by ct.full_desc) as committees
  FROM committee c
  INNER JOIN tms_committee_table ct
  ON c.committee_code = ct.committee_code
  WHERE c.committee_status_code = 'C'
    AND C.COMMITTEE_CODE IN ('KAMP', 'HAK', 'KPETC', 'APEAC', 'KREAC', 'KWLC', 'KAYAB', 'MBAAC', 'KTC')
   AND c.committee_role_code <> 'EF'
  GROUP BY c.id_number
)
/* Stewardship */
, stw_loyal As (
  Select
    id_number
    , stewardship_cfy
    , stewardship_pfy1
    , stewardship_pfy2
    , stewardship_pfy3
    , Case When stewardship_cfy > 0 And stewardship_pfy1 > 0 And stewardship_pfy2 > 0 Then 'Y' End As loyal_this_year
    , Case When stewardship_pfy1 > 0 And stewardship_pfy2 > 0 And stewardship_pfy3 > 0 Then 'Y' End As loyal_last_year
  From rpt_pbh634.v_ksm_giving_summary giving
)

/* KLC gift club */
/*, klc As (
  Select
    gift_club_id_number As id_number
    , substr(gift_club_end_date, 0, 4) As fiscal_year
  From gift_clubs
  Where gift_club_code = 'LKM'
)*/

/*New KLC to match AF definition*/
,GIVING_TRANS AS
( SELECT *
  FROM rpt_pbh634.v_ksm_giving_trans_hh
)

,CASH_ONLY AS (
   SELECT
     GT.ID_NUMBER
     ,GT.TX_NUMBER
     ,GT.FISCAL_YEAR
     ,GT.ALLOCATION_CODE
     ,GT.CREDIT_AMOUNT
   FROM GIVING_TRANS GT
   CROSS JOIN DTS MD
   WHERE GT.TX_GYPM_IND NOT IN ('P','M')
     AND (GT.AF_FLAG = 'Y' OR GT.CRU_FLAG = 'Y')
     AND GT.FISCAL_YEAR IN (MD.CURR_FY, MD.CURR_FY-1, MD.CURR_FY-2)
)

,MATCHES AS (
   SELECT
    GT."ID_NUMBER"
   ,GT."MATCHED_TX_NUMBER" RCPT
   ,GT.ALLOCATION_CODE ALLOC
   ,SUM(GT."CREDIT_AMOUNT") MTCH
    FROM GIVING_TRANS GT
    CROSS JOIN DTS MD
     WHERE GT.TX_GYPM_IND = 'M'
       AND (GT.AF_FLAG = 'Y' OR GT.CRU_FLAG = 'Y')
       AND GT.MATCHED_FISCAL_YEAR IN (MD.CURR_FY, MD.CURR_FY-1, MD.CURR_FY-2)
    GROUP BY GT."ID_NUMBER", GT."MATCHED_TX_NUMBER", GT.ALLOCATION_CODE
)

,CLAIMS AS (
    SELECT
      GT.ID_NUMBER
      ,GT."TX_NUMBER" RCPT
      ,GT.ALLOCATION_CODE ALLOC
      ,SUM(MC.CLAIM_AMOUNT) CLAIM
      FROM GIVING_TRANS GT
      CROSS JOIN DTS MD
      LEFT JOIN MATCHING_CLAIM MC
        ON GT.TX_NUMBER = MC.CLAIM_GIFT_RECEIPT_NUMBER
        AND GT.ALLOCATION_CODE = MC.ALLOCATION_CODE
      WHERE (GT.AF_FLAG = 'Y' OR GT.CRU_FLAG = 'Y')
        AND GT.FISCAL_YEAR IN (MD.CURR_FY, MD.CURR_FY-1, MD.CURR_FY-2)
      GROUP BY GT.ID_NUMBER, GT.TX_NUMBER, GT.ALLOCATION_CODE
)

,KGF_REWORKED AS (
    select ID
    ,FY
    ,SUM(AMT) AS TOT_KGIFTS
    --,SUM(case when FY = MD.CURR_FY-2 THEN AMT else 0 end) tot_kgifts_PFY1
    --,SUM(case when FY =  MD.CURR_FY-1 then AMT else 0 end) tot_kgifts_PFY
    --,SUM(case when FY =  MD.CURR_FY then AMT else 0 end) tot_kgifts_CFY
    FROM (
       SELECT
        HH.ID_NUMBER ID
       ,HH.TX_NUMBER RCPT
       ,HH.FISCAL_YEAR FY
       ,(HH.CREDIT_AMOUNT+ nvl(MTC.mtch,0)+ nvl(clm.claim,0)) AMT
       FROM CASH_ONLY HH
       CROSS JOIN DTS MD
       LEFT JOIN MATCHES MTC
        ON HH."ID_NUMBER" = MTC.ID_NUMBER
        AND HH."TX_NUMBER" = MTC.RCPT
        AND HH.ALLOCATION_CODE = MTC.ALLOC
       LEFT JOIN CLAIMS CLM
        ON HH."ID_NUMBER" = CLM.ID_NUMBER
        AND HH."TX_NUMBER" = CLM.RCPT
        AND HH."ALLOCATION_CODE" = CLM.ALLOC
        WHERE HH.FISCAL_YEAR IN (MD.CURR_FY, MD.CURR_FY-1, MD.CURR_FY-2))
     CROSS JOIN DTS MD
      GROUP BY ID, FY
)

,MANUAL_KLC AS (
SELECT
   gift_club_id_number As id_number
   ,substr(gift_club_end_date, 0, 4) As fiscal_year
FROM GIFT_CLUBS
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



, klc_years As (
  /*Select
    id_number
    , listagg(fiscal_year, ', ') Within Group (Order By fiscal_year Desc) As klc_years
  From klc
  Group By id_number*/
    SELECT
      KGF.ID AS ID_NUMBER
      ,LISTAGG(KGF.FY, ', ') WITHIN GROUP (ORDER BY KGF.FY DESC) AS KLC_YEARS
    FROM KGF_REWORKED KGF
    CROSS JOIN DTS MD
    LEFT JOIN ksm_deg KD
    ON KGF.ID = KD.ID_NUMBER
    WHERE (KD.LAST_NONCERT_YEAR BETWEEN MD.CURR_FY-5 AND MD.CURR_FY AND KGF.TOT_KGIFTS >= 1000)
       OR KGF.TOT_KGIFTS >= 2500
    GROUP BY ID
    UNION
    SELECT
      ID_NUMBER
      ,LISTAGG(MK.FISCAL_YEAR, ', ') WITHIN GROUP (ORDER BY MK.FISCAL_YEAR DESC) AS KLC_YEARS
    FROM MANUAL_KLC MK
    GROUP BY ID_NUMBER
)

/* Dean's salutations */
/*--, dean_sal As ( -- id_number 0000299349 = Dean Sally Blount
  Select
    dean.id_number
    , dean.salutation_type_code
    , dean.salutation
    , dean.active_ind
  From salutation dean
  Inner Join ksm_deg On ksm_deg.id_number = dean.id_number
  Where signer_id_number = '0000804796' And active_ind = 'Y'
)*/

,DEAN_SAL_ORDER AS (
 SELECT
  S.ID_NUMBER
  ,ROW_NUMBER() OVER(PARTITION BY S.ID_NUMBER ORDER BY S.DATE_ADDED DESC)RW
  ,S.SALUTATION
FROM SALUTATION S
WHERE S.SALUTATION_TYPE_CODE = 'KM'
  AND S.ACTIVE_IND = 'Y'
)

,DEAN_SAL AS (
 SELECT
   *
 FROM DEAN_SAL_ORDER
 WHERE RW = 1
)

/* Current faculty and staff */
, facstaff As ( -- Based on NU_RPT_PKG_SCHOOL_TRANSACTION
  Select Distinct
    af.id_number
    , tms_affil.short_desc
  From Affiliation af
  Inner Join tms_affiliation_level tms_affil On af.affil_level_code = tms_affil.affil_level_code
  Where af.affil_level_code In ('ES', 'EF') -- Staff, Faculty
    And af.affil_status_code = 'C'
)

,ACTIVE_ADDRESS AS (
Select
    id_number
    , AT.short_desc AS ADDR_TYPE
    , address.addr_pref_ind
    , address.addr_status_code
    , line_1
    , line_2
    , line_3
    , line_4
    , line_5
    , line_6
    , line_7
    , line_8
    ,business_title
    ,COMPANY_NAME_1
    ,STREET1
    ,STREET2
    ,STREET3
    ,DECODE(RTRIM(FOREIGN_CITYZIP),
              NULL, CITY,
              FOREIGN_CITYZIP) CITY
    ,STATE_CODE STATE
    ,ZIPCODE ZIP
    ,C.SHORT_DESC COUNTRY
  From address
  LEFT JOIN TMS_ADDRESS_TYPE AT
  ON ADDRESS.ADDR_TYPE_CODE = AT.addr_type_code
  LEFT JOIN TMS_COUNTRY C
  ON address.country_code = C.country_code
  Where (address.addr_status_code = 'A' AND ADDRESS.ADDR_TYPE_CODE = 'H') OR
        (addr_pref_ind = 'Y' and ADDR_STATUS_CODE = 'A')
     ORDER BY ID_NUMBER
)

,RANKED_ADDRESS AS (
  SELECT
    ID_NUMBER
    ,ADDR_TYPE
    ,LINE_1
    , line_2
    , line_3
    , line_4
    , line_5
    , line_6
    , line_7
    , line_8
    ,business_title
    ,COMPANY_NAME_1
    ,STREET1
    ,STREET2
    ,STREET3
    ,CITY
    ,STATE
    ,ZIP
    ,COUNTRY
    ,DENSE_RANK() OVER (PARTITION BY ID_NUMBER ORDER BY CASE WHEN ADDR_TYPE = 'Home' THEN '1' ELSE ADDR_TYPE END) AS DRANK
FROM ACTIVE_ADDRESS
)

,ADDR AS (
  SELECT
    *
  FROM RANKED_ADDRESS
  WHERE DRANK = 1
)


/* Transaction and pledge TMS table definition */
, tms_trans As (
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

/* First gift made to Kellogg */
, first_gift As (
  Select
    id_number
    , min(date_of_record) as first_ksm_gift_dt
  From rpt_pbh634.v_ksm_giving_trans
  Where transaction_type <> 'Telefund Pledge' -- Should not consider telefund pledges
  Group By id_number
)

/* Joint gift indicator */
, joint_ind As ( -- Cleaned up from ADVANCE_NU.NU_RPT_PKG_SCHOOL_TRANSACTION
  Select
    gft.tx_number
    , gft.tx_sequence
    , 'Y' As joint_ind
  From nu_gft_trp_gifttrans gft
  Where
    Exists (
      Select *
      From nu_gft_trp_gifttrans g
      Where gft.tx_number = g.tx_number
        And g.associated_code In ('J', 'K')
    ) And Exists (
      Select *
      From entity e
      Inner Join nu_gft_trp_gifttrans g On e.id_number = g.id_number
      Where gft.tx_number = g.tx_number
        And e.id_number = g.id_number
        And e.spouse_id_number = gft.id_number
        And e.marital_status_code In ('M', 'P')
    )
)

/* Transactions to use */
, trans As (
  Select
    gft.tx_number
    , gft.tx_sequence
    -- Pledge comment, if applicable
    , Case
        When gft.tx_gypm_ind = 'P' Then ppldg.prim_pledge_comment
        Else ppldgpay.prim_pledge_comment
      End As pledge_comment
    -- Pledge payment schedule
    , Case
        When gft.tx_gypm_ind = 'P' Then ppldg.prim_pledge_payment_freq
        Else ppldgpay.prim_pledge_payment_freq
      End As pledge_payment_freq_code
  -- Tables
  From nu_gft_trp_gifttrans gft
  Cross Join dts -- Date ranges; 1 row only so cross join has no performance impact
  Left Join pledge On pledge.pledge_pledge_number = gft.tx_number
    And pledge.pledge_sequence = gft.tx_sequence
  Left Join primary_pledge ppldg On ppldg.prim_pledge_number = gft.tx_number -- For pledge trans types
  Left Join primary_pledge ppldgpay On ppldgpay.prim_pledge_number = gft.pmt_on_pledge_number -- For pledge payment trans types
  -- Conditions
  Where trunc(gft.first_processed_date) Between dts.dt1 And dts.dt2 -- Only selected dates
    And (
      -- Only Kellogg, or BE/LE with Kellogg program code
      -- IMPORTANT: nu_gft_trp_gifttrans does NOT include the BE/LE allocations! (June 2017)
      nwu_std_alloc_group = 'KM'
      Or (
        gft.transaction_type In ('BE', 'LE')
        --And gft.nwu_std_alloc_group = 'UO'
        And pledge.pledge_program_code = 'KM'
      )
    )
)

/* Concatenated associated donor data */
, assoc_dnrs As ( -- One id_number per line
  Select
    gft.tx_number
    , gft.tx_sequence
    , gft.alloc_short_name
    , gft.id_number
    , gft.donor_name
    , entity.institutional_suffix
    -- Replace nulls with space
    , nvl(ksm_deg.degrees_concat, ' ') As degrees_concat
    , nvl(gab.gab_role, ' ') As gab_role
    , nvl(kac.kac_role, ' ') AS kac_role
    , nvl(t.trustee_role, ' ') AS trustee_role
    , nvl(keba.keba_role, ' ') AS keba_role
    , nvl(boards.committees, ' ') AS board_committees
    , nvl(facstaff.short_desc, ' ') As facstaff
    , nvl(klc_years.klc_years, ' ') As klc_years
    , to_char(first_gift.first_ksm_gift_dt, 'mm/dd/yyyy') As first_ksm_gift_dt
    , stw_loyal.loyal_this_year, stw_loyal.loyal_last_year
    -- Rank attributed donors for each receipt number/allocation combination
    , rank() Over (
        Partition By gft.tx_number, gft.alloc_short_name
        Order By gft.tx_number Asc, gft.alloc_short_name Asc, gft.tx_sequence Asc
      ) As attr_donor_rank
  From nu_gft_trp_gifttrans gft
  -- Only people attributed on the KSM receipts
  Inner Join trans On trans.tx_number = gft.tx_number And trans.tx_sequence = gft.tx_sequence
  Inner Join entity On entity.id_number = gft.id_number
  -- Entity indicators
  Left Join ksm_deg On ksm_deg.id_number = gft.id_number
  Left Join gab On gab.id_number = gft.id_number
  LEFT JOIN kac on kac.id_number = gft.id_number
  left join boards on boards.id_number = gft.id_number
  LEFT JOIN keba on keba.id_number = gft.id_number
  Left Join facstaff On facstaff.id_number = gft.id_number
  Left Join klc_years On klc_years.id_number = gft.id_number
  LEFT JOIN trustee t on t.id_number = gft.id_number
  Left Join first_gift On first_gift.id_number = gft.id_number
  Left Join stw_loyal On stw_loyal.id_number = gft.id_number
)

, assoc_dnr_count AS (
  SELECT
    TX_NUMBER
    ,COUNT(ID_NUMBER) AS assoc_donor_count
  FROM assoc_dnrs
  GROUP BY TX_NUMBER
)

, assoc_concat As ( -- Multiple id_numbers per line, separated by carriage return
  Select
    tx_number
    , alloc_short_name
    , Listagg(institutional_suffix, ';  ') Within Group (Order By tx_sequence) As inst_suffixes
    , Listagg(trim(donor_name) || ' (#' || id_number || ')', ';  ') Within Group (Order By tx_sequence) As assoc_donors
    , Listagg(degrees_concat, ';  ') Within Group (Order By tx_sequence) As assoc_degrees
    , Listagg(gab_role, ';  ') Within Group (Order By tx_sequence) As assoc_gab
    -- see if this works, might look cleaner, works but need to differenciate who is in what committee
    --, trim(Listagg(gab_role, chr(13)) Within Group (Order By tx_sequence)) As assoc_gab_test
    , Listagg(kac_role, ';  ') Within Group (Order by tx_sequence) AS assoc_kac
    , Listagg(trustee_role, '; ') Within Group (order by tx_sequence) as assoc_trustee
    , Listagg(keba_role, '; ') Within Group (order by tx_sequence) as assoc_keba
    , Listagg(board_committees, '; ') Within Group (Order by tx_sequence) as assoc_boards
    , Listagg(facstaff, ';  ') Within Group (Order By tx_sequence) As assoc_facstaff
    , Listagg(klc_years, ';  ') Within Group (Order By tx_sequence) As assoc_klc
    , Listagg(first_ksm_gift_dt, ';  ') Within Group (Order By tx_sequence) As first_ksm_gifts
    , Listagg(loyal_this_year, ';  ') Within Group (Order By tx_sequence) As loyal_this_fy
    , Listagg(loyal_last_year, ';  ') Within Group (Order By tx_sequence) As loyal_last_fy
  From assoc_dnrs
  Group By
    tx_number
    , alloc_short_name
)

/* Main query */
Select Distinct
  -- Recategorize BE and LE, as suggested by ADVANCE_NU.NU_RPT_PKG_SCHOOL_TRANSACTION
  Case When gft.transaction_type In ('BE', 'LE') And gft.nwu_std_alloc_group = 'UO'
    Then pledge.pledge_program_code
    Else gft.nwu_std_alloc_group
  End As nwu_std_alloc_group
  -- Entity identifiers
  , gft.id_number
  , entity.pref_mail_name
  , entity.report_name
  -- Associated donors
  , assoc.assoc_donors
  , Case When trim(assoc.assoc_degrees) <> ';' Then trim(assoc.assoc_degrees) End As assoc_degrees
  , assoc.inst_suffixes
  , assoc.first_ksm_gifts
  , CASE WHEN adr.assoc_donor_count > 2 then 'Y' ELSE ' ' END AS assc_donor_count_flag
  -- Notations
  , CASE when trim(assoc.assoc_trustee) <> ';' THEN trim(assoc.assoc_trustee) END AS assoc_trustee
  , CASE WHEN trim(assoc.assoc_keba) <> ';' THEN trim(assoc.assoc_keba) END AS assoc_keba
  , CASE WHEN trim(assoc.assoc_boards) <> ';' THEN trim(assoc.assoc_boards) END AS assoc_boards
  , Case When trim(assoc.assoc_facstaff) <> ';' Then trim(assoc.assoc_facstaff) End As assoc_facstaff
  , Case When trim(assoc.assoc_gab) <> ';' Then trim(assoc.assoc_gab) End As assoc_gab
  , CASE WHEN trim(assoc.assoc_kac) <> ';' THEN trim(assoc.assoc_kac) END AS assoc_kac
  , Case When trim(assoc.assoc_klc) <> ';' Then trim(assoc.assoc_klc) End As assoc_klc
  , gft.nwu_trustee_credit
  , assoc.loyal_this_fy
  , assoc.loyal_last_fy
  -- Joint gift data
  , Case When joint_ind.joint_ind Is Not Null Then 'Y' Else 'N' End As joint_ind
  , Case When joint_ind.joint_ind Is Not Null Then entity.spouse_id_number End As joint_id_number
  , Case When joint_ind.joint_ind Is Not Null Then (
      Select e.pref_mail_name
      From entity e
      Where entity.spouse_id_number = e.id_number
    ) End As joint_name
  -- Salutations
  , dean_sal.salutation As dean_salutation1
  , jdean_sal.salutation As dean_salutation2
  , entity.first_name As first_name1
  , Case When joint_ind.joint_ind Is Not Null Then (
      Select e.first_name
      From entity e
      Where entity.spouse_id_number = e.id_number
    ) End As first_name2
  -- Biodata
  , tms_rt.short_desc As record_type
  , Case When joint_ind.joint_ind Is Not Null Then (
      Select tms_record_type.short_desc
      From entity e
      Left Join tms_record_type On tms_record_type.record_type_code = e.record_type_code
      Where entity.spouse_id_number = e.id_number
    ) End As joint_record_type
  , entity.pref_class_year
  , tms_school.short_desc As pref_school
  , ksm_deg.program_group As ksm_program
  , ksm_deg.degrees_concat As ksm_degrees
  , Case When joint_ind.joint_ind Is Not Null Then jksm_deg.program_group End As joint_ksm_program
  , Case When joint_ind.joint_ind Is Not Null Then jksm_deg.degrees_concat End As joint_ksm_degrees
  -- Address data for tableau
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%'  or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN entitydnr2.pref_mail_name ELSE entity.pref_mail_name
          END AS PRIMARY_DONOR_NAME
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%'  or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN entitydnr2.first_name ELSE entity.first_name
          END AS SALUTATION_1

  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN entitydnr3.first_name ELSE entitydnr2.first_name
          END AS SALUTATION_2
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%'  THEN addrdnr2.addr_type ELSE addr.addr_type END AS ADDRESS_TYPE
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%'  THEN addrdnr2.line_1 ELSE addr.line_1 END AS ADDRESS_LINE_1
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr2.line_2 ELSE addr.line_2 END AS ADDRESS_LINE_2
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr2.line_3 ELSE addr.line_3 END AS ADDRESS_LINE_3
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr2.line_4 ELSE addr.line_4 END AS ADDRESS_LINE_4
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr2.line_5 ELSE addr.line_5 END AS ADDRESS_LINE_5
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr2.line_6 ELSE addr.line_6 END AS ADDRESS_LINE_6
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr2.line_7 ELSE addr.line_7 END AS ADDRESS_LINE_7
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr2.line_8 ELSE addr.line_8 END AS ADDRESS_LINE_8
  , entity.pref_jnt_mail_name1
  , entity.pref_jnt_mail_name2
  /*, addr.line_1
  , addr.line_2
  , addr.line_3
  , addr.line_4
  , addr.line_5
  , addr.line_6
  , addr.line_7
  , addr.line_8*/
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr2.business_title
          ELSE addr.business_title END AS business_title
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%'  or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr2.COMPANY_NAME_1
          ELSE addr.COMPANY_NAME_1 END AS COMPANY_NAME_1
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%'  or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr2.STREET1
          ELSE addr.STREET1 END AS STREET1
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%'  or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr2.STREET2 ELSE addr.STREET2 END AS STREET2
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%'  or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr2.STREET3 ELSE addr.STREET3 END AS STREET3
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%'  or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr2.CITY ELSE addr.CITY END AS CITY
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%'  or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr2.STATE ELSE addr.STATE END AS STATE
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%'  or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr2.ZIP ELSE addr.ZIP END AS ZIP
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%'  or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr2.COUNTRY ELSE addr.COUNTRY END AS COUNTRY
  /*,addr.business_title
  ,addr.COMPANY_NAME_1
  ,addr.STREET1
  ,addr.STREET2
  ,addr.STREET3
  ,addr.CITY
  ,addr.STATE
  ,addr.ZIP
  ,addr.COUNTRY*/
  -- Transaction data
  /*, gft.tx_gypm_ind
  , gft.tx_number
  , gft.tx_sequence
  , tms_trans.transaction_type
  , gft.pmt_on_pledge_number
  , trans.pledge_comment
  , gft.date_of_record*/


   , gft.tx_gypm_ind
  , gft.tx_number
  , CASE WHEN gft.appeal_code IN ('MAYKA', 'LAYKA', 'PAYKA') THEN 'Y' ELSE 'N' END AS "FROM CVENT"
  , gft.tx_sequence
  , tms_trans.transaction_type
  , gft.pmt_on_pledge_number
  , trans.pledge_comment
  , trans.pledge_payment_freq_code As pledge_payment_schedule_code
  , tms_plg_sch.short_desc As pledge_payment_schedule
  , gft.date_of_record
  , givc.description as memory_honor_of_ind
  , gc.gift_comment as memory_honor_of
  -- Added per Lola on 10/12/18
  , gft.adjustment_reason AS Reason_Changed
  , gft.last_modified_date AS Reason_Changed_Date
  , gft.date_of_receipt
  , pg.prim_gift_comment AS GIFT_COMMENT
  --
  , Case When trunc(gft.date_of_record) = trunc(first_gift.first_ksm_gift_dt) Then 'Y' End As first_gift
  , gft.processed_date
  , CASE WHEN gft.payment_type = '1' THEN 'Cash / Check' 
      WHEN gft.payment_type = '2' THEN 'Securities'
      WHEN gft.payment_type = '3' THEN 'Gift-in-Kind'
      WHEN gft.payment_type = '4' THEN 'Restricted Investment'
      WHEN gft.payment_type = '5' THEN 'Internal Transfer'
      WHEN gft.payment_type = '6' THEN 'Non-NU Held Trust'
      WHEN gft.payment_type = '7' THEN 'Real Estate'
      WHEN gft.payment_type = '8' THEN 'Credit Card'
      WHEN gft.payment_type = '9' THEN 'Payroll Deduction'
      WHEN gft.payment_type = 'A' THEN 'Apple Pay'
      WHEN gft.payment_type = 'G' THEN 'Google Pay'
      WHEN gft.payment_type = 'P' THEN 'PayPal'
      WHEN gft.payment_type = 'V' THEN 'Venmo' ELSE ' ' END AS PAYMENT_TYPE
  , gft.legal_amount
  , gft.alloc_short_name
  , tms_anonymous.short_desc AS ANONYMOUS_GIFT
  , allocation.long_name As alloc_long_name
  , Case When cu.status_code Is Not Null Then 'Y' End As cru_indicator
  , gft.alloc_purpose_desc
  , Case
      When lower(gft.alloc_short_name) Like '%scholarship%' Or lower(gft.alloc_purpose_desc) Like '%scholarship%' Then 'Y'
    End As scholarship_flag
  , gft.appeal_code
  , appeal_header.description As appeal_desc
  -- Prospect fields
  , prs.prospect_manager
  , prs.officer_rating
  , prs.evaluation_rating
  , prs.team
  -- Dates
  , dts.curr_fy
  -- Associated donor 2 information
  , dnr2.id_number As assoc2_id_number
  , entitydnr2.pref_mail_name AS assoc2_pref_mail_name
  , entitydnr2.pref_jnt_mail_name1 AS assoc2_pref_jnt_mail_name1
  , entitydnr2.pref_jnt_mail_name2 AS assoc2_pref_jnt_mail_name2
  --Preferred Address
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr3.addr_type ELSE addrdnr2.addr_type
         END AS   ASSOCIATED_ADDRESS_TYPE
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN entitydnr3.pref_mail_name ELSE entitydnr2.pref_mail_name
          END AS ASSOCIATED_DONOR_NAME
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr3.line_1 ELSE addrdnr2.line_1
         END AS   ASSOCIATED_ADDRESS_LINE_1
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr3.line_2 ELSE addrdnr2.line_2
         END AS ASSOCIATED_ADDRESS_LINE_2
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr3.line_3 ELSE addrdnr2.line_3
         END AS ASSOCIATED_ADDRESS_LINE_3
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr3.line_4 ELSE addrdnr2.line_4
         END AS ASSOCIATED_ADDRESS_LINE_4
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr3.line_5 ELSE addrdnr2.line_5
         END AS ASSOCIATED_ADDRESS_LINE_5
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr3.line_6 ELSE addrdnr2.line_6
         END AS ASSOCIATED_ADDRESS_LINE_6
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr3.line_7 ELSE addrdnr2.line_7
         END AS ASSOCIATED_ADDRESS_LINE_7
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr3.line_8 ELSE addrdnr2.line_8
         END AS ASSOCIATED_ADDRESS_LINE_8
 /* , addrdnr2.line_1 as assoc2_line1
  , addrdnr2.line_2 as assoc2_line2
  , addrdnr2.line_3 as assoc2_line3
  , addrdnr2.line_4 as assoc2_line4
  , addrdnr2.line_5 as assoc2_line5
  , addrdnr2.line_6 as assoc2_line6
  , addrdnr2.line_7 as assoc2_line7
  , addrdnr2.line_8 as assoc2_line8*/

  --Preferred Address
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr3.business_title ELSE addrdnr2.business_title
         END AS   ASSOCIATED_business_title
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr3.COMPANY_NAME_1 ELSE addrdnr2.COMPANY_NAME_1
         END AS ASSOCIATED_COMPANY_NAME_1
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr3.STREET1 ELSE addrdnr2.STREET1
         END AS ASSOCIATED_STREET1
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr3.STREET2 ELSE addrdnr2.STREET2
         END AS ASSOCIATED_STREET2
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr3.STREET3 ELSE addrdnr2.STREET3
         END AS ASSOCIATED_STREET3
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr3.CITY ELSE addrdnr2.CITY
         END AS ASSOCIATED_CITY
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr3.STATE ELSE addrdnr2.STATE
         END AS ASSOCIATED_STATE
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr3.ZIP ELSE addrdnr2.ZIP
         END AS ASSOCIATED_ZIP
  , CASE WHEN tms_rt.short_desc LIKE '%Fdn%' OR tms_rt.short_desc LIKE '%Fnd%' or tms_rt.short_desc like '%Corp%'
       OR tms_rt.short_desc Like '%Other%' THEN addrdnr3.COUNTRY ELSE addrdnr2.COUNTRY
         END AS ASSOCIATED_COUNTRY
 /* ,addrdnr2.business_title AS assoc2_business_title
  ,addrdnr2.COMPANY_NAME_1 AS assoc2__company_name_1
  ,addrdnr2.STREET1 AS assoc2_street1
  ,addrdnr2.STREET2 AS assoc2_street2
  ,addrdnr2.STREET3 AS assoc2_street3
  ,addrdnr2.CITY AS assoc2_CITY
  ,addrdnr2.STATE AS assoc2_state
  ,addrdnr2.ZIP as assoc2_zip
  ,addrdnr2.COUNTRY as assoc2_country*/
  -- Per Lola, got rid of this because she already has it in column E
  --, ksm_deg2.degrees_concat AS assoc2_degrees_concat
-- Tables start here
-- Gift reporting table
From nu_gft_trp_gifttrans gft
-- Calendar objects
Cross Join dts
  --gifts in honor of people
  LEFT JOIN GIFT_CODES GC
  ON gft.tx_number = GC.RECEIPT_NUMBER
    AND GC.GIFT_CODE_TYPE = '1'
  LEFT JOIN GIVING_CODES GIVC
  ON GC.GIFT_CODE = GIVC.GIFT_CODE
-- Only include desired receipt numbers
Inner Join trans On trans.tx_number = gft.tx_number
  And trans.tx_sequence = gft.tx_sequence
-- Entity table
Inner Join entity On entity.id_number = gft.id_number
-- Allocation table
Inner Join allocation On allocation.allocation_code = gft.allocation_code
-- Entity record type TMS definition
LEFT JOIN GIFT ON gft.id_number = gift.gift_donor_id
  AND gft.tx_number = gift.gift_receipt_number
   AND gft.tx_sequence = gift.gift_sequence
LEFT JOIN TMS_ANONYMOUS on gift.gift_associated_anonymous = tms_anonymous.anonymous_code
Inner Join tms_record_type tms_rt On tms_rt.record_type_code = gft.record_type_code
-- Transaction type TMS definition
Inner Join tms_trans On tms_trans.transaction_type_code = gft.transaction_type
-- Associated donor fields
Inner Join assoc_concat assoc On assoc.tx_number = gft.tx_number
  And assoc.alloc_short_name = gft.alloc_short_name
Left Join assoc_dnrs dnr2 On dnr2.tx_number = gft.tx_number
  And dnr2.alloc_short_name = gft.alloc_short_name
  And dnr2.attr_donor_rank = 2
LEFT JOIN assoc_dnr_count adr
  on adr.tx_number = gft.tx_number
--another level of associated donor for when the primary donor is through foundation or DAF
Left Join assoc_dnrs dnr3 On dnr3.tx_number = gft.tx_number
  And dnr3.alloc_short_name = gft.alloc_short_name
  And dnr3.attr_donor_rank = 3
-- Salutations
Left Join dean_sal On dean_sal.id_number = gft.id_number
Left Join dean_sal jdean_sal On jdean_sal.id_number = entity.spouse_id_number
-- Joint gifts
Left Join joint_ind On joint_ind.tx_number = gft.tx_number
  And joint_ind.tx_sequence = gft.tx_sequence
-- Pledge table
Left Join pledge On pledge.pledge_pledge_number = gft.tx_number
  And pledge.pledge_sequence = gft.tx_sequence
-- Other gift attributes
Left Join first_gift On first_gift.id_number = gft.id_number
Left Join ksm_cu cu On gft.allocation_code = cu.allocation_code
Left Join tms_payment_frequency tms_plg_sch On tms_plg_sch.payment_frequency_code = trans.pledge_payment_freq_code
--gift comment addition per Lola on 10/12/18
LEFT JOIN PRIMARY_GIFT PG
ON gft.tx_number = PG.PRIM_GIFT_RECEIPT_NUMBER
-- Degree info
Left Join tms_school On tms_school.school_code = entity.pref_school_code
Left Join ksm_deg On ksm_deg.id_number = gft.id_number
Left Join ksm_deg jksm_deg On jksm_deg.id_number = entity.spouse_id_number

-- Preferred addresses
Left Join addr On addr.id_number = gft.id_number
-- Prospect reporting table
Left Join nu_prs_trp_prospect prs On prs.id_number = gft.id_number
-- Appeal code definitions
Left Join appeal_header On appeal_header.appeal_code = gft.appeal_code

--Associated donor 2  pref address
LEFT JOIN addr addrdnr2 ON addrdnr2.id_number = dnr2.id_number
LEFT Join entity entitydnr2 On entitydnr2.id_number = dnr2.id_number
Left Join ksm_deg ksm_deg2 On ksm_deg2.id_number = dnr2.id_number

--associated donor 3 pref address
LEFT JOIN addr addrdnr3 ON addrdnr3.id_number = dnr3.id_number
LEFT Join entity entitydnr3 On entitydnr3.id_number = dnr3.id_number
Left Join ksm_deg ksm_deg3 On ksm_deg3.id_number = dnr3.id_number
-- Conditions
Where gft.legal_amount > 0 -- Only legal donors
;
