Create Or Replace View v_af_donors_5fy As
With

/* Requires the gift data aggregated in v_af_donors_gifts_5fy. Aggregated by household giving source donor and related fields,
   fiscal year, allocation, and whether the gift was made year-to-date or not. */

-- Degrees concat
deg As (
  Select id_number, degrees_concat, program, program_group
  From table(ksm_pkg.tbl_entity_degrees_concat_ksm)
)

-- Final results aggregated by entity and year
Select
  -- Entity fields
  id_hh_src_dnr, pref_name_sort, person_or_org, record_status_code, institutional_suffix,
  entity_deg.degrees_concat As src_dnr_degrees_concat,
  entity_deg.program As src_dnr_program,
  entity_deg.program_group As src_dnr_program_group,
  master_state, master_country, gender_code, spouse_id_number,
  spouse_deg.degrees_concat As spouse_degrees_concat,
  ksm_alum_flag,
  -- Giving fields
  allocation_code, alloc_short_name, alloc_purpose_desc, fiscal_year, ytd_ind,
  -- Date fields
  curr_fy, data_as_of,
  -- Aggregated giving amounts
  sum(legal_amount) As legal_amount  
From v_af_gifts_srcdnr_5fy af_gifts
  Left Join deg entity_deg On entity_deg.id_number = af_gifts.id_hh_src_dnr
  Left Join deg spouse_deg On spouse_deg.id_number = af_gifts.spouse_id_number
Group By id_hh_src_dnr, pref_name_sort, person_or_org, record_status_code, institutional_suffix, entity_deg.degrees_concat, entity_deg.program,
  entity_deg.program_group, master_state, master_country, gender_code, spouse_id_number, spouse_deg.degrees_concat, ksm_alum_flag,
  -- Giving fields
  allocation_code, alloc_short_name, alloc_purpose_desc, fiscal_year, ytd_ind,
  -- Date fields
  curr_fy, data_as_of
Order By pref_name_sort Asc, fiscal_year Desc, ytd_ind Asc
