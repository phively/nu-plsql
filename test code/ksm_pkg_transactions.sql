---------------------------
-- ksm_pkg_transactions tests
---------------------------

Select *
From table(ksm_pkg_transactions.tbl_transactions)
;

---------------------------
-- mv_transactions tests
---------------------------

Select count(*)
From mv_transactions
;

Select
  NULL As "Check bequest amounts"
  , mvt.*
From mv_transactions mvt
Where tx_id In ('T2934818', 'T2934800', 'T2584353', 'T2584354', 'T2584825', 'T2584826', 'T2584827', 'T2584830', 'T2584828', 'T2584829')
  And hard_credit_amount > 0
Order By credited_donor_name Asc
;
