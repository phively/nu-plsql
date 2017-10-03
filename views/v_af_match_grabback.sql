Create Or Replace View v_af_match_grabback As

-- Gift to KSM, match outside KSM
Select gft.tx_number, gft.tx_sequence, gft.alloc_school, gft.allocation_code, allocg.short_name As allocation,
  match_gift_matched_donor_id, entity.report_name, ksm_alum.degrees_concat,
  match_gift_receipt_number, match_gift_matched_sequence,
  allocm.allocation_code As match_allocation_code, allocm.short_name As match_allocation,
  match_gift_date_of_record, ksm_pkg.get_fiscal_year(match_gift_date_of_record) As fiscal_year_of_match, match_gift_amount
From matching_gift
Inner Join nu_gft_trp_gifttrans gft On gft.tx_number = matching_gift.match_gift_matched_receipt
  And gft.tx_sequence = matching_gift.match_gift_matched_sequence
Inner Join entity On entity.id_number = matching_gift.match_gift_matched_donor_id
Left Join table(rpt_pbh634.ksm_pkg.tbl_entity_degrees_concat_ksm) ksm_alum On ksm_alum.id_number = matching_gift.match_gift_matched_donor_id
Left Join allocation allocg On allocg.allocation_code = gft.allocation_code
Left Join allocation allocm On allocm.allocation_code = matching_gift.match_gift_allocation_name
Where match_gift_program_credit_code <> 'KM'
  And gft.alloc_school = 'KM'
Order By match_gift_date_of_record Desc
