Create Or Replace View v_household_id As
With

/* Household ID -- defined as min(id_number, spouse_id_number) from the entity table.
   Easy, clean, and no business logic. */

-- KSM degrees concat table function
ksm_deg_conc As (
  Select id_number, degrees_concat, first_ksm_year, program, program_group
  From table(ksm_pkg.tbl_entity_degrees_concat_ksm)
),
-- Household ID assignment
household As (
  Select id_number, spouse_id_number,
  Case
    When trim(spouse_id_number) Is Null Then entity.id_number
    When entity.id_number < spouse_id_number Then entity.id_number
    Else spouse_id_number
  End As household_id
  From entity
),
household_deg As (
  Select Distinct household_id, household.id_number, spouse_id_number,
    dce.degrees_concat As e_dc, dcs.degrees_concat As s_dc,
    dce.first_ksm_year As e_ksm_yr, dcs.first_ksm_year As s_ksm_yr,
    dce.program_group As e_prg, dcs.program_group As s_prg
  From household
    -- Degrees concat for entity
    Left Join ksm_deg_conc dce
      On household.id_number = dce.id_number
    -- Degrees concat for spouse
    Left Join ksm_deg_conc dcs
      On household.spouse_id_number = dcs.id_number
)
-- Final table
Select entity.id_number, dce.degrees_concat, entity.spouse_id_number, dcs.degrees_concat as spouse_degrees_concat,
  -- Household fields
  hhd.household_id,
  trim(hhd.e_dc || '; ' || hhd.s_dc) As household_degrees_concat,
  Case When hhd.e_ksm_yr < hhd.s_ksm_yr Or hhd.s_ksm_yr Is Null Then hhd.e_ksm_yr Else hhd.s_ksm_yr End As household_first_ksm_year,
  Case When hhd.e_prg < hhd.s_prg Or hhd.s_prg Is Null Then hhd.e_prg Else hhd.s_prg End As household_program
From entity
  Left Join household_deg hhd
    On hhd.id_number = entity.id_number
  -- Degrees concat for entity
  Left Join ksm_deg_conc dce On entity.id_number = dce.id_number
  -- Degrees concat for spouse
  Left Join ksm_deg_conc dcs On entity.spouse_id_number = dcs.id_number
