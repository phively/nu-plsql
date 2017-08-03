With
/* Implementation of KSM householdable giving transactions */

/* Household IDs */
hhid As (
  Select id_number, household_id
  From table(ksm_pkg.tbl_entity_households_ksm)
),

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
ksm_af_allocs As (
  Select allocation_code, af_flag
  From table(ksm_pkg.tbl_alloc_annual_fund_ksm) af
),
ksm_allocs As (
  Select allocation.allocation_code, allocation.short_name, ksm_af_allocs.af_flag
  From allocation
  Left Join ksm_af_allocs On ksm_af_allocs.allocation_code = allocation.allocation_code
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
    -- Outright gifts and payments
    Select gft.id_number, hhid.household_id,
      tx_number, tx_sequence, tms_trans.transaction_type, tx_gypm_ind,
      gft.allocation_code, gft.alloc_short_name, af_flag,
      NULL As pledge_status, date_of_record, credit_amount,
      Case When gft.id_number = household_id Then credit_amount Else 0 End As hh_credit
    From nu_gft_trp_gifttrans gft
    Inner Join hhid On hhid.id_number = gft.id_number
    Left Join tms_trans On tms_trans.transaction_type_code = gft.transaction_type
    Left Join ksm_af_allocs On ksm_af_allocs.allocation_code = gft.allocation_code
    Where alloc_school = 'KM'
      And tx_gypm_ind In ('G', 'Y')
  ) Union All (
    -- Matching gift matching company
    Select match_gift_company_id, hhid.household_id,
      match_gift_receipt_number, match_gift_matched_sequence, 'Matching Gift', 'M',
      match_gift_allocation_name, ksm_allocs.short_name, af_flag,
      NULL, match_gift_date_of_record, match_gift_amount,
      Case When id_number = household_id Then match_gift_amount Else 0 End As hh_credit
    From matching_gift
    Inner Join hhid On hhid.id_number = matching_gift.match_gift_company_id
    Inner Join ksm_allocs On ksm_allocs.allocation_code = matching_gift.match_gift_allocation_name
  ) Union All (
    -- Matching gift matched donors; inner join to add all attributed donor ids
    Select gft.id_number, hhid.household_id,
      match_gift_receipt_number, match_gift_matched_sequence, 'Matching Gift', 'M',
      match_gift_allocation_name, ksm_allocs.short_name, af_flag,
      NULL, match_gift_date_of_record, match_gift_amount,
      Case When gft.id_number = household_id Then match_gift_amount Else 0 End As hh_credit
    From matching_gift
    Inner Join (Select id_number, tx_number From nu_gft_trp_gifttrans) gft
      On matching_gift.match_gift_matched_receipt = gft.tx_number
    Inner Join hhid On hhid.id_number = gft.id_number
    Inner Join ksm_allocs On ksm_allocs.allocation_code = matching_gift.match_gift_allocation_name
  ) Union All (
    -- Pledges, including BE and LE program credit
    Select pledge_donor_id, hhid.household_id,
      pledge_pledge_number, pledge.pledge_sequence, tms_trans.transaction_type, 'P',
      pledge.pledge_allocation_name, ksm_allocs.short_name, ksm_allocs.af_flag,
      prim_pledge_status, pledge_date_of_record, plgd.credit,
      Case When pledge_donor_id = household_id Then plgd.credit Else 0 End As hh_credit
    From pledge
    Inner Join hhid On hhid.id_number = pledge.pledge_donor_id
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

Select *
From ksm_trans
