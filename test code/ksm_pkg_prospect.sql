---------------------------
-- ksm_pkg_prospect tests
---------------------------

Select *
From table(ksm_pkg_prospect.tbl_assignment_history)
;

Select *
From table(ksm_pkg_prospect.tbl_assignment_summary)
;

---------------------------
-- mv_assignments
---------------------------

Select *
From mv_assignments
Where ksm_manager_flag = 'Y'
;
