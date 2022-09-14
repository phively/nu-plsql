create or replace view v_ksm_reunion_giving_mod as
With hh_giving As (
  Select *
  -- Replace this with rpt_pbh634.v_ksm_giving_trans_hh for live data
  -- Replace this with rpt_pbh634.tmp_mv_hhgt for a data snapshot (runs in ~20 sec)
  From rpt_pbh634.v_ksm_giving_trans_hh give
)

/* Steps

1. Create Pledge Year Subquery: This will create a subquery for pledges
2. Create Pledge Pay AMT Subquery: Use HH giving as base, do a case when using pledge year subquery is less than the fiscal year AND
Transaction Type is only pledge payments. This will = pledge pay total
3. Create Pledge Final Subquery: Combines the pledge year and pledge pay by inner joing and using x sequence
4. Create a subquery TMP (Transactions Minus Pledge Payments)
5. Use HH as the base and join your pledge final and TMP subquery
*/

--- #1 Pledge Year
, pledge_year As (
  Select Distinct -- Need distinct to dedupe
    gt.tx_number
--    , pledge.pledge_donor_id -- This is just creating duplicate rows
    , gt.tx_sequence
    , gt.fiscal_year -- This is the year of the pledge PAYMENT
    , pledge.pledge_date_of_record -- This is the date of record of the PLEDGE
    , pledge.pledge_year_of_giving -- This is the year of the PLEDGE
  From rpt_pbh634.v_ksm_giving_trans gt
  Inner Join pledge On pledge.pledge_pledge_number = gt.pledge_number -- I want to grab pledge date of record
  Where gt.tx_gypm_ind = 'Y' -- We are only pulling pledge payments
)

-- #2: create a subquery computing giving amounts for all pledge payments
, pledge_pay_amt As (
  Select
    give.household_id
    , give.household_rpt_name
    , give.tx_number
    , give.tx_sequence
    , give.tx_gypm_ind
    , give.fiscal_year
    , pledge_year.pledge_year_of_giving
    , give.hh_credit
    -- Check whether it is a pledge; if pledge, always count the full amount
    , Case
        When tx_gypm_ind <> 'Y'
          Then hh_credit
        When tx_gypm_ind = 'Y'
          Then
          Case
            When give.fiscal_year > pledge_year.pledge_year_of_giving
              Then hh_credit
            Else 0
          End
        End
     As hh_credit_adjusted
  From hh_giving give
  Left Join pledge_year On pledge_year.tx_number = give.tx_number
    And pledge_year.tx_sequence = give.tx_sequence -- Need to include this, not just tx_number; remember we had to dedupe in the first subquery
  Cross Join rpt_pbh634.v_current_calendar cal
)

-- #3 Pledge Final: now that we have a hh_credit_adjusted we can just sum across that and should get the right amount

, pledge_final As (
Select
  give.household_id
  , give.household_rpt_name
  , sum(Case When give.fiscal_year = cal.curr_fy Then hh_credit_adjusted Else 0 End) As pledge_pay_cfy
  , sum(Case When give.fiscal_year = cal.curr_fy - 1 Then hh_credit_adjusted Else 0 End) As pledge_pay_pfy1
  , sum(Case When give.fiscal_year = cal.curr_fy - 2 Then hh_credit_adjusted Else 0 End) As pledge_pay_pfy2
  , sum(Case When give.fiscal_year = cal.curr_fy - 3 Then hh_credit_adjusted Else 0 End) As pledge_pay_pfy3
  , sum(Case When give.fiscal_year = cal.curr_fy - 4 Then hh_credit_adjusted Else 0 End) As pledge_pay_pfy4
  , sum(Case When give.fiscal_year = cal.curr_fy - 5 Then hh_credit_adjusted Else 0 End) As pledge_pay_pfy5
From pledge_pay_amt give
Cross Join rpt_pbh634.v_current_calendar cal
Group By
  give.household_id
  , give.household_rpt_name
)


--- -- #4 Transactions minus pledge payments

