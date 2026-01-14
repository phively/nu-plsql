With

-- Ensure alumni_base can be used to filter degrees recipe
alumni_base As (
  Select
    dc.constituent_salesforce_id
    , kd.donor_id
    , kd.full_name
  From dm_alumni.dim_constituent dc
  Inner Join mv_entity_ksm_degrees kd
    On kd.donor_id = dc.constituent_donor_id
)

-- Ensure these fields are available in degrees recipe
, c_degrees As (
  Select
    alumni_base.constituent_salesforce_id
    , alumni_base.donor_id
    , alumni_base.full_name
    , deginf.name
      As degree_record_id
    , deginf.ap_status__c
      As degree_status
    , Case
        When deginf.ucinn_ascendv2__degree_institution__c In ('001Uz00000Jp3SrIAJ', '001Uz00000NOVTpIAP') -- Northwestern University
          Then 'Y'
          Else 'N'
        End
      As nu_indicator
    , deginf.ap_school_name_formula__c
      As degree_school_name
    , deginf.ap_degree_type_from_degreecode__c
      As degree_level
    , degcd.ucinn_ascendv2__degree_code__c
      As degree_code
--    , degcd.ucinn_ascendv2__description__c
--      As degree_name
    , acaorg.ucinn_ascendv2__code__c
      As department_code
    , acaorg.ucinn_ascendv2__description_short__c
      As department_desc
--    , acaorg.ucinn_ascendv2__description_long__c
--      As department_desc_full
--    , deginf.ap_campus__c
--      As degree_campus
    , prog.ap_program_code__c
      As degree_program_code
--    , prog.name
--      As degree_program
  -- Degree information detail
  From stg_alumni.ucinn_ascendv2__degree_information__c deginf
  -- Use alumni base recipe stand-in to filter
  Inner Join alumni_base
    On alumni_base.constituent_salesforce_id = deginf.ucinn_ascendv2__contact__c
  -- Degree code
  Left Join stg_alumni.ucinn_ascendv2__degree_code__c degcd
    On degcd.id = deginf.ucinn_ascendv2__degree_code__c
  -- Program/cohort
  Left Join stg_alumni.ap_program__c prog
    On prog.id = deginf.ap_program_class_section__c
  -- Specialty code
  -- Academic orgs, aka department
  Left Join stg_alumni.ucinn_ascendv2__academic_organization__c acaorg
    On acaorg.id = deginf.ap_department__c
)

-- New datamart-side transformations; see the two case-whens
, prg As (
Select
  deg.donor_id
  , deg.full_name
  , deg.degree_record_id
  , deg.degree_level
  , deg.degree_status
  , Case
      When deg.degree_status In ('Inactive', 'Discontinued', 'Dismissed or Revoked')
        Then '50 NON'
      When deg.degree_status In ('Active', 'Deposited', 'Leave of Absence')
        Or deg.degree_code Like '%-STU'
        Then '10 STU'
      When degree_level Like '%Doctorate%'
        Then '01 PHD'
      When degree_level Like '%Master%'
        Then '02 MBA'
      When degree_level Like '%Undergrad%'
        Or degree_school_name = 'Undergraduate Business'
        Then '03 BBA'
      When degree_level Like '%Other%'
        Then '04 OTH'
      When degree_level Like '%Cert%'
        Then '05 CER'
      -- Placeholders
      When degree_level = 'Student_placeholder'
        Then '10 STU'
      When degree_level = 'Nongrad_placeholder'
        Then '50 NON'
      When degree_level Is Null
        Then '90 UNK'
      Else '99 TBD'
    End
    As degree_level_rank
  , deg.department_code
  , Case
      When deg.department_code In ('KGS2Y', '01KGS') -- New 2Y
        And deg.department_Desc Like '%2-Year MBA%'
        Then 'FT-2Y'
      When deg.department_code In ('KGS1Y', '011YR')  -- New 1Y
        And deg.department_desc Like '%1-Year MBA%'
        Then 'FT-1Y'
      When deg.department_code = '01MDB' -- Joint Feinberg
        Then 'MDMBA'
      When deg.department_code Like '01%' -- Full-time, joint full-time
        Then substr(deg.department_code, 3)
      When deg.department_code = '13JDM' -- Joint Law
        Then 'JDMBA'
      When deg.department_code = '13LCM' -- Law certificate
        Then 'LLM'
      When deg.department_code Like '41%' -- EMBA and IEMBA
        Then substr(deg.department_code, 3)
      When deg.department_code = '95BCH' -- College of Commerce 1
        Then 'BCH'
      When deg.department_code = '96BEV' -- College of Commerce 2
        Then 'BEV'
      When deg.department_code In ('AMP', 'AMPI', 'EDP', 'KSMEE')  -- KSM certificates
        Then deg.department_code
      When deg.department_code = '01MBI' -- Joint McCormick
        Then 'MBAI'
      When deg.department_code = '0000000' -- None
        Then ''
      Else deg.department_desc
    End As department_desc_short
From c_degrees deg
  Where deg.nu_indicator = 'Y' -- Northwestern University
    And (
      deg.degree_school_name Like ('%Kellogg%')
      Or deg.degree_school_name Like ('%Undergraduate Business%')
      Or deg.degree_code = 'MBAI' -- MBAI
      Or deg.degree_program_code In (
        '95BCH', '96BEV' -- College of Commerce
        , 'AMP', 'AMPI', 'EDP', 'KSMEE' -- KSMEE certificate
      )
    )
)

