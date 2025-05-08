---------------------------
-- ksm_pkg_gifts tests
---------------------------

-- Table functions

Select count(*)
From table(ksm_pkg_gifts.tbl_ksm_transactions)
;

Select count(*)
From table(ksm_pkg_gifts.tbl_discounted_transactions)
;

---------------------------
-- gift credit tests
---------------------------

Select
  NULL As "Check discounted countable amounts are non-round numbers (e.g. 305 instead of 500)"
  , dt.*
From table(ksm_pkg_gifts.tbl_discounted_transactions) dt
Where dt.designation_detail_record_id In ('DD-2555697', 'DD-2372155')
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
Where mkt.legacy_receipt_number = '0001659131'
  Or mkt.opportunity_record_id = 'PN2438947'
;

Select
  NULL As "Check discounted bequest amount"
  , mkt.*
From mv_ksm_transactions mkt
Where mkt.legacy_receipt_number = '0002999795'
;

Select
  NULL As "Split bequest, should be hard credit = recognition"
  , mkt.*
From mv_ksm_transactions mkt
Where mkt.legacy_receipt_number = '0003068356'
;

Select
  NULL As "Partially paid pledge"
  , mkt.*
From mv_ksm_transactions mkt
Where mkt.legacy_receipt_number = '0003068751'
;

Select
  NULL As "Written off pledge"
  , mkt.*
From mv_ksm_transactions mkt
Where mkt.legacy_receipt_number = '0002992956'
;

Select
  NULL As "Matching payment date is FY22"
  , mkt.*
From mv_ksm_transactions mkt
Where mkt.credit_receipt_number = '0002916204'
  Or mkt.opportunity_record_id = 'MN2984602'
;

Select
  NULL As "Payment date after pledge credit date"
  , mkt.*
From mv_ksm_transactions mkt
Where mkt.legacy_receipt_number = '0002431969'
  Or mkt.opportunity_record_id = 'PN2269769'
;

Select
  NULL As "Check matching gifts populate"
  , mkt.*
From mv_ksm_transactions mkt
Where mkt.credited_donor_id = '0000564117'
  And mkt.gypm_ind = 'M'
;
