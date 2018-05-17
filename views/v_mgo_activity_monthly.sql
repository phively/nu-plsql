/***********************************************************************************************
Tweak original v_mgo_goals_monthly to show activity even in months/years without a goal entered
***********************************************************************************************/

Create Or Replace View v_mgo_activity_monthly As

With

/**** If any of the parameters ever change, update them here ****/
custom_params As (
  Select
/********************* UPDATE BELOW HERE *********************/
       100000 As param_ask_amt -- As of 2018-03-23
    ,   48000 As param_granted_amt -- As of 2018-03-23
    ,   98000 As param_funded_count -- As of 2018-03-23
/********************* UPDATE ABOVE HERE *********************/
  From DUAL
)

/**** Universal proposals data ****/
-- All fields needed to recreate proposals subqueries appearing throughout the original file
, universal_proposals_data As (
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
)
-- Count for funded proposal goal 1
, proposals_funded_count As (
  -- Must be proposal manager, funded status, and above the ask & funded credit thresholds
  Select *
  From universal_proposals_data
  Where assignment_type = 'PA' -- Proposal Manager
    And ask_amt >= (Select param_ask_amt From custom_params)
    And granted_amt >= (Select param_funded_count From custom_params)
    And proposal_status_code = '7' -- Only funded
)
-- Count for asked proposal goal 2
, proposals_asked_count As (
  -- Must be proposal manager and above the ask credit threshold
  Select *
  From universal_proposals_data
  Where assignment_type = 'PA' -- Proposal Manager
    And ask_amt >= (Select param_ask_amt From custom_params)
)
-- Gift credit for funded proposal goal 3
, proposals_funded_cr As (
  -- Must be proposal manager, funded status, and above the ask & granted amount thresholds
  Select *
  From universal_proposals_data
  Where assignment_type = 'PA' -- Proposal Manager
    And ask_amt >= (Select param_ask_amt From custom_params)
    And granted_amt >= (Select param_granted_amt From custom_params)
    And proposal_status_code = '7' -- Only funded
)
-- Count for proposal assists goal 6
, proposal_assists_count As (
  -- Must be proposal assist; no dollar threshold
  Select *
  From universal_proposals_data
  Where assignment_type = 'AS' -- Proposal Assist
)

/**** Contact report data ****/
-- Fields to recreate contact report calculations used in goals 4 and 5
-- Corresponds to subqueries in lines 1392-1448
, contact_reports As (
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
)
-- Deduped contact report credit and author IDs
, cr_credit As (
    Select
      id_number
      , report_id
    From contact_rpt_credit
    Where contact_credit_type = '1' -- Primary credit only
  Union
    Select
      author_id_number
      , report_id
    From contact_reports
)

/**** Refactor goal 1 subqueries in lines 11-77 ****/
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

/**** Refactor all subqueries in lines 78-124 ****/
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

/**** Refactor goal 2 subqueries in lines 518-590 ****/
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

/**** Refactor goal 3 subqueries in lines 848-982 ****/
-- 3 clones, at 984-1170, 1120-1254, 1256-1390
, funded_credit As (
    -- 1st priority - Look across all proposal managers on a proposal (inactive OR active).
    -- If there is ONE proposal manager only, credit that for that proposal ID.
    Select proposal_id
      , assignment_id_number
      , granted_amt
      , 1 As info_rank
    From proposals_funded_cr
    Where proposalManagerCount = 1 ----- only one proposal manager/ credit that PA
  Union
    -- 2nd priority - For #2 if there is more than one active proposal managers on a proposal credit BOTH and exit the process.
    Select proposal_id
       , assignment_id_number
       , granted_amt
       , 2 As info_rank
    From proposals_funded_cr
    Where assignment_active_ind = 'Y'
  Union
    -- 3rd priority - For #3, Credit all inactive proposal managers where proposal stop date and assignment stop date within 24 hours
    Select proposal_id
       , assignment_id_number
       , granted_amt
       , 3 As info_rank
    From proposals_funded_cr
    Where proposal_active_ind = 'N' -- Inactives on the proposal.
      And proposal_stop_date - assignment_stop_date <= 1
  Order By info_rank
)
, funded_ranked As (
  Select proposal_id
    , assignment_id_number
    , max(granted_amt) keep(dense_rank First Order By info_rank Asc)
      As granted_amt
  From funded_credit
  Group By proposal_id
    , assignment_id_number
)

