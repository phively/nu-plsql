Create Or Replace Package metrics_pkg Is

/*************************************************************************
Author  : PBH634
Created : 2/13/2020 11:19:42 AM
  Initial CatConnect update 11/20/2025
Purpose : Consolidated gift officer metrics definitions to allow audit
  information to be easily pulled. Adapted from rpt_pbh634.v_mgo_activity_monthly
  and advance_nu.nu_gft_v_officer_metrics.
Dependencies: ksm_pkg_proposals (mv_proposals)
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
  proposal_record_id mv_proposals.proposal_record_id%type
  , historical_pm_user_id mv_proposals.historical_pm_user_id%type
  , historical_pm_name mv_proposals.historical_pm_name%type
  , historical_pm_role mv_proposals.historical_pm_role%type
  , historical_pm_business_unit mv_proposals.historical_pm_business_unit%type
  , ksm_flag mv_proposals.ksm_flag%type
  , historical_pm_is_active mv_proposals.historical_pm_is_active%type
  , proposal_active_indicator mv_proposals.proposal_active_indicator%type
  , proposal_type mv_proposals.proposal_type%type
  , standard_proposal_flag varchar2(1)
  , proposal_submitted_amount mv_proposals.proposal_submitted_amount%type
  , proposal_funded_amount mv_proposals.proposal_funded_amount%type
  , proposal_stage mv_proposals.proposal_stage%type
  , proposal_created_date mv_proposals.proposal_created_date%type
  , proposal_submitted_date mv_proposals.proposal_submitted_date%type
  , proposal_close_date mv_proposals.proposal_close_date%type
);

Type funded_credit Is Record (
  proposal_record_id mv_proposals.proposal_record_id%type
  , historical_pm_user_id mv_proposals.historical_pm_user_id%type
  , historical_pm_name mv_proposals.historical_pm_name%type
  , historical_pm_role mv_proposals.historical_pm_role%type
  , historical_pm_business_unit mv_proposals.historical_pm_business_unit%type
  , ksm_flag mv_proposals.ksm_flag%type
);
/*
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
Type t_funded_credit Is Table Of funded_credit;
/*Type t_funded_dollars Is Table Of funded_dollars;
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
From table(rpt_pbh634.ksm_pkg_tmp.tbl_alloc_annual_fund_ksm) ksm_af;
Select cal.*
From table(rpt_pbh634.ksm_pkg_tmp.tbl_current_calendar) cal;
*************************************************************************/

-- Standardized proposal data table function
Function tbl_universal_proposals_data
  Return t_proposals_data Pipelined;
  
-- Table functions for each of the MGO metrics
Function tbl_funded_count(
    ask_amt number default metrics_pkg.mg_ask_amt
    , funded_count number default metrics_pkg.mg_funded_count
  )
  Return t_funded_credit Pipelined;
/*
Function tbl_funded_dollars(
    ask_amt number default metrics_pkg.mg_ask_amt
    , granted_amt number default metrics_pkg.mg_granted_amt
  )
  Return t_funded_dollars Pipelined;

Function tbl_asked_count(
    ask_amt number default metrics_pkg.mg_ask_amt
  )
  Return t_ask_assist_credit Pipelined;

Function tbl_asked_count_ksm(
    ask_amt_ksm_plg number default metrics_pkg.mg_ask_amt_ksm_plg
    , ask_amt_ksm_outright number default metrics_pkg.mg_ask_amt_ksm_outright
  )
  Return t_ask_assist_credit Pipelined;

Function tbl_contact_reports
  Return t_contact_report Pipelined;

Function tbl_contact_count
  Return t_contact_count Pipelined;

Function tbl_assist_count
  Return t_ask_assist_credit Pipelined;
*/
End metrics_pkg;
/
Create Or Replace Package Body metrics_pkg Is

/*************************************************************************
Private cursor tables -- data definitions; update indicated sections as needed
*************************************************************************/

-- Universal proposals data, originally adapted from v_mgo_activity_monthly
-- All fields needed to recreate proposals subqueries appearing throughout the original file
Cursor c_universal_proposals_data Is
  Select
    p.proposal_record_id
    , p.historical_pm_user_id
    , p.historical_pm_name
    , p.historical_pm_role
    , p.historical_pm_business_unit
    , p.ksm_flag
    , p.historical_pm_is_active
    , p.proposal_active_indicator
    , p.proposal_type
    , Case When p.proposal_type = 'Standard' Then 'Y' End
      As standard_proposal_flag
    , p.proposal_submitted_amount
    , p.proposal_funded_amount
    , p.proposal_stage
    , p.proposal_created_date
    , p.proposal_submitted_date
    , p.proposal_close_date
  From mv_proposals p
  Where p.historical_pm_name Is Not Null
    And p.proposal_stage In (
      'Submitted', 'Approved by Donor', 'Declined', 'Funded'
    )
;

