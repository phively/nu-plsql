/***************************************
Gift officer proposal metrics audit
***************************************/

CREATE or REPLACE VIEW rpt_dgz654.KSM_MGO_Audit AS

select distinct
       Phf.prospect_id,
       Phf.prospect_name,
       Phf.prospect_name_sort,
       PE.id_number,
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
Left join nu_prs_trp_prospect PP
ON PP.prospect_id = PHF.prospect_ID
Cross Join rpt_pbh634.v_current_calendar CC
Where PE.Primary_Ind = 'Y'
Order by phf.proposal_id

--select * from rpt_pbh634.v_proposal_history_fast PHF
;

/***************************************
Gift officer contact report metrics audit
***************************************/

CREATE or REPLACE VIEW rpt_dgz654.MGD_Contact_Reports AS

With
/*
--Earliest Date visited by Kellogg Officer
KSM_Visited AS(
     Select 
     min(CR.report_ID) keep(dense_rank First Order By CR.contact_date Asc) AS Earliest_Visit
     , min(CR.contact_date) AS Earliest_Visit_Date
     , CR.credited
     , CR.credited_name
     , CR.ID_Number
     , CR.contacted_name
     From rpt_pbh634.v_contact_reports_fast CR
     Inner Join table(rpt_pbh634.ksm_pkg.tbl_frontline_ksm_staff)ST
     ON CR.credited = ST.ID_Number
     AND CR.contact_type = 'Visit'
     AND ST.ID_Number IN ('0000549376', '0000562459', '0000776709','0000642888', '0000561243','0000565742', '0000220843', '0000779347','0000772028')
     group by CR.ID_Number, CR.contacted_name, CR.credited, CR.credited_name
     Order By CR.ID_Number desc  
     ),
--Managed after the earliest visit
M_After_Visit AS(
     Select 
*/
Prospect_Manager AS (
     Select 
     A.prospect_ID
     , PE.ID_Number
     , PE.Primary_Ind
     , A.assignment_ID_Number AS Prospect_Manager_ID
     , E.Pref_Mail_Name AS Prospect_Manager
     From assignment A
     Inner Join prospect_entity PE
     ON A.prospect_ID = PE.prospect_Id
     Inner Join entity E
     ON A.assignment_id_number = E.id_number
     Where A.assignment_type = 'PM'
     AND A.active_IND = 'Y'
     AND PE.Primary_Ind = 'Y'
)

select CR.*
, PP.prospect_manager_id
, PP.prospect_manager
, assign.manager_ids
, assign.managers
, assign.curr_ksm_manager
, E.Institutional_Suffix
, hh.degrees_concat
, hh.household_city
, hh.household_state
, hh.household_country
, rpt_pbh634.ksm_pkg.get_performance_year(contact_date) AS PY_Contact

From rpt_pbh634.v_contact_reports_fast CR
Inner Join rpt_pbh634.v_entity_ksm_households hh
  On hh.id_number = CR.id_number
Left Join Prospect_manager PP
ON PP.ID_NUMBER = CR.id_number
Inner join entity e
ON E.Id_number = CR.Id_number
Left Join rpt_pbh634.v_assignment_summary assign
  On assign.id_number = cr.id_number
