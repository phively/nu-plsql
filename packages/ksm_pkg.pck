Create Or Replace Package ksm_pkg_tmp Is

/*************************************************************************
Author  : PBH634
Created : 2/8/2017 5:43:38 PM
Purpose : Kellogg-specific package with lots of fun functions
Dependencies:
  v_addr_continents (view)
  mv_past_ksm_gos (materialized view)

Suggested naming convetions:
  Pure functions: [function type]_[description] e.g.
    math_mod
  Row-by-row retrieval (slow): get_[object type]_[action or description] e.g.
    get_entity_degrees_concat_ksm
    get_gift_source_donor_ksm
  Table or cursor retrieval (fast): tbl_[object type]_[action or description] e.g.
    tbl_alloc_annual_fund_ksm
    
*************************************************************************/

/*************************************************************************
Public function declarations
*************************************************************************/

/* Mathematical modulo operator */
Function math_mod(
  m In number
  , n In number
) Return number; -- m % n
  
/* Rewritten to_date to return NULL for invalid dates */
Function to_date2(
  str In varchar2
  , format In varchar2 Default 'yyyymmdd'
) Return date;

/* Rewritten to_number to return NULL for invalid strings */
Function to_number2(
  str In varchar2
) Return number;

/* Run the Vignere cypher on input text */
Function to_cypher_vigenere(
  phrase In varchar2
  , key In varchar2
  , wordlength In integer Default 5
) Return varchar2;

/* Parse yyyymmdd string into a date after checking for invalid terms */
Function date_parse(
  date_str In varchar2
  , fallback_dt In date Default current_date()
) Return date;

/* Fiscal year to date indicator */
Function fytd_indicator(
  dt In date
  , day_offset In number Default -1 -- default offset in days, -1 means up to yesterday is year-to-date, 0 up to today, etc.
) Return character; -- Y or N

/* Compute fiscal or performance quarter from date */
Function get_quarter(
  dt In date
  , fisc_or_perf In varchar2 Default 'fiscal' -- 'f'iscal or 'p'erformance quarter
) Return number; -- Quarter, 1-4

/* Takes a date and returns the fiscal year */
-- Date version
Function get_fiscal_year(
  dt In date
) Return number; -- Fiscal year part of date
-- String version
Function get_fiscal_year(
  dt In varchar2
  , format In varchar2 Default 'yyyy/mm/dd'
) Return number; -- Fiscal year part of date

/* Takes a date and returns the performance year */
-- Date version
Function get_performance_year(
  dt In date
) Return number; -- Performance year part of date

/* Quick SQL-only retrieval of KSM degrees concat */
Function get_entity_degrees_concat_fast(
  id In varchar2
) Return varchar2;

/* Return specified master address information, defined as preferred if available, else home if available, else business.
   The field parameter should match an address table field or tms table name, e.g. street1, state_code, country, etc. */
Function get_entity_address(
  id In varchar2 -- entity id_number
  , field In varchar2 -- address item to pull, including city, state_code, country, etc.
  , debug In boolean Default FALSE -- if TRUE, debug output is printed via dbms_output.put_line()
) Return varchar2; -- matched address piece

/* Take receipt number and return id_number of entity to receive primary Kellogg gift credit */
Function get_gift_source_donor_ksm(
  receipt In varchar2
  , debug In boolean Default FALSE -- if TRUE, debug output is printed via dbms_output.put_line()
) Return varchar2; -- entity id_number

/* Take a string containing a dollar amount and extract the (first) numeric value */
Function get_number_from_dollar(
  str In varchar2
) Return number;

/* Take entity ID and return officer or evaluation rating bin from nu_prs_trp_prospect */
Function get_prospect_rating_numeric(
  id In varchar2
) Return number;

/* Binned version of the results from get_prospect_rating_numeric */
Function get_prospect_rating_bin(
  id In varchar2
) Return number;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

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

Examples: 
Select ksm_af.*
From table(rpt_pbh634.ksm_pkg.tbl_alloc_annual_fund_ksm) ksm_af;
Select cal.*
From table(rpt_pbh634.ksm_pkg.tbl_current_calendar) cal;
*************************************************************************/

/* Return allocations, both active and historical, as a pipelined function */
Function tbl_alloc_annual_fund_ksm
  Return ksm_pkg_allocation.t_alloc_list Pipelined; -- returns list of matching values

Function tbl_alloc_curr_use_ksm
  Return ksm_pkg_allocation.t_alloc_info Pipelined; -- returns list of matching values

/* Return current calendar object */
Function tbl_current_calendar
  Return ksm_pkg_calendar.t_calendar Pipelined;

/* Return random IDs */
Function tbl_random_id(
  random_seed In varchar2 Default NULL
) Return ksm_pkg_datamasking.t_random_id Pipelined;

/* Return pipelined table of entity_degrees_concat_ksm */
Function tbl_entity_degrees_concat_ksm
  Return ksm_pkg_degrees.t_degreed_alumni Pipelined;

