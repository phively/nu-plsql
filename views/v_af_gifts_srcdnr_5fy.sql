Create Or Replace View v_af_gifts_srcdnr_5fy As
With

/* Core Annual Fund transaction-level view; current and previous 5 fiscal years. Rolls data up to the household giving source donor
   level, e.g. Kellogg-specific giving source donor, then householded for married entities. */

-- Kellogg Annual Fund allocations as defined in ksm_pkg
ksm_af_allocs As (
  Select allocation_code
  From table(ksm_pkg.tbl_alloc_annual_fund_ksm)
),
ksm_cru_allocs As (
  Select allocation_code, af_flag
  From table(ksm_pkg.tbl_alloc_curr_use_ksm)
),

-- Calendar date range from current_calendar
cal As (
  Select curr_fy - 7 As prev_fy, curr_fy, yesterday
  From v_current_calendar
),

-- KSM householding
households As (
  Select id_number, pref_mail_name, spouse_id_number, spouse_pref_mail_name, household_id, household_ksm_year, household_program_group
  From table(ksm_pkg.tbl_entity_households_ksm)
),

-- Formatted giving table
ksm_cru_gifts As (
  Select ksm_cru_allocs.allocation_code, ksm_cru_allocs.af_flag,
    gft.alloc_short_name, gft.alloc_purpose_desc, gft.tx_number, gft.tx_sequence, gft.tx_gypm_ind,
    gft.fiscal_year, gft.date_of_record,
    gft.legal_amount, gft.credit_amount, gft.nwu_af_amount,
    gft.id_number As legal_dnr_id,
    ksm_pkg.get_gift_source_donor_ksm(tx_number) As id_src_dnr,
    households.household_id As id_hh_src_dnr,
    cal.curr_fy, cal.yesterday
  From cal, nu_gft_trp_gifttrans gft
    Inner Join ksm_cru_allocs
      On ksm_cru_allocs.allocation_code = gft.allocation_code
    Inner Join households On households.id_number = ksm_pkg.get_gift_source_donor_ksm(tx_number)
  Where 
    -- Drop pledges
    tx_gypm_ind != 'P'
    And (
      -- Only pull KSM current use gifts in recent fiscal years
      (gft.allocation_code = ksm_cru_allocs.allocation_code
        And fiscal_year Between cal.prev_fy And cal.curr_fy)
    )
)

-- Gift receipts and biographic information
Select
  -- Giving fields
  af.allocation_code, af.af_flag, af.alloc_short_name, af.alloc_purpose_desc, af.tx_number, af.tx_sequence, af.tx_gypm_ind, af.fiscal_year,
  af.date_of_record,
  ksm_pkg.fytd_indicator(af.date_of_record) As ytd_ind, -- year to date flag
  af.legal_dnr_id, af.legal_amount, af.credit_amount, af.nwu_af_amount,
  -- Household source donor entity fields
  af.id_hh_src_dnr, hh.pref_mail_name, e_src_dnr.pref_name_sort, e_src_dnr.report_name, e_src_dnr.person_or_org, e_src_dnr.record_status_code,
  e_src_dnr.institutional_suffix,
--  ksm_pkg.get_entity_address(e_src_dnr.id_number, 'state_code') As master_state,
--  ksm_pkg.get_entity_address(e_src_dnr.id_number, 'country') As master_country,
  e_src_dnr.gender_code, hh.spouse_id_number, hh.spouse_pref_mail_name,
  -- KSM alumni flag
  Case When hh.household_program_group Is Not Null Then 'Y' Else 'N' End As ksm_alum_flag,
  -- Fiscal year number
  curr_fy, yesterday As data_as_of
From ksm_cru_gifts af
Inner Join entity e_src_dnr On af.id_hh_src_dnr = e_src_dnr.id_number
Inner Join households hh On hh.id_number = af.id_hh_src_dnr
Where legal_amount > 0
