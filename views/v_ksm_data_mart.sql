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
  , rpt_pbh634.ksm_pkg_tmp.to_date2(start_dt) As interest_start_date
  , interest.stop_dt
  , rpt_pbh634.ksm_pkg_tmp.to_date2(stop_dt) As interest_stop_date
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
    , rpt_pbh634.ksm_pkg_tmp.to_date2(address.start_dt) As start_date
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
    , rpt_pbh634.ksm_pkg_tmp.to_date2(address.start_dt) As start_date
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
),

p_employ as (Select
  id_number
  , ultimate_parent_employer_id
  , ultimate_parent_employer_name
From dm_ard.dim_employment@catrackstobi)

Select
  employ.id_Number As catracks_id
  , employ.start_dt
  , rpt_pbh634.ksm_pkg_tmp.to_date2(employ.start_dt) As employment_start_date
  , employ.stop_dt
  , rpt_pbh634.ksm_pkg_tmp.to_date2(employ.stop_dt) As employment_stop_date
  , employ.job_status_code As job_status_code
  , tms_job_status.short_desc As job_status_desc
  , employ.primary_emp_ind As primary_employer_indicator
  , employ.self_employ_ind As self_employed_indicator
  , employ.job_title
  , employ.employer_id_number
  , p_employ.ultimate_parent_employer_id
  , p_employ.ultimate_parent_employer_name
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
Left Join P_Employ on P_Employ.id_number = deg.id_number --- to get parent employer ID and parent employer name
Where employ.job_status_code In ('C', 'P', 'Q', 'R', ' ', 'L')
--- Employment Key: C = Current, P = Past, Q = Semi Retired R = Retired L = On Leave
and deg.record_status_code != 'X' --- Remove Purgable
Order By employ.id_Number Asc
;

/************************************************************************
Disaggregated degree view for data mart

Updated 2019-11-12
- Includes all degrees, not just KSM or NU ones

Updated 2022-05-05
-Including first KSM Year and first Masters Year from Paul's Degree View
- Included a case when for KSM years as well 
- Adding degree level
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
  , degrees.degree_level_code 
  , TMS_DEGREE_LEVEL.short_desc As Degree_Level_Desc
  , degrees.grad_dt
  , rpt_pbh634.ksm_pkg_tmp.to_date2(degrees.grad_dt) As grad_date
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
  , case when deg.FIRST_KSM_YEAR is not null and degrees.school_code = 'KSM' then deg.FIRST_KSM_YEAR End As First_KSM_Year
  , case when deg.FIRST_MASTERS_YEAR is not null and degrees.school_code = 'KSM' then deg.FIRST_MASTERS_YEAR End as First_KSM_Masters_Year
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
Left join TMS_DEGREE_LEVEL 
ON TMS_DEGREE_LEVEL.degree_level_code = degrees.degree_level_code
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
2022-05-05
- Added Full Birthday
- Adding in Pref Mail Name and Dean Salutation (Nickname)
************************************************************************/

Create Or Replace View v_datamart_entities As
-- KSM entity view
-- Core alumni table which includes summary information and current fields from the other views
-- Aggregated to return one unique alum per line
--- Adding Pref Mail Name and Nickname (Dean Salut)
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
    , empl.ultimate_parent_employer_id
    , empl.ultimate_parent_employer_name
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
(Select aff.id_number,
         Listagg (aff.class_year, ';  ') Within Group (Order By aff.class_year) As class_year
From affiliation aff
Where aff.affil_code = 'KM'
And aff.affil_level_code = 'RG'
Group By aff.id_number)

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
    , p.P_Dean_Salut
    , p.p_pref_mail_name
    , entity.gender_code
    , TMS_RACE.short_desc as race
    , entity.birth_dt
    , deg.REPORT_NAME
    , deg.RECORD_STATUS_CODE
    , deg.degrees_concat
    , deg.degrees_verbose
    , deg.FIRST_KSM_YEAR
    , deg.FIRST_MASTERS_YEAR
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
    , emp.ultimate_parent_employer_id as ult_parent_employer_id
    , emp.ultimate_parent_employer_name as ult_parent_employer_name
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
  Left Join rpt_zrc8929.v_dean_salutation p
    On p.id_number = deg.id_number
  Where deg.record_status_code In ('A', 'C', 'L', 'D')
  and deg.record_status_code != 'X' --- Remove Purgable
)

