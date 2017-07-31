With

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

/* KSM allocations */
ksm_allocs As (
  Select allocation_code
  From allocation
  Where alloc_school = 'KM'
),

/* Pledge numbers of interest */
ksm_pledges As (
  Select Distinct pledge.pledge_pledge_number
  From pledge
  Inner Join primary_pledge On primary_pledge.prim_pledge_number = pledge.pledge_pledge_number
  Left Join ksm_allocs On ksm_allocs.allocation_code = pledge.pledge_allocation_name
  Where primary_pledge.prim_pledge_status = 'A'
    And (
      ksm_allocs.allocation_code Is Not Null
      Or (
      -- KSM program code
        pledge_allocation_name In ('BE', 'LE') -- BE and LE discounted amounts
        And pledge_program_code = 'KM'
      )
    )
),
pledge_allocs As (
  Select pledge.pledge_pledge_number, count(pledge.pledge_allocation_name) As allocs_count
  From pledge
  Inner Join ksm_pledges On ksm_pledges.pledge_pledge_number = pledge.pledge_pledge_number
  Where pledge.pledge_amount > 0
  Group By pledge.pledge_pledge_number
),

/* Pledge payments */
ksm_payments As (
  Select gft.tx_number, gft.tx_sequence, gft.pmt_on_pledge_number, gft.allocation_code, gft.date_of_record, gft.legal_amount
  From nu_gft_trp_gifttrans gft
  Inner Join ksm_allocs On ksm_allocs.allocation_code = gft.allocation_code
  Inner Join ksm_pledges On ksm_pledges.pledge_pledge_number = gft.pmt_on_pledge_number
  Where gft.legal_amount > 0
  Order By pmt_on_pledge_number Asc, date_of_record Desc
),
ksm_paid_amt As (
  Select pmt_on_pledge_number, allocation_code, sum(legal_amount) As total_paid
  From ksm_payments
  Group By pmt_on_pledge_number, allocation_code
),
recent_payments As (
  Select pmt_on_pledge_number,
    min(tx_number) keep(dense_rank First Order By pmt_on_pledge_number Asc, date_of_record Desc, tx_number Desc) As recent_pmt_nbr_plg,
    max(date_of_record) keep(dense_rank First Order By pmt_on_pledge_number Asc, date_of_record Desc, tx_number Desc) As date_of_record_plg,
    sum(legal_amount) keep(dense_rank First Order By pmt_on_pledge_number Asc, date_of_record Desc, tx_number Desc) As pmt_amount_plg
  From ksm_payments
  Group By pmt_on_pledge_number
  Order By pmt_on_pledge_number Asc
),
recent_payments_alloc As (
  Select pmt_on_pledge_number, allocation_code,
    min(tx_number) Keep (dense_rank First Order By pmt_on_pledge_number Asc, date_of_record Desc, tx_number Desc) As recent_pmt_nbr_alloc,
    max(date_of_record) Keep (dense_rank First Order By pmt_on_pledge_number Asc, date_of_record Desc, tx_number Desc) As date_of_record_alloc,
    sum(legal_amount) Keep (dense_rank First Order By pmt_on_pledge_number Asc, date_of_record Desc, tx_number Desc) As pmt_amount_alloc
  From ksm_payments
  Group By pmt_on_pledge_number, allocation_code
  Order By pmt_on_pledge_number Asc
),

/* Pledge reminder entity notes */
reminders As (
  Select id_number, note_id, note_date, description, brief_note, date_added
  From notes
  Cross Join v_current_calendar cal
  Where note_type = 'GP'
    And trunc(note_date) Between cal.curr_fy_start And cal.next_fy_start
    And lower(description) Like '%pledge reminder%'
),
recent_reminders As (
  Select reminders.id_number,
    min(note_id) Keep (dense_rank First Order By reminders.id_number Asc, note_date Desc, note_id Desc) As note_id,
    max(note_date) Keep (dense_rank First Order By reminders.id_number Asc, note_date Desc, note_id Desc) As note_date,
    min(description) Keep (dense_rank First Order By reminders.id_number Asc, note_date Desc, note_id Desc) As note_desc,
    min(brief_note) Keep (dense_rank First Order By reminders.id_number Asc, note_date Desc, note_id Desc) As brief_note,
    max(date_added) Keep (dense_rank First Order By reminders.id_number Asc, note_date Desc, note_id Desc) As date_added
  From reminders
  Group By reminders.id_number
)

