Create Or Replace View v_ksm_prospect_pool As

With
/* View pulling the KSM prospect pool */

-- Kellogg alumni
ksm_deg As (
  Select *
  From rpt_pbh634.v_entity_ksm_degrees
  Where record_status_code Not In ('D', 'X') -- Exclude deceased, purgable
)

-- Modeled scores
, af_10k_model As (
  Select *
  From v_ksm_model_af_10k
)
, mgo_model As (
  Select *
  From v_ksm_model_mg
)

-- Kellogg Top 150/300
, ksm_150_300 As (
  Select *
  From table(rpt_pbh634.ksm_pkg.tbl_entity_top_150_300)
)

-- Numeric rating bins
, rating_bins As (
  Select *
  From table(ksm_pkg.tbl_numeric_capacity_ratings)
)

-- Prospect entity table filtered for active prospects
, prs_e As (
  Select
    pe.prospect_id
    , pe.id_number
    , pe.primary_ind
  From prospect_entity pe
  Inner Join prospect p On p.prospect_id = pe.prospect_id
  Where p.active_ind = 'Y' -- Active only
)

-- Kellogg prospect interest
, ksm_prs As (
  (
  -- Top 150/300
  Select
    prs_e.prospect_id
    , prs_e.id_number
    , prs_e.primary_ind
    , 'Y' As ksm_prospect_interest_flag -- N.B. includes the 150/300 list
  From program_prospect prs
  Inner Join ksm_150_300 On ksm_150_300.prospect_id = prs.prospect_id
  Inner Join prs_e On prs_e.prospect_id = prs.prospect_id
  Inner Join entity on entity.id_number = prs_e.id_number
  ) Union (
  Select
    prs_e.prospect_id
    , prs_e.id_number
    , prs_e.primary_ind
    , 'Y' As ksm_prospect_interest_flag
  From program_prospect prs
  Inner Join prs_e On prs_e.prospect_id = prs.prospect_id
  Inner Join entity on entity.id_number = prs_e.id_number
  Where
      prs.program_code = 'KM' -- Kellogg only
      And prs.active_ind = 'Y' -- Active only
      And entity.record_status_code Not In ('D', 'X') -- Exclude deceased, purgable
      And prs.stage_code Not In (7, 11) -- Exclude Disqualified, Permanent Stewardship
  )
)

-- Previously disqualified prospects; note that this will include people with multiple prospect records
, dq_list As (
  (
  -- Overall disqualified
  Select
    prospect.prospect_id
    , id_number
    , tms_stage.short_desc As dq
    , Case
        When prospect.stop_date Is Not Null
          Then prospect.stop_date
        Else prospect.date_modified
      End
      As dq_date
  From prospect
  Inner Join prospect_entity On prospect_entity.prospect_id = prospect.prospect_id
  Left Join tms_stage On tms_stage.stage_code = prospect.stage_code
  Where prospect.stage_code = 7
  ) Union All (
  -- Program disqualified
  Select
    pp.prospect_id
    , id_number
    , tms_stage.short_desc As dq
    , Case
        When pp.stop_date Is Not Null
          Then pp.stop_date
        Else pp.date_modified
      End
      As dq_date
  From program_prospect pp
  Inner Join prospect_entity On prospect_entity.prospect_id = pp.prospect_id
  Left Join tms_stage On tms_stage.stage_code = pp.stage_code
  Where pp.stage_code = 7
    And pp.program_code = 'KM'
  )
)
-- Dedupe, using most recent DQ date as final
, dq As (
  Select Distinct
    prospect_id
    , id_number
    , dq
    , trunc(max(dq_date)) As dq_date
  From dq_list
  Group By
    prospect_id
    , id_number
    , dq
)

-- Permanent stewardship prospects
, perm_stew As (
  (
  -- Overall disqualified
  Select
    prospect.prospect_id
    , id_number
    , tms_stage.short_desc As ps
  From prospect
  Inner Join prospect_entity On prospect_entity.prospect_id = prospect.prospect_id
  Left Join tms_stage On tms_stage.stage_code = prospect.stage_code
  Where prospect.stage_code = 11
  ) Union (
  -- Program disqualified
  Select
    pp.prospect_id
    , id_number
    , tms_stage.short_desc As ps
  From program_prospect pp
  Inner Join prospect_entity On prospect_entity.prospect_id = pp.prospect_id
  Left Join tms_stage On tms_stage.stage_code = pp.stage_code
  Where pp.stage_code = 11
    And pp.program_code = 'KM'
  )
)

