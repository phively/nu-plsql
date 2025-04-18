-- Test records
Create Or Replace View test_v_degmap As

  Select NULL as donor_id, NULL as deg_short_desc From DUAL
  -- FT
  Union All Select '0000002207' as donor_id, 'FT' as deg_short_desc From DUAL
  Union All Select '0000016835' as donor_id, 'FT-1Y' as deg_short_desc From DUAL
  Union All Select '0000007247' as donor_id, 'FT-2Y' as deg_short_desc From DUAL
  Union All Select '0000002116' as donor_id, 'FT-CB' as deg_short_desc From DUAL
  Union All Select '0000003607' as donor_id, 'FT-EB' as deg_short_desc From DUAL
  Union All Select '0000291995' as donor_id, 'FT-JDMBA' as deg_short_desc From DUAL
  Union All Select '0000647203' as donor_id, 'FT-KENNEDY' as deg_short_desc From DUAL
  Union All Select '0000856140' as donor_id, 'FT-MBAi' as deg_short_desc From DUAL
  Union All Select '0000668233' as donor_id, 'FT-MDMBA' as deg_short_desc From DUAL
  Union All Select '0000441243' as donor_id, 'FT-MMGT' as deg_short_desc From DUAL
  Union All Select '0000298407' as donor_id, 'FT-MMM' as deg_short_desc From DUAL
  Union All Select '0000390813' as donor_id, 'FT-MS' as deg_short_desc From DUAL
  -- EMBA
  Union All Select '0000465027' as donor_id, 'EMP' as deg_short_desc From DUAL
  Union All Select '0000542590' as donor_id, 'EMP-CAN' as deg_short_desc From DUAL
  Union All Select '0000733116' as donor_id, 'EMP-CHI' as deg_short_desc From DUAL
  Union All Select '0000490295' as donor_id, 'EMP-FL' as deg_short_desc From DUAL
  Union All Select '0000438568' as donor_id, 'EMP-GER' as deg_short_desc From DUAL
  Union All Select '0000418885' as donor_id, 'EMP-HK' as deg_short_desc From DUAL
  Union All Select '0000255045' as donor_id, 'EMP-IL' as deg_short_desc From DUAL
  Union All Select '0000426947' as donor_id, 'EMP-ISR' as deg_short_desc From DUAL
  Union All Select '0000642174' as donor_id, 'EMP-JAN' as deg_short_desc From DUAL
  -- PT
  Union All Select '0000046397' as donor_id, 'TMP' as deg_short_desc From DUAL
  Union All Select '0000667034' as donor_id, 'TMP-SAT' as deg_short_desc From DUAL
  Union All Select '0000708371' as donor_id, 'TMP-SATXCEL' as deg_short_desc From DUAL
  Union All Select '0000664740' as donor_id, 'TMP-XCEL' as deg_short_desc From DUAL
  -- PHD
  Union All Select '0000072509' as donor_id, 'PHD' as deg_short_desc From DUAL
  -- EXECED
  Union All Select '0000833542' as donor_id, 'CERT' as deg_short_desc From DUAL
  Union All Select '0000133168' as donor_id, 'CERT-AEP' as deg_short_desc From DUAL
  Union All Select '0000733770' as donor_id, 'CERT-LLM' as deg_short_desc From DUAL
  Union All Select '0000016551' as donor_id, 'EXECED' as deg_short_desc From DUAL
  -- UNK
  Union All Select '0000212759' as donor_id, 'EXECED' as deg_short_desc From DUAL
  Union All Select '0000717174' as donor_id, 'EXECED' as deg_short_desc From DUAL
  Union All Select '0000837120' as donor_id, 'EXECED' as deg_short_desc From DUAL
  -- NONGRD - various; spot check above
;

-- Previously "Department" in CATracks
Select *
From stg_alumni.ucinn_ascendv2__academic_organization__c
;

Select *
From dm_alumni.dim_academic_organization
;

-- Degree types
Select *
From stg_alumni.ucinn_ascendv2__degree_code__c
;

-- Degrees
Select *
From stg_alumni.ucinn_ascendv2__degree_information__c
;

Select *
From dm_alumni.dim_degree_detail
;

Select
  degmap.deg_short_desc
  , degdet.constituent_donor_id
  , degdet.constituent_name
  , degdet.degree_record_id
  , degdet.degree_status
  , degdet.degree_northwestern_university_indicator
  , degdet.degree_organization_name
  , degdet.degree_school_name
  , degdet.degree_level
  , degdet.degree_year
  , degdet.degree_conferred_year
  , degdet.degree_reunion_year
  , degdet.degree_code
  , degdet.degree_name
  , nullif(degdet.degree_concentration_desc, '-')
    As degree_concentration_desc
  , acaorg.ucinn_ascendv2__code__c
    As department_code
  , acaorg.ucinn_ascendv2__description_short__c
    As department_desc
  , acaorg.ucinn_ascendv2__description_long__c
    As department_desc_full
  , degdet.degree_campus
  , degdet.degree_major_name
  , degdet.degree_minor_name
  , deginf.ap_notes__c
    As degree_notes
  , trunc(degdet.etl_update_date)
    As etl_update_date
