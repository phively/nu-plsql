/**************************************************
MV definitions
Run once or convert to subqueries below in TMP_TABLEAU_TASK_REPORT 
**************************************************/

-- Combined constituent/organization
-- Drop Materialized View TMP_MV_ENTITY;
Create Materialized View TMP_MV_ENTITY As
(
  Select
    'P' As person_or_org
    , c.constituent_salesforce_id As salesforce_id
    , c.constituent_household_account_donor_id As household_id
    , c.household_primary_constituent_indicator As household_primary
    , c.constituent_donor_id As donor_id
    , c.full_name
    , trim(trim(last_name || ', ' || first_name) || ' ' || Case When middle_name != '-' Then middle_name End)
      As sort_name
    , c.is_deceased_indicator
    , c.primary_constituent_type As primary_record_type
    , institutional_suffix
    , c.spouse_constituent_donor_id As spouse_donor_id
    , c.spouse_name
    , c.spouse_instituitional_suffix -- typo
      As spouse_institutional_suffix
    , NULL As org_ult_parent_donor_id
    , NULL As org_ult_parent_name
    , c.preferred_address_city
    , c.preferred_address_state
    , c.preferred_address_postal_code
    , c.preferred_address_country_name As preferred_address_country
    , c.etl_update_date
  From dm_alumni.dim_constituent c
  ) Union All ( 
  Select 
    'O' As person_or_org
    , o.organization_salesforce_id
    , o.organization_ultimate_parent_donor_id As household_id
    , Case
        When organization_donor_id = organization_ultimate_parent_donor_id
          Then 'Y'
        Else 'N'
        End
      As org_primary
    , o.organization_donor_id As donor_id
    , o.organization_name
    , o.organization_name As sort_name
    , o.organization_inactive_indicator
    , o.organization_type As primary_record_type
    , NULL As institutional_suffix
    , NULL As spouse_donor_id
    , NULL As spouse_name
    , NULL As spouse_institutional_suffix
    , o.organization_ultimate_parent_donor_id As org_ult_parent_donor_id
    , o.organization_ultimate_parent_name As org_ult_parent_name
    , o.preferred_address_city
    , o.preferred_address_state
    , o.preferred_address_postal_code
    , o.preferred_address_country_name As preferred_address_country
    , o.etl_update_date
  From dm_alumni.dim_organization o
  )
;

-- Current addresses
-- Drop Materialized View TMP_MV_ADDRESS;
Create Materialized View TMP_MV_ADDRESS As
Select
  a.address_donor_id As donor_id
  , a.address_prefered_indicator -- typo
    As address_preferred_indicator
  , a.address_geocode_description As geocode
  , trunc(etl_update_date)
    As etl_update_date
From dm_alumni.dim_address a
Where a.address_status = 'Current'
;

-- Active assignments
-- Drop Materialized View TMP_MV_ASSIGNMENTS;
Create Materialized View TMP_MV_ASSIGNMENTS As
With
assignments As (
  Select 
    a.name
      As assignment_record_id
    , u.id
      As staff_user_salesforce_id
    , u.username
      As staff_username
    , u.contactid
      As staff_constituent_salesforce_id
    , u.name
      As staff_name
    , u.isactive
      As staff_is_active
    , a.ucinn_ascendv2__assignment_type__c
      As assignment_type
    , a.ucinn_ascendv2__donor_id_formula__c
      As donor_id
  From stg_alumni.ucinn_ascendv2__assignment__c a
  Inner Join stg_alumni.user_tbl u
    On u.id = a.ucinn_ascendv2__assigned_relationship_manager_user__c
)

, pm As (
  Select
    donor_id
    , Listagg(staff_user_salesforce_id, '; ') Within Group (Order By staff_name)
      As prospect_manager_user_id
    , Listagg(staff_name, '; ') Within Group (Order By staff_name)
      As prospect_manager_name
  From assignments
  Where staff_is_active = 'true'
    And assignment_type = 'Primary Relationship Manager'
  Group By donor_id
)

, lgo As (
  Select
    donor_id
    , Listagg(staff_user_salesforce_id, '; ') Within Group (Order By staff_name)
      As lagm_user_id
    , Listagg(staff_name, '; ') Within Group (Order By staff_name)
      As lagm_name
  From assignments
  Where staff_is_active = 'true'
    And assignment_type = 'Leadership Annual Gift Manager'
  Group By donor_id
)