/* Return pipelined table of primary geo codes per address */
Function tbl_geo_code_primary
  Return ksm_pkg_address.t_geo_code_primary Pipelined;

/* Return pipelined table of entity_households_ksm */
Function tbl_entity_households_ksm
  Return ksm_pkg_households.t_household Pipelined;
  
/* Return pipelined table of company employees with Kellogg degrees
   N.B. uses matches pattern, user beware! */
Function tbl_entity_employees_ksm(company In varchar2)
  Return ksm_pkg_employment.t_employees Pipelined;
  
/* Return pipelined table of KLC members */
Function tbl_klc_history
  Return ksm_pkg_gifts_hh.t_klc_members Pipelined;

/* Return pipelined table of frontline KSM staff */
Function tbl_frontline_ksm_staff
  Return ksm_pkg_employment.t_ksm_staff Pipelined;

/* Return pipelined table of active prospect entities */
Function tbl_prospect_entity_active
  Return ksm_pkg_prospect.t_prospect_entity_active Pipelined;

/* Return pipelined table of current and past NU ARD staff, with most recent NU job */
Function tbl_nu_ard_staff
  Return ksm_pkg_employment.t_nu_ard_staff Pipelined;

/* Returns pipelined table of Kellogg transactions with household info */
Function plg_discount
  Return ksm_pkg_gifts.t_plg_disc Pipelined;

Function tbl_gift_credit
  Return ksm_pkg_gifts.t_trans_entity Pipelined;

Function tbl_gift_credit_ksm
  Return ksm_pkg_gifts.t_trans_entity Pipelined;
  
Function tbl_gift_credit_hh_ksm
  Return ksm_pkg_gifts_hh.t_trans_household Pipelined;

Function tbl_gift_credit_campaign
  Return ksm_pkg_gifts_campaign.t_trans_campaign Pipelined;
    
Function tbl_gift_credit_hh_campaign
  Return ksm_pkg_gifts_hh.t_trans_household Pipelined;

/* Return pipelined tasks */
Function tbl_university_strategy
  Return ksm_pkg_prospect.t_university_strategy Pipelined;

/* Return pipelined numeric ratings */
Function tbl_numeric_capacity_ratings
  Return ksm_pkg_prospect.t_numeric_capacity Pipelined;

/* Return pipelined model scores */
Function tbl_model_af_10k (
  model_year In integer Default NULL
  , model_month In integer Default NULL
) Return ksm_pkg_prospect.t_modeled_score Pipelined;

Function tbl_model_mg_identification (
  model_year In integer Default NULL
  , model_month In integer Default NULL
) Return ksm_pkg_prospect.t_modeled_score Pipelined;

Function tbl_model_mg_prioritization (
  model_year In integer Default NULL
  , model_month In integer Default NULL
) Return ksm_pkg_prospect.t_modeled_score Pipelined;

/* Return pipelined special handling preferences */
Function tbl_special_handling_concat
    Return ksm_pkg_special_handling.t_special_handling Pipelined;

-- Individual committees
Function tbl_committee_gab
  Return ksm_pkg_committee.t_committee_members Pipelined;

Function tbl_committee_phs
  Return ksm_pkg_committee.t_committee_members Pipelined;
    
Function tbl_committee_kac
  Return ksm_pkg_committee.t_committee_members Pipelined;

Function tbl_committee_kfn
  Return ksm_pkg_committee.t_committee_members Pipelined;
  
Function tbl_committee_corpGov
  Return ksm_pkg_committee.t_committee_members Pipelined;
  
Function tbl_committee_womenSummit
  Return ksm_pkg_committee.t_committee_members Pipelined;
  
Function tbl_committee_divSummit
  Return ksm_pkg_committee.t_committee_members Pipelined;
  
Function tbl_committee_realEstCouncil
  Return ksm_pkg_committee.t_committee_members Pipelined;
  
Function tbl_committee_amp
  Return ksm_pkg_committee.t_committee_members Pipelined;

Function tbl_committee_trustee
  Return ksm_pkg_committee.t_committee_members Pipelined;

Function tbl_committee_healthcare
  Return ksm_pkg_committee.t_committee_members Pipelined;
  
Function tbl_committee_womensLeadership
  Return ksm_pkg_committee.t_committee_members Pipelined;

Function tbl_committee_kalc
  Return ksm_pkg_committee.t_committee_members Pipelined;

Function tbl_committee_kic
  Return ksm_pkg_committee.t_committee_members Pipelined;
  
Function tbl_committee_privateEquity
  Return ksm_pkg_committee.t_committee_members Pipelined;

Function tbl_committee_pe_asia
  Return ksm_pkg_committee.t_committee_members Pipelined;
  
Function tbl_committee_asia
  Return ksm_pkg_committee.t_committee_members Pipelined;
  
Function tbl_committee_mbai
  Return ksm_pkg_committee.t_committee_members Pipelined;

