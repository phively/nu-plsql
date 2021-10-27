Create Or Replace View rpt_pbh634.v_advisory_committees_members As

-- GAB
Select *
From table(rpt_pbh634.ksm_pkg.tbl_committee_agg(
  my_committee_cd => ksm_pkg.get_string_constant('committee_gab')
  , shortname => 'GAB')
)
-- Asia
Union
Select *
From table(rpt_pbh634.ksm_pkg.tbl_committee_agg(
  my_committee_cd => ksm_pkg.get_string_constant('committee_asia')
  , shortname => 'KEBA')
)
-- KAC
Union
Select *
From table(rpt_pbh634.ksm_pkg.tbl_committee_agg(
  my_committee_cd => ksm_pkg.get_string_constant('committee_kac')
  , shortname => 'KAC')
)
-- PHS
Union
Select *
From table(rpt_pbh634.ksm_pkg.tbl_committee_agg(
  my_committee_cd => ksm_pkg.get_string_constant('committee_phs')
  , shortname => 'PHS')
)
-- KFN
Union
Select *
From table(rpt_pbh634.ksm_pkg.tbl_committee_agg(
  my_committee_cd => ksm_pkg.get_string_constant('committee_kfn')
  , shortname => 'KFN')
)
-- AMP
Union
Select *
From table(rpt_pbh634.ksm_pkg.tbl_committee_agg(
  my_committee_cd => ksm_pkg.get_string_constant('committee_AMP')
  , shortname => 'AMP')
)
-- Real Estate
Union
Select *
From table(rpt_pbh634.ksm_pkg.tbl_committee_agg(
  my_committee_cd => ksm_pkg.get_string_constant('committee_RealEstCouncil')
  , shortname => 'RealEstCouncil')
)
-- DivSummit
Union
Select *
From table(rpt_pbh634.ksm_pkg.tbl_committee_agg(
  my_committee_cd => ksm_pkg.get_string_constant('committee_DivSummit')
  , shortname => 'DivSummit')
)
-- WomenSummit
Union
Select *
From table(rpt_pbh634.ksm_pkg.tbl_committee_agg(
  my_committee_cd => ksm_pkg.get_string_constant('committee_WomenSummit')
  , shortname => 'WomenSummit')
)
-- CorpGov
Union
Select *
From table(rpt_pbh634.ksm_pkg.tbl_committee_agg(
  my_committee_cd => ksm_pkg.get_string_constant('committee_CorpGov')
  , shortname => 'CorpGov')
)
-- Healthcare
Union
Select *
From table(rpt_pbh634.ksm_pkg.tbl_committee_agg(
  my_committee_cd => ksm_pkg.get_string_constant('committee_healthcare')
  , shortname => 'Healthcare')
)
-- WomensLeadership
Union
Select *
From table(rpt_pbh634.ksm_pkg.tbl_committee_agg(
  my_committee_cd => ksm_pkg.get_string_constant('committee_WomensLeadership')
  , shortname => 'WomensLeadership')
)
-- Inclusion
Union
Select *
From table(rpt_pbh634.ksm_pkg.tbl_committee_agg(
  my_committee_cd => ksm_pkg.get_string_constant('committee_kic')
  , shortname => 'Inclusion')
)
-- PrivateEquity
Union
Select *
From table(rpt_pbh634.ksm_pkg.tbl_committee_agg(
  my_committee_cd => ksm_pkg.get_string_constant('committee_privateequity')
  , shortname => 'PrivateEquity')
)
;

/***********************************************
Committee giving views
***********************************************/

Create Or Replace View rpt_pbh634.vt_advisory_committees_report As

With

members As (
  Select *
  From rpt_pbh634.v_advisory_committees_members
)

, all_committees As (
  Select Distinct id_number
  From members
)

