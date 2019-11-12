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

Create Or Replace View v_datamart_interests As
-- View of INTEREST (Alumni List) v-datamart_interests
Select
  interest.id_number As catracks_id
  , tms_interest.short_desc AS interest_desc
  , interest.interest_code As interest_code
  , interest.start_dt
  , rpt_pbh634.ksm_pkg.to_date2(start_dt) As interest_start_date
  , interest.stop_dt
  , rpt_pbh634.ksm_pkg.to_date2(stop_dt) As interest_stop_date
  , interest.date_added
  , interest.date_modified
From interest 
Inner Join tms_interest
  On tms_interest.interest_code = interest.interest_code --- Produce TMS Codes
Inner Join rpt_pbh634.v_entity_ksm_degrees deg
  On deg.id_number = interest.id_number --- Only Kellogg Alumni
Where tms_interest.interest_code Like 'L%' --- Any Linkedin Industry Code
  Or tms_Interest.interest_code = '16'  --- KIS also wants the "16" Research Code
Order By interest_code Asc
;

Create Or Replace View v_datamart_ids As
-- View of KSM alumni with least a EMPLID, SES, or NETID along with a Catracks ID: v_datamart_ids
With ksm_ids As (
  Select ids_base.id_number
    , ids_base.ids_type_code
    , ids_base.other_id
  From rpt_pbh634.v_entity_ksm_degrees deg --- Kellogg Alumni Only
  Left Join ids_base
    On ids_base.id_number = deg.id_number
  Where ids_base.ids_type_code In ('SES', 'KSF','NET') --- SES = EMPLID + KSF = Salesforce ID + NET = NetID
) 

Select Distinct
  ksm_ids.id_number As catracks_id
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
  And net.ids_type_code = 'NET' --- Selects IDs for each row
;

Create Or Replace View v_datamart_address As
-- View for Address (Business + Home) v_data_mart_address
With business_address As (
  Select Distinct
    address.id_number
    , address.city
    , address.state_code
    , address.country_code
    , address.addr_type_code
    , address.addr_status_code
    , rpt_pbh634.v_geo_code_primary.geo_codes
    , rpt_pbh634.v_geo_code_primary.geo_code_primary
    , rpt_pbh634.v_geo_code_primary.geo_code_primary_desc
  From Address
  Left Join rpt_pbh634.v_geo_code_primary
    On rpt_pbh634.v_geo_code_primary.id_number = address.id_number
    And rpt_pbh634.v_geo_code_primary.xsequence = address.xsequence --- Joining Paul's New Geocode Table to get Business Address Geocodes 
  Where address.addr_type_code = 'B'
  and Address.Addr_Status_Code = 'A'
)

, home_address As (
  Select Distinct
    address.id_number
    , address.city --- KIS Wants Homes
    , address.state_code
    , address.country_code
    , address.addr_type_code
    , address.addr_status_code
    , rpt_pbh634.v_geo_code_primary.geo_codes --- KIS Wants Geocodes Home Address
    , rpt_pbh634.v_geo_code_primary.geo_code_primary
    , rpt_pbh634.v_geo_code_primary.geo_code_primary_desc
  From Address
  Left Join rpt_pbh634.v_geo_code_primary
    On rpt_pbh634.v_geo_code_primary.id_number = address.id_number
    And rpt_pbh634.v_geo_code_primary.xsequence = address.xsequence --- Joining Paul's New Geocode Table to get Business Address Geocodes
  Where address.addr_type_code = 'H'
    and address.addr_status_code = 'A'
)

Select Distinct 
  address.id_number As catracks_id
  , home_address.city As home_city
  , home_address.state_code As home_state
  , home_address.country_code As home_country
  , home_address.geo_codes As home_geo_codes
  , home_address.geo_code_primary As home_geo_primary_code
  , home_address.geo_code_primary_desc As home_geo_primary_desc
  , business_address.city As business_city
  , business_address.state_code As business_state
  , business_address.country_code As business_country_code
  , tms_country.short_desc As business_country
  , business_address.geo_codes As business_geo_code --- Kis Wants Geocodes for Business Address
  , business_address.geo_code_primary As business_geo_primary_code
  , business_address.geo_code_primary_desc As business_geo_primary_desc
From address 
Inner Join rpt_pbh634.v_entity_ksm_degrees deg
  On deg.id_number = address.id_number --- Degrees Table Base to only get KSM Alumni
Left Join address
  On deg.id_number = address.id_number --- Joining Address Table to get Business Address
Left Join business_address
  On business_address.id_number = deg.id_number --- Join Subquery for Business Address
Left Join home_address
  On home_address.id_number = deg.id_number --- Join Subquery for Home Address
Left Join tms_country 
  On business_address.country_code = tms_country.country_code --- Join to get Home Country Description
Order By address.id_number Asc
;

Create or Replace View v_datamart_employment AS
--- View for Employer: v_data_mart_employer
With org_employer As (
  --- Using subquery to Get Employer Names from Employee ID #'s 
  Select id_number, report_name
  From entity 
  Where entity.person_or_org = 'O'
) 

Select
  employ.id_Number As catracks_id
  , employ.start_dt As start_date
  , rpt_pbh634.ksm_pkg.to_date2(employ.start_dt) As employment_start_date
  , employ.Stop_Dt As stop_date
  , rpt_pbh634.ksm_pkg.to_date2(employ.stop_dt) As employment_stop_date
  , employ.job_status_code As job_status_code
  , tms_job_status.short_desc As job_status_desc
  , employ.primary_emp_ind As primary_employer_indicator
  , employ.self_employ_ind As self_employed_indicator
  , employ.job_title
  , Case --- Used for those alumni with an employer code, but not employer name1
      When employ.employer_name1 = ' '
        Then org_employer.report_name
      Else employ.employer_name1
      End
    As employer
  , employ.fld_of_work_code As fld_of_work_code
  , fow.short_desc As fld_of_work_desc
  , employ.date_added
  , employ.date_modified
  , employ.operator_name
From employment employ
Inner Join rpt_pbh634.v_entity_ksm_degrees deg
  On deg.id_number = employ.id_number --- To get KSM alumni 
Inner Join tms_fld_of_work fow
  On employ.fld_of_work_code = fow.fld_of_work_code --- To get FLD of Work Code
Left  Join tms_job_status
  On tms_job_status.job_status_code = employ.job_status_code --- To get job description
Left Join org_employer
  On org_employer.id_number = employ.employer_id_number --- To get the name of those with employee ID
Where employ.job_status_code In ('C','P','Q','R', ' ', 'L')
--- Employment Key: C = Current, P = Past, Q = Semi Retired R = Retired L = On Leave 
Order By employ.id_Number Asc
;

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
Inner Join rpt_pbh634.v_entity_ksm_degrees deg -- Alumni only
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
From rpt_pbh634.v_entity_ksm_degrees deg
Left Join tms_record_status tms_rs
  On tms_rs.record_status_code = deg.record_status_code
Where deg.record_status_code In ('A', 'C', 'L', 'D')
;