/**** Refactor goal 6 subqueries in lines 1456-1489 ****/
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

----- Main query goal 1, equivalent to lines 4-511 in nu_gft_v_officer_metrics -----
Select fcd.assignment_id_number As id_number
  , e.report_name
  , 'MGC' As goal_type
  , 'MG Closes' As goal_desc
  , extract(year From pd.date_of_record) As cal_year
  , extract(month From pd.date_of_record) As cal_month
  , rpt_pbh634.ksm_pkg.get_fiscal_year(pd.date_of_record) As fiscal_year
  , rpt_pbh634.ksm_pkg.get_quarter(pd.date_of_record, 'fisc') As fiscal_quarter
  , rpt_pbh634.ksm_pkg.get_performance_year(pd.date_of_record) As perf_year
  , rpt_pbh634.ksm_pkg.get_quarter(pd.date_of_record, 'perf') As perf_quarter
  , g.goal_1 As fy_goal
  , pyg.goal_1 As py_goal
  , Count(Distinct fcd.proposal_id) As progress
  , Count(Distinct fcd.proposal_id) As adjusted_progress
From funded_count_distinct fcd
Inner Join entity e On e.id_number = fcd.assignment_id_number
Inner Join proposal_dates pd
  On pd.proposal_id = fcd.proposal_id
-- Fiscal year goals
Left Join goal g
  On fcd.assignment_id_number = g.id_number
    And g.year = rpt_pbh634.ksm_pkg.get_fiscal_year(pd.date_of_record)
-- Performance year goals
Left Join goal pyg
  On fcd.assignment_id_number = pyg.id_number
    And pyg.year = rpt_pbh634.ksm_pkg.get_performance_year(pd.date_of_record)
Group By rpt_pbh634.ksm_pkg.get_fiscal_year(pd.date_of_record)
  , fcd.assignment_id_number
  , e.report_name
  , extract(year From pd.date_of_record)
  , extract(month From pd.date_of_record)
  , rpt_pbh634.ksm_pkg.get_quarter(pd.date_of_record, 'fisc')
  , rpt_pbh634.ksm_pkg.get_quarter(pd.date_of_record, 'perf')
  , rpt_pbh634.ksm_pkg.get_performance_year(pd.date_of_record)
  , g.goal_1
  , pyg.goal_1
Union
----- Main query goal 2, equivalent to lines 512-847 in nu_gft_v_officer_metrics -----
Select acr.assignment_id_number As id_number
  , e.report_name
  , 'MGS' As goal_type
  , 'MG Sols' As goal_desc
  , extract(year From acr.ask_or_stop_dt) As cal_year
  , extract(month From acr.ask_or_stop_dt) As cal_month
  , rpt_pbh634.ksm_pkg.get_fiscal_year(acr.ask_or_stop_dt) As fiscal_year
  , rpt_pbh634.ksm_pkg.get_quarter(acr.ask_or_stop_dt, 'fisc') As fiscal_quarter
  , rpt_pbh634.ksm_pkg.get_performance_year(acr.ask_or_stop_dt) As perf_year
  , rpt_pbh634.ksm_pkg.get_quarter(acr.ask_or_stop_dt, 'perf') As perf_quarter
  , g.goal_2 As fy_goal
  , pyg.goal_2 As py_goal
  -- Original definition: count only if ask date is filled in
  , Count(Distinct Case When acr.initial_contribution_date Is Not Null Then acr.proposal_id End)
    As progress
  -- Alternate definition: count if either ask date or stop date is filled in
  , Count(Distinct acr.proposal_id) As adjusted_progress
From asked_count_ranked acr
Inner Join entity e On e.id_number = acr.assignment_id_number
-- Fiscal year goals
Left Join goal g
  On acr.assignment_id_number = g.id_number
    And g.year = rpt_pbh634.ksm_pkg.get_fiscal_year(acr.ask_or_stop_dt)
-- Performance year goals
Left Join goal pyg
  On acr.assignment_id_number = pyg.id_number
    And pyg.year = rpt_pbh634.ksm_pkg.get_performance_year(acr.ask_or_stop_dt)