, ids As (
  Select donor_id
  From pm
  Union
  Select donor_id
  From lgo
)

Select
  ids.donor_id
  , pm.prospect_manager_user_id
  , pm.prospect_manager_name
  , lgo.lagm_user_id
  , lgo.lagm_name
From ids
Left Join pm
  On pm.donor_id = ids.donor_id
Left Join lgo
  On lgo.donor_id = ids.donor_id
;

/**************************************************
Tableau tasks data source
Lightly edited code for Tableau data source, from Amy Barba and Melanie Pozdol
Pulls from static data defined above
**************************************************/

--CREATE OR REPLACE VIEW TMP_TABLEAU_TASK_REPORT AS
WITH

params AS (
  SELECT
    to_date('20221101', 'YYYYMMDD') AS START_DATE
    ,to_date('20250501', 'YYYYMMDD') AS OPEN_DATE
  FROM DUAL
)
/*
,KSM_STAFF AS ( -- Not needed, filters on KSM MGO team
SELECT
  DONOR_ID
  ,SORT_NAME
  ,TEAM
  ,USER_ID
  ,USER_NAME
FROM tbl_ksm_gos staff
WHERE staff.active_flag = 'Y'
  AND STAFF.TEAM = 'MG'
)
*/

-- New subquery, filter on active prospect managers
, pms As (
  Select Distinct
    u.id As prospect_manager_user_id
    , u.username As prospect_manager_name
  From stg_alumni.ucinn_ascendv2__assignment__c a
  Inner Join stg_alumni.user_tbl u
    On u.id = a.ucinn_ascendv2__assigned_relationship_manager_user__c
  Where u.isactive = 'true'
    And a.ucinn_ascendv2__assignment_type__c = 'Primary Relationship Manager'
)

,task_detail AS (
SELECT
  ME.DONOR_ID
  ,ME.HOUSEHOLD_ID
  ,ME.SALESFORCE_ID
  ,C.CASENUMBER
  ,C.ID AS TASK_ID
  ,C.CREATEDDATE
  ,C.CLOSEDDATE
  ,C.AP_LEGACY_DATE_OPENED__C AS "Legacy Date Opened"
  ,C.AP_LEGACY_DATE_CLOSED__C AS "Legacy Date Closed"
  ,C.SYSTEMMODSTAMP
  ,UT.NAME AS "USER"
--  ,KSTF.USER_ID AS CASE_OWNER_ID
--  ,KSTF.USER_NAME AS CASE_OWNER
  , pms.prospect_manager_user_id As case_owner_id
  , pms.prospect_manager_name As case_owner
  ,C.STATUS
  ,C.SUBJECT
  ,C.DESCRIPTION
FROM STG_ALUMNI.CASE C
CROSS JOIN PARAMS P
INNER JOIN TMP_MV_ENTITY ME
ON C.AP_CONSTITUENT_RECORD__C = ME.SALESFORCE_ID
--INNER JOIN KSM_STAFF KSTF
--ON C.OWNERID = KSTF.USER_ID
Inner Join pms
  On pms.prospect_manager_user_id = c.ownerid
LEFT JOIN stg_alumni.user_tbl UT
ON C.AP_USER__C = UT.ID
  WHERE C.TYPE = 'Referral'
    AND (C.CREATEDDATE >= P.OPEN_DATE
      OR C.AP_LEGACY_DATE_OPENED__C >= P.START_DATE)
)

,STRATEGY_IDS AS (
SELECT
    T.DONOR_ID
    ,STRAT.NAME AS STRATEGY_ID
    ,STRAT.Ap_Is_Active__c
   -- ,STRAT.AP_STAGE__C AS "STAGE OF READINESS"
  FROM task_detail T
  INNER JOIN stg_alumni.ucinn_ascendv2__strategy__c STRAT
  ON T.DONOR_ID = STRAT.UCINN_ASCENDV2__PROSPECT_ID_FORMULA__C
   AND STRAT.AP_IS_ACTIVE__C = 'true'
UNION
SELECT
  T.DONOR_ID
  ,STRAT.NAME AS STRATEGY_ID
  ,STRAT.Ap_Is_Active__c
 -- ,STRAT.AP_STAGE__C AS "STAGE OF READINESS"
FROM task_detail T
  INNER JOIN stg_alumni.ap_strategy_relation__c  STRATR
  ON T.SALESFORCE_ID = STRATR.AP_CONSTITUENT__C
  INNER JOIN stg_alumni.ucinn_ascendv2__strategy__c STRAT
  ON STRATR.AP_STRATEGY__C = STRAT.ID
    AND STRATR.AP_IS_ACTIVE_FORMULA__C = 'true'
)

