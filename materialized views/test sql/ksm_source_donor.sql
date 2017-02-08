/*
Strategy -- look at gifts with multiple donors, i.e. max(tx_sequence) > 1
In general for gift crediting and prospecting we'd want to prioritize KSM alumni
over other NU alumni, and NU alumni over nonalumni.
*/

-- Highest sequence number per receipt, and FY/school criteria for main query
With seqs As (
  Select Distinct tx_number, max(tx_sequence) As max_seq, fiscal_year, alloc_school
  From nu_gft_trp_gifttrans
  Where alloc_school = 'KM'
    And fiscal_year = 2016
  Group By tx_number, fiscal_year, alloc_school
)
-- Main query
Select
  -- Basic entity fields
  gift.id_number, advance.ksm_degrees_concat(gift.id_number) As ksm_degrees, gift.donor_name, gift.person_or_org, gift.record_type_code,
  -- Matching gift fields
  gift.matched_donor_id, advance.ksm_degrees_concat(gift.matched_donor_id) As matched_ksm_degrees,
  -- KSM source donor
  Case When gift.id_number = advance.ksm_source_donor(gift.tx_number) Then 'Y' Else 'N' End As bool_id_is_ksm_source,
  advance.ksm_source_donor(gift.tx_number) As ksm_source_donor,
  -- Source donor
  -- Check if source donor ID is same as current entity ID
  Case When gift.id_number = srcdnr.id_number Then 'Y' Else 'N' End As bool_id_is_source,
  srcdnr.id_number As source_donor_id, advance.ksm_degrees_concat(srcdnr.id_number) As source_ksm_degrees,
  -- Gift fields
  gift.tx_number, gift.tx_sequence, seqs.max_seq, gift.tx_gypm_ind, gift.pmt_on_pledge_number, gift.date_of_record, gift.fiscal_year,
  gift.legal_amount, gift.credit_amount, gift.annual_sw, gift.alloc_short_name, gift.alloc_account, gift.alloc_school, gift.matched_receipt_nbr,
  gift.matched_seq_nbr
From  seqs
  Inner Join nu_gft_trp_gifttrans gift
    On seqs.tx_number = gift.tx_number
  Left Join nu_gft_trp_giving_source_donor srcdnr
    On gift.tx_number = srcdnr.trans_id_number
Where gift.alloc_school = seqs.alloc_school
  And gift.fiscal_year = seqs.fiscal_year
Order By tx_number Asc, tx_sequence Asc
