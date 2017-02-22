Create Or Replace View v_af_donors_5fy_summary As

/* Requires the gift data aggregated in v_af_donors_gifts_5fy. Aggregated by household giving source donor and related fields, with
   each of the recent fiscal years its own column. */ 

-- Aggregated by entity and fiscal year
Select
  -- Entity fields
  ksm_household_src_dnr, pref_name_sort, person_or_org, record_status_code, institutional_suffix, src_dnr_degrees_concat, src_dnr_program,
  src_dnr_program_group, master_state, master_country, gender_code, spouse_id_number, spouse_degrees_concat, ksm_alum_flag,
  -- Date fields
  curr_fy, data_as_of,
  -- Aggregated giving amounts
  sum(Case When fiscal_year = (curr_fy - 0) Then legal_amount Else 0 End) As ksm_af_curr_fy,
  sum(Case When fiscal_year = (curr_fy - 1) Then legal_amount Else 0 End) As ksm_af_prev_fy1,
  sum(Case When fiscal_year = (curr_fy - 2) Then legal_amount Else 0 End) As ksm_af_prev_fy2,
  sum(Case When fiscal_year = (curr_fy - 3) Then legal_amount Else 0 End) As ksm_af_prev_fy3,
  sum(Case When fiscal_year = (curr_fy - 4) Then legal_amount Else 0 End) As ksm_af_prev_fy4,
  sum(Case When fiscal_year = (curr_fy - 5) Then legal_amount Else 0 End) As ksm_af_prev_fy5
From v_af_donors_gifts_5fy
Group By ksm_household_src_dnr, pref_name_sort, person_or_org, record_status_code, institutional_suffix, src_dnr_degrees_concat, src_dnr_program,
  src_dnr_program_group, master_state, master_country, gender_code, spouse_id_number, spouse_degrees_concat, ksm_alum_flag,
  -- Date fields
  curr_fy, data_as_of
Order By pref_name_sort Asc
