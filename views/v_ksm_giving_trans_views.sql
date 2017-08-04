Create Or Replace View v_ksm_giving_trans As
-- View implementing ksm_pkg Kellogg gift credit
Select *
From table(ksm_pkg.tbl_gift_credit_ksm);
/

Create Or Replace View v_ksm_giving_trans_hh As
-- View implementing ksm_pkg Kellogg gift credit, with household ID (slower than tbl_gift_credit_ksm)
Select *
From table(ksm_pkg.tbl_gift_credit_hh_ksm);
