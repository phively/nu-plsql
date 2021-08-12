/************************************************************************
Assorted views for the KSM data mart

Conventions:
- id_number renamed to catracks_id
- Code fields end in _code
- Translated values of the code fields end in _desc for description
- Include both string and converted date versions of e.g. start/stop date
  E.g. interest_start_dt
- Fields ending in _dt are strings and those ending in _date are dates
- Always include date added and modified in the disaggregated data views
************************************************************************/

/************************************************************************
Disaggregated interests view for data mart

Updated 2019-11-12
- Includes only career-related interests
************************************************************************/
Create Or Replace View v_datamart_career_interests As
-- View of INTEREST (Alumni List) v-datamart_interests
Select
  interest.id_number As catracks_id
  , interest.interest_code As interest_code
  , tms_interest.short_desc As interest_desc
  , interest.start_dt
  , rpt_pbh634.ksm_pkg.to_date2(start_dt) As interest_start_date
  , interest.stop_dt
  , rpt_pbh634.ksm_pkg.to_date2(stop_dt) As interest_stop_date
  , interest.date_added
  , interest.date_modified
  , interest.operator_name
From interest 
Inner Join tms_interest
  On tms_interest.interest_code = interest.interest_code --- Produce TMS Codes
Inner Join rpt_pbh634.v_entity_ksm_degrees deg
  On deg.id_number = interest.id_number --- Only Kellogg Alumni
Where tms_interest.interest_code Like 'L%' --- Any Linkedin Industry Code
  Or tms_Interest.interest_code = '16'  --- KIS also wants the "16" Research Code
and deg.record_status_code != 'X' --- Remove Purgable
Order By interest_code Asc
;

/************************************************************************
Aggregated IDs view for data mart

Updated 2019-11-12
Updated 2019-11-20
- Added KSM Exec Ed ID
************************************************************************/
Create Or Replace View v_datamart_ids As
-- View of KSM alumni with least a EMPLID, NETID, EXED, Salesforce ID along with a Catracks ID: v_datamart_ids
With

ksm_ids As (
  Select ids_base.id_number
    , ids_base.ids_type_code
    , ids_base.other_id
  From rpt_pbh634.v_entity_ksm_degrees deg --- Kellogg Alumni Only
  Left Join ids_base
    On ids_base.id_number = deg.id_number
  Where ids_base.ids_type_code In ('SES', 'KSF', 'NET', 'KEX') --- SES = EMPLID + KSF = Salesforce ID + NET = NetID + KEX = KSM EXED ID
) 

Select Distinct
  ksm_ids.id_number As catracks_id
  , ses.other_id As emplid
  , ksf.other_id As salesforce_id
  , net.other_id As netid
  , kex.other_id AS ksm_exed_id
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
  And net.ids_type_code = 'NET'
Left Join ksm_ids kex
  On kex.id_number = ksm_ids.id_number
  And kex.ids_type_code = 'KEX'
Where deg.record_status_code != 'X' --- Remove Purgable
  --- Selects IDs for each row
  ;

/************************************************************************
Aggregated address view for data mart

Updated 2019-11-12
- Includes only current home and business addresses, as well as
  the job title/company associated with each business address (if any)
Updated 2021-08-11
-Includes Home and Business Zipcodes and Foreign Zipcodes
************************************************************************/
Create Or Replace View v_datamart_address As
-- View for Address (Business + Home) v_data_mart_address
With
business_address As (
  Select
    address.id_number
    , trim(address.business_title) As business_job_title
    , trim(
        trim(address.company_name_1) || ' ' || trim(address.company_name_2)
      ) As business_company_name
    , address.city
    , address.state_code
    , address.zipcode
    , address.foreign_cityzip
    , address.country_code
    , address.addr_type_code
    , address.addr_status_code
    , address.start_dt
    , rpt_pbh634.ksm_pkg.to_date2(address.start_dt) As start_date
    , address.date_modified
    , rpt_pbh634.v_geo_code_primary.geo_codes
    , rpt_pbh634.v_geo_code_primary.geo_code_primary
    , rpt_pbh634.v_geo_code_primary.geo_code_primary_desc
    , geo.LATITUDE
    , geo.LONGITUDE
  From address
  Left Join rpt_pbh634.v_geo_code_primary
    On rpt_pbh634.v_geo_code_primary.id_number = address.id_number
    And rpt_pbh634.v_geo_code_primary.xsequence = address.xsequence --- Joining Paul's New Geocode Table to get Business Address Geocodes 
  Left Join rpt_pbh634.v_addr_geocoding geo --- Joining Geocode table for latitude and longitude 
  On geo.id_number = address.id_number
  And geo.xsequence = address.xsequence
  Where address.addr_type_code = 'B'
  and Address.Addr_Status_Code = 'A'
)

