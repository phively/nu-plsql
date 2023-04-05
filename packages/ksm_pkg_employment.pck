Create Or Replace Package ksm_pkg_employment Is

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_employment';

/*************************************************************************
Public type declarations
*************************************************************************/

-- KSM staff
Type ksm_staff Is Record (
  id_number entity.id_number%type
  , report_name entity.report_name%type
  , last_name entity.last_name%type
  , team varchar2(5)
  , former_staff varchar2(1)
  , job_title employment.job_title%type
  , employer employment.employer_unit%type
);

-- NU ARD current/past staff
Type nu_ard_staff Is Record (
  id_number employment.id_number%type
  , report_name entity.report_name%type
  , job_title employment.job_title%type
  , employer_unit employment.employer_unit%type
  , job_status_code employment.job_status_code%type
  , primary_emp_ind employment.primary_emp_ind%type
  , start_dt employment.start_dt%type
  , stop_dt employment.stop_dt%type
);

-- Employee record type for company queries
Type employee Is Record (
  id_number entity.id_number%type
  , report_name entity.report_name%type
  , record_status tms_record_status.short_desc%type
  , institutional_suffix entity.institutional_suffix%type
  , degrees_concat varchar2(512)
  , first_ksm_year degrees.degree_year%type
  , program varchar2(20)
  , business_title nu_prs_trp_prospect.business_title%type
  , business_company varchar2(1024)
  , job_title varchar2(1024)
  , employer_name varchar2(1024)
  , business_city nu_prs_trp_prospect.business_city%type
  , business_state nu_prs_trp_prospect.business_state%type
  , business_country tms_country.short_desc%type
  , prospect_manager nu_prs_trp_prospect.prospect_manager%type
  , team nu_prs_trp_prospect.team%type
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type t_ksm_staff Is Table Of ksm_staff;
Type t_nu_ard_staff Is Table Of nu_ard_staff;
Type t_employees Is Table Of employee;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

-- Return pipelined table of frontline KSM staff
Function tbl_frontline_ksm_staff
  Return t_ksm_staff Pipelined;

-- Return pipelined table of current and past NU ARD staff, with most recent NU job
Function tbl_nu_ard_staff
  Return t_nu_ard_staff Pipelined;

-- Return pipelined table of company employees with Kellogg degrees
--   N.B. uses matches pattern, user beware!
Function tbl_entity_employees_ksm (company In varchar2)
  Return t_employees Pipelined;

/*************************************************************************
Public cursors -- data definitions
*************************************************************************/

-- Definition of frontline gift officers
Cursor ct_frontline_ksm_staff Is
  With
  staff As (
    -- First query block pulls from past KSM staff materialized view
    Select
      id_number
      , team
      , Case When stop_dt Is Not Null Then 'Y' End As former_staff
    From mv_past_ksm_gos
  )
  -- Job title information
  , employ As (
    Select
      employment.id_number
      , job_title
      , employer_unit As employer
    From employment
    Inner Join staff On staff.id_number = employment.id_number
    Where job_status_code = 'C'
    And primary_emp_ind = 'Y'
  )
  -- Main query
  Select
    staff.id_number
    , entity.report_name
    , entity.last_name
    , staff.team
    , staff.former_staff
    , employ.job_title
    , employ.employer
  From staff
  Inner Join entity On entity.id_number = staff.id_number
  Left Join employ on employ.id_number = staff.id_number
  ;

-- Definition of historical NU ARD employees
Cursor c_nu_ard_staff Is
  With
  -- NU ARD employment
  nuemploy As (
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
    Or nuemploy.employer_unit Like '%ARD%'
    Or lower(nuemploy.employer_unit) Like '%campaign strategy%'
    Or lower(nuemploy.employer_unit) Like '%external relations%'
    Or lower(nuemploy.employer_unit) Like '%gifts%'
    -- Job title sounds like frontline staff
    Or lower(last_nuemploy.job_title) Like '%gifts%'
  ;

-- Definition of a Kellogg alum employed by a company
Cursor c_entity_employees_ksm (company In varchar2) Is
  With
  -- Employment table subquery
  employ As (
    Select
      id_number
      , job_title
      -- If there's an employer ID filled in, use the entity name
      , Case
          When employer_id_number Is Not Null And employer_id_number != ' ' Then (
            Select pref_mail_name
            From entity
            Where id_number = employer_id_number
          )
          -- Otherwise use the write-in field
          Else trim(employer_name1 || ' ' || employer_name2)
        End As employer_name
    From employment
    Where employment.primary_emp_ind = 'Y'
  )
  -- Record status tms table
  , tms_rec_status As (
    Select
      record_status_code
      , short_desc As record_status
    From tms_record_status
  )
  , tms_ctry As (
    Select
      country_code
      , short_desc As country
    From tms_country
  )
  -- Main query
  Select
    -- Entity fields
    deg.id_number
    , entity.report_name
    , tms_rec_status.record_status
    , entity.institutional_suffix
    , deg.degrees_concat
    , deg.first_ksm_year
    , trim(deg.program_group) As program
    -- Employment fields
    , prs.business_title
    , trim(prs.employer_name1 || ' ' || prs.employer_name2) As business_company
    , employ.job_title
    , employ.employer_name
    , prs.business_city
    , prs.business_state
    , tms_ctry.country As business_country
    -- Prospect fields
    , prs.prospect_manager
    , prs.team
  From table(tbl_entity_degrees_concat_ksm) deg -- KSM alumni definition
  Inner Join entity On deg.id_number = entity.id_number
  Inner Join tms_rec_status On tms_rec_status.record_status_code = entity.record_status_code
  Left Join employ On deg.id_number = employ.id_number
  Left Join nu_prs_trp_prospect prs On deg.id_number = prs.id_number
  Left Join tms_ctry On tms_ctry.country_code = prs.business_country
  Where
    -- Matches pattern; user beware (Apple vs. Snapple)
    lower(employ.employer_name) Like lower('%' || company || '%')
    Or lower(prs.employer_name1) Like lower('%' || company || '%')
  ;

End ksm_pkg_employment;
/

Create Or Replace Package Body ksm_pkg_employment Is

/*************************************************************************
Pipelined functions
*************************************************************************/

-- Pipelined function returning frontline KSM staff (per c_frontline_ksm_staff)
Function tbl_frontline_ksm_staff
  Return t_ksm_staff Pipelined As
  -- Declarations
  staff t_ksm_staff;
    
  Begin
    Open ct_frontline_ksm_staff;
      Fetch ct_frontline_ksm_staff Bulk Collect Into staff;
    Close ct_frontline_ksm_staff;
    For i in 1..(staff.count) Loop
      Pipe row(staff(i));
    End Loop;
    Return;
  End;

  -- Pipelined function returning current/historical NU ARD employees (per c_nu_ard_staff)
Function tbl_nu_ard_staff
  Return t_nu_ard_staff Pipelined As
  -- Declarations
  staff t_nu_ard_staff;
    
  Begin
    Open c_nu_ard_staff;
      Fetch c_nu_ard_staff Bulk Collect Into staff;
    Close c_nu_ard_staff;
    For i in 1..(staff.count) Loop
      Pipe row(staff(i));
    End Loop;
    Return;
  End;

-- Pipelined function returning Kellogg alumni (per c_entity_degrees_concat_ksm) who
-- work for the specified company
Function tbl_entity_employees_ksm (company In varchar2)
  Return t_employees Pipelined As
  -- Declarations
  employees t_employees;
  
  Begin
    Open c_entity_employees_ksm (company => company);
      Fetch c_entity_employees_ksm Bulk Collect Into employees;
    Close c_entity_employees_ksm;
    For i in 1..(employees.count) Loop
      Pipe row(employees(i));
    End Loop;
    Return;
  End;

End ksm_pkg_employment;
/
