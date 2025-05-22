/*************************************************************************
Householded entity giving summaries
*************************************************************************/

--Create Or Replace View v_ksm_giving_summary As

-- View implementing Kellogg gift credit, householded, with several common types

With

-- Parameters defining KLC years/amounts
params As (
  Select
    2500 As klc_amt -- Edit this
    , 1000 As young_klc_amt -- Edit this
    , 5 As young_klc_yrs
  From DUAL
)

-- Sum transaction amounts
, trans As (
  Select Distinct
    hh.household_id
    , max(hh.household_account_name)
      As household_account_name
    , max(hh.household_spouse_donor_id)
      As household_spouse_donor_id
    , max(hh.household_spouse_full_name)
      As household_spouse_full_name
    , max(hh.household_last_masters_year)
      As household_last_masters_year
    , max(Case When hh.household_last_masters_year >= cal.curr_fy - young_klc_yrs Then 'Y' End)
      As af_young_alum
    , max(Case When hh.household_last_masters_year >= cal.curr_fy - young_klc_yrs - 1 Then 'Y' End)
      As af_young_alum1
    , max(Case When hh.household_last_masters_year >= cal.curr_fy - young_klc_yrs - 2 Then 'Y' End)
      As af_young_alum2
    , max(Case When hh.household_last_masters_year >= cal.curr_fy - young_klc_yrs - 3 Then 'Y' End)
      As af_young_alum3
    -- Lifetime giving
    , sum(ngc.hh_credit) As ngc_lifetime
    , sum(ngc.hh_recognition_credit) -- Count bequests at face value and internal transfers at > $0
      As ngc_lifetime_full_rec
    , sum(Case When ngc.anonymous_type Is Null Then ngc.hh_recognition_credit Else 0 End)
      As ngc_lifetime_nonanon_full_rec
    , sum(cash.hh_credit) As cash_lifetime
    -- Campaign totals
    , sum(Case When ngc.full_circle_campaign_priority Is Not Null Then ngc.hh_credit End) As full_circle_credit
    , sum(Case When ngc.full_circle_campaign_priority Is Not Null Then ngc.hh_recognition_credit End) As full_circle_recognition
    -- Yearly NGC totals
    , sum(Case When cal.curr_fy = ngc.fiscal_year     Then ngc.hh_credit Else 0 End) As ngc_cfy
    , sum(Case When cal.curr_fy = ngc.fiscal_year + 1 Then ngc.hh_credit Else 0 End) As ngc_pfy1
    , sum(Case When cal.curr_fy = ngc.fiscal_year + 2 Then ngc.hh_credit Else 0 End) As ngc_pfy2
    , sum(Case When cal.curr_fy = ngc.fiscal_year + 3 Then ngc.hh_credit Else 0 End) As ngc_pfy3
    , sum(Case When cal.curr_fy = ngc.fiscal_year + 4 Then ngc.hh_credit Else 0 End) As ngc_pfy4
    , sum(Case When cal.curr_fy = ngc.fiscal_year + 5 Then ngc.hh_credit Else 0 End) As ngc_pfy5
    , sum(Case When cal.curr_fy = cash.fiscal_year     Then cash.hh_countable_credit Else 0 End) As cash_cfy
    , sum(Case When cal.curr_fy = cash.fiscal_year + 1 Then cash.hh_countable_credit Else 0 End) As cash_pfy1
    , sum(Case When cal.curr_fy = cash.fiscal_year + 2 Then cash.hh_countable_credit Else 0 End) As cash_pfy2
    , sum(Case When cal.curr_fy = cash.fiscal_year + 3 Then cash.hh_countable_credit Else 0 End) As cash_pfy3
    , sum(Case When cal.curr_fy = cash.fiscal_year + 4 Then cash.hh_countable_credit Else 0 End) As cash_pfy4
    , sum(Case When cal.curr_fy = cash.fiscal_year + 5 Then cash.hh_countable_credit Else 0 End) As cash_pfy5
    -- Expendable cash totals
    , sum(Case When cash.cash_category = 'Expendable' And cal.curr_fy = cash.fiscal_year     Then cash.hh_countable_credit Else 0 End) As expendable_cfy
    , sum(Case When cash.cash_category = 'Expendable' And cal.curr_fy = cash.fiscal_year + 1 Then cash.hh_countable_credit Else 0 End) As expendable_pfy1
    , sum(Case When cash.cash_category = 'Expendable' And cal.curr_fy = cash.fiscal_year + 2 Then cash.hh_countable_credit Else 0 End) As expendable_pfy2
    , sum(Case When cash.cash_category = 'Expendable' And cal.curr_fy = cash.fiscal_year + 3 Then cash.hh_countable_credit Else 0 End) As expendable_pfy3
    , sum(Case When cash.cash_category = 'Expendable' And cal.curr_fy = cash.fiscal_year + 4 Then cash.hh_countable_credit Else 0 End) As expendable_pfy4
    , sum(Case When cash.cash_category = 'Expendable' And cal.curr_fy = cash.fiscal_year + 5 Then cash.hh_countable_credit Else 0 End) As expendable_pfy5
    -- Giving history
    , max(cal.curr_fy) As curr_fy
    , min(ngc.fiscal_year) As ngc_fy_giving_first_yr
    , max(ngc.fiscal_year) As ngc_fy_giving_last_yr
    --, count(Distinct ngc.fiscal_year) As fy_giving_yr_count_ngc
    , min(cash.fiscal_year) As cash_fy_giving_first_yr
    , max(cash.fiscal_year) As cash_fy_giving_last_yr
    --, count(Distinct cash.fiscal_year) As fy_giving_yr_count_cash
    , min(Case When cash.cash_category = 'Expendable' Then cash.fiscal_year End) As expendable_fy_giving_first_yr
    , max(Case When cash.cash_category = 'Expendable' Then cash.fiscal_year End) As expendable_fy_giving_last_yr
    -- Last KSM NGC
    , min(ngc.tx_id) keep(dense_rank First Order By ngc.credit_date Desc, ngc.tx_id Asc)
      As last_ngc_tx_id
    , min(ngc.credit_date) keep(dense_rank First Order By ngc.credit_date Desc, ngc.tx_id Asc)
      As last_ngc_date
    , min(ngc.opportunity_type) keep(dense_rank First Order By ngc.credit_date Desc, ngc.tx_id Asc)
      As last_ngc_opportunity_type
    , min(ngc.designation_record_id) keep(dense_rank First Order By ngc.credit_date Desc, ngc.tx_id Asc)
      As last_ngc_designation_id
    , min(ngc.designation_name) keep(dense_rank First Order By ngc.credit_date Desc, ngc.tx_id Asc)
      As last_ngc_designation
    , sum(ngc.hh_recognition_credit) keep(dense_rank First Order By ngc.credit_date Desc, ngc.tx_id Asc)
      As last_ngc_recognition_credit
    -- Last KSM cash
    , min(cash.tx_id) keep(dense_rank First Order By cash.credit_date Desc, cash.tx_id Asc)
      As last_cash_tx_id
    , min(cash.credit_date) keep(dense_rank First Order By cash.credit_date Desc, cash.tx_id Asc)
      As last_cash_date
    , min(cash.opportunity_type) keep(dense_rank First Order By cash.credit_date Desc, cash.tx_id Asc)
      As last_cash_opportunity_type
    , min(cash.designation_record_id) keep(dense_rank First Order By cash.credit_date Desc, cash.tx_id Asc)
      As last_cash_designation_id
    , min(cash.designation_name) keep(dense_rank First Order By cash.credit_date Desc, cash.tx_id Asc)
      As last_cash_designation
    , sum(cash.hh_recognition_credit) keep(dense_rank First Order By cash.credit_date Desc, cash.tx_id Asc)
      As last_cash_recognition_credit
    -- Largest KSM NGC
    , max(ngc.tx_id)
      keep(dense_rank First Order By ngc.unsplit_amount Desc, ngc.hh_recognition_credit Desc, ngc.credit_date Desc, ngc.tx_id Desc, ngc.designation_name Asc)
      As max_ngc_tx_number
    , max(ngc.credit_date)
      keep(dense_rank First Order By ngc.unsplit_amount Desc, ngc.hh_recognition_credit Desc, ngc.credit_date Desc, ngc.tx_id Desc, ngc.designation_name Asc)
      As max_ngc_date
    , max(ngc.opportunity_type)
      keep(dense_rank First Order By ngc.unsplit_amount Desc, ngc.hh_recognition_credit Desc, ngc.credit_date Desc, ngc.tx_id Desc, ngc.designation_name Asc)
      As max_ngc_opportunity_type
    , max(ngc.designation_record_id)
      keep(dense_rank First Order By ngc.unsplit_amount Desc, ngc.hh_recognition_credit Desc, ngc.credit_date Desc, ngc.tx_id Desc, ngc.designation_name Asc)
      As max_ngc_designation_id
    , max(ngc.designation_name)
      keep(dense_rank First Order By ngc.unsplit_amount Desc, ngc.hh_recognition_credit Desc, ngc.credit_date Desc, ngc.tx_id Desc, ngc.designation_name Asc)
      As max_ngc_designation
    , max(ngc.hh_recognition_credit)
      keep(dense_rank First Order By ngc.unsplit_amount Desc, ngc.hh_recognition_credit Desc, ngc.credit_date Desc, ngc.tx_id Desc, ngc.designation_name Asc)
      As max_ngc_recognition_credit
    , max(ngc.unsplit_amount)
      keep(dense_rank First Order By ngc.unsplit_amount Desc, ngc.hh_recognition_credit Desc, ngc.credit_date Desc, ngc.tx_id Desc, ngc.designation_name Asc)
      As max_ngc_unsplit_amount
    -- Anonymous flag
    , Case
        When max(cash.anonymous_type) Is Not Null
          Or max(ngc.anonymous_type) Is Not Null
          Then 'Y'
        End
      As anonymous_flag
  From mv_households hh
  Cross Join v_current_calendar cal
  Cross Join params
  Left Join v_ksm_gifts_cash cash
    On cash.household_id = hh.household_id
  Left Join v_ksm_gifts_ngc ngc
    On ngc.household_id = hh.household_id
  -- Donors only
  Where
    cash.donor_id Is Not Null
    Or ngc.donor_id Is Not Null
  Group By
    hh.household_id
)
-- Main query
Select
  trans.*
  -- AF status categorizer
  , Case
      When expendable_cfy > 0 Then 'Donor'
      When expendable_pfy1 > 0 Then 'LYBUNT'
      When expendable_pfy2 + expendable_pfy3 + expendable_pfy4 > 0 Then 'PYBUNT'
      When expendable_cfy + expendable_pfy1 + expendable_pfy2 + expendable_pfy3 + expendable_pfy4 = 0 Then 'Lapsed'
      When expendable_fy_giving_first_yr Is Null Then 'Non'
    End As expendable_status
  -- Expendable giving status last year
  , Case
      When expendable_pfy1 > 0 Then 'LYBUNT'
      When expendable_pfy2 + expendable_pfy3 + expendable_pfy4 > 0 Then 'PYBUNT'
      When expendable_pfy1 + expendable_pfy2 + expendable_pfy3 + expendable_pfy4 = 0 Then 'Lapsed'
      When expendable_fy_giving_first_yr Is Null
        Or expendable_fy_giving_first_yr = curr_fy
        Then 'Non'
    End As expendable_status_fy_start
  -- Expendable giving status last year
  , Case
      When expendable_pfy2 > 0 Then 'LYBUNT'
      When expendable_pfy3 + expendable_pfy4 + expendable_pfy5 > 0 Then 'PYBUNT'
      When expendable_pfy2 + expendable_pfy3 + expendable_pfy4 + expendable_pfy5 = 0 Then 'Lapsed'
      When expendable_fy_giving_first_yr Is Null
        Or expendable_fy_giving_first_yr = curr_fy - 1
        Then 'Non'
    End As expendable_status_pfy1_start
From trans
Cross Join params
;
