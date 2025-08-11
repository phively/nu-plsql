---------------------------
-- ksm_pkg_transactions tests
---------------------------

Select *
From table(ksm_pkg_transactions.tbl_transactions)
;

Select *
From table(ksm_pkg_transactions.tbl_tributes)
;

---------------------------
-- mv_transactions tests
---------------------------

Select count(*)
From mv_transactions
;

Select
  'Check bequest amounts' As explanation
  , mvt.*
From mv_transactions mvt
Where tx_id In ('T2934818', 'T2934800', 'T2584353', 'T2584354', 'T2584825', 'T2584826', 'T2584827', 'T2584830', 'T2584828', 'T2584829')
  And hard_credit_amount > 0
Order By credited_donor_name Asc
;

---------------------------
-- Matching gift tests
---------------------------

With

test_cases As (
  Select 'MN3037385' As mg_opp_id, 'Check no ThirdParty' As explanation From DUAL
  Union Select 'MN3000513', 'Is legacy receipt no RN' From DUAL
  Union Select 'MN2983900', 'FY24 match on FY23 gift' From DUAL
)
  
Select
  explanation
  , match.*
From table(ksm_pkg_transactions.tbl_matches) match
Inner Join test_cases
  On match.matching_gift_record_id = test_cases.mg_opp_id
;
