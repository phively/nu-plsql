With

pledge_bal As (
  Select NULL
  From DUAL
/*  Select
    id_number
    , report_name
    , min(next_unpaid_sched_dt) As next_unpaid_sched_dt
    , sum(balance_cfy) As pledge_balance_cfy
  From v_ksm_pledge_balances
  Group By
    id_number
    , report_name*/
)

-- CFY pledge balances + KGS + hh count

, gs As (
  Select
    kgs.*
--    , pledge_bal.pledge_balance_cfy
--    , pledge_bal.next_unpaid_sched_dt
  From mv_ksm_giving_summary kgs
--  Left Join pledge_bal
--    On pledge_bal.id_number = kgs.id_number
  Where
    kgs.expendable_pfy1 >= 10E3
    Or kgs.expendable_pfy2 >= 10E3
    Or kgs.expendable_pfy3 >= 10E3
    Or kgs.expendable_pfy4 >= 10E3
)

/*-- Prospect interests
, interests As (
  Select Distinct
    interest.id_number
    , interest.interest_code As interest_code
    , tms_interest.short_desc As interest_desc
  From interest
  Inner Join tms_interest
    On tms_interest.interest_code = interest.interest_code
  Inner Join gs
    On gs.id_number = interest.id_number
  Where tms_interest.interest_code Like 'L%' -- Any LinkedIn Industry Code
    Or tms_interest.interest_code = '16'  --Research Code
)

, interests_concat As (
  Select
    id_number
    , Listagg(interest_desc, '; ') Within Group (Order By id_number)
      As interests_concat
  From interests
  Group By id_number
)
*/

Select
  gs.household_id
  , mve.is_deceased_indicator
  , mve.household_primary
  , mve.person_or_org
  , Case
      When mve.is_deceased_indicator = 'Y'
        Then NULL
      When mve.household_primary = 'Y'
        Or hh.household_spouse_donor_id Is Null
        Then 'Y'
      End
    As hh_filter
  , Case
      When gs.last_cash_date >= cal.curr_fy_start
        Then gs.last_cash_date
      End
    As gave_as_of
  , cc.committees_and_roles
  , cc.committee_start_dates
  , NULL
    As discussed
  , NULL
    As next_step_owner
  , hh.household_account_name
  , gs.household_primary_donor_id
  , gs.household_primary_full_name
  , gs.household_spouse_donor_id
  , gs.household_spouse_full_name
  , hh.household_first_ksm_year
  , hh.household_program_group
  , mve.preferred_address_city
  , mve.preferred_address_state
  --, interests_concat.interests_concat
  , dd.research_evaluation
  , dd.university_overall_rating
  , mva.ksm_manager_flag
  , mva.prospect_manager_name
  , mva.lagm_name
  , gs.expendable_cfy As expendable_fy25
  , gs.expendable_pfy1 As expendable_fy24
  , gs.expendable_pfy2 As expendable_fy23
  , gs.expendable_pfy3 As expendable_fy22
  , gs.expendable_pfy4 As expendable_fy21
  , gs.ngc_lifetime As ksm_lifetime_giving
  , gs.cash_lifetime As ksm_lifetime_cash
  --, gs.pledge_balance_cfy
  --, gs.next_unpaid_sched_dt
  , gs.last_cash_tx_id
  , gs.last_cash_date
  , gs.last_cash_opportunity_type
  , gs.last_cash_designation
  , gs.last_cash_recognition_credit
From gs
Cross Join v_current_calendar cal
Inner Join mv_entity mve
  On mve.household_id = gs.household_id
Inner Join mv_households hh
  On hh.household_id = mve.household_id
Left Join mv_assignments mva
  On mva.donor_id = mve.donor_id
Left Join v_committees_concat cc
  On cc.donor_id = mve.donor_id
Left Join dm_alumni.dim_donor dd
  On dd.donor_id = mve.donor_id
--Left Join interests_concat
--  On interests_concat.id_number = gs.id_number
;

