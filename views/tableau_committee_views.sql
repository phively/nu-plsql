Create Or Replace View vt_advisory_committees_report As

With

KSM_Allocations AS (
        SELECT allocation_code
        From allocation
        WHERE ALLOC_SCHOOL = 'KM'
),

AF_Allocations AS (
        SELECT allocation_code
        From table(rpt_pbh634.ksm_pkg.tbl_alloc_annual_fund_ksm)
),

KSM_Campaign_Giving AS (
        SELECT *
        FROM rpt_pbh634.v_ksm_giving_campaign
),

AF_Giving AS (
        SELECT ID_number, sum(legal_amount) AS Legal_Total, sum(credit_amount) AS Credit_Total
        FROM nu_gft_trp_gifttrans
        INNER JOIN AF_allocations on AF_allocations.allocation_code = nu_gft_trp_gifttrans.allocation_code
        WHERE tx_GYPM_IND != 'P' AND credit_amount > 0 AND fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar)
        GROUP BY ID_number
),

AF_Giving_FY_2 AS (
        SELECT ID_number, sum(legal_amount) AS Legal_Total, sum(credit_amount) AS Credit_Total
        FROM nu_gft_trp_gifttrans
        INNER JOIN AF_allocations on AF_allocations.allocation_code = nu_gft_trp_gifttrans.allocation_code
        WHERE tx_GYPM_IND != 'P' AND credit_amount > 0 AND fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar) - 2
        GROUP BY ID_number
),

AF_Giving_FY_1 AS (
        SELECT ID_number, sum(legal_amount) AS Legal_Total, sum(credit_amount) AS Credit_Total
        FROM nu_gft_trp_gifttrans
        INNER JOIN AF_allocations on AF_allocations.allocation_code = nu_gft_trp_gifttrans.allocation_code
        WHERE tx_GYPM_IND != 'P' AND credit_amount > 0 AND fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar) - 1
        GROUP BY ID_number
),

AF_Giving_CurrentFY AS (
        SELECT ID_number, sum(legal_amount) AS Legal_Total, sum(credit_amount) AS Credit_Total
        FROM nu_gft_trp_gifttrans
        INNER JOIN AF_allocations on AF_allocations.allocation_code = nu_gft_trp_gifttrans.allocation_code
        WHERE tx_GYPM_IND != 'P' AND credit_amount > 0 AND fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar)
        GROUP BY ID_number
),

KSM_LT_Giving AS (
        SELECT *
        FROM rpt_pbh634.v_ksm_giving_lifetime
),

KSM_Giving AS (
        SELECT ID_number, sum(legal_amount) AS Legal_Total, sum(credit_amount) AS Credit_Total
        FROM nu_gft_trp_gifttrans nugft
        INNER JOIN KSM_allocations on KSM_allocations.allocation_code = nugft.allocation_code
        WHERE tx_GYPM_IND != 'Y'
        AND credit_amount > 0 
        AND nugft.fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar)
        GROUP BY ID_number
),

KSM_Giving_FY_1 AS (
        SELECT ID_number, sum(legal_amount) AS Legal_Total, sum(credit_amount) AS Credit_Total
        FROM nu_gft_trp_gifttrans
        INNER JOIN KSM_allocations on KSM_allocations.allocation_code = nu_gft_trp_gifttrans.allocation_code
        WHERE tx_GYPM_IND != 'Y' AND credit_amount > 0 AND fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar) - 1
        GROUP BY ID_number
),

KSM_Giving_FY_2 AS (
        SELECT ID_number, sum(legal_amount) AS Legal_Total, sum(credit_amount) AS Credit_Total
        FROM nu_gft_trp_gifttrans
        INNER JOIN KSM_allocations on KSM_allocations.allocation_code = nu_gft_trp_gifttrans.allocation_code
        WHERE tx_GYPM_IND != 'Y' AND credit_amount > 0 AND fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar) - 2
        GROUP BY ID_number
),

