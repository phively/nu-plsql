With

-- Kellogg Annual Fund allocations as defined in ksm_pkg
ksm_allocs As (
  Select allocation_code
  From allocation
  Where alloc_school = 'KM'
),

-- Calendar date range from current_calendar
cal As (
  Select curr_fy - 1 As prev_fy, curr_fy, yesterday
  From v_current_calendar
),

-- KSM householding
households As (
  Select id_number, pref_mail_name, spouse_id_number, spouse_pref_mail_name, household_id, household_ksm_year, household_program_group
  From table(ksm_pkg.tbl_entity_households_ksm)
)

Select ksm_allocs.allocation_code,
  gft.alloc_short_name, gft.alloc_purpose_desc, gft.tx_number, gft.tx_sequence, gft.tx_gypm_ind,
  gft.fiscal_year, gft.date_of_record,
  gft.legal_amount, gft.credit_amount, gft.nwu_af_amount,
  gft.id_number As legal_dnr_id,
  ksm_pkg.get_gift_source_donor_ksm(tx_number) As id_src_dnr,
  households.household_id As id_hh_src_dnr,
  cal.curr_fy, cal.yesterday
From cal, nu_gft_trp_gifttrans gft
  Inner Join ksm_allocs
    On ksm_allocs.allocation_code = gft.allocation_code
  Inner Join households On households.id_number = ksm_pkg.get_gift_source_donor_ksm(tx_number)
-- Only pull KSM AF gifts in recent fiscal years
Where gft.allocation_code = ksm_allocs.allocation_code
  And fiscal_year Between cal.prev_fy And cal.curr_fy
  -- Drop pledges
  And tx_gypm_ind != 'P'
  And legal_amount <= 100000
