/*
-- Last run on 2023-03-24
Create Materialized View test_ksm_pkg_households As
  Select '0000003803' As id_number, '0000003803' As expected_hhid, 'Widowed' As explanation From DUAL
  Union Select '0000003804', '0000003804', 'Widowed' From DUAL
  Union Select '0000262301', '0000262301', 'non-KSM no spouse' From DUAL
  Union Select '0000667071', '0000667071', 'KSM no spouse' From DUAL
  Union Select '0000463496', '0000463496', 'non-KSM with non-KSM spouse' From DUAL
  Union Select '0000889013', '0000463496', 'non-KSM with non-KSM spouse' From DUAL 
  Union Select '0000667067', '0000667067', 'KSM with non-KSM spouse' From DUAL
  Union Select '0000697199', '0000667067', 'non-KSM with KSM spouse' From DUAL
  Union Select '0000666955', '0000666955', 'same year same programs' From DUAL
  Union Select '0000666964', '0000666955', 'same year same programs' From DUAL
  Union Select '0000668667', '0000666464', 'different year same programs' From DUAL
  Union Select '0000666464', '0000666464', 'different year same programs' From DUAL
  Union Select '0000532299', '0000532299', 'same year different programs' From DUAL
  Union Select '0000542272', '0000532299', 'same year different programs' From DUAL
  Union Select '0000668904', '0000666991', 'different year different programs' From DUAL
  Union Select '0000666991', '0000666991', 'different year different programs' From DUAL
;
*/

---------------------------
-- ksm_pkg_households tests
---------------------------

Select
    hh.household_id
  , test_hh.expected_hhid
  , Case
      When hh.household_id = test_hh.expected_hhid
        Then 'true'
        Else 'FALSE'
        End
    As passed
  , test_hh.explanation
  , hh.id_number
  , hh.report_name
  , hh.spouse_report_name
  , hh.fmr_spouse_name
  , hh.household_primary
  , hh.household_rpt_name
  , hh.household_spouse
  , hh.degrees_concat
  , hh.spouse_degrees_concat
  , hh.program
  , hh.spouse_program
From test_ksm_pkg_households test_hh
Left Join table(ksm_pkg_households.tbl_entity_households_ksm) hh
  On test_hh.id_number = hh.id_number
Order By household_id
;

Select
    hh.household_id
  , test_hh.expected_hhid
  , Case
      When hh.household_id = test_hh.expected_hhid
        Then 'true'
        Else 'FALSE'
        End
    As passed
  , test_hh.explanation
From test_ksm_pkg_households test_hh
Left Join table(ksm_pkg_households.tbl_households_fast) hh
  On test_hh.id_number = hh.id_number
Order By household_id
;

Select
    hh.household_id
  , test_hh.expected_hhid
  , Case
      When hh.household_id = test_hh.expected_hhid
        Then 'true'
        Else 'FALSE'
        End
    As passed
  , test_hh.explanation
  , test_hh.id_number
  , entity.report_name
  , hh.household_rpt_name
  , hh.household_primary
From test_ksm_pkg_households test_hh
Inner Join entity
  On entity.id_number = test_hh.id_number
Left Join table(ksm_pkg_households.tbl_households_fast_ext) hh
  On test_hh.id_number = hh.id_number
Order By household_id
;

---------------------------
-- ksm_pkg tests
---------------------------

Select
    hh.household_id
  , test_hh.expected_hhid
  , Case
      When hh.household_id = test_hh.expected_hhid
        Then 'true'
        Else 'FALSE'
        End
    As passed
  , test_hh.explanation
  , hh.id_number
  , hh.report_name
  , hh.spouse_report_name
  , hh.fmr_spouse_name
  , hh.household_primary
  , hh.household_rpt_name
  , hh.household_spouse
  , hh.degrees_concat
  , hh.spouse_degrees_concat
  , hh.program
  , hh.spouse_program
From test_ksm_pkg_households test_hh
Left Join table(ksm_pkg_tst.tbl_entity_households_ksm) hh
  On test_hh.id_number = hh.id_number
Order By household_id
;
