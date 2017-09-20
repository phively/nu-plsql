Create Or Replace View v_ksm_giving_lifetime As

Select ksm.id_number, entity.report_name,
  ksm.ngc_lifetime As credit_amount,
  ksm.ngc_lifetime_beq_fv As credit_amount_full_BE
From rpt_pbh634.v_ksm_giving_summary ksm
Inner Join entity On entity.id_number = ksm.id_number