Function tbl_committee_yab
  Return ksm_pkg_committee.t_committee_members Pipelined;

Function tbl_committee_tech
  Return ksm_pkg_committee.t_committee_members Pipelined;

/*************************************************************************
End of package
*************************************************************************/

End ksm_pkg_tmp;
/
Create Or Replace Package Body ksm_pkg_tmp Is

/*************************************************************************
Functions
*************************************************************************/

/* Calculates the modulo function; needed to correct Oracle mod() weirdness
   2017-02-08 */
Function math_mod(m In number, n In number)
  Return number Is
  Begin
    Return ksm_pkg_utility.math_mod(m, n);
  End;

/* Check whether a passed yyyymmdd string can be parsed sucessfully as a date 
   2019-01-24 */
Function to_date2(str In varchar2, format In varchar2)
  Return date Is
  Begin
    Return ksm_pkg_utility.to_date2(str, format);
  End;

/* Check whether a passed string can be parsed sucessfully as a number
   2019-08-02 */
Function to_number2(str In varchar2)
  Return number Is
  Begin
    Return ksm_pkg_utility.to_number2(str);
  End;

/* Run the Vignere cypher on input text
   2021-02-04 */
Function to_cypher_vigenere(
  phrase In varchar2
  , key In varchar2
  , wordlength In integer Default 5
)
  Return varchar2 Is
  -- Run cypher
  Begin
    Return ksm_pkg_datamasking.to_cypher_vigenere(
      phrase => phrase, key => key, wordlength => wordlength
    );
  End;

/* Takes a yyyymmdd string and an optional fallback date argument and produces a date type
   2019-01-24 */
Function date_parse(date_str In varchar2, fallback_dt In date)
  Return date Is
  Begin
    Return ksm_pkg_utility.date_parse(date_str, fallback_dt);
  End;


/* Fiscal year to date indicator: Takes as an argument any date object and returns Y/N
   2017-02-08 */
Function fytd_indicator(dt In date, day_offset In number)
  Return character Is
  Begin
    Return ksm_pkg_calendar.fytd_indicator(dt, day_offset);
  End;

/* Compute fiscal or performance quarter from date
   Defaults to fiscal quarter
   2018-04-06 */
Function get_quarter(dt In date, fisc_or_perf In varchar2 Default 'fiscal')
  Return number Is
  Begin
    Return ksm_pkg_calendar.get_quarter(dt, fisc_or_perf);
  End;

/* Compute fiscal year from date parameter
   2017-03-15 */
-- Date version
Function get_fiscal_year(dt In date)
  Return number Is
  Begin
    Return ksm_pkg_calendar.get_fiscal_year(dt);
  End;
-- String version
Function get_fiscal_year(dt In varchar2, format In varchar2 Default 'yyyy/mm/dd')
  Return number Is
  Begin
    Return ksm_pkg_calendar.get_fiscal_year(dt, format);
  End;

/* Compute performance year from date parameter
   2018-04-06 */
-- Date version
Function get_performance_year(dt In date)
  Return number Is
  Begin
    Return ksm_pkg_calendar.get_performance_year(dt);
  End;

/* Fast degree years concat
   2017-02-15 */
Function get_entity_degrees_concat_fast(id In varchar2)
  Return varchar2 Is
  Begin
    Return ksm_pkg_degrees.get_entity_degrees_concat_fast(id);
  End;

/* Takes an ID and field and returns active address part from master address. Standardizes input
   fields to lower-case.
   2017-02-15 */
Function get_entity_address(id In varchar2, field In varchar2, debug In Boolean Default FALSE)
  Return varchar2 Is
  Begin
    Return ksm_pkg_address.get_entity_address(id, field, debug);
  End;

/* Take a string containing a dollar amount and extract the (first) numeric value */
Function get_number_from_dollar(str In varchar2) 
  Return number Is
  Begin
    Return ksm_pkg_utility.get_number_from_dollar(str);
  End;

/* Convert rating to numeric amount */
Function get_prospect_rating_numeric(id In varchar2)
  Return number Is
  Begin
    Return ksm_pkg_prospect.get_prospect_rating_numeric(id);
  End;

/* Binned numeric prospect ratings */
Function get_prospect_rating_bin(id In varchar2)
  Return number Is
  Begin
    Return ksm_pkg_prospect.get_prospect_rating_bin(id);
  End;

/* Takes a receipt number and returns the ID number of the entity who should receive primary Kellogg gift credit.
   Relies on nu_gft_trp_gifttrans, which combines gifts and matching gifts into a single table.
   Kellogg alumni status is defined as get_entity_degrees_concat_ksm(id_number) returning a non-null result.
   2017-02-09 */
Function get_gift_source_donor_ksm(receipt In varchar2, debug In boolean Default FALSE)
  Return varchar2 Is  
  -- Table type corresponding to above cursor
  Begin
    Return ksm_pkg_gifts.get_gift_source_donor_ksm(receipt, debug);
  End;

