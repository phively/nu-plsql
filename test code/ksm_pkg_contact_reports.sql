---------------------------
-- ksm_pkg_contact_reports tests
---------------------------

Select count(*)
From table(ksm_pkg_contact_reports.tbl_contact_reports)
;

With

test_cases As (
  Select '' As record_id, '' As explanation From DUAL
  Union Select 'CR-1689332', 'CR author and fundraiser credit' From DUAL
  Union Select 'CR-0015593', 'CR constituent author' From DUAL
)

Select cr.*
From table(ksm_pkg_contact_reports.tbl_contact_reports) cr
Inner Join test_cases
  On test_cases.record_id = cr.contact_report_record_id
;

---------------------------
-- mv tests and data check
---------------------------