-- Credit for asked & funded proposals
-- Count for funded proposal goal 1
Cursor c_funded_count(
      ask_amt_in In number
      , funded_count_in In number
    ) Is
    
  With
  
  proposals_funded_count As (
    -- Must be proposal manager, funded status, and above the ask & funded credit thresholds
    Select *
    From table(metrics_pkg.tbl_universal_proposals_data) upd
    Where historical_pm_role = 'Proposal Manager'
      And proposal_submitted_amount >= ask_amt_in
      And proposal_funded_amount >= funded_count_in
      And proposal_stage = 'Funded'
  )
  
  Select Distinct
    proposal_record_id
    , historical_pm_user_id
    , historical_pm_name
    , historical_pm_role
    , historical_pm_business_unit
    , ksm_flag
  From proposals_funded_count
;
  
/*-- Refactor goal 3 subqueries in lines 848-982
-- 3 clones, at 984-1170, 1120-1254, 1256-1390
-- Gift credit for funded proposal goal 3
Cursor c_funded_dollars(
    ask_amt_in In number
    , granted_amt_in In number
  ) Is
  With
  proposals_funded_cr As (
    Select
      upd.*
      -- Must be proposal manager, funded status, and above the ask & granted amount thresholds
      , Case
          When ask_amt >= ask_amt_in
            And granted_amt >= granted_amt_in
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
Cursor c_asked_count(
    ask_amt_in In number
  ) Is
  -- Must be proposal manager and above the ask credit threshold
  With
  proposals_asked_count As (
    Select *
    From table(tbl_universal_proposals_data)
    Where assignment_type = 'PA' -- Proposal Manager
      And ask_amt >= ask_amt_in
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
Cursor c_asked_count_ksm(
    ask_amt_ksm_plg_in In number
    , ask_amt_ksm_outright_in In number
  ) Is
  -- Must be proposal manager and above the ask credit threshold
  With
  proposals_asked_count As (
    Select *
    From table(tbl_universal_proposals_data)
    Where assignment_type = 'PA' -- Proposal Manager
      And (
        -- Any gift type above overall threshold
        ask_amt >= ask_amt_ksm_plg_in
        -- Outright asks above outright threshold
        Or (
          ask_amt >= ask_amt_ksm_outright_in
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
    , rpt_pbh634.ksm_pkg_calendar.get_fiscal_year(contact_date)
      As fiscal_year
    , extract(month From contact_date)
      As cal_month
    , rpt_pbh634.ksm_pkg_calendar.get_quarter(contact_date, 'fisc')
      As fiscal_qtr
    , rpt_pbh634.ksm_pkg_calendar.get_quarter(contact_date, 'perf')
      As perf_quarter
    , rpt_pbh634.ksm_pkg_calendar.get_performance_year(contact_date)
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

-- Pipelined function returning proposal funded data
Function tbl_funded_count(
    ask_amt number default metrics_pkg.mg_ask_amt
    , funded_count number default metrics_pkg.mg_funded_count
  )
  Return t_funded_credit Pipelined As
    -- Declarations
    pd t_funded_credit;

  Begin
    Open c_funded_count(
      ask_amt_in => ask_amt
      , funded_count_in => funded_count
    ); -- Annual Fund allocations cursor
      Fetch c_funded_count Bulk Collect Into pd;
    Close c_funded_count;
    -- Pipe out the data
    For i in 1..(pd.count) Loop
      Pipe row(pd(i));
    End Loop;
    Return;
  End;

/*-- Pipelined function returning proposal funded amounts data
Function tbl_funded_dollars(
    ask_amt number default metrics_pkg.mg_ask_amt
    , granted_amt number default metrics_pkg.mg_granted_amt
  )
  Return t_funded_dollars Pipelined As
    -- Declarations
    pd t_funded_dollars;

  Begin
    Open c_funded_dollars(
    ask_amt_in => ask_amt
    , granted_amt_in => granted_amt
  ); -- Annual Fund allocations cursor
      Fetch c_funded_dollars Bulk Collect Into pd;
    Close c_funded_dollars;
    -- Pipe out the data
    For i in 1..(pd.count) Loop
      Pipe row(pd(i));
    End Loop;
    Return;
  End;
/*
-- Pipelined function returning proposal asked data
Function tbl_asked_count(
    ask_amt number default metrics_pkg.mg_ask_amt
  )
  Return t_ask_assist_credit Pipelined As
    -- Declarations
    pd t_ask_assist_credit;

  Begin
    Open c_asked_count(
      ask_amt_in => ask_amt
    ); -- Annual Fund allocations cursor
      Fetch c_asked_count Bulk Collect Into pd;
    Close c_asked_count;
    -- Pipe out the data
    For i in 1..(pd.count) Loop
      Pipe row(pd(i));
    End Loop;
    Return;
  End;
  
Function tbl_asked_count_ksm(
    ask_amt_ksm_plg number default metrics_pkg.mg_ask_amt_ksm_plg
    , ask_amt_ksm_outright number default metrics_pkg.mg_ask_amt_ksm_outright
  )
  Return t_ask_assist_credit Pipelined As
    -- Declarations
    pd t_ask_assist_credit;

  Begin
    Open c_asked_count_ksm(
      ask_amt_ksm_plg_in => ask_amt_ksm_plg
      , ask_amt_ksm_outright_in => ask_amt_ksm_outright
    ); -- Annual Fund allocations cursor
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
*/
End metrics_pkg;
/
