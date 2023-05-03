/*****************************************
Core Annual Giving view - transactions by source donor
******************************************/

Create Or Replace View vt_af_gifts_srcdnr_5fy As

With

-- Thresholded allocations: count up to max_gift dollars
thresh_allocs As (
  Select
    allocation.allocation_code
    , allocation.short_name
    , 100E3 As max_gift
  From allocation
  Where allocation_code = '3203006213301GFT' -- KEC Fund
)

-- Kellogg Annual Fund allocations as defined in ksm_pkg
, ksm_cru_allocs As (
  Select *
  From table(ksm_pkg_tmp.tbl_alloc_curr_use_ksm)
)

-- Calendar date range from current_calendar
, cal As (
  Select
    curr_fy - 7 As prev_fy
    , curr_fy
    , yesterday
  From v_current_calendar
)

-- KSM householding
, households As (
  Select hh.*
  From table(ksm_pkg_tmp.tbl_entity_households_ksm) hh
)

-- Formatted giving tables
, ksm_cru_trans As (
  Select Distinct
    tx_number
    , cal.curr_fy
    , cal.yesterday
    , ksm_pkg_tmp.get_gift_source_donor_ksm(tx_number) As id_src_dnr -- giving source donor as defined by ksm_pkg
    , ksm_pkg_calendar.fytd_indicator(gft.date_of_record)
      As ytd_ind
  From nu_gft_trp_gifttrans gft
  Cross Join cal
  Inner Join ksm_cru_allocs cru On cru.allocation_code = gft.allocation_code
  Where
    -- Drop pledges
    tx_gypm_ind <> 'P'
    -- Only pull KSM current use gifts in recent fiscal years
    And fiscal_year Between cal.prev_fy And cal.curr_fy
)
, ksm_cru_gifts As (
  Select
    cru.allocation_code
    , cru.af_flag
    , cru.sweepable
    , cru.budget_relieving
    , gft.alloc_short_name
    , gft.alloc_purpose_desc
    , gft.tx_number
    , gft.tx_sequence
    , gft.tx_gypm_ind
    , gft.fiscal_year
    , trunc(gft.date_of_record) As date_of_record
    , trans.ytd_ind
    , gft.legal_amount
    , gft.credit_amount
    , gft.nwu_af_amount
    , Case
        When thresh_allocs.allocation_code Is Not Null
          And gft.legal_amount > thresh_allocs.max_gift
          Then thresh_allocs.max_gift
        When cru.af_flag = 'Y'
          Then gft.legal_amount
        Else 0
        End
      As ksm_af_amount_legal
    , Case
        When thresh_allocs.allocation_code Is Not Null
          And gft.credit_amount > thresh_allocs.max_gift
          Then thresh_allocs.max_gift
        When cru.af_flag = 'Y'
          Then gft.credit_amount
        Else 0
        End
      As ksm_af_amount_credit
    , gft.id_number As legal_dnr_id
    , trans.id_src_dnr
    , households.household_id As id_hh_src_dnr
    , trans.curr_fy
    , trans.yesterday
  From nu_gft_trp_gifttrans gft
  Inner Join ksm_cru_allocs cru On cru.allocation_code = gft.allocation_code
  Inner Join ksm_cru_trans trans On trans.tx_number = gft.tx_number
  Inner Join households On households.id_number = trans.id_src_dnr
  Left Join thresh_allocs On thresh_allocs.allocation_code = gft.allocation_code
)

-- Gift receipts and biographic information
Select
  -- Giving fields
  af.allocation_code
  , af.af_flag
  , af.sweepable
  , af.budget_relieving
  , af.alloc_short_name
  , af.alloc_purpose_desc
  , af.tx_number
  , af.tx_sequence
  , af.tx_gypm_ind
  , af.fiscal_year
  , af.date_of_record
  , af.ytd_ind
  , af.legal_dnr_id
  , af.legal_amount
  , af.credit_amount
  , af.nwu_af_amount
  , af.ksm_af_amount_legal
  , af.ksm_af_amount_credit
  , af.legal_amount - af.ksm_af_amount_legal
    As ksm_cru_amount_legal
  , af.credit_amount - af.ksm_af_amount_credit
    As ksm_cru_amount_credit
  -- Household source donor entity fields
  , af.id_hh_src_dnr
  , hh.pref_mail_name
  , e_src_dnr.pref_name_sort
  , e_src_dnr.report_name
  , e_src_dnr.person_or_org
  , e_src_dnr.record_status_code
  , e_src_dnr.institutional_suffix
  , hh.household_state As master_state
  , hh.household_country As master_country
  , e_src_dnr.gender_code
  , hh.spouse_id_number
  , hh.spouse_pref_mail_name
  -- KSM alumni flag
  , Case When hh.household_program_group Is Not Null Then 'Y' Else 'N' End
    As ksm_alum_flag
  -- Fiscal year number
  , curr_fy
  , yesterday As data_as_of
