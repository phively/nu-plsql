/*************************
Most recent AF 10K model
**************************/

Create Or Replace View v_ksm_model_af_10k As

Select
  id_number
  , segment_year
  , segment_month
  , segment_code
  , replace(description, 'KSM $10k Model ', '')
    As description
  , to_number(score) As score
From table(
  rpt_pbh634.ksm_pkg.tbl_model_af_10k(
    -- Replace these with the most up-to-date modeled score month/year
    model_year => 2018
    , model_month => 01
  )
)
;

/*************************
Most recent MG scores
**************************/

Create Or Replace View v_ksm_model_mg As

With

-- Model function inputs
params As (
  Select
    2019 As model_year
    , 01 As model_month
  From DUAL
)

-- Model scores
, identification As (
  Select *
  From table(
    rpt_pbh634.ksm_pkg.tbl_model_mg_identification(
      -- Replace these with the most up-to-date modeled score month/year
      model_year => (Select model_year From params)
      , model_month => (Select model_month From params)
    )
  )
)
, prioritization As (
  Select *
  From table(
    rpt_pbh634.ksm_pkg.tbl_model_mg_prioritization(
      -- Replace these with the most up-to-date modeled score month/year
      model_year => (Select model_year From params)
      , model_month => (Select model_month From params)
    )
  )
)

-- Final query
Select
  identification.id_number
  , identification.segment_year
  , identification.segment_month
  , identification.segment_code
    As id_code
  , replace(identification.description, 'Kellogg Major Gift Identification Model ', '')
    As id_segment
  , to_number(identification.score) As id_score
  , prioritization.segment_code
    As pr_code
  , replace(prioritization.description, 'KSM Major Gift Prioritization Model ', '')
    As pr_segment
  , to_number(prioritization.score)
    As pr_score
  , to_number(prioritization.score) / to_number(identification.score) As est_probability
From identification
Inner Join prioritization
  On identification.id_number = prioritization.id_number
;
