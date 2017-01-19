-- Allocations tagged as Kellogg Annual Fund
With ksm_af_allocs As (
  Select Distinct allocation_code,
    allocation.short_name
  From advance.allocation
  Where annual_sw = 'Y'
    And alloc_school = 'KM'
),
-- Formatted giving table
ksm_af_gifts As (
  Select ksm_af_allocs.allocation_code, short_name, tx_number, fiscal_year, date_of_record, legal_amount, nwu_af_amount,
    -- Construct custom gift size bins column
    Case
      When nwu_af_amount >= 100000 Then 'A: 100K+'
      When nwu_af_amount >= 50000 Then 'B: 50K+'
      When nwu_af_amount >= 25000 Then 'C: 25K+'
      When nwu_af_amount >= 20000 Then 'D: 20K+'
      When nwu_af_amount >= 10000 Then 'E: 10K+'
      When nwu_af_amount >= 5000 Then 'F: 5K+'
      When nwu_af_amount >= 2500 Then 'G: 2.5K+'
      When nwu_af_amount >= 1000 Then 'H: 1K+'
      When nwu_af_amount >= 500 Then 'I: 500+'
      When nwu_af_amount >= 250 Then 'J: 250+'
      When nwu_af_amount > 0 Then 'K: <250'
      Else 'L: Credit Only'
    End As nwu_af_bin,
    id_number
  From ksm_af_allocs, nu_gft_trp_gifttrans
    -- Only pull recent fiscal years
  Where nu_gft_trp_gifttrans.allocation_code = ksm_af_allocs.allocation_code
    And fiscal_year Between 2016 And 2016
    -- Drop pledges
    And tx_gypm_ind != 'P'
)
-- Select final fields
Select allocation_code, short_name, tx_number, fiscal_year, date_of_record, legal_amount, nwu_af_amount, nwu_af_bin,
  ksm_af_gifts.id_number, pref_name_sort, person_or_org, record_status_code, institutional_suffix,
  advance.ksm_degrees_concat(ksm_af_gifts.id_number) As degrees_concat,
  gender_code, spouse_id_number, advance.ksm_degrees_concat(spouse_id_number) As spouse_degrees_concat,
  Case
    When advance.ksm_degrees_concat(ksm_af_gifts.id_number) Is Not Null Then 'Y'
    Else 'N'
  End As ksm_alum_flag
From ksm_af_gifts, entity
Where ksm_af_gifts.id_number = entity.id_number
Order By date_of_record Asc, tx_number Asc, legal_amount Desc;
