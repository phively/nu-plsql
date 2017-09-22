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
  sum(Case When tx_gypm_ind != 'Y' Then hh_recognition_credit Else 0 End) As ngc_lifetime_beq_fv, -- Count bequests at face value
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

Create Or Replace View v_ksm_giving_lifetime As
-- Replacement lifetime giving view, based on giving summary to household lifetime giving amounts. Kept for historical purposes.
Select ksm.id_number, entity.report_name,
  ksm.ngc_lifetime As credit_amount,
  ksm.ngc_lifetime_beq_fv As credit_amount_full_BE
From v_ksm_giving_summary ksm
Inner Join entity On entity.id_number = ksm.id_number;
/

/*****************
 Campaign giving
*****************/

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
Select Distinct hh.id_number, entity.report_name, hh.degrees_concat, cgft.household_id, hh.household_rpt_name, hh.household_spouse_id, hh.household_spouse,
  sum(cgft.hh_credit) As campaign_giving,
  sum(Case When cgft.anonymous In (Select Distinct anonymous_code From tms_anonymous) Then hh_credit Else 0 End) As campaign_anonymous,
  sum(Case When cgft.anonymous Not In (Select Distinct anonymous_code From tms_anonymous) Then hh_credit Else 0 End) As campaign_nonanonymous,
  sum(cgft.legal_amount) As campaign_legal_giving,
  sum(Case When cal.curr_fy = fiscal_year     Then hh_credit Else 0 End) As campaign_cfy,
  sum(Case When cal.curr_fy = fiscal_year + 1 Then hh_credit Else 0 End) As campaign_pfy1,
  sum(Case When cal.curr_fy = fiscal_year + 2 Then hh_credit Else 0 End) As campaign_pfy2,
  sum(Case When cal.curr_fy = fiscal_year + 3 Then hh_credit Else 0 End) As campaign_pfy3,
  sum(Case When fiscal_year < 2008 Then hh_credit Else 0 End) As campaign_reachbacks,
  sum(Case When fiscal_year = 2008 Then hh_credit Else 0 End) As campaign_fy08,
  sum(Case When fiscal_year = 2009 Then hh_credit Else 0 End) As campaign_fy09,
  sum(Case When fiscal_year = 2010 Then hh_credit Else 0 End) As campaign_fy10,
  sum(Case When fiscal_year = 2011 Then hh_credit Else 0 End) As campaign_fy11,
  sum(Case When fiscal_year = 2012 Then hh_credit Else 0 End) As campaign_fy12,
  sum(Case When fiscal_year = 2013 Then hh_credit Else 0 End) As campaign_fy13,
  sum(Case When fiscal_year = 2014 Then hh_credit Else 0 End) As campaign_fy14,
  sum(Case When fiscal_year = 2015 Then hh_credit Else 0 End) As campaign_fy15,
  sum(Case When fiscal_year = 2016 Then hh_credit Else 0 End) As campaign_fy16,
  sum(Case When fiscal_year = 2017 Then hh_credit Else 0 End) As campaign_fy17,
  sum(Case When fiscal_year = 2018 Then hh_credit Else 0 End) As campaign_fy18,
  sum(Case When fiscal_year = 2019 Then hh_credit Else 0 End) As campaign_fy19,
  sum(Case When fiscal_year = 2020 Then hh_credit Else 0 End) As campaign_fy20,
  -- Recognition amounts for stewardship purposes; includes face value of bequests and life expectancy intentions
  sum(cgft.hh_recognition_credit - cgft.hh_credit) As campaign_discounted_bequests,
  sum(cgft.hh_recognition_credit) As campaign_steward_giving,
  sum(Case When fiscal_year <= 2017 Then hh_recognition_credit Else 0 End) As campaign_steward_thru_fy17,
  sum(Case When fiscal_year <= 2017 And cgft.anonymous In (Select Distinct anonymous_code From tms_anonymous) Then hh_recognition_credit Else 0 End) As anon_steward_thru_fy17,
  sum(Case When fiscal_year <= 2017 And cgft.anonymous Not In (Select Distinct anonymous_code From tms_anonymous) Then hh_recognition_credit Else 0 End) As nonanon_steward_thru_fy17 
From hh
Cross Join v_current_calendar cal
Inner Join v_ksm_giving_campaign_trans_hh cgft On cgft.household_id = hh.household_id
Inner Join entity On entity.id_number = hh.id_number
Group By hh.id_number, entity.report_name, hh.degrees_concat, cgft.household_id, hh.household_rpt_name, hh.household_spouse_id, hh.household_spouse
/
