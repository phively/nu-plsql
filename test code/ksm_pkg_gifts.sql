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
  NULL As "Check discounted countable amounts are non-round numbers (e.g. 305 instead of 500)"
  , dt.*
From table(ksm_pkg_gifts.tbl_discounted_transactions) dt
Where dt.designation_detail_record_id In ('DD-2555697', 'DD-2372155')
;

Select
  NULL As "Check bequest amount calc receive full paid credit for paid"
  , dt.*
From table(ksm_pkg_gifts.tbl_discounted_transactions) dt
Where dt.pledge_or_gift_record_id In ('PN2241905', 'PN2241904')
;

Select
  NULL As "Check total paid amount <= countable amount"
  , dt.*
From table(ksm_pkg_gifts.tbl_discounted_transactions) dt
Where dt.pledge_or_gift_record_id In ('PN2442329', 'PN2347181')
;

Select
  NULL As "Should be $25M"
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
  NULL As "Written off bequest, check credit = recognition"
  , mkt.*
From mv_ksm_transactions mkt
Where mkt.opportunity_record_id = 'PN2296500'
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

Select
  NULL As "Recognition credit: total payments > original amount"
  , mkt.*
From mv_ksm_transactions mkt
Where mkt.opportunity_record_id = 'PN2463109'
  Order By gypm_ind
;

Select
  NULL As "Gift exceptions check"
  , mkt.*
From mv_ksm_transactions mkt
Where mkt.opportunity_record_id In ('PN2463400', 'PN2297936')
;

Select
  NULL As "Check bequest hard credit sum < hh_recognition_credit"
  , mkt.*
From mv_ksm_transactions mkt
Where mkt.opportunity_record_id In ('PN2442329', 'PN2347181')
  And mkt.hard_credit_amount > 0
Order By mkt.opportunity_record_id, source_type
;
