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
    mve.household_id
    , max(hh.household_account_name)
      As household_account_name
    , max(hh.household_spouse_donor_id)
      As household_spouse_donor_id
    , max(hh.household_spouse_full_name)
      As household_spouse_full_name
    , max(hh.household_last_masters_year)
      As household_last_masters_year
    , max(Case When household_last_masters_year >= cal.curr_fy - young_klc_yrs Then 'Y' End)
      As af_young_alum
    , max(Case When household_last_masters_year >= cal.curr_fy - young_klc_yrs - 1 Then 'Y' End)
      As af_young_alum1
    , max(Case When household_last_masters_year >= cal.curr_fy - young_klc_yrs - 2 Then 'Y' End)
      As af_young_alum2
    , max(Case When household_last_masters_year >= cal.curr_fy - young_klc_yrs - 3 Then 'Y' End)
      As af_young_alum3
    , sum(Case When mve.household_primary = 'Y' Then ngc.credit_amount Else 0 End) As ngc_lifetime
    , sum(Case When mve.household_primary = 'Y' Then ngc.recognition_credit Else 0 End) -- Count bequests at face value and internal transfers at > $0
      As ngc_lifetime_full_rec
    , sum(Case When mve.household_primary = 'Y' And anonymous Not In (Select Distinct anonymous_code From tms_anonymous) Then hh_recognition_credit Else 0 End)
      As ngc_lifetime_nonanon_full_rec
