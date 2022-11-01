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
  rpt_pbh634.ksm_pkg_tmp.tbl_model_af_10k(
    -- Replace these with the most up-to-date modeled score month/year
    model_year => 2022
    , model_month => 09
  )
)
;

/*************************
Most recent MG scores
**************************/

Create Or Replace View v_ksm_model_mg As

With

-- Determine maximum year to be used for the models
seg_yr As (
  Select
    max(segment_year) As segment_year
  From segment
  Where segment_code Like 'KMID_'
    Or segment_code Like 'KMPR_'
)

-- Determine maximum month to be used for the models
, seg_mo As (
  Select
    max(segment_month) As segment_month
  From segment
  Where segment_year = (Select segment_year From seg_yr)
    And (
      segment_code Like 'KMID_'
      Or segment_code Like 'KMPR_'
    )
)

-- Model scores
, identification As (
  Select *
  From table(
    rpt_pbh634.ksm_pkg_tmp.tbl_model_mg_identification(
      -- Replace these with the most up-to-date modeled score month/year
      model_year => (Select segment_year From seg_yr)
      , model_month => (Select segment_month From seg_mo)
    )
  )
)
, prioritization As (
  Select *
  From table(
    rpt_pbh634.ksm_pkg_tmp.tbl_model_mg_prioritization(
      -- Replace these with the most up-to-date modeled score month/year
      model_year => (Select segment_year From seg_yr)
      , model_month => (Select segment_month From seg_mo)
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
  , Case
      When to_number(identification.score) <> 0
        Then to_number(prioritization.score) / to_number(identification.score)
      End
     As est_probability
From identification
Inner Join prioritization
  On identification.id_number = prioritization.id_number
;