/* Main query */

Select
  -- Donor fields
  pledge.pledge_donor_id As legal_donor_id,
  -- Pledge fields
  pledge.pledge_pledge_number As pledge_number,
  pp.prim_pledge_date_of_record As date_of_record,
  pp.prim_pledge_year_of_giving As fiscal_year,
  tms_trans.transaction_type,
  -- Allocation fields
  pledge_allocation_name As allocation_code,
  allocation.short_name As allocation_name,
  -- Amount fields
  pledge.pledge_amount,
  ksm_paid_amt.total_paid,
  pledge.pledge_amount - nvl(ksm_paid_amt.total_paid, 0) As alloc_pledge_balance,
  Case When pledge_allocs.allocs_count > 1 Then pledge_allocs.allocs_count End As split_gift_allocs,
  pp.prim_pledge_amount,
  pp.prim_pledge_amount_paid,
  pp.prim_pledge_amount - nvl(pp.prim_pledge_amount_paid, 0) As prim_pledge_balance,
  -- Recent payment fields
  pmts.recent_pmt_nbr_plg,
  pmts.date_of_record_plg,
  pmts.pmt_amount_plg,
  pmtsa.recent_pmt_nbr_alloc,
  pmtsa.date_of_record_alloc,
  pmtsa.pmt_amount_alloc,
  -- Pledge reminders
  remind.note_id As most_recent_note_id,
  remind.note_date,
  remind.note_desc,
  remind.brief_note,
  remind.date_added
-- Pledge tables
From pledge
Inner Join primary_pledge pp On pp.prim_pledge_number = pledge.pledge_pledge_number
-- Descriptions from codes
Inner Join tms_trans On tms_trans.transaction_type_code = pp.prim_pledge_type
Inner Join allocation On allocation.allocation_code = pledge.pledge_allocation_name
-- Only active KSM pledges
Inner Join ksm_pledges On ksm_pledges.pledge_pledge_number = pledge.pledge_pledge_number
-- Only Kellogg portion of split pledges
Inner Join ksm_allocs On ksm_allocs.allocation_code = pledge.pledge_allocation_name
-- Split gift allocations count
Inner Join pledge_allocs On pledge_allocs.pledge_pledge_number = pledge.pledge_pledge_number
-- Paid amounts toward Kellogg allocations
Left Join ksm_paid_amt On ksm_paid_amt.pmt_on_pledge_number = pledge.pledge_pledge_number
  And ksm_paid_amt.allocation_code = pledge.pledge_allocation_name
-- Most recent payment info
Left Join recent_payments pmts On pmts.pmt_on_pledge_number = pledge.pledge_pledge_number
Left Join recent_payments_alloc pmtsa On pmtsa.pmt_on_pledge_number = pledge.pledge_pledge_number
  And pmtsa.allocation_code = pledge.pledge_allocation_name
-- Any recent GRS reminders sent?
Left Join recent_reminders remind On remind.id_number = pledge.pledge_donor_id
-- Conditions
Where pledge_amount > 0
  -- Only unfulfilled commitments
  And (pledge.pledge_amount > ksm_paid_amt.total_paid Or ksm_paid_amt.total_paid Is Null)
Order By pledge.pledge_pledge_number Asc, pp.prim_pledge_date_of_record Desc, pledge.pledge_donor_id Asc, pledge.pledge_allocation_name Asc
