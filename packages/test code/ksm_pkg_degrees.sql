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
