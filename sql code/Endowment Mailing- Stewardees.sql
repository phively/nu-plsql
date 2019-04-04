With


Rep_End_Alloc AS (
       Select 
       a.allocation_code, a.short_name, a.long_name
       From allocation a
       Where steward_reporting_code = 'RP'
       AND alloc_school = 'KM'
       AND Agency = 'END'
),

HH_Stewardees AS (
    Select 
    ALS.ID_number AS "HOUSEHOLD_ID"
    , listagg(REA.allocation_code, ', ') within group (order by ALS.allocation_code) AS "STEWARDEE_ALLOC_CODE"
    , listagg(REA.short_name, ', ') within group (order by ALS.allocation_code) AS "STEWARDEE_ALLOC_SHORT_NAME"
    , listagg(REA.long_name, ', ') within group (order by ALS.allocation_code) AS "STEWARDEE_ALLOC_LONG_NAME"
    From allocation_stewardee ALS
    Inner Join Rep_End_Alloc REA
    ON ALS.allocation_code = REA.allocation_code
    Where ALS.ID_Number In (Select Distinct id_number From table(rpt_pbh634.ksm_pkg.tbl_entity_households_ksm))    
    Group by ALS.ID_number
),

HH_END_Trans AS (
  Select gft.*
  From rpt_pbh634.v_ksm_giving_campaign_trans_hh gft
  Where
  -- Reportable Endowed allocations per Rep_End_Alloc subquery
  gft.allocation_code In (Select Distinct allocation_code From Rep_End_Alloc)
),

HH_End_Donors AS (
    SELECT
      trans."HOUSEHOLD_ID"
      ,SUM(trans."HH_RECOGNITION_CREDIT") AS TOTAL_TO_END
    FROM HH_END_Trans trans
    GROUP BY trans.HOUSEHOLD_ID
),
              
Spouse AS(
   SELECT 
  E.ID_NUMBER
  ,E.SPOUSE_ID_NUMBER
  ,SE.RECORD_STATUS_CODE
  ,SE.PREF_MAIL_NAME
  ,SE.FIRST_NAME
  ,SE.LAST_NAME
FROM ENTITY E
LEFT JOIN ENTITY SE
ON E.SPOUSE_ID_NUMBER = SE.ID_NUMBER
WHERE
SE.RECORD_STATUS_CODE = 'A'
),

Sally_Salut AS(
Select
      ID_Number
    , max(salutation) keep(dense_rank First Order By ID_number Asc, date_modified) AS Latest_Sal
    From salutation
    WHERE signer_ID_number = '0000299349'
    AND Active_IND = 'Y'
    AND salutation != '%and%'
    Group by ID_Number
    Order by ID_number
),

PrefAddress AS( 
Select 
   a.Id_number
,  tms_addr_status.short_desc AS Address_Status
,  tms_address_type.short_desc AS Address_Type
,  a.addr_pref_ind
,  a.company_name_1
,  a.company_name_2
,  a.street1
,  a.street2
,  a.street3
,  a.foreign_cityzip
,  a.city
,  a.state_code
,  a.zipcode
,  tms_country.short_desc AS Country
FROM address a
INNER JOIN tms_addr_status
ON tms_addr_status.addr_status_code = a.addr_status_code
LEFT JOIN tms_address_type
ON tms_address_type.addr_type_code = a.addr_type_code
LEFT JOIN tms_country
ON tms_country.country_code = a.country_code
WHERE a.addr_pref_IND = 'Y'
AND a.addr_status_code IN('A','K')
),

Seas_Address AS(
SELECT *
FROM v_seasonal_addr SA
WHERE CURRENT_DATE
  BETWEEN SA.real_start_date1 AND SA.real_stop_date1 
  OR CURRENT_DATE BETWEEN SA.real_start_date2 AND SA.real_stop_date2
),

Prospect_Manager AS (
     Select A.prospect_ID, PET.ID_Number, A.assignment_ID_Number, E.Pref_Mail_Name
     From assignment A
     Inner Join prospect_entity PET
     ON A.prospect_ID = PET.prospect_Id
     Inner Join entity E
     ON A.assignment_id_number = E.id_number
     Where A.assignment_type = 'PM'
     AND A.active_IND = 'Y'
),

Prog_Prospect_Manager AS (
     Select 
     A.prospect_ID
     , PET.ID_Number
     , listagg(A.assignment_ID_Number, ', ') within group (order by A.Assignment_Id_Number Asc) AS PPM_IDs
     , listagg(E.Pref_Mail_Name, ', ') within group (order by A.Assignment_Id_Number Asc) AS PPM_Names
     From assignment A
     Inner Join prospect_entity PET
     ON A.prospect_ID = PET.prospect_Id
     Inner Join entity E
     ON A.assignment_id_number = E.id_number
     Where A.assignment_type = 'PP'
     AND A.active_IND = 'Y'
     AND PET.PRIMARY_IND = 'Y'
     Group by A.Prospect_ID, PET.ID_Number
)

