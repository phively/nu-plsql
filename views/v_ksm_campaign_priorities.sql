CREATE OR REPLACE VIEW RPT_ABM1914.V_KSM_CAMPAIGN_PRIORITIES AS

With
-- KSM-specific campaign new gifts & commitments definition

ksm_data As (
  Select *
  From table(rpt_pbh634.ksm_pkg.tbl_gift_credit_campaign)
)

-- Allocation-priority assignment, taken from RPT_BTAYLOR_WT09931_EXTRACTTRANSACTIONS

, priorities As (
  Select
    field01 As allocation_code
    , field02 As priority
  From WT099030_ALLOCATIONS_20111130 wt

)

  Select Distinct
  rcpt_or_plg_number
  , alloc_code
  -- Campaign priority coding
  -- Logic copied from function RPT_BTAYLOR.WT09931_EXTRACTTRANSACTIONS
  , Case
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
  End
  As ksm_campaign_category
  From ksm_data
  Left Join priorities On priorities.allocation_code = ksm_data.alloc_code
