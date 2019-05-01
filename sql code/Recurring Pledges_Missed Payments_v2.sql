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
  From table(rpt_pbh634.ksm_pkg.tbl_alloc_annual_fund_ksm)
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
      Then rpt_pbh634.ksm_pkg.get_fiscal_year(to_date(psched.payment_schedule_date, 'YYYYMMDD'))
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
  Cross Join rpt_pbh634.v_current_calendar cal
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
  Cross Join rpt_pbh634.v_current_calendar cal
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
--counts
COUNT_PLEDGES AS
(
select plg.id,
       plg.plg,
      COUNT(sc.payment_schedule_date) SCHEDULED_PAYMENTS,  
      sum(CASE WHEN sc.payment_schedule_status = 'P' THEN sc.payment_schedule_amount else 0 end) PAID_FY18,
        sum(plg.prop * sc.payment_schedule_balance) pay      
 from payment_schedule sc,
 (select p.pledge_donor_id ID,
         pp.prim_pledge_number plg, 
         p.pledge_allocation_name alloc,
         al.annual_sw AF,
         p.pledge_associated_credit_amt / pp.prim_pledge_amount prop         
  from primary_pledge pp,
       pledge p,
       allocation al
  where p.pledge_pledge_number = pp.prim_pledge_number
  and   p.pledge_allocation_name = al.allocation_code
  and   al.alloc_school = 'KM'
  and   pp.prim_pledge_status = 'A') plg
 where plg.plg = sc.payment_schedule_pledge_nbr
 and   sc.payment_schedule_date between '20170901' and '20180831'
 group by plg.id,plg.plg
)
SELECT 
  HH."HOUSEHOLD_ID"
  ,E.ID_NUMBER
  ,E.PREF_MAIL_NAME
  ,AT.short_desc AS ADDRESS_TYPE
  ,A.STATE_CODE
  ,WT0_PKG.GetPrefPhoneType(E.ID_NUMBER) PREF_PHONE_TYPE
	,WT0_PKG.GetPhone(E.ID_NUMBER, 'H') HM_PHONE
  ,WT0_PKG.GetPhoneStatus(E.ID_NUMBER) PH_STATUS
  ,ET.short_desc AS EMAIL_PREF
    -- Pledge overview
  ,tms_trans.transaction_type
/*  ,rpt_pbh634.ksm_pkg.get_fiscal_year(pmts.date_of_record_prim_plg) As last_payment_fy_prim_plg
  ,pay_last.last_sched_year_paid
  ,pay_next.next_sched_year
  ,Case When remind.note_id || remindk.ksm_note_id Is Null Then 'N' Else 'Y' End As recent_reminder*/
  -- Pledge fields
  ,p.pledge_pledge_number As pledge_number
  ,pp.prim_pledge_date_of_record As date_of_record
  ,pp.prim_pledge_year_of_giving As fiscal_year
  -- Allocation fields
  ,P2.pledge_allocation_name As allocation_code
  ,ALLOC.short_name As allocation_name
  ,ksm_af_allocs.af_flag
  -- Amount fields
  ,p2.pledge_amount As alloc_pledge_amount
  ,ksm_paid_amt.total_paid As alloc_total_paid
  ,p2.pledge_amount - nvl(ksm_paid_amt.total_paid, 0) As alloc_pledge_balance
  
  ,CP.SCHEDULED_PAYMENTS AS SCHEDULED_PAYMENTS_FY18
  ,CP.PAID_FY18
  ,CP.PAY AS BALANCE_FY18
FROM ENTITY E
LEFT JOIN RPT_PBH634.V_ENTITY_KSM_DEGREES EKD
ON E.ID_NUMBER = EKD."ID_NUMBER"
INNER JOIN PLEDGE P
ON E.ID_NUMBER = P.PLEDGE_DONOR_ID
INNER JOIN PLEDGE P2
ON P2.Pledge_Pledge_Number = P.Pledge_Pledge_Number
 AND P2.Pledge_Associated_Code IN ('P', 'S')
 AND P2.PLEDGE_ALLOC_SCHOOL = 'KM'
LEFT JOIN RPT_PBH634.V_ENTITY_KSM_HOUSEHOLDS HH
ON E.ID_NUMBER = HH."ID_NUMBER"
Inner Join primary_pledge pp 
On pp.prim_pledge_number = P.pledge_pledge_number
-- Descriptions from codes
Inner Join tms_trans 
On tms_trans.transaction_type_code = pp.prim_pledge_type
Inner Join allocation ALLOC
On ALLOC.allocation_code = P.pledge_allocation_name
-- Only active KSM pledges
Inner Join ksm_pledges On ksm_pledges.pledge_pledge_number = p.pledge_pledge_number
-- Only Kellogg portion of split pledges
Inner Join ksm_allocs On ksm_allocs.allocation_code = p.pledge_allocation_name
-- Split gift allocations count
Inner Join pledge_counts On pledge_counts.pledge_pledge_number = p.pledge_pledge_number
-- Current calendar
Cross Join rpt_pbh634.v_current_calendar cal
-- AF flag
Left Join ksm_af_allocs On ksm_af_allocs.allocation_code = p.pledge_allocation_name
-- Paid amounts toward Kellogg allocations
Left Join ksm_paid_amt On ksm_paid_amt.pmt_on_pledge_number = p.pledge_pledge_number
  And ksm_paid_amt.allocation_code = p.pledge_allocation_name
-- Most recent payment info
Left Join recent_payments pmts On pmts.pmt_on_pledge_number = p.pledge_pledge_number
Left Join recent_payments_alloc pmtsa On pmtsa.pmt_on_pledge_number = p.pledge_pledge_number
  And pmtsa.allocation_code = p.pledge_allocation_name
-- Payment schedule
Left Join pay_last On pay_last.pledge_pledge_number = p.pledge_pledge_number
Left Join pay_next On pay_next.pledge_pledge_number = p.pledge_pledge_number
-- Any recent reminders sent? (Assumes to the LEGAL donor)
Left Join recent_reminders remind On remind.id_number = p.pledge_donor_id
Left Join recent_ksm_reminders remindk On remindk.id_number = p.pledge_donor_id
--COUNTS
INNER JOIN COUNT_PLEDGES CP 
 ON E.ID_NUMBER = CP.ID
 AND P.PLEDGE_PLEDGE_NUMBER = CP.PLG
LEFT JOIN ADDRESS A
ON E.ID_NUMBER = A.ID_NUMBER
  AND A.ADDR_PREF_IND = 'Y'
  AND A.ADDR_STATUS_CODE = 'A'
LEFT JOIN TMS_ADDRESS_TYPE AT
ON A.ADDR_TYPE_CODE = AT.addr_type_code
LEFT JOIN EMAIL EM
ON E.ID_NUMBER = EM.ID_NUMBER
  AND EM.EMAIL_STATUS_CODE = 'A'
  AND EM.PREFERRED_IND = 'Y'
LEFT JOIN TMS_EMAIL_TYPE ET
ON EM.EMAIL_TYPE_CODE = ET.email_type_code
WHERE E.record_status_code not in ('I','X','D')
AND 
  -- Trans types filter
  transaction_type_code In ('RC')
ORDER BY HH."HOUSEHOLD_ID" ASC
