-- Create Or Replace View v_ksm_pledge_balances As

With

/** Parameters - EDIT THIS **/
params As (
  Select
    '20170901' As param_start_dt
    , '20180831' As param_stop_dt
  From DUAL
)

-- Transaction and pledge TMS table definition
, tms_trans As (
  (
    Select
      transaction_type_code
      , short_desc As transaction_type
    From tms_transaction_type
  ) Union All (
    Select
      pledge_type_code
      , short_desc
    From tms_pledge_type
  )
)

-- KSM allocations
, ksm_allocs As (
  Select
    allocation_code
  From allocation
  Where alloc_school = 'KM'
)
, ksm_af_allocs As (
  Select
    allocation_code
    , af_flag
  From table(rpt_pbh634.ksm_pkg.tbl_alloc_curr_use_ksm)
)

-- Pledge numbers of interest
, ksm_pledges As (
  Select Distinct
    pledge.pledge_pledge_number
  From pledge
  Inner Join primary_pledge
    On primary_pledge.prim_pledge_number = pledge.pledge_pledge_number
  Left Join ksm_allocs
    On ksm_allocs.allocation_code = pledge.pledge_allocation_name
  Where primary_pledge.prim_pledge_status = 'A'
    And (
      ksm_allocs.allocation_code Is Not Null
      Or (
      -- KSM program code
        pledge_allocation_name In ('BE', 'LE') -- BE and LE discounted amounts
        And pledge_program_code = 'KM'
      )
    )
)
, pledge_counts As (
  Select
    pledge.pledge_pledge_number
    , count(Distinct pledge.pledge_allocation_name)
      As allocs_count
    , count(Distinct pledge.pledge_donor_id) - 1 -- Subtract 1 for the legal donor
      As attr_donors_count
  From pledge
  Inner Join ksm_pledges
    On ksm_pledges.pledge_pledge_number = pledge.pledge_pledge_number
  Group By pledge.pledge_pledge_number
)

-- Associated donors
, plg_assoc_dnrs As (
  Select
    pledge.pledge_pledge_number
    , pledge.pledge_donor_id
    , entity.institutional_suffix
  From pledge
  Inner Join ksm_pledges
    On ksm_pledges.pledge_pledge_number = pledge.pledge_pledge_number
  Inner Join entity
    On entity.id_number = pledge.pledge_donor_id
)
, inst_suffixes As (
  Select
    pledge_pledge_number
    , listagg(institutional_suffix, '; ') Within Group (Order By pledge_donor_id)
      As inst_suffixes
  From plg_assoc_dnrs
  Group By pledge_pledge_number
)

-- Pledge payments
, ksm_payments As (
  Select
    gft.tx_number
    , gft.tx_sequence
    , gft.pmt_on_pledge_number
    , gft.allocation_code
    , gft.date_of_record
    , gft.legal_amount
  From nu_gft_trp_gifttrans gft
  Inner Join ksm_allocs
    On ksm_allocs.allocation_code = gft.allocation_code
  Inner Join ksm_pledges
    On ksm_pledges.pledge_pledge_number = gft.pmt_on_pledge_number
  Where gft.legal_amount > 0
  Order By
    pmt_on_pledge_number Asc
    , date_of_record Desc
)
, ksm_paid_amt As (
  Select
    pmt_on_pledge_number
    , allocation_code
    , sum(legal_amount)
      As total_paid
  From ksm_payments
  Group By pmt_on_pledge_number, allocation_code
)
, recent_payments As (
  Select
    pmt_on_pledge_number
    , min(tx_number) keep(dense_rank First Order By pmt_on_pledge_number Asc, date_of_record Desc, tx_number Desc)
      As recent_pmt_nbr_prim_plg
    , max(date_of_record) keep(dense_rank First Order By pmt_on_pledge_number Asc, date_of_record Desc, tx_number Desc)
      As date_of_record_prim_plg
    , sum(legal_amount) keep(dense_rank First Order By pmt_on_pledge_number Asc, date_of_record Desc, tx_number Desc)
      As pmt_amount_prim_plg
  From ksm_payments
  Group By pmt_on_pledge_number
  Order By pmt_on_pledge_number Asc
)
, recent_payments_alloc As (
  Select
    pmt_on_pledge_number
    , allocation_code
    , min(tx_number) Keep (dense_rank First Order By pmt_on_pledge_number Asc, date_of_record Desc, tx_number Desc)
      As recent_pmt_nbr_alloc
    , max(date_of_record) Keep (dense_rank First Order By pmt_on_pledge_number Asc, date_of_record Desc, tx_number Desc)
      As date_of_record_alloc
    , sum(legal_amount) Keep (dense_rank First Order By pmt_on_pledge_number Asc, date_of_record Desc, tx_number Desc)
      As pmt_amount_alloc
  From ksm_payments
  Group By
    pmt_on_pledge_number
    , allocation_code
  Order By pmt_on_pledge_number Asc
)

