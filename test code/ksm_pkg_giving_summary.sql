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
