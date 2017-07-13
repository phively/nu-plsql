Create Or Replace View v_af_donors_5fy_summary As
With

/* Requires the gift data aggregated in v_af_gifts_srcdnr_5fy. Aggregated by household giving source donor and related
   fields, with each of the recent fiscal years its own column. */ 

-- Degrees concat
deg As (
  Select deg.id_number, deg.degrees_concat, deg.first_ksm_year, deg.program, deg.program_group
  From table(ksm_pkg.tbl_entity_degrees_concat_ksm) deg
),

-- Housheholds
hh As (
  Select id_number, household_id
  From table(ksm_pkg.tbl_entity_households_ksm) hh
),

-- Prospect reporting table
prs As (
  Select p.id_number, p.business_title,
    trim(p.employer_name1 || ' ' || p.employer_name2) As employer_name,
    p.prospect_id, p.prospect_manager, p.team, p.prospect_stage, p.officer_rating, p.evaluation_rating
  From nu_prs_trp_prospect p
),

-- Committee members
kac As (
  Select hh.household_id, comm.short_desc, comm.status, comm.role
  From table(ksm_pkg.tbl_committee_kac) comm
    Inner Join hh On hh.id_number = comm.id_number
),
gab As (
  Select hh.household_id, comm.short_desc, comm.status, comm.role
  From table(ksm_pkg.tbl_committee_gab) comm
    Inner Join hh On hh.id_number = comm.id_number
),

-- KLC segments
klc_cfy As (
  Select Distinct household_id, 'Y' As klc0
  From gift_clubs
  Cross Join rpt_pbh634.v_current_calendar cal
  Inner Join hh On hh.id_number = gift_clubs.gift_club_id_number
  Left Join nu_mem_v_tmsclublevel tms_lvl On tms_lvl.level_code = gift_clubs.school_code
  Where gift_club_code = 'LKM'
    And substr(gift_club_end_date, 0, 4) = cal.curr_fy
),
klc_pfy1 As (
  Select Distinct household_id, 'Y' As klc1
  From gift_clubs
  Cross Join rpt_pbh634.v_current_calendar cal
  Inner Join hh On hh.id_number = gift_clubs.gift_club_id_number
  Left Join nu_mem_v_tmsclublevel tms_lvl On tms_lvl.level_code = gift_clubs.school_code
  Where gift_club_code = 'LKM'
    And substr(gift_club_end_date, 0, 4) = cal.curr_fy - 1
),
klc_pfy2 As (
  Select Distinct household_id, 'Y' As klc2
  From gift_clubs
  Cross Join rpt_pbh634.v_current_calendar cal
  Inner Join hh On hh.id_number = gift_clubs.gift_club_id_number
  Left Join nu_mem_v_tmsclublevel tms_lvl On tms_lvl.level_code = gift_clubs.school_code
  Where gift_club_code = 'LKM'
    And substr(gift_club_end_date, 0, 4) = cal.curr_fy - 2
),

-- Kellogg Annual Fund allocations as defined in ksm_pkg
ksm_af_allocs As (
  Select allocation_code
  From table(ksm_pkg.tbl_alloc_annual_fund_ksm)
),

-- First gift year
first_af As (
  Select hh.household_id,
    min(gft.fiscal_year) As first_af_gift_year
  From nu_gft_trp_gifttrans gft
  Inner Join ksm_af_allocs
    On ksm_af_allocs.allocation_code = gft.allocation_code
  Inner Join hh On hh.id_number = ksm_pkg.get_gift_source_donor_ksm(tx_number)
  Where tx_gypm_ind != 'P'
  Group By hh.household_id
),