From dm_alumni.dim_degree_detail degdet
-- Degree information detail
Inner Join stg_alumni.ucinn_ascendv2__degree_information__c deginf
  On deginf.name = degdet.degree_record_id
-- Academic orgs, aka department
Left Join stg_alumni.ucinn_ascendv2__academic_organization__c acaorg
  On acaorg.id = deginf.ap_academic_group__c
Inner Join test_v_degmap degmap
  On degmap.donor_id = degdet.constituent_donor_id
;

-- Reduce use of dm_alumni.dim_degree_detail
Drop Materialized View tmp_mv_degree
;

Create Materialized View tmp_mv_degree As 

  Select
    dcon.constituent_donor_id
    , dcon.full_name
      As constituent_name
    , deginf.name
      As degree_record_id
    , deginf.ap_status__c
      As degree_status
    , Case
        When deginf.Ucinn_Ascendv2__Degree_Institution__c = '001O800000B8YHhIAN' -- Northwestern University
          Then 'Y'
          Else 'N'
        End
      As nu_indicator
    , dorg.organization_name
      As degree_organization_name
    , deginf.ap_school_name_formula__c
      As degree_school_name
    , deginf.ap_degree_type_from_degreecode__c
      As degree_level
    , deginf.ucinn_ascendv2__conferred_degree_year__c
      As degree_year
    , deginf.ucinn_ascendv2__reunion_year__c
      As degree_reunion_year
    , deginf.ucinn_ascendv2__degree_date__c
      As degree_grad_date
    , degcd.ucinn_ascendv2__degree_code__c
      As degree_code
    , degcd.ucinn_ascendv2__description__c
      As degree_name
    , acaorg.ucinn_ascendv2__code__c
      As department_code
    , acaorg.ucinn_ascendv2__description_short__c
      As department_desc
    , acaorg.ucinn_ascendv2__description_long__c
      As department_desc_full
    , deginf.ap_campus__c
      As degree_campus
    , prog.ap_program_code__c
      As degree_program_code
    , prog.name
      As degree_program
    , spec.name
      As degree_concentration_desc
    , postcd.ap_major_code__c
      As degree_major_code_1
    , postcd2.ap_major_code__c
      As degree_major_code_2
    , postcd3.ap_major_code__c
      As degree_major_code_3
    , postcd.name
      As degree_major_1
    , postcd2.name
      As degree_major_2
    , postcd3.name
      As degree_major_3
    , deginf.ap_notes__c
      As degree_notes
    , trunc(deginf.etl_update_date) -- data refresh timestamp
      As etl_update_date
  -- Degree information detail
  From stg_alumni.ucinn_ascendv2__degree_information__c deginf
  -- Constituent and organization lookup tables
  Inner Join dm_alumni.dim_constituent dcon
    On dcon.constituent_salesforce_id = deginf.ucinn_ascendv2__contact__c
  Left Join dm_alumni.dim_organization dorg
    On dorg.organization_salesforce_id = deginf.ucinn_ascendv2__degree_institution__c
  -- Degree code
  Left Join stg_alumni.ucinn_ascendv2__degree_code__c degcd
    On degcd.id = deginf.ucinn_ascendv2__degree_code__c
  -- Major codes
  Left Join stg_alumni.ucinn_ascendv2__post_code__c postcd
    On postcd.id = deginf.ucinn_ascendv2__post_code__c
  Left Join stg_alumni.ucinn_ascendv2__post_code__c postcd2
    On postcd2.id = deginf.ucinn_ascendv2__second_major_post_code__c
  Left Join stg_alumni.ucinn_ascendv2__post_code__c postcd3
    On postcd3.id = deginf.ap_third_major_post_code__c
  -- Program/cohort
  Left Join stg_alumni.ap_program__c prog
    On prog.id = deginf.ap_program_class_section__c
  -- Specialty code
  Left Join stg_alumni.ucinn_ascendv2__specialty__c spec
    On spec.id = deginf.ucinn_ascendv2__concentration_specialty__c
  -- Academic orgs, aka department
  Left Join stg_alumni.ucinn_ascendv2__academic_organization__c acaorg
    On acaorg.id = deginf.ap_academic_group__c
;

-- Check dw_pkg for completeness
Select
  degmap.deg_short_desc
  , deg.*
From tmp_mv_degree deg
Inner Join test_v_degmap degmap
  On degmap.donor_id = deg.constituent_donor_id
Where deg.nu_indicator = 'Y'
;
