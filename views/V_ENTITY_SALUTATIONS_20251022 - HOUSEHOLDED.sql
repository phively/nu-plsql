-- Household salutations: One row per household (household_primary_ksm = 'Y')
-- Join on: household_id_ksm

CREATE OR REPLACE VIEW V_ENTITY_SALUTATIONS_HOUSEHOLD AS
WITH P_Dean_Salut AS (
  SELECT
    mv_entity.donor_id
    ,MAX(sal.ucinn_ascendv2__inside_salutation__c)
      KEEP (
        DENSE_RANK FIRST ORDER BY
          CASE
            WHEN sal.ucinn_ascendv2__author_title__c = 'Dean of Kellogg School of Management' THEN 1
            ELSE 2
          END
          ,sal.createddate DESC
      ) AS latest_sal
    ,MAX(
      CASE
        WHEN sal.ucinn_ascendv2__author_title__c = 'Dean of Kellogg School of Management' THEN 'Dean Salutation'
        ELSE 'Latest Salutation'
      END
    ) KEEP (
      DENSE_RANK FIRST ORDER BY
        CASE
          WHEN sal.ucinn_ascendv2__author_title__c = 'Dean of Kellogg School of Management' THEN 1
          ELSE 2
        END
        ,sal.createddate DESC
    ) AS sal_source
  FROM mv_entity
  LEFT JOIN stg_alumni.ucinn_ascendv2__salutation__c sal
    ON sal.ucinn_ascendv2__contact__c = mv_entity.salesforce_id
  WHERE sal.ucinn_ascendv2__salutation_record_type_formula__c = 'Ind'
    AND sal.ucinn_ascendv2__salutation_type__c = 'Informal'
    AND sal.ucinn_ascendv2__inside_salutation__c != '-'
    AND sal.ucinn_ascendv2__inside_salutation__c NOT LIKE '% & %'
    AND sal.ucinn_ascendv2__inside_salutation__c NOT LIKE '% + %'
    AND LOWER(sal.ucinn_ascendv2__inside_salutation__c) NOT LIKE '% and %'
    AND LOWER(sal.ucinn_ascendv2__inside_salutation__c) NOT LIKE '%mr. %'
    AND LOWER(sal.ucinn_ascendv2__inside_salutation__c) NOT LIKE '%mrs. %'
    AND LOWER(sal.ucinn_ascendv2__inside_salutation__c) NOT LIKE '%ms. %'
    AND LOWER(sal.ucinn_ascendv2__inside_salutation__c) NOT LIKE '%miss %'
    AND LOWER(sal.ucinn_ascendv2__inside_salutation__c) NOT LIKE '%dr. %'
    AND LOWER(sal.ucinn_ascendv2__inside_salutation__c) NOT LIKE '%prof. %'
  GROUP BY mv_entity.donor_id
)

, NAMES AS (
  SELECT DISTINCT
    e.donor_id
    ,CASE
      WHEN e.is_deceased_indicator = 'Y' THEN NULL
      WHEN TRIM(PDS.latest_sal) IS NOT NULL THEN TRIM(PDS.latest_sal)
      WHEN TRIM(e.first_name) IS NOT NULL AND e.first_name NOT LIKE '%.%' THEN TRIM(e.first_name)
      ELSE NULL
    END AS P_Dean_Salut
    ,CASE
      WHEN e.is_deceased_indicator = 'Y' THEN 'Deceased'
      WHEN TRIM(PDS.latest_sal) IS NOT NULL THEN PDS.sal_source
      WHEN TRIM(e.first_name) IS NOT NULL AND e.first_name NOT LIKE '%.%' THEN 'Entity First Name'
      ELSE NULL
    END AS P_Dean_Source
    ,CASE
      WHEN spouse.is_deceased_indicator = 'Y' THEN NULL
      WHEN TRIM(PDS_S.latest_sal) IS NOT NULL THEN TRIM(PDS_S.latest_sal)
      WHEN TRIM(spouse.first_name) IS NOT NULL AND spouse.first_name NOT LIKE '%.%' THEN TRIM(spouse.first_name)
      ELSE NULL
    END AS Spouse_Dean_Salut
    ,CASE
      WHEN spouse.is_deceased_indicator = 'Y' THEN 'Deceased'
      WHEN TRIM(PDS_S.latest_sal) IS NOT NULL THEN PDS_S.sal_source
      WHEN TRIM(spouse.first_name) IS NOT NULL AND spouse.first_name NOT LIKE '%.%' THEN 'Entity First Name'
      ELSE NULL
    END AS Spouse_Dean_Source
    ,CASE
      WHEN e.is_deceased_indicator = 'Y' THEN NULL
      ELSE e.full_name
    END AS p_full_name
    ,CASE
      WHEN spouse.is_deceased_indicator = 'Y' THEN NULL
      ELSE spouse.full_name
    END AS spouse_full_name
  FROM mv_entity e
  LEFT JOIN mv_entity spouse
    ON spouse.donor_id = e.spouse_donor_id
  LEFT JOIN P_Dean_Salut PDS
    ON PDS.donor_id = e.donor_id
  LEFT JOIN P_Dean_Salut PDS_S
    ON PDS_S.donor_id = e.spouse_donor_id
  WHERE e.person_or_org = 'P'
)
SELECT DISTINCT 
    e.household_id_ksm
    ,e.household_primary_ksm
    ,n.donor_id AS p_donor_id
    ,n.P_Dean_Salut AS p_dean_salut
    ,n.p_full_name
    ,n.P_Dean_Source AS p_dean_source
    ,dp.degrees_concat AS p_degrees_concat
    ,dp.program AS p_program
    ,e.spouse_donor_id
    ,n.Spouse_Dean_Salut AS spouse_dean_salut
    ,n.spouse_full_name
    ,n.Spouse_Dean_Source AS spouse_dean_source
    ,ds.degrees_concat AS spouse_degrees_concat
    ,ds.program AS spouse_program
    ,CASE
      WHEN n.P_Dean_Salut IS NOT NULL AND n.Spouse_Dean_Salut IS NOT NULL
        THEN n.P_Dean_Salut || ' and ' || n.Spouse_Dean_Salut
      WHEN n.P_Dean_Salut IS NOT NULL THEN n.P_Dean_Salut
      WHEN n.Spouse_Dean_Salut IS NOT NULL THEN n.Spouse_Dean_Salut
    END AS joint_dean_salut
    ,CASE
      WHEN n.p_full_name IS NOT NULL AND n.spouse_full_name IS NOT NULL
        THEN n.p_full_name || ' and ' || n.spouse_full_name
      WHEN n.p_full_name IS NOT NULL THEN n.p_full_name
      WHEN n.spouse_full_name IS NOT NULL THEN n.spouse_full_name
    END AS joint_fullname
FROM NAMES n
INNER JOIN mv_entity e
  ON n.donor_id = e.donor_id
LEFT JOIN mv_entity_ksm_degrees dp
  ON e.donor_id = dp.donor_id
LEFT JOIN mv_entity_ksm_degrees ds
  ON e.spouse_donor_id = ds.donor_id
WHERE e.household_primary_ksm = 'Y'
;
