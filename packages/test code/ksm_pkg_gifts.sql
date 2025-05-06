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

Select
  NULL As "Check for multiple credited donors, single opportunity donor on pledge"
  , mkt.*
From mv_ksm_transactions mkt
Where mkt.opp_receipt_number = '0001659131'
;

Select
  NULL As "Check discounted bequest amount"
  , mkt.*
From mv_ksm_transactions mkt
Where mkt.opp_receipt_number = '0002999795'
;

Select
  NULL As "Partially paid pledge"
  , mkt.*
From mv_ksm_transactions mkt
Where mkt.opp_receipt_number = '0003068751'
;
