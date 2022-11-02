/* FY22 Kellogg Investor's Report
    Previously based on Campaign giving through the entire counting period, FY07 through FY19
    -- UPDATE for FY21: counts only the current year's giving
    See Paul's "Investor's Report" folder on the G drive for criteria and notes
    See GitHub for the complete version history: https://github.com/phively/nu-plsql/tree/master/sql%20code/IR%20FY19
    Shouldn't take more than 5 minutes to run to completion
    (FY19: 8 minutes)
    (FY22: 3:21)
    
    Updates for FY19:
    - Added 1 to all the years, table names, column names, etc. next to an <UPDATE THIS> tag
    - v_ksm_giving_campaign needed to be updated with campaign_steward_thru, anon_steward_thru, nonanon_steward_thru 
        for 2019 (https://github.com/phively/nu-plsql/blob/master/views/ksm_giving_trans_views.sql)
    - Updated comments, where applicable
    - BIG CHANGE: tbl_ir_fy19_approved_names will store all the final IR names from FY18, which will be used as the
        starting point for this year's names. The previous format appears as a "constructed_name" column. If there's
        a difference from the constructed name I'll still toggle one of the "manually check" flags.
    
    N.B. no new report in FY20
    
    Updates for FY21:
    - Checked all the <UPDATE THIS> indicators and revised where needed
    - Revised giving level definitions: now based on stewardship_credit_amount from ksm_pkg (used in v_ksm_giving_summary
        among others)
    - Pulled Cornerstone from the gift club table rather than manually tagging (this group might not be called out, but it's future-proofing)
    - Created approved names table for FY19 IR and added additional audits
    - Checked manual householding from FY19
    - Removed Cornerstone and KLC indicators
    
    Updates for FY22:
    - Checked all the <UPDATE THIS> indicators and revised where needed
*/

With

/* Parameters -- update this each year
  Also look for <UPDATE THIS> comment */
params_cfy As (
  Select
    2022 As params_cfy -- <UPDATE THIS>
  From DUAL
)
, params As (
  Select
    params_cfy
    , params_cfy - 1 As params_pfy1
    , params_cfy - 2 As params_pfy2
    , params_cfy - 3 As params_pfy3
    , params_cfy - 4 As params_pfy4
    , params_cfy - 5 As params_pfy5
    , params_cfy - 6 As params_pfy6
    , params_cfy - 7 As params_pfy7
    , params_cfy - 8 As params_pfy8
    , params_cfy - 9 As params_pfy9
    , params_cfy - 10 As params_pfy10
  From params_cfy
)

/* Honor roll names
  CATracks honor roll names, where available */
, hr_names As (
  Select
    id_number
    , trim(pref_name) As honor_roll_name
    , Case
        -- If prefix is at start of name then remove it
        When pref_name Like (prefix || '%')
          Then trim(
            regexp_replace(pref_name, prefix, '', 1) -- Remove first occurrence only
          )
        Else pref_name
        End
      As honor_roll_name_no_prefix
  From name
  Where name_type_code = 'HR'
)

/* IR names
  FY19 IR names, if available */
