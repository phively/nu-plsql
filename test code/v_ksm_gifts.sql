---------------------------
-- v_ksm_gifts_cash tests
---------------------------

Select
  'Check JL is credited' As test
  , c.tx_id
  , c.credited_donor_audit
  , c.historical_credit_name
  , c.historical_pm_name
  , c.historical_prm_name
  , c.historical_lagm_name
From v_ksm_gifts_cash c
Where c.tx_id In ('T1958891', 'T2072822', 'T2239680', 'T2534929', 'T2534952', 'T2535530', 'T2579815', 'T2579877', 'T2930526', 'T2121202', 'T2133311', 'T0246401', 'T0302742')
Order By c.tx_id
;

Select
  'Check SK is credited' As test
  , c.tx_id
  , c.credited_donor_audit
  , c.historical_credit_name
  , c.historical_pm_name
  , c.historical_prm_name
  , c.historical_lagm_name
From v_ksm_gifts_cash c
Where c.opportunity_record_id In ('GN1704880', 'MN2991397')
Order By c.opportunity_record_id
;

Select
  'Check hard credit = recognition = cash countable amt' As test
  , c.*
From v_ksm_gifts_cash c
Where c.opportunity_record_id In ('PN2442329', 'PN2347181')
  And hard_credit_amount > 0
Order By c.opportunity_record_id
