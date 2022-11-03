Create Or Replace View GAB_report As

With
KSM_Allocations AS (
SELECT allocation_code
From allocation
WHERE ALLOC_SCHOOL = 'KM'),

AF_Allocations AS (
SELECT allocation_code
From table(rpt_pbh634.ksm_pkg_tmp.tbl_alloc_annual_fund_ksm)),

KSM_Campaign_Giving AS (
SELECT *
FROM rpt_pbh634.v_ksm_giving_campaign),

AF_Giving AS (
SELECT ID_number, sum(legal_amount) AS Legal_Total, sum(credit_amount) AS Credit_Total
FROM nu_gft_trp_gifttrans
INNER JOIN AF_allocations on AF_allocations.allocation_code = nu_gft_trp_gifttrans.allocation_code
WHERE tx_GYPM_IND != 'P' AND credit_amount > 0 AND fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar)
GROUP BY ID_number),

AF_Giving_FY_2 AS (
SELECT ID_number, sum(legal_amount) AS Legal_Total, sum(credit_amount) AS Credit_Total
FROM nu_gft_trp_gifttrans
INNER JOIN AF_allocations on AF_allocations.allocation_code = nu_gft_trp_gifttrans.allocation_code
WHERE tx_GYPM_IND != 'P' AND credit_amount > 0 AND fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar) - 2
GROUP BY ID_number),

AF_Giving_FY_1 AS (
SELECT ID_number, sum(legal_amount) AS Legal_Total, sum(credit_amount) AS Credit_Total
FROM nu_gft_trp_gifttrans
INNER JOIN AF_allocations on AF_allocations.allocation_code = nu_gft_trp_gifttrans.allocation_code
WHERE tx_GYPM_IND != 'P' AND credit_amount > 0 AND fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar) - 1
GROUP BY ID_number),

AF_Giving_CurrentFY AS (
SELECT ID_number, sum(legal_amount) AS Legal_Total, sum(credit_amount) AS Credit_Total
FROM nu_gft_trp_gifttrans
INNER JOIN AF_allocations on AF_allocations.allocation_code = nu_gft_trp_gifttrans.allocation_code
WHERE tx_GYPM_IND != 'P' AND credit_amount > 0 AND fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar)
GROUP BY ID_number),

KSM_LT_Giving AS (
SELECT *
FROM rpt_pbh634.v_ksm_giving_lifetime
),

KSM_Giving AS (
SELECT ID_number, sum(legal_amount) AS Legal_Total, sum(credit_amount) AS Credit_Total
FROM nu_gft_trp_gifttrans
INNER JOIN KSM_allocations on KSM_allocations.allocation_code = nu_gft_trp_gifttrans.allocation_code
WHERE tx_GYPM_IND != 'Y' AND credit_amount > 0 AND fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar)
GROUP BY ID_number),

KSM_Giving_FY_1 AS (
SELECT ID_number, sum(legal_amount) AS Legal_Total, sum(credit_amount) AS Credit_Total
FROM nu_gft_trp_gifttrans
INNER JOIN KSM_allocations on KSM_allocations.allocation_code = nu_gft_trp_gifttrans.allocation_code
WHERE tx_GYPM_IND != 'Y' AND credit_amount > 0 AND fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar) - 1
GROUP BY ID_number),

KSM_Giving_FY_2 AS (
SELECT ID_number, sum(legal_amount) AS Legal_Total, sum(credit_amount) AS Credit_Total
FROM nu_gft_trp_gifttrans
INNER JOIN KSM_allocations on KSM_allocations.allocation_code = nu_gft_trp_gifttrans.allocation_code
WHERE tx_GYPM_IND != 'Y' AND credit_amount > 0 AND fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar) - 2
GROUP BY ID_number),

GAB AS (
  SELECT *
  FROM table(rpt_pbh634.ksm_pkg_tmp.tbl_committee_gab)
),

KSMdegree AS (
  SELECT id_number, degrees_concat
  FROM table(rpt_pbh634.ksm_pkg_tmp.tbl_entity_degrees_concat_ksm)
),

NU_LT_Giving AS (
Select prs.id_number, prs.giving_total
From nu_prs_trp_prospect prs
Inner Join GAB On GAB.id_number = prs.id_number
),

CFY_NULT_Giving AS (
Select nugft.id_number, sum(nugft.credit_amount) AS CFY_NULT_Giving
From nu_gft_trp_gifttrans nugft
Inner Join GAB On GAB.id_number = nugft.id_number
WHERE TX_GYPM_IND != 'Y' AND fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar)
GROUP BY nugft.ID_Number
),

LFY_NULT_Giving AS (
Select nugft.id_number, sum(nugft.credit_amount) AS LFY_NULT_Giving
From nu_gft_trp_gifttrans nugft
Inner Join GAB On GAB.id_number = nugft.id_number
WHERE TX_GYPM_IND != 'Y' AND fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar) - 1
GROUP BY nugft.ID_Number
),

LFY2_NULT_Giving AS (
Select nugft.id_number, sum(nugft.credit_amount) AS LFY2_NULT_Giving
From nu_gft_trp_gifttrans nugft
Inner Join GAB On GAB.id_number = nugft.id_number
WHERE TX_GYPM_IND != 'Y' AND fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar) - 2
GROUP BY nugft.ID_Number
),