, ir_names As (
  Select
    id_number
    , ir21_name --<UPDATE THIS>
    , first_name
    , middle_name
    , last_name
    , suffix
    -- Check whether suffix is a class year
    , Case
        When regexp_like(suffix, '''[0-9]+') -- valid examples: '00 '92 '11 '31
          Then 'Y'
        End
      As replace_year_flag
  From rpt_pbh634.tbl_ir_FY22_approved_names ian --<UPDATE THIS>
)

/* Degree strings
  Kellogg and NU strings, according to the updated FY21 degree format.
  Years and degree types are listed in chronological order and de-duped (listagg) */
, degs As (
  Select
    id_number
    , nu_degrees_string As yrs
  From rpt_pbh634.v_entity_nametags
)

/* Household data
  Household IDs and definitions as defined by ksm_pkg_tmp. Names are based on primary name and personal suffix. */
, hhs As (
  Select hh.*, degs.yrs
  From table(rpt_pbh634.ksm_pkg_tmp.tbl_entity_households_ksm) hh
  Left Join degs
    On degs.id_number = hh.id_number
)
, hh_name As (
  Select
    hhs.id_number
    , entity.gender_code
    , entity.record_status_code
    , entity.jnt_gifts_ind
    , trim(entity.last_name)
      As entity_last_name
    -- First Middle Last Suffix 'YY
    -- Primary name
    , trim(
        trim(
          trim(
            -- Choose last year's name or honor roll name
            Case
              When ir_names.first_name Is Not Null
                Then
                  trim(
                    trim(
                      trim(ir_names.first_name) || ' ' || trim(ir_names.middle_name)
                    ) || ' ' || trim(ir_names.last_name)
                  ) || ' ' || ir_names.suffix
              Else
              -- Choose honor roll name or constructed name
              Case
                When hr_names.honor_roll_name_no_prefix Is Not Null
                  Then hr_names.honor_roll_name_no_prefix
                Else
                  trim(
                    trim(
                      trim(entity.first_name) || ' ' || trim(entity.middle_name)
                    ) || ' ' || trim(entity.last_name)
                  ) || ' ' || entity.pers_suffix
                End
              End
          )
          -- Add class year if replace_year_flag is null
          || ' ' || (Case When ir_names.replace_year_flag Is Null Then hhs.yrs End)
        -- Check for deceased status
        ) || (Case When entity.record_status_code = 'D' Then '<DECEASED>' End)
      )
      As primary_name
    -- How was the primary_name constructed?
    , Case
        When ir_names.first_name Is Not Null
          Then 'PFY IR'
        When hr_names.honor_roll_name_no_prefix Is Not Null
          Then 'NU HR name'
        Else 'Constructed'
        End
      As primary_name_source
    -- Constructed name
    , trim(
        trim(
          trim(
            trim(
              trim(
                trim(entity.first_name) || ' ' || trim(entity.middle_name)
              ) || ' ' || trim(entity.last_name)
            ) || ' ' || entity.pers_suffix
          ) || ' ' || hhs.yrs
        ) || (Case When entity.record_status_code = 'D' Then '<DECEASED>' End)
      )
      As constructed_name
    , ir_names.ir21_name --<UPDATE THIS>
    , hhs.yrs
    , Case
        When entity.record_status_code = 'D'
          And trunc(entity.status_change_date) Between cal.prev_fy_start And cal.today
          Then 'Y'
        End
      As deceased_past_year
  From hhs
  Inner Join entity
    On entity.id_number = hhs.id_number
  Cross Join rpt_pbh634.v_current_calendar cal
  Left Join hr_names
    On hr_names.id_number = hhs.id_number
  Left Join ir_names
    On ir_names.id_number = hhs.id_number
)
, hh As (
  Select
    hhs.*
    , hh_name.gender_code As gender
    , hh_name_s.gender_code As gender_spouse
    , hh_name.record_status_code As record_status
    , hh_name_s.record_status_code As record_status_spouse
    , hh_name.deceased_past_year
    -- Is either spouse no joint gifts?
    , Case
        When hhs.household_spouse_rpt_name Is Not Null
          And (hh_name.jnt_gifts_ind = 'N' Or hh_name_s.jnt_gifts_ind = 'N')
          Then 'Y'
        End
      As no_joint_gifts_flag
    -- First Middle Last Suffix 'YY
    , hh_name.primary_name
    , hh_name.constructed_name
    , hh_name.primary_name_source
    , hh_name_s.primary_name As primary_name_spouse
    , hh_name_s.constructed_name As constructed_name_spouse
    , hh_name_s.primary_name_source As primary_name_source_spouse
    , hh_name.yrs As yrs_self
    , hh_name_s.yrs As yrs_spouse
    -- Check for entity last name
    , Case
        When hh_name.primary_name Not Like '%' || hh_name.entity_last_name || '%'
          And hh_name.primary_name Not Like '%Anonymous%'
          Then 'Y'
        End
      As check_primary_lastname
    , Case
        When hh_name_s.primary_name Not Like '%' || hh_name_s.entity_last_name || '%'
          And hh_name_s.primary_name Not Like '%Anonymous%'
          Then 'Y'
        End
      As check_primary_lastname_spouse  
  From hhs hhs
  -- Names and strings for formatting
  Inner Join hh_name
    On hh_name.id_number = hhs.household_id
  Left Join hh_name hh_name_s
    On hh_name_s.id_number = hhs.household_spouse_id
  -- Exclude purgable entities
  Where hhs.record_status_code <> 'X'
)

/* Anonymous
  Anonymous special handling indicator; entity should be anonymous for ALL gifts. Overrides the transaction-level anon flag.
  Also mark as anonymous people whose names last year were Anonymous. */
, anon_dat As (
  (
  Select
    hhs.household_id
    , tms.short_desc As anon
  From handling
  Inner Join hhs
    On hhs.id_number = handling.id_number
  Inner Join tms_handling_type tms
    On tms.handling_type = handling.hnd_type_code
  Where hnd_type_code = 'AN' -- Anonymous
    And hnd_status_code = 'A' -- Active only
  ) Union (
  Select
    hhs.household_id
    , 'Anonymous IR Name' As anon
  From hhs
  Inner Join ir_names
    On ir_names.id_number = hhs.id_number
  Where ir_names.first_name = 'Anonymous'
  )
)
, anon As (
  Select
    household_id
    , min(anon) As anon -- min() results in the order Anonymous, Anonymous Donor, Anonymous IR Name
  From anon_dat
  Group By household_id
)

/* Deceased spouses
  Check whether there are former or widowed spouses in the former_spouse table */
, dec_spouse As (
  Select Distinct
    id_number
    , spouse_id_number
  From former_spouse
  Where marital_status_code In (
    Select marital_status_code
    From tms_marital_status
    Where lower(short_desc) Like '%death%' -- Marriage ended by death, married at time of death, etc.
  )
)
, dec_spouse_conc As (
  Select
    id_number
    , Listagg(spouse_id_number, '; ') Within Group (Order By spouse_id_number)
      As dec_spouse_ids
  From dec_spouse
  Group By id_number
)

/* Manual household TABLE -- update rpt_pbh634.tbl_ir_fy19_manual_household
  This is the interface used to manually household deceased spouses and other entities */
, dec_spouse_ids As (
  Select
    -- Personal info
    ds.id_number
    , Case
        When hhd.household_spouse_rpt_name Is Null
          Then hh.gender
        When ds.id_number = hh.household_id
          Then hh.gender
        Else hhd.gender_spouse
        End
      As gender
    , Case
        When hhd.household_spouse_rpt_name Is Null
          Then hh.primary_name
        When ds.id_number = hh.household_id
          Then hh.primary_name
        Else hhd.primary_name_spouse
        End
      As pn
    , Case
        When hhd.household_spouse_rpt_name Is Null
          Then hh.yrs
        When ds.id_number = hh.household_id
          Then hh.yrs
        Else hhd.yrs_spouse
        End
      As yrs
    , Case
        When hhd.household_spouse_rpt_name Is Null
          Then regexp_replace(hh.household_rpt_name, ' ,', ',')
        When ds.id_number = hh.household_id
          Then regexp_replace(hh.household_rpt_name, ' ,', ',')
        Else regexp_replace(hhd.household_spouse_rpt_name, ' ,', ',')
        End
      As sn
    -- Spouse info
    , ds.id_join
    , Case
        When hhd.household_spouse_rpt_name Is Null
          Then hhd.gender
        When ds.id_join = hh.household_id
          Then hhd.gender
        Else hhd.gender_spouse
        End
      As gender_join
    , Case
        When hhd.household_spouse_rpt_name Is Null
          Then hhd.primary_name
        When ds.id_join = hh.household_id
          Then hhd.primary_name
        Else hhd.primary_name_spouse
        End
      As pnj
    , Case
        When hhd.household_spouse_rpt_name Is Null
          Then hhd.yrs 
        When ds.id_join = hh.household_id
          Then hhd.yrs
        Else hhd.yrs_spouse
        End
      As yrs_join
    , Case
        When hhd.household_spouse_rpt_name Is Null
          Then regexp_replace(hhd.household_rpt_name, ' ,', ',')
        When ds.id_join = hh.household_id
          Then regexp_replace(hhd.household_rpt_name, ' ,', ',')
        Else regexp_replace(hhd.household_spouse_rpt_name, ' ,', ',')
        End
      As snj
  From rpt_pbh634.tbl_IR_FY22_manual_household ds -- <UPDATE THIS>
  Inner Join hh
    On hh.id_number = ds.id_number
  Inner Join hh hhd
    On hhd.id_number = ds.id_join
)

/* Prospect assignments
  All active prospect manager and program manager assignments, to be used for manual review by staff */
, assign As (
  Select Distinct
    hhs.household_id
--    , ah.prospect_id
    , ah.assignment_id_number
    , ah.assignment_report_name
    , ksm.team As ksm_team
    , ah.assignment_type
    , Case
        When ah.assignment_type = 'PM'
          Then 1
        When ah.assignment_type = 'LG'
          Then 2
        When ah.assignment_type = 'PP'
          Then 3
        End
      As assignment_rank
  From rpt_pbh634.v_assignment_history ah
  Inner Join hhs
    On hhs.id_number = ah.id_number
  Left Join rpt_pbh634.v_frontline_ksm_staff ksm
    On ksm.id_number = ah.assignment_id_number
    And ksm.former_staff Is Null
  Where ah.assignment_active_calc = 'Active' -- Active assignments only
    And ah.assignment_type In ('PP', 'PM', 'LG') -- Program Manager (PP), Prospect Manager (PM), Leadership Giving Officer (LG)
)
, assign_conc As (
  Select
    household_id
    , Listagg(assignment_report_name, ';  ') Within Group (Order By assignment_rank Asc, ksm_team Asc Nulls Last, assignment_report_name Asc)
      As managers
    , Listagg(assignment_type, '; ') Within Group (Order By assignment_rank Asc, ksm_team Asc Nulls Last, assignment_report_name Asc)
      As assignment_types
    -- Show only specific assignment types
    , Listagg(
        Case When assignment_type = 'PM' Then assignment_report_name End
        , ';  '
      ) Within Group (Order By assignment_rank Asc, ksm_team Asc Nulls Last, assignment_report_name Asc)
      As pm
    , Listagg(
        Case When assignment_type = 'PP' Then assignment_report_name End
        , ';  '
      ) Within Group (Order By assignment_rank Asc, ksm_team Asc Nulls Last, assignment_report_name Asc)
      As ppm
    , Listagg(
        Case When assignment_type = 'LG' Then assignment_report_name End
        , ';  '
      ) Within Group (Order By assignment_rank Asc, ksm_team Asc Nulls Last, assignment_report_name Asc)
      As lgo
    -- Determine whether the specific assignment types include KSM GOs
    , Listagg(
        Case When assignment_type = 'PM' Then ksm_team End
        , ';  '
      ) Within Group (Order By assignment_rank Asc, ksm_team Asc Nulls Last, assignment_report_name Asc)
      As pm_ksm
    , Listagg(
        Case When assignment_type = 'PP' Then ksm_team End
        , ';  '
      ) Within Group (Order By assignment_rank Asc, ksm_team Asc Nulls Last, assignment_report_name Asc)
      As ppm_ksm
    , Listagg(
        Case When assignment_type = 'LG' Then ksm_team End
        , ';  '
      ) Within Group (Order By assignment_rank Asc, ksm_team Asc Nulls Last, assignment_report_name Asc)
      As lgo_ksm
  From assign
  Group By household_id
)
/* Recommended KSM or Central reviewer
  1.  If Kellogg PM, always use Kellogg PM
  2.  Otherwise, if Kellogg PPM, use Kellogg PPM
  3.  Otherwise, if Kellogg LGO, use Kellogg LGO
  4.  Otherwise, use Central PM if present
  5.  Otherwise, use Central PPM if present
  6.  Otherwise, use Central LGO if present
*/
, assign_reviewer As (
  Select
    household_id
    , Case
        When pm_ksm Is Not Null
          Then 'PM KSM'
        When ppm_ksm Is Not Null
          Then 'PPM KSM'
        When lgo_ksm Is Not Null
          Then 'LGO KSM'
        When pm Is Not Null
          Then 'PM'
        When ppm Is Not Null
          Then 'PPM'
        When lgo Is Not Null
          Then 'LGO'
        End
      As reviewer_assign_type
      , Case
          When pm_ksm Is Not Null
            Then pm
          When ppm_ksm Is Not Null
            Then ppm
          When lgo_ksm Is Not Null
            Then lgo
          When pm Is Not Null
            Then pm
          When ppm Is Not Null
            Then ppm
          When lgo Is Not Null
            Then lgo
          End
        As reviewer
  From assign_conc
)

/* KLC entities
  Our definition for Kellogg Leadership Circle. The young_klc needs to pull multiple years because gifts within 5 years of graduating
  are classified differently. */
, young_klc As (
  Select
    klc.*
  From table(rpt_pbh634.ksm_pkg_tmp.tbl_klc_history) klc
  Cross Join params
  Where fiscal_year Between params_pfy5 And params_cfy -- KLC member in current or 5 previous FYs
)
, fy_klc As (
  Select Distinct
    household_id
    , '<KLC22>' As klc -- <UPDATE THIS>
  From young_klc
  Cross Join params
  Where fiscal_year = params_cfy
)

-- Cache v_ksm_giving_trans_hh for efficiency (test if this is a speedup or not)
, v_kgth As (
  Select *
  From rpt_pbh634.v_ksm_giving_trans_hh gfts
)

/* Loyal households
  Stewardship giving as defined by ksm_giving_trans (and thus indirectly by ksm_pkg).
  For the FY18 IR, loyal implies either spouse is credited toward any KSM gift > $0, including matches, for each of FY18, FY17, FY16  */ 
, loyal_giving As (
  Select Distinct
    hhs.household_id
    -- WARNING: includes new gifts and commitments as well as cash
    , sum(Case When fiscal_year = params_pfy2 Then hh_stewardship_credit Else 0 End) As stewardship_pfy2
    , sum(Case When fiscal_year = params_pfy1 Then hh_stewardship_credit Else 0 End) As stewardship_pfy1
    , sum(Case When fiscal_year = params_cfy Then hh_stewardship_credit Else 0 End) As stewardship_cfy
  From hhs
  Cross Join params
  Inner Join v_kgth gfts
    On gfts.household_id = hhs.household_id
  Group By hhs.household_id
)
, loyal As (
  Select
    loyal_giving.*
    , Case
        When stewardship_cfy > 0 And stewardship_pfy1 > 0 And stewardship_pfy2 > 0
          Then '<LOYAL>'
        End
      As loyal -- Only loyal if gave every year
  From loyal_giving
)

-- Stewardship giving amounts, computed manually to be parametrized
, stewgft As (
  Select
    hhs.id_number
    , hhs.household_id
    , hhs.household_rpt_name
    , hhs.household_spouse_id
    , hhs.household_spouse
    -- FY total and anonymous giving definitions
    , sum(Case When fiscal_year = params.params_cfy Then hh_stewardship_credit Else 0 End) As stewardship_cfy
    , sum(Case When fiscal_year = params.params_cfy And anonymous <> ' ' Then hh_stewardship_credit Else 0 End) As stewardship_anonymous_cfy
    , sum(Case When fiscal_year = params.params_cfy And anonymous = ' ' Then hh_stewardship_credit Else 0 End) As stewardship_nonanonymous_cfy
    -- FY cash and NGC
    , sum(Case When tx_gypm_ind <> 'Y' And fiscal_year = params.params_cfy Then hh_credit Else 0 End) As ngc_cfy
    , sum(Case When tx_gypm_ind <> 'P' And fiscal_year = params.params_cfy Then hh_credit Else 0 End) As cash_cfy
  From v_kgth
  Cross Join params
  Inner Join hhs
    On hhs.id_number = v_kgth.id_number
  Group By
    hhs.id_number
    , hhs.household_id
    , hhs.household_rpt_name
    , hhs.household_spouse_id
    , hhs.household_spouse
)

-- NOT USED starting in FY21:
/* Campaign giving amounts
  ksm_pkg rewrite of Kellogg campaign giving, based on Bill's campaign reporting table.
  For the FY18 IR, this deliberately counts bequests/life expectancy at face value, but only the PAID amounts of cancelled pledges. */
-- USED starting in FY21:
/* Stewardship giving amounts
  Uses giving rules agreed on by KSM stewardship: pledge payment if pledge was in earlier year, else 0, only matches that were
  received the same FY, etc. */
, cgft As (
  Select
    gft.*
    , hhs.report_name
    , hhs.degrees_concat
    , hhs.person_or_org
    -- Custom giving level indicator
    , Case When custlvl.id_number Is Not Null Then 'Y' End
      As manual_giving_level
    -- Giving level string
    , Case
        -- Custom level override
        When custlvl.id_number Is Not Null
          Then
          Case
            When upper(custlvl.custom_level) Like '%ORG%' Then 'Z. Org'
            When upper(custlvl.custom_level) Like '%10M%' Then 'A. 10M+'
            When upper(custlvl.custom_level) Like '%2.5M%' Then 'C. 2.5M+' -- Before 5M so we don't match the 5M in 2.5M
            When upper(custlvl.custom_level) Like '%5M%' Then 'B. 5M+'
            When upper(custlvl.custom_level) Like '%1M%' Then 'D. 1M+'
            When upper(custlvl.custom_level) Like '%500K%' Then 'E. 500K+'
            When upper(custlvl.custom_level) Like '%250K%' Then 'F. 250K+'
            When upper(custlvl.custom_level) Like '%100K%' Then 'G. 100K+'
            When upper(custlvl.custom_level) Like '%50K%' Then 'H. 50K+'
            When upper(custlvl.custom_level) Like '%25K%' Then 'I. 25K+'
            When upper(custlvl.custom_level) Like '%10K%' Then 'J. 10K+'
            When upper(custlvl.custom_level) Like '%2.5K%' Then 'L. 2.5K+' -- Before 5K so we don't match the 5K in 2.5K
            When upper(custlvl.custom_level) Like '%5K%' Then 'K. 5K+'
            Else 'CHECK BY HAND'
            End
        -- All others
        When hhs.person_or_org = 'O' Then 'Z. Org'
        When stewardship_cfy >= 10000000 Then 'A. 10M+'
        When stewardship_cfy >=  5000000 Then 'B. 5M+'
        When stewardship_cfy >=  2500000 Then 'C. 2.5M+'
        When stewardship_cfy >=  1000000 Then 'D. 1M+'
        When stewardship_cfy >=   500000 Then 'E. 500K+'
        When stewardship_cfy >=   250000 Then 'F. 250K+'
        When stewardship_cfy >=   100000 Then 'G. 100K+'
        When stewardship_cfy >=    50000 Then 'H. 50K+'
        When stewardship_cfy >=    25000 Then 'I. 25K+'
        When stewardship_cfy >=    10000 Then 'J. 10K+'
        When stewardship_cfy >=     5000 Then 'K. 5K+'
        Else 'L. 2.5K+'
        End
      As proposed_giving_level
    , Case
        When hhs.person_or_org = 'O' Then 'Z. Org'
        When stewardship_nonanonymous_cfy >= 10000000 Then 'A. 10M+'
        When stewardship_nonanonymous_cfy >=  5000000 Then 'B. 5M+'
        When stewardship_nonanonymous_cfy >=  2500000 Then 'C. 2.5M+'
        When stewardship_nonanonymous_cfy >=  1000000 Then 'D. 1M+'
        When stewardship_nonanonymous_cfy >=   500000 Then 'E. 500K+'
        When stewardship_nonanonymous_cfy >=   250000 Then 'F. 250K+'
        When stewardship_nonanonymous_cfy >=   100000 Then 'G. 100K+'
        When stewardship_nonanonymous_cfy >=    50000 Then 'H. 50K+'
        When stewardship_nonanonymous_cfy >=    25000 Then 'I. 25K+'
        When stewardship_nonanonymous_cfy >=    10000 Then 'J. 10K+'
        When stewardship_nonanonymous_cfy >=     5000 Then 'K. 5K+'
        Else 'L. 2.5K+'
        End
      As nonanon_giving_level
  From stewgft gft
  Inner Join hhs
    On hhs.id_number = gft.id_number
  -- Interface for custom giving levels override; add to the tbl_ir_fy18_custom_level table and they'll show up here
  Left Join rpt_pbh634.tbl_ir_FY22_custom_level custlvl -- <UPDATE THIS>
    On custlvl.id_number = gft.id_number
)

/* Cash giving amounts
  Determine how much young alumni gave in a sliding 5FY window; for the FY18 IR it has to be at least $1,000 in a single year to be included. */
, cash As (
  Select Distinct
    hhs.id_number
    , hhs.household_id
    , hhs.household_rpt_name
    , hhs.household_spouse_id
    , hhs.household_spouse
    -- Cash giving for KLC young alumni determination
    , sum(Case When fiscal_year = params_pfy5 And tx_gypm_ind <> 'P' Then hh_credit Else 0 End)
      As cash_fy17 -- <UPDATE THIS>
    , sum(Case When fiscal_year = params_pfy4 And tx_gypm_ind <> 'P' Then hh_credit Else 0 End)
      As cash_fy18 -- <UPDATE THIS>
    , sum(Case When fiscal_year = params_pfy3 And tx_gypm_ind <> 'P' Then hh_credit Else 0 End)
      As cash_fy19 -- <UPDATE THIS>
    , sum(Case When fiscal_year = params_pfy2 And tx_gypm_ind <> 'P' Then hh_credit Else 0 End)
      As cash_fy20 -- <UPDATE THIS>
    , sum(Case When fiscal_year = params_pfy1 And tx_gypm_ind <> 'P' Then hh_credit Else 0 End)
      As cash_fy21 -- <UPDATE THIS>
    , sum(Case When fiscal_year = params_cfy And tx_gypm_ind <> 'P' Then hh_credit Else 0 End)
      As cash_fy22 -- <UPDATE THIS>
  From hhs
  Cross Join params
  Inner Join v_kgth gfts
    On gfts.household_id = hhs.household_id
  Group By
    hhs.id_number
    , hhs.household_id
    , hhs.household_rpt_name
    , hhs.household_spouse_id
    , hhs.household_spouse
)

/* Cornerstone criteria
  Uses the new Cornerstone gift club; anyone with an end date in the FY of interest should be included */
, cornerstone_data As (
  Select
    gc.gift_club_id_number As id_number
    , gtt.club_code
    , gtt.club_desc
    , gc.gift_club_start_date
    , gc.gift_club_end_date
    , gc.school_code
    , rpt_pbh634.ksm_pkg_tmp.to_date2(gift_club_end_date) As gift_club_end_dt
    , extract(year from rpt_pbh634.ksm_pkg_tmp.to_date2(gift_club_end_date)) As gift_club_end_fy
  From gift_clubs gc
  Inner Join tms_gift_club_table gtt
    On gtt.club_code = gc.gift_club_code
  Where gc.gift_club_code = 'KCD'
)
, cornerstone As (
  Select Distinct
    id_number
  From cornerstone_data
  Cross Join params
  Where cornerstone_data.gift_club_end_fy = params.params_cfy
)

/* Combine all criteria
  Main temp table pulling together all criteria */
, donorlist As (
  (
  -- $2500+ giving for people
  Select
    cgft.*, hh.deceased_past_year, hh.record_status_code, hh.household_spouse_rpt_name, hh.household_suffix, hh.household_spouse_suffix
    , hh.household_masters_year, hh.primary_name, hh.primary_name_source, hh.constructed_name, hh.gender
    , hh.primary_name_spouse, hh.constructed_name_spouse, hh.primary_name_source_spouse
    , hh.gender_spouse, hh.yrs, hh.yrs_spouse, hh.fmr_spouse_id, hh.fmr_spouse_name, hh.fmr_marital_status, hh.no_joint_gifts_flag
    , hh.check_primary_lastname, hh.check_primary_lastname_spouse
  From cgft
  Inner Join hh
    On hh.id_number = cgft.id_number
  Inner Join entity
    On entity.id_number = cgft.id_number
  Where hh.person_or_org = 'P' -- People
    And (
      cgft.stewardship_cfy >= 2500 --<UPDATE THIS>
      Or manual_giving_level = 'Y' -- Always include custom level override even if below $2500
    )
  ) Union All (
  -- $100K+ giving for orgs
  Select
    cgft.*, hh.deceased_past_year, hh.record_status_code, hh.household_spouse_rpt_name, hh.household_suffix, hh.household_spouse_suffix
    , hh.household_masters_year, hh.primary_name, hh.primary_name_source, hh.constructed_name, hh.gender
    , hh.primary_name_spouse, hh.constructed_name_spouse, hh.primary_name_source_spouse
    , hh.gender_spouse, hh.yrs, hh.yrs_spouse, hh.fmr_spouse_id, hh.fmr_spouse_name, hh.fmr_marital_status, hh.no_joint_gifts_flag
    , hh.check_primary_lastname, hh.check_primary_lastname_spouse
  From cgft
  Inner Join hh
    On hh.id_number = cgft.id_number
  Inner Join entity
    On entity.id_number = cgft.id_number
  Where hh.person_or_org = 'O' -- Orgs
    And (
      cgft.stewardship_cfy >= 100000 -- <UPDATE THIS>
      Or manual_giving_level = 'Y' -- Always include custom level override even if below $2500
    )
  )
Union All (
  -- Young alumni (degree in CFY-5 to CFY) giving $1000+ in CFY
  Select
    cgft.*, hh.deceased_past_year, hh.record_status_code, hh.household_spouse_rpt_name, hh.household_suffix, hh.household_spouse_suffix
    , hh.household_masters_year, hh.primary_name, hh.primary_name_source, hh.constructed_name, hh.gender
    , hh.primary_name_spouse, hh.constructed_name_spouse, hh.primary_name_source_spouse
    , hh.gender_spouse, hh.yrs, hh.yrs_spouse, hh.fmr_spouse_id, hh.fmr_spouse_name, hh.fmr_marital_status, hh.no_joint_gifts_flag
    , hh.check_primary_lastname, hh.check_primary_lastname_spouse
  From cgft
  Cross Join params
  Inner Join hh
    On hh.id_number = cgft.id_number
  Left Join cash
    On cash.id_number = cgft.id_number
  -- Graduated within "past" 5 years and gave at least $1000 "this" year
  -- After 5 years people are no longer young alums and will "fall" off if they
  -- haven't given at least $2500 cumulative by then; this is intentional!
  Where cgft.household_id In (Select Distinct household_id From young_klc)
    And (
      hh.last_noncert_year Between params_pfy5 And params_cfy
      Or hh.spouse_last_noncert_year Between params_pfy5 And params_cfy
    )
    And cgft.stewardship_cfy >= 1000 -- <UPDATE THIS>
  )
)

/* Name ordering helper */
, rec_name_logic As (
  Select
    donorlist.id_number
    , donorlist.report_name
    , donorlist.person_or_org
    , donorlist.household_id
    , donorlist.household_spouse_id
    , primary_name
    , primary_name_spouse
    , household_rpt_name
    , household_spouse_rpt_name
    , id_join
    -- Name ordering based on rules we had discussed: alum first, if both or neither are alums then female first
    , Case
        -- Anonymous donors take precedence
        When (
          anon.anon Is Not Null
          Or lower(primary_name) Like '%anonymous%donor%'
          Or lower(cust_name.custom_name) Like '%anonymous%'
          )
          -- Make sure they're not on the manual name override list, unless it's as anonymous
          And (
            cust_name.id_number Is Null
            Or lower(cust_name.custom_name) Like '%anonymous%'
          )
            Then 'Anon'
        -- If on deceased spouse list, override
        When dec_spouse_ids.id_number Is Not Null
          Then 'Manually HH'
        -- Organizations next
        When donorlist.person_or_org = 'O'
          Then 'Org'
        When donorlist.person_or_org = 'P'
          And upper(custlvl.custom_level) Like '%ORG%'
            Then 'Org'
        -- If no joint gift indicator, self only
        When no_joint_gifts_flag Is Not Null
          Then 'No Joint'
        -- If no spouse, use own name
        When donorlist.primary_name_spouse Is Null
          Then 'Self'
        -- If spouse, check if either/both have degrees
        When donorlist.primary_name_spouse Is Not Null
          Then
          Case
            -- If primary is only one with degrees, order is primary spouse
            When donorlist.yrs Is Not Null
              And donorlist.yrs_spouse Is Null
                Then 'Self Spouse'
            -- If spouse is only one with degrees, order is spouse primary
            When donorlist.yrs Is Null
              And donorlist.yrs_spouse Is Not Null
                Then 'Spouse Self'
            -- Check gender
            Else
            Case
              -- If primary is female list primary first
              When donorlist.gender = 'F'
                Then 'Self Spouse'
              -- If spouse is female list spouse first
              When donorlist.gender_spouse = 'F'
                Then 'Spouse Self'
              -- Fallback
              Else 'Self Spouse'
              End
            End
          End
      As name_order  
  From donorlist
  Left Join dec_spouse_ids
    On dec_spouse_ids.id_number = donorlist.id_number
  Left Join anon
    On anon.household_id = donorlist.household_id
  Left Join rpt_pbh634.tbl_IR_FY22_custom_name cust_name -- <UPDATE THIS>
    On cust_name.id_number = donorlist.id_number
  Left Join rpt_pbh634.tbl_IR_FY22_custom_level custlvl -- <UPDATE THIS>
    On custlvl.id_number = donorlist.id_number
)
, rec_name As (
  Select
    rn.id_number
    , rn.name_order
    , anon.anon
    -- Custom name flag
    , Case When cust_name.id_number Is Not Null Then 'Y' End
      As manually_named
    -- Proposed recognition name
    , Case
        -- If custom name, use that instead
        When cust_name.id_number Is Not Null
          Then cust_name.custom_name
        -- Fully anonymous donors are just Anonymous
        When rn.name_order = 'Anon'
          Then 'Anonymous'
        -- Orgs get their full name
        When rn.name_order = 'Org'
          Then household_rpt_name
        -- Deceased spouses -- have to manually join
        When rn.name_order = 'Manually HH'
          Then
          Case
            When dec_spouse_ids.yrs Is Not Null
              And yrs_join Is Null
                Then trim(pn || ' and ' || pnj)
            When dec_spouse_ids.yrs Is Null
              And yrs_join Is Not Null
                Then trim(pnj || ' and ' || pn)
            When dec_spouse_ids.gender = 'F'
              Then trim(pn || ' and ' || pnj)
            When dec_spouse_ids.gender_join = 'F'
              Then trim(pnj || ' and ' || pn)
            Else trim(pn || ' and ' || pnj)
            End
        -- If no joint gift indicator, use personal name
        When rn.name_order = 'No Joint'
          Then
          Case
            When rn.id_number = rn.household_id Then trim(primary_name)
            Else trim(primary_name_spouse)
            End
        -- Everyone else
        When rn.name_order = 'Self'
          Then trim(primary_name)
        When rn.name_order = 'Self Spouse'
          Then trim(primary_name || ' and ' || primary_name_spouse)
        When rn.name_order = 'Spouse Self'
          Then trim(primary_name_spouse || ' and ' || primary_name)
        End
        -- Add loyal tag if applicable
        || Case
             When rn.name_order <> 'Anon'
               And cust_name.override_suffixes Is Null
                 Then loyal.loyal
             End
        -- Add KLC tag if applicable
       /* || Case
             When rn.name_order Not In('Anon', 'Org')
               And cust_name.override_suffixes Is Null
                 Then fy_klc.klc
             End
        -- Add Cornerstone tag if applicable
        || Case
             When cornerstone.id_number Is Not Null
               Or cornerstone_s.id_number Is Not Null
                 Then '<CORNERSTONE>'
             End */
      As proposed_recognition_name --<EDIT>
    -- Proposed sort name within groups
    , Case
        When rn.name_order = 'Anon'
          Then '*Anonymous' -- Special characters sort before double space, 0-9, A-z, etc.
        When rn.name_order = 'Org'
          And person_or_org = 'P'
            Then -- For people categorized as orgs: use the custom name, dropping any The for alpha
            Case
              When substr(lower(cust_name.custom_name), 1, 4) = 'the '
                Then substr(cust_name.custom_name, 5)
              Else cust_name.custom_name
              End
        When rn.name_order = 'Org'
          Then -- For orgs: drop "The " from sort name
          Case
            When substr(lower(household_rpt_name), 1, 4) = 'the '
              Then substr(household_rpt_name, 5)
            Else household_rpt_name
            End
        When rn.name_order = 'Manually HH'
          Then
          Case
            When dec_spouse_ids.yrs Is Not Null
              And yrs_join Is Null
                Then trim(sn || '; ' || snj)
            When dec_spouse_ids.yrs Is Null
              And yrs_join Is Not Null
                Then trim(snj || '; ' || sn)
            When dec_spouse_ids.gender = 'F'
              Then trim(sn || '; ' || snj)
            When dec_spouse_ids.gender_join = 'F'
              Then trim(snj || '; ' || sn)
            Else trim(sn || '; ' || snj)
            End
        When rn.name_order = 'No Joint'
          -- Remove trailing spaces, if any, from last name to fix alphabetization issues
          Then regexp_replace(report_name, ' ,', ',')
        When rn.name_order = 'Self'
          Then regexp_replace(household_rpt_name, ' ,', ',')
        When rn.name_order = 'Self Spouse'
          Then regexp_replace(household_rpt_name, ' ,', ',') || '; ' || regexp_replace(household_spouse_rpt_name, ' ,', ',')
        When rn.name_order = 'Spouse Self'
          Then regexp_replace(household_spouse_rpt_name, ' ,', ',') || '; ' || regexp_replace(household_rpt_name, ' ,', ',')
        End
      As proposed_sort_name --<EDIT>
    -- Concatenated IDs for deduping
    , Case
        When rn.name_order = 'Anon'
          Then rn.household_id || rn.household_spouse_id -- Single space sorts before double space, 0-9, A-z, etc.
        When rn.name_order = 'Org'
          Then rn.household_id
        When rn.name_order = 'Manually HH'
          Then
          Case
            When dec_spouse_ids.yrs Is Not Null
              And yrs_join Is Null
                Then trim(dec_spouse_ids.id_number || dec_spouse_ids.id_join)
            When dec_spouse_ids.yrs Is Null
              And yrs_join Is Not Null
                Then trim(dec_spouse_ids.id_join || dec_spouse_ids.id_number)
            When dec_spouse_ids.gender = 'F'
              Then trim(dec_spouse_ids.id_number || dec_spouse_ids.id_join)
            When dec_spouse_ids.gender_join = 'F'
              Then trim(dec_spouse_ids.id_join || dec_spouse_ids.id_number)
            Else trim(dec_spouse_ids.id_number || dec_spouse_ids.id_join)
            End
        When rn.name_order = 'No Joint'
          Then rn.id_number
        When rn.name_order = 'Self'
          Then rn.household_id
        When rn.name_order = 'Self Spouse'
          Then rn.household_id || rn.household_spouse_id
        When rn.name_order = 'Spouse Self'
          Then rn.household_spouse_id || rn.household_id
        End
      As ids_for_deduping
  From rec_name_logic rn
  Left Join dec_spouse_ids
    On dec_spouse_ids.id_number = rn.id_number
  Left Join fy_klc
    On fy_klc.household_id = rn.household_id
  Left Join loyal
    On loyal.household_id = rn.household_id
  Left Join anon
    On anon.household_id = rn.household_id
  Left Join tbl_IR_FY22_custom_name cust_name -- <UPDATE THIS>
    On cust_name.id_number = rn.id_number
  Left Join cornerstone
    On cornerstone.id_number = rn.household_id
  Left Join cornerstone cornerstone_s
    On cornerstone_s.id_number = rn.household_spouse_id
)

/* Main query */
Select Distinct
  -- Print in IR flag, for household deduping
  rec_name.ids_for_deduping
  , dense_rank() Over(
      Partition By rec_name.ids_for_deduping
      Order By donorlist.proposed_giving_level Asc, lower(rec_name.proposed_sort_name) Asc, rec_name.proposed_recognition_name Desc, donorlist.household_rpt_name Asc, donorlist.id_number Asc
    )
    As name_rank
  , Case
      When dense_rank() Over(
        Partition By rec_name.ids_for_deduping
        Order By donorlist.proposed_giving_level Asc, lower(rec_name.proposed_sort_name) Asc, rec_name.proposed_recognition_name Desc, donorlist.household_rpt_name Asc, donorlist.id_number Asc
      ) = 1 Then 'Y'
      End
    As print_in_report
  -- Recognition name string
  , rec_name.proposed_sort_name
  , rec_name.proposed_recognition_name
  -- Giving level string
  , donorlist.proposed_giving_level
  -- Anonymous flags
  , Case
      When donorlist.proposed_giving_level <> donorlist.nonanon_giving_level
        And rec_name.anon Is Null
          Then donorlist.nonanon_giving_level
      End
    As different_nonanon_level
  , rec_name.anon
  --- Check last year's name; drops everything after the first < delimiter
  , Case
      When ir_names.ir21_name <> regexp_substr(rec_name.proposed_recognition_name, '[^<]*') --<UPDATE THIS>
        Then 'Y'
      End
    As name_change_from_pfy
  , ir_names.ir21_name --<UPDATE THIS>
  -- Fields
  , donorlist.deceased_past_year
  , donorlist.manual_giving_level
  , Case
      When rec_name.name_order = 'Manually HH'
        Then 'Y'
      End
    As manually_householded
  , rec_name.manually_named
  , Case
      When hr_names_s.honor_roll_name Is Not Null
        Or hr_names.honor_roll_name Is Not Null
        Then 'Y'
      End
      As has_nu_honor_roll_name
  , Case
      When proposed_sort_name = ' '
        Then NULL
      When dense_rank() Over(
          Partition By lower(proposed_recognition_name)
          Order By proposed_giving_level Asc, lower(proposed_sort_name) Asc, donorlist.id_number Asc
        ) > 1
        And dense_rank() Over(
          Partition By rec_name.ids_for_deduping
          Order By proposed_giving_level Asc, lower(proposed_sort_name) Asc, proposed_recognition_name Desc, donorlist.id_number Asc
        ) = 1
        Then 'Y'
      End
      As possible_dupe
  , donorlist.no_joint_gifts_flag
  , assign_conc.managers
  , assign_conc.assignment_types
  , assign_conc.pm
  , assign_conc.ppm
  , assign_conc.lgo
  , assign_reviewer.reviewer
  , assign_reviewer.reviewer_assign_type
  , donorlist.id_number
  , donorlist.report_name
  , donorlist.degrees_concat
  , dec_spouse_conc.dec_spouse_ids
  , donorlist.fmr_spouse_id
  , donorlist.fmr_spouse_name
  , donorlist.fmr_marital_status
  , donorlist.household_id
  , donorlist.person_or_org
  , donorlist.record_status_code
  , donorlist.household_rpt_name
  , donorlist.household_suffix
  , donorlist.primary_name
  , donorlist.constructed_name
  , donorlist.primary_name_source
  , Case
      When donorlist.primary_name <> donorlist.constructed_name
        Then 'Y'
      End
    As constructed_name_difference
  , Case
      When donorlist.primary_name_spouse <> donorlist.constructed_name_spouse
        Then 'Y'
      End
    As constructed_spouse_difference
  , donorlist.check_primary_lastname
  , donorlist.check_primary_lastname_spouse
  , donorlist.yrs
  , donorlist.gender
  , hr_names.honor_roll_name
  , donorlist.household_masters_year
  , donorlist.household_spouse_id
  , donorlist.household_spouse_rpt_name
  , donorlist.household_spouse_suffix
  , donorlist.primary_name_spouse
  , donorlist.constructed_name_spouse
  , donorlist.primary_name_source_spouse
  , donorlist.yrs_spouse
  , donorlist.gender_spouse
  , hr_names_s.honor_roll_name As honor_roll_name_spouse
  , donorlist.stewardship_cfy
  , donorlist.stewardship_anonymous_cfy
  , donorlist.stewardship_cfy - donorlist.stewardship_anonymous_cfy As stewardship_nonanonymous_cfy
  , donorlist.ngc_cfy
  , donorlist.cash_cfy
--  , loyal.stewardship_cfy
--  , loyal.stewardship_pfy1
--  , loyal.stewardship_pfy2
From donorlist
Inner Join rec_name
  On rec_name.id_number = donorlist.id_number
Left Join assign_conc
  On assign_conc.household_id = donorlist.household_id
Left Join assign_reviewer
  On assign_reviewer.household_id = donorlist.household_id
Left Join loyal
  On loyal.household_id = donorlist.household_id
Left Join dec_spouse_conc
  On dec_spouse_conc.id_number = donorlist.id_number
Left Join hr_names
  On hr_names.id_number = donorlist.household_id
Left Join hr_names hr_names_s
  On hr_names_s.id_number = donorlist.household_spouse_id
  Left Join ir_names
    On ir_names.id_number = donorlist.id_number
Order By
  proposed_giving_level Asc
  , lower(proposed_sort_name) Asc
  , proposed_recognition_name Desc
  , household_rpt_name
  , donorlist.id_number Asc
