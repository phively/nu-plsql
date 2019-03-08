CREATE or REPLACE VIEW KSM_MGO_Audit AS

select distinct
       Phf.prospect_id,
       Phf.prospect_name,
       Phf.prospect_name_sort,
       PP.prospect_manager_id,
       PP.prospect_manager,
--       PP.degrees_concat,
--       PP.INSTITUTIONAL_SUFFIX,
--       PP.SPOUSE_DEGREES_CONCAT,
--       PP.SPOUSE_SUFFIX,
       Phf.proposal_id,
       Phf.ksm_proposal_ind,
       Phf.proposal_title,
       Phf.proposal_description,
       Phf.proposal_type,
       Phf.proposal_manager_id,
       Phf.proposal_manager,
       Phf.proposal_assist,
       Phf.historical_managers,
       Phf.proposal_status_code,
       Phf.probability,
       Phf.hierarchy_order,
       Phf.proposal_status,
       Phf.proposal_active,
       Phf.proposal_in_progress,
       Phf.proposal_active_calc,
       Phf.prop_purposes,
       Phf.initiatives,
       Phf.other_programs,
       Phf.university_strategy,
       Phf.start_date,
       Phf.start_fy,
       Phf.start_dt_calc,
       Phf.ask_date,
       Phf.ask_fy,
       Phf.close_date,
       Phf.close_fy,
       Phf.close_dt_calc,
       Phf.date_modified,
       Phf.total_original_ask_amt,
       Phf.total_ask_amt,
       Phf.total_anticipated_amt,
       Phf.total_granted_amt,
       Phf.ksm_ask,
       Phf.ksm_anticipated,
       Phf.ksm_af_ask,
       Phf.ksm_af_anticipated,
       Phf.ksm_facilities_ask,
       Phf.ksm_facilities_anticipated,
       Phf.ksm_or_univ_ask,
       Phf.ksm_or_univ_orig_ask,
       Phf.ksm_or_univ_anticipated,
       Phf.final_anticipated_or_ask_amt,
       Phf.ksm_bin,
Case when KSM_OR_UNIV_ASK >= 100000 
  AND TOTAL_GRANTED_AMT >= 98000
  AND proposal_Status = 'Funded'
--  AND TO_DATE(Close_date, 'DD/MM/YYYY') BETWEEN TO_DATE('05/01/2018') AND TO_DATE(
  THEN rpt_pbh634.ksm_pkg.get_performance_year(Close_date)
    ELSE NULL
      End MG_Commitments
      ,
Case when KSM_OR_UNIV_ASK >= 100000 
  AND proposal_Status IN ('Verbal', 'Submitted', 'Declined', 'Funded')
  THEN rpt_pbh634.ksm_pkg.get_performance_year(ASK_date)
    ELSE NULL
      End MG_Solicitations
      ,
Case when KSM_OR_UNIV_ASK >= 100000 
  AND TOTAL_GRANTED_AMT >= 48000
  AND proposal_Status = 'Funded'
  THEN rpt_pbh634.ksm_pkg.get_performance_year(Close_date)
    ELSE NULL
      End MG_Dollars_Raised
      ,
CC.Today,
CC.CURR_FY,
CC.CURR_FY_START,
CC.CURR_PY,
CC.Curr_PY_Start
from rpt_pbh634.v_proposal_history_fast PHF
Left Join Prospect_Entity PE
ON PE.prospect_ID = PHF.prospect_id
Inner join rpt_pbh634.v_ksm_prospect_pool PP
ON PP.prospect_id = PHF.prospect_ID
Cross Join rpt_pbh634.v_current_calendar CC
Where PE.Primary_Ind = 'Y'
Order by phf.proposal_id

--select * from rpt_pbh634.v_proposal_history_fast PHF
