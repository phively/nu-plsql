-- Create Or Replace View KELLOGG_ALUMNI_VIEWER.NU_KSM_V_CONSTITUENT As
Select
    constituent_salesforce_id
    As salesforce_id
  , constituent_household_account_salesforce_id
    As household_id
  , household_primary_constituent_indicator
    As household_primary
  , constituent_donor_id
    As donor_id
  , full_name
  , trim(trim(last_name || ', ' || first_name) || ' ' || Case When middle_name != '-' Then middle_name End)
    As sort_name
  , is_deceased_indicator
  , primary_constituent_type
  , institutional_suffix
  , spouse_constituent_donor_id
    As spouse_donor_id
  , spouse_name
  , spouse_instituitional_suffix
  , preferred_address_city
  , preferred_address_state
  , preferred_address_country_name
  , trunc(etl_update_date)
    As etl_update_date
From DM_ALUMNI.DIM_CONSTITUENT entity
;

-- Checking degree info
With

degmap As (
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
  Union All Select '0000724349' as donor_id, 'FT-MDMBA' as deg_short_desc From DUAL
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
)

Select
  degmap.donor_id
  , degmap.deg_short_desc
  , degrees.ap_school_name_formula__c
    As school_name_formula
  , degrees.ucinn_ascendv2__class_level__c
    As class_level
  , degrees.ucinn_ascendv2__conferred_degree_year__c
    As conferred_year
  , degrees.ap_campus__c
From STG_ALUMNI.UCINN_ASCENDV2__DEGREE_INFORMATION__C degrees
Inner Join DM_ALUMNI.DIM_CONSTITUENT constituent
  On constituent.constituent_salesforce_id = degrees.ucinn_ascendv2__contact__c
Inner Join degmap
  On degmap.donor_id = constituent.constituent_donor_id
Where degrees.Ucinn_Ascendv2__Degree_Institution__c = '001O800000B8YHhIAN' -- Northwestern
;

-- Create Or Replace View KELLOGG_ALUMNI_VIEWER.NU_KSM_V_DEGREES
With

degmap As (
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
  Union All Select '0000724349' as donor_id, 'FT-MDMBA' as deg_short_desc From DUAL
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
)

Select
    constituent_donor_id
  , constituent_name
  , degmap.deg_short_desc
  , degree_status
  , degree_school_name
  , degree_level
  , degree_year
  , degree_conferred_year
  , degree_reunion_year
  , degree_code
  , degree_name
  , degree_concentration_desc
  , degree_campus
  , degree_major_name
From DM_ALUMNI.DIM_DEGREE_DETAIL degree
Inner Join degmap
  On degmap.donor_id = degree.constituent_donor_id
;

-- Organization
Select *
From dm_alumni.dim_organization org
;

Select
  organization_salesforce_id
  As salesforce_id
  , organization_ultimate_parent_donor_id
    As household_id
  , organization_donor_id
    As donor_id
  , Case When organization_donor_id = organization_ultimate_parent_donor_id Then 'Y' End
    As household_primary
  , organization_name
  , organization_name
    As sort_name
  , organization_inactive_indicator
  , organization_type
  , organization_ultimate_parent_donor_id
    As org_ult_parent_donor_id
  , organization_ultimate_parent_name
    As org_ult_parent_name
  , preferred_address_city
  , preferred_address_state
  , preferred_address_country_name
  , trunc(etl_update_date)
    As etl_update_date
From dm_alumni.dim_organization org
;

-- Designation (allocation)
Select *
From dm_alumni.dim_designation
;

Select
  designation_record_id
  , designation_name
  , designation_status
  , legacy_allocation_code
  , fin_fund
  , Case
      When fin_fund Not In ('Historical Data', '-')
        Then substr(fin_fund, 0, 3)
      End
    As fin_fund_id
  , fin_project
    As fin_project_id
  , Case
      When designation_activity != '-'
        Then designation_activity
      End
    As fin_activity
  , Case
      When designation_fin_department_id != '-'
        Then designation_fin_department_id
      End
    As fin_department_id
  , Case
      When designation_school = 'Kellogg'
        Or designation_department_program_code Like '%Kellogg%'
      Then 'Y'
      End
    As ksm_flag
  , designation_school
  , designation_department_program_code
    As department_program
  , fasb_type
  , case_type
  , case_purpose
  , designation_tier_1
  , designation_tier_2
  , designation_comment
  , designation_date_added
  , designation_date_modified
  , gl_effective_date
  , gl_expiration_date
From dm_alumni.dim_designation
;