-- Pledge payment schedules
, pay_sch As (
  Select
    ksm_pledges.pledge_pledge_number
    , psched.payment_schedule_status
    , psched.payment_schedule_date
    , Case
        When payment_schedule_date Not Like '0000%'
          And payment_schedule_date Not Like '____00%'
          Then rpt_pbh634.ksm_pkg.get_fiscal_year(to_date(psched.payment_schedule_date, 'YYYYMMDD'))
        End
      As payment_schedule_fiscal_year
    , psched.payment_schedule_amount
    , psched.payment_schedule_balance
  From payment_schedule psched
  Inner Join ksm_pledges
    On ksm_pledges.pledge_pledge_number = psched.payment_schedule_pledge_nbr
)
, pay_last As (
  Select
    pledge_pledge_number
    , min(payment_schedule_date) Keep (dense_rank First Order By payment_schedule_date Desc, payment_schedule_balance Desc)
      As last_sched_date_paid
    , min(payment_schedule_fiscal_year) Keep (dense_rank First Order By payment_schedule_date Desc, payment_schedule_balance Desc)
      As last_sched_year_paid
    , min(payment_schedule_amount) Keep (dense_rank First Order By payment_schedule_date Desc, payment_schedule_balance Desc)
      As last_sched_amount
    , min(payment_schedule_balance) Keep (dense_rank First Order By payment_schedule_date Desc, payment_schedule_balance Desc)
      As last_sched_balance
  From pay_sch
  Where payment_schedule_status = 'P'
  Group By pledge_pledge_number
)
, pay_next As (
  Select
    pledge_pledge_number
    , min(payment_schedule_date) Keep (dense_rank First Order By payment_schedule_date Asc, payment_schedule_balance Desc)
      As next_sched_date
    , min(payment_schedule_fiscal_year) Keep (dense_rank First Order By payment_schedule_date Asc, payment_schedule_balance Desc)
      As next_sched_year
    , min(payment_schedule_amount) Keep (dense_rank First Order By payment_schedule_date Asc, payment_schedule_balance Desc)
      As next_sched_amount
    , min(payment_schedule_balance) Keep (dense_rank First Order By payment_schedule_date Asc, payment_schedule_balance Desc)
      As next_sched_balance
  From pay_sch
  Where payment_schedule_status = 'U'
  Group By pledge_pledge_number
)

-- Counts
, plg As (
  Select
    p.pledge_donor_id As id
    , pp.prim_pledge_number As plg
    , p.pledge_allocation_name As alloc
    , al.annual_sw As af
    , p.pledge_associated_credit_amt / pp.prim_pledge_amount
      As prop
  From primary_pledge pp
  Inner Join pledge p
    On p.pledge_pledge_number = pp.prim_pledge_number
  Inner Join allocation al
    On al.allocation_code = p.pledge_allocation_name
  Where al.alloc_school = 'KM'
    And pp.prim_pledge_status = 'A'
)
, count_pledges As (
  Select
    plg.id
    , plg.plg
    , count(sc.payment_schedule_date) As scheduled_payments
    , sum(Case When sc.payment_schedule_status = 'P' Then sc.payment_schedule_amount Else 0 End)
      As paid_fy18
    , sum(plg.prop * sc.payment_schedule_balance)
      As pay      
  From payment_schedule sc
  Inner Join plg
    On plg.plg = sc.payment_schedule_pledge_nbr
  Cross Join params
  Where sc.payment_schedule_date Between param_start_dt And param_stop_dt
  Group By
    plg.id
    , plg.plg
)