Group By rpt_pbh634.ksm_pkg.get_fiscal_year(acr.ask_or_stop_dt)
  , acr.assignment_id_number
  , e.report_name
  , extract(year From acr.ask_or_stop_dt)
  , extract(month From acr.ask_or_stop_dt)
  , rpt_pbh634.ksm_pkg.get_quarter(acr.ask_or_stop_dt, 'fisc')
  , rpt_pbh634.ksm_pkg.get_quarter(acr.ask_or_stop_dt, 'perf')
  , rpt_pbh634.ksm_pkg.get_performance_year(acr.ask_or_stop_dt)
  , g.goal_2
  , pyg.goal_2
Union
----- Main query goal 3, equivalent to lines 848-1391 in nu_gft_v_officer_metrics -----
Select fr.assignment_id_number As id_number
  , e.report_name
  , 'MGDR' As goal_type
  , 'MG Dollars Raised' As goal_desc
  , extract(year From pd.date_of_record) As cal_year
  , extract(month From pd.date_of_record) As cal_month
  , rpt_pbh634.ksm_pkg.get_fiscal_year(pd.date_of_record) As fiscal_year
  , rpt_pbh634.ksm_pkg.get_quarter(pd.date_of_record, 'fisc') As fiscal_quarter
  , rpt_pbh634.ksm_pkg.get_performance_year(pd.date_of_record) As perf_year
  , rpt_pbh634.ksm_pkg.get_quarter(pd.date_of_record, 'perf') As perf_quarter
  , g.goal_3 As fy_goal
  , pyg.goal_3 As py_goal
  , sum(fr.granted_amt) As progress
  , sum(fr.granted_amt) As adjusted_progress
From funded_ranked fr
Inner Join entity e On e.id_number = fr.assignment_id_number
Inner Join proposal_dates pd
  On pd.proposal_id = fr.proposal_id
-- Fiscal year goals
Left Join goal g
  On fr.assignment_id_number = g.id_number
    And g.year = rpt_pbh634.ksm_pkg.get_fiscal_year(pd.date_of_record)
-- Performance year goals
Left Join goal pyg
  On fr.assignment_id_number = pyg.id_number
    And pyg.year = rpt_pbh634.ksm_pkg.get_performance_year(pd.date_of_record)
Group By rpt_pbh634.ksm_pkg.get_fiscal_year(pd.date_of_record)
  , fr.assignment_id_number
  , e.report_name
  , extract(year From pd.date_of_record)
  , extract(month From pd.date_of_record)
  , rpt_pbh634.ksm_pkg.get_quarter(pd.date_of_record, 'fisc')
  , rpt_pbh634.ksm_pkg.get_quarter(pd.date_of_record, 'perf')
  , rpt_pbh634.ksm_pkg.get_performance_year(pd.date_of_record)
  , g.goal_3
  , pyg.goal_3
Union
----- Main query goal 4, equivalent to lines 1392-1419 in nu_gft_v_officer_metrics -----
Select Distinct cr.id_number As id_number
  , e.report_name
  , 'NOV' as goal_type
  , 'Visits' As goal_desc
  , c.cal_year
  , c.cal_month
  , c.fiscal_year
  , c.fiscal_qtr As fiscal_quarter
  , c.perf_year
  , c.perf_quarter
  , g.goal_4 As fy_goal
  , pyg.goal_4 As py_goal
  , count(Distinct c.report_id) As progress
  , count(Distinct c.report_id) As adjusted_progress
From cr_credit cr
Inner Join entity e On e.id_number = cr.id_number
Inner Join contact_reports c
  On cr.report_id = c.report_id
-- Fiscal year goals
Left Join goal g
  On g.id_number = cr.id_number
    And g.year = c.fiscal_year
-- Performance year goals
Left Join goal pyg
  On pyg.id_number = cr.id_number
    And pyg.year = c.perf_year
Group By c.fiscal_year
  , cr.id_number
  , e.report_name
  , c.cal_year
  , c.cal_month
  , c.fiscal_qtr
  , c.perf_quarter
  , c.perf_year
  , g.goal_4
  , pyg.goal_4
