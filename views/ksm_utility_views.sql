Create Or Replace View v_current_calendar As
-- View compiling useful dates together for use in other functions in ksm_pkg
-- Naming convention:
  -- curr_, or no prefix, for current year, e.g. today, curr_fy
  -- prev_fy, prev_fy2, prev_fy3, etc. for 1, 2, 3 years ago, e.g. prev_fy_today
  -- next_fy, next_fy2, next_fy3, etc. for 1, 2, 3 years in the future, e.g. next_fy_today
  Select *
  From table(ksm_pkg.tbl_current_calendar);
/

Create Or Replace View v_alloc_curr_use As
-- View implementing KSM Current Use allocations (including AF flag) from ksm_pkg
  Select *
  From table(ksm_pkg.tbl_alloc_curr_use_ksm);
/

Create Or Replace View v_entity_ksm_degrees As
-- View implementing KSM degree/certificate definitions, including concatenated degree strings, from ksm_pkg
  Select *
  From table(ksm_pkg.tbl_entity_degrees_concat_ksm);
/

Create Or Replace View v_entity_ksm_households As
-- View implementing the Kellogg householding definition from ksm_pkg
-- Do not try to load all rows as this households every entity record in the database
  Select *
  From table(ksm_pkg.tbl_entity_households_ksm);
/
