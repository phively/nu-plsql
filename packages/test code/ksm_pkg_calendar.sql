---------------------------
-- ksm_pkg_calendar tests
---------------------------

-- Constants
Select
    ksm_pkg_calendar.get_numeric_constant('fy_start_month') As fy_start_month -- 9
  , ksm_pkg_calendar.get_numeric_constant('py_start_month') As py_start_month -- 5
  , ksm_pkg_calendar.get_numeric_constant('py_start_month_py21') As py_start_month_py21 -- 6
From DUAL
;

-- Table functions
Select *
From table(ksm_pkg_calendar.tbl_current_calendar)
;

-- Functions
Select
    ksm_pkg_calendar.date_parse('20220801') As aug_01_2022
  , ksm_pkg_calendar.date_parse('zzzz0909', to_date('20200108', 'yyyymmdd')) As sep_09_2020
  , ksm_pkg_calendar.date_parse('2022zzzz', to_date('20200108', 'yyyymmdd')) As jan_08_2022
From DUAL
;

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
    ksm_pkg_tst.date_parse('20220801') As aug_01_2022
  , ksm_pkg_tst.date_parse('zzzz0909', to_date('20200108', 'yyyymmdd')) As sep_09_2020
  , ksm_pkg_tst.date_parse('2022zzzz', to_date('20200108', 'yyyymmdd')) As jan_08_2022
From DUAL
;

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