,RATINGS AS (
SELECT
  T.DONOR_ID
  ,DSTRAT.STRATEGY_PRIMARY_RELATION_UNIVERSITY_OVERALL_RATING_ENTRY_DATE AS "UOR DATE"
  ,CASE WHEN DSTRAT.STRATEGY_PRIMARY_RELATION_UNIVERSITY_OVERALL_RATING = '-'
     THEN ' ' ELSE DSTRAT.STRATEGY_PRIMARY_RELATION_UNIVERSITY_OVERALL_RATING END AS UOR
  ,CASE WHEN DSTRAT.STRATEGY_PRIMARY_RELATION_UNIVERSITY_OVERALL_RATING_RESPONSIBLE_FUNDRAISER = '-' THEN ' ' ELSE
      DSTRAT.STRATEGY_PRIMARY_RELATION_UNIVERSITY_OVERALL_RATING_RESPONSIBLE_FUNDRAISER END AS "UOR AUTHOR"
  ,DSTRAT.STRATEGY_PRIMARY_RELATION_RESEARCH_EVALUATION_DATE AS "EVALUATION RATING DATE"
  ,CASE WHEN DSTRAT.STRATEGY_PRIMARY_RELATION_RESEARCH_EVALUATION = '-' THEN ' '
      ELSE DSTRAT.STRATEGY_PRIMARY_RELATION_RESEARCH_EVALUATION END AS "EVALUATION RATING"
FROM task_detail T
INNER JOIN DM_ALUMNI.DIM_CONSTITUENT  DC
ON T.DONOR_ID = DC.CONSTITUENT_DONOR_ID
INNER JOIN DM_ALUMNI.DIM_STRATEGY DSTRAT
ON DC.CONSTITUENT_PRIMARY_PROSPECT_STRATEGY_RECORD_ID = DSTRAT.STRATEGY_RECORD_ID
  WHERE DSTRAT.STRATEGY_ACTIVE_INDICATOR = 'Y'
)

,HOUSEHOLD_ADDRESS AS (
  SELECT
    ME.HOUSEHOLD_ID
    ,ME.PREFERRED_ADDRESS_CITY AS HOUSEHOLD_CITY
    ,ME.PREFERRED_ADDRESS_STATE AS HOUSEHOLD_STATE
    ,ME.PREFERRED_ADDRESS_POSTAL_CODE AS HOUSEHOLD_ZIP
    ,ME.PREFERRED_ADDRESS_COUNTRY AS HOUSEHOLD_COUNTRY
  FROM TMP_MV_ENTITY ME
  INNER JOIN TASK_DETAIL T
  ON T.HOUSEHOLD_ID = ME.HOUSEHOLD_ID
  WHERE ME.HOUSEHOLD_PRIMARY = 'Y'
)

,LAST_CONTACT AS (
  SELECT
    T.DONOR_ID
    ,MAX(CR.AP_CONTACT_REPORT_AUTHOR_NAME_FORMULA__C) KEEP (DENSE_RANK FIRST ORDER BY CR.UCINN_ASCENDV2__DATE__C Desc) AS "LAST CONTACTED BY"
    ,max(CR.UCINN_ASCENDV2__DATE__C) KEEP (DENSE_RANK FIRST ORDER BY CR.UCINN_ASCENDV2__DATE__C Desc) AS "LAST CONTACT DATE"
    ,max(CR.UCINN_ASCENDV2__CONTACT_METHOD__C) keep(dense_rank First Order By CR.UCINN_ASCENDV2__DATE__C Desc) AS "LAST CONTACT TYPE"
  FROM stg_alumni.ucinn_ascendv2__contact_report__c CR
  INNER JOIN stg_alumni.ucinn_ascendv2__contact_report_relation__c CRR
   ON CRR.UCINN_ASCENDV2__CONTACT_REPORT__C = CR.ID
  INNER JOIN TASK_DETAIL T
   ON CRR.UCINN_ASCENDV2__CONTACT__C = T.SALESFORCE_ID
  GROUP BY   T.DONOR_ID
)

