With

/* KSM allocations */
ksm_alloc As (
  Select allocation_code
  From allocation
  Where alloc_school = 'KM'
),

/* Primary pledge discounted amounts */
plg_discount As (
  Select pplg.prim_pledge_number As pledge_number, pplg.prim_pledge_type, pplg.prim_pledge_status,
    pplg.prim_pledge_amount, pplg.prim_pledge_amount_paid, pplg.prim_pledge_original_amount, pplg.discounted_amt,
    -- Discounted pledge credit amounts
    Case
      -- Not inactive, not a BE or LE
      When pplg.prim_pledge_status Not In ('I', 'R') And pplg.prim_pledge_type Not In ('BE', 'LE') Then pplg.prim_pledge_amount
      -- Not inactive, is BE or LE
      When pplg.prim_pledge_status Not In ('I', 'R') And pplg.prim_pledge_type In ('BE', 'LE') Then pplg.discounted_amt
      -- If inactive, take % of amount paid
      Else pplg.prim_pledge_amount * (pplg.prim_pledge_amount_paid / pplg.prim_pledge_original_amount)
    End As credit
  From primary_pledge pplg
  Inner Join pledge On pledge.pledge_pledge_number = pplg.prim_pledge_number
  Inner Join ksm_alloc On ksm_alloc.allocation_code = pledge.pledge_allocation_name
  Where pledge.pledge_allocation_name In ksm_alloc.allocation_code
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

ksm_trans As (
  (
    -- Outright gift and matches
    Select id_number, tx_number, tms_trans.transaction_type, date_of_record, credit_amount
    From nu_gft_trp_gifttrans gft
    Left Join tms_trans On tms_trans.transaction_type_code = gft.transaction_type
    Where alloc_school = 'KM'
      And tx_gypm_ind Not In ('Y', 'P') -- No pledges or pledge payments
  ) Union All (
    -- Pledges and pledge payments, including BE and LE program credit
    Select pledge_donor_id, pledge_pledge_number, tms_trans.transaction_type, pledge_date_of_record, credit
    From pledge
    Inner Join tms_trans On tms_trans.transaction_type_code = pledge.pledge_pledge_type
    Left Join plg_discount plgd On plgd.pledge_number = pledge.pledge_pledge_number
    Left Join ksm_alloc On ksm_alloc.allocation_code = pledge.pledge_allocation_name
    Where (
      -- KSM allocations
      pledge_allocation_name In ksm_alloc.allocation_code
    ) Or (
      -- KSM program code
      pledge_allocation_name In ('BE', 'LE') -- BE and LE discounted amounts
      And pledge_program_code = 'KM'
    )
  )
)

Select
  id_number,
  sum(credit_amount) As credit_amount
From ksm_trans
Group By id_number
