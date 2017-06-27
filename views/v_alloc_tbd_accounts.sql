Create Or Replace View v_alloc_tbd_accounts As

With

/* All Kellogg TBD accounts */
ksm_tbd As (
  Select *
  From allocation alloc
  Where lower(alloc.short_name) Like '%kellogg%tbd%'
),

/* KSM degrees concat definition */
deg As (
  Select *
  From table(rpt_pbh634.ksm_pkg.tbl_entity_degrees_concat_ksm)
),

/* Transaction and pledge TMS table definition */
tms_trans As (
  (
    Select transaction_type_code, short_desc As transaction_type
    From tms_transaction_type
  ) Union All (
    Select pledge_type_code, short_desc
    From tms_pledge_type
  )
)

/* Main query */
Select
  gft.id_number, donor_name, record_type_code, deg.degrees_concat, trim(deg.program_group) As program_group,
  tx_number, tx_sequence, date_of_record, fiscal_year, legal_amount, credit_amount, gft.tx_gypm_ind, tms_trans.transaction_type,
  gft.allocation_code, gft.alloc_short_name
From nu_gft_trp_gifttrans gft
Inner Join ksm_tbd On gft.allocation_code = ksm_tbd.allocation_code
Left Join deg On deg.id_number = gft.id_number
Left Join tms_trans On tms_trans.transaction_type_code = gft.transaction_type
Order By date_of_record Desc, credit_amount Desc, tx_sequence Asc
;
