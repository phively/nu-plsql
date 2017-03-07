With

/* All Kellogg alumni households and annual fund giving behavior. */

-- Housheholds
hh As (
  Select hh.id_number, hh.pref_mail_name, hh.degrees_concat, hh.program_group,
    hh.spouse_id_number, hh.spouse_pref_mail_name, hh.spouse_degrees_concat, hh.spouse_program_group,
    hh.household_id, hh.household_program_group
  From table(ksm_pkg.tbl_entity_households_ksm) hh
  Where hh.household_ksm_year Is Not Null
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

Select Distinct
  -- Household fields
  hh.household_id, hh.pref_mail_name, hh.degrees_concat, hh.program_group,
  hh.spouse_id_number, hh.spouse_pref_mail_name, hh.spouse_degrees_concat, hh.spouse_program_group,
  hh.household_id, hh.household_program_group
From nu_prs_trp_prospect prs
  Inner Join hh On hh.household_id = prs.id_number
