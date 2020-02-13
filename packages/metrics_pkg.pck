Create Or Replace Package metrics_pkg Is

/*************************************************************************
Author  : PBH634
Created : 2/13/2020 11:19:42 AM
Purpose : Consolidated gift officer metrics definitions to allow audit
information to be easily pulled.

Adapted from rpt_pbh634.v_mgo_activity_monthly and 
*************************************************************************/

/*************************************************************************
Public constant declarations
*************************************************************************/

-- Thresholds for proposals to count toward MGO metrics
mg_ask_amt Constant number := 100000; -- As of 2018-03-23. Minimum $ to count as ask
mg_granted_amt Constant number := 48000; -- As of 2018-03-23. Minimum $ to count as granted
mg_funded_count Constant number := 98000; -- As of 2018-03-23. Minimum $ to count as funded

/*************************************************************************
Public type declarations
*************************************************************************/

Type proposals_data Is Record (
  proposal_id proposal.proposal_id%type
  , assignment_id_number assignment.assignment_id_number%type
  , assignment_type assignment.assignment_type%type
  , assignment_active_ind assignment.active_ind%type
  , proposal_active_ind proposal.active_ind%type
  , ask_amt proposal.ask_amt%type
  , granted_amt proposal.granted_amt%type
  , proposal_status_code proposal.proposal_status_code%type
  , initial_contribution_date proposal.initial_contribution_date%type
  , proposal_stop_date proposal.stop_date%type
  , assignment_stop_date assignment.stop_date%type
  , proposalmanagercount number
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type t_proposals_data Is Table Of proposals_data;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

/*********************** About pipelined functions ***********************
Q: What is a pipelined function?

A: Pipelined functions are used to return the results of a cursor row by row.
This is an efficient way to re-use a cursor between multiple programs. Pipelined
tables can be queried in SQL exactly like a table when embedded in the table()
function. My experience has been that thanks to the magic of the Oracle compiler,
joining on a table() function scales hugely better than running a function once
on each element of a returned column. Note that the exact columns returned need
to be specified as a public type, which I did in the type and table declarations
above, or the pipelined function can't be run in pure SQL. Alternately, the
pipelined function could return a generic table, but the columns would still need
to be individually named.

Examples: 
Select ksm_af.*
From table(rpt_pbh634.ksm_pkg.tbl_alloc_annual_fund_ksm) ksm_af;
Select cal.*
From table(rpt_pbh634.ksm_pkg.tbl_current_calendar) cal;
*************************************************************************/

Function tbl_universal_proposals_data
  Return t_proposals_data Pipelined;

End metrics_pkg;
/
Create Or Replace Package Body metrics_pkg Is

/*************************************************************************
Private cursor tables -- data definitions; update indicated sections as needed
*************************************************************************/

-- Universal proposals data, adapted from v_mgo_activity_monthly
-- All fields needed to recreate proposals subqueries appearing throughout the original file
Cursor c_universal_proposals_data Is
  Select p.proposal_id
    , a.assignment_id_number
    , a.assignment_type
    , a.active_ind As assignment_active_ind
    , p.active_ind As proposal_active_ind
    , p.ask_amt
    , p.granted_amt
    , p.proposal_status_code
    , p.initial_contribution_date
    , p.stop_date As proposal_stop_date
    , a.stop_date As assignment_stop_date
    -- Count only proposal managers, not proposal assists
    , count(Case When a.assignment_type = 'PA' Then a.assignment_id_number Else NULL End)
        Over(Partition By a.proposal_id)
      As proposalManagerCount
  From proposal p
  Inner Join assignment a
    On a.proposal_id = p.proposal_id
  Where a.assignment_type In ('PA', 'AS') -- Proposal Manager, Proposal Assist
    And assignment_id_number != ' '
    And p.proposal_status_code In ('C', '5', '7', '8') -- submitted/approved/declined/funded
  ;
/*  
-- Count for funded proposal goal 1
Cursor proposals_funded_count Is
  -- Must be proposal manager, funded status, and above the ask & funded credit thresholds
  Select *
  From universal_proposals_data
  Where assignment_type = 'PA' -- Proposal Manager
    And ask_amt >= (Select param_ask_amt From custom_params)
    And granted_amt >= (Select param_funded_count From custom_params)
    And proposal_status_code = '7' -- Only funded
  ;
  
-- Count for asked proposal goal 2
Cursor proposals_asked_count Is
  -- Must be proposal manager and above the ask credit threshold
  Select *
  From universal_proposals_data
  Where assignment_type = 'PA' -- Proposal Manager
    And ask_amt >= (Select param_ask_amt From custom_params)
  ;
  
-- Gift credit for funded proposal goal 3
Cursor proposals_funded_cr Is
  Select
    upd.*
    -- Must be proposal manager, funded status, and above the ask & granted amount thresholds
    , Case
        When ask_amt >= (Select param_ask_amt From custom_params)
          And granted_amt >= (Select param_granted_amt From custom_params)
          Then 'Y'
        Else 'N'
      End
      As funded_credit_flag
  From universal_proposals_data upd
  Where assignment_type = 'PA' -- Proposal Manager
    And granted_amt >= 0
    And proposal_status_code = '7' -- Only funded
  ;
  
-- Count for proposal assists goal 6
Cursor proposal_assists_count Is
  -- Must be proposal assist; no dollar threshold
  Select *
  From universal_proposals_data
  Where assignment_type = 'AS' -- Proposal Assist
  ;
  
-- Refactor goal 1 subqueries in lines 11-77
-- 3 clones, at 138-204, 265-331, 392-458
-- Credit for asked & funded proposals
, funded_count As (
    -- 1st priority - Look across all proposal managers on a proposal (inactive OR active).
    -- If there is ONE proposal manager only, credit that for that proposal ID.
    Select proposal_id
      , assignment_id_number
      , 1 As info_rank
    From proposals_funded_count
    Where proposalManagerCount = 1 ------ only one proposal manager/ credit that PA
  Union
    -- 2nd priority - For #2 if there is more than one active proposal managers on a proposal credit BOTH and exit the process.
    Select proposal_id
      , assignment_id_number
      , 2 As info_rank
    From proposals_funded_count
    Where assignment_active_ind = 'Y'
  Union
    -- 3rd priority - For #3, Credit all inactive proposal managers where proposal stop date and assignment stop date within 24 hours
    Select proposal_id
      , assignment_id_number
      , 3 As info_rank
    From proposals_funded_count
    Where proposal_active_ind = 'N' -- Inactives on the proposal.
      And proposal_stop_date - assignment_stop_date <= 1
  Order By info_rank
)
, funded_count_distinct As (
  Select Distinct proposal_id
    , assignment_id_number
  From funded_count
)

-- Refactor all subqueries in lines 78-124
-- 7 clones, at 205-251, 332-378, 459-505, 855-901, 991-1037, 1127-1173, 1263-1309
, proposal_dates_data As (
  -- In determining which date to use, evaluate outright gifts and pledges first and then if necessary
  -- use the date from a pledge payment.
    Select proposal_id
      , 1 As rank
      , min(prim_gift_date_of_record) As date_of_record --- gifts
    From primary_gift
    Where proposal_id Is Not Null
      And proposal_id != 0
      And pledge_payment_ind = 'N'
    Group By proposal_id
  Union
    Select proposal_id
      , 2 As rank
      , min(prim_gift_date_of_record) As date_of_record --- pledge payments
    From primary_gift
    Where proposal_id Is Not Null
      And proposal_id != 0
      And pledge_payment_ind = 'Y'
    Group By proposal_id
  Union
    Select proposal_id
        , 1 As rank
        , min(prim_pledge_date_of_record) As date_of_record --- pledges
      From primary_pledge
      Where proposal_id Is Not Null
        And proposal_id != 0
      Group By proposal_id
)
, proposal_dates As (
  Select proposal_id
    , min(date_of_record) keep(dense_rank First Order By rank Asc)
      As date_of_record
  From proposal_dates_data
  Group By proposal_id
)

-- Refactor goal 2 subqueries in lines 518-590
-- 3 clones, at 602-674, 686-758, 769-841
, asked_count As (
    -- 1st priority - Look across all proposal managers on a proposal (inactive OR active).
    -- If there is ONE proposal manager only, credit that for that proposal ID.
    Select proposal_id
      , assignment_id_number
      , initial_contribution_date
      , proposal_stop_date
      , 1 As info_rank
    From proposals_asked_count
    Where proposalManagerCount = 1 ----- only one proposal manager/ credit that PA 
  Union
    -- 2nd priority - For #2 if there is more than one active proposal managers on a proposal credit BOTH and exit the process.
    Select proposal_id
      , assignment_id_number
      , initial_contribution_date
      , proposal_stop_date
      , 2 As info_rank
    From proposals_asked_count
    Where assignment_active_ind = 'Y'
  Union
    -- 3rd priority - For #3, Credit all inactive proposal managers where proposal stop date and assignment stop date within 24 hours
    Select proposal_id
      , assignment_id_number
      , initial_contribution_date
      , proposal_stop_date
      , 3 As info_rank
    From proposals_asked_count
    Where proposal_active_ind = 'N' -- Inactives on the proposal.
      And proposal_stop_date - assignment_stop_date <= 1
  Order By info_rank
)
, asked_count_ranked As (
  Select proposal_id
    , assignment_id_number
    , min(initial_contribution_date) keep(dense_rank First Order By info_rank Asc)  -- initial_contribution_date is 'ask_date'
      As initial_contribution_date
    -- Replace null initial_contribution_date with proposal_stop_date
    , min(nvl(initial_contribution_date, proposal_stop_date)) keep(dense_rank First Order By info_rank Asc)
      As ask_or_stop_dt
  From asked_count
  Group By proposal_id
    , assignment_id_number
)

-- Refactor goal 3 subqueries in lines 848-982
-- 3 clones, at 984-1170, 1120-1254, 1256-1390
, funded_credit As (
    -- 1st priority - Look across all proposal managers on a proposal (inactive OR active).
    -- If there is ONE proposal manager only, credit that for that proposal ID.
    Select proposal_id
      , assignment_id_number
      , granted_amt
      , funded_credit_flag
      , 1 As info_rank
    From proposals_funded_cr
    Where proposalManagerCount = 1 ----- only one proposal manager/ credit that PA
  Union
    -- 2nd priority - For #2 if there is more than one active proposal managers on a proposal credit BOTH and exit the process.
    Select proposal_id
       , assignment_id_number
       , granted_amt
       , funded_credit_flag
       , 2 As info_rank
    From proposals_funded_cr
    Where assignment_active_ind = 'Y'
  Union
    -- 3rd priority - For #3, Credit all inactive proposal managers where proposal stop date and assignment stop date within 24 hours
    Select proposal_id
       , assignment_id_number
       , granted_amt
       , funded_credit_flag
       , 3 As info_rank
    From proposals_funded_cr
    Where proposal_active_ind = 'N' -- Inactives on the proposal.
      And proposal_stop_date - assignment_stop_date <= 1
  Order By info_rank
)
, funded_ranked As (
  Select proposal_id
    , assignment_id_number
    , max(funded_credit_flag)
      As funded_credit_flag
    , max(granted_amt) keep(dense_rank First Order By info_rank Asc)
      As granted_amt
  From funded_credit
  Group By proposal_id
    , assignment_id_number
)

-- Refactor goal 6 subqueries in lines 1456-1489
-- 3 clones, at 1501-1534, 1546-1579, 1591-1624
, assist_count As (
  -- Any active proposals (1st priority)
    Select proposal_id
      , assignment_id_number
      , initial_contribution_date
      , proposal_stop_date
      , 1 As info_rank
    From proposal_assists_count
    Where assignment_active_ind = 'Y'
  Union
    Select proposal_id
      , assignment_id_number
      , initial_contribution_date
      , proposal_stop_date
      , 2 As info_rank
    From proposal_assists_count
    Where assignment_active_ind = 'N'
      And proposal_stop_date - assignment_stop_date <= 1
  Order By info_rank
)
, assist_count_ranked As (
  Select proposal_id
    , assignment_id_number
    , min(initial_contribution_date) keep(dense_rank First Order By info_rank Asc)
      As initial_contribution_date
    -- Replace null initial_contribution_date with proposal_stop_date
    , min(nvl(initial_contribution_date, proposal_stop_date)) keep(dense_rank First Order By info_rank Asc)
      As ask_or_stop_dt
  From assist_count
  Group By proposal_id
    , assignment_id_number
)
*/
/*************************************************************************
Pipelined functions
*************************************************************************/

-- Pipelined function returning consolidated proposals data
Function tbl_universal_proposals_data
  Return t_proposals_data Pipelined As
    -- Declarations
    pd t_proposals_data;

  Begin
    Open c_universal_proposals_data; -- Annual Fund allocations cursor
      Fetch c_universal_proposals_data Bulk Collect Into pd;
    Close c_universal_proposals_data;
    -- Pipe out the data
    For i in 1..(pd.count) Loop
      Pipe row(pd(i));
    End Loop;
    Return;
  End;

End metrics_pkg;
/
