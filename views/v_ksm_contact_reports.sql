Create Or Replace View v_ksm_contact_reports As

/* Main query */
Select ard.*
From v_ard_contact_reports ard
Where frontline_ksm_staff = 'Y'
  And contact_date Between prev_fy_start And yesterday