, home_address As (
  Select
    address.id_number
    , address.city --- KIS Wants Homes
    , address.state_code
    , address.zipcode
    , address.foreign_cityzip
    , address.country_code
    , address.addr_type_code
    , address.addr_status_code
    , address.start_dt
    , rpt_pbh634.ksm_pkg.to_date2(address.start_dt) As start_date
    , address.date_modified
    , rpt_pbh634.v_geo_code_primary.geo_codes --- KIS Wants Geocodes Home Address
    , rpt_pbh634.v_geo_code_primary.geo_code_primary
    , rpt_pbh634.v_geo_code_primary.geo_code_primary_desc
    , geo.LATITUDE
    , geo.LONGITUDE
  From address
  Left Join rpt_pbh634.v_geo_code_primary
    On rpt_pbh634.v_geo_code_primary.id_number = address.id_number
    And rpt_pbh634.v_geo_code_primary.xsequence = address.xsequence --- Joining Paul's New Geocode Table to get Business Address Geocodes
  Left Join rpt_pbh634.v_addr_geocoding geo --- Joining Geocode table for latitude and longitude
  On geo.id_number = address.id_number
  And geo.xsequence = address.xsequence
  Where address.addr_type_code = 'H'
    and address.addr_status_code = 'A'
)

Select 
  deg.id_number As catracks_id
  , home_address.city As home_city
  , home_address.state_code As home_state
  , home_address.zipcode AS home_zipcode
  , home_address.foreign_cityzip AS home_foreign_zipcode
  , home_address.country_code As home_country_code
  , tms_home.country As home_country_desc
  , home_address.geo_codes As home_geo_codes
  , home_address.geo_code_primary As home_geo_primary_code
  , home_address.geo_code_primary_desc As home_geo_primary_desc
  , home_address.LATITUDE as home_latitude
  , home_address.LONGITUDE as home_longitude
  , home_address.start_dt As home_start_dt
  , home_address.start_date As home_start_date
  , home_address.date_modified As home_date_modified
  , business_address.business_job_title
  , business_address.business_company_name
  , business_address.city As business_city
  , business_address.state_code As business_state
  , business_address.zipcode AS business_zipcode
  , business_address.foreign_cityzip AS business_foreign_zipcode
  , business_address.country_code As business_country_code
  , tms_bus.country As business_country_desc
  , business_address.geo_codes As business_geo_codes --- KIS Wants Geocodes for Business Address
  , business_address.geo_code_primary As business_geo_primary_code
  , business_address.geo_code_primary_desc As business_geo_primary_desc
  , business_address.LATITUDE as business_latitude
  , business_address.LONGITUDE as business_longitude 
  , business_address.start_dt As business_start_dt
  , business_address.start_date As business_start_date
  , business_address.date_modified As business_date_modified
From rpt_pbh634.v_entity_ksm_degrees deg
Left Join business_address
  On business_address.id_number = deg.id_number --- Join Subquery for Business Address
Left Join home_address
  On home_address.id_number = deg.id_number --- Join Subquery for Home Address
Left Join rpt_pbh634.v_addr_continents tms_bus
  On business_address.country_code = tms_bus.country_code --- Join to get Home Country Description
Left Join rpt_pbh634.v_addr_continents tms_home
  On home_address.country_code = tms_home.country_code
Where deg.record_status_code != 'X' --- Remove Purgable
Order By deg.id_number Asc
;

/************************************************************************
Disaggregated employment view for data mart

Updated 2019-11-12
- Includes both current and past job information
- N.B. people may not have a row on the employment table but have text
  entered under company or job_title on the address table
Updated 2021-08-11
- Includes Employer ID Number
************************************************************************/
Create or Replace View v_datamart_employment As
--- View for Employer: v_data_mart_employer
With
org_employer As (
  --- Using subquery to Get Employer Names from Employee ID #'s 
  Select id_number, report_name
  From entity 
  Where entity.person_or_org = 'O'
) 