-- New datamart-side transformation; depends on prg above
Select
  prg.*
  , Case
      When degree_level_rank = '01 PHD'
        Then 'PHD'
      When degree_level_rank = '02 MBA'
        Then Case
          When department_desc_short Like '%FT-2Y%' Then 'FT-2Y'
          When department_desc_short Like '%FT-1Y%' Then 'FT-1Y'
          When department_desc_short Like '%JDMBA%' Then 'FT-JDMBA'
          When department_desc_short Like '%MMM%' Then 'FT-MMM'
          When department_desc_short Like '%MDMBA%' Then 'FT-MDMBA'
          When department_desc_short Like '%MBAI%' Then 'FT-MBAi'
          When department_desc_short Like '%Kellogg KEN%' Then 'FT-KENNEDY'
          When department_desc_short Like '%TMP%' Then 'TMP'
          When department_desc_short Like '%PTS%' Then 'TMP-SAT'
          When department_desc_short Like '%PSA%' Then 'TMP-SATXCEL'
          When department_desc_short Like '%PTA%' Then 'TMP-XCEL'
          When department_desc_short Like '%NAP%' Then 'EMP-IL'
          When department_desc_short Like '%WHU%' Then 'EMP-GER'
          When department_desc_short Like '%SCH%' Then 'EMP-CAN'
          When department_desc_short Like '%LAP%' Then 'EMP-FL'
          When department_desc_short Like '%HK%' Then 'EMP-HK'
          When department_desc_short Like '%JNA%' Then 'EMP-JAN'
          When department_desc_short Like '%RU%' Then 'EMP-ISR'
          When department_desc_short Like '%PKU%' Then 'EMP-CHI'
          When department_desc_short Like '% EMP%' Then 'EMP'
          When department_desc_short Like '%MIM%' Or department_desc_short Like '%MSMS%'
            Then 'FT-MIM'
          When department_desc_short Like '%MS %' Then 'FT-MS'
          When department_desc_short Like '%MMGT%' Then 'FT-MMGT'
          Else 'FT-UNK-MBA'
          End
      When degree_level_rank = '03 BBA'
        Then Case
          When department_desc_short Like '%BEV%' Then 'FT-EB'
          When department_desc_short Like '%BCH%' Then 'FT-CB'
          Else 'FT-UNK-BBA'
          End
      When degree_level_rank In ('04 OTH', '05 CER')
        Then Case
          When department_desc_short Like '%AEP%' Then 'CERT-AEP'
          When department_desc_short Like '%KSMEE%' Then 'EXECED'
          When department_desc_short Like '%CERT%' Then 'EXECED'
          When department_desc_short Like '%Institute for Mgmt%' Then 'EXECED'
          When department_desc_short Like '%LLM%' Then 'CERT-LLM'
          When department_desc_short Like '%Certificate%' Then 'CERT'
          Else 'CERT-UNK'
          End
      When degree_level_rank = '10 STU'
        Then 'STUDENT'
      When degree_level_rank = '50 NON'
        Then 'NONGRAD'
      Else 'UNK'
    End
    As program
From prg
;

-- Comparison group
Select
  kd.degree_level_ranked
  , kd.program_group
  , kd.program
  , count(*) As n
From mv_entity_ksm_degrees kd
Group By
  kd.degree_level_ranked
  , kd.program_group
  , kd.program
Order By degree_level_ranked Asc
;