-- Main query
Select
  e.id_number
  , e.report_name
  -- Pledge overview
  , tms_trans.transaction_type_code
  , tms_trans.transaction_type
  -- Pledge fields
  , p.pledge_pledge_number As pledge_number
  , pp.prim_pledge_date_of_record As date_of_record
  , pp.prim_pledge_year_of_giving As fiscal_year
  -- Allocation fields
  , p2.pledge_allocation_name As allocation_code
  , alloc.short_name As allocation_name
  , Case When ksm_af_allocs.af_flag Is Not Null Then 'Y' End
    As ksm_cru_flag
  , Case When ksm_af_allocs.af_flag = 'Y' Then 'Y' End
    As ksm_af_flag
  -- Amount fields
  , p2.pledge_amount As alloc_pledge_amount
  , ksm_paid_amt.total_paid As alloc_total_paid
  , p2.pledge_amount - nvl(ksm_paid_amt.total_paid, 0) As alloc_pledge_balance
  , cp.scheduled_payments As scheduled_payments_fy18
  , cp.paid_fy18
  , cp.pay As balance_fy18
From entity e
Inner Join pledge p
  on e.id_number = p.pledge_donor_id
Inner Join pledge p2
  On p2.pledge_pledge_number = p.pledge_pledge_number
  And p2.pledge_associated_code In ('P', 'S')
  And p2.pledge_alloc_school = 'KM'
Inner Join primary_pledge pp 
  On pp.prim_pledge_number = p.pledge_pledge_number
-- Descriptions from codes
Inner Join tms_trans 
  On tms_trans.transaction_type_code = pp.prim_pledge_type
Inner Join allocation alloc
  On alloc.allocation_code = p.pledge_allocation_name
-- Only active KSM pledges
Inner Join ksm_pledges
  On ksm_pledges.pledge_pledge_number = p.pledge_pledge_number
-- Only Kellogg portion of split pledges
Inner Join ksm_allocs
  On ksm_allocs.allocation_code = p.pledge_allocation_name
-- Split gift allocations count
Inner Join pledge_counts
  On pledge_counts.pledge_pledge_number = p.pledge_pledge_number
-- Current calendar
Cross Join rpt_pbh634.v_current_calendar cal
-- AF flag
Left Join ksm_af_allocs
  On ksm_af_allocs.allocation_code = p.pledge_allocation_name
-- Paid amounts toward Kellogg allocations
Left Join ksm_paid_amt
  On ksm_paid_amt.pmt_on_pledge_number = p.pledge_pledge_number
  And ksm_paid_amt.allocation_code = p.pledge_allocation_name
-- Most recent payment info
Left Join recent_payments pmts
  On pmts.pmt_on_pledge_number = p.pledge_pledge_number
Left Join recent_payments_alloc pmtsa
  On pmtsa.pmt_on_pledge_number = p.pledge_pledge_number
  And pmtsa.allocation_code = p.pledge_allocation_name
-- Payment schedule
Left Join pay_last
  On pay_last.pledge_pledge_number = p.pledge_pledge_number
Left Join pay_next
  On pay_next.pledge_pledge_number = p.pledge_pledge_number
-- Counts
Inner Join count_pledges cp 
 On e.id_number = cp.id
 And p.pledge_pledge_number = cp.plg
Where e.record_status_code Not In ('I','X','D')
  -- Recurring gift, straight pledge, NBI, grant pledge only
  And transaction_type_code In ('RC', 'ST', 'NB', 'GP')