Select
  catracks_id
  , first_name
  , middle_name
  , last_name
  , P_Dean_Salut
  , p_pref_mail_name
  , gender_code
  , race
  , (substr (birth_dt, 1, 10)) as birth_dt
  , report_name
  , degrees_concat
  , degrees_verbose
  , program
  , program_group
  , FIRST_KSM_YEAR
  , FIRST_MASTERS_YEAR
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
  , fld_of_work_desc as employment_industry
  , interests_concat as industry_interest_concat
  , primary_job_source
  , business_date_modified
  , employment_date_modified
From emp_chooser
;




/*** 

Updated: 2021-08-24
 Paul Hively
    Giving definitions
1) subquery based on v_ksm_giving_trans_hh
2) drop any transactions that are anonymous, e.g. WHERE trim(anonymous) is null
3) drop any entities with anonymous special handling code

, anonymous As (
Select *
From v_entity_special_handling sh
Where sh."ANONYMOUS_DONOR" = 'Y'
)

Fields to include, ALWAYS excluding the transactions above:
1) FY of most recent transaction, group by entity
2) Made any gifts this FY (use v_current_calendar)
3) Made any gifts last FY
4) KSM total years of giving (count distinct fiscal_year)
5) AF donor status - you can get this from v_ksm_giving_summary, but again drop anonymous donors
6) KLC status - this FY - from gift_clubs (again drop anonymous donors)
7) KLC status - last FY
8) Distinct years of giving in last 5 (should be a number 0 to 5; maybe try count(distinct fiscal_year) again)
9) KSM KLC years on record (count distinct year from gift_club, again dropping anonymous)


****/

Create or Replace View v_datamart_giving as 



/* 
EXCLUSIONS:
1) Drop all records linked to an entity with the anonymous special handling code
2) Drop individual gifts with anonymous type 1, 2, 3 for the purpose of calculating the suggested fields,or alternatively drop all such records

*/ 

With a As (
Select *
From rpt_pbh634.v_entity_special_handling sh
--- Drop all records linked to an entity with the anonymous special handling code
Where sh.ANONYMOUS_DONOR is not null
),

hh as (select *
from rpt_pbh634.v_ksm_giving_trans_hh
--- Drop individual gifts with anonymous type 1, 2, 3 for the purpose of calculating the suggested fields,or alternatively drop all such records
where trim(rpt_pbh634.v_ksm_giving_trans_hh.ANONYMOUS) is null),

degrees as (select *
from rpt_pbh634.v_entity_ksm_degrees),

--- Subquery for spouse (9/29) where we take out anonymous donor. 

spouse as (select degrees.id_number,
a_spouse.ANONYMOUS_DONOR
from degrees 
left join a a_spouse on a_spouse.spouse_id_number = degrees.id_number
where a_spouse.anonymous_donor is not null),

give as (select give.ID_NUMBER, 
give.af_status,
rpt_pbh634.ksm_pkg_tmp.get_fiscal_year(give.LAST_GIFT_DATE) as last_gift_fy
from RPT_PBH634.v_Ksm_Giving_Summary give), --- stewardship amount

--- Subquery (9/29) for Most Recent Gift, but takes out anonymous donors

max_date as (select hh.ID_NUMBER,
rpt_pbh634.ksm_pkg_tmp.get_fiscal_year (max (hh.DATE_OF_RECORD)) as last_gift_fy 
from hh
where trim (hh.ANONYMOUS) is null
group by hh.ID_NUMBER),

/* KSM Donor Current FY and Last FY
Using a subquery to find out if an entity gave during a given year */
Donor as (select distinct hh.ID_NUMBER,
Max(Case When cal.curr_fy = fiscal_year Then hh.FISCAL_YEAR Else NULL End) as KSM_donor_cfy,
Max(Case When cal.curr_fy = fiscal_year + 1 Then hh.FISCAL_YEAR Else NULL End) as KSM_donor_pfy1
from hh
inner join degrees on degrees.ID_NUMBER = hh.ID_NUMBER
cross join rpt_pbh634.v_current_calendar cal
where trim(hh.ANONYMOUS) is null
Group by hh.ID_NUMBER),

