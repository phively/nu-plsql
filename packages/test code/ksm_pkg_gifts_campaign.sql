---------------------------
-- ksm_pkg_gifts_campaign tests
---------------------------

Select count(*)
From table(ksm_pkg_gifts_campaign.tbl_gift_credit_campaign)
;

Select
  gc.transaction_type
  , count(gc.tx_number)
  , sum(gc.hh_stewardship_credit)
From table(ksm_pkg_gifts_campaign.tbl_gift_credit_hh_campaign) gc
Group By gc.transaction_type
;

---------------------------
-- ksm_pkg tests
---------------------------

Select count(*)
From table(ksm_pkg_tst.tbl_gift_credit_campaign)
;

Select
  gc.transaction_type
  , count(gc.tx_number)
  , sum(gc.hh_stewardship_credit)
From table(ksm_pkg_tst.tbl_gift_credit_hh_campaign) gc
Group By gc.transaction_type
;