,ACTIVE_PROPOSAL AS (
   SELECT
   --row_number() OVER(PARTITION BY DC.CONSTITUENT_DONOR_ID ORDER BY PO.PROPOSAL_OPPORTUNITY_SID ASC) rw
   DC.CONSTITUENT_DONOR_ID
   ,PO.PROPOSAL_MANAGER_NAME
   ,PO.PROPOSAL_MANAGER_BUSINESS_UNIT
   ,PO.PROPOSAL_STAGE
  FROM DM_ALUMNI.DIM_CONSTITUENT DC
  INNER JOIN dm_alumni.dim_proposal_opportunity PO
    ON DC.CONSTITUENT_PRIMARY_PROSPECT_STRATEGY_RECORD_ID = PO.PROPOSAL_STRATEGY_RECORD_ID
  WHERE  PO.PROPOSAL_ACTIVE_INDICATOR = 'Y'
    --AND P.PROPOSAL_DESIGNATION_WORK_PLAN_UNITS LIKE '%Kellogg School of Management%'
     AND PO.PROPOSAL_STRATEGY_RECORD_ID <> '-'
 )

,geo as (
select distinct g.ap_address_relation_record_type__c,
                        g.ap_address_relation__c,
                        g.ap_constituent__c,
                        g.ap_geocode_value__c,
                        g.ap_geocode_value_description__c,
                        g.ap_is_active__c,
                        g.ap_is_constituent_address_relation__c,
                        g.geocode_value_type_description__c,
                        g.id
from stg_alumni.ap_geocode__c g
--- Active Geocode
where g.ap_is_active__c = 'true'
  AND G.GEOCODE_VALUE_TYPE_DESCRIPTION__C LIKE '%Tier 1%'
)


,CONTACT_COUNTS AS (
SELECT
  TD.TASK_ID
  ,TD.CASE_OWNER_ID
  ,COUNT (DISTINCT
    CASE WHEN CR.UCINN_ASCENDV2__DATE__C BETWEEN TD.CREATEDDATE AND trunc(sysdate) - 1 -- yesterday --v_current_calendar.YESTERDAY
      AND TD.STATUS IN ('New', 'In Progress')
      AND CR.UCINN_ASCENDV2__CONTACT_METHOD__C <> 'Visit' THEN CR.NAME END) AS NONVISIT_CONTACT_DURING_TASK
  ,COUNT (DISTINCT
     CASE WHEN   CR.UCINN_ASCENDV2__DATE__C > TD.CREATEDDATE
         AND CR.UCINN_ASCENDV2__CONTACT_METHOD__C = 'Visit' THEN CR.NAME END) AS TOTAL_VISITS
  FROM stg_alumni.ucinn_ascendv2__contact_report__c CR
--  CROSS JOIN v_current_calendar
  INNER JOIN stg_alumni.ucinn_ascendv2__contact_report_relation__c CRR
   ON CRR.UCINN_ASCENDV2__CONTACT_REPORT__C = CR.ID
  INNER JOIN TASK_DETAIL TD
   ON CRR.CREATEDBYID = TD.CASE_OWNER_ID
   AND CRR.UCINN_ASCENDV2__CONTACT__C = TD.SALESFORCE_ID
  GROUP BY TD.TASK_ID, TD.CASE_OWNER_ID
)

SELECT DISTINCT
--  ME.HOUSEHOLD_ID_KSM
  ME.HOUSEHOLD_ID
  ,ME.HOUSEHOLD_PRIMARY
--  ,ME.HOUSEHOLD_PRIMARY_KSM
  ,ME.SALESFORCE_ID
  ,STID.STRATEGY_ID
  ,ME.DONOR_ID
  ,ME.SORT_NAME
--  ,EKD.FIRST_KSM_YEAR
--  ,EKD.PROGRAM
  ,ME.SPOUSE_DONOR_ID
  ,ME.SPOUSE_NAME
  ,ME.SPOUSE_INSTITUTIONAL_SUFFIX
  ,C.UCINN_ASCENDV2__STAGE_OF_READINESS__C AS STAGE_OF_READINESS
  ,C.UCINN_ASCENDV2__STAGE_OF_READINESS_LAST_MODIFIED_DATE__C AS STAGE_OF_READINESS_DATE
  ,R.UOR
  ,R."UOR DATE"
  ,R."UOR AUTHOR"
  ,R."EVALUATION RATING"
  ,R."EVALUATION RATING DATE"
