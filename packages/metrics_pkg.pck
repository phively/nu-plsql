Create Or Replace Package metrics_pkg Is

/*************************************************************************
Author  : PBH634
Created : 2/13/2020 11:19:42 AM
Purpose : Consolidated gift officer metrics definitions to allow audit
information to be easily pulled.

Adapted from rpt_pbh634.v_mgo_activity_monthly and
advance_nu.nu_gft_v_officer_metrics.
*************************************************************************/

/*************************************************************************
Public constant declarations
*************************************************************************/

-- Thresholds for proposals to count toward MGO metrics
mg_ask_amt Constant number := 100E3; -- As of 2018-03-23. Minimum $ to count as ask
mg_ask_amt_ksm_outright Constant number := 100E3; -- As of 2021-05-01. Minimum KSM outright $ to count as ask.
mg_ask_amt_ksm_plg Constant number := 250E3; -- As of 2021-05-01. Minimum KSM pledge $ to count as ask.
mg_granted_amt Constant number := 48E3; -- As of 2018-03-23. Minimum $ to count as granted
mg_funded_count Constant number := 98E3; -- As of 2018-03-23. Minimum $ to count as funded

/*************************************************************************
Public type declarations
*************************************************************************/

Type proposals_data Is Record (
  proposal_id proposal.proposal_id%type
  , assignment_id_number assignment.assignment_id_number%type
  , assignment_type assignment.assignment_type%type
  , assignment_active_ind assignment.active_ind%type
  , proposal_active_ind proposal.active_ind%type
  , proposal_type proposal.proposal_type%type
  , outright_gift_proposal varchar2(1)
  , ask_amt proposal.ask_amt%type
  , granted_amt proposal.granted_amt%type
  , proposal_status_code proposal.proposal_status_code%type
  , initial_contribution_date proposal.initial_contribution_date%type
  , proposal_stop_date proposal.stop_date%type
  , assignment_stop_date assignment.stop_date%type
  , proposalmanagercount number
);

Type proposal_dates Is Record (
  proposal_id proposal.proposal_id%type
  , date_of_record date
);

Type funded_credit Is Record (
  proposal_id proposal.proposal_id%type
  , assignment_id_number assignment.assignment_id_number%type
);

Type funded_dollars Is Record (
  proposal_id proposal.proposal_id%type
  , assignment_id_number assignment.assignment_id_number%type
  , funded_credit_flag varchar2(1)
  , granted_amt number
);

Type contact_report Is Record (
  author_id_number contact_rpt_credit.id_number%type
  , report_id contact_rpt_credit.report_id%type
  , contact_purpose_code char(1)
  , cal_year number
  , fiscal_year number
  , cal_month number
  , fiscal_qtr number
  , perf_quarter number
  , perf_year number
);

Type contact_count Is Record (
  id_number contact_rpt_credit.id_number%type
  , report_id contact_rpt_credit.report_id%type
);

