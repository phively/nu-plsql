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
