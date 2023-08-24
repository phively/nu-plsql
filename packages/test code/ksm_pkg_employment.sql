---------------------------
-- ksm_pkg_employment tests
---------------------------

Select *
From table(ksm_pkg_employment.tbl_frontline_ksm_staff)
;

Select *
From table(ksm_pkg_employment.tbl_nu_ard_staff)
;

Select *
From table(ksm_pkg_employment.tbl_entity_employees_ksm('Apple'))
;

---------------------------
-- ksm_pkg tests
---------------------------

Select *
From table(ksm_pkg_tst.tbl_frontline_ksm_staff)
;

Select *
From table(ksm_pkg_tst.tbl_nu_ard_staff)
;

Select *
From table(ksm_pkg_tst.tbl_entity_employees_ksm('Apple'))
;