/* Donor Indicator of FY and PFY
Using the previous subquery to populate and Yes or Null to donor in a given year */

Donor_Ind AS (Select Donor.id_number,
Case when Donor.KSM_donor_cfy is not null then 'Yes' Else '' END as Donor_fy_ind,
Case when Donor.KSM_donor_pfy1 is not null then 'Yes' Else '' END as Donor_pfy_ind
from Donor),

---- KSM Total Years of Giving
G as (select hh.ID_NUMBER,
count (distinct hh.FISCAL_YEAR) as fy_count
from hh
group by hh.ID_NUMBER),

/* KLC Membership Queries
1. Establishing KLC Members
2. Separate Queries to Count Total KLC Years and for the last 5 */

--- Establishing KLC Membership: Date Functions to reflect years in gift club

KLC AS (Select distinct
       GIFT_CLUBS.GIFT_CLUB_ID_NUMBER,
       GIFT_CLUBS.GIFT_CLUB_CODE,
       TMS_GIFT_CLUB_TABLE.club_desc,
       rpt_pbh634.ksm_pkg_tmp.get_fiscal_year (GIFT_CLUBS.GIFT_CLUB_END_DATE) as Club_END_DATE
FROM GIFT_CLUBS
LEFT JOIN TMS_GIFT_CLUB_TABLE ON TMS_GIFT_CLUB_TABLE.club_code = GIFT_CLUBS.GIFT_CLUB_CODE
Where GIFT_CLUB_CODE = 'LKM'),


KLC_Give_Ind As (select KLC.GIFT_CLUB_ID_NUMBER,
Max(Case When cal.curr_fy = Club_END_DATE Then 'Yes' Else NULL End) as KSM_donor_cfy,
Max(Case When cal.curr_fy = Club_END_DATE + 1 Then 'Yes' Else NULL End) as KSM_donor_pfy1
from KLC
cross join rpt_pbh634.v_current_calendar cal
group BY KLC.GIFT_CLUB_ID_NUMBER),

--- Count Total KLC Years 

KLC_Count As (Select distinct KLC.GIFT_CLUB_ID_NUMBER,
Count (distinct Club_END_DATE) as klc_fy_count
from KLC
cross join rpt_pbh634.v_current_calendar cal
GROUP BY KLC.GIFT_CLUB_ID_NUMBER),

--- Count of KLC Years, but in last 5

KLC5 AS (Select distinct KLC.GIFT_CLUB_ID_NUMBER,
Count (distinct Club_END_DATE) as klc_fy_count_5
from KLC
cross join rpt_pbh634.v_current_calendar cal
Where (KLC.Club_END_DATE = cal.CURR_FY - 1
or KLC.Club_END_DATE = cal.CURR_FY - 2
or KLC.Club_END_DATE = cal.CURR_FY - 3 
or KLC.Club_END_DATE = cal.CURR_FY - 4
or KLC.Club_END_DATE = cal.CURR_FY - 5)
Group By KLC.GIFT_CLUB_ID_NUMBER),


KLC_Final As (Select distinct KLC.GIFT_CLUB_ID_NUMBER,
--- KLC FY Donor This Year
KLC_Give_Ind.KSM_donor_cfy,
--- KLC FY Donor Last Year 
KLC_Give_Ind.KSM_donor_pfy1,
--- KLC Total Years on Record 
KLC_Count.klc_fy_count,
--- KLC Total Years in the Last 5
KLC5.klc_fy_count_5
from KLC
left join KLC_Count on KLC_Count.GIFT_CLUB_ID_NUMBER = KLC.GIFT_CLUB_ID_NUMBER
left join KLC5 ON KLC5.GIFT_CLUB_ID_NUMBER = KLC.GIFT_CLUB_ID_NUMBER 
left join KLC_Give_Ind on KLC_Give_Ind.GIFT_CLUB_ID_NUMBER = KLC.GIFT_CLUB_ID_NUMBER
cross join rpt_pbh634.v_current_calendar cal)

