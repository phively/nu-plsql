---------------------------
-- ksm_pkg_models tests
---------------------------

Select *
From table(ksm_pkg_models.tbl_ksm_model_mg)
;

Select *
From table(ksm_pkg_models.tbl_ksm_model_af_10k)
;

Select *
From table(ksm_pkg_models.tbl_ksm_model_af_pr)
;

Select *
From table(ksm_pkg_models.tbl_ksm_model_alumni_engagement)
;

Select *
From table(ksm_pkg_models.tbl_ksm_model_student_supporter)
;

Select *
From table(ksm_pkg_models.tbl_ksm_models)
;

Select *
From table(ksm_pkg_models.tbl_ksm_models_hh)
;

---------------------------
-- materialized view tests
---------------------------

Select
  count(m.mg_id_code) As mg_id
  , count(m.mg_pr_code) As mg_pr
  , count(m.af_10k_code) As af_10k
  , count(m.af_pr_code) As af_pr
  , count(m.alumni_engagement_code) As ae
  , count(m.student_supporter_code) As ss
From mv_ksm_models m
;

Select
  count(m.mg_id_code) As mg_id
  , count(m.mg_pr_code) As mg_pr
  , count(m.af_10k_code) As af_10k
  , count(m.af_pr_code) As af_pr
  , count(m.alumni_engagement_code) As ae
  , count(m.student_supporter_code) As ss
From mv_ksm_models_hh m
;

-- Householded checks
Select
  'No null scores' As explanation
  , h.*
From mv_ksm_models_hh h
Where h.donor_id In (86400, 86401)
;

Select
  'No nonprimary households appear' As explanation
  , h.*
From mv_ksm_models_hh h
Where h.household_primary_ksm = 'N'
;

Select
  'Highest score is householded' As explanation
  , 'Householded' As source
  , h.*
From mv_ksm_models_hh h
Where h.household_id_ksm = '0001047035'
Union
Select
  'Highest score is joint' As explanation
  , 'Unhouseholded' As source
  , h.*
From mv_ksm_models h
Where h.household_id_ksm = '0001047035'
;
