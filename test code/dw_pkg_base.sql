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
From table(dw_pkg_base.tbl_mini_entity)
;

Select *
From table(dw_pkg_base.tbl_degrees)
;

Select *
From table(dw_pkg_base.tbl_designation)
;

Select *
From table(dw_pkg_base.tbl_opportunity)
;

Select *
From table(dw_pkg_base.tbl_payment)
;

Select *
From table(dw_pkg_base.tbl_gift_credit)
;

Select *
From table(dw_pkg_base.tbl_involvement)
;

Select *
From table(dw_pkg_base.tbl_service_indicators)
;

Select *
From table(dw_pkg_base.tbl_assignments)
;

Select *
From table(dw_pkg_base.tbl_proposals)
;

Select *
From table(dw_pkg_base.tbl_social_media)
;

Select *
From table(dw_pkg_base.tbl_address)
;