/*************************************************************************
Pipelined functions
*************************************************************************/

-- Pipelined function returning Kellogg Annual Fund allocations, both active and historical
Function tbl_alloc_annual_fund_ksm
  Return ksm_pkg_allocation.t_alloc_list Pipelined As
    -- Declarations
    allocs ksm_pkg_allocation.t_alloc_list;

  Begin
    Open ksm_pkg_allocation.c_alloc_annual_fund_ksm; -- Annual Fund allocations cursor
      Fetch ksm_pkg_allocation.c_alloc_annual_fund_ksm Bulk Collect Into allocs;
    Close ksm_pkg_allocation.c_alloc_annual_fund_ksm;
    -- Pipe out the allocations
    For i in 1..(allocs.count) Loop
      Pipe row(allocs(i));
    End Loop;
    Return;
  End;

-- Pipelined function returning Kellogg current use allocations
Function tbl_alloc_curr_use_ksm
  Return ksm_pkg_allocation.t_alloc_info Pipelined As
    -- Declarations
    allocs ksm_pkg_allocation.t_alloc_info;

  Begin
    Open ksm_pkg_allocation.c_alloc_curr_use_ksm; -- Annual Fund allocations cursor
      Fetch ksm_pkg_allocation.c_alloc_curr_use_ksm Bulk Collect Into allocs;
    Close ksm_pkg_allocation.c_alloc_curr_use_ksm;
    -- Pipe out the allocations
    For i in 1..(allocs.count) Loop
      Pipe row(allocs(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning the current calendar definition
   2017-09-21 */
Function tbl_current_calendar
  Return ksm_pkg_calendar.t_calendar Pipelined As
  -- Declarations
  cal ksm_pkg_calendar.t_calendar;
  fy_start_month number;
  py_start_month number;
    
  Begin
    fy_start_month := ksm_pkg_calendar.get_numeric_constant('fy_start_month');
    py_start_month := ksm_pkg_calendar.get_numeric_constant('py_start_month');
    Open ksm_pkg_calendar.c_current_calendar(fy_start_month, py_start_month);
      Fetch ksm_pkg_calendar.c_current_calendar Bulk Collect Into cal;
    Close ksm_pkg_calendar.c_current_calendar;
    For i in 1..(cal.count) Loop
      Pipe row(cal(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning a randomly generated ID conversion table
   2020-02-11 */
Function tbl_random_id(random_seed In varchar2 Default NULL)
  Return ksm_pkg_datamasking.t_random_id Pipelined As
  -- Declarations
  rid ksm_pkg_datamasking.t_random_id;
  
  Begin
    -- Set seed
    If random_seed Is Not Null Then
      -- Set random seed
      dbms_random.seed(random_seed);
    End If;
    Open ksm_pkg_datamasking.c_random_id;
      Fetch ksm_pkg_datamasking.c_random_id Bulk Collect Into rid;
    Close ksm_pkg_datamasking.c_random_id;
    For i in 1..(rid.count) Loop
      Pipe row(rid(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning all non-null entity_degrees_concat_ksm rows
   2017-02-15 */
Function tbl_entity_degrees_concat_ksm
  Return ksm_pkg_degrees.t_degreed_alumni Pipelined As
  -- Declarations
  degrees ksm_pkg_degrees.t_degreed_alumni;
    
  Begin
    Open ksm_pkg_degrees.c_entity_degrees_concat_ksm;
      Fetch ksm_pkg_degrees.c_entity_degrees_concat_ksm Bulk Collect Into degrees;
    Close ksm_pkg_degrees.c_entity_degrees_concat_ksm;
    For i in 1..(degrees.count) Loop
      Pipe row(degrees(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning concatenated geo codes for all addresses
   2019-11-05 */
Function tbl_geo_code_primary
  Return ksm_pkg_address.t_geo_code_primary Pipelined As
  -- Declarations
  geo ksm_pkg_address.t_geo_code_primary;
  
  Begin
    Open ksm_pkg_address.c_geo_code_primary;
      Fetch ksm_pkg_address.c_geo_code_primary Bulk Collect Into geo;
    Close ksm_pkg_address.c_geo_code_primary;
    For i in 1..(geo.count) Loop
      Pipe row(geo(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning households and household degree information
   2017-02-15 */
Function tbl_entity_households_ksm
  Return ksm_pkg_households.t_household Pipelined As
  -- Declarations
  households ksm_pkg_households.t_household;
  
  Begin
    Open ksm_pkg_households.c_entity_households;
      Fetch ksm_pkg_households.c_entity_households Bulk Collect Into households;
    Close ksm_pkg_households.c_entity_households;
    For i in 1..(households.count) Loop
      Pipe row(households(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning Kellogg alumni (per c_entity_degrees_concat_ksm) who
   work for the specified company
   2017-07-25 */
Function tbl_entity_employees_ksm(company In varchar2)
  Return ksm_pkg_employment.t_employees Pipelined As
  -- Declarations
  employees ksm_pkg_employment.t_employees;
  
  Begin
    Open ksm_pkg_employment.c_entity_employees_ksm(company => company);
      Fetch ksm_pkg_employment.c_entity_employees_ksm Bulk Collect Into employees;
    Close ksm_pkg_employment.c_entity_employees_ksm;
    For i in 1..(employees.count) Loop
      Pipe row(employees(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning KLC members (per c_klc_history)
   2017-07-26 */
Function tbl_klc_history
  Return ksm_pkg_gifts_hh.t_klc_members Pipelined As
  -- Declarations
  klc ksm_pkg_gifts_hh.t_klc_members;
  
  Begin
    Open ksm_pkg_gifts_hh.c_klc_history(ksm_pkg_calendar.get_numeric_constant('fy_start_month'));
      Fetch ksm_pkg_gifts_hh.c_klc_history Bulk Collect Into klc;
    Close ksm_pkg_gifts_hh.c_klc_history;
    For i in 1..(klc.count) Loop
      Pipe row(klc(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning frontline KSM staff (per c_frontline_ksm_staff)
   2017-09-26 */
Function tbl_frontline_ksm_staff
  Return ksm_pkg_employment.t_ksm_staff Pipelined As
  -- Declarations
  staff ksm_pkg_employment.t_ksm_staff;
    
  Begin
    Open ksm_pkg_employment.c_frontline_ksm_staff;
      Fetch ksm_pkg_employment.c_frontline_ksm_staff Bulk Collect Into staff;
    Close ksm_pkg_employment.c_frontline_ksm_staff;
    For i in 1..(staff.count) Loop
      Pipe row(staff(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning prospect entity table filtered for active prospects
   2018-08-14 */
Function tbl_prospect_entity_active
  Return ksm_pkg_prospect.t_prospect_entity_active Pipelined As
  -- Declarations
  pe ksm_pkg_prospect.t_prospect_entity_active;
    
  Begin
    Open ksm_pkg_prospect.c_prospect_entity_active;
      Fetch ksm_pkg_prospect.c_prospect_entity_active Bulk Collect Into pe;
    Close ksm_pkg_prospect.c_prospect_entity_active;
    For i in 1..(pe.count) Loop
      Pipe row(pe(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning current/historical NU ARD employees (per c_nu_ard_staff)
   2018-01-17 */
Function tbl_nu_ard_staff
  Return ksm_pkg_employment.t_nu_ard_staff Pipelined As
  -- Declarations
  staff ksm_pkg_employment.t_nu_ard_staff;
    
  Begin
    Open ksm_pkg_employment.c_nu_ard_staff;
      Fetch ksm_pkg_employment.c_nu_ard_staff Bulk Collect Into staff;
    Close ksm_pkg_employment.c_nu_ard_staff;
    For i in 1..(staff.count) Loop
      Pipe row(staff(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning current university strategies (per c_university_strategy)
   2017-09-29 */
Function tbl_university_strategy
  Return ksm_pkg_prospect.t_university_strategy Pipelined As
  -- Declarations
  task ksm_pkg_prospect.t_university_strategy;
    
  Begin
    Open ksm_pkg_prospect.c_university_strategy;
      Fetch ksm_pkg_prospect.c_university_strategy Bulk Collect Into task;
    Close ksm_pkg_prospect.c_university_strategy;
    For i in 1..(task.count) Loop
      Pipe row(task(i));
    End Loop;
    Return;
  End;

/* Pipelined function returning numeric capacity and binned capacity */
Function tbl_numeric_capacity_ratings
  Return ksm_pkg_prospect.t_numeric_capacity Pipelined As
  -- Declarations
  caps ksm_pkg_prospect.t_numeric_capacity;

  Begin
    Open ksm_pkg_prospect.c_numeric_capacity_ratings;
      Fetch ksm_pkg_prospect.c_numeric_capacity_ratings Bulk Collect Into caps;
    Close ksm_pkg_prospect.c_numeric_capacity_ratings;
    For i in 1..(caps.count) Loop
      Pipe row(caps(i));
    End Loop;
    Return;
  End;
  
/* Pipelined function for Kellogg modeled scores */
  -- AF 10K model
  Function tbl_model_af_10k(
    model_year In integer Default NULL
    , model_month In integer Default NULL
    )
    Return ksm_pkg_prospect.t_modeled_score Pipelined As
    -- Declarations
    score ksm_pkg_prospect.t_modeled_score;

    Begin
      score := ksm_pkg_prospect.c_segment_extract(
        year => nvl(model_year, ksm_pkg_prospect.get_numeric_constant('seg_af_10k_yr'))
        , month => nvl(model_month, ksm_pkg_prospect.get_numeric_constant('seg_af_10k_mo'))
        , code => ksm_pkg_prospect.get_string_constant('seg_af_10k')
      );
      For i in 1..(score.count) Loop
        Pipe row(score(i));
      End Loop;
      Return;
    End;

  -- MG identification model
  Function tbl_model_mg_identification (
    model_year In integer Default NULL
    , model_month In integer Default NULL
    )
    Return ksm_pkg_prospect.t_modeled_score Pipelined As
    -- Declarations
    score ksm_pkg_prospect.t_modeled_score;

    Begin
      score := ksm_pkg_prospect.c_segment_extract(
        year => nvl(model_year, ksm_pkg_prospect.get_numeric_constant('seg_mg_yr'))
        , month => nvl(model_month, ksm_pkg_prospect.get_numeric_constant('seg_mg_mo'))
        , code => ksm_pkg_prospect.get_string_constant('seg_mg_id')
      );
      For i in 1..(score.count) Loop
        Pipe row(score(i));
      End Loop;
      Return;
    End;

  -- MG prioritization model
  Function tbl_model_mg_prioritization (
    model_year In integer Default NULL
    , model_month In integer Default NULL
  )
    Return ksm_pkg_prospect.t_modeled_score Pipelined As
    -- Declarations
    score ksm_pkg_prospect.t_modeled_score;
    
    Begin
      score := ksm_pkg_prospect.c_segment_extract(
        year => nvl(model_year, ksm_pkg_prospect.get_numeric_constant('seg_mg_yr'))
        , month => nvl(model_month, ksm_pkg_prospect.get_numeric_constant('seg_mg_mo'))
        , code => ksm_pkg_prospect.get_string_constant('seg_mg_pr')
      );
      For i in 1..(score.count) Loop
        Pipe row(score(i));
      End Loop;
      Return;
    End;

/* Pipelined function returning giving credit for entities or households */

  /* Function to return discounted pledge amounts */
  Function plg_discount
    Return ksm_pkg_gifts.t_plg_disc Pipelined As
    -- Declarations
    trans ksm_pkg_gifts.t_plg_disc;
    
    Begin
      Open ksm_pkg_gifts.c_plg_discount;
        Fetch ksm_pkg_gifts.c_plg_discount Bulk Collect Into trans;
      Close ksm_pkg_gifts.c_plg_discount;
      For i in 1..(trans.count) Loop
        Pipe row(trans(i));
      End Loop;
      Return;
    End;

  /* Individual entity giving, all units, based on c_gift_credit
     2019-10-25 */
  Function tbl_gift_credit
    Return ksm_pkg_gifts.t_trans_entity Pipelined As
    -- Declarations
    trans ksm_pkg_gifts.t_trans_entity;
    
    Begin
      Open ksm_pkg_gifts.c_gift_credit;
        Fetch ksm_pkg_gifts.c_gift_credit Bulk Collect Into trans;
      Close ksm_pkg_gifts.c_gift_credit;
      For i in 1..(trans.count) Loop
        Pipe row(trans(i));
      End Loop;
      Return;
    End;
    

  /* Individual entity giving, based on c_gift_credit_ksm
     2017-08-04 */
  Function tbl_gift_credit_ksm
    Return ksm_pkg_gifts.t_trans_entity Pipelined As
    -- Declarations
    trans ksm_pkg_gifts.t_trans_entity;
    
    Begin
      Open ksm_pkg_gifts.c_gift_credit_ksm;
        Fetch ksm_pkg_gifts.c_gift_credit_ksm Bulk Collect Into trans;
      Close ksm_pkg_gifts.c_gift_credit_ksm;
      For i in 1..(trans.count) Loop
        Pipe row(trans(i));
      End Loop;
      Return;
    End;

  /* Householdable entity giving, based on c_gift_credit_hh_ksm
     2017-08-04 */
  Function tbl_gift_credit_hh_ksm
    Return ksm_pkg_gifts_hh.t_trans_household Pipelined As
    -- Declarations
    trans ksm_pkg_gifts_hh.t_trans_household;
    
    Begin
      Open ksm_pkg_gifts_hh.c_gift_credit_hh_ksm;
        Fetch ksm_pkg_gifts_hh.c_gift_credit_hh_ksm Bulk Collect Into trans;
      Close ksm_pkg_gifts_hh.c_gift_credit_hh_ksm;
      For i in 1..(trans.count) Loop
        Pipe row(trans(i));
      End Loop;
      Return;
    End;

  /* Campaign giving by entity, based on c_gifts_campaign_2008
     2017-08-04 */
  Function tbl_gift_credit_campaign
    Return ksm_pkg_gifts_campaign.t_trans_campaign Pipelined As
    -- Declarations
    trans ksm_pkg_gifts_campaign.t_trans_campaign;
    
    Begin
      Open ksm_pkg_gifts_campaign.c_gift_credit_campaign_2008;
        Fetch ksm_pkg_gifts_campaign.c_gift_credit_campaign_2008 Bulk Collect Into trans;
      Close ksm_pkg_gifts_campaign.c_gift_credit_campaign_2008;
      For i in 1..(trans.count) Loop
        Pipe row(trans(i));
      End Loop;
      Return;
    End;

  /* Householdable entity campaign giving, based on c_ksm_trans_hh_campaign_2008
     2017-09-05 */
  Function tbl_gift_credit_hh_campaign
    Return ksm_pkg_gifts_hh.t_trans_household Pipelined As
    -- Declarations
    trans ksm_pkg_gifts_hh.t_trans_household;
    
    Begin
      Open ksm_pkg_gifts_campaign.c_gift_credit_hh_campaign_2008;
        Fetch ksm_pkg_gifts_campaign.c_gift_credit_hh_campaign_2008 Bulk Collect Into trans;
      Close ksm_pkg_gifts_campaign.c_gift_credit_hh_campaign_2008;
      For i in 1..(trans.count) Loop
        Pipe row(trans(i));
      End Loop;
      Return;
    End;

/* Concatenated special handling preferences */

Function tbl_special_handling_concat
    Return ksm_pkg_special_handling.t_special_handling Pipelined As
    -- Declarations
    hnd ksm_pkg_special_handling.t_special_handling;
    
    Begin
      Open ksm_pkg_special_handling.c_special_handling_concat;
        Fetch ksm_pkg_special_handling.c_special_handling_concat Bulk Collect Into hnd;
      Close ksm_pkg_special_handling.c_special_handling_concat;
      For i in 1..(hnd.count) Loop
        Pipe row(hnd(i));
      End Loop;
      Return;
    End;

/* Pipelined function for Kellogg committees */
  -- GAB
  Function tbl_committee_gab
    Return ksm_pkg_committee.t_committee_members Pipelined As
    committees ksm_pkg_committee.t_committee_members;
    
    Begin
    committees := ksm_pkg_committee.c_committee_members(my_committee_cd => ksm_pkg_committee.get_string_constant('committee_gab'));
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;
  
  -- KAC
  Function tbl_committee_kac
    Return ksm_pkg_committee.t_committee_members Pipelined As
    committees ksm_pkg_committee.t_committee_members;
    
    Begin
      committees := ksm_pkg_committee.c_committee_members(my_committee_cd => ksm_pkg_committee.get_string_constant('committee_kac'));
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;

  -- PHS
  Function tbl_committee_phs
    Return ksm_pkg_committee.t_committee_members Pipelined As
    committees ksm_pkg_committee.t_committee_members;
    
    Begin
      committees := ksm_pkg_committee.c_committee_members(my_committee_cd => ksm_pkg_committee.get_string_constant('committee_phs'));
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;

  -- KFN
  Function tbl_committee_kfn
    Return ksm_pkg_committee.t_committee_members Pipelined As
    committees ksm_pkg_committee.t_committee_members;
    
    Begin
      committees := ksm_pkg_committee.c_committee_members(my_committee_cd =>ksm_pkg_committee.get_string_constant('committee_kfn'));
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;

  -- CorpGov
  Function tbl_committee_corpGov
    Return ksm_pkg_committee.t_committee_members Pipelined As
    committees ksm_pkg_committee.t_committee_members;
    
    Begin
      committees := ksm_pkg_committee.c_committee_members(my_committee_cd => ksm_pkg_committee.get_string_constant('committee_corpGov'));
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;
    
  -- GlobalWomenSummit
  Function tbl_committee_womenSummit
    Return ksm_pkg_committee.t_committee_members Pipelined As
    committees ksm_pkg_committee.t_committee_members;
    
    Begin
      committees := ksm_pkg_committee.c_committee_members(my_committee_cd => ksm_pkg_committee.get_string_constant('committee_womenSummit'));
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;
    
  -- DivSummit
  Function tbl_committee_divSummit
    Return ksm_pkg_committee.t_committee_members Pipelined As
    committees ksm_pkg_committee.t_committee_members;
    
    Begin
      committees := ksm_pkg_committee.c_committee_members(my_committee_cd => ksm_pkg_committee.get_string_constant('committee_divSummit'));
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;
    
  -- RealEstCouncil
  Function tbl_committee_realEstCouncil
    Return ksm_pkg_committee.t_committee_members Pipelined As
    committees ksm_pkg_committee.t_committee_members;
    
    Begin
      committees := ksm_pkg_committee.c_committee_members(my_committee_cd => ksm_pkg_committee.get_string_constant('committee_realEstCouncil'));
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;

  -- AMP
  Function tbl_committee_amp
    Return ksm_pkg_committee.t_committee_members Pipelined As
    committees ksm_pkg_committee.t_committee_members;
    
    Begin
      committees := ksm_pkg_committee.c_committee_members(my_committee_cd => ksm_pkg_committee.get_string_constant('committee_amp'));
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;

  -- Trustees
  Function tbl_committee_trustee
    Return ksm_pkg_committee.t_committee_members Pipelined As
    committees ksm_pkg_committee.t_committee_members;
    
    Begin
      committees := ksm_pkg_committee.c_committee_members(my_committee_cd => ksm_pkg_committee.get_string_constant('committee_trustee'));
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;

    -- Healthcare
    Function tbl_committee_healthcare
      Return ksm_pkg_committee.t_committee_members Pipelined As
      committees ksm_pkg_committee.t_committee_members;
      
      Begin
        committees := ksm_pkg_committee.c_committee_members(my_committee_cd => ksm_pkg_committee.get_string_constant('committee_healthcare'));
        For i in 1..committees.count Loop
          Pipe row(committees(i));
        End Loop;
        Return;
      End;

    -- Women's leadership
    Function tbl_committee_womensLeadership
      Return ksm_pkg_committee.t_committee_members Pipelined As
      committees ksm_pkg_committee.t_committee_members;
      
      Begin
        committees := ksm_pkg_committee.c_committee_members(my_committee_cd => ksm_pkg_committee.get_string_constant('committee_womensLeadership'));
        For i in 1..committees.count Loop
          Pipe row(committees(i));
        End Loop;
        Return;
      End;
      
    -- Kellogg Admissions Leadership Council
    Function tbl_committee_kalc
      Return ksm_pkg_committee.t_committee_members Pipelined As
      committees ksm_pkg_committee.t_committee_members;
      
      Begin
        committees := ksm_pkg_committee.c_committee_members(my_committee_cd => ksm_pkg_committee.get_string_constant('committee_kalc'));
        For i in 1..committees.count Loop
          Pipe row(committees(i));
        End Loop;
        Return;
      End;
    
    -- Kellogg Inclusion Coalition
    Function tbl_committee_kic
      Return ksm_pkg_committee.t_committee_members Pipelined As
      committees ksm_pkg_committee.t_committee_members;
      
      Begin
        committees := ksm_pkg_committee.c_committee_members(my_committee_cd => ksm_pkg_committee.get_string_constant('committee_kic'));
        For i in 1..committees.count Loop
          Pipe row(committees(i));
        End Loop;
        Return;
      End;
      
    --  Kellogg Private Equity Taskforce Council
    Function tbl_committee_privateEquity
      Return ksm_pkg_committee.t_committee_members Pipelined As
      committees ksm_pkg_committee.t_committee_members;
        
      Begin
        committees := ksm_pkg_committee.c_committee_members(my_committee_cd => ksm_pkg_committee.get_string_constant('committee_privateEquity'));
        For i in 1..committees.count Loop
          Pipe row(committees(i));
        End Loop;
        Return;
      End;

    --  Kellogg Private Equity Taskforce Council
    Function tbl_committee_pe_asia
      Return ksm_pkg_committee.t_committee_members Pipelined As
      committees ksm_pkg_committee.t_committee_members;
        
      Begin
        committees := ksm_pkg_committee.c_committee_members(my_committee_cd => ksm_pkg_committee.get_string_constant('committee_pe_asia'));
        For i in 1..committees.count Loop
          Pipe row(committees(i));
        End Loop;
        Return;
      End;

    --  Kellogg Executive Board for Asia
    Function tbl_committee_asia
      Return ksm_pkg_committee.t_committee_members Pipelined As
      committees ksm_pkg_committee.t_committee_members;
        
      Begin
        committees := ksm_pkg_committee.c_committee_members(my_committee_cd => ksm_pkg_committee.get_string_constant('committee_asia'));
        For i in 1..committees.count Loop
          Pipe row(committees(i));
        End Loop;
        Return;
      End;
      
    --  Kellogg MBAi Advisory Council
    Function tbl_committee_mbai
      Return ksm_pkg_committee.t_committee_members Pipelined As
      committees ksm_pkg_committee.t_committee_members;
        
      Begin
        committees := ksm_pkg_committee.c_committee_members(my_committee_cd => ksm_pkg_committee.get_string_constant('committee_mbai'));
        For i in 1..committees.count Loop
          Pipe row(committees(i));
        End Loop;
        Return;
      End;

    --  Kellogg Young Alumni Board
    Function tbl_committee_yab
      Return ksm_pkg_committee.t_committee_members Pipelined As
      committees ksm_pkg_committee.t_committee_members;
        
      Begin
        committees := ksm_pkg_committee.c_committee_members(my_committee_cd => ksm_pkg_committee.get_string_constant('committee_yab'));
        For i in 1..committees.count Loop
          Pipe row(committees(i));
        End Loop;
        Return;
      End;

    --  Kellogg Alumni Tech Council
    Function tbl_committee_tech
      Return ksm_pkg_committee.t_committee_members Pipelined As
      committees ksm_pkg_committee.t_committee_members;
        
      Begin
        committees := ksm_pkg_committee.c_committee_members(my_committee_cd => ksm_pkg_committee.get_string_constant('committee_tech'));
        For i in 1..committees.count Loop
          Pipe row(committees(i));
        End Loop;
        Return;
      End;

End ksm_pkg_tmp;
/
