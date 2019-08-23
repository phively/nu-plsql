-- PARAMETERS for below analysis; update here
Drop Table tmp_params_for_pm
;
Create Table tmp_params_for_pm As

Select
  2019 As this_fy -- FY to be used for primary analysis
From DUAL
;

-- Current State: Pipeline Development
-- New leads outcomes by the numbers
Select
  NULL
From DUAL
;

-- Current State: Pipeline Development
-- Visit conversion rate for new leads
Select
  NULL
From DUAL
;

-- Pipeline patterns and shifts
Select
  NULL
From DUAL
;

-- Current State: Portfolio Calibration
-- Solicitation dollars versus expectation to close
-- Active proposals and MG scores
-- Proposals vs MG score
With

mg_scores As (
  Select
    prospect_id
    , max(pr_score) keep(dense_rank First Order By pr_score Desc)
      As pr_score
    , max(pr_segment) keep(dense_rank First Order By pr_score Desc)
      As pr_segment
  From v_ksm_model_mg mg
  Inner Join prospect_entity pe
    On pe.id_number = mg.id_number
  Group By prospect_id
)

Select
  phf.prospect_id
  , mg_scores.pr_segment
  , mg_scores.pr_score
  , proposal_id
  , proposal_manager
  , proposal_status
  , start_dt_calc
  , close_dt_calc
  , close_fy
  , ksm_or_univ_ask
  , ksm_or_univ_anticipated
  , final_anticipated_or_ask_amt
From v_proposal_history_fast phf
Left Join mg_scores
  On mg_scores.prospect_id = phf.prospect_id
Where proposal_active_calc = 'Active'
  And phf.ksm_proposal_ind = 'Y'
;

-- Current State: Moves Management
-- Visits by score
-- Visits by MG score
Select
  mg.pr_segment
  , mg.pr_score
  , v.*
From v_ksm_visits v
Left Join v_ksm_model_mg mg
  On mg.id_number = v.id_number
Inner Join table(ksm_pkg.tbl_frontline_ksm_staff) gos
  On gos.id_number = v.credited
  And former_staff Is Null
  And team = 'MG'
Cross Join tmp_params_for_pm
Where v.fiscal_year >= tmp_params_for_pm.this_fy - 1 -- include any PFY visits
;

-- Current State: Moves Management
-- Active management and color coding
-- Trimmed table
-- Run R code afterwards to create Tableau-readable file
Select
  fls.team
  , ts.*
From vt_go_portfolio_time_series ts
Inner Join table(ksm_pkg.tbl_frontline_ksm_staff) fls
  On fls.id_number = ts.assignment_id_number
  And fls.former_staff Is Null
;

-- Current State: Moves Management
-- Ask amounts versus capacity levels
-- UOR vs Proposals
-- Proposals by UOR v2
With

prospects As (
  Select Distinct
    prospect_id
  From v_proposal_history_fast phf
  Inner Join table(ksm_pkg.tbl_frontline_ksm_staff) gos
    On gos.id_number = phf.proposal_manager_id
    And former_staff Is Null
    And team = 'MG'
  Where proposal_active_calc = 'Active'
)

, phf As (
  Select
    phf.prospect_id
    , count(Distinct proposal_id)
      As proposals
    , sum(ksm_or_univ_ask)
      As ksm_or_univ_asks
  From v_proposal_history_fast phf
  Inner Join prospects
    On prospects.prospect_id = phf.prospect_id
  Where proposal_active_calc = 'Active'
    And phf.close_dt_calc Between to_date('20180901', 'yyyymmdd') And to_date('20201231', 'yyyymmdd') -- Campaign date range
--    And ksm_proposal_ind = 'Y'
  Group By
    phf.prospect_id
)

, prs As (
  Select
    prospect_id
    , pref_mail_name
    , evaluation_rating
    , ksm_pkg.get_prospect_rating_numeric(id_number)
      As uor_or_eval
    , ksm_pkg.get_prospect_rating_bin(id_number)
      As uor_or_eval_bin
  From nu_prs_trp_prospect
)

, uor As (
  Select
    prospect_id
    , evaluation_date As uor_date
    , evaluation.rating_code
    , tms_rating.short_desc As uor
  From evaluation
  Left Join tms_rating
    On tms_rating.rating_code = evaluation.rating_code
  Where evaluation_type = 'UR'
    And active_ind = 'Y' -- University overall rating
)

Select
  phf.prospect_id
  , prs.pref_mail_name
  , uor.uor
  , prs.evaluation_rating
  , prs.uor_or_eval
  , prs.uor_or_eval_bin
  , phf.proposals
  , phf.ksm_or_univ_asks
  , Case
      When ksm_or_univ_asks >= 5E6
        Then 5E6
      When ksm_or_univ_asks >= 1E6
        Then 1E6
      When ksm_or_univ_asks >= 5E5
        Then 5E5
      When ksm_or_univ_asks >= 1E5
        Then 1E5
      Else 0
      End
    As ask_amount_range
From phf
Left Join prs
  On prs.prospect_id = phf.prospect_id
Left Join uor
  On uor.prospect_id = phf.prospect_id
;
