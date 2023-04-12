/*
-- Last run on 2023-04-12
Create Materialized View test_ksm_pkg_prospect As
  Select
    id_number
    , pref_mail_name
    , evaluation_rating
    , officer_rating
    , Case
        When trim(officer_rating) Is Not Null
          Then ksm_pkg_utility.get_number_from_dollar(officer_rating)
        When trim(evaluation_rating) Is Null
          Or evaluation_rating = 'H  Under $10K'
          Then 0
        Else ksm_pkg_utility.get_number_from_dollar(evaluation_rating)
        End
        As extracted_rating
  From nu_prs_trp_prospect
  Where id_number In (
    '0000376979', '0000704936', '0000314499', '0000559687', '0000432656', '0000878487', '0000508725', '0000213352'
  )
;
*/

---------------------------
-- ksm_pkg_prospect tests
---------------------------

-- Constants
Select
  ksm_pkg_prospect.get_string_constant('pkg_name') As pkg_name
  , ksm_pkg_prospect.get_string_constant('seg_af_10k') As af_seg
  , ksm_pkg_prospect.get_string_constant('seg_mg_id') As mgid_seg
  , ksm_pkg_prospect.get_string_constant('seg_mg_pr') As mgpr_seg
From DUAL
;

-- Functions
Select
  id_number
  , Case
      When extracted_rating = ksm_pkg_prospect.get_prospect_rating_numeric(id_number) * 1E6
        Then 'true'
      Else 'FALSE'
      End
    As expected
  , evaluation_rating
  , officer_rating
  , extracted_rating
  , ksm_pkg_prospect.get_prospect_rating_numeric(id_number) As get_pr_num
  , ksm_pkg_prospect.get_prospect_rating_bin(id_number) As get_pr_bin
From test_ksm_pkg_prospect
;

-- Table functions
Select *
From table(ksm_pkg_prospect.tbl_prospect_entity_active)
;

Select *
From table(ksm_pkg_prospect.tbl_university_strategy)
;

Select *
From table(ksm_pkg_prospect.tbl_numeric_capacity_ratings)
;

-- Segment table functions
Select *
From table(ksm_pkg_prospect.tbl_model_af_10k)
;

Select *
From table(ksm_pkg_prospect.tbl_model_mg_identification)
;

Select *
From table(ksm_pkg_prospect.tbl_model_mg_prioritization)
;

-- Check segment dates
With
pkg_dates As (
  Select
    ksm_pkg_prospect.get_numeric_constant('seg_af_10k_mo') As af_10k_mo
    , ksm_pkg_prospect.get_numeric_constant('seg_af_10k_yr') As af_10k_yr
    , ksm_pkg_prospect.get_numeric_constant('seg_mg_mo') As mg_mo
    , ksm_pkg_prospect.get_numeric_constant('seg_mg_yr') As mg_yr
  From DUAL
)
, af_dates As (
  Select
    max(segment_year) As max_af_10k_yr
    , max(segment_month) As max_af_10k_mo
  From table(ksm_pkg_prospect.tbl_model_af_10k)
)
, mg_dates As (
  Select
    max(segment_year) As max_mg_yr
    , max(segment_month) As max_mg_mo
  From table(ksm_pkg_prospect.tbl_model_mg_identification)
)
Select
  Case
    When af_10k_yr = max_af_10k_yr
      And af_10k_mo = max_af_10k_mo
      And mg_yr = max_mg_yr
      And mg_mo = max_mg_mo
      Then 'true'
    Else 'FALSE'
    End
  As expected
  , af_10k_yr
  , max_af_10k_yr
  , af_10k_mo
  , max_af_10k_mo
  , mg_yr
  , max_mg_yr
  , mg_mo
  , max_mg_mo
From pkg_dates
Cross Join af_dates
Cross Join mg_dates
;

---------------------------
-- ksm_pkg tests
---------------------------

-- Functions
Select
  id_number
  , Case
      When extracted_rating = ksm_pkg_tmp.get_prospect_rating_numeric(id_number) * 1E6
        Then 'true'
      Else 'FALSE'
      End
    As expected
  , evaluation_rating
  , officer_rating
  , extracted_rating
  , ksm_pkg_tmp.get_prospect_rating_numeric(id_number) As get_pr_num
  , ksm_pkg_tmp.get_prospect_rating_bin(id_number) As get_pr_bin
From test_ksm_pkg_prospect
;

-- Table functions
Select *
From table(ksm_pkg_tmp.tbl_prospect_entity_active)
;

Select *
From table(ksm_pkg_tmp.tbl_university_strategy)
;

Select *
From table(ksm_pkg_tmp.tbl_numeric_capacity_ratings)
;

-- Segment table functions
Select *
From table(ksm_pkg_tmp.tbl_model_af_10k)
;

Select *
From table(ksm_pkg_tmp.tbl_model_mg_identification)
;

Select *
From table(ksm_pkg_tmp.tbl_model_mg_prioritization)
;