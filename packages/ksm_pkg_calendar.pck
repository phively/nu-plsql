Create Or Replace Package ksm_pkg_calendar Is

/*************************************************************************
Public type declarations
*************************************************************************/

Type calendar Is Record (
  today date
  , yesterday date
  , yesterday_last_year date
  , ninety_days_ago date
  , curr_fy number
  , prev_fy_start date
  , curr_fy_start date
  , next_fy_start date
  , curr_py number
  , prev_py_start date
  , curr_py_start date
  , next_py_start date
  , prev_fy_today date
  , next_fy_today date
  , prev_week_start date
  , curr_week_start date
  , next_week_start date
  , prev_month_start date
  , curr_month_start date
  , next_month_start date
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type t_calendar Is Table Of calendar;

/*************************************************************************
Public constant declarations
*************************************************************************/

-- Fiscal and performance start months
fy_start_month Constant number := 9; -- fiscal start month, 9 = September
py_start_month Constant number := 5; -- performance start month, 5 = May
py_start_month_py21 Constant number := 6; -- performance start month, 6 = June in PY2021 (COVID adjustment)

/*************************************************************************
Public function declarations
*************************************************************************/

-- Returns numeric constants
Function get_numeric_constant(
  const_name In varchar2 -- Name of constant to retrieve
) Return number Deterministic;

-- Parse yyyymmdd string into a date
-- If there are invalid date parts, overwrite with the corresponding element from fallback_dt
Function date_parse(
  date_str In varchar2
  , fallback_dt In date Default current_date()
) Return date;

-- Based on fy_start_month
Function fytd_indicator(
  dt In date
  , day_offset In number Default -1 -- default offset in days; -1 means up to yesterday is year-to-date, 0 up to today, etc.
) Return character; -- Y or N

-- Compute fiscal or performance quarter from date
Function get_quarter(
  dt In date
  , fisc_or_perf In varchar2 Default 'fiscal' -- 'f'iscal or 'p'erformance quarter
) Return number; -- Quarter, 1-4

-- Takes a date or string and returns the fiscal year
-- Date version
Function get_fiscal_year(
  dt In date
) Return number; -- Fiscal year part of date
-- String version
Function get_fiscal_year(
  dt In varchar2
  , format In varchar2 Default 'yyyy/mm/dd'
) Return number; -- Fiscal year part of date

-- Takes a date and returns the performance year
-- Date version
Function get_performance_year(
  dt In date
) Return number; -- Performance year part of date

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

-- Returns a 1-row table with selectable date objects (safe to cross join)
Function tbl_current_calendar
  Return t_calendar Pipelined;

End ksm_pkg_calendar;
/

Create Or Replace Package Body ksm_pkg_calendar Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/



/*************************************************************************
Functions
*************************************************************************/



/*************************************************************************
Pipelined functions
*************************************************************************/



End ksm_pkg_calendar;
/