/* Final Query */

Select distinct degrees.ID_NUMBER
--- FY of most recent gift, pledge, or payment, (numeric)
,max_date.last_gift_fy --use FY function, give FY not date
--- KSM Donor this Year
,Donor_Ind.Donor_fy_ind as KSM_Donor_CFY
--- KSM Donor last Year
,Donor_Ind.Donor_pfy_ind as KSM_Donor_Pfy
--- KSM Total Years of Giving (Numeric) 
,G.fy_count as KSM_total_years_giving
--- Current KSM AF donor status, (Donor, LYBUNT, PYBUNT, Lapsed, Non)
,Give.af_status
--- KLC FY Donor This Year
,KLC_Final.KSM_donor_cfy as KSM_KLC_Donor_CFY
--- KLC FY Donor Last Year 
,KLC_Final.KSM_donor_pfy1 as KSM_KLC_Donor_PFY
--- KLC Total Years on Record 
,KLC_Final.klc_fy_count as KSM_KLC_Total_FY_Count
--- KLC Total Years in the Last 5
,KLC_Final.klc_fy_count_5 as KSM_KLC_Last5_PFY_Count
FROM degrees
Left Join a on a.id_number = degrees.ID_NUMBER
Left Join give on give.id_number = degrees.ID_NUMBER
Left Join g on g.id_number = degrees.ID_NUMBER
Left Join KLC_Final on KLC_Final.GIFT_CLUB_ID_NUMBER = degrees.ID_NUMBER
Left Join Donor_Ind on Donor_Ind.id_number = degrees.id_number
Left Join spouse on spouse.id_number = degrees.id_number
Left Join max_date on max_date.id_number = degrees.id_number
where a.ANONYMOUS_DONOR is null
and spouse.ANONYMOUS_DONOR is null;

--- View to Pull in KSM Students with CATracks ID, EMPLID, Insitutiona and affilations

/*

Confirmed by Jennifer Meyer

Hi Sergio - 

Yes, the affiliation table is the best place to base your query on.  

You are correct that if someone is an Alum and has now re-enrolled as a student their Record Type will still show Alum and not Student (there can be only one Record Type and Alum takes priority).  

However, the Affiliation table will show all existing student or alumni paths that individual has earned/is on.  Also, the affiliation table is going to be more accurate/up to date for their affiliated school because it is pulling directly from SES (where student and degree information is stored from the registrar).    

Your query looks good!


*/

Create or Replace View v_datamart_students as

With ksm_ids As (
  Select ids_base.id_number
    , ids_base.ids_type_code
    , ids_base.other_id
  From entity --- Kellogg Alumni Only
  Left Join ids_base
    On ids_base.id_number = entity.id_number
  Where ids_base.ids_type_code In ('SES') --- SES = EMPLID + KSF = Salesforce ID + NET = NetID + KEX = KSM EXED ID
),

KSM_Email AS (select email.id_number,
       TMS_EMAIL_TYPE.short_desc,
       email.email_type_code,
       email.email_address
From email
Left join TMS_EMAIL_TYPE ON TMS_EMAIL_TYPE.email_type_code = email.email_type_code
Where email.preferred_ind = 'Y'),

KSM_Spec AS (Select spec.ID_NUMBER,
       spec.NO_PHONE_IND,
       spec.NO_CONTACT,
       spec.NO_EMAIL_IND,
       spec.ACTIVE_WITH_RESTRICTIONS
From rpt_pbh634.v_entity_special_handling spec),

linked as (select distinct ec.id_number,
max(ec.start_dt) keep(dense_rank First Order By ec.start_dt Desc, ec.econtact asc) As Max_Date,
max (ec.econtact) keep(dense_rank First Order By ec.start_dt Desc, ec.econtact asc) as linkedin_address
from econtact ec
where  ec.econtact_status_code = 'A'
and  ec.econtact_type_code = 'L'
Group By ec.id_number),

org_employer As (
  --- Using subquery to Get Employer Names from Employee ID #'s 
  Select id_number, report_name
  From entity 
  Where entity.person_or_org = 'O'
),

p_employ as (Select
  id_number
  , ultimate_parent_employer_id
  , ultimate_parent_employer_name
From dm_ard.dim_employment@catrackstobi),


