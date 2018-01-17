With

/* NU ARD historical faculty and staff */

-- Faculty/staff affiliations
-- NOT currently used
nu_fs As (
  Select
    affil.id_number
    , entity.report_name
    , affil_code
    , affil_primary_ind
    , tms_al.short_desc As affil_level
    , affil_status_code
    , trunc(affil.start_date) As start_date
    , trunc(affil.stop_date) As stop_date
    , trunc(affil.date_added)  As date_added
    , trunc(affil.date_modified) As date_modified
  From affiliation affil
  Inner Join tms_affiliation_level tms_al On tms_al.affil_level_code = affil.affil_level_code
  Inner Join entity On entity.id_number = affil.id_number
  Where affil.affil_level_code In ('ES', 'EF', 'EE') -- Staff, Faculty, Employee
)

-- NU ARD employment
, nuemploy As (
  Select
    employment.id_number
    , entity.report_name
    , xsequence
    , row_number() Over(Partition By employment.id_number Order By primary_emp_ind Desc, job_status_code Asc, xsequence Desc) As nbr
    , job_status_code
    , primary_emp_ind
    , job_title
    , employer_id_number
    , employer_unit
    , trunc(employment.start_dt) As start_dt
    , trunc(employment.stop_dt) As stop_dt
    , trunc(employment.date_added) As date_added
    , trunc(employment.date_modified) As date_modified
  From employment
  Inner Join entity On entity.id_number = employment.id_number
  Where employer_id_number = '0000439808' -- Northwestern University
    And employ_relat_code Not In ('ZZ', 'MA') -- Exclude historical and matching gift employers
)
-- Last NU job
, last_nuemploy As (
  Select
    id_number
    , report_name
    , job_title
    , employer_unit
    , job_status_code
    , primary_emp_ind
    , start_dt
    , stop_dt
    , date_added
    , date_modified
  From nuemploy
  Where nbr = 1
)

-- Main query
Select Distinct
  nuemploy.id_number
  , nuemploy.report_name
  , last_nuemploy.job_title
  , last_nuemploy.employer_unit
  , last_nuemploy.job_status_code
  , last_nuemploy.primary_emp_ind
  , last_nuemploy.start_dt
  , last_nuemploy.stop_dt
From nuemploy
Inner Join last_nuemploy On last_nuemploy.id_number = nuemploy.id_number
Where 
  nuemploy.id_number In ('0000768730', '0000299349') -- HG, SB
  -- Ever worked for University-wide ARD
  Or lower(nuemploy.employer_unit) Like '%alumni%'
  Or lower(nuemploy.employer_unit) Like '%development%'
  Or lower(nuemploy.employer_unit) Like '%advancement%'
  Or lower(nuemploy.employer_unit) Like '%campaign strategy%'
  Or lower(nuemploy.employer_unit) Like '%external relations%'
