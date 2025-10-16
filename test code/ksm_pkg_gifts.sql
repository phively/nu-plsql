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

Select count(*)
From table(ksm_pkg_gifts.tbl_source_donors)
;

---------------------------
-- gift credit tests
---------------------------

Select
  'Check discounted countable amounts are non-round numbers (e.g. 305 instead of 500)' As explanation
  , dt.*
From table(ksm_pkg_gifts.tbl_discounted_transactions) dt
Where dt.designation_detail_record_id In ('DD-2555697', 'DD-2372155')
;

Select
  'Check bequest amount calc receive full paid credit for paid' As explanation
  , dt.*
From table(ksm_pkg_gifts.tbl_discounted_transactions) dt
Where dt.pledge_or_gift_record_id In ('PN2241905', 'PN2241904')
;

Select
  'Check prepaid bequest amount calc < face value' As explanation
  , dt.*
From table(ksm_pkg_gifts.tbl_discounted_transactions) dt
Where dt.pledge_or_gift_record_id In ('PN2391224', 'PN2481659', 'PN3006164')
;

Select
  'Check total paid amount <= countable amount' As explanation
  , dt.*
From table(ksm_pkg_gifts.tbl_discounted_transactions) dt
Where dt.pledge_or_gift_record_id In ('PN2442329', 'PN2347181')
;

Select
  'Should be $25M' As explanation
  , ua.*
From table(ksm_pkg_gifts.tbl_unsplit_amounts) ua
Where ua.pledge_or_gift_record_id = 'PN2482912'
;

---------------------------
-- mv_source_donor tests
---------------------------

Select count(*)
From mv_source_donor
;

With

test_cases As (
  Select '0002371580' As legacy_tx, '0000073925' As expected_donor_id, 'NU' As explanation From DUAL
  Union Select '0002371650', '0000437871', 'donor + spouse' From DUAL
  Union Select '0002372038', '0000314967', 'KSM + spouse + DAF' From DUAL
  Union Select '0002373070', '0000386715', 'Trst + KSM' From DUAL
  Union Select '0002400638', '0000385764', 'MATCH: Fdn + KSM' From DUAL
  Union Select '0002373286', '0000505616', 'NU + KSM spouse' From DUAL
  Union Select '0002373551', '0000206322', 'Trst + nonalum donor + nonalum spouse' From DUAL
  Union Select '0002374381', '0000579707', 'MATCH: Fdn + Fdn + KSM + KSM Spouse' From DUAL
  Union Select '0002370746', '0000564106', 'KSM' From DUAL
  Union Select '0002370763', '0000484652', 'KSM + spouse' From DUAL
  Union Select '0002370765', '0000303126', 'KSM + KSM spouse' From DUAL
  Union Select '0002422364', '0000285609', 'MATCH: Fdn + KSM + spouse' From DUAL
)

Select
  mvs.tx_id
  , mvs.legacy_receipt_number
  , mvs.source_donor_id
  , test_cases.expected_donor_id
  , test_cases.explanation
  , Case
      When test_cases.expected_donor_id = mvs.source_donor_id
        Then 'Y'
      Else 'FALSE' End
    As pass
From mv_source_donor mvs
Inner Join mv_transactions mvt
  On mvt.tx_id = mvs.tx_id
  And mvt.credit_type = 'Hard'
Inner Join test_cases
  On test_cases.legacy_tx = mvt.legacy_receipt_number
;

---------------------------
-- mv_ksm_transactions matching gifts tests
---------------------------

Select
  'Check matching gifts populate' As explanation
  , mkt.*
From mv_ksm_transactions mkt
Where mkt.credited_donor_id = '0000564117'
  And mkt.gypm_ind = 'M'
;

Select
  'Exactly 2 rows' As explanation
  , mkt.*
From mv_ksm_transactions mkt
Where mkt.legacy_receipt_number = '0003103274'
;


Select
  'Matching payment date is FY22' As explanation
  , mkt.credited_donor_audit
  , mkt.opportunity_donor_id
  , mkt.source_type_detail
  , mkt.gypm_ind
  , mkt.tx_id
  , mkt.opportunity_record_id
  , mkt.credit_receipt_number
  , mkt.matched_gift_record_id
  , mkt.matching_gift_original_gift_receipt
  , mkt.original_gift_credit_date
  , mkt.original_gift_fy
  , mkt.matching_gift_credit_date
  , mkt.matching_gift_fy
From mv_ksm_transactions mkt
Where mkt.credit_receipt_number = '0002916204'
  Or mkt.opportunity_record_id = 'MN2984602'
;

Select
  'All but gypm_ind = G populated' As explanation
  , mkt.credited_donor_name
  , mkt.source_type_detail
  , mkt.gypm_ind
  , mkt.tx_id
  , mkt.credit_receipt_number
  , mkt.matched_gift_record_id
  , mkt.matching_gift_original_gift_receipt
  , mkt.original_gift_credit_date
  , mkt.original_gift_fy
  , mkt.matching_gift_credit_date
  , mkt.matching_gift_fy