employ As (
Select
  employ.id_Number As catracks_id
  , employ.start_dt
  , rpt_pbh634.ksm_pkg_tmp.to_date2(employ.start_dt) As employment_start_date
  , employ.stop_dt
  , rpt_pbh634.ksm_pkg_tmp.to_date2(employ.stop_dt) As employment_stop_date
  , employ.job_status_code As job_status_code
  , tms_job_status.short_desc As job_status_desc
  , employ.primary_emp_ind As primary_employer_indicator
  , employ.self_employ_ind As self_employed_indicator
  , employ.job_title
  , employ.employer_id_number
  , p_employ.ultimate_parent_employer_id
  , p_employ.ultimate_parent_employer_name
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
Left Join rpt_pbh634.v_entity_ksm_households h on h.id_number = employ.id_number
Left Join tms_fld_of_work fow
  On employ.fld_of_work_code = fow.fld_of_work_code --- To get FLD of Work Code
Left  Join tms_job_status
  On tms_job_status.job_status_code = employ.job_status_code --- To get job description
Left Join org_employer
  On org_employer.id_number = employ.employer_id_number --- To get the name of those with employee ID
Left Join P_Employ on P_Employ.id_number = h.id_number --- to get parent employer ID and parent employer name
Where employ.job_status_code In ('C', 'P', 'Q', 'R', ' ', 'L')
--- Employment Key: C = Current, P = Past, Q = Semi Retired R = Retired L = On Leave
and h.record_status_code != 'X' --- Remove Purgable
Order By employ.id_Number Asc),

e as (Select
  employ.catracks_id
  , max (employ.start_dt) as start_dt
  , max (rpt_pbh634.ksm_pkg_tmp.to_date2(employ.start_dt)) As employment_start_date
  , max (employ.stop_dt) as stop_dt
  , max (employ.job_status_desc) As job_status_code
  , max (job_status_desc) As job_status_desc
  , max (employ.primary_employer_indicator) As primary_employer_indicator
  , max (employ.self_employed_indicator) As self_employed_indicator
  , max (employ.job_title) as job_title
  , max (employ.employer_id_number) as employer_id_number
  , max (employ.ultimate_parent_employer_id) as ultimate_parent_employer_id
  , max (employ.ultimate_parent_employer_name) as ultimate_parent_employer_name
  , max (employ.employer) as employer
  , max (employ.fld_of_work_desc) As fld_of_work_code
  , max (employ.fld_of_work_desc) As fld_of_work_desc
  , max (employ.date_added) as date_added
  , max (employ.date_modified) as date_modified
  , max (employ.operator_name) as operator_name
  from employ 
  group by employ.catracks_id),

intr As (
  Select
    intr.catracks_id
    , Listagg(intr.interest_desc, '; ') Within Group (Order By interest_start_date Asc, interest_desc Asc)
      As interests_concat
  From v_datamart_career_interests intr
  Group By intr.catracks_id
),

Reunion As 
(Select aff.id_number,
         Listagg (aff.class_year, ';  ') Within Group (Order By aff.class_year) As class_year
From affiliation aff
Where aff.affil_code = 'KM'
And aff.affil_level_code = 'RG'
Group By aff.id_number),

--- Pull Affilaton For Student Details 

--- Creating a Listag for Affilation Level, Class Year and Start Date 
--- Noticed that a few entities had multiple aff levels (masters/doctorate)
--- Coding defensively just in case a future recrod has mult class years and start dates

lev as (select distinct affiliation.id_number,
--- Concat Affilation Levels
listagg (tms_affiliation_level.short_desc, ';  ') Within Group (Order By tms_affiliation_level.short_desc) As affilation_level,
--- Possibly concat if there are mult years
listagg (affiliation.class_year, ';  ') Within Group (Order By affiliation.class_year) As class_year,
--- Earliest Date of Enrollment
min (affiliation.start_date) as start_date
from affiliation 
LEFT JOIN tms_affiliation_level on tms_affiliation_level.affil_level_code = affiliation.affil_level_code
--- Pulling school code and enrollment - This will pull in "Alumni" from other schools who are students at KSM 
where affiliation.affil_code = 'KM'
and affiliation.affil_status_code = 'E'
Group by affiliation.id_number),

