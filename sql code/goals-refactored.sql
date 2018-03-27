/******** Refactored version of ADVANCE_NU.NU_GFT_V_OFFICER_METRICS ********/

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
    , a.active_ind As assignment_active_ind
    , p.active_ind As proposal_active_ind
    , p.ask_amt
    , p.granted_amt
    , p.proposal_status_code
    , p.initial_contribution_date
    , p.stop_date As proposal_stop_date
    , a.stop_date As assignment_stop_date
    , count(*) Over(Partition By a.proposal_id) As proposalManagerCount
  From proposal p
  Inner Join assignment a
    On a.proposal_id = p.proposal_id
  Where a.assignment_type = 'PA' -- Proposal Manager
    And a.assignment_id_number != ' '
    And p.ask_amt >= (Select param_ask_amt From custom_params)
    And p.proposal_status_code In ('C', '5', '7', '8') -- submitted/approved/declined/funded
)
-- Count for funded proposal goals
, proposals_funded_count As (
  -- Must be funded status and above the funded credit threshold
  Select *
  From universal_proposals_data
  Where granted_amt >= (Select param_funded_count From custom_params)
    And proposal_status_code = '7' -- Only funded
)
-- Gift credit for funded proposal goals
, proposals_funded_cr As (
  -- Must be funded status, and above the granted amount threshold
  Select *
  From universal_proposals_data
  Where granted_amt >= (Select param_granted_amt From custom_params)
    And proposal_status_code = '7' -- Only funded
)

