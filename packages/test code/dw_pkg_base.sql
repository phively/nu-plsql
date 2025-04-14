---------------------------
-- dw_pkg_base tests
---------------------------

-- Verify that table functions work
Select *
From table(dw_pkg_base.tbl_constituent)
;

Select *
From table(dw_pkg_base.tbl_organization)
;

Select *
From table(dw_pkg_base.tbl_designation)
;

Select *
From table(dw_pkg_base.tbl_opportunity)
;