A as (SELECT DISTINCT
aff.id_number,
aff.affil_code,
tms_affil_code.short_desc as affilation,
lev.affilation_level,
tms_affil_status.short_desc as affilation_status,
lev.class_year,
lev.start_date
  FROM  affiliation aff
  Inner Join lev on lev.id_number = aff.id_number
  LEFT JOIN tms_affil_code on tms_affil_code.affil_code = aff.affil_code
  LEFT JOIN tms_affiliation_level on tms_affiliation_level.affil_level_code = aff.affil_level_code
  Left Join tms_affil_status on  tms_affil_status.affil_status_code = aff.affil_status_code
--- Pulling school code and enrollment - This will pull in "Alumni" from other schools who are students at KSM 
 WHERE  (aff.affil_code = 'KM' 
   AND  aff.affil_status_code = 'E')),
   
emp_chooser As (
  Select Distinct
    h.id_number As catracks_id
    , ksm_ids.other_id As EMPLID
    , h.INSTITUTIONAL_SUFFIX
    , entity.first_name
    , entity.middle_name
    , entity.last_name
    , p.P_Dean_Salut
    , p.p_pref_mail_name
    , entity.gender_code
    , TMS_RACE.short_desc as race
    , entity.birth_dt
    , h.REPORT_NAME
    , h.RECORD_STATUS_CODE
    , a.id_number
    , a.affil_code
    , a.affilation
    , a.affilation_level
    , a.affilation_status
    , a.class_year
    , a.start_date
    , d.degrees_concat
    , d.degrees_verbose
    , d.FIRST_KSM_YEAR
    , d.FIRST_MASTERS_YEAR
    , h.program
    , h.program_group
    , d.majors_concat
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
    , e.date_modified As employment_date_modified
    , Case
        -- No data -> none
        When addr.business_date_modified Is Null
          And e.date_modified Is Null
          Then 'None'
        When addr.business_date_modified Is Not Null
          And e.date_modified Is Null
          Then 'Address'
        When addr.business_date_modified Is Null
          And e.date_modified Is Not Null
          Then 'Employment'
        When addr.business_date_modified >= e.date_modified
          Then 'Address'
        When addr.business_date_modified <= e.date_modified
          Then 'Employment'
        Else '#ERR'
        End
      As primary_job_source
    , e.job_title
    , e.employer
    , e.fld_of_work_desc
    , e.employer_id_number
    , e.ultimate_parent_employer_id as ult_parent_employer_id
    , e.ultimate_parent_employer_name as ult_parent_employer_name
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
       --- Case when Email Type 
    , Case  When NO_Email_Ind is null then KSM_email.short_desc 
      when KSM_Spec.NO_Email_Ind is not null then 'No Email' End as email_type
      ---- Case when email addresses
    , Case When KSM_Spec.NO_Email_Ind is null then KSM_email.email_address 
      when KSM_Spec.NO_Email_Ind is not null then 'No Email' End as Email
  From rpt_pbh634.v_entity_ksm_households h
    Inner Join A on A.id_number = h.id_number
  Left Join rpt_pbh634.v_entity_ksm_degrees d 
    On d.id_number = h.id_number
  Left Join tms_record_status tms_rs
    On tms_rs.record_status_code = h.record_status_code
  Left Join v_datamart_address addr
    On addr.catracks_id = h.id_number
  Left join e
    On e.catracks_id = h.id_number
  Left Join intr
    On intr.catracks_id = h.id_number
  Left Join linked
    On linked.id_number = h.id_number
  Left Join entity 
    On entity.id_number = h.id_number
  Left Join TMS_RACE 
    ON TMS_RACE.ethnic_code = entity.ethnic_code
  Left Join Reunion 
    On Reunion.id_number = h.id_number
  Left Join rpt_zrc8929.v_dean_salutation p
    On p.id_number = h.id_number
  Left Join KSM_Email 
  on KSM_Email.id_number = h.id_number
  Left Join KSM_Spec
  on KSM_Spec.id_number = h.id_number
  Left Join ksm_ids
  on ksm_ids.id_number = h.id_number
  Where h.record_status_code In ('A', 'C', 'L', 'D')
  and h.record_status_code != 'X' --- Remove Purgable
  --- Enrolled Students Only! 
  and a.id_number is not null 
  --- Take out No Contacts and Active with Restrictions
  and (KSM_Spec.NO_CONTACT is null
and KSM_Spec.ACTIVE_WITH_RESTRICTIONS is null)
)