KSMPROP AS (
SELECT proposal_ID
FROM proposal_purpose
WHERE program_code = 'KM' ),

ActiveProposals AS (SELECT p.proposal_id, p.prospect_id, 
CASE WHEN p.original_ask_amt >= 100000 OR p.ask_amt >= 100000 OR p.anticipated_amt >= 100000
  THEN 'Y' ELSE 'N' END AS MajorGift
FROM proposal p
INNER JOIN KSMPROP ON KSMPROP.proposal_ID = p.proposal_ID
WHERE active_IND = 'Y'),

ProposalCount AS (SELECT prospect_ID, count(proposal_ID) AS ProposalCount
FROM ActiveProposals
WHERE MajorGift = 'Y'
GROUP BY prospect_ID)
  
SELECT prs.id_number, prs.pref_mail_name, KSMdegree.degrees_concat, prs.employer_name1, prs.business_title,
 prs.pref_city, prs.pref_state, prs.pref_zip, prs.preferred_country, prs.prospect_id,
  prs.prospect_manager, prs.evaluation_rating, prs.evaluation_date, 
  prs.officer_rating,gab.short_desc, gab.start_dt, gab.stop_dt, gab.status, gab.role,
  nvl(NU_LT_Giving.giving_total, 0) AS NU_LT_Giving, nvl(CFY_NULT_Giving.CFY_NULT_Giving, 0) AS CFY_NULT_Giving,
  nvl(LFY_NULT_Giving.LFY_NULT_Giving, 0) AS LFY_NULT_Giving, nvl(LFY2_NULT_Giving.LFY2_NULT_Giving, 0) AS LFY2_NULT_Giving,
  nvl(KSM_LT_Giving.credit_amount, 0) AS KSM_LT_Giving,
  nvl(KSM_Campaign_Giving.campaign_giving,0) AS KSM_Campaign_Giving, nvl(ProposalCount.ProposalCount, 0) AS Proposal_Count,
  nvl(AF_Giving_CurrentFY.Legal_Total, 0) as AF_CFY_Legal, nvl(AF_Giving_CurrentFY.Credit_Total, 0) AS AF_CFY_SftCredit, 
  nvl(AF_Giving_FY_1.Legal_Total, 0) AS AF_LYFY_Legal, nvl(AF_Giving_FY_1.Credit_Total, 0) AS AF_LYFY_SftCredit,
  nvl(AF_Giving_FY_2.Legal_Total, 0) AS AF_LYFY2_Legal, nvl(AF_Giving_FY_2.Credit_Total, 0) AS AF_LYFY2_SftCredit, 
  nvl(KSM_Giving.Legal_Total, 0) AS KSM_CFY_Legal, nvl(KSM_Giving.credit_Total, 0) AS KSM_CFY_SftCredit,
  nvl(KSM_Giving_FY_1.Legal_Total, 0) AS KSM_LYFY_Legal, nvl(KSM_Giving_FY_1.credit_Total, 0) AS KSM_LYFY_SftCredit,
  nvl(KSM_Giving_FY_2.Legal_Total, 0) AS KSM_LYFY2_Legal, nvl(KSM_Giving_FY_2.credit_Total, 0) AS KSM_LYFY2_SftCredit,
  KSM_Campaign_Giving.CAMPAIGN_CFY, 
  KSM_Campaign_Giving.Campaign_PFY1, KSM_Campaign_Giving.Campaign_PFY2, KSM_Campaign_Giving.Campaign_PFY3
  
  
FROM nu_prs_trp_prospect prs
Inner Join GAB ON GAB.id_number = prs.id_number
Left Join KSMdegree
ON KSMdegree.id_number = prs.id_number
Left Join ProposalCount
ON ProposalCount.prospect_ID = prs.prospect_ID
Left Join AF_Giving_CurrentFY
ON GAB.id_number = AF_Giving_CurrentFY.id_number
Left Join AF_Giving_FY_2
ON GAB.id_number = AF_Giving_FY_2.id_number
Left Join AF_Giving_FY_1
ON GAB.id_number = AF_Giving_FY_1.id_number
Left Join KSM_Giving
ON GAB.id_number = KSM_Giving.id_number
Left Join KSM_Giving_FY_1
ON GAB.id_number = KSM_Giving_FY_1.id_number
Left Join KSM_Giving_FY_2
ON GAB.id_number = KSM_Giving_FY_2.id_number
LEFT JOIN KSM_Campaign_Giving
ON GAB.ID_NUMBER = KSM_Campaign_Giving.ID_NUMBER
LEFT JOIN KSM_LT_Giving
ON GAB.ID_Number = KSM_LT_Giving.ID_Number
LEFT JOIN NU_LT_Giving
ON GAB.ID_Number = NU_LT_Giving.ID_Number
LEFT JOIN KSM_Campaign_Giving
ON GAB.ID_Number = KSM_Campaign_Giving.ID_Number
LEFT JOIN CFY_NULT_Giving
ON GAB.ID_Number = CFY_NULT_Giving.ID_Number
LEFT JOIN LFY_NULT_Giving
ON GAB.ID_Number = LFY_NULT_Giving.ID_Number
LEFT JOIN LFY2_NULT_Giving
ON GAB.ID_Number = LFY2_NULT_Giving.ID_Number



