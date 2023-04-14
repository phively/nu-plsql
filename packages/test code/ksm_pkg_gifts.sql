/*
-- Last run on 2023-04-14
Create Materialized View test_ksm_pkg_gifts_src_dnr As
Select '0002371580' As tx_number, '0000073925' As expected, 'NU' As explanation From DUAL
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
*/

---------------------------
-- ksm_pkg_gifts tests
---------------------------

-- Functions
With
srcdnrs As (
    Select Distinct
        tst.tx_number
        , ksm_pkg_gifts.get_gift_source_donor_ksm(tx_number)
            As result
        , tst.expected
        , tst.explanation
    From test_ksm_pkg_gifts_src_dnr tst
)
Select
  Case
    When result = expected
      Then 'true'
    Else 'FALSE'
    End
    As pass
  , srcdnrs.tx_number
  , srcdnrs.result
  , srcdnrs.expected
  , srcdnrs.explanation
  , entity.person_or_org
  , entity.institutional_suffix
From srcdnrs
Inner Join entity
    On entity.id_number = srcdnrs.result
;

-- Table functions

---------------------------
-- ksm_pkg tests
---------------------------

