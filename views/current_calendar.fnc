Create Or Replace View current_calendar As
/* 
Created by pbh634
Compiles useful dates together for use in other functions.
*/

-- If the fiscal start month ever changes from September (9) change here
With fy_start_month As (
  Select 9 As nbr
  From DUAL
),

-- Calculate current fiscal year; always year + 1 unless the FY starts in Jan
curr_date As (
  Select
  -- Current fiscal year; uses constant above
  Case
    When extract(month from sysdate) >= fy_start_month.nbr
      And fy_start_month.nbr != 1
      Then extract(year from sysdate) + 1 
    Else extract(year from sysdate)
  End As yr,
  -- Correction for starting after January
  Case
    When fy_start_month.nbr != 1 Then 1 Else 0
  End As yr_dif
  From fy_start_month
)

-- Final table with definitions
Select
  -- Current day
  trunc(sysdate) As today,
  -- Yesterday
  trunc(sysdate - 1) As yesterday,
  -- Current fiscal year
  curr_date.yr As curr_fy,
  -- Start of fiscal year objects
  to_date(fy_start_month.nbr || '/01/' || (curr_date.yr - yr_dif - 1), 'mm/dd/yyyy')
    As prev_fy_start,
  to_date(fy_start_month.nbr || '/01/' || (curr_date.yr - yr_dif + 0), 'mm/dd/yyyy')
    As curr_fy_start,
  to_date(fy_start_month.nbr || '/01/' || (curr_date.yr - yr_dif + 1), 'mm/dd/yyyy')
    As next_fy_start
From fy_start_month, curr_date
