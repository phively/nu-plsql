-- Allocations tagged as Kellogg Annual Fund
With ksm_af_allocs As (
  Select Distinct allocation_code, short_name
  From advance.allocation
  Where annual_sw = 'Y'
    And alloc_school = 'KM'
),
-- Formatted giving table
ksm_af_gifts As (
  Select allocs.allocation_code, short_name, tx_number, id_number, tx_gypm_ind, fiscal_year, date_of_record, legal_amount, credit_amount, nwu_af_amount,
    -- Construct custom gift size bins column
    Case
      When credit_amount >= 100000 Then 'A: 100K+'
      When credit_amount >= 50000 Then 'B: 50K+'
      When credit_amount >= 25000 Then 'C: 25K+'
      When credit_amount >= 20000 Then 'D: 20K+'
      When credit_amount >= 10000 Then 'E: 10K+'
      When credit_amount >= 5000 Then 'F: 5K+'
      When credit_amount >= 2500 Then 'G: 2.5K+'
      When credit_amount >= 1000 Then 'H: 1K+'
      When credit_amount >= 500 Then 'I: 500+'
      When credit_amount >= 250 Then 'J: 250+'
      When credit_amount > 0 Then 'K: <250'
      Else 'L: Credit Only'
    End As ksm_af_bin
  From ksm_af_allocs allocs,
       nu_gft_trp_gifttrans
    -- Only pull recent fiscal years
  Where nu_gft_trp_gifttrans.allocation_code = allocs.allocation_code
    And fiscal_year Between 2012 And 2016
    -- Drop pledges
    And tx_gypm_ind != 'P'
)
-- Select final fields
Select af.allocation_code, af.short_name, af.tx_number, af.tx_gypm_ind, af.fiscal_year, af.date_of_record, af.legal_amount, af.credit_amount, af.nwu_af_amount, af.ksm_af_bin,
       srcdnr.id_number, entity.pref_name_sort, entity.person_or_org, entity.record_status_code, entity.institutional_suffix,
       advance.ksm_degrees_concat(entity.id_number) As degrees_concat,
       advance.master_addr(entity.id_number, 'state_code') As master_state,
       advance.master_addr(entity.id_number, 'country') As master_country,
       entity.gender_code, entity.spouse_id_number,
       advance.ksm_degrees_concat(entity.spouse_id_number) As spouse_degrees_concat,
       -- KSM alumni flag
       Case
         When advance.ksm_degrees_concat(entity.id_number) Is Not Null Then 'Y'
         Else 'N'
       End As ksm_alum_flag
From ksm_af_gifts af,
     nu_gft_trp_giving_source_donor srcdnr
  Inner Join entity
    On srcdnr.id_number = entity.id_number
Where srcdnr.trans_id_number = af.tx_number
  And legal_amount > 0
Order By date_of_record Asc, tx_number Asc, legal_amount Desc