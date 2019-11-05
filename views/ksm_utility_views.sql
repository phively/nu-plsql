Create Or Replace View v_current_calendar As
-- View compiling useful dates together for use in other functions in ksm_pkg
-- Naming convention:
  -- curr_, or no prefix, for current year, e.g. today, curr_fy
  -- prev_fy, prev_fy2, prev_fy3, etc. for 1, 2, 3 years ago, e.g. prev_fy_today
  -- next_fy, next_fy2, next_fy3, etc. for 1, 2, 3 years in the future, e.g. next_fy_today
  Select cal.*
  From table(ksm_pkg.tbl_current_calendar) cal
;

Create Or Replace View v_alloc_curr_use As
-- View implementing KSM Current Use allocations (including AF flag) from ksm_pkg
  Select cru.*
  From table(ksm_pkg.tbl_alloc_curr_use_ksm) cru
;

Create Or Replace View v_entity_ksm_degrees As
-- View implementing KSM degree/certificate definitions, including concatenated degree strings, from ksm_pkg
  Select deg.*
  From table(ksm_pkg.tbl_entity_degrees_concat_ksm) deg
;

Create Or Replace View v_entity_ksm_households As
-- View implementing the Kellogg householding definition from ksm_pkg
-- Do not try to load all rows as this households every entity record in the database
  Select hh.*
  From table(ksm_pkg.tbl_entity_households_ksm) hh
;

Create Or Replace View v_frontline_ksm_staff As
-- View for pulling current and past frontline KSM staff from ksm_pkg
-- New staff and start/stop dates need to be added to mv_past_ksm_gos to be reflected in this view
  Select fs.*
  From table(ksm_pkg.tbl_frontline_ksm_staff) fs
;

Create Or Replace View v_entity_special_handling As
-- View pulling together active special handling and mailing list codes for all entities with at least one
-- Use ONLY for Kellogg mailings!
  Select sh.*
  From table(ksm_pkg.tbl_special_handling_concat) sh
;

Create Or Replace View v_geo_code_primary As
-- View defining primary geo code for each active address
-- Primary key is id_number + xsequence
  Select *
  From table(ksm_pkg.tbl_geo_code_primary)
;