, TMP AS
    (select
     gfts.household_id
    , sum(Case When gfts.tx_gypm_ind != 'Y'  And gfts.fiscal_year = cal.curr_fy Then hh_credit Else 0 End) As modified_cfy_hh_credit
    , count (Distinct Case When gfts.tx_gypm_ind != 'Y'  And gfts.fiscal_year = cal.curr_fy Then gfts.TX_NUMBER End) As cfy_giving_yr_count
    , sum(Case When gfts.tx_gypm_ind != 'Y'  And gfts.fiscal_year = cal.curr_fy - 1 Then hh_credit Else 0 End) As modified_pfy1_hh_credit
    , count (Distinct Case When gfts.tx_gypm_ind != 'Y'  And gfts.fiscal_year = cal.curr_fy - 1 Then gfts.TX_NUMBER End) As pfy1_giving_yr_count
    , sum(Case When gfts.tx_gypm_ind != 'Y'  And gfts.fiscal_year = cal.curr_fy - 2 Then hh_credit Else 0 End) As modified_pfy2_hh_credit
    , count(Distinct Case When gfts.tx_gypm_ind != 'Y'  And gfts.fiscal_year = cal.curr_fy - 2 Then gfts.TX_NUMBER End) As pfy2_giving_yr_count
    , sum(Case When gfts.tx_gypm_ind != 'Y'  And gfts.fiscal_year = cal.curr_fy - 3 Then hh_credit Else 0 End) As modified_pfy3_hh_credit
    , count(Distinct Case When gfts.tx_gypm_ind != 'Y'  And gfts.fiscal_year = cal.curr_fy - 3 Then gfts.TX_NUMBER End) As pfy3_giving_yr_count
    , sum(Case When gfts.tx_gypm_ind != 'Y' And gfts.fiscal_year = cal.curr_fy - 4 Then hh_credit Else 0 End) As modified_pfy4_hh_credit
    , count(Distinct Case When gfts.tx_gypm_ind != 'Y'  And gfts.fiscal_year = cal.curr_fy - 4 Then gfts.TX_NUMBER End) As pfy4_giving_yr_count
    , sum(Case When gfts.tx_gypm_ind != 'Y' And gfts.fiscal_year = cal.curr_fy - 5 Then hh_credit Else 0 End) As modified_pfy5_hh_credit
    , count(Distinct Case When gfts.tx_gypm_ind != 'Y' And gfts.fiscal_year = cal.curr_fy - 5 Then gfts.TX_NUMBER End) As pfy5_giving_yr_count
    from hh_giving gfts
    Cross Join rpt_pbh634.v_current_calendar cal
    Group By gfts.household_id)

--- # 5 Use the HH as Base and join the subqueries

  Select Distinct
      hh.household_id
    , hh.household_rpt_name
    --- Recalculated Pledge Totals
    , pledge_final.pledge_pay_cfy as pledge_modified_cfy
    , pledge_final.pledge_pay_pfy1 as pledge_modified_pfy1
    , pledge_final.pledge_pay_pfy2 as pledge_modified_pfy2
    , pledge_final.pledge_pay_pfy3 as pledge_modified_pfy3
    , pledge_final.pledge_pay_pfy4 as pledge_modified_pfy4
    , pledge_final.pledge_pay_pfy5 as pledge_modified_pfy5
    --- Recalculated Giving Totals Minus Pledge (Totals Each Year and Count of Gifts)
    , TMP.modified_cfy_hh_credit as modified_hh_credit_cfy
    , TMP.cfy_giving_yr_count as modified_hh_gift_count_cfy
    , TMP.modified_pfy1_hh_credit as modified_hh_gift_credit_pfy1
    , TMP.pfy1_giving_yr_count as modified_hh_gift_count_pfy1
    , TMP.modified_pfy2_hh_credit as modified_hh_gift_credit_pfy2
    , TMP.pfy2_giving_yr_count as modified_hh_gift_count_pfy2
    , TMP.modified_pfy3_hh_credit as modified_hh_gift_credit_pfy3
    , TMP.pfy3_giving_yr_count as modified_hh_gift_count_pfy3
    , TMP.modified_pfy4_hh_credit as modified_hh_gift_credit_pfy4
    , TMP.pfy4_giving_yr_count as modified_hh_gift_count_pfy4
    , TMP.modified_pfy5_hh_credit as modified_hh_gift_credit_pfy5
    , TMP.pfy5_giving_yr_count as modified_hh_gift_count_pfy5
From hh_giving hh
Left Join TMP On TMP.household_id = hh.household_id
Left Join pledge_final on pledge_final.household_id = hh.household_id
Order By household_id
;
