---------------------------
-- ksm_pkg_special_handling tests
---------------------------

-- Totals
Select count(*)
From table(ksm_pkg_special_handling.tbl_special_handling_concat)
;

-- No Contact
With
nc As (
  Select *
  From table(ksm_pkg_special_handling.tbl_special_handling_concat) shc
  Where shc.spec_hnd_codes Like '%NC%'
)
Select *
From nc
Where rownum <= 10
;

-- No Solicit
With
ns As (
  Select *
  From table(ksm_pkg_special_handling.tbl_special_handling_concat) shc
  Where shc.spec_hnd_codes Not Like '%NC%'
    And shc.spec_hnd_codes Like '%DNS%'
)
Select *
From ns
Where rownum <= 10
;

-- Trustee check
With
trustee As (
  Select *
  From table(ksm_pkg_special_handling.tbl_special_handling_concat) shc
  Where shc.trustee Is Not Null
)
Select *
From trustee
Where rownum <= 10
;

---------------------------
-- ksm_pkg tests
---------------------------

-- Totals
Select count(*)
From table(ksm_pkg_tst.tbl_special_handling_concat)
;

-- No Contact
With
nc As (
  Select *
  From table(ksm_pkg_tst.tbl_special_handling_concat) shc
  Where shc.spec_hnd_codes Like '%NC%'
)
Select *
From nc
Where rownum <= 10
;

-- No Solicit
With
ns As (
  Select *
  From table(ksm_pkg_tst.tbl_special_handling_concat) shc
  Where shc.spec_hnd_codes Not Like '%NC%'
    And shc.spec_hnd_codes Like '%DNS%'
)
Select *
From ns
Where rownum <= 10
;

-- Trustee check
With
trustee As (
  Select *
  From table(ksm_pkg_tst.tbl_special_handling_concat) shc
  Where shc.trustee Is Not Null
)
Select *
From trustee
Where rownum <= 10
;