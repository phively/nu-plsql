---------------------------
-- v_ksm_gifts_cash tests
---------------------------

Select
  NULL As "Check Julie is credited"
  , tx_id
  , credited_donor_audit
  , historical_credit_name
From v_ksm_gifts_cash c
Where c.legacy_receipt_number In ('0002566399', '0002942812')
Order By tx_id
;
