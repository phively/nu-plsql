Create Or Replace View v_af_klc_donors As

Select *
From table(ksm_pkg.tbl_klc_history)
;