Select
  employ.id_Number As catracks_id
  , employ.start_dt
  , rpt_pbh634.ksm_pkg.to_date2(employ.start_dt) As employment_start_date
  , employ.stop_dt
  , rpt_pbh634.ksm_pkg.to_date2(employ.stop_dt) As employment_stop_date
  , employ.job_status_code As job_status_code
  , tms_job_status.short_desc As job_status_desc
  , employ.primary_emp_ind As primary_employer_indicator
  , employ.self_employ_ind As self_employed_indicator
  , employ.job_title
  , employ.employer_id_number
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
Left Join tms_fld_of_work fow
  On employ.fld_of_work_code = fow.fld_of_work_code --- To get FLD of Work Code
Left  Join tms_job_status
  On tms_job_status.job_status_code = employ.job_status_code --- To get job description
Left Join org_employer
  On org_employer.id_number = employ.employer_id_number --- To get the name of those with employee ID
Where employ.job_status_code In ('C', 'P', 'Q', 'R', ' ', 'L')
--- Employment Key: C = Current, P = Past, Q = Semi Retired R = Retired L = On Leave
and deg.record_status_code != 'X' --- Remove Purgable
Order By employ.id_Number Asc
;

/************************************************************************
Disaggregated degree view for data mart

Updated 2019-11-12
- Includes all degrees, not just KSM or NU ones
************************************************************************/

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
Where deg.record_status_code != 'X' --- Remove Purgable
;

/************************************************************************
Entity view for data mart aggregating current data together

Includes Active, Current, Lost, Deceased record types

Updated 2019-11-12
- Primary job title and employer are defined as the title/company associated
  with the current business address if they are filled in; otherwise
  the current primary employer defined in v_datamart_employment
2019-11-20
- Added current employment field of work
- Primary job title and employer are now defined as the title/company
  associated with the most recently updated table, whether employment
  or address with addr_type_code = 'B'
2021-08-11
- Includes: Home and Business Zipcode and Foreign Zipcodes
- Employer ID 
- First, Last Name
- Gender
- Ethnicity 
- Birthdate
************************************************************************/

Create Or Replace View v_datamart_entities As
-- KSM entity view
-- Core alumni table which includes summary information and current fields from the other views
-- Aggregated to return one unique alum per line
With
emp As (
  Select
    empl.catracks_id
    , empl.employment_start_date
    , empl.job_title
    , empl.employer
    , empl.fld_of_work_desc
    , empl.date_modified
    , empl.employer_id_number
  From v_datamart_employment empl
  Where empl.job_status_code = 'C' -- current only
    And empl.primary_employer_indicator = 'Y' -- primary employer only
)

, intr As (
  Select
    intr.catracks_id
    , Listagg(intr.interest_desc, '; ') Within Group (Order By interest_start_date Asc, interest_desc Asc)
      As interests_concat
  From v_datamart_career_interests intr
  Group By intr.catracks_id
),

Reunion As 
( Select aff.id_number,
         aff.affil_code,
         aff.affil_level_code,
         aff.class_year
From affiliation aff
Where aff.affil_code = 'KM'
And aff.affil_level_code = 'RG')

, linked as (select distinct ec.id_number,
max(ec.start_dt) keep(dense_rank First Order By ec.start_dt Desc, ec.econtact asc) As Max_Date,
max (ec.econtact) keep(dense_rank First Order By ec.start_dt Desc, ec.econtact asc) as linkedin_address
from econtact ec
where  ec.econtact_status_code = 'A'
and  ec.econtact_type_code = 'L'
Group By ec.id_number)

