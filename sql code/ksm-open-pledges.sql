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
ksm_af_allocs As (
  Select allocation_code, af_flag
  From table(ksm_pkg.tbl_alloc_annual_fund_ksm)
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
pledge_counts As (
  Select pledge.pledge_pledge_number,
    count(Distinct pledge.pledge_allocation_name) As allocs_count,
    count(Distinct pledge.pledge_donor_id) - 1 As attr_donors_count -- Subtract 1 for the legal donor
  From pledge
  Inner Join ksm_pledges On ksm_pledges.pledge_pledge_number = pledge.pledge_pledge_number
  Group By pledge.pledge_pledge_number
),

/* Associated donors */
plg_assoc_dnrs As (
  Select pledge.pledge_pledge_number, pledge.pledge_donor_id, entity.institutional_suffix
  From pledge
  Inner Join ksm_pledges On ksm_pledges.pledge_pledge_number = pledge.pledge_pledge_number
  Inner Join entity On entity.id_number = pledge.pledge_donor_id
),
inst_suffixes As (
  Select pledge_pledge_number,
    listagg(institutional_suffix, '; ') Within Group (Order By pledge_donor_id) As inst_suffixes
  From plg_assoc_dnrs
  Group By pledge_pledge_number
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
    min(tx_number) keep(dense_rank First Order By pmt_on_pledge_number Asc, date_of_record Desc, tx_number Desc) As recent_pmt_nbr_prim_plg,
    max(date_of_record) keep(dense_rank First Order By pmt_on_pledge_number Asc, date_of_record Desc, tx_number Desc) As date_of_record_prim_plg,
    sum(legal_amount) keep(dense_rank First Order By pmt_on_pledge_number Asc, date_of_record Desc, tx_number Desc) As pmt_amount_prim_plg
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

/* Pledge payment schedules */
pay_sch As (
  Select ksm_pledges.pledge_pledge_number, psched.payment_schedule_status, psched.payment_schedule_date,
    Case When payment_schedule_date Not Like '0000%' And payment_schedule_date Not Like '____00%'
      Then ksm_pkg.get_fiscal_year(to_date(psched.payment_schedule_date, 'YYYYMMDD'))
    End As payment_schedule_fiscal_year,
    psched.payment_schedule_amount, psched.payment_schedule_balance
  From payment_schedule psched
  Inner Join ksm_pledges On ksm_pledges.pledge_pledge_number = psched.payment_schedule_pledge_nbr
),
pay_last As (
  Select pledge_pledge_number,
    min(payment_schedule_date) Keep (dense_rank First Order By payment_schedule_date Desc, payment_schedule_balance Desc) As last_sched_date_paid,
    min(payment_schedule_fiscal_year) Keep (dense_rank First Order By payment_schedule_date Desc, payment_schedule_balance Desc) As last_sched_year_paid,
    min(payment_schedule_amount) Keep (dense_rank First Order By payment_schedule_date Desc, payment_schedule_balance Desc) As last_sched_amount,
    min(payment_schedule_balance) Keep (dense_rank First Order By payment_schedule_date Desc, payment_schedule_balance Desc) As last_sched_balance
  From pay_sch
  Where payment_schedule_status = 'P'
  Group By pledge_pledge_number
),
pay_next As (
  Select pledge_pledge_number,
    min(payment_schedule_date) Keep (dense_rank First Order By payment_schedule_date Asc, payment_schedule_balance Desc) As next_sched_date,
    min(payment_schedule_fiscal_year) Keep (dense_rank First Order By payment_schedule_date Asc, payment_schedule_balance Desc) As next_sched_year,
    min(payment_schedule_amount) Keep (dense_rank First Order By payment_schedule_date Asc, payment_schedule_balance Desc) As next_sched_amount,
    min(payment_schedule_balance) Keep (dense_rank First Order By payment_schedule_date Asc, payment_schedule_balance Desc) As next_sched_balance
  From pay_sch
  Where payment_schedule_status = 'U'
  Group By pledge_pledge_number
),

/* Pledge reminder entity notes */
reminders As (
  Select id_number, note_id, note_date, description, brief_note, date_added
  From notes
  Cross Join v_current_calendar cal
  Where note_type In ('GP', 'GS')
    And trunc(note_date) Between cal.curr_fy_start And cal.next_fy_start
    And lower(description) Like '%pledge reminder%'
),
recent_reminders As (
  Select id_number,
    min(note_id) Keep (dense_rank First Order By id_number Asc, note_date Desc, note_id Desc) As note_id,
    max(note_date) Keep (dense_rank First Order By id_number Asc, note_date Desc, note_id Desc) As note_date,
    min(description) Keep (dense_rank First Order By id_number Asc, note_date Desc, note_id Desc) As note_desc,
    min(brief_note) Keep (dense_rank First Order By id_number Asc, note_date Desc, note_id Desc) As brief_note,
    max(date_added) Keep (dense_rank First Order By id_number Asc, note_date Desc, note_id Desc) As date_added
  From reminders
  Group By id_number
),
ksm_reminders As (
  Select id_number, note_id, note_date, description, brief_note, date_added
  From notes
  Cross Join v_current_calendar cal
  Where data_source_code = 'KSM'
    And trunc(note_date) Between cal.curr_fy_start And cal.next_fy_start
    And lower(description) Like '%pledge reminder%'
),
recent_ksm_reminders As (
  Select id_number,
    min(note_id) Keep (dense_rank First Order By id_number Asc, note_date Desc, note_id Desc) As ksm_note_id,
    max(note_date) Keep (dense_rank First Order By id_number Asc, note_date Desc, note_id Desc) As ksm_note_date,
    min(description) Keep (dense_rank First Order By id_number Asc, note_date Desc, note_id Desc) As ksm_note_desc,
    min(brief_note) Keep (dense_rank First Order By id_number Asc, note_date Desc, note_id Desc) As ksm_brief_note,
    max(date_added) Keep (dense_rank First Order By id_number Asc, note_date Desc, note_id Desc) As ksm_date_added
  From ksm_reminders
  Group By id_number
),

/* Preferred address and email */
addr As (
  Select id_number, line_1, line_2, line_3, line_4, line_5, line_6, line_7, line_8
  From address
  Where addr_pref_ind = 'Y'
),
emails As (
  Select id_number,
    max(Case When preferred_ind = 'Y' Then email_address End) As pref_email,
    max(email_address) Keep (dense_rank First Order By (Case When email_type_code = 'X' Then 1 End) Asc, xsequence Desc) As home_email,
    max(email_address) Keep (dense_rank First Order By (Case When email_type_code = 'Y' Then 1 End) Asc, xsequence Desc) As bus_email
  From email
  Where email_status_code = 'A'
  Group By id_number
),

/* Special handling */
spec_hnd As (
  Select Distinct handling.id_number, handling.hnd_type_code, tms_ht.short_desc As hnd_type
  From handling
  Inner Join plg_assoc_dnrs On plg_assoc_dnrs.pledge_donor_id = handling.id_number
  Inner Join tms_handling_type tms_ht On tms_ht.handling_type = handling.hnd_type_code
  Where hnd_status_code = 'A'
    And hnd_type_code In (
    -- No Contact, Do Not Solicit, No Pledge Reminder, No Mail/Solicit, No Email/Solicit, Opt In Only
    'NC', 'DNS', 'NPR', 'NM', 'NMS', 'NE', 'NES', 'OIO'
  )
),
spec_hnd_conc As (
  Select id_number,
    Listagg(hnd_type_code, '; ') Within Group (Order By hnd_type_code) As hnd_type_code_concat,
    Listagg(hnd_type, '; ') Within Group (Order By hnd_type_code) As hnd_type_concat
  From spec_hnd
  Group By id_number
)

/* Main query */

Select
  -- Donor fields
  pledge.pledge_donor_id As legal_donor_id,
  entity.report_name As legal_donor_name,
  entity.institutional_suffix,
  Case When pledge_counts.attr_donors_count > 0 Then pledge_counts.attr_donors_count End As attr_donors_count,
  -- Pledge overview
  tms_trans.transaction_type,
  ksm_pkg.get_fiscal_year(pmts.date_of_record_prim_plg) As last_payment_fy_prim_plg,
  pay_last.last_sched_year_paid,
  pay_next.next_sched_year,
  Case When remind.note_id || remindk.ksm_note_id Is Null Then 'N' Else 'Y' End As recent_reminder,
  -- Pledge fields
  pledge.pledge_pledge_number As pledge_number,
  pp.prim_pledge_date_of_record As date_of_record,
  pp.prim_pledge_year_of_giving As fiscal_year,
  -- Allocation fields
  pledge_allocation_name As allocation_code,
  allocation.short_name As allocation_name,
  ksm_af_allocs.af_flag,
  -- Amount fields
  pledge.pledge_amount As alloc_pledge_amount,
  ksm_paid_amt.total_paid As alloc_total_paid,
  pledge.pledge_amount - nvl(ksm_paid_amt.total_paid, 0) As alloc_pledge_balance,
  Case When pledge_counts.allocs_count > 1 Then pledge_counts.allocs_count End As split_gift_allocs,
  pp.prim_pledge_amount,
  pp.prim_pledge_amount_paid,
  pp.prim_pledge_amount - nvl(pp.prim_pledge_amount_paid, 0) As prim_pledge_balance,
  -- Recent payment fields
  pmts.recent_pmt_nbr_prim_plg,
  pmts.date_of_record_prim_plg,
  pmts.pmt_amount_prim_plg,
  pmtsa.recent_pmt_nbr_alloc,
  pmtsa.date_of_record_alloc,
  pmtsa.pmt_amount_alloc,
  -- Scheduled payment fields
  pay_last.last_sched_date_paid,
  pay_last.last_sched_amount,
  pay_next.next_sched_date,
  pay_next.next_sched_amount,
  pay_next.next_sched_balance,
  -- Pledge reminders
  remind.note_id As grs_most_recent_note_id,
  remind.note_date,
  remind.note_desc,
  remind.brief_note,
  remind.date_added,
  remindk.ksm_note_id As ksm_most_recent_note_id,
  remindk.ksm_note_date,
  remindk.ksm_note_desc,
  remindk.ksm_brief_note,
  remindk.ksm_date_added,
  -- Special handling
  Case When lower(inst_suffixes.inst_suffixes) Like '%trustee%' Then 'Trustee' End As trustee, -- Are ANY attr donors trustees
  spec_hnd_conc.hnd_type_code_concat,
  spec_hnd_conc.hnd_type_concat,
  -- Contact info
  entity.first_name,
  entity.pref_mail_name,
  addr.line_1,
  addr.line_2,
  addr.line_3,
  addr.line_4,
  addr.line_5,
  addr.line_6,
  addr.line_7,
  addr.line_8,
  emails.pref_email,
  emails.home_email,
  emails.bus_email,
  -- Prospect managers
  prs.prospect_manager,
  prs.team,
    -- Logic for including/excluding
  Case
    When pp.prim_pledge_type In ('BE', 'GP') Then 'N'
    When lower(inst_suffixes.inst_suffixes) Like '%trustee%' Then 'N'
    When pp.prim_pledge_type In ('ST', 'NB') And pay_next.next_sched_year > cal.curr_fy Then 'N'
    Else 'Y'
  End As include_pledge
-- Pledge tables
From pledge
Inner Join primary_pledge pp On pp.prim_pledge_number = pledge.pledge_pledge_number
-- Entity data
Inner Join entity On entity.id_number = pledge.pledge_donor_id
Inner Join inst_suffixes On inst_suffixes.pledge_pledge_number = pledge.pledge_pledge_number
-- Descriptions from codes
Inner Join tms_trans On tms_trans.transaction_type_code = pp.prim_pledge_type
Inner Join allocation On allocation.allocation_code = pledge.pledge_allocation_name
-- Only active KSM pledges
Inner Join ksm_pledges On ksm_pledges.pledge_pledge_number = pledge.pledge_pledge_number
-- Only Kellogg portion of split pledges
Inner Join ksm_allocs On ksm_allocs.allocation_code = pledge.pledge_allocation_name
-- Split gift allocations count
Inner Join pledge_counts On pledge_counts.pledge_pledge_number = pledge.pledge_pledge_number
-- Current calendar
Cross Join v_current_calendar cal
-- AF flag
Left Join ksm_af_allocs On ksm_af_allocs.allocation_code = pledge.pledge_allocation_name
-- Paid amounts toward Kellogg allocations
Left Join ksm_paid_amt On ksm_paid_amt.pmt_on_pledge_number = pledge.pledge_pledge_number
  And ksm_paid_amt.allocation_code = pledge.pledge_allocation_name
-- Most recent payment info
Left Join recent_payments pmts On pmts.pmt_on_pledge_number = pledge.pledge_pledge_number
Left Join recent_payments_alloc pmtsa On pmtsa.pmt_on_pledge_number = pledge.pledge_pledge_number
  And pmtsa.allocation_code = pledge.pledge_allocation_name
-- Payment schedule
Left Join pay_last On pay_last.pledge_pledge_number = pledge.pledge_pledge_number
Left Join pay_next On pay_next.pledge_pledge_number = pledge.pledge_pledge_number
-- Any recent reminders sent? (Assumes to the LEGAL donor)
Left Join recent_reminders remind On remind.id_number = pledge.pledge_donor_id
Left Join recent_ksm_reminders remindk On remindk.id_number = pledge.pledge_donor_id
-- Contact info
Left Join spec_hnd_conc On spec_hnd_conc.id_number = pledge.pledge_donor_id
Left Join addr On addr.id_number = pledge.pledge_donor_id
Left Join emails On emails.id_number = pledge.pledge_donor_id
-- Prospect manager
Left Join nu_prs_trp_prospect prs On prs.id_number = pledge.pledge_donor_id
-- Conditions
Where
  -- Only legal donor
  pledge_amount > 0
  -- Only unfulfilled commitments
  And (pledge.pledge_amount > ksm_paid_amt.total_paid Or ksm_paid_amt.total_paid Is Null)
-- Sort for easier comparison
Order By
  pledge.pledge_pledge_number Asc,
  pp.prim_pledge_date_of_record Desc,
  pledge.pledge_donor_id Asc,
  pledge.pledge_allocation_name Asc
