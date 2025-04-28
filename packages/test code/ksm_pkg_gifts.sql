---------------------------
-- ksm_pkg_gifts tests
---------------------------

-- Table functions

Select count(*)
From table(ksm_pkg_gifts.tbl_ksm_transactions)
;

---------------------------
-- mv tests
---------------------------

Select *
From mv_ksm_transactions mkt
Where mkt.fiscal_year Between 2022 And 2024
;
