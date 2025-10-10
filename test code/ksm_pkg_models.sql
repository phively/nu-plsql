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
From table(ksm_pkg_models.tbl_ksm_model_alumni_engagement)
;

Select *
From table(ksm_pkg_models.tbl_ksm_model_student_supporter)
;

Select *
From table(ksm_pkg_models.tbl_ksm_models)
;

---------------------------
-- materialized view tests
---------------------------

Select
  count(m.mg_id_code) As mg_id
  , count(m.mg_pr_code) As mg_pr
  , count(m.af_10k_code) As af_10k
  , count(m.alumni_engagement_code) As ae
  , count(m.student_supporter_code) As ss
From mv_ksm_models m
;
