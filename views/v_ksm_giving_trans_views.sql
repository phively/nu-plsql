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

Create or Replace View v_ksm_giving_campaign As
With
-- View implementing householded campaign giving based on new gifts & commitments
hhid As (
  Select id_number, household_id, household_rpt_name, household_spouse_id, household_spouse
  From table(ksm_pkg.tbl_entity_households_ksm)
),
cgft As (
  Select hhid.*,
  Case When gft.id_number = household_id Then gft.credited_amount Else 0 End As hh_credit,
  gft.year_of_giving fiscal_year
  From hhid
  Inner Join v_ksm_giving_campaign_trans gft On gft.id_number = hhid.id_number
)
Select Distinct hhid.id_number, entity.report_name, hhid.household_id, hhid.household_rpt_name, hhid.household_spouse_id, hhid.household_spouse,
  sum(cgft.hh_credit) As campaign_giving,
  sum(Case When cal.curr_fy = fiscal_year     Then hh_credit Else 0 End) As campaign_cfy,
  sum(Case When cal.curr_fy = fiscal_year + 1 Then hh_credit Else 0 End) As campaign_pfy1,
  sum(Case When cal.curr_fy = fiscal_year + 2 Then hh_credit Else 0 End) As campaign_pfy2,
  sum(Case When cal.curr_fy = fiscal_year + 3 Then hh_credit Else 0 End) As campaign_pfy3
From hhid
Cross Join v_current_calendar cal
Inner Join cgft On hhid.household_id = cgft.household_id
Inner Join entity On entity.id_number = hhid.id_number
Group By hhid.id_number, entity.report_name, hhid.household_id, hhid.household_rpt_name, hhid.household_spouse_id, hhid.household_spouse
/
