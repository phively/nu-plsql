/*************************************************
Kellogg lifetime giving transactions
*************************************************/
Create Or Replace View v_ksm_giving_trans As
-- View implementing ksm_pkg Kellogg gift credit
Select
  g.*
  , cal.today
  , cal.yesterday
  , cal.curr_fy
From table(ksm_pkg.tbl_gift_credit_ksm) g
Cross Join table(ksm_pkg.tbl_current_calendar) cal
;

/*************************************************
Householded Kellogg lifetime giving transactions
*************************************************/
Create Or Replace View v_ksm_giving_trans_hh As
-- View implementing ksm_pkg Kellogg gift credit, with household ID (slower than tbl_gift_credit_ksm)
Select
  g.*
  , cal.today
  , cal.yesterday
  , cal.curr_fy
From table(ksm_pkg.tbl_gift_credit_hh_ksm) g
Cross Join table(ksm_pkg.tbl_current_calendar) cal
;

/*************************************************
Householded entity giving summaries
*************************************************/
Create Or Replace View v_ksm_giving_summary As
-- View implementing Kellogg gift credit, householded, with several common types
With
-- Sum transaction amounts
trans As (
  Select Distinct
    hh.id_number
    , hh.household_id
    , hh.household_rpt_name
    , hh.household_spouse_id
    , hh.household_spouse
    , sum(Case When tx_gypm_ind != 'Y' Then hh_credit Else 0 End) As ngc_lifetime
    , sum(Case When tx_gypm_ind != 'Y' Then hh_recognition_credit Else 0 End) -- Count bequests at face value and internal transfers at > $0
      As ngc_lifetime_full_rec
    , sum(Case When tx_gypm_ind != 'Y' And anonymous Not In (Select Distinct anonymous_code From tms_anonymous) Then hh_recognition_credit Else 0 End)
      As ngc_lifetime_nonanon_full_rec
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
    -- Current Use cash totals (for KLC)
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year     And cru_flag = 'Y' Then hh_credit Else 0 End) As cru_cfy
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 1 And cru_flag = 'Y' Then hh_credit Else 0 End) As cru_pfy1
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 2 And cru_flag = 'Y' Then hh_credit Else 0 End) As cru_pfy2
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 3 And cru_flag = 'Y' Then hh_credit Else 0 End) As cru_pfy3
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 4 And cru_flag = 'Y' Then hh_credit Else 0 End) As cru_pfy4
    , sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 5 And cru_flag = 'Y' Then hh_credit Else 0 End) As cru_pfy5
    -- WARNING: includes new gifts and commitments as well as cash
    , sum(Case When cal.curr_fy = fiscal_year     Then hh_credit Else 0 End) As stewardship_cfy
    , sum(Case When cal.curr_fy = fiscal_year + 1 Then hh_credit Else 0 End) As stewardship_pfy1
    , sum(Case When cal.curr_fy = fiscal_year + 2 Then hh_credit Else 0 End) As stewardship_pfy2
    , sum(Case When cal.curr_fy = fiscal_year + 3 Then hh_credit Else 0 End) As stewardship_pfy3
    , sum(Case When cal.curr_fy = fiscal_year + 4 Then hh_credit Else 0 End) As stewardship_pfy4
    , sum(Case When cal.curr_fy = fiscal_year + 5 Then hh_credit Else 0 End) As stewardship_pfy5
    -- Anonymous stewardship giving per FY
    , sum(Case When cal.curr_fy = fiscal_year     And anonymous <> ' ' Then hh_credit Else 0 End) As anonymous_cfy
    , sum(Case When cal.curr_fy = fiscal_year + 1 And anonymous <> ' ' Then hh_credit Else 0 End) As anonymous_pfy1
    , sum(Case When cal.curr_fy = fiscal_year + 2 And anonymous <> ' ' Then hh_credit Else 0 End) As anonymous_pfy2
    , sum(Case When cal.curr_fy = fiscal_year + 3 And anonymous <> ' ' Then hh_credit Else 0 End) As anonymous_pfy3
    , sum(Case When cal.curr_fy = fiscal_year + 4 And anonymous <> ' ' Then hh_credit Else 0 End) As anonymous_pfy4
    , sum(Case When cal.curr_fy = fiscal_year + 5 And anonymous <> ' ' Then hh_credit Else 0 End) As anonymous_pfy5
    -- Giving history
    , min(gfts.fiscal_year) As fy_giving_first_yr
    , max(gfts.fiscal_year) As fy_giving_last_yr
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
    , sum(gfts.hh_recognition_credit) keep(dense_rank First Order By gfts.date_of_record Desc, gfts.tx_number Asc)
      As last_gift_recognition_credit
  From table(ksm_pkg.tbl_entity_households_ksm) hh
  Cross Join v_current_calendar cal
  Inner Join v_ksm_giving_trans_hh gfts
    On gfts.household_id = hh.household_id
  Group By
    hh.id_number
    , hh.household_id
    , hh.household_rpt_name
    , hh.household_spouse_id
    , hh.household_spouse
)
-- Main query
Select
  trans.*
  -- AF status categorizer
  , Case
      When af_cfy > 0 Then 'Donor'
      When af_pfy1 > 0 Then 'LYBUNT'
      When af_pfy2 + af_pfy3 + af_pfy4 > 0 Then 'PYBUNT'
      When af_cfy + af_pfy1 + af_pfy2 + af_pfy3 + af_pfy4 = 0 Then 'Lapsed/Non'
    End As af_status
  -- AF status last year
  , Case
      When af_pfy1 > 0 Then 'LYBUNT'
      When af_pfy2 + af_pfy3 + af_pfy4 > 0 Then 'PYBUNT'
      When af_pfy1 + af_pfy2 + af_pfy3 + af_pfy4 = 0 Then 'Lapsed/Non'
    End As af_status_fy_start
  -- Anonymous flags
  , shc.anonymous_donor
  , Case When anonymous_cfy > 0 Then 'Y' End As anonymous_cfy_flag
  , Case When anonymous_pfy1 > 0 Then 'Y' End As anonymous_pfy1_flag
  , Case When anonymous_pfy2 > 0 Then 'Y' End As anonymous_pfy2_flag
  , Case When anonymous_pfy3 > 0 Then 'Y' End As anonymous_pfy3_flag
  , Case When anonymous_pfy4 > 0 Then 'Y' End As anonymous_pfy4_flag
  , Case When anonymous_pfy5 > 0 Then 'Y' End As anonymous_pfy5_flag
  
