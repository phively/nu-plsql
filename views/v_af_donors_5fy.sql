Create Or Replace View v_af_donors_5fy As

/* Requires the gift data aggregated in v_af_donors_gifts_5fy. Aggregated by household giving source donor and related fields,
   fiscal year, allocation, and whether the gift was made year-to-date or not. */

-- Final results aggregated by entity and year
Select
  -- Entity fields
  ksm_household_src_dnr, pref_name_sort, person_or_org, record_status_code, institutional_suffix, src_dnr_degrees_concat, src_dnr_program,
  src_dnr_program_group, master_state, master_country, gender_code, spouse_id_number, spouse_degrees_concat, ksm_alum_flag,
  -- Giving fields
  alloc_short_name, fiscal_year, ytd_ind,
  -- Date fields
  curr_fy, data_as_of,
  -- Aggregated giving amounts
  sum(legal_amount) As legal_amount  
From v_af_donors_gifts_5fy
Group By ksm_household_src_dnr, pref_name_sort, person_or_org, record_status_code, institutional_suffix, src_dnr_degrees_concat, src_dnr_program,
  src_dnr_program_group, master_state, master_country, gender_code, spouse_id_number, spouse_degrees_concat, ksm_alum_flag,
  -- Giving fields
  alloc_short_name, fiscal_year, ytd_ind,
  -- Date fields
  curr_fy, data_as_of
Order By pref_name_sort Asc, fiscal_year Desc, ytd_ind Asc
