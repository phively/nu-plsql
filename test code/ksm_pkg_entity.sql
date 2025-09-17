---------------------------
-- ksm_pkg_entity tests
---------------------------

Select *
From table(ksm_pkg_entity.tbl_entity)
;

---------------------------
-- mv tests
---------------------------

Select *
From mv_entity_relationships
;

-- Check for blank role
Select Distinct
  primary_role
  , primary_role_type
From mv_entity_relationships
;
