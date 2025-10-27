-- Individual salutations: One row per donor_id
-- Join on: donor_id

CREATE OR REPLACE VIEW V_ENTITY_SALUTATIONS_INDIVIDUAL AS
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

SELECT DISTINCT 
    e.donor_id
    ,e.household_id_ksm
    ,e.household_primary_ksm
    ,CASE
      WHEN e.is_deceased_indicator = 'Y' THEN NULL
      WHEN TRIM(PDS.latest_sal) IS NOT NULL THEN TRIM(PDS.latest_sal)
      WHEN TRIM(e.first_name) IS NOT NULL AND e.first_name NOT LIKE '%.%' THEN TRIM(e.first_name)
      ELSE NULL
    END AS dean_salut
    ,CASE
      WHEN e.is_deceased_indicator = 'Y' THEN 'Deceased'
      WHEN TRIM(PDS.latest_sal) IS NOT NULL THEN PDS.sal_source
      WHEN TRIM(e.first_name) IS NOT NULL AND e.first_name NOT LIKE '%.%' THEN 'Entity First Name'
      ELSE NULL
    END AS dean_source
    ,CASE
      WHEN e.is_deceased_indicator = 'Y' THEN NULL
      ELSE e.full_name
    END AS full_name
    ,d.degrees_concat
    ,d.program
FROM mv_entity e
LEFT JOIN P_Dean_Salut PDS
  ON PDS.donor_id = e.donor_id
LEFT JOIN mv_entity_ksm_degrees d
  ON e.donor_id = d.donor_id
WHERE e.person_or_org = 'P'
;
