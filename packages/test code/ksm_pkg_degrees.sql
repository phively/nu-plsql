---------------------------
-- ksm_pkg_degrees tests
---------------------------

Select count(*)
From table(ksm_pkg_degrees.tbl_entity_degrees_concat_ksm)
;

Select
    deg.id_number
    , entity.institutional_suffix
    , deg.degrees_concat
    , ksm_pkg_degrees.get_entity_degrees_concat_fast(id_number)
        As deg_conc_from_func
    , deg.first_ksm_year
    , deg.first_ksm_grad_dt
From table(ksm_pkg_degrees.tbl_entity_degrees_concat_ksm) deg
Inner Join entity On entity.id_number = deg.id_number
;

---------------------------
-- ksm_pkg tests
---------------------------

Select count(*)
From table(ksm_pkg_tst.tbl_entity_degrees_concat_ksm)
;