AMP AS (
        SELECT
              id_number
              , short_desc
              , listagg(start_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
                AS start_dt
              , listagg(stop_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
                AS stop_dt
              , status
              , listagg(role, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
                AS role
        FROM table(rpt_pbh634.ksm_pkg.tbl_committee_AMP)
        Group By id_number, short_desc, status
),
    
          
RealEstCouncil AS(
        SELECT
              id_number
              , short_desc
              , listagg(start_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
                AS start_dt
              , listagg(stop_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
                AS stop_dt
              , status
              , listagg(role, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
                AS role
        FROM table(rpt_pbh634.ksm_pkg.tbl_committee_RealEstCouncil)
        Group By id_number, short_desc, status
),
    
DivSummit AS(
        SELECT
              id_number
              , short_desc
              , listagg(start_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
                AS start_dt
              , listagg(stop_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
                AS stop_dt
              , status
              , listagg(role, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
                AS role
        FROM table(rpt_pbh634.ksm_pkg.tbl_committee_DivSummit)
        Group By id_number, short_desc, status
),
          
WomenSummit AS(
        SELECT
              id_number
              , short_desc
              , listagg(start_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
                AS start_dt
              , listagg(stop_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
                AS stop_dt
              , status
              , listagg(role, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
                AS role
        FROM table(rpt_pbh634.ksm_pkg.tbl_committee_WomenSummit)
        Group By id_number, short_desc, status
),
                
CorpGov AS(
        SELECT
              id_number
              , short_desc
              , listagg(start_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
                AS start_dt
              , listagg(stop_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
                AS stop_dt
              , status
              , listagg(role, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
                AS role
        FROM table(rpt_pbh634.ksm_pkg.tbl_committee_CorpGov)
        Group By id_number, short_desc, status
),
                
KFN AS(  
        SELECT
              id_number
              , short_desc
              , listagg(start_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
                AS start_dt
              , listagg(stop_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
                AS stop_dt
              , status
              , listagg(role, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
                AS role
        FROM table(rpt_pbh634.ksm_pkg.tbl_committee_KFN)
        Group By id_number, short_desc, status
),
                
GAB AS(         
        SELECT
              id_number
              , short_desc
              , listagg(start_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
                AS start_dt
              , listagg(stop_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
                AS stop_dt
              , status
              , listagg(role, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
                AS role
        FROM table(rpt_pbh634.ksm_pkg.tbl_committee_gab)
        Group By id_number, short_desc, status
),

All_Committees As (
                    SELECT id_number FROM AMP
                    Union
                    SELECT id_number FROM RealEstCouncil
                    Union
                    SELECT id_number FROM DivSummit
                    Union
                    SELECT id_number FROM WomenSummit
                    Union
                    SELECT id_number FROM CorpGov
                    Union
                    SELECT id_number FROM KFN
                    Union
                    SELECT id_number FROM GAB
),

All_Committee_Data As (
                    SELECT * FROM AMP
                    Union
                    SELECT * FROM RealEstCouncil
                    Union
                    SELECT * FROM DivSummit
                    Union
                    SELECT * FROM WomenSummit
                    Union
                    SELECT * FROM CorpGov
                    Union
                    SELECT * FROM KFN
                    Union
                    SELECT * FROM GAB
),

KSMdegree AS (
                    SELECT id_number, degrees_concat
                    FROM table(rpt_pbh634.ksm_pkg.tbl_entity_degrees_concat_ksm)
),

NU_LT_Giving AS (
                    Select prs.id_number, prs.giving_total
                    From nu_prs_trp_prospect prs
                    Inner Join All_Committees On All_Committees.id_number = prs.id_number
),

CFY_NULT_Giving AS (
                    Select nugft.id_number, sum(nugft.credit_amount) AS CFY_NULT_Giving
                    From nu_gft_trp_gifttrans nugft
                    Inner Join All_Committees On All_Committees.id_number = nugft.id_number
                    WHERE TX_GYPM_IND != 'Y' AND fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar)
                    GROUP BY nugft.ID_Number
),

LFY_NULT_Giving AS (
                    Select nugft.id_number, sum(nugft.credit_amount) AS LFY_NULT_Giving
                    From nu_gft_trp_gifttrans nugft
                    Inner Join All_Committees On All_Committees.id_number = nugft.id_number
                    WHERE TX_GYPM_IND != 'Y' AND fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar) - 1
                    GROUP BY nugft.ID_Number
),

LFY2_NULT_Giving AS (
                    Select nugft.id_number, sum(nugft.credit_amount) AS LFY2_NULT_Giving
                    From nu_gft_trp_gifttrans nugft
                    Inner Join All_Committees On All_Committees.id_number = nugft.id_number
                    WHERE TX_GYPM_IND != 'Y' AND fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar) - 2
                    GROUP BY nugft.ID_Number
),

KSMPROP AS (
                    SELECT proposal_ID
                    FROM proposal_purpose
                    WHERE program_code = 'KM' 
),

ActiveProposals AS (SELECT p.proposal_id, p.prospect_id, 
                    CASE WHEN p.original_ask_amt >= 100000 OR p.ask_amt >= 100000 OR p.anticipated_amt >= 100000
                      THEN 'Y' ELSE 'N' END AS MajorGift
                    FROM proposal p
                    INNER JOIN KSMPROP ON KSMPROP.proposal_ID = p.proposal_ID
                    WHERE active_IND = 'Y'
),

ProposalCount AS (SELECT prospect_ID, count(proposal_ID) AS ProposalCount
                  FROM ActiveProposals
                  WHERE MajorGift = 'Y'
                  GROUP BY prospect_ID)
  
SELECT distinct prs.id_number
      , prs.pref_mail_name
      , KSMdegree.degrees_concat
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
--      , All_Committee_Data.short_desc
--      , All_Committee_Data.start_dt
--      , All_Committee_Data.stop_dt
--      , All_Committee_Data.status
--      , All_Committee_Data.role
      , case when GAB.short_desc = 'KSM Global Advisory Board' then 'Y' else 'N' 
            End GAB_Ind
      , GAB.Start_dt AS "GAB_START_DATE"
      , GAB.Stop_dt AS "GAB_STOP_DATE"
      , GAB.status AS "GAB_STATUS"
      , GAB.Role AS "GAB_ROLE"
      , case when KFN.short_desc = 'Kellogg Finance Network' then 'Y' else 'N' 
            End KFN_Ind
      , KFN.Start_dt AS "KFN_START_DATE"
      , KFN.Stop_dt AS "KFN_STOP_DATE"
      , KFN.status AS "KFN_STATUS"
      , KFN.Role AS "KFN_ROLE"
      , case when CorpGov.short_desc = 'KSM Corporate Governance Committee' then 'Y' else 'N' 
            End CorpGov_Ind
      , CorpGov.Start_dt AS "CORPGOV_START_DATE"
      , Corpgov.Stop_dt AS "CORPGOV_STOP_DATE"
      , Corpgov.status AS "CORPGOV_STATUS"
      , Corpgov.Role AS "CORPGOV_ROLE"
--      , case when WomenSummit.short_desc Like 'KSM Global W%s Summit' then 'Y' else 'N' 
--            End WomenSummit_Ind
--      , WomenSummit.Start_dt AS "WS_START_DATE"
--      , Womensummit.Stop_dt AS "WS_STOP_DATE"
--      , Womensummit.status AS "WS_STATUS"
--      , Womensummit.Role AS "WS_ROLE"
      ,  case when DivSummit.short_desc = 'KSM Chief Diversity Officer Summit' then 'Y' else 'N' 
            End DivSummit_Ind
      , DivSummit.Start_dt AS "DS_START_DATE"
      , DivSummit.Stop_dt AS "DS_STOP_DATE"
      , DivSummit.status AS "DS_STATUS"
      , DivSummit.Role AS "DS_ROLE"
      ,  case when RealEstCouncil.short_desc = 'Real Estate Advisory Council' then 'Y' else 'N' 
            End RealEst_Ind
      , RealEstCouncil.Start_dt AS "REC_START_DATE"
      , RealEstCouncil.Stop_dt AS "REC_STOP_DATE"
      , RealEstCouncil.status AS "REC_STATUS"
      , RealEstCouncil.Role AS "REC_ROLE"
      ,  case when AMP.short_desc = 'AMP Advisory Council' then 'Y' else 'N' 
            End AMP_Ind
      , AMP.Start_dt AS "AMP_START_DATE"
      , AMP.Stop_dt AS "AMP_STOP_DATE"
      , AMP.status AS "AMP_STATUS"
      , AMP.Role AS "AMP_ROLE",
  nvl(NU_LT_Giving.giving_total, 0) AS NU_LT_Giving,
  nvl(CFY_NULT_Giving.CFY_NULT_Giving, 0) AS CFY_NULT_Giving,
  nvl(LFY_NULT_Giving.LFY_NULT_Giving, 0) AS LFY_NULT_Giving,
  nvl(LFY2_NULT_Giving.LFY2_NULT_Giving, 0) AS LFY2_NULT_Giving,
  nvl(KSM_LT_Giving.credit_amount, 0) AS KSM_LT_Giving,
  nvl(KSM_Campaign_Giving.campaign_giving,0) AS KSM_Campaign_Giving,
  nvl(ProposalCount.ProposalCount, 0) AS Proposal_Count,
  nvl(AF_Giving_CurrentFY.Legal_Total, 0) as AF_CFY_Legal,
  nvl(AF_Giving_CurrentFY.Credit_Total, 0) AS AF_CFY_SftCredit, 
  nvl(AF_Giving_FY_1.Legal_Total, 0) AS AF_LYFY_Legal,
  nvl(AF_Giving_FY_1.Credit_Total, 0) AS AF_LYFY_SftCredit,
  nvl(AF_Giving_FY_2.Legal_Total, 0) AS AF_LYFY2_Legal,
  nvl(AF_Giving_FY_2.Credit_Total, 0) AS AF_LYFY2_SftCredit, 
  nvl(KSM_Giving.Legal_Total, 0) AS KSM_CFY_Legal,
  nvl(KSM_Giving.credit_Total, 0) AS KSM_CFY_SftCredit,
  nvl(KSM_Giving_FY_1.Legal_Total, 0) AS KSM_LYFY_Legal,
  nvl(KSM_Giving_FY_1.credit_Total, 0) AS KSM_LYFY_SftCredit,
  nvl(KSM_Giving_FY_2.Legal_Total, 0) AS KSM_LYFY2_Legal,
  nvl(KSM_Giving_FY_2.credit_Total, 0) AS KSM_LYFY2_SftCredit,
  nvl(KSM_Campaign_Giving.CAMPAIGN_CFY, 0) AS CAMPAIGN_CFY,
  nvl(KSM_Campaign_Giving.Campaign_PFY1, 0) AS CAMPAIGN_PFY1, 
  nvl(KSM_Campaign_Giving.Campaign_PFY2, 0) AS CAMPAIGN_PFY2,
  nvl(KSM_Campaign_Giving.Campaign_PFY3, 0) AS CAMPAIGN_PFY3
FROM nu_prs_trp_prospect prs
Inner Join All_Committee_Data On All_Committee_Data.id_number = prs.id_number
Inner Join All_Committees ON All_Committees.id_number = prs.id_number
Left Join AMP
ON AMP.id_number = All_Committees.id_number
Left Join RealEstCouncil
ON RealEstCouncil.id_number = All_Committees.id_number
Left Join DivSummit
ON DivSummit.id_number = All_Committees.id_number
Left Join WomenSummit
ON WomenSummit.id_number = All_Committees.id_number
Left Join CorpGov
ON CorpGov.id_number = All_Committees.id_number
Left Join KFN
ON KFN.id_number = All_Committees.id_number
Left Join GAB
ON GAB.id_number = All_Committees.id_number
Left Join KSMdegree
ON KSMdegree.id_number = prs.id_number
Left Join ProposalCount
ON ProposalCount.prospect_ID = prs.prospect_ID
Left Join AF_Giving_CurrentFY
ON All_Committees.id_number = AF_Giving_CurrentFY.id_number
Left Join AF_Giving_FY_2
ON All_Committees.id_number = AF_Giving_FY_2.id_number
Left Join AF_Giving_FY_1
ON All_Committees.id_number = AF_Giving_FY_1.id_number
Left Join KSM_Giving
ON All_Committees.id_number = KSM_Giving.id_number
Left Join KSM_Giving_FY_1
ON All_Committees.id_number = KSM_Giving_FY_1.id_number
Left Join KSM_Giving_FY_2
ON All_Committees.id_number = KSM_Giving_FY_2.id_number
LEFT JOIN KSM_Campaign_Giving
ON All_Committees.ID_NUMBER = KSM_Campaign_Giving.ID_NUMBER
LEFT JOIN KSM_LT_Giving
ON All_Committees.ID_Number = KSM_LT_Giving.ID_Number
LEFT JOIN NU_LT_Giving
ON All_Committees.ID_Number = NU_LT_Giving.ID_Number
LEFT JOIN KSM_Campaign_Giving
ON All_Committees.ID_Number = KSM_Campaign_Giving.ID_Number
LEFT JOIN CFY_NULT_Giving
ON All_Committees.ID_Number = CFY_NULT_Giving.ID_Number
LEFT JOIN LFY_NULT_Giving
ON All_Committees.ID_Number = LFY_NULT_Giving.ID_Number
LEFT JOIN LFY2_NULT_Giving
ON All_Committees.ID_Number = LFY2_NULT_Giving.ID_Number