--  ,MKM.MG_PR_DESCRIPTION
  ,HA.HOUSEHOLD_CITY
  ,HA.HOUSEHOLD_STATE
  ,HA.HOUSEHOLD_ZIP
  ,HA.HOUSEHOLD_COUNTRY
  ,DA.EMPLOYER_ORGANIZATION_NAME AS EMPLOYER
  ,DA.EMPLOYEE_JOB_TITLE  AS "JOB TITLE"
  ,LC."LAST CONTACT DATE"
  ,LC."LAST CONTACTED BY"
  ,CASE WHEN APROP.CONSTITUENT_DONOR_ID IS NOT NULL THEN 'Y' ELSE 'N' END AS ACTIVE_PROPOSAL
  ,MAD.GEOCODE AS GEOCODE
  ,MA.PROSPECT_MANAGER_USER_ID
  ,MA.PROSPECT_MANAGER_NAME
  ,MA.LAGM_USER_ID
  ,MA.LAGM_NAME
  ,TD.TASK_ID
  ,TD.CREATEDDATE
  ,TD.CLOSEDDATE
  ,TD."Legacy Date Opened"
  ,TD."Legacy Date Closed"
  ,TD.SYSTEMMODSTAMP
  ,TD."USER"
  ,TD.CASE_OWNER_ID
  ,TD.CASE_OWNER
  ,TD.STATUS
  ,TD.SUBJECT
  ,TD.DESCRIPTION
  ,C.NONVISIT_CONTACT_DURING_TASK
  ,C.TOTAL_VISITS
  ,CASE WHEN C.UCINN_ASCENDV2__STAGE_OF_READINESS__C = 'Unresponsive' AND
      C.UCINN_ASCENDV2__STAGE_OF_READINESS_LAST_MODIFIED_DATE__C > TD.CREATEDDATE THEN 'Y' ELSE 'N' END AS "Unresponsive"
  ,CASE WHEN C.UCINN_ASCENDV2__STAGE_OF_READINESS__C = 'Disqualified' AND
      C.UCINN_ASCENDV2__STAGE_OF_READINESS_LAST_MODIFIED_DATE__C > TD.CREATEDDATE THEN 'Y' ELSE 'N' END AS "Disqualified"
FROM TMP_MV_ENTITY ME
INNER JOIN TASK_DETAIL TD
ON ME.SALESFORCE_ID = TD.SALESFORCE_ID
--LEFT JOIN MV_ENTITY_KSM_DEGREES EKD -- IGNORE - not needed outside KSM
--ON ME.DONOR_ID = EKD.DONOR_ID
LEFT JOIN TMP_MV_ADDRESS MAD
ON ME.DONOR_ID = MAD.DONOR_ID
  AND MAD.ADDRESS_PREFERRED_INDICATOR = 'Y'
--    AND MAD.geocodes_concat Is Not Null
  And MAD.geocode Is Not Null
LEFT JOIN STRATEGY_IDS STID
ON ME.DONOR_ID = STID.DONOR_ID
LEFT JOIN stg_alumni.contact C
ON ME.DONOR_ID = C.Ucinn_Ascendv2__Donor_Id__c
LEFT JOIN RATINGS R
ON ME.DONOR_ID = R.DONOR_ID
--LEFT JOIN mv_ksm_models MKM -- IGNORE - not needed outside KSM
--ON ME.DONOR_ID = MKM.DONOR_ID
LEFT JOIN HOUSEHOLD_ADDRESS HA
ON ME.HOUSEHOLD_ID = HA.HOUSEHOLD_ID
LEFT JOIN DM_ALUMNI.DIM_AFFILIATION DA
  ON ME.DONOR_ID = DA.CONSTITUENT_DONOR_ID
    AND DA.PRIMARY_EMPLOYMENT_INDICATOR = 'Y'
LEFT JOIN LAST_CONTACT LC
ON ME.DONOR_ID = LC.DONOR_ID
LEFT JOIN ACTIVE_PROPOSAL APROP
ON ME.DONOR_ID = APROP.CONSTITUENT_DONOR_ID
LEFT JOIN TMP_MV_ASSIGNMENTS MA
ON ME.DONOR_ID = MA.DONOR_ID
LEFT JOIN CONTACT_COUNTS C
ON C.TASK_ID = TD.TASK_ID
   AND C.CASE_OWNER_ID = TD.CASE_OWNER_ID
WHERE ME.IS_DECEASED_INDICATOR = 'N'
;