-- NU yearly NGC giving amounts
, fy_nu_giving As (
  Select
    nugft.id_number
    , sum(Case When fiscal_year = cal.curr_fy - 0 Then nugft.credit_amount Else 0 End)
      As cfy_nult_giving
    , sum(Case When fiscal_year = cal.curr_fy - 1 Then nugft.credit_amount Else 0 End)
      As lfy_nult_giving
    , sum(Case When fiscal_year = cal.curr_fy - 2 Then nugft.credit_amount Else 0 End)
      As lfy2_nult_giving
  From nu_gft_trp_gifttrans nugft
  Cross Join rpt_pbh634.v_current_calendar cal
  Inner Join all_committees
    On all_committees.id_number = nugft.id_number
  Where tx_gypm_ind != 'Y' -- No pledge payments
    And fiscal_year Between cal.curr_fy - 2 And cal.curr_fy
  Group By nugft.id_number
)

, all_committees_giving As (
  Select
    all_committees.id_number
    , nvl(fy_nu_giving.cfy_nult_giving, 0) As cfy_nult_giving
    , nvl(fy_nu_giving.lfy_nult_giving, 0) As lfy_nult_giving
    , nvl(fy_nu_giving.lfy2_nult_giving, 0) As lfy2_nult_giving
    , nvl(v_ksm_giving_summary.ngc_lifetime_full_rec, 0) As ksm_lt_giving
    , nvl(v_ksm_giving_campaign.campaign_giving,0) As ksm_campaign_giving
    , nvl(v_ksm_giving_summary.af_cfy, 0) As af_cfy_sftcredit
    , nvl(v_ksm_giving_summary.af_pfy1, 0) As af_lyfy_sftcredit
    , nvl(v_ksm_giving_summary.af_pfy2, 0) As af_lyfy2_sftcredit
    , nvl(v_ksm_giving_summary.ngc_cfy, 0) As ksm_cfy_sftcredit
    , nvl(v_ksm_giving_summary.ngc_pfy1, 0) As ksm_lyfy_sftcredit
    , nvl(v_ksm_giving_summary.ngc_pfy2, 0) As ksm_lyfy2_sftcredit
    , nvl(v_ksm_giving_campaign.campaign_cfy, 0) As campaign_cfy
    , nvl(v_ksm_giving_campaign.campaign_pfy1, 0) As campaign_pfy1
    , nvl(v_ksm_giving_campaign.campaign_pfy2, 0) As campaign_pfy2
    , nvl(v_ksm_giving_campaign.campaign_pfy3, 0) As campaign_pfy3
  From all_committees
  Left Join rpt_pbh634.v_ksm_giving_summary
    On v_ksm_giving_summary.id_number = all_committees.id_number
  Left Join fy_nu_giving
    On all_committees.id_number = fy_nu_giving.id_number
  Left Join rpt_pbh634.v_ksm_giving_campaign
    On all_committees.id_number = v_ksm_giving_campaign.id_number
)

-- KSM proposal data
, activeproposals As (
  Select
    phf.proposal_id
    , phf.prospect_id
    , Case
        When phf.total_original_ask_amt >= 100000
          Or phf.total_ask_amt >= 100000
          Or phf.total_anticipated_amt >= 100000
          Then 'Y'
        Else 'N'
        End
      As majorgift
  From v_proposal_history_fast phf
  Where phf.ksm_proposal_ind = 'Y'
    And phf.proposal_active_calc = 'Active'
)

, proposalcount As (
  Select
    prospect_id
    , count(proposal_id) As proposalcount
  From activeproposals
  Where majorgift = 'Y'
  Group By prospect_id
)

