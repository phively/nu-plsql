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
