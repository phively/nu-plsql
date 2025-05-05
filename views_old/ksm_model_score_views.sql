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
From table(rpt_pbh634.ksm_pkg_prospect.tbl_model_af_10k)
;

/*************************
Most recent MG scores
**************************/

Create Or Replace View v_ksm_model_mg As

With

-- Model scores
identification As (
  Select *
  From table(rpt_pbh634.ksm_pkg_prospect.tbl_model_mg_identification)
)
, prioritization As (
  Select *
  From table(rpt_pbh634.ksm_pkg_prospect.tbl_model_mg_prioritization)
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

/*************************
Most recent alumni engagement model
**************************/

Create Or Replace View v_ksm_model_alumni_engagement As

Select *
From rpt_lfs898.ksm_ae_model_scores
;

Create Or Replace View v_ksm_model_student_supporter As 

Select
  segment.id_number
  , segment.segment_code
  , sh.description
    As segment
  , segment.segment_year
  , segment.segment_month
  , segment.xcomment
    As score
From segment
Inner Join segment_header sh
  On sh.segment_code = segment.segment_code
Where segment.segment_code = 'KAESS'
  And segment_year = 2024
;

/*************************
All Brightcrowd connector scores
**************************/

Create Or Replace View v_ksm_model_connector_ranking As

Select
  id_number
  , segment_code
  , segment_year
  , segment_month
  , rpt_pbh634.ksm_pkg_tmp.to_number2(xcomment)
    As score
From segment
Where segment_code = 'KBCR'
;