-- Main query
Select
  prs.id_number
  , prs.pref_mail_name
  , v_entity_ksm_degrees.degrees_concat
  , prs.employer_name1
  , prs.business_title
  , prs.pref_city
  , prs.pref_state
  , prs.pref_zip
  , prs.preferred_country
  , prs.prospect_id
  , prs.prospect_manager
  , prs.evaluation_rating
  , prs.evaluation_date
  , prs.officer_rating
  , Case When gab.committee_code = 'U' Then 'Y' Else 'N' End
    As gab_ind
  , gab.start_dt As gab_start_date
  , gab.stop_dt As gab_stop_date
  , gab.status As gab_status
  , gab.role As gab_role
  , gab.committee_title As gab_committee_title
  , Case When kfn.committee_code = 'KFN' Then 'Y' Else 'N' End
    As kfn_ind
  , kfn.start_dt As kfn_start_date
  , kfn.stop_dt As kfn_stop_date
  , kfn.status As kfn_status
  , kfn.role As kfn_role
  , kfn.committee_title As kfn_committee_title
  , Case When corpgov.committee_code = 'KCGN' Then 'Y' Else 'N' End
    As corpgov_ind
  , corpgov.start_dt As corpgov_start_date
  , corpgov.stop_dt As corpgov_stop_date
  , corpgov.status As corpgov_status
  , corpgov.role As corpgov_role
  , corpgov.committee_title As corpgov_committee_title
  , Case When divsummit.committee_code = 'KCDO' Then 'Y' Else 'N' End
    As divsummit_ind
  , divsummit.start_dt As ds_start_date
  , divsummit.stop_dt As ds_stop_date
  , divsummit.status As ds_status
  , divsummit.role As ds_role
  , divsummit.committee_title As divsummit_committee_title
  , Case When RealEstCouncil.committee_code = 'KREAC' Then 'Y' Else 'N' End
    As realest_ind
  , realestcouncil.start_dt As rec_start_date
  , realestcouncil.stop_dt As rec_stop_date
  , realestcouncil.status As rec_status
  , realestcouncil.role As rec_role
  , realestcouncil.committee_title As rec_committee_title
  , Case When amp.committee_code = 'KAMP' Then 'Y' Else 'N' End
    As amp_ind
  , amp.start_dt As amp_start_date
  , amp.stop_dt As amp_stop_date
  , amp.status As amp_status
  , amp.role As amp_role
  , amp.committee_title As amp_committee_title
  , Case When healthcare.committee_code = 'HAK' Then 'Y' Else 'N' End
    As healthcare_ind
  , healthcare.start_dt As healthcare_start_date
  , healthcare.stop_dt As healthcare_stop_date
  , healthcare.status As healthcare_status
  , healthcare.role As healthcare_role
  , healthcare.committee_title As healthcare_committee_title
  , Case When WomensLeadership.committee_code = 'KWLC' Then 'Y' Else 'N' End
    As womensleadership_ind
  , womensleadership.start_dt As womensleadership_start_date
  , womensleadership.stop_dt As womensleadership_stop_date
  , womensleadership.status As womensleadership_status
  , womensleadership.role As womensleadership_role
  , womensleadership.committee_title As womens_committee_title
  , Case When KAC.committee_code = 'KACNA' Then 'Y' Else 'N' End
    As kac_ind
  , kac.start_dt As kac_start_date
  , kac.stop_dt As kac_stop_date
  , kac.status As kac_status
  , kac.role As kac_role
  , kac.committee_title As kac_committee_title
  , Case When phs.committee_code = 'KPH' Then 'Y' Else 'N' End
    As phs_ind
  , phs.start_dt As phs_start_date
  , phs.stop_dt As phs_stop_date
  , phs.status As phs_status
  , phs.role As phs_role
  , phs.committee_title As phs_committee_title
  , Case When inclusion.committee_code = 'KIC' Then 'Y' Else 'N' End
    As inclusion_ind
  , inclusion.start_dt As inclusion_start_date
  , inclusion.stop_dt As inclusion_stop_date
  , inclusion.status As inclusion_status
  , inclusion.role As inclusion_role
  , inclusion.committee_title As inclusion_committee_title
  , Case When private_equity.committee_code = 'KPETC' Then 'Y' Else 'N' End
    As private_equity_ind
  , private_equity.start_dt As private_equity_start_date
  , private_equity.stop_dt As private_equity_stop_date
  , private_equity.status As private_equity_status
  , private_equity.role As private_equity_role
  , private_equity.committee_title As private_equity_committee_title
  , Case When keba.committee_code = 'KEBA' Then 'Y' Else 'N' End
    As keba_ind
  , keba.start_dt As keba_start_date
  , keba.stop_dt As keba_stop_date
  , keba.status As keba_status
  , keba.role As keba_role
  , keba.committee_title As keba_committee_title
  , nvl(prs.giving_total, 0) As nu_lt_giving
  , acg.cfy_nult_giving
  , acg.lfy_nult_giving
  , acg.lfy2_nult_giving
  , acg.ksm_lt_giving
  , acg.ksm_campaign_giving
  , nvl(proposalcount.proposalcount, 0) As proposal_count
  , acg.af_cfy_sftcredit
  , acg.af_lyfy_sftcredit
  , acg.af_lyfy2_sftcredit
  , acg.ksm_cfy_sftcredit
  , acg.ksm_lyfy_sftcredit
  , acg.ksm_lyfy2_sftcredit
  , acg.campaign_cfy
  , acg.campaign_pfy1
  , acg.campaign_pfy2
  , acg.campaign_pfy3