From mv_ksm_transactions mkt
Where mkt.matched_gift_record_id = 'GN2150702'
  Or mkt.opportunity_record_id = 'GN2150702'
;

Select
  'Original gift 7/7' As explanation
  , mkt.credited_donor_name
  , mkt.source_type_detail
  , mkt.gypm_ind
  , mkt.tx_id
  , mkt.credit_receipt_number
  , mkt.matched_gift_record_id
  , mkt.matching_gift_original_gift_receipt
  , mkt.original_gift_credit_date
  , mkt.original_gift_fy
  , mkt.matching_gift_credit_date
  , mkt.matching_gift_fy
From mv_ksm_transactions mkt
Where mkt.opportunity_record_id = 'MN2982122'
;

Select
  'Original gift 12/24/24' As explanation
  , mkt.credited_donor_name
  , mkt.source_type_detail
  , mkt.gypm_ind
  , mkt.tx_id
  , mkt.credit_receipt_number
  , mkt.matched_gift_record_id
  , mkt.matching_gift_original_gift_receipt
  , mkt.original_gift_credit_date
  , mkt.original_gift_fy
  , mkt.matching_gift_credit_date
  , mkt.matching_gift_fy
From mv_ksm_transactions mkt
Where mkt.opportunity_record_id = 'MN3005749'
;

---------------------------
-- mv_ksm_transactions tests
---------------------------

Select count(*)
From mv_ksm_transactions
;

Select *
From mv_ksm_transactions mkt
Where mkt.fiscal_year Between 2022 And 2024
;

Select
  'Check for multiple credited donors, single opportunity donor on pledge' As explanation
  , mkt.credited_donor_name
  , mkt.opportunity_donor_name
From mv_ksm_transactions mkt
Where mkt.legacy_receipt_number = '0001659131'
  Or mkt.opportunity_record_id = 'PN2438947'
;

Select
  'Check discounted bequest amount' As explanation
  , mkt.credited_donor_audit
  , mkt.tx_id
  , mkt.credit_amount
  , mkt.hard_credit_amount
  , mkt.recognition_credit
From mv_ksm_transactions mkt
Where mkt.legacy_receipt_number = '0002999795'
;

Select
  'Split bequest, should be credit = recognition' As explanation
  , mkt.credited_donor_audit
  , mkt.tx_id
  , mkt.credit_amount
  , mkt.hard_credit_amount
  , mkt.recognition_credit
From mv_ksm_transactions mkt
Where mkt.legacy_receipt_number = '0003068356'
;

Select
  'Partially paid pledge' As explanation
  , mkt.*
From mv_ksm_transactions mkt
Where mkt.legacy_receipt_number = '0003068751'
;

Select
  'Written off pledge' As explanation
  , mkt.*
From mv_ksm_transactions mkt
Where mkt.legacy_receipt_number = '0002992956'
;

Select
  'Written off bequest, check credit = recognition' As explanation
  , mkt.credited_donor_audit
  , mkt.tx_id
  , mkt.credit_amount
  , mkt.hard_credit_amount
  , mkt.recognition_credit
From mv_ksm_transactions mkt
Where mkt.opportunity_record_id = 'PN2296500'
;

Select
  'Payment date after pledge credit date' As explanation
  , mkt.*
From mv_ksm_transactions mkt
Where mkt.legacy_receipt_number = '0002431969'
  Or mkt.opportunity_record_id = 'PN2269769'
;

Select
  'Recognition credit: total payments > original amount' As explanation
  , mkt.credited_donor_audit
  , mkt.tx_id
  , mkt.credit_amount
  , mkt.hard_credit_amount
  , mkt.recognition_credit
From mv_ksm_transactions mkt
Where mkt.opportunity_record_id = 'PN2463109'
  Order By gypm_ind
;

Select
  'Gift exceptions check' As explanation
  , mkt.*
From mv_ksm_transactions mkt
Where mkt.opportunity_record_id In ('PN2463400', 'PN2297936')
;

Select
  'Check bequest hard credit sum < hh_recognition_credit' As explanation
  , credited_donor_audit
  , tx_id
  , opportunity_record_id
  , gypm_ind
  , hard_credit_amount
  , recognition_credit
  , hh_credit
  , hh_recognition_credit
From mv_ksm_transactions mkt
Where mkt.opportunity_record_id In ('PN2442329', 'PN2347181')
  And mkt.hard_credit_amount > 0
Order By mkt.opportunity_record_id, source_type
;

Select
  'Check DAF credit amounts, should be >= $60K' As explanation
  , mvt.credited_donor_audit
  , mvt.opportunity_record_id
  , mvt.opportunity_type
  , mvt.source_type_detail
  , mvt.credit_type
  , mvt.credit_amount
  , mvt.hard_credit_amount
From mv_ksm_transactions mvt
Where opportunity_record_id In ('GN3034268', 'GN2087965')
;
