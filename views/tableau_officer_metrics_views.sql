/***************************************
Gift officer proposal metrics audit
***************************************/

Create Or Replace View rpt_dgz654.ksm_mgo_audit As

Select Distinct
  Phf.prospect_id
  , Phf.prospect_name
  , Phf.prospect_name_sort
  , PE.id_number
  , hh.household_city
  , hh.household_geo_primary_desc
  , hh.household_state
  , hh.household_country
  , PP.prospect_manager_id
  , PP.prospect_manager
  , Phf.proposal_id
  , Phf.ksm_proposal_ind
  , Phf.proposal_title
  , Phf.proposal_description
  , Phf.proposal_type
  , Phf.proposal_manager_id
  , Phf.proposal_manager
  , Phf.proposal_assist
  , Phf.historical_managers
  , Phf.metrics_credit_ids
  , Phf.metrics_credit_names
  , Phf.proposal_status_code
  , Phf.probability
  , Phf.hierarchy_order
  , Phf.proposal_status
  , Phf.proposal_active
  , Phf.proposal_in_progress
  , Phf.proposal_active_calc
  , Phf.prop_purposes
  , Phf.initiatives
  , Phf.other_programs
  , Phf.university_strategy
  , Phf.start_date
  , Phf.start_fy
  , Phf.start_dt_calc
  , Phf.ask_date
  , Phf.ask_fy
  , Phf.close_date
  , Phf.close_fy
  , Phf.close_dt_calc
  , Phf.date_modified
  , Phf.total_original_ask_amt
  , Phf.total_ask_amt
  , Phf.total_anticipated_amt
  , Phf.total_granted_amt
  , Phf.ksm_ask
  , Phf.ksm_anticipated
  , Phf.ksm_af_ask
  , Phf.ksm_af_anticipated
  , Phf.ksm_facilities_ask
  , Phf.ksm_facilities_anticipated
  , Phf.ksm_or_univ_ask
  , Phf.ksm_or_univ_orig_ask
  , Phf.ksm_or_univ_anticipated
  , Phf.final_anticipated_or_ask_amt
  , Phf.ksm_bin
  , Case
      When ksm_or_univ_ask >= 100000 
        And total_granted_amt >= 98000
        And proposal_Status_code = '7'
        Then rpt_pbh634.ksm_pkg.get_performance_year(close_date)
      Else NULL
      End
    As MG_Commitments
  , Case
      When ksm_or_univ_ask >= 100000 
        And proposal_status_code In ('5', 'C', 'B', '8', '7')
        Then rpt_pbh634.ksm_pkg.get_performance_year(ask_date)
      Else NULL
      End
    As MG_Solicitations
  , Case
      When ksm_or_univ_ask >= 100000 
        And total_granted_amt >= 48000
        And proposal_status_code = '7'
        Then rpt_pbh634.ksm_pkg.get_performance_year(close_date)
      Else NULL
      End
    As MG_Dollars_Raised
  , CC.Today
  , CC.CURR_FY
  , CC.CURR_FY_START
  , CC.CURR_PY
  , CC.Curr_PY_Start
From rpt_pbh634.v_proposal_history_fast PHF
Inner Join Prospect_Entity PE
  On PE.prospect_ID = PHF.prospect_id
Inner Join rpt_pbh634.v_entity_ksm_households hh
  On hh.id_number = pe.id_number
Left Join nu_prs_trp_prospect PP
  On PP.prospect_id = PHF.prospect_ID
Cross Join rpt_pbh634.v_current_calendar CC
Where PE.Primary_Ind = 'Y'
Order by phf.proposal_id
;

/***************************************
Gift officer contact report metrics audit
***************************************/

Create Or Replace View rpt_dgz654.mgo_contact_reports As

With

Prospect_Manager As (
  Select
    A.prospect_ID
    , PE.ID_Number
    , PE.Primary_Ind
    , A.assignment_ID_Number As Prospect_Manager_ID
    , E.Pref_Mail_Name As Prospect_Manager
  From assignment A
  Inner Join prospect_entity PE
    On A.prospect_ID = PE.prospect_Id
  Inner Join entity E
    On A.assignment_id_number = E.id_number
  Where A.assignment_type = 'PM'
    And A.active_IND = 'Y'
    And PE.Primary_Ind = 'Y'
)

Select
  CR.*
  , PP.prospect_manager_id
  , PP.prospect_manager
  , assign.manager_ids
  , assign.managers
  , assign.curr_ksm_manager
  , E.Institutional_Suffix
  , hh.degrees_concat
  , hh.household_city
  , hh.household_geo_primary_desc
  , hh.household_state
  , hh.household_country
  , rpt_pbh634.ksm_pkg.get_performance_year(contact_date) As PY_Contact
From rpt_pbh634.v_contact_reports_fast CR
Inner Join rpt_pbh634.v_entity_ksm_households hh
  On hh.id_number = CR.id_number
Left Join Prospect_manager PP
  On PP.ID_NUMBER = CR.id_number
Inner Join entity e
  On E.Id_number = CR.Id_number
Left Join rpt_pbh634.v_assignment_summary assign
  On assign.id_number = cr.id_number
;