From trans
Left Join table(ksm_pkg.tbl_special_handling_concat) shc
  On shc.id_number = trans.id_number
;

/*************************************************
KSM lifetime giving
Kept for historical purposes for past queries that reference v_ksm_giving_lifetime
*************************************************/
Create Or Replace View v_ksm_giving_lifetime As
-- Replacement lifetime giving view, based on giving summary to household lifetime giving amounts. Kept for historical purposes.
Select
  ksm.id_number
  , entity.report_name
  , ksm.ngc_lifetime As credit_amount
  , ksm.ngc_lifetime_full_rec As credit_amount_full_rec
From v_ksm_giving_summary ksm
Inner Join entity On entity.id_number = ksm.id_number
;

/*************************************************
Kellogg Transforming Together Campaign giving transactions
*************************************************/
Create Or Replace View v_ksm_giving_campaign_trans As
-- Campaign transactions
Select *
From table(ksm_pkg.tbl_gift_credit_campaign)
;

/*************************************************
Householded Kellogg campaign giving transactions
*************************************************/
Create Or Replace View v_ksm_giving_campaign_trans_hh As
-- Householded campaign transactions
Select *
From table(ksm_pkg.tbl_gift_credit_hh_campaign)
;

/*************************************************
Kellogg Campaign giving summaries
*************************************************/
Create or Replace View v_ksm_giving_campaign As
With
hh As (
  Select *
  From table(ksm_pkg.tbl_entity_households_ksm)
)
, cgft As (
  Select *
  From v_ksm_giving_campaign_trans_hh
)
, legal As (
  Select id_number, sum(legal_amount) As campaign_legal_giving
  From cgft
  Group By id_number
)
-- View implementing householded campaign giving based on new gifts & commitments
Select Distinct
  hh.id_number
  , entity.report_name
  , hh.degrees_concat
  , cgft.household_id
  , hh.household_rpt_name
  , hh.household_spouse_id
  , hh.household_spouse
  -- Legal giving is for the individual
  , legal.campaign_legal_giving
  -- All other giving is for the household
  , sum(cgft.hh_credit) As campaign_giving
  , sum(Case When cgft.anonymous In (Select Distinct anonymous_code From tms_anonymous) Then hh_credit Else 0 End) As campaign_anonymous
  , sum(Case When cgft.anonymous Not In (Select Distinct anonymous_code From tms_anonymous) Then hh_credit Else 0 End) As campaign_nonanonymous
  , sum(Case When cal.curr_fy = fiscal_year     Then hh_credit Else 0 End) As campaign_cfy
  , sum(Case When cal.curr_fy = fiscal_year + 1 Then hh_credit Else 0 End) As campaign_pfy1
  , sum(Case When cal.curr_fy = fiscal_year + 2 Then hh_credit Else 0 End) As campaign_pfy2
  , sum(Case When cal.curr_fy = fiscal_year + 3 Then hh_credit Else 0 End) As campaign_pfy3
  , sum(Case When fiscal_year < 2008 Then hh_credit Else 0 End) As campaign_reachbacks
  , sum(Case When fiscal_year = 2008 Then hh_credit Else 0 End) As campaign_fy08
  , sum(Case When fiscal_year = 2009 Then hh_credit Else 0 End) As campaign_fy09
  , sum(Case When fiscal_year = 2010 Then hh_credit Else 0 End) As campaign_fy10
  , sum(Case When fiscal_year = 2011 Then hh_credit Else 0 End) As campaign_fy11
  , sum(Case When fiscal_year = 2012 Then hh_credit Else 0 End) As campaign_fy12
  , sum(Case When fiscal_year = 2013 Then hh_credit Else 0 End) As campaign_fy13
  , sum(Case When fiscal_year = 2014 Then hh_credit Else 0 End) As campaign_fy14
  , sum(Case When fiscal_year = 2015 Then hh_credit Else 0 End) As campaign_fy15
  , sum(Case When fiscal_year = 2016 Then hh_credit Else 0 End) As campaign_fy16
  , sum(Case When fiscal_year = 2017 Then hh_credit Else 0 End) As campaign_fy17
  , sum(Case When fiscal_year = 2018 Then hh_credit Else 0 End) As campaign_fy18
  , sum(Case When fiscal_year = 2019 Then hh_credit Else 0 End) As campaign_fy19
  , sum(Case When fiscal_year = 2020 Then hh_credit Else 0 End) As campaign_fy20
  -- Recognition amounts for stewardship purposes; includes face value of bequests and life expectancy intentions
  , sum(cgft.hh_recognition_credit - cgft.hh_credit) As campaign_discounted_bequests
  , sum(cgft.hh_recognition_credit) As campaign_steward_giving
  , sum(Case When fiscal_year <= 2017 Then hh_recognition_credit Else 0 End) As campaign_steward_thru_fy17
  , sum(Case When fiscal_year <= 2017 And cgft.anonymous In (Select Distinct anonymous_code From tms_anonymous) Then hh_recognition_credit Else 0 End)
    As anon_steward_thru_fy17
  , sum(Case When fiscal_year <= 2017 And cgft.anonymous Not In (Select Distinct anonymous_code From tms_anonymous) Then hh_recognition_credit Else 0 End)
    As nonanon_steward_thru_fy17
  , sum(Case When fiscal_year <= 2018 Then hh_recognition_credit Else 0 End)
    As campaign_steward_thru_fy18
  , sum(Case When fiscal_year <= 2018 And cgft.anonymous In (Select Distinct anonymous_code From tms_anonymous) Then hh_recognition_credit Else 0 End)
    As anon_steward_thru_fy18
  , sum(Case When fiscal_year <= 2018 And cgft.anonymous Not In (Select Distinct anonymous_code From tms_anonymous) Then hh_recognition_credit Else 0 End)
    As nonanon_steward_thru_fy18