From ksm_cru_gifts af
Inner Join entity e_src_dnr On af.id_hh_src_dnr = e_src_dnr.id_number
Inner Join households hh On hh.id_number = af.id_hh_src_dnr
Where legal_amount > 0
;

/*****************************************
Append household information
******************************************/

Create Or Replace View vt_af_donors_5fy As

With

/* Requires the gift data aggregated in vt_af_gifts_srcdnr_5fy. Aggregated by household giving source donor and related fields,
   fiscal year, allocation, and whether the gift was made year-to-date or not. */

-- Degrees concat
deg As (
  Select
    id_number
    , degrees_concat
    , program
    , program_group
  From table(ksm_pkg_tmp.tbl_entity_degrees_concat_ksm)
)

-- Final results aggregated by entity and year
Select
  -- Entity fields
  id_hh_src_dnr
  , pref_name_sort
  , report_name
  , person_or_org
  , record_status_code
  , institutional_suffix
  , entity_deg.degrees_concat As src_dnr_degrees_concat
  , entity_deg.program As src_dnr_program
  , entity_deg.program_group As src_dnr_program_group
  , gender_code
  , spouse_id_number
  , spouse_deg.degrees_concat As spouse_degrees_concat
  , ksm_alum_flag
  , master_state
  , master_country
  -- Giving fields
  , af_flag
  , sweepable
  , budget_relieving
  , allocation_code
  , alloc_short_name
  , alloc_purpose_desc
  , fiscal_year
  , ytd_ind
  -- Date fields
  , curr_fy
  , data_as_of
  -- Aggregated giving amounts
  , sum(legal_amount) As legal_amount
From vt_af_gifts_srcdnr_5fy af_gifts
Left Join deg entity_deg On entity_deg.id_number = af_gifts.id_hh_src_dnr
Left Join deg spouse_deg On spouse_deg.id_number = af_gifts.spouse_id_number
Group By
  id_hh_src_dnr
  , pref_name_sort
  , report_name
  , person_or_org
  , record_status_code
  , institutional_suffix
  , entity_deg.degrees_concat
  , entity_deg.program
  , entity_deg.program_group
  , gender_code
  , spouse_id_number
  , spouse_deg.degrees_concat
  , ksm_alum_flag
  , master_state
  , master_country
  -- Giving fields
  , af_flag
  , sweepable
  , budget_relieving
  , allocation_code
  , alloc_short_name
  , alloc_purpose_desc
  , fiscal_year
  , ytd_ind
  -- Date fields
  , curr_fy
  , data_as_of
;

/*****************************************
Aggregated version of above
******************************************/

Create Or Replace View vt_af_donors_5fy_summary As

With

/* Requires the gift data aggregated in vt_af_gifts_srcdnr_5fy. Aggregated by household giving source donor and related
   fields, with each of the recent fiscal years its own column. */ 

-- Current calendar
cal As (
  Select *
  From table(ksm_pkg_tmp.tbl_current_calendar)
)

-- Degrees concat
, deg As (
  Select
    id_number
    , degrees_concat
    , first_ksm_year
    , program
    , program_group
  From table(ksm_pkg_tmp.tbl_entity_degrees_concat_ksm)
)

-- Housheholds
, hh As (
  Select
    id_number
    , household_id
  From table(ksm_pkg_tmp.tbl_entity_households_ksm)
)

-- Prospect reporting table
, prs As (
  Select
    id_number
    , business_title
    , trim(employer_name1 || ' ' || employer_name2) As employer_name
    , prospect_id
    , prospect_manager
    , team
    , prospect_stage
    , officer_rating
    , evaluation_rating
  From nu_prs_trp_prospect
)

-- Committee members
, kac As (
  Select
    hh.household_id
    , comm.short_desc
    , comm.status
    , comm.role
  From table(ksm_pkg_tmp.tbl_committee_kac) comm
  Inner Join hh On hh.id_number = comm.id_number
)
, gab As (
  Select
    hh.household_id
    , comm.short_desc
    , comm.status
    , comm.role
  From table(ksm_pkg_tmp.tbl_committee_gab) comm
  Inner Join hh On hh.id_number = comm.id_number
)

