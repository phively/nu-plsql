---------------------------
-- ksm_pkg_degrees tests
---------------------------

Select count(*)
From table(ksm_pkg_degrees.tbl_entity_degrees_concat_ksm)
;

Select
    deg.id_number
    , deg.degrees_concat
    , ksm_pkg_degrees.get_entity_degrees_concat_fast(id_number)
        As deg_conc_from_func
From table(ksm_pkg_degrees.tbl_entity_degrees_concat_ksm) deg
;

---------------------------
-- ksm_pkg tests
---------------------------

Select count(*)
From table(ksm_pkg_tst.tbl_entity_degrees_concat_ksm)
;
