--Create Or Replace View af_5fy_gifts As
--With stop_hiding_my_comments As (Select NULL From DUAL),

-- Kellogg Annual Fund allocations as defined in ksm_pkg
ksm_af_allocs As (
  Select COLUMN_VALUE As allocation_code
  From table(ksm_pkg.get_alloc_annual_fund_ksm)
),

-- Calendar date range from current_calendar
cal As (
  Select curr_fy - 5 As prev_fy5, curr_fy
  From current_calendar
),

-- Formatted giving table
ksm_af_gifts As (
  Select ksm_af_allocs.allocation_code, alloc_short_name, tx_number, tx_gypm_ind, fiscal_year, date_of_record, legal_amount, credit_amount, nwu_af_amount,
    id_number, ksm_pkg.get_gift_source_donor_ksm(tx_number) As ksm_src_dnr
  From nu_gft_trp_gifttrans, ksm_af_allocs, cal
  -- Only pull KSM AF gifts in recent fiscal years
  Where nu_gft_trp_gifttrans.allocation_code = ksm_af_allocs.allocation_code
    And fiscal_year Between cal.curr_fy And cal.curr_fy
    -- Drop pledges
    And tx_gypm_ind != 'P'
)

-- Final results
Select
  -- Giving fields
  af.allocation_code, af.alloc_short_name, af.tx_number, af.tx_gypm_ind, af.fiscal_year, af.date_of_record,
  af.legal_amount, af.credit_amount, af.nwu_af_amount,
    -- Source donor flag
  Case When af.ksm_src_dnr = entity.id_number Then 'Y' Else 'N' End As src_donor_flag,
  -- Entity fields
  entity.id_number, entity.pref_name_sort, entity.record_status_code, entity.institutional_suffix,
  -- Source donor fields
  af.ksm_src_dnr, e_src_dnr.pref_name_sort, e_src_dnr.person_or_org, e_src_dnr.record_status_code, e_src_dnr.institutional_suffix,
  advance.ksm_degrees_concat(e_src_dnr.id_number) As src_dnr_degrees_concat,
  advance.master_addr(e_src_dnr.id_number, 'state_code') As master_state,
  advance.master_addr(e_src_dnr.id_number, 'country') As master_country,
  e_src_dnr.gender_code, e_src_dnr.spouse_id_number,
  advance.ksm_degrees_concat(e_src_dnr.spouse_id_number) As spouse_degrees_concat,
  -- KSM alumni flag
  Case When advance.ksm_degrees_concat(entity.id_number) Is Not Null Then 'Y' Else 'N' End As ksm_alum_flag
From ksm_af_gifts af
  Inner Join entity
    On af.id_number = entity.id_number
  Inner Join entity e_src_dnr
    On af.ksm_src_dnr = e_src_dnr.id_number
Where legal_amount > 0
Order By date_of_record Asc, tx_number Asc, legal_amount Desc