Type ask_assist_credit Is Record (
  proposal_id proposal.proposal_id%type
  , assignment_id_number assignment.assignment_id_number%type
  , initial_contribution_date date
  , ask_or_stop_dt date
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type t_proposals_data Is Table Of proposals_data;
Type t_proposal_dates Is Table Of proposal_dates;
Type t_funded_credit Is Table Of funded_credit;
Type t_funded_dollars Is Table Of funded_dollars;
Type t_contact_report Is Table Of contact_report;
Type t_contact_count Is Table Of contact_count;
Type t_ask_assist_credit Is Table Of ask_assist_credit;

/*************************************************************************
Public function declarations
*************************************************************************/

/* Function to return public/private constants */
Function get_constant(
  const_name In varchar2 -- Name of constant to retrieve
) Return number Deterministic;

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

-- Standardized proposal data table function
Function tbl_universal_proposals_data
  Return t_proposals_data Pipelined;
  
Function tbl_proposal_dates
  Return t_proposal_dates Pipelined;
  
-- Table functions for each of the MGO metrics
Function tbl_funded_count
  Return t_funded_credit Pipelined;

Function tbl_funded_dollars
  Return t_funded_dollars Pipelined;

Function tbl_asked_count
  Return t_ask_assist_credit Pipelined;

Function tbl_asked_count_ksm
  Return t_ask_assist_credit Pipelined;

Function tbl_contact_reports
  Return t_contact_report Pipelined;

Function tbl_contact_count
  Return t_contact_count Pipelined;

Function tbl_assist_count
  Return t_ask_assist_credit Pipelined;

End metrics_pkg;
/
Create Or Replace Package Body metrics_pkg Is

/*************************************************************************
Private cursor tables -- data definitions; update indicated sections as needed
*************************************************************************/

-- N.B. all line numbers reference the March 2018 version of advance_nu.nu_gft_v_officer_metrics.

-- Universal proposals data, adapted from v_mgo_activity_monthly
-- All fields needed to recreate proposals subqueries appearing throughout the original file
Cursor c_universal_proposals_data Is
  Select p.proposal_id
    , a.assignment_id_number
    , a.assignment_type
    , a.active_ind As assignment_active_ind
    , p.active_ind As proposal_active_ind
    , p.proposal_type
    , Case When p.proposal_type = '01' Then 'Y' End
      As outright_gift_proposal
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

-- Choose a proposal date based on date of record
-- Refactor all subqueries in lines 78-124
-- 7 clones, at 205-251, 332-378, 459-505, 855-901, 991-1037, 1127-1173, 1263-1309
Cursor c_proposal_dates Is
  With
  proposal_dates_data As (
    -- In determining which date to use, evaluate outright gifts and pledges first and then if necessary
    -- use the date from a pledge payment.
      Select proposal_id
        , 1 As rank
        , min(prim_gift_date_of_record) As date_of_record -- gifts
      From primary_gift
      Where proposal_id Is Not Null
        And proposal_id != 0
        And pledge_payment_ind = 'N'
      Group By proposal_id
    Union
      Select proposal_id
        , 2 As rank
        , min(prim_gift_date_of_record) As date_of_record -- pledge payments
      From primary_gift
      Where proposal_id Is Not Null
        And proposal_id != 0
        And pledge_payment_ind = 'Y'
      Group By proposal_id
    Union
      Select proposal_id
          , 1 As rank
          , min(prim_pledge_date_of_record) As date_of_record -- pledges
        From primary_pledge
        Where proposal_id Is Not Null
          And proposal_id != 0
        Group By proposal_id
  )
  Select proposal_id
    , min(date_of_record) keep(dense_rank First Order By rank Asc)
      As date_of_record
  From proposal_dates_data
  Group By proposal_id
  ;

-- Refactor goal 1 subqueries in lines 11-77
-- 3 clones, at 138-204, 265-331, 392-458
-- Credit for asked & funded proposals
-- Count for funded proposal goal 1
Cursor c_funded_count Is
  With
  proposals_funded_count As (
    -- Must be proposal manager, funded status, and above the ask & funded credit thresholds
    Select *
    From table(tbl_universal_proposals_data)
    Where assignment_type = 'PA' -- Proposal Manager
      And ask_amt >= metrics_pkg.mg_ask_amt
      And granted_amt >= metrics_pkg.mg_funded_count
      And proposal_status_code = '7' -- Only funded
  )
  , funded_count As (
      -- 1st priority - Look across all proposal managers on a proposal (inactive OR active).
      -- If there is ONE proposal manager only, credit that for that proposal ID.
      Select proposal_id
        , assignment_id_number
        , 1 As info_rank
      From proposals_funded_count
      Where proposalManagerCount = 1 -- only one proposal manager/ credit that PA
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
  Select Distinct proposal_id
    , assignment_id_number
  From funded_count
  ;
  
-- Refactor goal 3 subqueries in lines 848-982
-- 3 clones, at 984-1170, 1120-1254, 1256-1390
-- Gift credit for funded proposal goal 3
Cursor c_funded_dollars Is
  With
  proposals_funded_cr As (
    Select
      upd.*
      -- Must be proposal manager, funded status, and above the ask & granted amount thresholds
      , Case
          When ask_amt >= metrics_pkg.mg_ask_amt
            And granted_amt >= metrics_pkg.mg_granted_amt
            Then 'Y'
          Else 'N'
        End
        As funded_credit_flag
    From table(tbl_universal_proposals_data) upd
    Where assignment_type = 'PA' -- Proposal Manager
      And granted_amt >= 0
      And proposal_status_code = '7' -- Only funded
  )
  , funded_credit As (
      -- 1st priority - Look across all proposal managers on a proposal (inactive OR active).
      -- If there is ONE proposal manager only, credit that for that proposal ID.
      Select proposal_id
        , assignment_id_number
        , granted_amt
        , funded_credit_flag
        , 1 As info_rank
      From proposals_funded_cr
      Where proposalManagerCount = 1 -- only one proposal manager/ credit that PA
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
  Select proposal_id
    , assignment_id_number
    , max(funded_credit_flag)
      As funded_credit_flag
    , max(granted_amt) keep(dense_rank First Order By info_rank Asc)
      As granted_amt
  From funded_credit
  Group By proposal_id
    , assignment_id_number
  ;
  
-- Refactor goal 2 subqueries in lines 518-590
-- 3 clones, at 602-674, 686-758, 769-841
-- Count for asked proposal goal 2
Cursor c_asked_count Is
  -- Must be proposal manager and above the ask credit threshold
  With
  proposals_asked_count As (
    Select *
    From table(tbl_universal_proposals_data)
    Where assignment_type = 'PA' -- Proposal Manager
      And ask_amt >= metrics_pkg.mg_ask_amt
  )
  , asked_count As (
      -- 1st priority - Look across all proposal managers on a proposal (inactive OR active).
      -- If there is ONE proposal manager only, credit that for that proposal ID.
      Select proposal_id
        , assignment_id_number
        , initial_contribution_date
        , proposal_stop_date
        , 1 As info_rank
      From proposals_asked_count
      Where proposalManagerCount = 1 -- only one proposal manager/ credit that PA 
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
  ;

-- KSM asked count: asks must be for an outright gift >= mg_ask_amt_ksm_outright
-- or for a pledge >= mg_ask_amt_ksm_plg
Cursor c_asked_count_ksm Is
  -- Must be proposal manager and above the ask credit threshold
  With
  proposals_asked_count As (
    Select *
    From table(tbl_universal_proposals_data)
    Where assignment_type = 'PA' -- Proposal Manager
      And (
        -- Any gift type above overall threshold
        ask_amt >= metrics_pkg.mg_ask_amt_ksm_plg
        -- Outright asks above outright threshold
        Or (
          ask_amt >= metrics_pkg.mg_ask_amt_ksm_outright
          And outright_gift_proposal = 'Y'
        )
      )
  )
  , asked_count As (
      -- 1st priority - Look across all proposal managers on a proposal (inactive OR active).
      -- If there is ONE proposal manager only, credit that for that proposal ID.
      Select proposal_id
        , assignment_id_number
        , initial_contribution_date
        , proposal_stop_date
        , 1 As info_rank
      From proposals_asked_count
      Where proposalManagerCount = 1 -- only one proposal manager/ credit that PA 
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
  ;

-- Contact report data
-- Fields to recreate contact report calculations used in goals 4 and 5
-- Corresponds to subqueries in lines 1392-1448
Cursor c_contact_reports Is
  Select Distinct author_id_number
    , report_id
    , contact_purpose_code
    , extract(year From contact_date)
      As cal_year
    , rpt_pbh634.ksm_pkg.get_fiscal_year(contact_date)
      As fiscal_year
    , extract(month From contact_date)
      As cal_month
    , rpt_pbh634.ksm_pkg.get_quarter(contact_date, 'fisc')
      As fiscal_qtr
    , rpt_pbh634.ksm_pkg.get_quarter(contact_date, 'perf')
      As perf_quarter
    , rpt_pbh634.ksm_pkg.get_performance_year(contact_date)
      As perf_year -- performance year
  From contact_report
  Where contact_type = 'V' -- Only count visits
  ;
  
-- Deduped contact report credit and author IDs
Cursor c_contact_count Is
    Select
      id_number
      , report_id
    From contact_rpt_credit
    Where contact_credit_type = '1' -- Primary credit only
  Union
    Select
      author_id_number
      , report_id
    From table(tbl_contact_reports)
  ;

-- Refactor goal 6 subqueries in lines 1456-1489
-- 3 clones, at 1501-1534, 1546-1579, 1591-1624
Cursor c_assist_count Is
  With
  -- Count for proposal assists goal 6
  proposal_assists_count As (
    -- Must be proposal assist; no dollar threshold
    Select *
    From table(tbl_universal_proposals_data)
    Where assignment_type = 'AS' -- Proposal Assist
  )
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
  ;

/*************************************************************************
Functions
*************************************************************************/

Function get_constant(const_name In varchar2)
  Return number Deterministic Is
  -- Declarations
  val number;
  var varchar2(100);
  
  Begin
    -- If const_name doesn't include metrics_pkg, prepend it
    If substr(lower(const_name), 1, 12) <> 'metrics_pkg.'
      Then var := 'metrics_pkg.' || const_name;
    Else
      var := const_name;
    End If;
    -- Run command
    Execute Immediate
      'Begin :val := ' || var || '; End;'
      Using Out val;
      Return val;
  End;

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
  
-- Pipelined function determining proposal date
Function tbl_proposal_dates
  Return t_proposal_dates Pipelined As
    -- Declarations
    pd t_proposal_dates;

  Begin
    Open c_proposal_dates; -- Annual Fund allocations cursor
      Fetch c_proposal_dates Bulk Collect Into pd;
    Close c_proposal_dates;
    -- Pipe out the data
    For i in 1..(pd.count) Loop
      Pipe row(pd(i));
    End Loop;
    Return;
  End;

-- Pipelined function returning proposal funded data
Function tbl_funded_count
  Return t_funded_credit Pipelined As
    -- Declarations
    pd t_funded_credit;

  Begin
    Open c_funded_count; -- Annual Fund allocations cursor
      Fetch c_funded_count Bulk Collect Into pd;
    Close c_funded_count;
    -- Pipe out the data
    For i in 1..(pd.count) Loop
      Pipe row(pd(i));
    End Loop;
    Return;
  End;

-- Pipelined function returning proposal funded amounts data
Function tbl_funded_dollars
  Return t_funded_dollars Pipelined As
    -- Declarations
    pd t_funded_dollars;

  Begin
    Open c_funded_dollars; -- Annual Fund allocations cursor
      Fetch c_funded_dollars Bulk Collect Into pd;
    Close c_funded_dollars;
    -- Pipe out the data
    For i in 1..(pd.count) Loop
      Pipe row(pd(i));
    End Loop;
    Return;
  End;

-- Pipelined function returning proposal asked data
Function tbl_asked_count
  Return t_ask_assist_credit Pipelined As
    -- Declarations
    pd t_ask_assist_credit;

  Begin
    Open c_asked_count; -- Annual Fund allocations cursor
      Fetch c_asked_count Bulk Collect Into pd;
    Close c_asked_count;
    -- Pipe out the data
    For i in 1..(pd.count) Loop
      Pipe row(pd(i));
    End Loop;
    Return;
  End;
  
Function tbl_asked_count_ksm
  Return t_ask_assist_credit Pipelined As
    -- Declarations
    pd t_ask_assist_credit;

  Begin
    Open c_asked_count_ksm; -- Annual Fund allocations cursor
      Fetch c_asked_count_ksm Bulk Collect Into pd;
    Close c_asked_count_ksm;
    -- Pipe out the data
    For i in 1..(pd.count) Loop
      Pipe row(pd(i));
    End Loop;
    Return;
  End;

-- Pipelined function returning visits data
Function tbl_contact_reports
  Return t_contact_report Pipelined As
    -- Declarations
    cd t_contact_report;

  Begin
    Open c_contact_reports; -- Annual Fund allocations cursor
      Fetch c_contact_reports Bulk Collect Into cd;
    Close c_contact_reports;
    -- Pipe out the data
    For i in 1..(cd.count) Loop
      Pipe row(cd(i));
    End Loop;
    Return;
  End;

-- Pipelined function returning visits data
Function tbl_contact_count
  Return t_contact_count Pipelined As
    -- Declarations
    cd t_contact_count;

  Begin
    Open c_contact_count; -- Annual Fund allocations cursor
      Fetch c_contact_count Bulk Collect Into cd;
    Close c_contact_count;
    -- Pipe out the data
    For i in 1..(cd.count) Loop
      Pipe row(cd(i));
    End Loop;
    Return;
  End;

-- Pipelined function returning proposal assists data
Function tbl_assist_count
  Return t_ask_assist_credit Pipelined As
    -- Declarations
    pd t_ask_assist_credit;

  Begin
    Open c_assist_count; -- Annual Fund allocations cursor
      Fetch c_assist_count Bulk Collect Into pd;
    Close c_assist_count;
    -- Pipe out the data
    For i in 1..(pd.count) Loop
      Pipe row(pd(i));
    End Loop;
    Return;
  End;

End metrics_pkg;
/