/**** Contact report data ****/
-- Fields to recreate contact report calculations used in goals 4 and 5
-- Corresponds to subqueries in lines 1392-1448
, contact_reports As (
  Select Distinct author_id_number
    , report_id
    , contact_purpose_code
    , Case
        When extract(month From contact_date) < 9 Then extract(year From contact_date)
        Else extract(year From contact_date) + 1
      End As c_year -- fiscal year
    , decode(
        to_char(contact_date, 'MM')
        , '01', '2', '02',  '2'
        , '03', '3', '04', '3', '05', '3'
        , '06', '4', '07', '4', '08', '4'
        , '09', '1', '10', '1', '11', '1'
        , '12', '2'
        , NULL
      ) As fiscal_qtr
     From contact_report
     Where contact_type = 'V' -- Only count visits
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
      , 1 As info_rank
    From universal_proposals_data
    Where proposalManagerCount = 1 ----- only one proposal manager/ credit that PA 
  Union
    -- 2nd priority - For #2 if there is more than one active proposal managers on a proposal credit BOTH and exit the process.
    Select proposal_id
      , assignment_id_number
      , initial_contribution_date
      , 2 As info_rank
    From universal_proposals_data
    Where assignment_active_ind = 'Y'
  Union
    -- 3rd priority - For #3, Credit all inactive proposal managers where proposal stop date and assignment stop date within 24 hours
    Select proposal_id
      , assignment_id_number
      , initial_contribution_date
      , 3 As info_rank
    From universal_proposals_data
    Where proposal_active_ind = 'N' -- Inactives on the proposal.
      And proposal_stop_date - assignment_stop_date <= 1
  Order By info_rank
)
, pr2 As (
  Select proposal_id
    , assignment_id_number
    , min(initial_contribution_date) keep(dense_rank First Order By info_rank Asc)
      As initial_contribution_date
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

/**** Main query goal 1, equivalent to lines 4-511 in nu_gft_v_officer_metrics ****/
Select g.year
 , g.id_number
 , 'MGC' goal_type
 , to_number(nu_sys_f_getquarter(pd.date_of_record)) As quarter
 , g.goal_1 As goal
 , Count(Distinct fcd.proposal_id) As cnt
From goal g
Inner Join funded_count_distinct fcd
  On fcd.assignment_id_number = g.id_number
Inner Join proposal_dates pd
  On pd.proposal_id = fcd.proposal_id
Where g.year = nu_sys_f_getfiscalyear(pd.date_of_record)
Group By g.year
  , g.id_number
  , nu_sys_f_getquarter(pd.date_of_record)
  , g.goal_1
Union
/**** Main query goal 2, equivalent to lines 512-847 in nu_gft_v_officer_metrics ****/
Select g.year
  , g.id_number
  , 'MGS' As goal_type
  , to_number(nu_sys_f_getquarter(pr2.initial_contribution_date)) As quarter
  , g.goal_2 As goal
  , Count(Distinct pr2.proposal_id) As cnt
From goal g
Inner Join pr2
  On pr2.assignment_id_number = g.id_number
Where g.year = nu_sys_f_getfiscalyear(pr2.initial_contribution_date) -- initial_contribution_date is 'ask_date'
Group By g.year
  , g.id_number
  , nu_sys_f_getquarter(pr2.initial_contribution_date)
  , g.goal_2
Union
/**** Main query goal 3, equivalent to lines 848-1391 in nu_gft_v_officer_metrics ****/
Select g.year
  , g.id_number
  , 'MGDR' As goal_type
  , to_number(nu_sys_f_getquarter(pd.date_of_record)) As quarter
  , g.goal_3 As goal
  , sum(fr.granted_amt) As cnt
From goal g
Inner Join funded_ranked fr
  On fr.assignment_id_number = g.id_number
Inner Join proposal_dates pd
  On pd.proposal_id = fr.proposal_id
Where g.year = nu_sys_f_getfiscalyear(pd.date_of_record)
Group By g.year
  , g.id_number
  , nu_sys_f_getquarter(pd.date_of_record)
  , g.goal_3
Union
/**** Main query goal 4, equivalent to lines 1392-1419 in nu_gft_v_officer_metrics ****/
Select Distinct g.year
  , g.id_number
  , 'NOV' as goal_type
  , to_number(c.fiscal_qtr) As quarter
  , g.goal_4 As goal
  , count(Distinct c.report_id) As cnt
From contact_reports c
Inner Join contact_rpt_credit cr
  On cr.report_id = c.report_id
Inner Join goal g
  On g.id_number = c.author_id_number
    Or g.id_number = cr.id_number
Where cr.contact_credit_type = '1' -- Primary credit only
  And g.year = c.c_year
Group By g.year
  , c.fiscal_qtr
  , g.id_number
  , g.goal_4
Union
/**** Main query goal 5, equivalent to lines 1420-1448 in nu_gft_v_officer_metrics ****/
Select Distinct g.year
  , g.id_number
  , 'NOQV' As goal_type
  , to_number(c.fiscal_qtr) As quarter
  , g.goal_5 As goal
  , count(Distinct c.report_id) As cnt
From contact_reports c
Inner Join contact_rpt_credit cr
  On cr.report_id = c.report_id
Inner Join goal g
  On g.id_number = c.author_id_number
    Or g.id_number = cr.id_number
Where c.contact_purpose_code = '1' -- Only count qualification visits
  And cr.contact_credit_type = '1' -- Primary credit only
  And g.year = c.c_year
Group By g.year
  , c.fiscal_qtr
  , g.id_number
  , g.goal_5
Union
/**** Main query goal 6, equivalent to lines 1449-1627 in nu_gft_v_officer_metrics ****/
SELECT g.year,
       g.id_number,
       'PA' as goal_type,
       1 as quarter,
       g.goal_6 as goal,
       count(distinct(pr.proposal_id)) cnt
  FROM goal g,
       (SELECT e1.proposal_id,
               e1.assignment_id_number,
               e1.initial_contribution_date
          FROM (SELECT e.proposal_id,
                       e.assignment_id_number,
                       e.initial_contribution_date,
                       row_number() over(partition by e.proposal_id, e.assignment_id_number ORDER BY e.info_rank) proposal_rank,
                       e.info_rank
                  FROM ( -- Any active proposals (1st priority)
                        SELECT p.proposal_id,
                                a.assignment_id_number,
                                p.initial_contribution_date,
                                1 as info_rank
                          FROM proposal p, assignment a
                         WHERE a.proposal_id = p.proposal_id
                           AND a.assignment_type = 'AS' -- Proposal Assist
                           AND a.active_ind = 'Y'
                           AND p.proposal_status_code IN ('C', '5', '7', '8') --submitted/approved/declined/funded
                           AND nu_sys_f_getquarter(p.initial_contribution_date) = 1
                        UNION
                        -- If no active proposals, then any inactive proposals where proposal stop date and assignment stop date within 24 hours  (2nd priority)
                        SELECT p.proposal_id,
                               a.assignment_id_number,
                               p.initial_contribution_date,
                               2 as info_rank
                          FROM proposal p, assignment a
                         WHERE a.proposal_id = p.proposal_id
                           AND a.assignment_type = 'AS' -- Proposal Assist
                           AND a.active_ind = 'N'
                           AND p.proposal_status_code IN ('C', '5', '7', '8') --submitted/approved/declined/funded
                           AND nu_sys_f_getquarter(p.initial_contribution_date) = 1
                           AND p.stop_date - a.stop_date <= 1
                         ORDER BY info_rank) e) e1
         WHERE e1.proposal_rank = 1) pr
 WHERE g.id_number = pr.assignment_id_number
   AND g.year = nu_sys_f_getfiscalyear(pr.initial_contribution_date) -- initial_contribution_date is 'ask_date'
 GROUP BY g.year, g.id_number, g.goal_6
UNION
SELECT g.year,
       g.id_number,
       'PA' as goal_type,
       2 as quarter,
       g.goal_6 as goal,
       count(distinct(pr.proposal_id)) cnt
  FROM goal g,
       (SELECT e1.proposal_id,
               e1.assignment_id_number,
               e1.initial_contribution_date
          FROM (SELECT e.proposal_id,
                       e.assignment_id_number,
                       e.initial_contribution_date,
                       row_number() over(partition by e.proposal_id, e.assignment_id_number ORDER BY e.info_rank) proposal_rank,
                       e.info_rank
                  FROM ( -- Any active proposals (1st priority)
                        SELECT p.proposal_id,
                                a.assignment_id_number,
                                p.initial_contribution_date,
                                1 as info_rank
                          FROM proposal p, assignment a
                         WHERE a.proposal_id = p.proposal_id
                           AND a.assignment_type = 'AS' -- Proposal Assist
                           AND a.active_ind = 'Y'
                           AND p.proposal_status_code IN ('C', '5', '7', '8') --submitted/approved/declined/funded
                           AND nu_sys_f_getquarter(p.initial_contribution_date) = 2
                        UNION
                        -- If no active proposals, then any inactive proposals where proposal stop date and assignment stop date within 24 hours  (2nd priority)
                        SELECT p.proposal_id,
                               a.assignment_id_number,
                               p.initial_contribution_date,
                               2 as info_rank
                          FROM proposal p, assignment a
                         WHERE a.proposal_id = p.proposal_id
                           AND a.assignment_type = 'AS' -- Proposal Assist
                           AND a.active_ind = 'N'
                           AND p.proposal_status_code IN ('C', '5', '7', '8') --submitted/approved/declined/funded
                           AND nu_sys_f_getquarter(p.initial_contribution_date) = 2
                           AND p.stop_date - a.stop_date <= 1
                         ORDER BY info_rank) e) e1
         WHERE e1.proposal_rank = 1) pr
 WHERE g.id_number = pr.assignment_id_number
   AND g.year = nu_sys_f_getfiscalyear(pr.initial_contribution_date) -- initial_contribution_date is 'ask_date'
 GROUP BY g.year, g.id_number, g.goal_6
UNION
SELECT g.year,
       g.id_number,
       'PA' as goal_type,
       3 as quarter,
       g.goal_6 as goal,
       count(distinct(pr.proposal_id)) cnt
  FROM goal g,
       (SELECT e1.proposal_id,
               e1.assignment_id_number,
               e1.initial_contribution_date
          FROM (SELECT e.proposal_id,
                       e.assignment_id_number,
                       e.initial_contribution_date,
                       row_number() over(partition by e.proposal_id, e.assignment_id_number ORDER BY e.info_rank) proposal_rank,
                       e.info_rank
                  FROM ( -- Any active proposals (1st priority)
                        SELECT p.proposal_id,
                                a.assignment_id_number,
                                p.initial_contribution_date,
                                1 as info_rank
                          FROM proposal p, assignment a
                         WHERE a.proposal_id = p.proposal_id
                           AND a.assignment_type = 'AS' -- Proposal Assist
                           AND a.active_ind = 'Y'
                           AND p.proposal_status_code IN ('C', '5', '7', '8') --submitted/approved/declined/funded
                           AND nu_sys_f_getquarter(p.initial_contribution_date) = 3
                        UNION
                        -- If no active proposals, then any inactive proposals where proposal stop date and assignment stop date within 24 hours  (2nd priority)
                        SELECT p.proposal_id,
                               a.assignment_id_number,
                               p.initial_contribution_date,
                               2 as info_rank
                          FROM proposal p, assignment a
                         WHERE a.proposal_id = p.proposal_id
                           AND a.assignment_type = 'AS' -- Proposal Assist
                           AND a.active_ind = 'N'
                           AND p.proposal_status_code IN ('C', '5', '7', '8') --submitted/approved/declined/funded
                           AND nu_sys_f_getquarter(p.initial_contribution_date) = 3
                           AND p.stop_date - a.stop_date <= 1
                         ORDER BY info_rank) e) e1
         WHERE e1.proposal_rank = 1) pr
 WHERE g.id_number = pr.assignment_id_number
   AND g.year = nu_sys_f_getfiscalyear(pr.initial_contribution_date) -- initial_contribution_date is 'ask_date'
 GROUP BY g.year, g.id_number, g.goal_6
UNION
SELECT g.year,
       g.id_number,
       'PA' as goal_type,
       4 as quarter,
       g.goal_6 as goal,
       count(distinct(pr.proposal_id)) cnt
  FROM goal g,
       (SELECT e1.proposal_id,
               e1.assignment_id_number,
               e1.initial_contribution_date
          FROM (SELECT e.proposal_id,
                       e.assignment_id_number,
                       e.initial_contribution_date,
                       row_number() over(partition by e.proposal_id, e.assignment_id_number ORDER BY e.info_rank) proposal_rank,
                       e.info_rank
                  FROM ( -- Any active proposals (1st priority)
                        SELECT p.proposal_id,
                                a.assignment_id_number,
                                p.initial_contribution_date,
                                1 as info_rank
                          FROM proposal p, assignment a
                         WHERE a.proposal_id = p.proposal_id
                           AND a.assignment_type = 'AS' -- Proposal Assist
                           AND a.active_ind = 'Y'
                           AND p.proposal_status_code IN ('C', '5', '7', '8') --submitted/approved/declined/funded
                           AND nu_sys_f_getquarter(p.initial_contribution_date) = 4
                        UNION
                        -- If no active proposals, then any inactive proposals where proposal stop date and assignment stop date are within 24 hours  (2nd priority)
                        SELECT p.proposal_id,
                               a.assignment_id_number,
                               p.initial_contribution_date,
                               2 as info_rank
                          FROM proposal p, assignment a
                         WHERE a.proposal_id = p.proposal_id
                           AND a.assignment_type = 'AS' -- Proposal Assist
                           AND a.active_ind = 'N'
                           AND p.proposal_status_code IN ('C', '5', '7', '8') --submitted/approved/declined/funded
                           AND nu_sys_f_getquarter(p.initial_contribution_date) = 4
                           AND p.stop_date - a.stop_date <= 1
                         ORDER BY info_rank) e) e1
         WHERE e1.proposal_rank = 1) pr
 WHERE g.id_number = pr.assignment_id_number
   AND g.year = nu_sys_f_getfiscalyear(pr.initial_contribution_date) -- initial_contribution_date is 'ask_date'
 GROUP BY g.year, g.id_number, g.goal_6
/* Sort results */
Order By id_number
  , year
  , quarter
;