, emp_chooser As (
  Select
    deg.id_number As catracks_id
    , entity.first_name
    , entity.middle_name
    , entity.last_name
    , entity.gender_code
    , TMS_RACE.short_desc as race
    , entity.birth_dt
    , deg.REPORT_NAME
    , deg.RECORD_STATUS_CODE
    , deg.degrees_concat
    , deg.degrees_verbose
    , deg.program
    , deg.program_group
    , deg.majors_concat
    , reunion.class_year AS reunion_class_year
    , tms_rs.short_desc As record_status_desc
    , addr.home_city
    , addr.home_state
    , addr.home_zipcode
    , addr.home_foreign_zipcode
    , addr.home_country_desc
    , addr.home_geo_codes
    , addr.home_geo_primary_desc
    , addr.home_start_date
    -- Determine whether to use business job title or employment job title
    -- The row with a later modified date is assumed to be more recent
    , addr.business_date_modified
    , emp.date_modified As employment_date_modified
    , Case
        -- No data -> none
        When addr.business_date_modified Is Null
          And emp.date_modified Is Null
          Then 'None'
        When addr.business_date_modified Is Not Null
          And emp.date_modified Is Null
          Then 'Address'
        When addr.business_date_modified Is Null
          And emp.date_modified Is Not Null
          Then 'Employment'
        When addr.business_date_modified >= emp.date_modified
          Then 'Address'
        When addr.business_date_modified <= emp.date_modified
          Then 'Employment'
        Else '#ERR'
        End
      As primary_job_source
    , emp.job_title
    , emp.employer
    , emp.fld_of_work_desc
    , emp.employer_id_number
    , addr.business_job_title
    , addr.business_company_name
    , addr.business_city
    , addr.business_state
    , addr.business_zipcode
    , addr.business_foreign_zipcode
    , addr.business_country_desc
    , addr.business_geo_codes
    , addr.business_geo_primary_desc
    , addr.business_start_date
    , intr.interests_concat
    , linked.linkedin_address
  From rpt_pbh634.v_entity_ksm_degrees deg
  Left Join tms_record_status tms_rs
    On tms_rs.record_status_code = deg.record_status_code
  Left Join v_datamart_address addr
    On addr.catracks_id = deg.id_number
  Left join emp
    On emp.catracks_id = deg.id_number
  Left Join intr
    On intr.catracks_id = deg.id_number
  Left Join linked
    On linked.id_number = deg.id_number
  Left Join entity 
    On entity.id_number = deg.id_number
  Left Join TMS_RACE 
    ON TMS_RACE.ethnic_code = entity.ethnic_code
  Left Join Reunion 
    On Reunion.id_number = deg.id_number
  Where deg.record_status_code In ('A', 'C', 'L', 'D')
  and deg.record_status_code != 'X' --- Remove Purgable
)

Select
  catracks_id
  , first_name
  , middle_name
  , last_name
  , gender_code
  , race
  , birth_dt
  , report_name
  , degrees_concat
  , degrees_verbose
  , program
  , program_group
  , majors_concat
  , reunion_class_year
  , record_status_code
  , record_status_desc
  , home_city
  , home_state
  , home_zipcode
  , home_foreign_zipcode
  , home_country_desc
  , home_geo_codes
  , home_geo_primary_desc
  , home_start_date
  , linkedin_address
  , employer_id_number
  , Case
      When primary_job_source = 'Address'
        Then business_job_title
      Else job_title
      End
    As primary_job_title
  , Case
      When primary_job_source = 'Address'
        Then business_company_name
      Else employer
      End
    As primary_employer
  , business_city
  , business_state
  , business_zipcode
  , business_foreign_zipcode
  , business_country_desc
  , business_geo_codes
  , business_geo_primary_desc
  , business_start_date
  , fld_of_work_desc
  , interests_concat
  , primary_job_source
  , business_date_modified
  , employment_date_modified
From emp_chooser
;

/************************************************************************

Updated: 2021-08-11

Added a new view to include giving data
Most Recent Gift Credit Year 
Gift Credit Years in Prev 5 
Gift Credit Years of $100+ 
Gift Credit Years of Gift Credit Years of $1K+ 
Gift Credit Years of $1K+ in Past 5 FYs 
Annual Giving Category 
Kellogg Most Recent Gift Credit Year 
Kellogg Gift Credit Years in Prev 5 
Kellogg Gift Credit Years of $100+ 
Kellogg Gift Credit Years of $1K+ 
Kellogg Gift Credit Years of $1K+ in Past 5 
Kellogg Annual Giving Category 
Kellogg AF Most Recent Gift Credit Year 
Kellogg AF Gift Credit Years in Prev 5 
Kellogg AF Gift Credit Years of $1K+ 
Kellogg AF Gift Credit Years of $1K+ in Past 5 FYs 
Kellogg AF Annual Giving Category 


************************************************************************/