-- Aggregated by entity and fiscal year
totals As (
  Select
    id_hh_src_dnr,
      -- Aggregated giving amounts
    sum(Case When fiscal_year = (curr_fy - 0) And af_flag = 'Y' Then legal_amount Else 0 End) As ksm_af_curr_fy,
    sum(Case When fiscal_year = (curr_fy - 1) And af_flag = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy1,
    sum(Case When fiscal_year = (curr_fy - 2) And af_flag = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy2,
    sum(Case When fiscal_year = (curr_fy - 3) And af_flag = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy3,
    sum(Case When fiscal_year = (curr_fy - 4) And af_flag = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy4,
    sum(Case When fiscal_year = (curr_fy - 5) And af_flag = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy5,
    sum(Case When fiscal_year = (curr_fy - 6) And af_flag = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy6,
    sum(Case When fiscal_year = (curr_fy - 7) And af_flag = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy7,
    -- Aggregated YTD giving amounts
    sum(Case When fiscal_year = (curr_fy - 0) And af_flag = 'Y' And ytd_ind = 'Y' Then legal_amount Else 0 End) As ksm_af_curr_fy_ytd,
    sum(Case When fiscal_year = (curr_fy - 1) And af_flag = 'Y' And ytd_ind = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy1_ytd,
    sum(Case When fiscal_year = (curr_fy - 2) And af_flag = 'Y' And ytd_ind = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy2_ytd,
    sum(Case When fiscal_year = (curr_fy - 3) And af_flag = 'Y' And ytd_ind = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy3_ytd,
    sum(Case When fiscal_year = (curr_fy - 4) And af_flag = 'Y' And ytd_ind = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy4_ytd,
    sum(Case When fiscal_year = (curr_fy - 5) And af_flag = 'Y' And ytd_ind = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy5_ytd,
    sum(Case When fiscal_year = (curr_fy - 6) And af_flag = 'Y' And ytd_ind = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy6_ytd,
    sum(Case When fiscal_year = (curr_fy - 7) And af_flag = 'Y' And ytd_ind = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy7_ytd,
    -- Aggregated match amounts
    sum(Case When fiscal_year = (curr_fy - 0) And af_flag = 'Y' And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As ksm_af_curr_fy_match,
    sum(Case When fiscal_year = (curr_fy - 1) And af_flag = 'Y' And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As ksm_af_prev_fy1_match,
    sum(Case When fiscal_year = (curr_fy - 2) And af_flag = 'Y' And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As ksm_af_prev_fy2_match,
    sum(Case When fiscal_year = (curr_fy - 3) And af_flag = 'Y' And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As ksm_af_prev_fy3_match,
    sum(Case When fiscal_year = (curr_fy - 4) And af_flag = 'Y' And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As ksm_af_prev_fy4_match,
    sum(Case When fiscal_year = (curr_fy - 5) And af_flag = 'Y' And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As ksm_af_prev_fy5_match,
    sum(Case When fiscal_year = (curr_fy - 6) And af_flag = 'Y' And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As ksm_af_prev_fy6_match,
    sum(Case When fiscal_year = (curr_fy - 7) And af_flag = 'Y' And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As ksm_af_prev_fy7_match,
    -- Recent gift details
    max(Case When fiscal_year = (curr_fy - 0) And af_flag = 'Y' Then date_of_record Else NULL End) As last_gift_curr_fy,
    max(Case When fiscal_year = (curr_fy - 1) And af_flag = 'Y' Then date_of_record Else NULL End) As last_gift_prev_fy1,
    max(Case When fiscal_year = (curr_fy - 2) And af_flag = 'Y' Then date_of_record Else NULL End) As last_gift_prev_fy2,
    -- Count of gifts per year
    sum(Case When fiscal_year = (curr_fy - 0) And af_flag = 'Y' Then 1 Else 0 End) As gifts_curr_fy,
    sum(Case When fiscal_year = (curr_fy - 1) And af_flag = 'Y' Then 1 Else 0 End) As gifts_prev_fy1,
    sum(Case When fiscal_year = (curr_fy - 2) And af_flag = 'Y' Then 1 Else 0 End) As gifts_prev_fy2,
    -- Aggregated current use
    sum(Case When fiscal_year = (curr_fy - 0) Then legal_amount Else 0 End) As cru_curr_fy,
    sum(Case When fiscal_year = (curr_fy - 1) Then legal_amount Else 0 End) As cru_prev_fy1,
    sum(Case When fiscal_year = (curr_fy - 2) Then legal_amount Else 0 End) As cru_prev_fy2,
    -- Aggregated YTD current use
    sum(Case When fiscal_year = (curr_fy - 0) And ytd_ind = 'Y' Then legal_amount Else 0 End) As cru_curr_fy_ytd,
    sum(Case When fiscal_year = (curr_fy - 1) And ytd_ind = 'Y' Then legal_amount Else 0 End) As cru_prev_fy1_ytd,
    sum(Case When fiscal_year = (curr_fy - 2) And ytd_ind = 'Y' Then legal_amount Else 0 End) As cru_prev_fy2_ytd
  From v_af_gifts_srcdnr_5fy af_gifts
  Group By id_hh_src_dnr
)

-- Final results
Select Distinct
  -- Entity fields
  totals.id_hh_src_dnr, pref_mail_name, pref_name_sort, report_name, person_or_org, record_status_code, institutional_suffix,
  entity_deg.degrees_concat As src_dnr_degrees_concat,
  entity_deg.first_ksm_year As src_dnr_first_ksm_year,
  entity_deg.program As src_dnr_program,
  entity_deg.program_group As src_dnr_program_group,
  gender_code, spouse_id_number, spouse_pref_mail_name,
  spouse_deg.degrees_concat As spouse_degrees_concat,
  spouse_deg.program As spouse_program,
  spouse_deg.program_group As spouse_program_group,
  -- Prospect reporting table fields
  prs.employer_name, prs.business_title, prs.prospect_id, prs.prospect_manager, prs.team, prs.prospect_stage,
  prs.officer_rating, prs.evaluation_rating,
  -- Indicators
  ksm_alum_flag, kac.short_desc As kac, gab.short_desc As gab,
  Case When lower(institutional_suffix) Like '%trustee%' Then 'Trustee' Else NULL End As trustee,
  klc_cfy.klc0 As klc_cfy, klc_pfy1.klc1 As klc_pfy1, klc_pfy2.klc2 As klc_pfy2,
  -- Date fields
  curr_fy, data_as_of,
  -- Precalculated giving fields
  first_af.first_af_gift_year,
  ksm_af_curr_fy, ksm_af_prev_fy1, ksm_af_prev_fy2, ksm_af_prev_fy3, ksm_af_prev_fy4, ksm_af_prev_fy5, ksm_af_prev_fy6, ksm_af_prev_fy7,
  ksm_af_curr_fy_ytd, ksm_af_prev_fy1_ytd, ksm_af_prev_fy2_ytd, ksm_af_prev_fy3_ytd, ksm_af_prev_fy4_ytd, ksm_af_prev_fy5_ytd,
  ksm_af_prev_fy6_ytd, ksm_af_prev_fy7_ytd,
  ksm_af_curr_fy_match, ksm_af_prev_fy1_match, ksm_af_prev_fy2_match, ksm_af_prev_fy3_match, ksm_af_prev_fy4_match, ksm_af_prev_fy5_match,
  ksm_af_prev_fy6_match, ksm_af_prev_fy7_match,
  last_gift_curr_fy, last_gift_prev_fy1, last_gift_prev_fy2,
  gifts_curr_fy, gifts_prev_fy1, gifts_prev_fy2,
  cru_curr_fy, cru_prev_fy1, cru_prev_fy2, cru_curr_fy_ytd, cru_prev_fy1_ytd, cru_prev_fy2_ytd
From v_af_gifts_srcdnr_5fy af_gifts
Inner Join totals On totals.id_hh_src_dnr = af_gifts.id_hh_src_dnr
Left Join prs On prs.id_number = af_gifts.id_hh_src_dnr
Left Join first_af On first_af.household_id = af_gifts.id_hh_src_dnr
Left Join deg entity_deg On entity_deg.id_number = af_gifts.id_hh_src_dnr
Left Join deg spouse_deg On spouse_deg.id_number = af_gifts.spouse_id_number
Left Join kac On totals.id_hh_src_dnr = kac.household_id
Left Join gab On totals.id_hh_src_dnr = gab.household_id
Left Join klc_cfy On klc_cfy.household_id = af_gifts.id_hh_src_dnr
Left Join klc_pfy1 On klc_pfy1.household_id = af_gifts.id_hh_src_dnr
Left Join klc_pfy2 On klc_pfy2.household_id = af_gifts.id_hh_src_dnr
