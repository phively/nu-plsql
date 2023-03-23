---------------------------
-- ksm_pkg_utility tests
---------------------------

-- math_mod
Select
      ksm_pkg_utility.math_mod(5, 2) As "1"
    , ksm_pkg_utility.math_mod(5, 3) As "2"
    , ksm_pkg_utility.math_mod(-2, 5) As "3"
    , ksm_pkg_utility.math_mod(5, 5) As "0"
    , ksm_pkg_utility.math_mod(0, 5) As "0"
    , ksm_pkg_utility.math_mod(0, 0) As "NULL: divide by 0"
From DUAL
;

-- to_date2
Select
      ksm_pkg_utility.to_date2('20201001', 'yyyymmdd') As "Oct 1 2020"
    , ksm_pkg_utility.to_date2('20201001', 'yyyyddmm') As "Jan 10 2020"
    , ksm_pkg_utility.to_date2('29022020', 'ddmmyyyy') As "Feb 29 2020"
    , ksm_pkg_utility.to_date2('29022021', 'ddmmyyyy') As "NULL: bad leap year"
    , ksm_pkg_utility.to_date2('20200100') As "NULL: no day"
    , ksm_pkg_utility.to_date2('20200001') As "NULL: no month"
    , ksm_pkg_utility.to_date2('00000101') As "NULL: no year"    
From DUAL
;

-- to_number2
Select
      ksm_pkg_utility.to_number2('0400') As "400"
    , ksm_pkg_utility.to_number2('0.400') As "0.4"
    , ksm_pkg_utility.to_number2('-0.400') As "-0.4"
    , ksm_pkg_utility.to_number2('4E3') As "4000"
    , ksm_pkg_utility.to_number2('4B3') As "NULL: letters"
    , ksm_pkg_utility.to_number2('3/3') As "NULL: symbols"
From DUAL
;

-- get_number_from_dollar
Select
      ksm_pkg_utility.get_number_from_dollar('$0') As "$0"
    , ksm_pkg_utility.get_number_from_dollar('$1.111') As "$1.111"
    , ksm_pkg_utility.get_number_from_dollar('$1E2') As "$1E2 -> 1"
    , ksm_pkg_utility.get_number_from_dollar('$10') As "$10"
    , ksm_pkg_utility.get_number_from_dollar('$1k') As "$1k (lowercase)"
    , ksm_pkg_utility.get_number_from_dollar('$1M') As "$1M"
    , ksm_pkg_utility.get_number_from_dollar('$11,000K') As "$11,000K -> $11M"
    , ksm_pkg_utility.get_number_from_dollar('$1B') As "$1B"
    , ksm_pkg_utility.get_number_from_dollar('10') As "NULL: no dollar sign"
    , ksm_pkg_utility.get_number_from_dollar('$$10') As "NULL: too many dollar signs"
From DUAL
;

---------------------------
-- ksm_pkg tests
---------------------------

-- math_mod
Select
      ksm_pkg_tst.math_mod(5, 2) As "1"
    , ksm_pkg_tst.math_mod(5, 3) As "2"
    , ksm_pkg_tst.math_mod(-2, 5) As "3"
    , ksm_pkg_tst.math_mod(5, 5) As "0"
    , ksm_pkg_tst.math_mod(0, 5) As "0"
    , ksm_pkg_tst.math_mod(0, 0) As "NULL: divide by 0"
From DUAL
;

-- to_date2
Select
      ksm_pkg_tst.to_date2('20201001', 'yyyymmdd') As "Oct 1 2020"
    , ksm_pkg_tst.to_date2('20201001', 'yyyyddmm') As "Jan 10 2020"
    , ksm_pkg_tst.to_date2('29022020', 'ddmmyyyy') As "Feb 29 2020"
    , ksm_pkg_tst.to_date2('29022021', 'ddmmyyyy') As "NULL: bad leap year"
    , ksm_pkg_tst.to_date2('20200100') As "NULL: no day"
    , ksm_pkg_tst.to_date2('20200001') As "NULL: no month"
    , ksm_pkg_tst.to_date2('00000101') As "NULL: no year"    
From DUAL
;

-- to_number2
Select
      ksm_pkg_tst.to_number2('0400') As "400"
    , ksm_pkg_tst.to_number2('0.400') As "0.4"
    , ksm_pkg_tst.to_number2('-0.400') As "-0.4"
    , ksm_pkg_tst.to_number2('4E3') As "4000"
    , ksm_pkg_tst.to_number2('4B3') As "NULL: letters"
    , ksm_pkg_tst.to_number2('3/3') As "NULL: symbols"
From DUAL
;

-- get_number_from_dollar
Select
      ksm_pkg_tst.get_number_from_dollar('$0') As "$0"
    , ksm_pkg_tst.get_number_from_dollar('$1.111') As "$1.111"
    , ksm_pkg_tst.get_number_from_dollar('$1E2') As "$1E2 -> 1"
    , ksm_pkg_tst.get_number_from_dollar('$10') As "$10"
    , ksm_pkg_tst.get_number_from_dollar('$1k') As "$1k (lowercase)"
    , ksm_pkg_tst.get_number_from_dollar('$1M') As "$1M"
    , ksm_pkg_tst.get_number_from_dollar('$11,000K') As "$11,000K -> $11M"
    , ksm_pkg_tst.get_number_from_dollar('$1B') As "$1B"
    , ksm_pkg_tst.get_number_from_dollar('10') As "NULL: no dollar sign"
    , ksm_pkg_tst.get_number_from_dollar('$$10') As "NULL: too many dollar signs"
From DUAL
;