-- All prospects with an active Kellogg program code
, ksm_prs_ids As (
  (
  -- KSM top 150/300
  Select id_number
  From ksm_150_300
  ) Union (
  -- KSM prospect program, not inactive or DQ
  Select id_number
  From ksm_prs
  -- All living alumni
  ) Union (
  Select id_number
  From ksm_deg
  Where record_status_code Not In ('D', 'X')
  ) Union (
  -- All living donors
  Select gft.id_number
  From v_ksm_giving_trans gft
  Inner Join entity On entity.id_number = gft.id_number
  Where entity.record_status_code Not In ('D', 'X')
  )
)

-- No Solicit special handling
, spec_hnd As (
  Select
    id_number
    , hnd_type_code As DNS
  From handling
  Where hnd_type_code = 'DNS'
    And hnd_status_code = 'A'
)

-- UOR
, uor As (
 Select
    prospect_id
    -- If multiple active UORs, keep only the most recent (by evaluation date)
    , max(evaluation_date) keep(dense_rank First Order By evaluation_date Desc NULLS Last, evaluation.rating_code Asc)
      As uor_date
    , max(evaluation.rating_code) keep(dense_rank First Order By evaluation_date Desc NULLS Last, evaluation.rating_code Asc)
      As rating_code
    , max(tms_rating.short_desc) keep(dense_rank First Order By evaluation_date Desc NULLS Last, evaluation.rating_code Asc)
      As uor
    , max(entity.id_number) keep(dense_rank First Order By evaluation_date Desc NULLS Last, evaluation.rating_code Asc)
      As uor_evaluator_id
    , max(entity.report_name) keep(dense_rank First Order By evaluation_date Desc NULLS Last, evaluation.rating_code Asc)
      As uor_evaluator
  From evaluation
  Left Join tms_rating On tms_rating.rating_code = evaluation.rating_code
  Left Join entity On entity.id_number = evaluation.evaluator_id_number
  Where evaluation_type = 'UR'
    And active_ind = 'Y' -- University overall rating
  Group By
    prospect_id
)

-- Pref address type
, pref_addr As (
  Select
    address.id_number
    , address.addr_type_code As pref_addr_type
  From address
  Where address.addr_pref_ind = 'Y'
    And address.addr_status_code = 'A'
)

-- Home addresses
, home_addr As (
  Select
    address.id_number
    , address.city As home_city
    , address.state_code As home_state
    , conts.country As home_country
  From address
  Left Join v_addr_continents conts
    On conts.country_code = address.country_code
  Where address.addr_status_code = 'A'
    -- This works because entities may have no more than one address type H
    And address.addr_type_code = 'H'
)

