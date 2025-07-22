---------------------------
-- ksm_pkg_proposals tests
---------------------------

Select count(*)
From table(ksm_pkg_proposals.tbl_proposals)
;

---------------------------
-- mv_proposals tests
---------------------------

Select count(*)
From mv_proposals
;

Select *
From mv_proposals
;
