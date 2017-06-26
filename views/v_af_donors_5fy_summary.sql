Create Or Replace View v_af_donors_5fy_summary As
With

/* Requires the gift data aggregated in v_af_donors_gifts_5fy. Aggregated by household giving source donor and related
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
)

-- Aggregated by entity and fiscal year
Select
  -- Entity fields
  id_hh_src_dnr, pref_mail_name, pref_name_sort, person_or_org, record_status_code, institutional_suffix,
  entity_deg.degrees_concat As src_dnr_degrees_concat,
  entity_deg.first_ksm_year As src_dnr_first_ksm_year,
  entity_deg.program As src_dnr_program,
  entity_deg.program_group As src_dnr_program_group,
  master_state, master_country, gender_code, spouse_id_number, spouse_pref_mail_name,
  spouse_deg.degrees_concat As spouse_degrees_concat,
  spouse_deg.program As spouse_program,
  spouse_deg.program_group As spouse_program_group,
  -- Prospect reporting table fields
  prs.employer_name, prs.business_title, prs.prospect_id, prs.prospect_manager, prs.team, prs.prospect_stage,
  prs.officer_rating, prs.evaluation_rating,
  -- Indicators
  ksm_alum_flag, kac.short_desc As kac, gab.short_desc As gab,
  Case When lower(institutional_suffix) Like '%trustee%' Then 'Trustee' Else NULL End As trustee,
  -- Date fields
  curr_fy, data_as_of,
  -- Precalculated giving fields
  first_af_gift_year,
  -- Aggregated giving amounts
  sum(Case When fiscal_year = (curr_fy - 0) Then legal_amount Else 0 End) As ksm_af_curr_fy,
  sum(Case When fiscal_year = (curr_fy - 1) Then legal_amount Else 0 End) As ksm_af_prev_fy1,
  sum(Case When fiscal_year = (curr_fy - 2) Then legal_amount Else 0 End) As ksm_af_prev_fy2,
  sum(Case When fiscal_year = (curr_fy - 3) Then legal_amount Else 0 End) As ksm_af_prev_fy3,
  sum(Case When fiscal_year = (curr_fy - 4) Then legal_amount Else 0 End) As ksm_af_prev_fy4,
  sum(Case When fiscal_year = (curr_fy - 5) Then legal_amount Else 0 End) As ksm_af_prev_fy5,
  sum(Case When fiscal_year = (curr_fy - 6) Then legal_amount Else 0 End) As ksm_af_prev_fy6,
  sum(Case When fiscal_year = (curr_fy - 7) Then legal_amount Else 0 End) As ksm_af_prev_fy7,
  -- Aggregated YTD giving amounts
  sum(Case When fiscal_year = (curr_fy - 0) And ytd_ind = 'Y' Then legal_amount Else 0 End) As ksm_af_curr_fy_ytd,
  sum(Case When fiscal_year = (curr_fy - 1) And ytd_ind = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy1_ytd,
  sum(Case When fiscal_year = (curr_fy - 2) And ytd_ind = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy2_ytd,
  sum(Case When fiscal_year = (curr_fy - 3) And ytd_ind = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy3_ytd,
  sum(Case When fiscal_year = (curr_fy - 4) And ytd_ind = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy4_ytd,
  sum(Case When fiscal_year = (curr_fy - 5) And ytd_ind = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy5_ytd,
  sum(Case When fiscal_year = (curr_fy - 6) And ytd_ind = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy6_ytd,
  sum(Case When fiscal_year = (curr_fy - 7) And ytd_ind = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy7_ytd,
  -- Aggregated match amounts
  sum(Case When fiscal_year = (curr_fy - 0) And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As ksm_af_curr_fy_match,
  sum(Case When fiscal_year = (curr_fy - 1) And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As ksm_af_prev_fy1_match,
  sum(Case When fiscal_year = (curr_fy - 2) And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As ksm_af_prev_fy2_match,
  sum(Case When fiscal_year = (curr_fy - 3) And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As ksm_af_prev_fy3_match,
  sum(Case When fiscal_year = (curr_fy - 4) And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As ksm_af_prev_fy4_match,
  sum(Case When fiscal_year = (curr_fy - 5) And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As ksm_af_prev_fy5_match,
  sum(Case When fiscal_year = (curr_fy - 6) And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As ksm_af_prev_fy6_match,
  sum(Case When fiscal_year = (curr_fy - 7) And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As ksm_af_prev_fy7_match,
  -- Recent gift details
  max(Case When fiscal_year = (curr_fy - 0) then date_of_record Else NULL End) As last_gift_curr_fy,
  max(Case When fiscal_year = (curr_fy - 1) then date_of_record Else NULL End) As last_gift_prev_fy1,
  max(Case When fiscal_year = (curr_fy - 2) then date_of_record Else NULL End) As last_gift_prev_fy2,
  -- Count of gifts per year
  sum(Case When fiscal_year = (curr_fy - 0) then 1 Else 0 End) As gifts_curr_fy,
  sum(Case When fiscal_year = (curr_fy - 1) then 1 Else 0 End) As gifts_prev_fy1,
  sum(Case When fiscal_year = (curr_fy - 2) then 1 Else 0 End) As gifts_prev_fy2
From v_af_gifts_srcdnr_5fy af_gifts
  Left Join prs On prs.id_number = af_gifts.id_hh_src_dnr
  Left Join deg entity_deg On entity_deg.id_number = af_gifts.id_hh_src_dnr
  Left Join deg spouse_deg On spouse_deg.id_number = af_gifts.spouse_id_number
  Left Join kac On id_hh_src_dnr = kac.household_id
  Left Join gab On id_hh_src_dnr = gab.household_id
Group By id_hh_src_dnr, pref_mail_name, pref_name_sort, person_or_org, record_status_code, institutional_suffix,
  entity_deg.degrees_concat, entity_deg.first_ksm_year, entity_deg.program, entity_deg.program_group, master_state, master_country, gender_code,
  spouse_id_number, spouse_pref_mail_name, spouse_deg.degrees_concat, spouse_deg.program, spouse_deg.program_group,
  -- Prospect reporting table fields
  prs.employer_name, prs.business_title, prs.prospect_id, prs.prospect_manager, prs.team, prs.prospect_stage,
  prs.officer_rating, prs.evaluation_rating,
  -- Indicators
  ksm_alum_flag, kac.short_desc, gab.short_desc,
  -- Date fields
  curr_fy, data_as_of,
  -- Precalculated giving fields
  first_af_gift_year
