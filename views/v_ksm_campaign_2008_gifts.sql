Create Or Replace View v_ksm_campaign_2008_gifts As

With 

/* Current calendar */
cal As (
  Select yesterday
  From v_current_calendar
),

/* KSM-specific campaign new gifts & commitments definition */
ksm_data As (
  Select *
  From table(ksm_pkg.tbl_gift_credit_campaign)
),

/* Allocation-priority assignment, taken from RPT_BTAYLOR_WT09931_EXTRACTTRANSACTIONS */
priorities As (
  Select field01 As allocation_code, field02 As priority
  From WT099030_ALLOCATIONS_20111130 wt
),

/* Additional KSM-specific derived fields */
ksm_campaign As (
  Select ksm_data.*,
    -- Prospect data fields
    entity.report_name, entity.institutional_suffix,
    prs.business_title, trim(prs.employer_name1 || ' ' || prs.employer_name2) As employer_name,
    prs.pref_state, prs.preferred_country, prs.evaluation_rating, prs.evaluation_date, prs.officer_rating,
    -- Fiscal year-to-date indicator
    ksm_pkg.fytd_indicator(date_of_record) As ftyd_ind,
    -- Calendar objects
    cal.curr_fy,
    -- Giving bin
    Case
      When amount >= 1000000 Then 'A $1M+'
      When amount >= 100000  Then 'B $100K-$999.9K'
      When amount >= 50000   Then 'C $50K-$99.9K'
      When amount >= 2500    Then 'D $2.5K-$49.9K'
      When amount <  2500    Then 'E <$2.5K'
    End As giving_band,
    -- Campaign priority coding
    -- Logic copied from function RPT_BTAYLOR.WT09931_EXTRACTTRANSACTIONS
    Case
      -- Special receipt overrides
      When rcpt_or_plg_number In ('0002214209', '0002224310', '0002323505', '0002259492', '0002293065', '0002335663')
        Then 'Global Hub'
      When rcpt_or_plg_number In ('0002144755')
        Then 'Global Innovation'
      When rcpt_or_plg_number In ('0002299914', '0002263981', '0002011088', '0002414118')
        Then 'Thought Leadership'
      -- General logic
      When alloc_code In ('BE', 'LE')
        Then 'Educational Mission Unrestricted'
      When alloc_code = '3303000882101GFT'
        Then 'Global Hub'
      When priority = 'Kellogg Capital Projects'
        And Not (date_of_record >= to_date('20100901', 'YYYYMMDD') And annual_sw = 'Y')
        Then 'Educational Mission'
      -- Global Innovation logic
      When priority = 'Global Innovation' Or (date_of_record >= to_date('20100901', 'YYYYMMDD') And annual_sw = 'Y') Then (
        Case
          When year_of_giving >= '2011' And (annual_sw = 'Y' Or alloc_code = 'BE')
            Then 'Global Innovation Unrestricted'
          When date_of_record >= to_date('20100901', 'YYYYMMDD') And annual_sw = 'Y'
            Then 'Global Innovation'
          Else priority
        End
      )
      When date_of_record >= to_date('20100901', 'YYYYMMDD') And annual_sw = 'Y'
        Then 'Global Innovation'
      -- Fallback -- read from WT099030_ALLOCATIONS_20111130 table
      Else priority
    End As ksm_campaign_category,
    -- Replace null ksm_source_donor with id_number
    NVL(ksm_pkg.get_gift_source_donor_ksm(rcpt_or_plg_number), ksm_data.id_number) As ksm_source_donor
  From ksm_data
  Cross Join v_current_calendar cal
  Inner Join entity On ksm_data.id_number = entity.id_number
  Left Join priorities On priorities.allocation_code = ksm_data.alloc_code
  Left Join nu_prs_trp_prospect prs On prs.id_number = ksm_data.id_number
)

/* Main query */
Select ksm_campaign.*,
  hh.household_id, hh.household_name, hh.household_rpt_name, hh.household_ksm_year, hh.household_program_group, hh.household_suffix,
  hh.household_spouse, hh.household_spouse_suffix,
  hh.household_city, hh.household_state, hh.household_country,
  -- Record type
  Case
    When household_record = 'ST' Then '3 Students'
    When household_record In ('AL', 'FA') Then '1 Alumni'
    When household_record In ('NA', 'FN') Then '2 Non-Alumni'
    When household_record In ('CP', 'CF') Then '4 Corporations'
    When household_record = 'FP' Then '5 Foundations'
    Else '6 Other Organizations'
  End As hh_source_ksm,
  -- Calendar
  yesterday
From ksm_campaign
Cross Join cal
Inner Join table(ksm_pkg.tbl_entity_households_ksm) hh On ksm_campaign.ksm_source_donor = hh.id_number
