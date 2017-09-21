Create Or Replace View v_current_calendar As
-- View compiling useful dates together for use in other functions
-- Naming convention:
  -- curr_, or no prefix, for current year, e.g. today, curr_fy
  -- prev_fy, prev_fy2, prev_fy3, etc. for 1, 2, 3 years ago, e.g. prev_fy_today
  -- next_fy, next_fy2, next_fy3, etc. for 1, 2, 3 years in the future, e.g. next_fy_today
  Select *
  From table(ksm_pkg.tbl_current_calendar);
/