/*    , max(nu_giving.lifetime_giving) As nu_max_hh_lifetime_giving
    , sum(Case When tx_gypm_ind != 'P' Then hh_credit Else 0 End) As cash_lifetime
    , sum(Case When tx_gypm_ind != 'Y' And cal.curr_fy = fiscal_year     Then hh_credit Else 0 End) As ngc_cfy
    , sum(Case When tx_gypm_ind != 'Y' And cal.curr_fy = fiscal_year + 1 Then hh_credit Else 0 End) As ngc_pfy1
    , sum(Case When tx_gypm_ind != 'Y' And cal.curr_fy = fiscal_year + 2 Then hh_credit Else 0 End) As ngc_pfy2
    , sum(Case When tx_gypm_ind != 'Y' And cal.curr_fy = fiscal_year + 3 Then hh_credit Else 0 End) As ngc_pfy3
    , sum(Case When tx_gypm_ind != 'Y' And cal.curr_fy = fiscal_year + 4 Then hh_credit Else 0 End) As ngc_pfy4
    , sum(Case When tx_gypm_ind != 'Y' And cal.curr_fy = fiscal_year + 5 Then hh_credit Else 0 End) As ngc_pfy5
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year     Then hh_credit Else 0 End) As cash_cfy
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 1 Then hh_credit Else 0 End) As cash_pfy1
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 2 Then hh_credit Else 0 End) As cash_pfy2
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 3 Then hh_credit Else 0 End) As cash_pfy3
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 4 Then hh_credit Else 0 End) As cash_pfy4
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 5 Then hh_credit Else 0 End) As cash_pfy5
    -- Annual Fund cash totals
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year     And af_flag = 'Y' Then hh_credit Else 0 End) As af_cfy
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 1 And af_flag = 'Y' Then hh_credit Else 0 End) As af_pfy1
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 2 And af_flag = 'Y' Then hh_credit Else 0 End) As af_pfy2
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 3 And af_flag = 'Y' Then hh_credit Else 0 End) As af_pfy3
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 4 And af_flag = 'Y' Then hh_credit Else 0 End) As af_pfy4
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 5 And af_flag = 'Y' Then hh_credit Else 0 End) As af_pfy5
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 6 And af_flag = 'Y' Then hh_credit Else 0 End) As af_pfy6
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 7 And af_flag = 'Y' Then hh_credit Else 0 End) As af_pfy7
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 8 And af_flag = 'Y' Then hh_credit Else 0 End) As af_pfy8
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 9 And af_flag = 'Y' Then hh_credit Else 0 End) As af_pfy9
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 10 And af_flag = 'Y' Then hh_credit Else 0 End) As af_pfy10
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 11 And af_flag = 'Y' Then hh_credit Else 0 End) As af_pfy11
    -- Current Use cash totals
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year     And cru_flag = 'Y' Then hh_credit Else 0 End) As cru_cfy
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 1 And cru_flag = 'Y' Then hh_credit Else 0 End) As cru_pfy1
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 2 And cru_flag = 'Y' Then hh_credit Else 0 End) As cru_pfy2
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 3 And cru_flag = 'Y' Then hh_credit Else 0 End) As cru_pfy3
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 4 And cru_flag = 'Y' Then hh_credit Else 0 End) As cru_pfy4
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 5 And cru_flag = 'Y' Then hh_credit Else 0 End) As cru_pfy5
    -- KLC cash totals; count matching gift credit in year of matched gift
    , sum(Case When tx_gypm_ind != 'P' And cru_flag = 'Y' And (
        (cal.curr_fy = fiscal_year     And tx_gypm_ind != 'M') Or (cal.curr_fy = matched_fiscal_year     And tx_gypm_ind = 'M')
      ) Then hh_credit Else 0 End) As klc_cfy
    , sum(Case When tx_gypm_ind != 'P' And cru_flag = 'Y' And (
        (cal.curr_fy = fiscal_year + 1 And tx_gypm_ind != 'M') Or (cal.curr_fy = matched_fiscal_year + 1 And tx_gypm_ind = 'M')
      ) Then hh_credit Else 0 End) As klc_pfy1
    , sum(Case When tx_gypm_ind != 'P' And cru_flag = 'Y' And (
        (cal.curr_fy = fiscal_year + 2 And tx_gypm_ind != 'M') Or (cal.curr_fy = matched_fiscal_year + 2 And tx_gypm_ind = 'M')
      ) Then hh_credit Else 0 End) As klc_pfy2
    , sum(Case When tx_gypm_ind != 'P' And cru_flag = 'Y' And (
        (cal.curr_fy = fiscal_year + 3 And tx_gypm_ind != 'M') Or (cal.curr_fy = matched_fiscal_year + 3 And tx_gypm_ind = 'M')
      ) Then hh_credit Else 0 End) As klc_pfy3
    , sum(Case When tx_gypm_ind != 'P' And cru_flag = 'Y' And (
        (cal.curr_fy = fiscal_year + 4 And tx_gypm_ind != 'M') Or (cal.curr_fy = matched_fiscal_year + 4 And tx_gypm_ind = 'M')
      ) Then hh_credit Else 0 End) As klc_pfy4
    , sum(Case When tx_gypm_ind != 'P' And cru_flag = 'Y' And (
        (cal.curr_fy = fiscal_year + 5 And tx_gypm_ind != 'M') Or (cal.curr_fy = matched_fiscal_year + 5 And tx_gypm_ind = 'M')
      ) Then hh_credit Else 0 End) As klc_pfy5
    -- Stewardship giving, defined as new gifts and commitments plus pledge payments where the NGC was not already counted
    -- in the current year.
    -- WARNING: includes new gifts and commitments as well as cash
    , sum(Case When cal.curr_fy = fiscal_year     Then hh_stewardship_credit Else 0 End) As stewardship_cfy
    , sum(Case When cal.curr_fy = fiscal_year + 1 Then hh_stewardship_credit Else 0 End) As stewardship_pfy1
    , sum(Case When cal.curr_fy = fiscal_year + 2 Then hh_stewardship_credit Else 0 End) As stewardship_pfy2
    , sum(Case When cal.curr_fy = fiscal_year + 3 Then hh_stewardship_credit Else 0 End) As stewardship_pfy3
    , sum(Case When cal.curr_fy = fiscal_year + 4 Then hh_stewardship_credit Else 0 End) As stewardship_pfy4
    , sum(Case When cal.curr_fy = fiscal_year + 5 Then hh_stewardship_credit Else 0 End) As stewardship_pfy5
    -- Anonymous stewardship giving per FY
    -- WARNING: includes new gifts and commitments as well as cash
    , sum(Case When cal.curr_fy = fiscal_year     And anonymous <> ' ' Then hh_stewardship_credit Else 0 End) As anonymous_cfy
    , sum(Case When cal.curr_fy = fiscal_year + 1 And anonymous <> ' ' Then hh_stewardship_credit Else 0 End) As anonymous_pfy1
    , sum(Case When cal.curr_fy = fiscal_year + 2 And anonymous <> ' ' Then hh_stewardship_credit Else 0 End) As anonymous_pfy2
    , sum(Case When cal.curr_fy = fiscal_year + 3 And anonymous <> ' ' Then hh_stewardship_credit Else 0 End) As anonymous_pfy3
    , sum(Case When cal.curr_fy = fiscal_year + 4 And anonymous <> ' ' Then hh_stewardship_credit Else 0 End) As anonymous_pfy4
    , sum(Case When cal.curr_fy = fiscal_year + 5 And anonymous <> ' ' Then hh_stewardship_credit Else 0 End) As anonymous_pfy5
    -- Giving history
    , max(cal.curr_fy) As curr_fy
    , min(gfts.fiscal_year) As fy_giving_first_yr
    , max(gfts.fiscal_year) As fy_giving_last_yr
    , min(Case When tx_gypm_ind != 'P' And af_flag = 'Y' Then fiscal_year End) As fy_giving_first_yr_af
    , max(Case When tx_gypm_ind != 'P' And af_flag = 'Y' Then fiscal_year End) As fy_giving_last_yr_af
    , min(Case When tx_gypm_ind != 'P' And cru_flag = 'Y' Then fiscal_year End) As fy_giving_first_yr_cru
    , max(Case When tx_gypm_ind != 'P' And cru_flag = 'Y' Then fiscal_year End) As fy_giving_last_yr_cru
    , count(Distinct gfts.fiscal_year) As fy_giving_yr_count
    , min(Case When tx_gypm_ind != 'P' Then gfts.fiscal_year Else NULL End) As fy_giving_first_cash_yr
    , max(Case When tx_gypm_ind != 'P' Then gfts.fiscal_year Else NULL End) As fy_giving_last_cash_yr
    , count(Distinct Case When tx_gypm_ind != 'P' Then gfts.fiscal_year Else NULL End) As fy_giving_yr_cash_count
    -- Last KSM gift
    , min(gfts.tx_number) keep(dense_rank First Order By gfts.date_of_record Desc, gfts.tx_number Asc)
      As last_gift_tx_number
    , min(gfts.date_of_record) keep(dense_rank First Order By gfts.date_of_record Desc, gfts.tx_number Asc)
      As last_gift_date
    , min(gfts.transaction_type) keep(dense_rank First Order By gfts.date_of_record Desc, gfts.tx_number Asc)
      As last_gift_type
    , min(gfts.allocation_code) keep(dense_rank First Order By gfts.date_of_record Desc, gfts.tx_number Asc, gfts.alloc_short_name Asc)
      As last_gift_alloc_code
    , min(gfts.alloc_short_name) keep(dense_rank First Order By gfts.date_of_record Desc, gfts.tx_number Asc, gfts.alloc_short_name Asc)
      As last_gift_alloc
    , sum(gfts.hh_recognition_credit) keep(dense_rank First Order By gfts.date_of_record Desc, gfts.tx_number Asc)
      As last_gift_recognition_credit
    -- Largest KSM gift
    , max(gfts.tx_number)
      keep(dense_rank First Order By gfts.hh_recognition_credit Desc, gfts.date_of_record Desc, gfts.tx_number Desc, gfts.alloc_short_name Asc)
      As max_gift_tx_number
    , max(gfts.date_of_record)
      keep(dense_rank First Order By gfts.hh_recognition_credit Desc, gfts.date_of_record Desc, gfts.tx_number Desc, gfts.alloc_short_name Asc)
      As max_gift_date_of_record
    , max(gfts.allocation_code)
      keep(dense_rank First Order By gfts.hh_recognition_credit Desc, gfts.date_of_record Desc, gfts.tx_number Desc, gfts.alloc_short_name Asc)
      As max_gift_alloc_code
    , max(gfts.alloc_short_name)
      keep(dense_rank First Order By gfts.hh_recognition_credit Desc, gfts.date_of_record Desc, gfts.tx_number Desc, gfts.alloc_short_name Asc)
      As max_gift_alloc
    , max(gfts.hh_recognition_credit)
      keep(dense_rank First Order By gfts.hh_recognition_credit Desc, gfts.date_of_record Desc, gfts.tx_number Desc, gfts.alloc_short_name Asc)
      As max_gift_credit*/
  From mv_entity mve
  Cross Join v_current_calendar cal
  Cross Join params
  Left Join mv_households hh
    On hh.household_id = mve.household_id
  Left Join mv_hh_donor_count hhc
    On hhc.household_id = mve.household_id
  Left Join v_ksm_gifts_cash cash
    On cash.household_id = mve.household_id
  Left Join v_ksm_gifts_ngc ngc
    On ngc.household_id = mve.household_id
  Group By
    mve.household_id
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
