---------------------------
-- ksm_pkg_designation tests
---------------------------

Select *
From table(ksm_pkg_designation.tbl_designation_ksm_af)
;

Select *
From table(ksm_pkg_designation.tbl_designation_ksm_cru)
;

Select *
From table(ksm_pkg_designation.tbl_designation_cash)
;

Select *
From table(ksm_pkg_designation.tbl_designation_campaign_kfc)
;

Select *
From table(ksm_pkg_designation.tbl_ksm_designation)
;

-- These should all have same # of rows
Select count(*) As count_rows
From table(ksm_pkg_designation.tbl_designation_cash)
Union All
Select count(*) As count_rows
From table(ksm_pkg_designation.tbl_designation_campaign_kfc)
Union All
Select count(*) As count_rows
From table(ksm_pkg_designation.tbl_ksm_designation)
;
