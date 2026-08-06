---------------------------
-- ksm_pkg_employment tests
---------------------------

-- Totals
Select count(*)
From table(ksm_pkg_employment.tbl_entity_employment)
;

---------------------------
-- mv tests
---------------------------

Select count(*)
From mv_entity_employment
;

Select *
From mv_entity_employment
;
