---------------------------
-- ksm_pkg_gifts_hh tests
---------------------------

Select count(*)
From table(ksm_pkg_gifts_hh.tbl_klc_history)
;

Select
  gc.transaction_type
  , count(gc.tx_number)
  , sum(gc.hh_stewardship_credit)
From table(ksm_pkg_gifts_hh.tbl_gift_credit_hh_ksm) gc
Group By gc.transaction_type
;

---------------------------
-- ksm_pkg tests
---------------------------

Select count(*)
From table(ksm_pkg_tst.tbl_klc_history)
;

Select
  gc.transaction_type
  , count(gc.tx_number)
  , sum(gc.hh_stewardship_credit)
From table(ksm_pkg_tst.tbl_gift_credit_hh_ksm) gc
Group By gc.transaction_type
;