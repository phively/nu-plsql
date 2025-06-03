---------------------------
-- v_ksm_gifts_cash tests
---------------------------

Select
  NULL As "Check JL is credited"
  , c.tx_id
  , c.credited_donor_audit
  , c.historical_credit_name
  , c.historical_pm_name
  , c.historical_prm_name
  , c.historical_lagm_name
From v_ksm_gifts_cash c
Where c.tx_id In ('T1958891', 'T2072822', 'T2239680', 'T2534929', 'T2534952', 'T2535530', 'T2579815', 'T2579877', 'T2930526')
Order By c.tx_id
;