SELECT DISTINCT
  E.ID_NUMBER AS "Household ID"
  ,E.Report_name as "P Report Name"
  ,E.first_name AS "P First Name"
  ,PSAL.latest_sal AS "P Sally Salut"
  ,E.Pref_Mail_Name AS P_Pref_Name
  ,E.RECORD_STATUS_CODE "P Record Status" 
  ,D.DEGREES_CONCAT P_Degrees_Concat
  ,E.spouse_ID_Number AS "Spouse ID"
  ,S.record_status_code AS "Spouse_Status"
  ,S.pref_mail_name AS "Spouse_Pref_Name"
  ,S.first_name  AS "Spouse_First_Name"
  ,S.last_name AS "Spouse_Last_Name"
  ,SSAL.latest_sal  AS "Sally_Spouse_Salut"
  ,E.JNT_SALUTATION AS "Joint Salutation"
  ,PM.pref_Mail_Name AS "Prospect Manager"
  ,PP.PPM_Names AS "Program Prospect Manager"
  ,HH.Stewardee_Alloc_Code
  ,HH.Stewardee_Alloc_Short_Name
  ,HH.Stewardee_Alloc_Long_Name
--  ,Don.Total_To_End
--  ,Case
--     When e.first_Name IS NOT Null AND s.spouse_first_name IS NOT Null
--       Then E.first_name ||' and '||S.spouse_first_name
--         Else 'Friends'
--           End Joint_First_Name
  ,Case
     When SA.ADDRESS_TYPE = 'Seasonal' Then 'Seasonal'
     When PA.Address_type IS NOT Null Then 'Preferred'
     Else Null
       End Addr_Type
  ,Case
     When SA.ADDRESS_TYPE = 'Seasonal' Then SA.Company_Name_1
     When PA.Address_type IS NOT Null Then PA.Company_Name_1
     Else Null
       End Company_Name_1
   ,Case
     When SA.ADDRESS_TYPE = 'Seasonal' Then SA.Company_Name_2
     When PA.Address_type IS NOT Null Then PA.Company_Name_2
     Else Null
       End Company_Name_2
   ,Case
     When SA.ADDRESS_TYPE = 'Seasonal' Then SA.Street1
     When PA.Address_type IS NOT Null Then PA.Street1
     Else Null
       End Street1
   ,Case
     When SA.ADDRESS_TYPE = 'Seasonal' Then SA.Street2
     When PA.Address_type IS NOT Null Then PA.Street2
     Else Null
       End Street2
   ,Case
     When SA.ADDRESS_TYPE = 'Seasonal' Then SA.Street3
     When PA.Address_type IS NOT Null Then PA.Street3
     Else Null
       End Street3
   ,Case
     When SA.ADDRESS_TYPE = 'Seasonal' Then SA.Foreign_Cityzip
     When PA.Address_type IS NOT Null Then PA.Foreign_Cityzip
     Else Null
       End Foreign_Zipcode
   ,Case
     When SA.ADDRESS_TYPE = 'Seasonal' Then SA.City
     When PA.Address_type IS NOT Null Then PA.City
     Else Null
       End City
  ,Case
     When SA.ADDRESS_TYPE = 'Seasonal' Then SA.State_Code
     When PA.Address_type IS NOT Null Then PA.State_Code
     Else Null
       End State
  ,Case
     When SA.ADDRESS_TYPE = 'Seasonal' Then SA.Zipcode
     When PA.Address_type IS NOT Null Then PA.Zipcode
     Else Null
       End Zipcode
  ,Case
     When SA.ADDRESS_TYPE = 'Seasonal' Then SA.Country
     When PA.Address_type IS NOT Null Then PA.Country
     Else Null
       End Country
  ,SPH.*
  ,E.Pref_Name_Sort
FROM ENTITY E
   INNER JOIN HH_Stewardees HH
   ON E.ID_NUMBER = HH.HOUSEHOLD_ID
   LEFT JOIN rpt_pbh634.v_entity_ksm_degrees D
   ON HH.HOUSEHOLD_ID = D."ID_NUMBER"
   LEFT JOIN HH_End_Donors Don
   ON HH.HOUSEHOLD_ID = Don.HOUSEHOLD_ID
   LEFT JOIN PrefAddress PA
   ON E.ID_NUMBER = PA.ID_NUMBER
   LEFT JOIN Seas_Address SA
   ON E.ID_NUMBER = SA.ID_NUMBER
   LEFT JOIN table(rpt_pbh634.ksm_pkg.tbl_special_handling_concat) SPH
   ON E.ID_NUMBER = SPH.ID_NUMBER
   LEFT JOIN Spouse S
   ON E.ID_number = S.ID_NUMBER
   LEFT JOIN Sally_Salut PSAL
   ON E.ID_number = PSAL.ID_Number
   LEFT JOIN Prospect_Manager PM
   ON E.ID_Number = PM.ID_Number
   LEFT JOIN Sally_Salut PSAL
   ON E.ID_number = PSAL.ID_Number
   LEFT JOIN Sally_Salut SSAL
   ON E.spouse_ID_Number = SSAL.ID_Number
   LEFT JOIN Prospect_Manager PM
   ON E.ID_Number = PM.ID_Number
   LEFT JOIN Prog_Prospect_Manager PP
   ON E.ID_Number = PP.ID_Number
   WHERE E.RECORD_STATUS_CODE = 'A'
  -- This returns people who do not have special handling restrictions
   AND SPH.NO_CONTACT IS NULL
   AND SPH.NO_MAIL_IND IS NULL

-- Put this in for the second tab with special handling restrictions
/* For the people that have been removed from Mailing  
   WHERE E.RECORD_STATUS_CODE != 'A'
   AND (SPH.NO_CONTACT = 'Y'
   OR SPH.NO_MAIL_IND = 'Y')

 */  