From all_committees_giving acg
Inner Join nu_prs_trp_prospect prs
  On prs.id_number = acg.id_number
Left Join rpt_pbh634.v_entity_ksm_degrees
  On v_entity_ksm_degrees.id_number = acg.id_number
Left Join proposalcount
  On proposalcount.prospect_id = prs.prospect_id
Left Join members amp
  On amp.id_number = acg.id_number
  And amp.committee_short_desc = 'AMP'
Left Join members realestcouncil
  On realestcouncil.id_number = acg.id_number
  And realestcouncil.committee_short_desc = 'RealEstCouncil'
Left Join members divsummit
  On divsummit.id_number = acg.id_number
  And divsummit.committee_short_desc = 'DivSummit'
Left Join members womensummit
  On womensummit.id_number = acg.id_number
  And womensummit.committee_short_desc = 'WomenSummit'
Left Join members corpgov
  On corpgov.id_number = acg.id_number
  And corpgov.committee_short_desc = 'CorpGov'
Left Join members kfn
  On kfn.id_number = acg.id_number
  And kfn.committee_short_desc = 'KFN'
Left Join members gab
  On gab.id_number = acg.id_number
  And gab.committee_short_desc = 'GAB'
Left Join members healthcare
  On healthcare.id_number = acg.id_number
  And healthcare.committee_short_desc = 'Healthcare'
Left Join members WomensLeadership
  On WomensLeadership.id_number = acg.id_number
  And WomensLeadership.committee_short_desc = 'WomensLeadership'
Left Join members KAC
  On KAC.id_number = acg.id_number
  And KAC.committee_short_desc = 'KAC'
Left Join members PHS
  On KAC.id_number = acg.id_number
  And KAC.committee_short_desc = 'PHS'
Left Join members inclusion
  On inclusion.id_number = acg.id_number
  And inclusion.committee_short_desc = 'Inclusion'
Left Join members private_equity
  On private_equity.id_number = acg.id_number
  And private_equity.committee_short_desc = 'PrivateEquity'
Left Join members keba
  On keba.id_number = acg.id_number
  And keba.committee_short_desc = 'KEBA'
;

/***********************************************
Committee data views
One committee per line
***********************************************/
Create Or Replace View rpt_pbh634.vt_advisory_committees_list As

With

members As (
  Select *
  From rpt_pbh634.v_advisory_committees_members
)

, all_committees As (
  Select *
  From members
)

-- NU yearly NGC giving amounts
, fy_nu_giving As (
  Select
    nugft.id_number
    , sum(Case When fiscal_year = cal.curr_fy - 0 Then nugft.credit_amount Else 0 End)
      As cfy_nult_giving
    , sum(Case When fiscal_year = cal.curr_fy - 1 Then nugft.credit_amount Else 0 End)
      As lfy_nult_giving
    , sum(Case When fiscal_year = cal.curr_fy - 2 Then nugft.credit_amount Else 0 End)
      As lfy2_nult_giving
  From nu_gft_trp_gifttrans nugft
  Cross Join rpt_pbh634.v_current_calendar cal
  Inner Join all_committees
    On all_committees.id_number = nugft.id_number
  Where tx_gypm_ind != 'Y' -- No pledge payments
    And fiscal_year Between cal.curr_fy - 2 And cal.curr_fy
  Group By nugft.id_number
)

