With

KLC AS (
      Select *
      From KLC_17_18
),

Campaign_Donors AS(
      Select *
      From IR_100K_Campaign
),

BE_Donors AS (
      Select 
      HH.household_ID AS ID_Number
      , case When household_ID is NOT NULL
         Then 'Y'
           Else ' '
           End BE_Donors
  --  , HH.Report_name
  --  , e.record_status_code
  --  , HH.tx_Number
  --  , HH.transaction_type
  --  , HH.hh_recognition_credit
      FROM rpt_pbh634.v_ksm_giving_campaign_trans_hh HH
      LEFT JOIN Entity e
      ON e.Id_number = HH.HOUSEHOLD_ID
      Where (HH.transaction_type LIKE 'Bequest%Expectancy'
      OR HH.transaction_type LIKE 'Bequest%Received')
      AND HH.hh_recognition_credit > 0
      AND e.record_status_code = 'A'
      GROUP BY hh.HOUSEHOLD_ID
),

GAB AS (
      SELECT c.id_number
      , case When ID_Number is NOT NULL
         Then 'Y'
           Else ' '
           End GAB
      From committee c
      where c.committee_code = 'U'
      AND c.committee_status_code = 'C'
),

BOT AS (
      SELECT c.ID_Number
      , case When ID_Number is NOT NULL
         Then 'Y'
           Else ' '
           End Trustee
      From committee c
      where c.committee_code = 'TBOT'
      AND c.committee_status_code = 'C'   
),

KAC AS (
      SELECT c.id_number
      , case When ID_Number is NOT NULL
         Then 'Y'
           Else ' '
           End KAC
      From committee c
      where c.committee_code = 'KACNA'
      AND c.committee_status_code = 'C'
),

ACT_CL AS (
      SELECT c.ID_Number
      , case When ID_Number is NOT NULL
         Then 'Y'
           Else ' '
           End Club_Leaders
      From committee c
      where c.committee_code = 'KACLE'
      AND c.committee_status_code = 'C'
),

PHS AS (
      SELECT c.ID_number
      , case When ID_Number is NOT NULL
         Then 'Y'
           Else ' '
           End PHS
      From committee c
      where c.committee_code = 'KPH'
      AND c.committee_status_code = 'C'
),

ALL_Segments AS(
Select ID_number From KLC
UNION
Select ID_number From Campaign_Donors
UNION
Select ID_number From BE_Donors
UNION
Select ID_number From GAB
UNION
Select ID_number From BOT
UNION
Select ID_number From KAC
UNION
Select ID_number From ACT_CL
UNION
Select ID_number From PHS
),

Spouse AS(
       SELECT 
       E.ID_NUMBER
      ,E.SPOUSE_ID_NUMBER
      ,SE.RECORD_STATUS_CODE
      ,SE.PREF_MAIL_NAME
      ,SE.FIRST_NAME
      ,SE.LAST_NAME
      ,SE.Gender_Code
      FROM ENTITY E
      LEFT JOIN ENTITY SE
      ON E.SPOUSE_ID_NUMBER = SE.ID_NUMBER
      WHERE
      SE.RECORD_STATUS_CODE = 'A'
),

P_Sally_Salut AS(
Select
      ID_Number
      , max(salutation) keep(dense_rank First Order By ID_number Asc, date_modified) AS Latest_Sal
      From salutation
      WHERE signer_ID_number = '0000299349'
      AND Active_IND = 'Y'
      AND salutation NOT LIKE '%and%'
      Group by ID_Number
      Order by ID_number
),

Sally_Salut AS (
      SELECT * 
      FROM (Select E.ID_Number
      , E.Spouse_Id_Number
      , Case When PSS.Latest_sal IS NOT NULL Then PSS.Latest_Sal
             -- '%.%' means there is a dot somewhere in first name (initial)
             When PSS.Latest_sal IS NULL AND E.First_name != ' ' AND E.First_name NOT LIKE '%.%'
               THEN E.First_Name
             When PSS.Latest_sal IS NULL AND E.First_name = ' ' AND E.First_name LIKE '%.%'
               THEN NULL
          ELSE NULL
            END Dean_Salut
      From Entity E
      Left Join P_Sally_Salut PSS
      ON PSS.Id_number = E.ID_number)
      Where Dean_Salut IS NOT NULL
),

JOINT_DEANS_SALUT AS ( 
      Select distinct
            HH.ID_NUMBER
            , PS.Dean_Salut || ' and ' || SSA.Dean_salut AS Joint_Dean_Salut
      FROM rpt_pbh634.v_entity_ksm_households HH
      LEFT Join Sally_Salut PS
      ON HH.Household_LIST_First = PS.Id_Number
      LEFT Join Sally_Salut SSA
      ON HH.Household_LIST_Second = SSA.Id_Number
      WHERE PS.Dean_Salut IS NOT NULL
      AND SSA.Dean_salut IS NOT NULL
),