Create or Replace View v_datamart_giving as 

With gs as (select      
     g.ID_NUMBER,
--- Last Gift Date
     g.LAST_GIFT_DATE,
     --- Giving Last 5 Years
     g.NGC_CFY,
     g.NGC_PFY1,
     g.NGC_PFY2,
     g.NGC_PFY3,
     g.NGC_PFY4,
     g.NGC_PFY5,
     --- Annual Fund Status
     g.af_status, 
     g.af_status_fy_start,
     --- Annual Fund Giving
     g.CRU_CFY,
     g.CRU_PFY1,
     g.CRU_PFY2,
     g.CRU_PFY3,
     g.CRU_PFY4,
     g.CRU_PFY5,
     g.LAST_GIFT_ALLOC_CODE,
     g.FY_GIVING_FIRST_YR,
     g.FY_GIVING_LAST_YR,
     g.FY_GIVING_YR_COUNT
from RPT_PBH634.v_Ksm_Giving_Summary g),

give As (
--- Counting Years of Gifts $100 and $1000 

select give.ID_NUMBER,
--- Last 5 Years Over $100 NGC
count(Case When give.NGC_CFY > 100
or give.NGC_PFY1 > 100 or give.NGC_PFY2 > 100 or give.NGC_PFY3 > 100 or give.NGC_PFY4 > 100
or give.NGC_PFY5 > 100 Then give.FY_GIVING_YR_COUNT Else NULL End)  as Count_Yrs_Gifts_Over_100,
--- Last 5 Years Over $1000 NGC
count(Case When give.NGC_CFY > 1000 or give.NGC_PFY1 > 1000
or give.NGC_PFY2 > 1000 or give.NGC_PFY3 > 1000 or give.NGC_PFY4 > 1000 or give.NGC_PFY5 > 1000 
Then give.FY_GIVING_YR_COUNT Else NULL End) as Count_Yrs_Gifts_Over_1000,
--- Last 5 Years Over $100 AF
count(Case When give.CRU_CFY > 100 or give.NGC_PFY1 > 100
or give.CRU_PFY2 > 100 or give.CRU_PFY3 > 100 or give.CRU_PFY4 > 100 or give.CRU_PFY5 > 100 
Then give.FY_GIVING_YR_COUNT Else NULL End) as Count_AFYrs_Gifts_Over_100,
--- Last 5 Years Over $1000 AF 
count(Case When give.CRU_CFY > 1000 or give.NGC_PFY1 > 1000
or give.CRU_PFY2 > 1000 or give.CRU_PFY3 > 1000 or give.CRU_PFY4 > 1000 or give.CRU_PFY5 > 1000 
Then give.FY_GIVING_YR_COUNT Else NULL End) as Count_AFYrs_Gifts_Over_1000
       From rpt_pbh634.v_entity_ksm_households hh
       inner join gs give on give.id_number = hh.id_number 
       Group By give.id_number)

Select deg.ID_NUMBER,
--- Last Gift Date
     gs.LAST_GIFT_DATE,
     --- Giving Last 5 Years
     gs.NGC_CFY,
     gs.NGC_PFY1,
     gs.NGC_PFY2,
     gs.NGC_PFY3,
     gs.NGC_PFY4,
     gs.NGC_PFY5,
     --- Annual Fund Status
     gs.af_status, 
     gs.af_status_fy_start,
     --- Annual Fund Giving
     gs.CRU_CFY,
     gs.CRU_PFY1,
     gs.CRU_PFY2,
     gs.CRU_PFY3,
     gs.CRU_PFY4,
     gs.CRU_PFY5,
     gs.LAST_GIFT_ALLOC_CODE,
     gs.FY_GIVING_FIRST_YR,
     gs.FY_GIVING_LAST_YR,
     gs.FY_GIVING_YR_COUNT,
     give.Count_Yrs_Gifts_Over_100,
     give.Count_Yrs_Gifts_Over_1000,
     give.Count_AFYrs_Gifts_Over_100,
     give.Count_AFYrs_Gifts_Over_1000
from rpt_pbh634.v_entity_ksm_degrees deg
left join gs on gs.id_number = deg.ID_NUMBER
left join give on give.ID_NUMBER = deg.ID_NUMBER;
