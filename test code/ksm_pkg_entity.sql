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

-- Check for shared household_id_ksm
Select *
From mv_entity
Where donor_id In ('0000469096', '0003379658')
;

-- Ensure no nulls
Select count(household_id), count(household_id_ksm)
From mv_entity
;