JOINT_PREFNAME AS ( 
      Select distinct
            HH.ID_NUMBER
            , PE.Pref_Mail_Name || ' and ' || SE.Pref_Mail_Name AS Joint_Prefname
      FROM rpt_pbh634.v_entity_ksm_households HH
      LEFT Join Entity PE
      ON HH.Household_LIST_First = PE.Id_Number
      LEFT Join Entity SE
      ON HH.Household_LIST_Second = SE.Id_Number
      WHERE PE.Pref_Mail_Name IS NOT NULL
      AND SE.Pref_Mail_Name IS NOT NULL
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
),

Emails AS (
      SELECT *
      FROM email
      WHERE email_status_code = 'A'
      AND preferred_IND = 'Y'
)

SELECT DISTINCT
  E.ID_NUMBER AS Household_ID
  ,E.Pref_Mail_Name P_Pref_Mail_Name
  ,Sal.Dean_salut AS P_Dean_Salut
  ,E.RECORD_STATUS_CODE P_Record_Status 
  ,D.DEGREES_CONCAT P_Degrees_Concat
  ,E.Gender_Code As P_Gender
  ,E.spouse_ID_Number AS Spouse_ID
  ,S.pref_mail_name AS Spouse_Pref_Name
  ,SSAL.Dean_salut AS Spouse_Dean_Salut
  ,S.record_status_code AS Spouse_Status
  ,SD.DEGREES_CONCAT S_Degrees_concat
  ,S.gender_code AS Spouse_Gender
  ,JDS.Joint_Dean_Salut
  ,JPN.Joint_prefname
  ,PM.pref_Mail_Name AS Prospect_Manager
  ,PP.PPM_Names AS Program_Prospect_Manager
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
  ,SPH.special_handling_concat
  ,SPH.No_contact
  ,SPH.NO_Mail_IND
  ,SPH.NO_EMail_IND
  ,KLC.KLC_17_18
  ,CD.Campaign_$100K_Donors
  ,BE.BE_donors
  ,GAB.GAB
  ,BOT.Trustee
  ,KAC.KAC
  ,ACT.Club_Leaders
  ,PHS.PHS
  ,E.Pref_Name_Sort
FROM rpt_pbh634.v_entity_ksm_households HH
   INNER JOIN ALL_Segments ALS
   ON HH.HOUSEHOLD_ID = ALS.ID_Number
   LEFT JOIN Entity E
   ON HH.HOUSEHOLD_ID = E.ID_Number
   LEFT JOIN rpt_pbh634.v_entity_ksm_degrees D
   ON HH.Household_ID = D."ID_NUMBER"
   LEFT JOIN rpt_pbh634.v_entity_ksm_degrees SD
   ON E.SPOUSE_ID_NUMBER = D."ID_NUMBER"
   LEFT JOIN PrefAddress PA
   ON HH.Household_ID = PA.ID_NUMBER
   LEFT JOIN Seas_Address SA
   ON HH.Household_ID = SA.ID_NUMBER
   LEFT JOIN table(rpt_pbh634.ksm_pkg.tbl_special_handling_concat) SPH
   ON HH.Household_ID = SPH.ID_NUMBER
   LEFT JOIN Spouse S
   ON HH.Household_ID = S.ID_NUMBER
   LEFT JOIN Prospect_Manager PM
   ON HH.Household_ID = PM.ID_Number
   LEFT JOIN Sally_salut SAL
   ON HH.HOUSEHOLD_ID = SAL.ID_number
   LEFT JOIN Sally_salut SSAL
   ON HH.HOUSEHOLD_SPOUSE_ID = SSAL.spouse_ID_number
   LEFT JOIN JOINT_Deans_salut JDS
   ON HH.Household_ID = JDS.ID_Number
   LEFT JOIN JOINT_Prefname JPN
   ON HH.Household_ID = JPN.ID_number
   LEFT JOIN Prospect_Manager PM
   ON HH.Household_ID = PM.ID_Number
   LEFT JOIN Prog_Prospect_Manager PP
   ON HH.Household_ID = PP.ID_Number
   LEFT JOIN KLC
   ON HH.Household_ID = KLC.ID_number
   LEFT JOIN campaign_donors CD
   ON HH.Household_ID = CD.ID_Number
   LEFT JOIN BE_Donors BE
   ON HH.Household_ID = BE.ID_Number
   LEFT JOIN GAB
   ON HH.Household_ID = GAB.ID_number
   LEFT JOIN BOT
   ON HH.Household_ID = BOT.ID_Number
   LEFT JOIN KAC
   ON HH.Household_ID = KAC.ID_number
   LEFT JOIN ACT_CL ACT
   ON HH.Household_ID = ACT.ID_Number
   LEFT JOIN PHS
   ON HH.Household_ID = PHS.ID_number
   WHERE E.RECORD_STATUS_CODE = 'A'
   AND SPH.NO_CONTACT IS NULL
   AND SPH.NO_MAIL_IND IS NULL
   
/* For the people that have been removed from Mailing 
   WHERE E.RECORD_STATUS_CODE = 'D'
   OR (SPH.NO_CONTACT = 'Y'
   OR SPH.NO_MAIL_IND = 'Y')
    */   
   
   
   

 
