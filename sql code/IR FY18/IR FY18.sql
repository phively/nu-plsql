/* FY18 Kellogg Investor's Report
    Based on Campaign giving through the entire counting period, FY07 through FY18
    See Paul's "Investor's Report" folder on the G drive for criteria and notes
    See GitHub for the complete version history: https://github.com/phively/nu-plsql/tree/master/sql%20code/IR%20FY18
    Shouldn't take more than 4 minutes to run to completion
*/

With

/* Parameters -- update this each year
  Also look for <UPDATE THIS> comment */
params_cfy As (
  Select
    2018 As params_cfy -- <UPDATE THIS>
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


/* Degree strings
  Kellogg stewardship degree years as defined by ksm_pkg. For the FY18 IR these are in the format:
  'YY, 'YY
  With years listed in chronological order and de-duped (listagg) */
, degs As (
  Select
    id_number
    , stewardship_years As yrs
  From table(ksm_pkg.tbl_entity_degrees_concat_ksm) deg
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

/* Household data
  Household IDs and definitions as defined by ksm_pkg. Names are based on primary name and personal suffix. */
, hhs As (
  Select *
  From table(ksm_pkg.tbl_entity_households_ksm)
)
, hh_name As (
  Select
    hhs.id_number
    , entity.gender_code
    , entity.record_status_code
    , entity.jnt_gifts_ind
    -- First Middle Last Suffix 'YY
    , trim(
        trim(
          trim(
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
          ) || ' ' || degs.yrs
        ) || (Case When entity.record_status_code = 'D' Then '<DECEASED>' End)
      )
      As primary_name
    , degs.yrs
    , Case
        When entity.record_status_code = 'D'
          And trunc(entity.status_change_date) Between cal.prev_fy_start And cal.today
          Then 'Y'
        End
      As deceased_past_year
  From hhs
  Inner Join entity
    On entity.id_number = hhs.id_number
  Cross Join v_current_calendar cal
  Left Join degs
    On degs.id_number = hhs.id_number
  Left Join hr_names
    On hr_names.id_number = hhs.id_number
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
    , hh_name_s.primary_name As primary_name_spouse
    , hh_name.yrs
    , hh_name_s.yrs As yrs_spouse
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
  Anonymous special handling indicator; entity should be anonymous for ALL gifts. Overrides the transaction-level anon flag. */
, anon As (
  Select Distinct
    hh.household_id
    , tms.short_desc As anon
  From handling
  Inner Join hh
    On hh.id_number = handling.id_number
  Inner Join tms_handling_type tms
    On tms.handling_type = handling.hnd_type_code
  Where hnd_type_code = 'AN' -- Anonymous
    And hnd_status_code = 'A' -- Active only
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

/* Deceased spouse TABLE -- update rpt_pbh634.tbl_ir_fy18_dec_spouse
  This is the interface used to manually household deceased spouses; could be done on other entities as well */
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
          Then hh.household_rpt_name
        When ds.id_number = hh.household_id
          Then hh.household_rpt_name
        Else hhd.household_spouse_rpt_name
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
          Then hhd.household_rpt_name
        When ds.id_join = hh.household_id
          Then hhd.household_rpt_name
        Else hhd.household_spouse_rpt_name
        End
      As snj
  From rpt_pbh634.tbl_ir_fy18_dec_spouse ds -- <UPDATE THIS>
  Inner Join hh
    On hh.id_number = ds.id_number
  Inner Join hh hhd
    On hhd.id_number = ds.id_join
)

/* Prospect assignments
  All active prospect manager and program manager assignments, to be used for manual review by staff */
, assign As (
  Select Distinct
    hh.household_id
    , prospect_id
    , assignment_id_number
    , assignment_report_name
  From v_assignment_history ah
  Inner Join hh
    On hh.id_number = ah.id_number
  Where assignment_active_calc = 'Active' -- Active assignments only
    And assignment_type In ('PP', 'PM', 'LG') -- Program Manager (PP), Prospect Manager (PM), Leadership Giving Officer (LG)
)
, assign_conc As (
  Select
    household_id
    , Listagg(assignment_report_name, ';  ') Within Group (Order By assignment_report_name)
      As managers
  From assign
  Group By household_id
)

/* KLC entities
  Our definition for Kellogg Leadership Circle. The young_klc needs to pull multiple years because gifts within 5 years of graduating
  are classified differently. */
, young_klc As (
  Select
    klc.*
  From table(ksm_pkg.tbl_klc_history) klc
  Cross Join params
  Where fiscal_year Between params_pfy5 And params_cfy -- KLC member in current or 5 previous FYs
)
, fy_klc As (
  Select Distinct
    household_id
    , '<KLC18>' As klc -- <UPDATE THIS>
  From young_klc
  Cross Join params
  Where fiscal_year = params_cfy
)

/* Loyal households
  Stewardship giving as defined by ksm_giving_trans (and thus indirectly by ksm_pkg).
  For the FY18 IR, loyal implies either spouse is credited toward any KSM gift > $0, including matches, for each of FY18, FY17, FY16  */
, loyal_giving As (
  Select Distinct
    hhs.household_id
    -- WARNING: includes new gifts and commitments as well as cash
    , sum(Case When fiscal_year = params_pfy2 Then hh_credit Else 0 End) As stewardship_pfy2
    , sum(Case When fiscal_year = params_pfy1 Then hh_credit Else 0 End) As stewardship_pfy1
    , sum(Case When fiscal_year = params_cfy Then hh_credit Else 0 End) As stewardship_cfy
  From hhs
  Cross Join params
  Inner Join v_ksm_giving_trans_hh gfts
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

/* Campaign giving amounts
  ksm_pkg rewrite of Kellogg campaign giving, based on Bill's campaign reporting table.
  For the FY18 IR, this deliberately counts bequests/life expectancy at face value, but only the PAID amounts of cancelled pledges. */
, cgft As (
  Select
    gft.*
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
        When entity.person_or_org = 'O' Then 'Z. Org'
        When campaign_steward_thru_fy18 >= 10000000 Then 'A. 10M+' -- <UPDATE THIS>
        When campaign_steward_thru_fy18 >=  5000000 Then 'B. 5M+' -- <UPDATE THIS>
        When campaign_steward_thru_fy18 >=  2500000 Then 'C. 2.5M+' -- <UPDATE THIS>
        When campaign_steward_thru_fy18 >=  1000000 Then 'D. 1M+' -- <UPDATE THIS>
        When campaign_steward_thru_fy18 >=   500000 Then 'E. 500K+' -- <UPDATE THIS>
        When campaign_steward_thru_fy18 >=   250000 Then 'F. 250K+' -- <UPDATE THIS>
        When campaign_steward_thru_fy18 >=   100000 Then 'G. 100K+' -- <UPDATE THIS>
        When campaign_steward_thru_fy18 >=    50000 Then 'H. 50K+' -- <UPDATE THIS>
        When campaign_steward_thru_fy18 >=    25000 Then 'I. 25K+' -- <UPDATE THIS>
        When campaign_steward_thru_fy18 >=    10000 Then 'J. 10K+' -- <UPDATE THIS>
        When campaign_steward_thru_fy18 >=     5000 Then 'K. 5K+' -- <UPDATE THIS>
        Else 'L. 2.5K+'
        End
      As proposed_giving_level
    , Case
        When entity.person_or_org = 'O' Then 'Z. Org'
        When nonanon_steward_thru_fy18 >= 10000000 Then 'A. 10M+' -- <UPDATE THIS>
        When nonanon_steward_thru_fy18 >=  5000000 Then 'B. 5M+' -- <UPDATE THIS>
        When nonanon_steward_thru_fy18 >=  2500000 Then 'C. 2.5M+' -- <UPDATE THIS>
        When nonanon_steward_thru_fy18 >=  1000000 Then 'D. 1M+' -- <UPDATE THIS>
        When nonanon_steward_thru_fy18 >=   500000 Then 'E. 500K+' -- <UPDATE THIS>
        When nonanon_steward_thru_fy18 >=   250000 Then 'F. 250K+' -- <UPDATE THIS>
        When nonanon_steward_thru_fy18 >=   100000 Then 'G. 100K+' -- <UPDATE THIS>
        When nonanon_steward_thru_fy18 >=    50000 Then 'H. 50K+' -- <UPDATE THIS>
        When nonanon_steward_thru_fy18 >=    25000 Then 'I. 25K+' -- <UPDATE THIS>
        When nonanon_steward_thru_fy18 >=    10000 Then 'J. 10K+' -- <UPDATE THIS>
        When nonanon_steward_thru_fy18 >=     5000 Then 'K. 5K+' -- <UPDATE THIS>
        Else 'L. 2.5K+'
        End
      As nonanon_giving_level
  From v_ksm_giving_campaign gft
  Inner Join entity
    On entity.id_number = gft.id_number
  -- Interface for custom giving levels override; add to the tbl_ir_fy18_custom_level table and they'll show up here
  Left Join tbl_ir_fy18_custom_level custlvl -- <UPDATE THIS>
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
      As cash_fy13 -- <UPDATE THIS>
    , sum(Case When fiscal_year = params_pfy4 And tx_gypm_ind <> 'P' Then hh_credit Else 0 End)
      As cash_fy14 -- <UPDATE THIS>
    , sum(Case When fiscal_year = params_pfy3 And tx_gypm_ind <> 'P' Then hh_credit Else 0 End)
      As cash_fy15 -- <UPDATE THIS>
    , sum(Case When fiscal_year = params_pfy2 And tx_gypm_ind <> 'P' Then hh_credit Else 0 End)
      As cash_fy16 -- <UPDATE THIS>
    , sum(Case When fiscal_year = params_pfy1 And tx_gypm_ind <> 'P' Then hh_credit Else 0 End)
      As cash_fy17 -- <UPDATE THIS>
    , sum(Case When fiscal_year = params_cfy And tx_gypm_ind <> 'P' Then hh_credit Else 0 End)
      As cash_fy18 -- <UPDATE THIS>
  From hhs
  Cross Join params
  Inner Join v_ksm_giving_trans_hh gfts
    On gfts.household_id = hhs.household_id
  Group By
    hhs.id_number
    , hhs.household_id
    , hhs.household_rpt_name
    , hhs.household_spouse_id
    , hhs.household_spouse
)

/* Combine all criteria
  Main temp table pulling together all criteria for IR17 */
, donorlist As (
  (
  -- $2500+ cumulative campaign giving for people
  Select
    cgft.*, hh.deceased_past_year, hh.record_status_code, hh.household_spouse_rpt_name, hh.household_suffix, hh.household_spouse_suffix
    , hh.household_masters_year, hh.primary_name, hh.gender, hh.primary_name_spouse, hh.gender_spouse
    , hh.person_or_org, hh.yrs, hh.yrs_spouse, hh.fmr_spouse_id, hh.fmr_spouse_name, hh.fmr_marital_status
    , hh.no_joint_gifts_flag
  From cgft
  Inner Join hh
    On hh.id_number = cgft.id_number
  Where hh.person_or_org = 'P' -- People
    And (
      cgft.campaign_steward_thru_fy18 >= 2500 -- <UPDATE THIS>
      Or manual_giving_level = 'Y' -- Always include custom level override even if below $2500
    )
  ) Union All (
  -- $100K+ cumulative campaign giving for orgs
  Select
    cgft.*, hh.deceased_past_year, hh.record_status_code, hh.household_spouse_rpt_name, hh.household_suffix, hh.household_spouse_suffix
    , hh.household_masters_year, hh.primary_name, hh.gender, hh.primary_name_spouse, hh.gender_spouse
    , hh.person_or_org, hh.yrs, hh.yrs_spouse, hh.fmr_spouse_id, hh.fmr_spouse_name, hh.fmr_marital_status
    , hh.no_joint_gifts_flag
  From cgft
  Inner Join hh
    On hh.id_number = cgft.id_number
  Where hh.person_or_org = 'O' -- Orgs
    And (
      cgft.campaign_steward_thru_fy18 >= 100000 -- <UPDATE THIS>
      Or manual_giving_level = 'Y' -- Always include custom level override even if below $2500
    )
  ) Union All (
  -- Young alumni giving $1000+ from FY12 on
  Select
    cgft.*, hh.deceased_past_year, hh.record_status_code, hh.household_spouse_rpt_name, hh.household_suffix, hh.household_spouse_suffix
    , hh.household_masters_year, hh.primary_name, hh.gender, hh.primary_name_spouse, hh.gender_spouse
    , hh.person_or_org, hh.yrs, hh.yrs_spouse, hh.fmr_spouse_id, hh.fmr_spouse_name, hh.fmr_marital_status
    , hh.no_joint_gifts_flag
  From cgft
  Cross Join params
  Inner Join hh
    On hh.id_number = cgft.id_number
  Left Join cash
    On cash.id_number = cgft.id_number
  -- Graduated within "past" 5 years and gave at least $1000 "this" year
  Where cgft.household_id In (Select Distinct household_id From young_klc)
    And (
      (
        (hh.last_noncert_year Between params_pfy10 And params_pfy5
          Or hh.spouse_last_noncert_year Between params_pfy10 And params_pfy5)
        And (campaign_fy13 >= 1000 Or cash_fy13 >= 1000) -- <UPDATE THIS>
      )
      Or (
        (hh.last_noncert_year Between params_pfy9 And params_pfy4
          Or hh.spouse_last_noncert_year Between params_pfy9 And params_pfy4)
        And (campaign_fy14 >= 1000 Or cash_fy14 >= 1000) -- <UPDATE THIS>
      )
      Or (
        (hh.last_noncert_year Between params_pfy8 And params_pfy3
          Or hh.spouse_last_noncert_year Between params_pfy8 And params_pfy3)
        And (campaign_fy15 >= 1000 Or cash_fy15 >= 1000) -- <UPDATE THIS>
      )
      Or (
        (hh.last_noncert_year Between params_pfy7 And params_pfy2
          Or hh.spouse_last_noncert_year Between params_pfy7 And params_pfy2)
        And (campaign_fy16 >= 1000 Or cash_fy16 >= 1000) -- <UPDATE THIS>
      )
      Or (
        (hh.last_noncert_year Between params_pfy6 And params_pfy1
          Or hh.spouse_last_noncert_year Between params_pfy6 And params_pfy1)
        And (campaign_fy17 >= 1000 Or cash_fy17 >= 1000) -- <UPDATE THIS>
      )
      Or (
        (hh.last_noncert_year Between params_pfy5 And params_cfy
          Or hh.spouse_last_noncert_year Between params_pfy5 And params_cfy)
        And (campaign_fy18 >= 1000 Or cash_fy18 >= 1000) -- <UPDATE THIS>
      )
    )
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
        When anon.anon Is Not Null
          Or lower(primary_name) Like '%anonymous%donor%'
          Or lower(cust_name.custom_name) Like '%anonymous%'
            Then 'Anon'
        -- Organizations next
        When donorlist.person_or_org = 'O'
          Then 'Org'
        When donorlist.person_or_org = 'P'
          And upper(custlvl.custom_level) Like '%ORG%'
            Then 'Org'
        -- If on deceased spouse list, override
        When dec_spouse_ids.id_number Is Not Null
          Then 'Manually HH'
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
  Left Join tbl_IR_FY18_custom_name cust_name -- <UPDATE THIS>
    On cust_name.id_number = donorlist.id_number
  Left Join Tbl_IR_FY18_custom_level custlvl -- <UPDATE THIS>
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
        || Case
             When rn.name_order Not In('Anon', 'Org')
               And cust_name.override_suffixes Is Null
                 Then fy_klc.klc
             End
        -- Add Cornerstone tag if applicable
        || Case
             When cornerstone.id_number Is Not Null
               Or cornerstone_s.id_number Is Not Null
                 Then '<CORNERSTONE>'
             End
      As proposed_recognition_name
    -- Proposed sort name within groups
    , Case
        When rn.name_order = 'Anon'
          Then ' ' -- Single space sorts before double space, 0-9, A-z, etc.
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
          Then report_name
        When rn.name_order = 'Self'
          Then household_rpt_name
        When rn.name_order = 'Self Spouse'
          Then household_rpt_name || '; ' || household_spouse_rpt_name
        When rn.name_order = 'Spouse Self'
          Then household_spouse_rpt_name || '; ' || household_rpt_name
        End
      As proposed_sort_name
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
  Left Join tbl_IR_FY18_custom_name cust_name -- <UPDATE THIS>
    On cust_name.id_number = rn.id_number
  Left Join tbl_IR_FY18_cornerstone cornerstone -- <UPDATE THIS>
    On cornerstone.id_number = rn.household_id
  Left Join tbl_IR_FY18_cornerstone cornerstone_s -- <UPDATE THIS>
    On cornerstone_s.id_number = rn.household_spouse_id
)

/* Main query */
Select Distinct
  -- Print in IR flag, for household deduping
  ids_for_deduping
  , dense_rank() Over(
      Partition By ids_for_deduping
      Order By proposed_giving_level Asc, lower(proposed_sort_name) Asc, proposed_recognition_name Desc, donorlist.id_number Asc
    )
    As name_rank
  , Case
      When dense_rank() Over(
        Partition By ids_for_deduping
        Order By proposed_giving_level Asc, lower(proposed_sort_name) Asc, proposed_recognition_name Desc, donorlist.id_number Asc
      ) = 1 Then 'Y'
      End
    As print_in_report
  -- Recognition name string
  , rec_name.proposed_sort_name
  , rec_name.proposed_recognition_name
  -- Giving level string
  , proposed_giving_level
  -- Anonymous flags
  , Case
      When proposed_giving_level <> nonanon_giving_level
        And rec_name.anon Is Null
          Then nonanon_giving_level
      End
    As different_nonanon_level
  , rec_name.anon
  , anon_steward_thru_fy18 -- <UPDATE THIS>
  , nonanon_steward_thru_fy18 -- <UPDATE THIS>
  -- Fields
  , campaign_steward_thru_fy18 -- <UPDATE THIS>
  , deceased_past_year
  , manual_giving_level
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
          Partition By ids_for_deduping
          Order By proposed_giving_level Asc, lower(proposed_sort_name) Asc, proposed_recognition_name Desc, donorlist.id_number Asc
        ) = 1
        Then 'Y'
      End
      As possible_dupe
  , no_joint_gifts_flag
  , assign_conc.managers
  , donorlist.id_number
  , report_name
  , degrees_concat
  , dec_spouse_conc.dec_spouse_ids
  , fmr_spouse_id
  , fmr_spouse_name
  , fmr_marital_status
  , donorlist.household_id
  , person_or_org
  , record_status_code
  , household_rpt_name
  , household_suffix
  , primary_name
  , yrs
  , gender
  , hr_names.honor_roll_name
  , household_masters_year
  , household_spouse_id
  , household_spouse_rpt_name
  , household_spouse_suffix
  , primary_name_spouse
  , yrs_spouse
  , gender_spouse
  , hr_names_s.honor_roll_name
  , loyal.stewardship_cfy
  , loyal.stewardship_pfy1
  , loyal.stewardship_pfy2
  , campaign_steward_giving
  , campaign_anonymous
  , campaign_nonanonymous
  , campaign_giving
  , campaign_reachbacks
  , campaign_fy08
  , campaign_fy09
  , campaign_fy10
  , campaign_fy11
  , campaign_fy12
  , campaign_fy13
  , campaign_fy14
  , campaign_fy15
  , campaign_fy16
  , campaign_fy17
  , campaign_fy18
  , campaign_fy19 -- <UPDATE THIS>
From donorlist
Inner Join rec_name
  On rec_name.id_number = donorlist.id_number
Left Join assign_conc
  On assign_conc.household_id = donorlist.household_id
Left Join loyal
  On loyal.household_id = donorlist.household_id
Left Join dec_spouse_conc
  On dec_spouse_conc.id_number = donorlist.id_number
Left Join hr_names
  On hr_names.id_number = donorlist.household_id
Left Join hr_names hr_names_s
  On hr_names_s.id_number = donorlist.household_spouse_id
Order By
  proposed_giving_level Asc
  , lower(proposed_sort_name) Asc
  , proposed_recognition_name Desc
  , donorlist.id_number Asc
