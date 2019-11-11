/************************************************************************
Assorted views for the KSM data mart

Conventions:
- id_number renamed to catracks_id
- Code fields end in _code
- Translated values of the code fields end in _desc for description
- Include both string and converted date versions of e.g. start/stop date
  E.g. interest_start_dt
- Always include date added and modified in the disaggregated data views
************************************************************************/

Create or Replace View v_datamart_interests As


Select interest.id_Number AS catracks_id,
       tms_interest.short_desc AS interest_desc,
       interest.interest_Code As interest_code,
       interest.start_dt,
       rpt_pbh634.ksm_pkg.to_date2(start_dt) As interest_start_date,
       interest.stop_dt,
       rpt_pbh634.ksm_pkg.to_date2(stop_dt) As interest_stop_date,
       interest.date_added,
       interest.date_modified
From Interest 
Inner JOIN tms_interest ON tms_interest.interest_code = interest.interest_code --- Produce TMS Codes
Inner Join rpt_pbh634.v_entity_ksm_degrees deg on deg.id_number = interest.id_number --- Only Kellogg Alumni
Where tms_interest.interest_code LIKE 'L%' --- Any Linkedin Industry Code
or tms_Interest.interest_code = '16'  --- KIS also wants the "16" Research Code 
Order By interest_code ASC;


--- View of KSM alumni with least a EMPLID, SES, or NETID along with a Catracks ID: v_datamart_ids 


Create or Replace View v_datamart_ids AS 
 

With KSM_IDS AS (select ids_base.id_number,

       ids_base.ids_type_code,

       ids_base.other_id

From rpt_pbh634.v_entity_ksm_degrees deg --- Kellogg Alumni Only

Left Join ids_base on ids_Base.id_number = deg.id_number

Where ids_base.ids_type_code IN('SES', 'KSF','NET')) --- SES = EMPLID + KSF = Salesforce ID + NET = NetID

Select Distinct
KSM_ids.id_number As catracks_id
, ses.other_id As emplid
, ksf.other_id As salesforce_id
, net.other_id As netid
From ksm_ids
Inner Join rpt_pbh634.v_entity_ksm_degrees deg
     On deg.id_number = ksm_ids.id_number
Left Join ksm_ids ses
     On ses.id_number = ksm_ids.id_number
     And ses.ids_type_code = 'SES'
Left Join ksm_ids KSF
     On ksf.id_number = ksm_ids.id_number
     And ksf.ids_type_code = 'KSF'
Left Join ksm_ids net
     On net.id_number = ksm_ids.id_number
     And net.ids_type_code = 'NET'; --- Selects IDs for each row


--- View for Address (Business + Home) v_data_mart_address 


Create or Replace View v_datamart_address AS


With Business_Address As (

Select Distinct 
Address.Id_Number,
Address.City,
Address.State_Code,
Address.Country_Code,
Address.Addr_Type_Code,
Address.Addr_Status_Code,
rpt_pbh634.v_geo_code_primary.GEO_CODES,
rpt_pbh634.v_geo_code_primary.GEO_CODE_PRIMARY,
rpt_pbh634.v_geo_code_primary.GEO_CODE_PRIMARY_DESC

From Address
Left Join rpt_pbh634.v_geo_code_primary on rpt_pbh634.v_geo_code_primary.ID_NUMBER = address.ID_NUMBER
And rpt_pbh634.v_geo_code_primary.XSEQUENCE = address.XSEQUENCE --- Joining Paul's New Geocode Table to get Business Address Geocodes 
Where Address.addr_type_code = 'B'
and Address.Addr_Status_Code = 'A'),

Home_Address As (

Select Distinct 
Address.Id_Number,
Address.City,--- KIS Wants Homes
Address.State_Code,
Address.Country_Code,
Address.Addr_Type_Code,
Address.Addr_Status_Code,
rpt_pbh634.v_geo_code_primary.GEO_CODES,--- KIS Wants Geocodes Home Address
rpt_pbh634.v_geo_code_primary.GEO_CODE_PRIMARY,
rpt_pbh634.v_geo_code_primary.GEO_CODE_PRIMARY_DESC

From Address
Left Join rpt_pbh634.v_geo_code_primary on rpt_pbh634.v_geo_code_primary.ID_NUMBER = address.ID_NUMBER
And rpt_pbh634.v_geo_code_primary.XSEQUENCE = address.XSEQUENCE --- Joining Paul's New Geocode Table to get Business Address Geocodes 
Where Address.addr_type_code = 'H'
and Address.Addr_Status_Code = 'A')


Select Distinct 
address.id_number As Catracks_ID,
       home_address.city AS home_city, 
       home_address.state_code AS home_state,
       home_address.country_code AS home_country,
       home_address.GEO_CODES AS home_geo_codes,
       home_address.GEO_CODE_PRIMARY AS home_geo_primary_code, 
       home_address.GEO_CODE_PRIMARY_DESC AS home_geo_primary_desc,
       Business_Address.City AS business_city,
       Business_Address.State_Code AS business_state,
       Business_Address.Country_Code AS business_country_code,
       tms_country.short_desc As business_country,
       Business_Address.GEO_CODES AS business_geo_code, --- Kis Wants Geocodes for Business Address
       Business_Address.GEO_CODE_PRIMARY As business_geo_primary_code,
       Business_Address.GEO_CODE_PRIMARY_DESC AS business_geo_primary_desc