Select Distinct 
  catracks_id
  , EMPLID
  , first_name
  , middle_name
  , last_name
  , P_Dean_Salut
  , p_pref_mail_name
  , gender_code
  , race
  , (substr (birth_dt, 1, 10)) as birth_dt
  , report_name
  , affil_code as affiliation_code
  , affilation as affiliation_desc
  , start_date as start_date
  , affilation_level
  , affilation_status
  , class_year as expected_graduation_year
  , INSTITUTIONAL_SUFFIX
  , degrees_concat
  , degrees_verbose
  , program
  , program_group
  , FIRST_KSM_YEAR
  , FIRST_MASTERS_YEAR
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
  , fld_of_work_desc as employment_industry
  , interests_concat as industry_interest_concat
  , primary_job_source
  , business_date_modified
  , employment_date_modified
  , email_type
  , email
From emp_chooser
;
  
--- View to Pull Primary Email and Phones Number with consideration of special handling codes

Create or Replace View v_datamart_contact as

With KSM_Email AS (select email.id_number,
       TMS_EMAIL_TYPE.short_desc,
       email.email_address
From email
Left join TMS_EMAIL_TYPE ON TMS_EMAIL_TYPE.email_type_code = email.email_type_code
Where email.preferred_ind = 'Y'),

--- Phone 
Phone as (Select t.id_number,
t.telephone_type_code,
TMS_TELEPHONE_TYPE.short_desc,
t.preferred_ind,
t.area_code,
t.telephone_number
from telephone t
left join TMS_TELEPHONE_TYPE on TMS_TELEPHONE_TYPE.telephone_type_code = t.telephone_type_code
where t.preferred_ind = 'Y'),

--- Special Handling Code

KSM_Spec AS (Select spec.ID_NUMBER,
       spec.NO_PHONE_IND,
       spec.NO_CONTACT,
       spec.NO_EMAIL_IND,
       spec.ACTIVE_WITH_RESTRICTIONS
From rpt_pbh634.v_entity_special_handling spec)

select d.ID_NUMBER,
--- Use Case Whens to exclude no emails/no phone special handling codes
--- Case when for Phone Type
Case When NO_PHONE_IND is null then p.short_desc 
  when KSM_Spec.NO_PHONE_IND is not null then 'No Phone' End as phone_type,
--- Case when for area code 
Case When NO_PHONE_IND is null then p.area_code 
  when KSM_Spec.NO_PHONE_IND is not null then 'No Phone' End as area_code,
--- Case when telephone number
Case  When NO_PHONE_IND is null then p.telephone_number 
  when KSM_Spec.NO_PHONE_IND is not null then 'No Phone' End as telephone_number,
--- Case when Email Type 
Case  When NO_Email_Ind is null then e.short_desc 
  when KSM_Spec.NO_Email_Ind is not null then 'No Email' End as email_type,
---- Case when email addresses
Case When KSM_Spec.NO_Email_Ind is null then e.email_address 
when KSM_Spec.NO_Email_Ind is not null then 'No Email' End as Email,
case when KSM_Spec.NO_PHONE_IND is not null then 'No Phone' Else '' End as NO_PHONE_IND,
case when KSM_Spec.NO_Email_Ind is not null then 'No Email' Else '' End as NO_EMAIL_IND
from rpt_pbh634.v_entity_ksm_degrees d
LEFT JOIN KSM_Email e ON e.ID_NUMBER = d.ID_NUMBER
LEFT JOIN phone p on p.id_number = d.id_number
Left Join KSM_Spec on KSM_Spec.id_number = d.id_number
Where (KSM_Spec.NO_CONTACT is null
and KSM_Spec.ACTIVE_WITH_RESTRICTIONS is null);
