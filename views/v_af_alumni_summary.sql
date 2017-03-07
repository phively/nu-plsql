Create Or Replace View v_af_alumni_summary As
With

/* All Kellogg alumni households and annual fund giving behavior.
   Base table is nu_prs_trp_prospect so deceased entities are excluded. */

-- Housheholds
hh As (
  Select hh.id_number, hh.pref_mail_name, hh.degrees_concat, hh.program_group,
    hh.spouse_id_number, hh.spouse_pref_mail_name, hh.spouse_degrees_concat, hh.spouse_program_group,
    hh.household_id, hh.household_program_group
  From table(ksm_pkg.tbl_entity_households_ksm) hh
  Where hh.household_ksm_year Is Not Null
)/*,

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
)*/

Select Distinct
  -- Household fields
  hh.household_id, hh.pref_mail_name, hh.degrees_concat, hh.program_group,
  hh.spouse_id_number, hh.spouse_pref_mail_name, hh.spouse_degrees_concat, hh.spouse_program_group,
  hh.household_program_group,
  -- Entity-based fields
  prs.record_status_code, prs.pref_state, prs.preferred_country,
  prs.business_title,
  trim(prs.employer_name1 || ' ' || prs.employer_name2) As employer_name,
  -- Giving fields
  af_summary.ksm_af_curr_fy, af_summary.ksm_af_prev_fy1, af_summary.ksm_af_prev_fy2, af_summary.ksm_af_prev_fy3,
  af_summary.ksm_af_prev_fy4, af_summary.ksm_af_prev_fy5
From nu_prs_trp_prospect prs
  Inner Join hh On hh.household_id = prs.id_number
  Left Join v_af_donors_5fy_summary af_summary On af_summary.id_hh_src_dnr = hh.household_id
