---------------------------
-- ksm_pkg_calendar tests
---------------------------

-- Constants
Select
    ksm_pkg_calendar.get_numeric_constant('fy_start_month') As fy_start_month -- 9
  , ksm_pkg_calendar.get_numeric_constant('py_start_month') As py_start_month -- 5
  , ksm_pkg_calendar.get_numeric_constant('py_start_month_py21') As py_start_month_py21 -- 6
  , ksm_pkg_calendar.get_numeric_constant('ksm_pkg_calendar.fy_start_month') As fy_start_month -- 9
  , ksm_pkg_calendar.get_numeric_constant('ksm_pkg_calendar.py_start_month') As py_start_month -- 5
  , ksm_pkg_calendar.get_numeric_constant('ksm_pkg_calendar.py_start_month_py21') As py_start_month_py21 -- 6
From DUAL
;

-- Table functions
Select *
From table(ksm_pkg_calendar.tbl_current_calendar)
;

-- Functions
Select
  ksm_pkg_calendar.fytd_indicator(trunc(sysdate)) As N
  , ksm_pkg_calendar.fytd_indicator(trunc(sysdate), day_offset => 0) As Y
From DUAL
;

Select
    ksm_pkg_calendar.get_quarter(to_date('20000901', 'yyyymmdd')) As "1"
  , ksm_pkg_calendar.get_quarter(to_date('20001201', 'yyyymmdd')) As "2"
  , ksm_pkg_calendar.get_quarter(to_date('20000301', 'yyyymmdd')) As "3"
  , ksm_pkg_calendar.get_quarter(to_date('20000601', 'yyyymmdd')) As "4"
  , ksm_pkg_calendar.get_quarter(to_date('20000901', 'yyyymmdd'), 'p') As "2"
  , ksm_pkg_calendar.get_quarter(to_date('20001201', 'yyyymmdd'), 'p') As "3"
  , ksm_pkg_calendar.get_quarter(to_date('20000301', 'yyyymmdd'), 'p') As "4"
  , ksm_pkg_calendar.get_quarter(to_date('20000601', 'yyyymmdd'), 'p') As "1"
From DUAL
;

-- Fiscal month tests
Select
  ksm_pkg_calendar.get_fiscal_month(to_date('20200905', 'yyyymmdd')) As "1"
  , ksm_pkg_calendar.get_fiscal_month(to_date('20201005', 'yyyymmdd')) As "2"
  , ksm_pkg_calendar.get_fiscal_month(to_date('20201105', 'yyyymmdd')) As "3"
  , ksm_pkg_calendar.get_fiscal_month(to_date('20201205', 'yyyymmdd')) As "4"
  , ksm_pkg_calendar.get_fiscal_month(to_date('20210105', 'yyyymmdd')) As "5"
  , ksm_pkg_calendar.get_fiscal_month(to_date('20210205', 'yyyymmdd')) As "6"
  , ksm_pkg_calendar.get_fiscal_month(to_date('20210305', 'yyyymmdd')) As "7"
  , ksm_pkg_calendar.get_fiscal_month(to_date('20210405', 'yyyymmdd')) As "8"
  , ksm_pkg_calendar.get_fiscal_month(to_date('20210505', 'yyyymmdd')) As "9"
  , ksm_pkg_calendar.get_fiscal_month(to_date('20210605', 'yyyymmdd')) As "10"
  , ksm_pkg_calendar.get_fiscal_month(to_date('20210705', 'yyyymmdd')) As "11"
  , ksm_pkg_calendar.get_fiscal_month(to_date('20210805', 'yyyymmdd')) As "12"
From DUAL
;

Select
    ksm_pkg_calendar.get_fiscal_year('20100831') As "2010"
  , ksm_pkg_calendar.get_fiscal_year(to_date('20110831', 'yyyymmdd')) As "2011"
  , ksm_pkg_calendar.get_fiscal_year('20200901') As "2021"
  , ksm_pkg_calendar.get_fiscal_year(to_date('20210901', 'yyyymmdd')) As "2022" 
From DUAL
;

Select
    ksm_pkg_calendar.get_performance_year(to_date('20100401', 'yyyymmdd')) As "2010"
  , ksm_pkg_calendar.get_performance_year(to_date('20100501', 'yyyymmdd')) As "2011"
  , ksm_pkg_calendar.get_performance_year(to_date('20200401', 'yyyymmdd')) As "2020"
  , ksm_pkg_calendar.get_performance_year(to_date('20200501', 'yyyymmdd')) As "2020" -- COVID 13-mo performance year
  , ksm_pkg_calendar.get_performance_year(to_date('20200601', 'yyyymmdd')) As "2021" -- COVID 13-mo performance year
From DUAL
;


---------------------------
-- ksm_pkg tests
---------------------------

-- Table functions
Select *
From table(ksm_pkg_tst.tbl_current_calendar)
;

-- Functions

Select
  ksm_pkg_tst.fytd_indicator(trunc(sysdate)) As N
  , ksm_pkg_tst.fytd_indicator(trunc(sysdate), day_offset => 0) As Y
From DUAL
;

Select
    ksm_pkg_tst.get_quarter(to_date('20000901', 'yyyymmdd')) As "1"
  , ksm_pkg_tst.get_quarter(to_date('20001201', 'yyyymmdd')) As "2"
  , ksm_pkg_tst.get_quarter(to_date('20000301', 'yyyymmdd')) As "3"
  , ksm_pkg_tst.get_quarter(to_date('20000601', 'yyyymmdd')) As "4"
  , ksm_pkg_tst.get_quarter(to_date('20000901', 'yyyymmdd'), 'p') As "2"
  , ksm_pkg_tst.get_quarter(to_date('20001201', 'yyyymmdd'), 'p') As "3"
  , ksm_pkg_tst.get_quarter(to_date('20000301', 'yyyymmdd'), 'p') As "4"
  , ksm_pkg_tst.get_quarter(to_date('20000601', 'yyyymmdd'), 'p') As "1"
From DUAL
;

Select
    ksm_pkg_tst.get_fiscal_year('20100831') As "2010"
  , ksm_pkg_tst.get_fiscal_year(to_date('20110831', 'yyyymmdd')) As "2011"
  , ksm_pkg_tst.get_fiscal_year('20200901') As "2021"
  , ksm_pkg_tst.get_fiscal_year(to_date('20210901', 'yyyymmdd')) As "2022" 
From DUAL
;

Select
    ksm_pkg_tst.get_performance_year(to_date('20100401', 'yyyymmdd')) As "2010"
  , ksm_pkg_tst.get_performance_year(to_date('20100501', 'yyyymmdd')) As "2011"
  , ksm_pkg_tst.get_performance_year(to_date('20200401', 'yyyymmdd')) As "2020"
  , ksm_pkg_tst.get_performance_year(to_date('20200501', 'yyyymmdd')) As "2020" -- COVID 13-mo performance year
  , ksm_pkg_tst.get_performance_year(to_date('20200601', 'yyyymmdd')) As "2021" -- COVID 13-mo performance year
From DUAL
;
