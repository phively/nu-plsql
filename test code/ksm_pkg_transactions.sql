---------------------------
-- ksm_pkg_transactions tests
---------------------------

Select *
From table(ksm_pkg_transactions.tbl_transactions)
;

Select *
From table(ksm_pkg_transactions.tbl_tributes)
;

Select *
From table(ksm_pkg_transactions.tbl_matches)
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

Select
  'Check DAF credit amounts' As explanation
  , mvt.credited_donor_audit
  , mvt.opportunity_record_id
  , mvt.opportunity_type
  , mvt.source_type_detail
  , mvt.credit_type
  , mvt.credit_amount
  , mvt.hard_credit_amount
  , mvt.daf_contribution_amount
  , mvt.daf_distribution_amount
From mv_transactions mvt
Where opportunity_record_id In ('GN3034268', 'GN2087965')
  And credit_type = 'Hard'
;

---------------------------
-- Matching gift tests
---------------------------

-- One row result tests
With

test_cases As (
  Select 'MN3037385' As mg_opp_id, 'Check no ThirdParty' As explanation From DUAL
  Union Select 'MN3000513', 'Is legacy receipt no RN' From DUAL
)

Select
  explanation
  , match.*
From mv_matches match
Inner Join test_cases
  On match.matching_gift_record_id = test_cases.mg_opp_id
;

-- Date tests
With

test_cases As (
  Select 'MN2983900' As mg_opp_id, '20240716' As expected, 'FY25 match on FY24 gift' As explanation From DUAL
  Union Select 'MN2982122', '20240707', 'Original gift date 7/7' From DUAL
  Union Select 'MN3005749', '20241224', 'Original gift date 12/24' From DUAL
  Union Select 'MN2986540', '20221223', 'Pledge payment date 12/23/22' From DUAL
  Union Select 'MN2926284', '20140915', 'Pledge/payment date mismatch, should be 9/15/14' From DUAL
  Union Select 'MN2984767', '20230828', 'Original gift date 8/28/23' From DUAL
  Union Select 'MN2986653', '20221219', 'Pledge payment date 12/19/22' From DUAL
)
  
Select
  explanation
  , to_date(test_cases.expected, 'yyyymmdd')
    As expected
  , original_gift_credit_date
    As result
  , Case
      When to_date(test_cases.expected, 'yyyymmdd') = original_gift_credit_date
        Then 'Y'
      Else 'FALSE'
    End
    As pass
  , match.*
From mv_matches match
Inner Join test_cases
  On match.matching_gift_record_id = test_cases.mg_opp_id
;
