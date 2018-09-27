With

Alumni AS (
      Select DE.ID_Number
      ,Case when DE.ID_NUMBER IS NOT NULL
            Then 'Y'
              End Alumni_IND
      From rpt_pbh634.v_entity_ksm_degrees DE
      Inner Join rpt_pbh634.v_entity_ksm_households E
      ON E.ID_number = DE.ID_number
      Where DE.PROGRAM NOT Like '%NONGRD%'
),

KLC AS (
      Select *
      From KLC_17_18
),

Campaign_Donors AS(
      Select *
      From IR_ALL_Campaign
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
Select ID_number From GAB
UNION
Select ID_number From BOT
UNION
Select ID_number From KAC
UNION
Select ID_number From ACT_CL
UNION
Select ID_number From PHS
UNION
Select ID_Number FROM Alumni
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
      ,A.Alumni_IND
      FROM ENTITY E
      LEFT JOIN ENTITY SE
      ON E.SPOUSE_ID_NUMBER = SE.ID_NUMBER
      LEFT JOIN Alumni A
      ON E.ID_NUMBER = A.ID_Number
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
  E.ID_NUMBER AS P_ID_NUMBER
  ,E.Pref_Mail_Name AS P_Pref_Name
  ,Sal.Dean_salut AS P_Dean_Salut
  ,E.RECORD_STATUS_CODE P_Record_Status 
  ,D.DEGREES_CONCAT P_Degrees
  ,E.Gender_Code AS P_Gender
  ,E.spouse_ID_Number AS Spouse_ID
  ,S.record_status_code AS Spouse_Status
  ,S.pref_mail_name AS Spouse_Pref_Name
  ,SSAL.Dean_salut AS Spouse_Dean_Salut
  ,SD.DEGREES_CONCAT Spouse_Degrees
  ,S.gender_code AS Spouse_Gender
  , Case When JDS.Joint_Dean_Salut iS NOT NULL Then JDS.Joint_Dean_Salut
         When JDS.Joint_Dean_Salut iS NULL AND Sal.Dean_salut IS NOT NULL THEN Sal.Dean_Salut
         When JDS.Joint_Dean_Salut iS NULL AND SSAL.Dean_salut IS NOT NULL THEN SSAL.Dean_salut
           ELSE NULL
             End JOINT_DeanSalut
    , Case When JPN.Joint_prefname iS NOT NULL Then JPN.Joint_prefname
         When JPN.Joint_prefname iS NULL AND Sal.Dean_salut IS NOT NULL THEN Sal.Dean_Salut
         When JPN.Joint_prefname iS NULL AND SSAL.Dean_salut IS NOT NULL THEN SSAL.Dean_salut
           ELSE NULL
             End JOINT_PREF_MAIL_NAME
  ,EM.EMAIL_ADDRESS
  ,PM.pref_Mail_Name AS "Prospect Manager"
  ,PP.PPM_Names AS "Program Prospect Manager"
  ,SPH.special_handling_concat
  ,SPH.No_contact
  ,SPH.NO_Mail_IND
  ,SPH.NO_EMail_IND
  ,E.Pref_Name_Sort
  ,A.Alumni_IND
  ,KLC.KLC_17_18
  ,CD.IR_ALL_Donors
  ,GAB.GAB
  ,BOT.Trustee
  ,KAC.KAC
  ,ACT.Club_Leaders
  ,PHS.PHS
FROM ENTITY E
   INNER JOIN ALL_Segments ALS
   ON E.ID_Number = ALS.ID_Number
   LEFT JOIN rpt_pbh634.v_entity_ksm_degrees D
   ON E.ID_Number = D."ID_NUMBER"
   LEFT JOIN rpt_pbh634.v_entity_ksm_degrees SD
   ON E.SPOUSE_ID_NUMBER = D."ID_NUMBER"
   LEFT JOIN Email EM
   ON E.ID_Number = EM.ID_Number
   LEFT JOIN table(rpt_pbh634.ksm_pkg.tbl_special_handling_concat) SPH
   ON E.ID_NUMBER = SPH.ID_NUMBER
   LEFT JOIN Spouse S
   ON E.ID_number = S.ID_NUMBER
   LEFT JOIN Prospect_Manager PM
   ON E.ID_Number = PM.ID_Number
   LEFT JOIN Sally_salut SAL
   ON E.ID_Number = SAL.ID_number
   LEFT JOIN Sally_salut SSAL
   ON E.SPOUSE_ID_NUMBER = SSAL.spouse_ID_number
   LEFT JOIN JOINT_Deans_salut JDS
   ON E.ID_Number = JDS.ID_Number
   LEFT JOIN JOINT_Prefname JPN
   ON E.ID_Number = JPN.ID_number
   LEFT JOIN Prospect_Manager PM
   ON E.ID_Number = PM.ID_Number
   LEFT JOIN Prog_Prospect_Manager PP
   ON E.ID_Number = PP.ID_Number
   LEFT JOIN Alumni A
   ON E.ID_NUMBER = A.ID_Number
   LEFT JOIN KLC
   ON E.ID_NUMBER = KLC.ID_number
   LEFT JOIN campaign_donors CD
   ON E.ID_Number = CD.ID_Number
   LEFT JOIN GAB
   ON E.ID_number = GAB.ID_number
   LEFT JOIN BOT
   ON E.ID_Number = BOT.ID_Number
   LEFT JOIN KAC
   ON E.ID_Number = KAC.ID_number
   LEFT JOIN ACT_CL ACT
   ON E.ID_number = ACT.ID_Number
   LEFT JOIN PHS
   ON E.ID_Number = PHS.ID_number
   WHERE E.RECORD_STATUS_CODE = 'A'
   AND SPH.NO_CONTACT IS NULL
   AND SPH.NO_EMAIL_IND IS NULL
   
/* For the people that have been removed from Mailing  
   WHERE E.RECORD_STATUS_CODE = 'D'
   OR (SPH.NO_CONTACT = 'Y'
   OR SPH.NO_EMAIL_IND = 'Y')
 */  