From address 
Inner Join rpt_pbh634.v_entity_ksm_degrees deg on deg.id_number = address.id_number --- Degrees Table Base to only get KSM Alumni
Left Join address ON deg.ID_NUMBER = address.id_number --- Joining Address Table to get Business Address
Left Join Business_Address ON Business_Address.Id_Number = deg.ID_NUMBER --- Join Subquery for Business Address
Left Join Home_Address ON Home_Address.id_number = deg.ID_NUMBER --- Join Subquery for Home Address
Left Join tms_country ON business_address.Country_Code = tms_country.country_code --- Join to get Home Country Description
Order By address.ID_NUMBER ASC;


--- View for Employer: v_data_mart_employer

Create or Replace View v_datamart_employment AS

With org_employer As 
(Select id_number, report_name
From entity 
Where entity.person_or_org = 'O') --- Using subquery to Get Employer Names from Employee ID #'s 

Select employ.id_Number AS catracks_id,
       employ.start_dt As start_date,
       rpt_pbh634.ksm_pkg.to_date2 (employ.start_dt) As employment_start_date,
       employ.Stop_Dt As stop_date,
       rpt_pbh634.ksm_pkg.to_date2 (employ.Stop_Dt) As employment_stop_date,
       employ.job_status_code As job_status_code,
       tms_job_status.short_desc AS job_status_desc,
       employ.primary_emp_Ind AS primary_employer_indicator,
       employ.self_employ_Ind As self_employed_indicator,
       employ.job_title,
       (Case When Employ.Employer_Name1 = ' ' then org_employer.report_name Else Employ.Employer_Name1 End) As Employer, --- Used for those alumni with an employer code, but not employer name1
       employ.fld_of_work_code As fld_of_work_code,
       fow.short_desc AS Fld_of_work_desc,
       employ.date_added,
       employ.date_modified,
       employ.operator_name
       

From employment employ
Inner Join rpt_pbh634.v_entity_ksm_degrees deg on deg.ID_NUMBER = employ.id_number --- To get KSM alumni 
Inner Join tms_fld_of_work fow on employ.fld_of_work_code = fow.fld_of_work_code --- To get FLD of Work Code
Left  Join tms_job_status On tms_job_status.job_status_code = employ.job_status_code --- To get job description
Left Join org_employer ON org_employer.id_number = employ.employer_id_number --- To get the name of those with employee ID
Where employ.job_status_code IN ('C','P','Q','R', ' ', 'L')
--- Employment Key: C = Current, P = Past, Q = Semi Retired R = Retired L = On Leave 
Order By employ.id_Number ASC;

Create Or Replace View v_datamart_degrees As
-- KSM degrees view
-- Includes Kellogg degrees
Select
  degrees.id_number As catracks_id
  , degrees.institution_code
  , institution.institution_name
  , degrees.school_code
  , tms_sch.short_desc As school_desc
  , degrees.campus_code
  , tms_cmp.short_desc As campus_desc
  , degrees.degree_code
  , tms_deg.short_desc As degree_desc
  , degrees.degree_year
  , degrees.grad_dt
  , rpt_pbh634.ksm_pkg.to_date2(degrees.grad_dt) As grad_date
  , degrees.class_section
  , tms_cs.short_desc As class_section_desc
  , degrees.dept_code
  , tms_dc.short_desc As dept_desc
  , degrees.major_code1
  , degrees.major_code2
  , degrees.major_code3
  , m1.short_desc As major_desc1
  , m2.short_desc As major_desc2
  , m3.short_desc As major_desc3
  , degrees.date_added
  , degrees.date_modified
  , degrees.operator_name
From degrees
Inner Join v_entity_ksm_degrees deg -- Alumni only
  On deg.id_number = degrees.id_number
Left Join institution
  On institution.institution_code = degrees.institution_code
Left Join tms_school tms_sch
  On tms_sch.school_code = degrees.school_code
Left Join tms_campus tms_cmp
  On tms_cmp.campus_code = degrees.campus_code
Left Join tms_degrees tms_deg
  On tms_deg.degree_code = degrees.degree_code
Left Join tms_class_section tms_cs
  On tms_cs.section_code = degrees.class_section
Left Join tms_dept_code tms_dc
  On tms_dc.dept_code = degrees.dept_code
Left Join tms_majors m1
  On m1.major_code = degrees.major_code1
Left Join tms_majors m2
  On m2.major_code = degrees.major_code2
Left Join tms_majors m3
  On m3.major_code = degrees.major_code3
;

Create Or Replace View v_datamart_entities As
-- KSM entity view
-- Core alumni table which includes summary information and current fields from the other views
-- Aggregated to return one unique alum per line
Select
  deg.id_number As catracks_id
  , deg.degrees_concat
  , deg.degrees_verbose
  , deg.program
  , deg.program_group
  , deg.majors_concat
  , deg.record_status_code
  , tms_rs.short_desc As record_status_desc
  -- Current home address info
  -- Current business address info
  -- Current employment info
  -- Concatenated interests
From v_entity_ksm_degrees deg
Left Join tms_record_status tms_rs
  On tms_rs.record_status_code = deg.record_status_code
Where deg.record_status_code In ('A', 'C', 'L', 'D')
;