-- KLC segments
, klc_cfy As (
  Select Distinct
    household_id
    , 'Y' As klc0
  From gift_clubs
  Cross Join cal
  Inner Join hh On hh.id_number = gift_clubs.gift_club_id_number
  Left Join nu_mem_v_tmsclublevel tms_lvl On tms_lvl.level_code = gift_clubs.school_code
  Where gift_club_code = 'LKM'
    And substr(gift_club_end_date, 0, 4) = cal.curr_fy
)
, klc_pfy1 As (
  Select Distinct
    household_id
    , 'Y' As klc1
  From gift_clubs
  Cross Join cal
  Inner Join hh On hh.id_number = gift_clubs.gift_club_id_number
  Left Join nu_mem_v_tmsclublevel tms_lvl On tms_lvl.level_code = gift_clubs.school_code
  Where gift_club_code = 'LKM'
    And substr(gift_club_end_date, 0, 4) = cal.curr_fy - 1
)
, klc_pfy2 As (
  Select Distinct
    household_id
    , 'Y' As klc2
  From gift_clubs
  Cross Join cal
  Inner Join hh On hh.id_number = gift_clubs.gift_club_id_number
  Left Join nu_mem_v_tmsclublevel tms_lvl On tms_lvl.level_code = gift_clubs.school_code
  Where gift_club_code = 'LKM'
    And substr(gift_club_end_date, 0, 4) = cal.curr_fy - 2
)
, klc_pfy3 As (
  Select Distinct
    household_id
    , 'Y' As klc3
  From gift_clubs
  Cross Join cal
  Inner Join hh On hh.id_number = gift_clubs.gift_club_id_number
  Left Join nu_mem_v_tmsclublevel tms_lvl On tms_lvl.level_code = gift_clubs.school_code
  Where gift_club_code = 'LKM'
    And substr(gift_club_end_date, 0, 4) = cal.curr_fy - 3
)

-- Kellogg Annual Fund allocations as defined in ksm_pkg
, ksm_af_allocs As (
  Select allocation_code
  From table(ksm_pkg_tmp.tbl_alloc_annual_fund_ksm)
)

-- Householded first gift year
, first_af As (
  Select Distinct
    household_id
    , min(fiscal_year) As first_af_gift_year
  From table(ksm_pkg_tmp.tbl_gift_credit_hh_ksm) gft
  Inner Join ksm_af_allocs On ksm_af_allocs.allocation_code = gft.allocation_code
  Where tx_gypm_ind <> 'P'
    And af_flag = 'Y'
    And recognition_credit > 0
  Group By household_id
)

-- All AF gifts by source donor
, af_gifts As (
  Select *
  From vt_af_gifts_srcdnr_5fy
)

