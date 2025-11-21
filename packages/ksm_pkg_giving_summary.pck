Create Or Replace Package ksm_pkg_giving_summary Is

/*************************************************************************
Author  : PBH634
Created : 11/21/2025
Purpose : Giving summary view for all donors to Kellogg.
Dependencies: v_ksm_gifts_ngc, v_ksm_gifts_cash, ksm_pkg_calendar (v_current_calendar),
  ksm_pkg_degrees (mv_entity_ksm_degrees), ksm_pkg_households (mv_households),
  ksm_pkg_gifts (mv_ksm_transactions)

Suggested naming conventions:
  Pure functions: [function type]_[description]
  Row-by-row retrieval (slow): get_[object type]_[action or description] e.g.
  Table or cursor retrieval (fast): tbl_[object type]_[action or description]
*************************************************************************/

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_giving_summary';

/*************************************************************************
Public type declarations
*************************************************************************/

--------------------------------------
Type rec_giving_summary Is Record (
    household_id mv_households.household_id%type
    , household_account_name mv_households.household_account_name%type
    , household_primary_donor_id mv_households.household_primary_donor_id%type
    , household_primary_full_name mv_households.household_primary_full_name%type
    , household_spouse_donor_id mv_households.household_spouse_donor_id%type
    , household_spouse_full_name mv_households.household_spouse_full_name%type
    , household_last_masters_year mv_households.household_last_masters_year%type
    , af_young_alum varchar2(1)
    , af_young_alum1 varchar2(1)
    , af_young_alum2 varchar2(1)
    , af_young_alum3 varchar2(1)
    -- Giving totals
    , ngc_lifetime number
    , ngc_lifetime_full_rec number
    , ngc_lifetime_nonanon_full_rec number
    , cash_lifetime number
    , full_circle_credit number
    , full_circle_recognition number
    , ngc_cfy number
    , ngc_pfy1 number
    , ngc_pfy2 number
    , ngc_pfy3 number
    , ngc_pfy4 number
    , ngc_pfy5 number
    , pledge_cfy number
    , pledge_pfy1 number
    , pledge_pfy2 number
    , pledge_pfy3 number
    , pledge_pfy4 number
    , pledge_pfy5 number
    , cash_cfy number
    , cash_pfy1 number
    , cash_pfy2 number
    , cash_pfy3 number
    , cash_pfy4 number
    , cash_pfy5 number
    , expendable_cfy number
    , expendable_pfy1 number
    , expendable_pfy2 number
    , expendable_pfy3 number
    , expendable_pfy4 number
    , expendable_pfy5 number
    , ngc_giving_first_credit_dt date
    , ngc_fy_giving_first_yr integer
    , ngc_fy_giving_last_yr integer
    , cash_giving_first_credit_dt date
    , cash_fy_giving_first_yr integer
    , cash_fy_giving_last_yr integer
    -- Gift transaction info
    , last_ngc_tx_id mv_ksm_transactions.tx_id%type
    , last_ngc_date mv_ksm_transactions.credit_date%type
    , last_ngc_opportunity_type mv_ksm_transactions.opportunity_type%type
    , last_ngc_designation_id mv_ksm_transactions.designation_record_id%type
    , last_ngc_designation mv_ksm_transactions.designation_name%type
    , last_ngc_recognition_credit mv_ksm_transactions.recognition_credit%type
    , last_cash_tx_id mv_ksm_transactions.tx_id%type
    , last_cash_date mv_ksm_transactions.credit_date%type
    , last_cash_opportunity_type mv_ksm_transactions.opportunity_type%type
    , last_cash_designation_id_id mv_ksm_transactions.designation_record_id%type
    , last_cash_designation mv_ksm_transactions.designation_name%type
    , last_cash_recognition_credit mv_ksm_transactions.recognition_credit%type
    , last_pledge_tx_id mv_ksm_transactions.tx_id%type
    , last_pledge_date mv_ksm_transactions.credit_date%type
    , last_pledge_opportunity_type mv_ksm_transactions.opportunity_type%type
    , last_pledge_designation_id_id mv_ksm_transactions.designation_record_id%type
    , last_pledge_designation mv_ksm_transactions.designation_name%type
    , last_pledge_recognition_credit mv_ksm_transactions.recognition_credit%type
    -- AF status categorizer
    , expendable_status varchar2(10)
    -- Expendable giving status last year
    , expendable_status_fy_start varchar2(10)
    -- Expendable giving status last year
    , expendable_status_pfy1_start varchar2(10)
    , curr_fy integer
    , etl_update_date mv_ksm_transactions.min_etl_update_date%type
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type giving_summary Is Table Of rec_giving_summary;

/*************************************************************************
Public function declarations
*************************************************************************/

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

Function tbl_ksm_giving_summary
  Return giving_summary Pipelined;

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
*************************************************************************/

/*************************************************************************
End of package
*************************************************************************/

End ksm_pkg_giving_summary;
/
Create Or Replace Package Body ksm_pkg_giving_summary Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

-- Implementing Kellogg gift credit, householded, with several common types
Cursor c_ksm_giving_summary Is

  With

  -- Parameters defining KLC years/amounts
  params As (
    Select
      2500 As klc_amt -- Edit this
      , 1000 As young_klc_amt -- Edit this
      , 5 As young_klc_yrs
    From DUAL
  )

  , hh_base As (
    Select Distinct
      hh.household_id
      , hh.household_account_name
      , hh.household_primary_donor_id
      , hh.household_primary_full_name
      , hh.household_spouse_donor_id
      , hh.household_spouse_full_name
      , hh.household_last_masters_year
      , Case When hh.household_last_masters_year >= cal.curr_fy - young_klc_yrs Then 'Y' End
        As af_young_alum
      , Case When hh.household_last_masters_year >= cal.curr_fy - young_klc_yrs - 1 Then 'Y' End
        As af_young_alum1
      , Case When hh.household_last_masters_year >= cal.curr_fy - young_klc_yrs - 2 Then 'Y' End
        As af_young_alum2
      , Case When hh.household_last_masters_year >= cal.curr_fy - young_klc_yrs - 3 Then 'Y' End
        As af_young_alum3
      , hh.etl_update_date
    From mv_households hh
    Inner Join mv_ksm_transactions kt
      On kt.household_id = hh.household_id
    Cross Join params
    Cross Join v_current_calendar cal
    Where hh.household_primary = 'Y'
  )

  -- Sum cash amounts
  , cash As (
    Select Distinct
      cash.household_id
      -- Lifetime giving
      , sum(cash.hh_credit) As cash_lifetime
      -- Yearly totals
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
      , min(cash.fiscal_year) As cash_fy_giving_first_yr
      , min(cash.credit_date) As cash_giving_first_credit_dt
      , max(cash.fiscal_year) As cash_fy_giving_last_yr
      --, count(Distinct cash.fiscal_year) As fy_giving_yr_count_cash
      , min(Case When cash.cash_category = 'Expendable' Then cash.fiscal_year End) As expendable_fy_giving_first_yr
      , max(Case When cash.cash_category = 'Expendable' Then cash.fiscal_year End) As expendable_fy_giving_last_yr
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
      -- Anonymous flag
      , Case
          When max(cash.anonymous_type) Is Not Null
            Then 'Y'
          End
        As anonymous_flag_cash
      , max(cash.max_etl_update_date)
        As etl_update_date
    From v_ksm_gifts_cash cash
    Cross Join v_current_calendar cal
    Cross Join params
    Group By
      cash.household_id
  )

  -- Sum transaction amounts
  , ngc As (
    Select Distinct
      ngc.household_id
      -- Lifetime giving
      , sum(ngc.hh_credit) As ngc_lifetime
      , sum(ngc.hh_recognition_credit) -- Count bequests at face value and internal transfers at > $0
        As ngc_lifetime_full_rec
      , sum(Case When ngc.anonymous_type Is Null Then ngc.hh_recognition_credit Else 0 End)
        As ngc_lifetime_nonanon_full_rec
      -- Campaign totals
      , sum(Case When ngc.full_circle_campaign_priority Is Not Null Then ngc.hh_credit End) As full_circle_credit
      , sum(Case When ngc.full_circle_campaign_priority Is Not Null Then ngc.hh_recognition_credit End) As full_circle_recognition
      -- Yearly totals
      , sum(Case When cal.curr_fy = ngc.fiscal_year     Then ngc.hh_credit Else 0 End) As ngc_cfy
      , sum(Case When cal.curr_fy = ngc.fiscal_year + 1 Then ngc.hh_credit Else 0 End) As ngc_pfy1
      , sum(Case When cal.curr_fy = ngc.fiscal_year + 2 Then ngc.hh_credit Else 0 End) As ngc_pfy2
      , sum(Case When cal.curr_fy = ngc.fiscal_year + 3 Then ngc.hh_credit Else 0 End) As ngc_pfy3
      , sum(Case When cal.curr_fy = ngc.fiscal_year + 4 Then ngc.hh_credit Else 0 End) As ngc_pfy4
      , sum(Case When cal.curr_fy = ngc.fiscal_year + 5 Then ngc.hh_credit Else 0 End) As ngc_pfy5
      -- Pledge totals
      , sum(Case When ngc.gypm_ind = 'P' And cal.curr_fy = ngc.fiscal_year     Then ngc.hh_credit Else 0 End) As pledge_cfy
      , sum(Case When ngc.gypm_ind = 'P' And cal.curr_fy = ngc.fiscal_year + 1 Then ngc.hh_credit Else 0 End) As pledge_pfy1
      , sum(Case When ngc.gypm_ind = 'P' And cal.curr_fy = ngc.fiscal_year + 2 Then ngc.hh_credit Else 0 End) As pledge_pfy2
      , sum(Case When ngc.gypm_ind = 'P' And cal.curr_fy = ngc.fiscal_year + 3 Then ngc.hh_credit Else 0 End) As pledge_pfy3
      , sum(Case When ngc.gypm_ind = 'P' And cal.curr_fy = ngc.fiscal_year + 4 Then ngc.hh_credit Else 0 End) As pledge_pfy4
      , sum(Case When ngc.gypm_ind = 'P' And cal.curr_fy = ngc.fiscal_year + 5 Then ngc.hh_credit Else 0 End) As pledge_pfy5
      -- Giving history
      , min(ngc.fiscal_year) As ngc_fy_giving_first_yr
      , min(ngc.credit_date) As ngc_giving_first_credit_dt
      , max(ngc.fiscal_year) As ngc_fy_giving_last_yr
      --, count(Distinct ngc.fiscal_year) As fy_giving_yr_count_ngc
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
      -- Last KSM pledge
      , min(Case When ngc.gypm_ind = 'P' Then ngc.tx_id End) keep(dense_rank First Order By ngc.gypm_ind Desc, ngc.credit_date Desc, ngc.tx_id Asc)
        As last_pledge_tx_id
      , min(Case When ngc.gypm_ind = 'P' Then ngc.credit_date End) keep(dense_rank First Order By ngc.gypm_ind Desc, ngc.credit_date Desc, ngc.tx_id Asc)
        As last_pledge_date
      , min(Case When ngc.gypm_ind = 'P' Then ngc.opportunity_type End) keep(dense_rank First Order By ngc.gypm_ind Desc, ngc.credit_date Desc, ngc.tx_id Asc)
        As last_pledge_opportunity_type
      , min(Case When ngc.gypm_ind = 'P' Then ngc.designation_record_id End) keep(dense_rank First Order By ngc.gypm_ind Desc, ngc.credit_date Desc, ngc.tx_id Asc)
        As last_pledge_designation_id
      , min(Case When ngc.gypm_ind = 'P' Then ngc.designation_name End) keep(dense_rank First Order By ngc.gypm_ind Desc, ngc.credit_date Desc, ngc.tx_id Asc)
        As last_pledge_designation
      , sum(Case When ngc.gypm_ind = 'P' Then ngc.hh_recognition_credit End) keep(dense_rank First Order By ngc.gypm_ind Desc, ngc.credit_date Desc, ngc.tx_id Asc)
        As last_pledge_recognition_credit
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
          When max(ngc.anonymous_type) Is Not Null
            Then 'Y'
          End
        As anonymous_flag_ngc
      , max(ngc.max_etl_update_date)
        As etl_update_date
    From v_ksm_gifts_ngc ngc
    Cross Join v_current_calendar cal
    Cross Join params
    Group By
      ngc.household_id
  )

  -- Main query
  Select
    hh_base.household_id
    , hh_base.household_account_name
    , hh_base.household_primary_donor_id
    , hh_base.household_primary_full_name
    , hh_base.household_spouse_donor_id
    , hh_base.household_spouse_full_name
    , hh_base.household_last_masters_year
    , hh_base.af_young_alum
    , hh_base.af_young_alum1
    , hh_base.af_young_alum2
    , hh_base.af_young_alum3
    -- Giving totals
    , ngc.ngc_lifetime
    , ngc.ngc_lifetime_full_rec
    , ngc.ngc_lifetime_nonanon_full_rec
    , cash.cash_lifetime
    , ngc.full_circle_credit
    , ngc.full_circle_recognition
    -- Yearly giving
    , ngc.ngc_cfy
    , ngc.ngc_pfy1
    , ngc.ngc_pfy2
    , ngc.ngc_pfy3
    , ngc.ngc_pfy4
    , ngc.ngc_pfy5
    , ngc.pledge_cfy
    , ngc.pledge_pfy1
    , ngc.pledge_pfy2
    , ngc.pledge_pfy3
    , ngc.pledge_pfy4
    , ngc.pledge_pfy5
    , cash.cash_cfy
    , cash.cash_pfy1
    , cash.cash_pfy2
    , cash.cash_pfy3
    , cash.cash_pfy4
    , cash.cash_pfy5
    , cash.expendable_cfy
    , cash.expendable_pfy1
    , cash.expendable_pfy2
    , cash.expendable_pfy3
    , cash.expendable_pfy4
    , cash.expendable_pfy5
    , ngc.ngc_giving_first_credit_dt
    , ngc.ngc_fy_giving_first_yr
    , ngc.ngc_fy_giving_last_yr
    , cash.cash_giving_first_credit_dt
    , cash.cash_fy_giving_first_yr
    , cash.cash_fy_giving_last_yr
    -- Gift transaction info
    , ngc.last_ngc_tx_id
    , ngc.last_ngc_date
    , ngc.last_ngc_opportunity_type
    , ngc.last_ngc_designation_id
    , ngc.last_ngc_designation
    , ngc.last_ngc_recognition_credit
    , cash.last_cash_tx_id
    , cash.last_cash_date
    , cash.last_cash_opportunity_type
    , cash.last_cash_designation_id
    , cash.last_cash_designation
    , cash.last_cash_recognition_credit
    , ngc.last_pledge_tx_id
    , ngc.last_pledge_date
    , ngc.last_pledge_opportunity_type
    , ngc.last_pledge_designation_id
    , ngc.last_pledge_designation
    , ngc.last_pledge_recognition_credit
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
    , cal.curr_fy
    , greatest(hh_base.etl_update_date, cash.etl_update_date, ngc.etl_update_date)
      As etl_update_date
  From hh_base
  Cross Join params
  Cross Join v_current_calendar cal
  Left Join cash
    On cash.household_id = hh_base.household_id
  Left Join ngc
    On ngc.household_id = hh_base.household_id
;


/*************************************************************************
Private functions
*************************************************************************/

/*************************************************************************
Pipelined functions
*************************************************************************/

--------------------------------------
Function tbl_ksm_giving_summary
  Return giving_summary Pipelined As
    -- Declarations
    gs giving_summary;

  Begin
    Open c_ksm_giving_summary;
      Fetch c_ksm_giving_summary Bulk Collect Into gs;
    Close c_ksm_giving_summary;
    For i in 1..(gs.count) Loop
      Pipe row(gs(i));
    End Loop;
    Return;
  End;

End ksm_pkg_giving_summary;
/