, all_committees_giving As (
  Select
    all_committees.*
    , nvl(fy_nu_giving.cfy_nult_giving, 0) As cfy_nult_giving
    , nvl(fy_nu_giving.lfy_nult_giving, 0) As lfy_nult_giving
    , nvl(fy_nu_giving.lfy2_nult_giving, 0) As lfy2_nult_giving
    , nvl(KGS.ngc_lifetime_full_rec, 0) As ksm_lt_giving
    , nvl(v_ksm_giving_campaign.campaign_giving,0) As ksm_campaign_giving
    , nvl(KGS.af_cfy, 0) As af_cfy_sftcredit
    , nvl(KGS.af_pfy1, 0) As af_lyfy_sftcredit
    , nvl(KGS.af_pfy2, 0) As af_lyfy2_sftcredit
    , nvl(KGS.ngc_cfy, 0) As ksm_cfy_sftcredit
    , nvl(KGS.ngc_pfy1, 0) As ksm_lyfy_sftcredit
    , nvl(KGS.ngc_pfy2, 0) As ksm_lyfy2_sftcredit
    , nvl(v_ksm_giving_campaign.campaign_cfy, 0) As campaign_cfy
    , nvl(v_ksm_giving_campaign.campaign_pfy1, 0) As campaign_pfy1
    , nvl(v_ksm_giving_campaign.campaign_pfy2, 0) As campaign_pfy2
    , nvl(v_ksm_giving_campaign.campaign_pfy3, 0) As campaign_pfy3
    , nvl(KGS."CASH_PFY1",0)+nvl(KGS."CASH_PFY2",0)+nvl(KGS."CASH_PFY3",0)+nvl(KGS."CASH_PFY4",0)+nvl(KGS."CASH_PFY5",0) AS ksm_giving_5yrs
    , CASE WHEN KGS."AF_PFY1" >0 THEN 1 ELSE 0 END AS AF_PFY1
    , CASE WHEN KGS."AF_PFY2" >0 THEN 1 ELSE 0 END AS AF_PFY2
    , CASE WHEN KGS."AF_PFY3" >0 THEN 1 ELSE 0 END AS AF_PFY3
  From all_committees
  Left Join rpt_pbh634.v_ksm_giving_summary KGS
    On KGS.id_number = all_committees.id_number
  Left Join fy_nu_giving
    On all_committees.id_number = fy_nu_giving.id_number
  Left Join rpt_pbh634.v_ksm_giving_campaign
    On all_committees.id_number = v_ksm_giving_campaign.id_number
)

-- KSM proposal data
, activeproposals As (
  Select
    phf.proposal_id
    , phf.prospect_id
    , Case
        When phf.total_original_ask_amt >= 100000
          Or phf.total_ask_amt >= 100000
          Or phf.total_anticipated_amt >= 100000
          Then 'Y'
        Else 'N'
        End
      As majorgift
  From rpt_pbh634.v_proposal_history_fast phf
  Where phf.ksm_proposal_ind = 'Y'
    And phf.proposal_active_calc = 'Active'
)

, proposalcount As (
  Select
    prospect_id
    , count(proposal_id) As proposalcount
  From activeproposals
  Where majorgift = 'Y'
  Group By prospect_id
)

