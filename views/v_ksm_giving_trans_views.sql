Create Or Replace View v_ksm_giving_trans As
-- View implementing ksm_pkg Kellogg gift credit
Select *
From table(ksm_pkg.tbl_gift_credit_ksm);
/

Create Or Replace View v_ksm_giving_trans_hh As
-- View implementing ksm_pkg Kellogg gift credit, with household ID (slower than tbl_gift_credit_ksm)
Select *
From table(ksm_pkg.tbl_gift_credit_hh_ksm);
/

Create Or Replace View v_ksm_giving_summary As
-- View implementing Kellogg gift credit, householded, with several common types
Select Distinct hh.id_number, hh.household_id, hh.household_rpt_name, hh.household_spouse_id, hh.household_spouse,
  sum(Case When tx_gypm_ind != 'Y' Then hh_credit Else 0 End) As ngc_lifetime,
  sum(Case When tx_gypm_ind != 'Y' And cal.curr_fy = fiscal_year     Then hh_credit Else 0 End) As ngc_cfy,
  sum(Case When tx_gypm_ind != 'Y' And cal.curr_fy = fiscal_year + 1 Then hh_credit Else 0 End) As ngc_pfy1,
  sum(Case When tx_gypm_ind != 'Y' And cal.curr_fy = fiscal_year + 2 Then hh_credit Else 0 End) As ngc_pfy2,
  sum(Case When tx_gypm_ind != 'Y' And cal.curr_fy = fiscal_year + 3 Then hh_credit Else 0 End) As ngc_pfy3,
  sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year     Then hh_credit Else 0 End) As cash_cfy,
  sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 1 Then hh_credit Else 0 End) As cash_pfy1,
  sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 2 Then hh_credit Else 0 End) As cash_pfy2,
  sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 3 Then hh_credit Else 0 End) As cash_pfy3,
  sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year     And af_flag = 'Y' Then hh_credit Else 0 End) As af_cfy,
  sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 1 And af_flag = 'Y' Then hh_credit Else 0 End) As af_pfy1,
  sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 2 And af_flag = 'Y' Then hh_credit Else 0 End) As af_pfy2,
  sum(Case When tx_gypm_ind != 'P' And cal.curr_fy = fiscal_year + 3 And af_flag = 'Y' Then hh_credit Else 0 End) As af_pfy3,
  -- WARNING: includes new gifts and commitments as well as cash
  sum(Case When cal.curr_fy = fiscal_year     Then hh_credit Else 0 End) As stewardship_cfy,
  sum(Case When cal.curr_fy = fiscal_year + 1 Then hh_credit Else 0 End) As stewardship_pfy1,
  sum(Case When cal.curr_fy = fiscal_year + 2 Then hh_credit Else 0 End) As stewardship_pfy2,
  sum(Case When cal.curr_fy = fiscal_year + 3 Then hh_credit Else 0 End) As stewardship_pfy3
From table(ksm_pkg.tbl_entity_households_ksm) hh
Cross Join v_current_calendar cal
Inner Join v_ksm_giving_trans_hh gfts On gfts.household_id = hh.household_id
Group By hh.id_number, hh.household_id, hh.household_rpt_name, hh.household_spouse_id, hh.household_spouse;
/

/* Campaign giving */

Create Or Replace View v_ksm_giving_campaign_trans As
-- Campaign transactions
Select *
From table(ksm_pkg.tbl_gift_credit_campaign)
/

Create Or Replace View v_ksm_giving_campaign_trans_hh As
-- Householded campaign transactions
Select *
From table(ksm_pkg.tbl_gift_credit_hh_campaign)
/

Create or Replace View v_ksm_giving_campaign As
With
hh As (
  Select *
  From table(ksm_pkg.tbl_entity_households_ksm)
)
-- View implementing householded campaign giving based on new gifts & commitments
Select Distinct cgft.id_number, entity.report_name, hh.degrees_concat, cgft.household_id, hh.household_rpt_name, hh.household_spouse_id, hh.household_spouse,
  sum(cgft.hh_credit) As campaign_giving,
  sum(Case When cal.curr_fy = year_of_giving     Then hh_credit Else 0 End) As campaign_cfy,
  sum(Case When cal.curr_fy = year_of_giving + 1 Then hh_credit Else 0 End) As campaign_pfy1,
  sum(Case When cal.curr_fy = year_of_giving + 2 Then hh_credit Else 0 End) As campaign_pfy2,
  sum(Case When cal.curr_fy = year_of_giving + 3 Then hh_credit Else 0 End) As campaign_pfy3
From hh
Cross Join v_current_calendar cal
Inner Join v_ksm_giving_campaign_trans_hh cgft On cgft.household_id = hh.household_id
Inner Join entity On entity.id_number = hh.id_number
Group By cgft.id_number, entity.report_name, hh.degrees_concat, cgft.household_id, hh.household_rpt_name, hh.household_spouse_id, hh.household_spouse
/
