With

/* Primary pledge discounted amounts */
plg_discount As (
  Select pledge.pledge_pledge_number As pledge_number, pledge.pledge_sequence, pplg.prim_pledge_type, pplg.prim_pledge_status,
    pledge.pledge_amount, pledge.pledge_associated_credit_amt, pplg.prim_pledge_amount, pplg.prim_pledge_amount_paid,
    pplg.prim_pledge_original_amount, pplg.discounted_amt,
    -- Discounted pledge credit amounts
    Case
      -- Not inactive, not a BE or LE
      When (pplg.prim_pledge_status Is Null Or pplg.prim_pledge_status Not In ('I', 'R'))
        And pplg.prim_pledge_type Not In ('BE', 'LE') Then pledge.pledge_associated_credit_amt
      -- Not inactive, is BE or LE
      When (pplg.prim_pledge_status Is Null Or pplg.prim_pledge_status Not In ('I', 'R'))
        And pplg.prim_pledge_type In ('BE', 'LE') Then pplg.discounted_amt
      -- If inactive, take amount paid
      Else Case
        When pledge.pledge_amount = 0 And pplg.prim_pledge_amount > 0
          Then pplg.prim_pledge_amount_paid * pledge.pledge_associated_credit_amt / pplg.prim_pledge_amount
        When pplg.prim_pledge_amount > 0
          Then pplg.prim_pledge_amount_paid * pledge.pledge_amount / pplg.prim_pledge_amount
        Else pplg.prim_pledge_amount_paid
      End
    End As credit
  From primary_pledge pplg
  Inner Join pledge On pledge.pledge_pledge_number = pplg.prim_pledge_number
  Where pledge.pledge_program_code = 'KM'
    Or pledge_alloc_school = 'KM'
),

/* KSM allocations */
ksm_allocs As (
  Select allocation_code
  From allocation
  Where alloc_school = 'KM'
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
),

/* Kellogg transactions list */
ksm_trans As (
  (
    -- Outright gift
    Select id_number, tx_number, tx_sequence, tms_trans.transaction_type, date_of_record, credit_amount
    From nu_gft_trp_gifttrans gft
    Left Join tms_trans On tms_trans.transaction_type_code = gft.transaction_type
    Where alloc_school = 'KM'
      And tx_gypm_ind = 'G'
    ) Union All (
    -- Matching gift matching company
    Select match_gift_company_id, match_gift_receipt_number, match_gift_matched_sequence, 'Matching Gift', match_gift_date_of_record, match_gift_amount
    From matching_gift
    Inner Join ksm_allocs On ksm_allocs.allocation_code = matching_gift.match_gift_allocation_name
  ) Union All (
    -- Matching gift matched donors; inner join to add all attributed donor ids
    Select gft.id_number, match_gift_receipt_number, match_gift_matched_sequence, 'Matching Gift', match_gift_date_of_record, match_gift_amount
    From matching_gift
    Inner Join (Select id_number, tx_number From nu_gft_trp_gifttrans) gft
      On matching_gift.match_gift_matched_receipt = gft.tx_number
    Inner Join ksm_allocs On ksm_allocs.allocation_code = matching_gift.match_gift_allocation_name
  ) Union All (
    -- Pledges, including BE and LE program credit
    Select pledge_donor_id, pledge_pledge_number, pledge.pledge_sequence, tms_trans.transaction_type, pledge_date_of_record, plgd.credit
    From pledge
    Inner Join tms_trans On tms_trans.transaction_type_code = pledge.pledge_pledge_type
    Left Join plg_discount plgd On plgd.pledge_number = pledge.pledge_pledge_number And plgd.pledge_sequence = pledge.pledge_sequence
    Left Join ksm_allocs On ksm_allocs.allocation_code = pledge.pledge_allocation_name
    Where ksm_allocs.allocation_code Is Not Null
      Or (
        -- KSM program code
        pledge_allocation_name In ('BE', 'LE') -- BE and LE discounted amounts
        And pledge_program_code = 'KM'
      )
  )
)

/*
Select
  entity.report_name,
  ksm_trans.*
From (Select Distinct * From ksm_trans) ksm_trans -- Remove any duplicate matching gifts
Inner Join entity On entity.id_number = ksm_trans.id_number
Where entity.id_number = '0000393892'
*/

--/*
Select
  ksm_trans.id_number,
  entity.report_name,
  sum(ksm_trans.credit_amount) As credit_amount
From (Select Distinct * From ksm_trans) ksm_trans -- Remove any duplicate matching gifts
Inner Join entity On entity.id_number = ksm_trans.id_number
--Where ksm_trans.id_number = '0000271445'
Group By ksm_trans.id_number, entity.report_name
--*/