-- Aggregated by entity and fiscal year
, totals As (
  Select
    id_hh_src_dnr
    -- Aggregated giving amounts
    , sum(Case When fiscal_year = (curr_fy - 0) And af_flag = 'Y' Then legal_amount Else 0 End) As ksm_af_curr_fy
    , sum(Case When fiscal_year = (curr_fy - 1) And af_flag = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy1
    , sum(Case When fiscal_year = (curr_fy - 2) And af_flag = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy2
    , sum(Case When fiscal_year = (curr_fy - 3) And af_flag = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy3
    , sum(Case When fiscal_year = (curr_fy - 4) And af_flag = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy4
    , sum(Case When fiscal_year = (curr_fy - 5) And af_flag = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy5
    , sum(Case When fiscal_year = (curr_fy - 6) And af_flag = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy6
    , sum(Case When fiscal_year = (curr_fy - 7) And af_flag = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy7
    -- Aggregated YTD giving amounts
    , sum(Case When fiscal_year = (curr_fy - 0) And af_flag = 'Y' And ytd_ind = 'Y' Then legal_amount Else 0 End) As ksm_af_curr_fy_ytd
    , sum(Case When fiscal_year = (curr_fy - 1) And af_flag = 'Y' And ytd_ind = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy1_ytd
    , sum(Case When fiscal_year = (curr_fy - 2) And af_flag = 'Y' And ytd_ind = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy2_ytd
    , sum(Case When fiscal_year = (curr_fy - 3) And af_flag = 'Y' And ytd_ind = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy3_ytd
    , sum(Case When fiscal_year = (curr_fy - 4) And af_flag = 'Y' And ytd_ind = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy4_ytd
    , sum(Case When fiscal_year = (curr_fy - 5) And af_flag = 'Y' And ytd_ind = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy5_ytd
    , sum(Case When fiscal_year = (curr_fy - 6) And af_flag = 'Y' And ytd_ind = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy6_ytd
    , sum(Case When fiscal_year = (curr_fy - 7) And af_flag = 'Y' And ytd_ind = 'Y' Then legal_amount Else 0 End) As ksm_af_prev_fy7_ytd
    -- Aggregated match amounts
    , sum(Case When fiscal_year = (curr_fy - 0) And af_flag = 'Y' And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As ksm_af_curr_fy_match
    , sum(Case When fiscal_year = (curr_fy - 1) And af_flag = 'Y' And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As ksm_af_prev_fy1_match
    , sum(Case When fiscal_year = (curr_fy - 2) And af_flag = 'Y' And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As ksm_af_prev_fy2_match
    , sum(Case When fiscal_year = (curr_fy - 3) And af_flag = 'Y' And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As ksm_af_prev_fy3_match
    , sum(Case When fiscal_year = (curr_fy - 4) And af_flag = 'Y' And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As ksm_af_prev_fy4_match
    , sum(Case When fiscal_year = (curr_fy - 5) And af_flag = 'Y' And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As ksm_af_prev_fy5_match
    , sum(Case When fiscal_year = (curr_fy - 6) And af_flag = 'Y' And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As ksm_af_prev_fy6_match
    , sum(Case When fiscal_year = (curr_fy - 7) And af_flag = 'Y' And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As ksm_af_prev_fy7_match
    -- Recent gift details
    , max(Case When fiscal_year = (curr_fy - 0) And af_flag = 'Y' Then date_of_record Else NULL End) As last_gift_curr_fy
    , max(Case When fiscal_year = (curr_fy - 1) And af_flag = 'Y' Then date_of_record Else NULL End) As last_gift_prev_fy1
    , max(Case When fiscal_year = (curr_fy - 2) And af_flag = 'Y' Then date_of_record Else NULL End) As last_gift_prev_fy2
    -- First gift per FY details
    , min(Case When fiscal_year = (curr_fy - 0) And af_flag = 'Y' Then date_of_record End) As ksm_af_curr_fy_dt
    , min(Case When fiscal_year = (curr_fy - 1) And af_flag = 'Y' Then date_of_record End) As ksm_af_prev_fy1_dt
    , min(Case When fiscal_year = (curr_fy - 0) Then date_of_record End) As cru_curr_fy_dt
    , min(Case When fiscal_year = (curr_fy - 1) Then date_of_record End) As cru_prev_fy1_dt
    -- Count of gifts per year
    , sum(Case When fiscal_year = (curr_fy - 0) And af_flag = 'Y' Then 1 Else 0 End) As gifts_curr_fy
    , sum(Case When fiscal_year = (curr_fy - 1) And af_flag = 'Y' Then 1 Else 0 End) As gifts_prev_fy1
    , sum(Case When fiscal_year = (curr_fy - 2) And af_flag = 'Y' Then 1 Else 0 End) As gifts_prev_fy2
    -- Aggregated current use
    , sum(Case When fiscal_year = (curr_fy - 0) Then legal_amount Else 0 End) As cru_curr_fy
    , sum(Case When fiscal_year = (curr_fy - 1) Then legal_amount Else 0 End) As cru_prev_fy1
    , sum(Case When fiscal_year = (curr_fy - 2) Then legal_amount Else 0 End) As cru_prev_fy2
    , sum(Case When fiscal_year = (curr_fy - 3) Then legal_amount Else 0 End) As cru_prev_fy3
    , sum(Case When fiscal_year = (curr_fy - 4) Then legal_amount Else 0 End) As cru_prev_fy4
    , sum(Case When fiscal_year = (curr_fy - 5) Then legal_amount Else 0 End) As cru_prev_fy5
    -- Aggregated YTD current use
    , sum(Case When fiscal_year = (curr_fy - 0) And ytd_ind = 'Y' Then legal_amount Else 0 End) As cru_curr_fy_ytd
    , sum(Case When fiscal_year = (curr_fy - 1) And ytd_ind = 'Y' Then legal_amount Else 0 End) As cru_prev_fy1_ytd
    , sum(Case When fiscal_year = (curr_fy - 2) And ytd_ind = 'Y' Then legal_amount Else 0 End) As cru_prev_fy2_ytd
    , sum(Case When fiscal_year = (curr_fy - 3) And ytd_ind = 'Y' Then legal_amount Else 0 End) As cru_prev_fy3_ytd
    , sum(Case When fiscal_year = (curr_fy - 4) And ytd_ind = 'Y' Then legal_amount Else 0 End) As cru_prev_fy4_ytd
    , sum(Case When fiscal_year = (curr_fy - 5) And ytd_ind = 'Y' Then legal_amount Else 0 End) As cru_prev_fy5_ytd
    -- Aggregated current use matches
    , sum(Case When fiscal_year = (curr_fy - 0) And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As cru_curr_fy_match
    , sum(Case When fiscal_year = (curr_fy - 1) And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As cru_prev_fy1_match
    , sum(Case When fiscal_year = (curr_fy - 2) And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As cru_prev_fy2_match
    , sum(Case When fiscal_year = (curr_fy - 3) And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As cru_prev_fy3_match
    , sum(Case When fiscal_year = (curr_fy - 4) And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As cru_prev_fy4_match
    , sum(Case When fiscal_year = (curr_fy - 5) And tx_gypm_ind = 'M' Then legal_amount Else 0 End) As cru_prev_fy5_match
    -- Aggregated current use, no match
    , sum(Case When fiscal_year = (curr_fy - 0) And tx_gypm_ind <> 'M' Then legal_amount Else 0 End) As cru_curr_fy_nomatch
    , sum(Case When fiscal_year = (curr_fy - 1) And tx_gypm_ind <> 'M' Then legal_amount Else 0 End) As cru_prev_fy1_nomatch
    , sum(Case When fiscal_year = (curr_fy - 2) And tx_gypm_ind <> 'M' Then legal_amount Else 0 End) As cru_prev_fy2_nomatch
    , sum(Case When fiscal_year = (curr_fy - 3) And tx_gypm_ind <> 'M' Then legal_amount Else 0 End) As cru_prev_fy3_nomatch
    , sum(Case When fiscal_year = (curr_fy - 4) And tx_gypm_ind <> 'M' Then legal_amount Else 0 End) As cru_prev_fy4_nomatch
    , sum(Case When fiscal_year = (curr_fy - 5) And tx_gypm_ind <> 'M' Then legal_amount Else 0 End) As cru_prev_fy5_nomatch
  From af_gifts
  Group By id_hh_src_dnr
)

-- Divorced, widowed, etc.
, marital_status As (
  Select
    former_spouse.id_number
    , former_spouse.marital_status_code
    , tms_ms.short_desc
      As marital_status
    , former_spouse.marital_status_chg_dt
  From former_spouse
  Inner Join tms_marital_status tms_ms
    On tms_ms.marital_status_code = former_spouse.marital_status_code
  Where former_spouse.marital_status_code Not In ('M', 'P', 'S', 'V', 'X')
)
, marital_status_concat As (
  Select
    id_number
    , Listagg(marital_status, '; ') Within Group (Order By marital_status_chg_dt Desc)
      As marital_status_concat
  From marital_status
  Group By id_number
)

-- Final results
Select Distinct
  -- Entity fields
  totals.id_hh_src_dnr
  , pref_mail_name
  , pref_name_sort
  , report_name
  , person_or_org
  , record_status_code
  , institutional_suffix
  , entity_deg.degrees_concat As src_dnr_degrees_concat
  , entity_deg.first_ksm_year As src_dnr_first_ksm_year
  , entity_deg.program As src_dnr_program
  , entity_deg.program_group As src_dnr_program_group
  , gender_code
  , spouse_id_number
  , spouse_pref_mail_name
  , spouse_deg.degrees_concat As spouse_degrees_concat
  , spouse_deg.program As spouse_program
  , spouse_deg.program_group As spouse_program_group
  , msc.marital_status_concat
  , master_state
  , master_country
  -- Prospect reporting table fields
  , prs.employer_name
  , prs.business_title
  , prs.prospect_id
  , prs.prospect_manager
  , prs.team
  , prs.prospect_stage
  , prs.officer_rating
  , prs.evaluation_rating
  -- Indicators
  , ksm_alum_flag
  , kac.short_desc As kac
  , gab.short_desc As gab
  , Case When lower(institutional_suffix) Like '%trustee%' Then 'Trustee' Else NULL End
    As trustee
  , klc_cfy.klc0 As klc_cfy
  , klc_pfy1.klc1 As klc_pfy1
  , klc_pfy2.klc2 As klc_pfy2
  , klc_pfy3.klc3 As klc_pfy3
  -- Date fields
  , curr_fy
  , data_as_of
  -- Precalculated giving fields
  , first_af.first_af_gift_year
  , ksm_af_curr_fy_dt
  , ksm_af_prev_fy1_dt
  , ksm_af_curr_fy
  , ksm_af_prev_fy1
  , ksm_af_prev_fy2
  , ksm_af_prev_fy3
  , ksm_af_prev_fy4
  , ksm_af_prev_fy5
  , ksm_af_prev_fy6
  , ksm_af_prev_fy7
  , ksm_af_curr_fy_ytd
  , ksm_af_prev_fy1_ytd
  , ksm_af_prev_fy2_ytd
  , ksm_af_prev_fy3_ytd
  , ksm_af_prev_fy4_ytd
  , ksm_af_prev_fy5_ytd
  , ksm_af_prev_fy6_ytd
  , ksm_af_prev_fy7_ytd
  , ksm_af_curr_fy_match
  , ksm_af_prev_fy1_match
  , ksm_af_prev_fy2_match
  , ksm_af_prev_fy3_match
  , ksm_af_prev_fy4_match
  , ksm_af_prev_fy5_match
  , ksm_af_prev_fy6_match
  , ksm_af_prev_fy7_match
  , last_gift_curr_fy
  , last_gift_prev_fy1
  , last_gift_prev_fy2
  , gifts_curr_fy
  , gifts_prev_fy1
  , gifts_prev_fy2
  , cru_curr_fy_dt
  , cru_prev_fy1_dt
  , cru_curr_fy
  , cru_prev_fy1
  , cru_prev_fy2
  , cru_prev_fy3
  , cru_prev_fy4
  , cru_prev_fy5
  , cru_curr_fy_ytd
  , cru_prev_fy1_ytd
  , cru_prev_fy2_ytd
  , cru_prev_fy3_ytd
  , cru_prev_fy4_ytd
  , cru_prev_fy5_ytd
  , cru_curr_fy_match
  , cru_prev_fy1_match
  , cru_prev_fy2_match
  , cru_prev_fy3_match
  , cru_prev_fy4_match
  , cru_prev_fy5_match
  , cru_curr_fy_nomatch
  , cru_prev_fy1_nomatch
  , cru_prev_fy2_nomatch
  , cru_prev_fy3_nomatch
  , cru_prev_fy4_nomatch
  , cru_prev_fy5_nomatch
From af_gifts
Inner Join totals On totals.id_hh_src_dnr = af_gifts.id_hh_src_dnr
Left Join prs On prs.id_number = af_gifts.id_hh_src_dnr
Left Join first_af On first_af.household_id = af_gifts.id_hh_src_dnr
Left Join deg entity_deg On entity_deg.id_number = af_gifts.id_hh_src_dnr
Left Join deg spouse_deg On spouse_deg.id_number = af_gifts.spouse_id_number
Left Join kac On totals.id_hh_src_dnr = kac.household_id
Left Join gab On totals.id_hh_src_dnr = gab.household_id
Left Join klc_cfy On klc_cfy.household_id = af_gifts.id_hh_src_dnr
Left Join klc_pfy1 On klc_pfy1.household_id = af_gifts.id_hh_src_dnr
Left Join klc_pfy2 On klc_pfy2.household_id = af_gifts.id_hh_src_dnr
Left Join klc_pfy3 On klc_pfy3.household_id = af_gifts.id_hh_src_dnr
Left Join marital_status_concat msc On msc.id_number = af_gifts.id_hh_src_dnr
;

/*****************************************
Giving by allocation
******************************************/

Create Or Replace View vt_af_allocs_summary As

With

-- AF allocation purpose definitions
purposes As (
  Select
    purpose_code
    , short_desc
    , Case
        When lower(short_desc) Like '%scholar%' Or lower(short_desc) Like '%fellow%' Then 'Scholarships'
        When lower(short_desc) Like '%mainten%' Then 'Facilities'
        When lower(short_desc) Like '%research%' Then 'Research'
        Else 'Other Unrestricted'
      End As purpose
  From tms_purpose
)

-- CRU allocations
, cru As (
  Select
    alloc.*
    , Case
        When alloc.allocation_code = '3303000891301GFT' Then 'Annual Fund'
        When purposes.purpose Is Not Null Then purposes.purpose
        Else 'Other Unrestricted'
      End As alloc_categorizer
  From table(rpt_pbh634.ksm_pkg_tmp.tbl_alloc_curr_use_ksm) alloc
  Inner Join allocation On allocation.allocation_code = alloc.allocation_code
  Left Join purposes On purposes.purpose_code = allocation.alloc_purpose
)

-- KSM CRU gifts
, gft_summary As (
  Select
    allocation_code As alloc
    , fiscal_year
    , cal.curr_fy
    , count(tx_number) As total_gifts
    , sum(legal_amount) As total_cash_giving
    , count(Case When rpt_pbh634.ksm_pkg_tmp.fytd_indicator(date_of_record) = 'Y' Then tx_number Else NULL End) As ytd_gifts
    , sum(Case When rpt_pbh634.ksm_pkg_tmp.fytd_indicator(date_of_record) = 'Y' Then legal_amount Else 0 End) As ytd_cash_giving
  From table(rpt_pbh634.ksm_pkg_tmp.tbl_gift_credit_ksm) gft
  Cross Join table(rpt_pbh634.ksm_pkg_tmp.tbl_current_calendar) cal
  Where cru_flag = 'Y' -- Current Use only
    And tx_gypm_ind <> 'P' -- Exclude pledges, i.e. cash only
    And legal_amount > 0 -- Actual gifts only, not credited
  Group By
    allocation_code
    , fiscal_year
    , cal.curr_fy
)

-- Main query
Select *
From cru
Left Join gft_summary On gft_summary.alloc = cru.allocation_code
;

/*****************************************
Alumni giving behavior
******************************************/

Create Or Replace View vt_af_alumni_summary As

With

/* All Kellogg alumni households and annual fund giving behavior.
   Base table is nu_prs_trp_prospect so deceased entities are excluded. */

-- Calendar date range from current_calendar
cal As (
  Select
    curr_fy
    , yesterday
  From v_current_calendar
)

-- Housheholds
, hh As (
  Select
    id_number
    , pref_mail_name
    , degrees_concat
    , program_group
    , spouse_id_number
    , spouse_pref_mail_name
    , spouse_degrees_concat
    , spouse_program_group
    , household_id
    , household_ksm_year
    , household_masters_year
    , household_program_group
  From table(ksm_pkg_tmp.tbl_entity_households_ksm)
  Where household_ksm_year Is Not Null
)

-- Kellogg Annual Fund allocations as defined in ksm_pkg
, ksm_af_allocs As (
  Select allocation_code
  From table(ksm_pkg_tmp.tbl_alloc_annual_fund_ksm)
)

-- First gift year
, first_af As (
  Select Distinct
    household_id
    , min(fiscal_year) As first_af_gift_year
  From table(ksm_pkg_tmp.tbl_gift_credit_hh_ksm) gft
  Inner Join ksm_af_allocs On ksm_af_allocs.allocation_code = gft.allocation_code
  Where tx_gypm_ind <> 'P'
    And af_flag = 'Y'
    And recognition_credit > 0
  Group By household_id
)

Select Distinct
  -- Household fields
  hh.household_id
  , hh.pref_mail_name
  , hh.degrees_concat
  , hh.household_masters_year
  , hh.household_ksm_year
  , hh.program_group
  , hh.spouse_id_number
  , hh.spouse_pref_mail_name
  , hh.spouse_degrees_concat
  , hh.spouse_program_group
  , hh.household_program_group
  -- Entity-based fields
  , prs.record_status_code
  , prs.pref_city
  , prs.pref_zip
  , prs.pref_state
  , tms_states.short_desc As pref_state_desc
  , tms_country.short_desc As preferred_country
  , prs.business_title
  , trim(prs.employer_name1 || ' ' || prs.employer_name2) As employer_name
  -- Giving fields
  , af_summary.ksm_af_curr_fy
  , af_summary.ksm_af_prev_fy1
  , af_summary.ksm_af_prev_fy2
  , af_summary.ksm_af_prev_fy3
  , af_summary.ksm_af_prev_fy4
  , af_summary.ksm_af_prev_fy5
  , af_summary.ksm_af_prev_fy6
  , af_summary.ksm_af_prev_fy7
  , first_af.first_af_gift_year
  , cru_curr_fy
  , cru_prev_fy1
  , cru_prev_fy2
  , cru_curr_fy_ytd
  , cru_prev_fy1_ytd
  , cru_prev_fy2_ytd
  -- Prospect fields
  , prs.prospect_id
  , prs.prospect_manager
  , prs.team
  , prs.prospect_stage
  , prs.officer_rating
  , prs.evaluation_rating
  -- Indicators
  , af_summary.kac
  , af_summary.gab
  , af_summary.trustee
  , af_summary.klc_cfy
  , af_summary.klc_pfy1
  , af_summary.klc_pfy2
  -- Calendar objects
  , cal.curr_fy
  , cal.yesterday
From nu_prs_trp_prospect prs
Cross Join cal
Inner Join hh On hh.household_id = prs.id_number
Left Join vt_af_donors_5fy_summary af_summary On af_summary.id_hh_src_dnr = hh.household_id
Left Join first_af On first_af.household_id = prs.id_number
Left Join tms_states On tms_states.state_code = prs.pref_state
Left Join tms_country On tms_country.country_code = prs.preferred_country
Where hh.household_id = hh.id_number
;

/*****************************************
KLC summary
******************************************/

Create Or Replace View vt_af_klc_donors As

/* Pulls KLC donors using the ksm_pkg definition, and appends AF and Current Use giving */
Select Distinct
  -- KLC table data
  klc.*
  -- Summarized current use giving data
  , af.cru_curr_fy
  , af.cru_prev_fy1
  , af.cru_prev_fy2
  , af.cru_prev_fy3
  -- Current year CRU and AF data
  , Case
      When klc.fiscal_year = cal.curr_fy - 0 Then af.ksm_af_curr_fy
      When klc.fiscal_year = cal.curr_fy - 1 Then af.ksm_af_prev_fy1
      When klc.fiscal_year = cal.curr_fy - 2 Then af.ksm_af_prev_fy2
      When klc.fiscal_year = cal.curr_fy - 3 Then af.ksm_af_prev_fy3
      Else NULL
    End As fy_af
  , Case
      When klc.fiscal_year = cal.curr_fy - 0 Then af.cru_curr_fy
      When klc.fiscal_year = cal.curr_fy - 1 Then af.cru_prev_fy1
      When klc.fiscal_year = cal.curr_fy - 2 Then af.cru_prev_fy2
      When klc.fiscal_year = cal.curr_fy - 3 Then af.cru_prev_fy3
      Else NULL
    End As fy_cru
  -- Current calendar fields
  , cal.curr_fy
  , cal.yesterday
From table(ksm_pkg_tmp.tbl_klc_history) klc
Cross Join v_current_calendar cal
Left Join vt_af_donors_5fy_summary af On klc.household_id = af.id_hh_src_dnr
;

/*****************************************
KSM gift and match to non-KSM allocation
******************************************/

Create Or Replace View vt_af_match_grabback As

-- Gift to KSM, match outside KSM
Select
  gft.tx_number
  , gft.tx_sequence
  , gft.alloc_school
  , gft.allocation_code
  , allocg.short_name As allocation
  , match_gift_matched_donor_id
  , entity.report_name
  , ksm_alum.degrees_concat
  , match_gift_receipt_number
  , match_gift_matched_sequence
  , allocm.allocation_code As match_allocation_code
  , allocm.short_name As match_allocation
  , match_gift_date_of_record
  , ksm_pkg_tmp.get_fiscal_year(match_gift_date_of_record) As fiscal_year_of_match
  , match_gift_amount
From matching_gift
Inner Join nu_gft_trp_gifttrans gft On gft.tx_number = matching_gift.match_gift_matched_receipt
  And gft.tx_sequence = matching_gift.match_gift_matched_sequence
Inner Join entity On entity.id_number = matching_gift.match_gift_matched_donor_id
Left Join table(rpt_pbh634.ksm_pkg_tmp.tbl_entity_degrees_concat_ksm) ksm_alum On ksm_alum.id_number = matching_gift.match_gift_matched_donor_id
Left Join allocation allocg On allocg.allocation_code = gft.allocation_code
Left Join allocation allocm On allocm.allocation_code = matching_gift.match_gift_allocation_name
Where match_gift_program_credit_code <> 'KM'
  And gft.alloc_school = 'KM'
Order By match_gift_date_of_record Desc
;

/*****************************************
Gifts made to TBD accounts
******************************************/

Create Or Replace View vt_alloc_tbd_accounts As

With

/* All Kellogg TBD accounts */
ksm_tbd As (
  Select *
  From allocation alloc
  Where lower(alloc.short_name) Like '%kellogg%tbd%'
    -- Also include KSM Unrestricted Bequest
    Or alloc.allocation_code = '3203004290301GFT'
)

/* KSM degrees concat definition */
, deg As (
  Select *
  From table(rpt_pbh634.ksm_pkg_tmp.tbl_entity_degrees_concat_ksm)
)

/* Transaction and pledge TMS table definition */
, tms_trans As (
  (
    Select
      transaction_type_code
      , short_desc As transaction_type
    From tms_transaction_type
  ) Union All (
    Select
      pledge_type_code
      , short_desc
    From tms_pledge_type
  )
)

/* Main query */
Select
  gft.id_number
  , donor_name
  , record_type_code
  , deg.degrees_concat
  , trim(deg.program_group) As program_group
  , tx_number
  , tx_sequence
  , date_of_record
  , fiscal_year
  , legal_amount
  , credit_amount
  , gft.tx_gypm_ind
  , tms_trans.transaction_type
  , gft.allocation_code
  , gft.alloc_short_name
From nu_gft_trp_gifttrans gft
Inner Join ksm_tbd On gft.allocation_code = ksm_tbd.allocation_code
Left Join deg On deg.id_number = gft.id_number
Left Join tms_trans On tms_trans.transaction_type_code = gft.transaction_type
Order By
  date_of_record Desc
  , credit_amount Desc
  , tx_sequence Asc
;
