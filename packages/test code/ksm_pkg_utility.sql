---------------------------
-- ksm_pkg_utility tests
---------------------------



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
    , ksm_pkg_tst.math_mod(0, 0) As "NULL"
From DUAL

-- to_date2

-- to_number2

-- get_number_from_dollar