-- Main query
Select Distinct
  hh.*
  , prs.business_title
  , trim(prs.employer_name1 || ' ' || prs.employer_name2) As employer_name
  , pref_addr.pref_addr_type
  , prs.pref_city
  , prs.pref_state
  , prs.preferred_country
  , prs.business_city
  , prs.business_state
  , prs.business_country
  , home_addr.home_city
  , home_addr.home_state
  , home_addr.home_country
  , prs.prospect_id
  , prs_e.primary_ind
  , prospect.prospect_name
  , prospect.prospect_name_sort
  , strat.university_strategy
  , strat.strategy_sched_date
  , strat.strategy_responsible
  , dq.dq
  , dq.dq_date
  , perm_stew.ps As permanent_stewardship
  , spec_hnd.DNS
  , prs.evaluation_rating
  , prs.evaluation_date
  , prs.officer_rating
  , uor.uor
  , uor.uor_date
  , uor.uor_evaluator_id
  , uor.uor_evaluator
  , af_10k_model.description As af_10k_model
  , af_10k_model.score As af_10k_score
  , mgo_model.id_segment As mgo_id_model
  , mgo_model.id_score As mgo_id_score
  , mgo_model.pr_segment As mgo_pr_model
  , mgo_model.pr_score As mgo_pr_score
  , prs.prospect_manager_id
  , pm.report_name As prospect_manager
  , prs.team
  , prs.prospect_stage
  , prs.contact_date
  , contact_auth.report_name As contact_author
  -- Concatenated managers on prospect or entity ID as appropriate
  , assign.manager_ids
  , assign.managers
  , assign.curr_ksm_manager
  -- Primary prospect for 150/300, or primary household member for everyone else
  , Case
      When ksm_150_300.primary_ind = 'Y' Then 'Y'
      When ksm_150_300.primary_ind = 'N' Then NULL
      When household_id = hh.id_number Then 'Y'
    End As hh_primary
  -- Rating bin
  , Case
      When officer_rating <> ' ' Then uor.numeric_rating
      When evaluation_rating <> ' ' Then eval.numeric_rating
      Else 0
    End As rating_numeric
  , Case
      When officer_rating <> ' ' Then uor.numeric_bin
      When evaluation_rating <> ' ' Then eval.numeric_bin
      Else 0
    End As rating_bin
  -- Lifetime giving
  , prs.giving_total As nu_lifetime_recognition
  -- Which group?
  , ksm_prs.ksm_prospect_interest_flag
  , Case
      -- Top 150
      When ksm_150_300.prospect_category_code = 'KT1'
        Then 'A. Top 150'
      -- Top 300
      When ksm_150_300.prospect_category_code = 'KT3'
        Then 'B. Top 300'
      -- Assigned; exclude managed by Kellogg Donor Relations
      When assign.manager_ids Is Not Null
        And assign.prospect_manager_id Not In ('0000292130')
        Then 'C. Assigned'
      -- Leads
      When assign.manager_ids Is Null -- Unmanaged
        And (officer_rating <> ' ' Or evaluation_rating <> ' ') -- Has a rating
        And officer_rating Not In ('G  $10K - $24K') -- Not officer disqualified
        And dq.dq Is Null -- Not previously disqualified
        And perm_stew.ps Is Null -- Not permanent stewardship
        And team <> 'Unresponsive' -- Not unresponsive
        Then 'D. Leads'
      -- Previously disqualified
      When dq.dq Is Not Null Then 'Q. Previously Disqualified'
      When perm_stew.ps Is Not Null Then 'S. Permanent Stewardship'
      -- Fallback
      Else 'Z. None'
    End As pool_group
From table(rpt_pbh634.ksm_pkg.tbl_entity_households_ksm) hh
Inner Join ksm_prs_ids -- Must be a valid Kellogg entity
  On ksm_prs_ids.id_number = hh.id_number
Left Join ksm_prs
  On ksm_prs.id_number = hh.id_number
Left Join pref_addr
  On pref_addr.id_number = hh.id_number
Left Join home_addr
  On home_addr.id_number = hh.id_number
Left Join af_10k_model
  On af_10k_model.id_number = hh.id_number
Left Join mgo_model
  On mgo_model.id_number = hh.id_number
Left Join nu_prs_trp_prospect prs
  On prs.id_number = hh.id_number
Left Join rating_bins eval
  On eval.rating_desc = prs.evaluation_rating
Left Join rating_bins uor
  On uor.rating_desc = prs.officer_rating
Left Join entity pm
  On pm.id_number = prs.prospect_manager_id
Left Join prs_e
  On prs_e.prospect_id = prs.prospect_id
  And prs_e.id_number = hh.id_number
Left Join prospect
  On prospect.prospect_id = prs.prospect_id
Left Join ksm_150_300
  On ksm_150_300.id_number = hh.id_number
Left Join entity contact_auth
  On contact_auth.id_number = prs.contact_author
Left Join rpt_pbh634.v_assignment_summary assign
  On assign.prospect_id = prs.prospect_id
Left Join dq
  On dq.id_number = hh.id_number
Left Join perm_stew
  On perm_stew.id_number = hh.id_number
Left Join spec_hnd
  On spec_hnd.id_number = hh.id_number
Left Join uor
  On uor.prospect_id = prs.prospect_id
Left Join table(rpt_pbh634.ksm_pkg.tbl_university_strategy) strat
  On strat.prospect_id = prs.prospect_id