, gab_meetings AS (
  SELECT 
    id_number
    ,COUNT(EVENT_ID) AS gab_meeting_count_3yrs   
  FROM rpt_pbh634.v_nu_event_participants_fast E
  CROSS JOIN RPT_PBH634.V_CURRENT_CALENDAR CAL
  WHERE ((EVENT_NAME LIKE '%Global Advisory Board%' AND EVENT_TYPE = 'Meeting')
    OR (EVENT_NAME LIKE '%Global Advisory Board%')
    OR (EVENT_NAME LIKE '%GAB%')
    OR (EVENT_NAME LIKE '%GAB%' AND EVENT_TYPE = 'Meeting'))
    AND E.START_FY_CALC BETWEEN CAL."CURR_FY"-3 AND CAL."CURR_FY"-1
  GROUP BY ID_NUMBER
)
-- Main query
Select
  prs.id_number
  , prs.pref_mail_name
  , v_entity_ksm_degrees.degrees_concat
  , CASE WHEN T.ID_NUMBER IS NOT NULL THEN 'Y' ELSE 'N' END AS TRUSTEE
  , CASE WHEN E.ETHNIC_CODE IN ('1', '2', '4', '9', '12') THEN 'Y' ELSE 'N' END AS URM 
  , CASE WHEN E.citizen_cntry_code1 = ' ' AND E.citizen_cntry_code2 = ' ' THEN 'N' 
       WHEN E.citizen_cntry_code1 = 'US' AND E.citizen_cntry_code2 = 'US' THEN 'N'
       WHEN E.citizen_cntry_code1 <> 'US' THEN 'Y'
       WHEN E.citizen_cntry_code1 = ' ' AND E.citizen_cntry_code2 <> 'US' THEN 'Y'
       WHEN E.citizen_cntry_code1 = 'US' AND E.citizen_cntry_code2 = ' ' THEN 'N'   
       WHEN E.citizen_cntry_code1 = 'US' AND E.citizen_cntry_code2 <> 'US' THEN 'Y' END AS CITIZENSHIP_OUTSIDE_US
  , CASE WHEN E.GENDER_CODE = 'F' THEN 'Y' ELSE 'N' END AS FEMALE
  , prs.employer_name1
  , prs.business_title
  , prs.pref_city
  , prs.pref_state
  , prs.pref_zip
  , prs.preferred_country
  , prs.prospect_id
  , prs.prospect_manager
  , prs.evaluation_rating
  , prs.evaluation_date
  , prs.officer_rating
  , mg.pr_segment
  , mg.pr_score
  , acg.committee_code
  , ch.short_desc As committee_name
  , acg.committee_title
  , gm.gab_meeting_count_3yrs  
  , acg.start_dt
  , acg.stop_dt
  , acg.status
  , acg.role
  , nvl(prs.giving_total, 0) As nu_lt_giving
  , acg.cfy_nult_giving
  , acg.lfy_nult_giving
  , acg.lfy2_nult_giving
  , acg.ksm_lt_giving
  , acg.ksm_campaign_giving
  , nvl(proposalcount.proposalcount, 0) As proposal_count
  , acg.af_cfy_sftcredit
  , acg.af_lyfy_sftcredit
  , acg.af_lyfy2_sftcredit
  , acg.ksm_cfy_sftcredit
  , acg.ksm_lyfy_sftcredit
  , acg.ksm_lyfy2_sftcredit
  , acg.ksm_giving_5yrs
  , (acg.AF_PFY1+acg.AF_PFY2+acg.AF_PFY3)/3 AS AF_GIVING_PARTICIPATION_3yrs
  , acg.campaign_cfy
  , acg.campaign_pfy1
  , acg.campaign_pfy2
  , acg.campaign_pfy3
From all_committees_giving acg
Inner Join nu_prs_trp_prospect prs
  On prs.id_number = acg.id_number
Left Join committee_header ch
  On ch.committee_code = acg.committee_code
LEFT JOIN TABLE(RPT_PBH634.KSM_PKG.tbl_committee_trustee) T
ON T.ID_NUMBER = acg.id_number
LEFT JOIN ENTITY e
ON e.id_number = acg.id_number
LEFT JOIN gab_meetings gm
ON gm.id_number = acg.id_number
Left Join rpt_pbh634.v_entity_ksm_degrees
  On v_entity_ksm_degrees.id_number = acg.id_number
LEFT JOIN RPT_PBH634.V_KSM_MODEL_MG MG
ON mg.id_number = prs.id_number
Left Join proposalcount
  On proposalcount.prospect_id = prs.prospect_id
;
