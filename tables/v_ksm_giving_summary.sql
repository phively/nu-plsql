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
--, trans As (
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
    , sum(ngc.hh_credit) As ngc_lifetime
    , sum(ngc.hh_recognition_credit) -- Count bequests at face value and internal transfers at > $0
      As ngc_lifetime_full_rec
    , sum(Case When ngc.anonymous_type Is Null Then ngc.hh_recognition_credit Else 0 End)
      As ngc_lifetime_nonanon_full_rec
    , sum(cash.hh_credit) As cash_lifetime
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
/*)
-- Main query
Select
  trans.*
  -- AF status categorizer
  , Case
      When af_cfy > 0 Then 'Donor'
      When af_pfy1 > 0 Then 'LYBUNT'
      When af_pfy2 + af_pfy3 + af_pfy4 > 0 Then 'PYBUNT'
      When af_cfy + af_pfy1 + af_pfy2 + af_pfy3 + af_pfy4 = 0 Then 'Lapsed'
      When fy_giving_first_yr_af Is Null Then 'Non'
    End As af_status
  -- AF status last year
  , Case
      When af_pfy1 > 0 Then 'LYBUNT'
      When af_pfy2 + af_pfy3 + af_pfy4 > 0 Then 'PYBUNT'
      When af_pfy1 + af_pfy2 + af_pfy3 + af_pfy4 = 0 Then 'Lapsed'
      When fy_giving_first_yr_af Is Null
        Or fy_giving_first_yr_af = curr_fy
        Then 'Non'
    End As af_status_fy_start
  -- AF status last year
  , Case
      When af_pfy2 > 0 Then 'LYBUNT'
      When af_pfy3 + af_pfy4 + af_pfy5 > 0 Then 'PYBUNT'
      When af_pfy2 + af_pfy3 + af_pfy4 + af_pfy5 = 0 Then 'Lapsed'
      When fy_giving_first_yr_af Is Null
        Or fy_giving_first_yr_af = curr_fy - 1
        Then 'Non'
    End As af_status_pfy1_start
  -- AF KLC flag
  , Case
      When klc_cfy >= klc_amt
        Then 'Y'
      When af_young_alum = 'Y'
        And klc_cfy >= young_klc_amt
        Then 'Y'
      End
    As klc_current
  -- AF KLC LYBUNT flag
  , Case
      When klc_pfy1 >= klc_amt
        Then 'Y'
      When af_young_alum = 'Y'
        And klc_pfy1 >= young_klc_amt
        Then 'Y'
      When af_young_alum1 = 'Y'
        And klc_pfy1 >= young_klc_amt
        Then 'Y'
      End
    As klc_lybunt
  -- AF giving segment
  , Case
      -- $2500+ for 3 years is KLC
      When cru_pfy1 >= klc_amt
        And cru_pfy2 >= klc_amt
        And cru_pfy3 >= klc_amt
          Then 'KLC Loyal 3+'
      -- Check for KLC young alum loyal
      When af_young_alum = 'Y'
        And cru_pfy1 >= young_klc_amt
        And cru_pfy2 >= young_klc_amt
        And cru_pfy3 >= young_klc_amt
          Then 'KLC YA Loyal 3+'
      -- Check for KLC young alum -1 loyal
      When af_young_alum1 = 'Y'
        And cru_pfy1 >= young_klc_amt
        And cru_pfy2 >= young_klc_amt
        And cru_pfy3 >= young_klc_amt
          Then 'KLC YA1 Loyal 3+'
      -- Check for KLC young alum -2 loyal
      When af_young_alum2 = 'Y'
        And cru_pfy1 >= klc_amt
        And cru_pfy2 >= young_klc_amt
        And cru_pfy3 >= young_klc_amt
          Then 'KLC YA2 Loyal 3+'
      -- Check for KLC young alum -3 loyal
      When af_young_alum3 = 'Y'
        And cru_pfy1 >= klc_amt
        And cru_pfy2 >= klc_amt
        And cru_pfy3 >= young_klc_amt
          Then 'KLC YA3 Loyal 3+'
      -- $2500+ 2 of 3 is KLC loyal
      When (cru_pfy1 >= klc_amt And cru_pfy2 >= klc_amt)
        Or (cru_pfy1 >= klc_amt And cru_pfy3 >= klc_amt)
        Or (cru_pfy2 >= klc_amt And cru_pfy3 >= klc_amt)
          Then 'KLC Loyal 2 of 3'
      -- Check for KLC young alum loyal
      When af_young_alum = 'Y'
        And (
          (cru_pfy1 >= young_klc_amt And cru_pfy2 >= young_klc_amt)
          Or (cru_pfy1 >= young_klc_amt And cru_pfy3 >= young_klc_amt)
          Or (cru_pfy2 >= young_klc_amt And cru_pfy3 >= young_klc_amt)
        )
          Then 'KLC YA Loyal 2 of 3'
      -- Check for KLC young alum -1 loyal
      When af_young_alum1 = 'Y'
        And (
          (cru_pfy1 >= young_klc_amt And cru_pfy2 >= young_klc_amt)
          Or (cru_pfy1 >= young_klc_amt And cru_pfy3 >= young_klc_amt)
          Or (cru_pfy2 >= young_klc_amt And cru_pfy3 >= young_klc_amt)
        )
          Then 'KLC YA1 Loyal 2 of 3'
      -- Check for KLC young alum -2 loyal
      When af_young_alum2 = 'Y'
        And (
          (cru_pfy1 >= klc_amt And cru_pfy2 >= young_klc_amt)
          Or (cru_pfy1 >= klc_amt And cru_pfy3 >= young_klc_amt)
          Or (cru_pfy2 >= young_klc_amt And cru_pfy3 >= young_klc_amt)
        )
          Then 'KLC YA2 Loyal 2 of 3'
      -- Check for KLC young alum -3 loyal
      When af_young_alum3 = 'Y'
        And (
          (cru_pfy1 >= klc_amt And cru_pfy2 >= klc_amt)
          Or (cru_pfy1 >= klc_amt And cru_pfy3 >= young_klc_amt)
          Or (cru_pfy2 >= klc_amt And cru_pfy3 >= young_klc_amt)
        )
          Then 'KLC YA3 Loyal 2 of 3'
      -- KLC LYBUNT designation
      When cru_pfy1 >= klc_amt
        Then 'KLC LYBUNT'
      When af_young_alum = 'Y'
        And cru_pfy1 >= young_klc_amt
          Then 'KLC YA LYBUNT'
      When af_young_alum1 = 'Y'
        And cru_pfy1 >= young_klc_amt
          Then 'KLC YA1 LYBUNT'
      When af_young_alum2 = 'Y'
        And cru_pfy1 >= klc_amt
          Then 'KLC YA2 LYBUNT'
      When af_young_alum3 = 'Y'
        And cru_pfy1 >= klc_amt
          Then 'KLC YA3 LYBUNT'
      -- KLC PYBUNT designation
      When cru_pfy2 >= klc_amt
        Or cru_pfy3 >= klc_amt
        Or cru_pfy4 >= klc_amt
        Or cru_pfy5 >= klc_amt
          Then 'KLC PYBUNT'
      -- KLC YA PYBUNT designation
      When af_young_alum = 'Y'
        And (
          cru_pfy2 >= young_klc_amt
          Or cru_pfy3 >= young_klc_amt
          Or cru_pfy4 >= young_klc_amt
          Or cru_pfy5 >= young_klc_amt
        )
          Then 'KLC YA PYBUNT'
      -- KLC YA PYBUNT -1
      When af_young_alum1 = 'Y'
        And (
          cru_pfy2 >= young_klc_amt
          Or cru_pfy3 >= young_klc_amt
          Or cru_pfy4 >= young_klc_amt
          Or cru_pfy5 >= young_klc_amt
        )
          Then 'KLC YA1 PYBUNT'
      -- KLC YA PYBUNT -2
      When af_young_alum2 = 'Y'
        And (
          cru_pfy2 >= young_klc_amt
          Or cru_pfy3 >= young_klc_amt
          Or cru_pfy4 >= young_klc_amt
          Or cru_pfy5 >= young_klc_amt
        )
          Then 'KLC YA2 PYBUNT'
      -- KLC YA PYBUNT -3
      When af_young_alum3 = 'Y'
        And (
          cru_pfy2 >= klc_amt
          Or cru_pfy3 >= young_klc_amt
          Or cru_pfy4 >= young_klc_amt
          Or cru_pfy5 >= young_klc_amt
        )
          Then 'KLC YA3 PYBUNT'
      -- 3 years in a row is loyal
      When cru_pfy1 > 0
        And cru_pfy2 > 0
        And cru_pfy3 > 0
          Then 'Loyal 3+'
      -- 2 of 3 is loyal
      When (cru_pfy1 > 0 And cru_pfy2 > 0)
        Or (cru_pfy1 > 0 And cru_pfy3 > 0)
        Or (cru_pfy2 > 0 And cru_pfy3 > 0)
          Then 'Loyal 2 of 3'
      -- Standard designation
      When cru_pfy1 > 0
        Then 'LYBUNT'
      When cru_pfy2 > 0
        Then 'PYBUNT-2'
      When cru_pfy3 > 0
        Then 'PYBUNT-3'
      When cru_pfy4 > 0
        Then 'PYBUNT-4'
      When cru_pfy1 + cru_pfy2 + cru_pfy3 + cru_pfy4 = 0
        And fy_giving_first_yr_cru Is Not Null
        And fy_giving_first_yr_cru < curr_fy
        Then 'Lapsed'
      Else 'Non'
      End
    As af_giving_segment
  -- Stewardship flags
  , shc.ksm_stewardship_issue
  -- Anonymous flags
  , shc.anonymous_donor
  , Case When anonymous_cfy > 0 Then 'Y' End As anonymous_cfy_flag
  , Case When anonymous_pfy1 > 0 Then 'Y' End As anonymous_pfy1_flag
  , Case When anonymous_pfy2 > 0 Then 'Y' End As anonymous_pfy2_flag
  , Case When anonymous_pfy3 > 0 Then 'Y' End As anonymous_pfy3_flag
  , Case When anonymous_pfy4 > 0 Then 'Y' End As anonymous_pfy4_flag
  , Case When anonymous_pfy5 > 0 Then 'Y' End As anonymous_pfy5_flag
From trans
Cross Join params
Left Join table(ksm_pkg_special_handling.tbl_special_handling_concat) shc
  On shc.id_number = trans.id_number
;*/
