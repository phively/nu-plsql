---------------------------
-- ksm_pkg_degrees tests
---------------------------

Select count(*)
From table(ksm_pkg_degrees.tbl_entity_ksm_degrees)
;

Select
    deg.donor_id
    , con.institutional_suffix
    , deg.degrees_concat
    , deg.first_ksm_year
    , deg.first_ksm_grad_date
From table(ksm_pkg_degrees.tbl_entity_ksm_degrees) deg
Inner Join dm_alumni.dim_constituent con
  On con.constituent_donor_id = deg.donor_id
;

---------------------------
-- Data validation
---------------------------

Select
  'Check for dupes' As test_desc
  , deg.constituent_donor_id
  , deg.constituent_name
  , deg.degree_school_name
  , deg.degree_record_id
  , deg.degree_level
  , deg.degree_code
  , deg.degree_year
From table(dw_pkg_base.tbl_degrees) deg
Where constituent_donor_id In ('0000596215', '0000594932', '0000646274', '0000595931')
Order By
  constituent_name
  , degree_code  
;

Select
  'MiM >= 2024, MSMS <= 2023' As test_desc
  , deg.donor_id
  , deg.degrees_concat
  , deg.first_ksm_year
  , deg.first_ksm_grad_date
  , deg.program
  , deg.program_group
From table(ksm_pkg_degrees.tbl_entity_ksm_degrees) deg
Where deg.program In ('FT-MIM', 'FT-MIM NONGRAD', 'FT-MS', 'FT-MS NONGRAD')
;

Select
  'Students have blank date' As test_desc
  , deg.donor_id
  , deg.degrees_concat
  , deg.first_ksm_year
  , deg.first_ksm_grad_date
  , deg.program
  , deg.program_group
From table(ksm_pkg_degrees.tbl_entity_ksm_degrees) deg
Where deg.program = 'STUDENT'
;

Select
  'Check for non-execed degree names' As test_desc
  , deg.donor_id
  , deg.degrees_concat
  , deg.degrees_verbose
  , deg.first_ksm_year
  , deg.program
  , deg.program_group
From table(ksm_pkg_degrees.tbl_entity_ksm_degrees) deg
Where deg.program = 'EXECED'
  And deg.first_ksm_year Is Null
  And deg.majors_concat Is Not Null
;

---------------------------
-- Test cases
---------------------------

With

test_cases As (
  Select '0000084513' As donor_id, 'FT-MMGT' As expected_result, 'MMGT and CERT' As explanation From DUAL
  Union Select '0000043879', 'FT-EB', 'BBA no deg code'  From DUAL
  Union Select '0000145897', 'FT-MMM', 'MMM no program'  From DUAL
  Union Select '0000047624', 'PHD', 'MBA and PHD'  From DUAL
  Union Select '0000468293', '2002', 'NU conferred degree year' From DUAL
  Union Select '0000532693', 'FT-2Y', 'New 2Y degree code' From DUAL
  Union Select '0000291027', 'FT-1Y', 'New 1Y degree code' From DUAL
  Union Select '0000334071', 'FT-2Y', 'New 2Y degree code' From DUAL
  Union Select '0000356565', 'FT-2Y', 'New 2Y degree code' From DUAL
)

Select
  deg.first_ksm_year
  , deg.program
  , test_cases.expected_result
  , test_cases.explanation
  , Case
      When test_cases.expected_result = deg.program
        Or test_cases.expected_result = deg.first_ksm_year
        Then 'Y'        
      Else 'FALSE' End
    As pass
  , deg.degree_level_ranked
  , deg.degrees_concat
  , deg.completed_degrees_concat
  , deg.donor_id
  , deg.sort_name
From mv_entity_ksm_degrees deg
Inner Join test_cases
  On test_cases.donor_id = deg.donor_id
;