Union
----- Main query goal 5, equivalent to lines 1420-1448 in nu_gft_v_officer_metrics -----
Select Distinct cr.id_number As id_number
  , e.report_name
  , 'NOQV' As goal_type
  , 'Qual Visits' As goal_desc
  , c.cal_year
  , c.cal_month
  , c.fiscal_year
  , c.fiscal_qtr As fiscal_quarter
  , c.perf_year
  , c.perf_quarter
  , g.goal_5 As fy_goal
  , pyg.goal_5 As py_goal
  , count(Distinct c.report_id) As progress
  , count(Distinct c.report_id) As adjusted_progress
From cr_credit cr
Inner Join entity e On e.id_number = cr.id_number
Inner Join contact_reports c
  On cr.report_id = c.report_id
-- Fiscal year goals
Left Join goal g
  On g.id_number = cr.id_number
    And g.year = c.fiscal_year
-- Performance year goals
Left Join goal pyg
  On pyg.id_number = cr.id_number
    And pyg.year = c.perf_year
Where c.contact_purpose_code = '1' -- Only count qualification visits
Group By c.fiscal_year
  , cr.id_number
  , e.report_name
  , c.cal_year
  , c.cal_month
  , c.fiscal_qtr
  , c.perf_quarter
  , c.perf_year
  , g.goal_5
  , pyg.goal_5
Union
----- Main query goal 6, equivalent to lines 1449-1627 in nu_gft_v_officer_metrics -----
Select acr.assignment_id_number As id_number
  , e.report_name
  , 'PA' As goal_type
  , 'Proposal Assists' As goal_desc
  , extract(year From acr.ask_or_stop_dt) As cal_year
  , extract(month From acr.ask_or_stop_dt) As cal_month
  , rpt_pbh634.ksm_pkg.get_fiscal_year(acr.ask_or_stop_dt) As fiscal_year
  , rpt_pbh634.ksm_pkg.get_quarter(acr.ask_or_stop_dt, 'fisc') As fiscal_quarter
  , rpt_pbh634.ksm_pkg.get_performance_year(acr.ask_or_stop_dt) As perf_year
  , rpt_pbh634.ksm_pkg.get_quarter(acr.ask_or_stop_dt, 'perf') As perf_quarter
  , g.goal_6 As fy_goal
  , pyg.goal_6 As py_goal
  -- Original definition: count only if ask date is filled in
  , Count(Distinct Case When acr.initial_contribution_date Is Not Null Then acr.proposal_id End)
    As progress
  -- Alternate definition: count if either ask date or stop date is filled in
  , Count(Distinct acr.proposal_id) As adjusted_progress
From assist_count_ranked acr
Inner Join entity e On e.id_number = acr.assignment_id_number
-- Fiscal year goals
Left Join goal g
  On acr.assignment_id_number = g.id_number
    And g.year = rpt_pbh634.ksm_pkg.get_fiscal_year(acr.ask_or_stop_dt) -- initial_contribution_date is 'ask_date'
-- Performance year goals
Left Join goal pyg
  On acr.assignment_id_number = pyg.id_number
    And pyg.year = rpt_pbh634.ksm_pkg.get_performance_year(acr.ask_or_stop_dt)
Group By rpt_pbh634.ksm_pkg.get_fiscal_year(acr.ask_or_stop_dt)
  , acr.assignment_id_number
  , e.report_name
  , extract(year From acr.ask_or_stop_dt)
  , extract(month From acr.ask_or_stop_dt)
  , rpt_pbh634.ksm_pkg.get_quarter(acr.ask_or_stop_dt, 'fisc')
  , rpt_pbh634.ksm_pkg.get_quarter(acr.ask_or_stop_dt, 'perf')
  , rpt_pbh634.ksm_pkg.get_performance_year(acr.ask_or_stop_dt)
  , g.goal_6
  , pyg.goal_6
;

/***********************************************************************************************
Goals view -- monthly refactored version of ADVANCE_NU.NU_GFT_V_OFFICER_METRICS
***********************************************************************************************/

Create Or Replace View v_mgo_goals_monthly As

Select
  id_number
  , report_name
  , goal_type
  , goal_desc
  , cal_year
  , cal_month
  , fiscal_year
  , fiscal_quarter
  , perf_year
  , perf_quarter
  , fy_goal
  , py_goal
  , progress
From v_mgo_activity_monthly v
Where py_goal Is Not Null
  And progress > 0
;