From hh
Cross Join v_current_calendar cal
Inner Join cgft On cgft.household_id = hh.household_id
Left Join legal On legal.id_number = hh.id_number
Inner Join entity On entity.id_number = hh.id_number
Group By
  hh.id_number
  , entity.report_name
  , hh.degrees_concat
  , cgft.household_id
  , hh.household_rpt_name
  , hh.household_spouse_id
  , hh.household_spouse
  , legal.campaign_legal_giving
;

/*************************************************
Kellogg Campaign transactions with additional detail columns and a YTD indicator
*************************************************/
Create Or Replace View v_ksm_giving_campaign_ytd As
With
-- View implementing YTD KSM Campaign giving
-- Year-to-date calculator
cal As (
  Select 2007 As prev_fy, 2020 As curr_fy, yesterday -- FY 2007 and 2020 as first and last campaign gift dates
  From v_current_calendar
)
, ytd_dts As (
  Select to_date('09/01/' || (cal.prev_fy - 1), 'mm/dd/yyyy') + rownum - 1 As dt,
    ksm_pkg.fytd_indicator(to_date('09/01/' || (cal.prev_fy - 1), 'mm/dd/yyyy') + rownum - 1) As ytd_ind
  From cal
  Connect By
    rownum <= (to_date('09/01/' || cal.curr_fy, 'mm/dd/yyyy') - to_date('09/01/' || (cal.prev_fy - 1), 'mm/dd/yyyy'))
)
-- Kellogg degrees
, deg As (
  Select id_number, degrees_concat
  From v_entity_ksm_degrees
)
-- Main query
Select
  gft.*
  , cal.curr_fy
  , ytd_dts.ytd_ind
  , entity.report_name
  , entity.institutional_suffix
  , deg.degrees_concat
  , prs.prospect_manager
  , allocation.short_name As allocation_name
From v_ksm_giving_campaign_trans gft
Cross Join v_current_calendar cal
Inner Join ytd_dts On ytd_dts.dt = trunc(gft.date_of_record)
Inner Join entity On entity.id_number = gft.id_number
Inner Join allocation On allocation.allocation_code = gft.alloc_code
Left Join deg On deg.id_number = entity.id_number
Left Join nu_prs_trp_prospect prs On prs.id_number = entity.id_number
;
