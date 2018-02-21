/*************************
Most recent AF 10K model
**************************/

Create Or Replace View v_ksm_model_af_10k As

Select *
From table(rpt_pbh634.ksm_pkg.tbl_model_af_10k(
-- Replace these with the most up-to-date modeled score month/year
  model_year => 2018
  , model_month => 01
))
;
