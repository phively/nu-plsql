---------------------------
-- ksm_pkg_giving_summary tests
---------------------------

-- Table functions
Select *
From table(ksm_pkg_giving_summary.tbl_ksm_giving_summary) gs
Where gs.household_primary_donor_id = '0000086400'
;

Select ltg.*
From table(ksm_pkg_giving_summary.tbl_lifetime_giving) ltg
;

---------------------------
-- lifetime giving audit
---------------------------

-- Check for no null values
With

test_cases As (
  Select '0000421394' As donor_id, 'Individual' As explanation From DUAL
  Union Select '0000704936', 'Individual' From DUAL
  Union Select '0000501347', 'Individual' From DUAL
  Union Select '0000595343', 'Individual + Spouse' From DUAL
  Union Select '0003375876', 'Spouse + Individual' From DUAL
)

Select
  test_cases.explanation
  , ltg.donor_id
  , ltg.sort_name
  , ltg.household_id
  , ltg.nu_lifetime_ngc
  , ltg.nu_lifetime_ngc_individual
  , ltg.nu_lifetime_ngc_with_spouse
  , ltg.etl_update_date
From table(ksm_pkg_giving_summary.tbl_lifetime_giving) ltg
Inner Join test_cases
  On test_cases.donor_id = ltg.donor_id
;
