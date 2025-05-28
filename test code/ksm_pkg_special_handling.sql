---------------------------
-- ksm_pkg_special_handling tests
---------------------------

-- Totals
Select count(*)
From table(ksm_pkg_special_handling.tbl_special_handling)
;

---------------------------
-- mv tests
---------------------------

-- No Contact
Select *
From mv_special_handling sh
Where sh.no_contact Is Not Null
;

-- No Solicit
Select *
From mv_special_handling sh
Where sh.no_solicit Is Not Null
  And sh.no_contact Is Null
;

-- No Release
Select *
From mv_special_handling sh
Where sh.no_release Is Not Null
  And sh.no_contact Is Null
;

-- AWR
Select *
From mv_special_handling sh
Where sh.active_with_restrictions Is Not Null
  And sh.no_contact Is Null
;

-- NEF
Select *
From mv_special_handling sh
Where sh.never_engaged_forever Is Not Null
  And sh.never_engaged_reunion Is Null
;

-- NER
Select *
From mv_special_handling sh
Where sh.never_engaged_reunion Is Not Null
  And sh.never_engaged_forever Is Null
;

-- Anon
Select *
From mv_special_handling sh
Where sh.anonymous_donor Is Not Null
;

-- No Phone
Select *
From mv_special_handling sh
Where sh.no_phone_ind Is Not Null
  And sh.no_solicit Is Null
;
Select *
From mv_special_handling sh
Where sh.no_phone_sol_ind Is Not Null
  And sh.no_phone_ind Is Null
  And sh.no_solicit Is Null
;

-- No Email
Select *
From mv_special_handling sh
Where sh.no_email_ind Is Not Null
  And sh.no_solicit Is Null
;
Select *
From mv_special_handling sh
Where sh.no_email_sol_ind Is Not Null
  And sh.no_email_ind Is Null
  And sh.no_solicit Is Null
;

-- No Mail
Select *
From mv_special_handling sh
Where sh.no_mail_ind Is Not Null
  And sh.no_solicit Is Null
;
Select *
From mv_special_handling sh
Where sh.no_mail_sol_ind Is Not Null
  And sh.no_mail_ind Is Null
  And sh.no_solicit Is Null
;

-- No Texts
Select *
From mv_special_handling sh
Where sh.no_texts_ind Is Not Null
  And sh.no_solicit Is Null
;
Select *
From mv_special_handling sh
Where sh.no_texts_sol_ind Is Not Null
  And sh.no_texts_ind Is Null
  And sh.no_solicit Is Null
;

-- Trustees
Select *
From mv_special_handling sh
Where sh.trustee Is Not Null
;

-- GAB
Select *
From mv_special_handling sh
Where sh.gab Is Not Null
;

-- EBFA
Select *
From mv_special_handling sh
Where sh.ebfa Is Not Null
;
