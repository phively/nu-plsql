Create Or Replace View V_DEAN_SALUTATION As

WITH Spouse AS(
       SELECT 
       E.ID_NUMBER
      ,E.Institutional_Suffix
      ,E.SPOUSE_ID_NUMBER
      ,SE.RECORD_STATUS_CODE
      ,SE.PREF_MAIL_NAME
      ,SE.FIRST_NAME
      ,SE.LAST_NAME
      ,SE.Gender_Code
      FROM ENTITY E
      LEFT JOIN ENTITY SE ON E.SPOUSE_ID_NUMBER = SE.ID_NUMBER
      WHERE
      SE.RECORD_STATUS_CODE = 'A'
)




, P_Dean_Salut AS(
    Select
      ID_Number
      , max(salutation) keep(dense_rank First Order By ID_number Asc, date_modified Desc) AS Latest_Sal
      From salutation
      WHERE Active_IND = 'Y'
      AND salutation NOT LIKE '%and%'
      AND salutation_type_code = 'KM'
      Group by ID_Number
      Order by ID_number
)


, NAMES AS(
  Select Distinct
    E.id_number
    , Case
        When PDS.Latest_sal IS NOT NULL Then trim(PDS.Latest_Sal)
        -- '%.%' means there is a dot somewhere in first name (initial)
        When PDS.Latest_sal IS NULL AND e.First_name != ' ' AND e.First_name NOT LIKE '%.%'
          THEN trim(e.First_Name)
        When PDS.Latest_sal IS NULL AND e.First_name = ' ' AND e.First_name LIKE '%.%'
          THEN NULL
        ELSE NULL
        END
      As P_Dean_Salut
      
    , Case
        When PDS.Latest_sal IS NOT NULL Then 'P_Dean_Salut'
        -- '%.%' means there is a dot somewhere in first name (initial)
        When PDS.Latest_sal IS NULL AND e.First_name != ' ' AND e.First_name NOT LIKE '%.%'
          THEN 'Entity First Name'
        ELSE NULL
        END
      As P_Dean_Source
      
    , Case
        When pds_s.Latest_sal IS NOT NULL Then trim(pds_s.Latest_Sal)
        -- '%.%' means there is a dot somewhere in first name (initial)
        When pds_s.Latest_sal IS NULL AND spouse.First_name != ' ' AND spouse.First_name NOT LIKE '%.%'
          THEN trim(spouse.First_Name)
        When pds_s.Latest_sal IS NULL AND spouse.First_name = ' ' AND spouse.First_name LIKE '%.%'
          THEN NULL
        ELSE NULL
        END
      As Spouse_Dean_Salut
      
      , Case 
        When pds_s.Latest_sal IS NOT NULL Then 'Spouse_Dean_Salut'
        -- '%.%' means there is a dot somewhere in first name (initial)
        When pds_s.Latest_sal IS NULL AND spouse.First_name != ' ' AND spouse.First_name NOT LIKE '%.%'
          THEN 'Entity First Name'
        ELSE NULL
        END
      As Spouse_Dean_Source
      
    , e.pref_mail_name As p_pref_mail_name
    , spouse.pref_mail_name As spouse_pref_name
  From entity e
  Left Join entity spouse On spouse.id_number = e.spouse_id_number
  Left Join P_Dean_Salut pds On pds.id_number = e.id_number
  Left Join P_Dean_Salut pds_s On pds_s.id_number = e.spouse_id_number
)

  Select
      n.id_number
    , dp.degrees_concat
    , dp.program
    , n.P_Dean_Salut
    , n.p_pref_mail_name
    , n.P_Dean_Source
    , e.spouse_id_number
    , ds.degrees_concat as spouse_degrees_concat
    , ds.program as spouse_program
    , n.Spouse_Dean_Salut
    , n.spouse_pref_name
    , n.Spouse_Dean_Source
    , Case
        When n.P_Dean_Salut IS NOT NULL
          And n.Spouse_Dean_Salut IS NOT NULL
            Then n.P_Dean_Salut || ' and ' || n.Spouse_Dean_Salut
        End
      As Joint_Dean_Salut
    , Case
        When n.p_pref_mail_name IS NOT NULL
          And n.spouse_pref_name IS NOT NULL
            Then n.p_pref_mail_name || ' and ' || n.spouse_pref_name
        End
      As Joint_Prefname
  From NAMES n
  INNER JOIN entity e ON n.id_number = e.id_number
  LEFT JOIN RPT_PBH634.v_Entity_Ksm_Degrees dp ON e.id_number = dp.id_number
  LEFT JOIN RPT_PBH634.v_Entity_Ksm_Degrees ds ON e.spouse_id_number = ds.id_number
