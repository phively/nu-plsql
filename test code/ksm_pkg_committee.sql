---------------------------
-- ksm_pkg_committee tests
---------------------------

-- Constant retrieval
Select
    ksm_pkg_committee.get_string_constant('committee_gab') As gab_no_pkg
  , ksm_pkg_committee.get_string_constant('ksm_pkg_committee.committee_gab') As gab_with_pkg
  , ksm_pkg_committee.get_numeric_constant('dues_gab') As gab_dues_no_pkg
  , ksm_pkg_committee.get_numeric_constant('ksm_pkg_committee.dues_gab') As gab_dues_with_pkg
From DUAL
;

-- Committee members by committee code
Select *
From ksm_pkg_committee.tbl_committee_members('COM-U')
;

-- Committee members by committee name
Select *
From ksm_pkg_committee.tbl_committee_members('committee_gab')
;

-- All committees
Select *
From table(ksm_pkg_committee.tbl_committees_all)
;

-- Concatenated committees
Select *
From table(ksm_pkg_committee.tbl_committees_concat)
;
