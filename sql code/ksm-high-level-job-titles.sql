With

-- Primary employment
prim_emp As (
  Select
    id_number
    , job_title
    , trim(employer_name1 || ' ' || employer_name2) As employer_name
    , self_employ_ind
    , matching_status_ind
    , tms_pl.short_desc As position_level
  From employment
  Left Join tms_position_level tms_pl On tms_pl.position_level_code = employment.position_level_code
  Where primary_emp_ind = 'Y'
  And job_status_code = 'C'
)

-- Main query
Select
  prs.id_number
  , prs.business_title
  , trim(prs.employer_name1 || ' ' || prs.employer_name2) As business_name
  , prim_emp.job_title
  , prim_emp.employer_name
  , prim_emp.matching_status_ind
  , prim_emp.position_level
  , Case -- High-level job title indicator
    When prs.business_title || prim_emp.job_title Like '%CAO%'
      Or prs.business_title || prim_emp.job_title Like '%C_A_O%'
      Or lower(prs.business_title || prim_emp.job_title) Like '%chief_admin%'
      Then 'CAO'
    When prs.business_title || prim_emp.job_title Like '%CEO%'
      Or prs.business_title || prim_emp.job_title Like '%C_E_O%'
      Or lower(prs.business_title || prim_emp.job_title) Like '%chief_exec%'
      Then 'CEO'
    When prs.business_title || prim_emp.job_title Like '%CFO%'
      Or prs.business_title || prim_emp.job_title Like '%C_F_O%'
      Or lower(prs.business_title || prim_emp.job_title) Like '%chief_finan%'
      Then 'CFO'
    When prs.business_title || prim_emp.job_title Like '%CIO%'
      Or prs.business_title || prim_emp.job_title Like '%C_I_O%'
      Or lower(prs.business_title || prim_emp.job_title) Like '%chief_info%'
      Then 'CIO'
    When prs.business_title || prim_emp.job_title Like '%CMO%'
      Or prs.business_title || prim_emp.job_title Like '%C_M_O%'
      Or lower(prs.business_title || prim_emp.job_title) Like '%chief_market%'
      Or lower(prs.business_title || prim_emp.job_title) Like '%chief_medi%'
      Then 'CMO'
    When (prs.business_title || prim_emp.job_title Like '%COO%' And prs.business_title || prim_emp.job_title Not Like '%COORD%') -- Not coordinator
      Or prs.business_title || prim_emp.job_title Like '%C_O_O%'
      Or lower(prs.business_title || prim_emp.job_title) Like '%chief_op%'
      Then 'COO'
    When (prs.business_title || prim_emp.job_title Like '%CTO%' And prs.business_title || prim_emp.job_title Not Like '%CTOR%') -- Not director, doctor
      Or prs.business_title || prim_emp.job_title Like '%C_T_O%'
      Or lower(prs.business_title || prim_emp.job_title) Like '%chief_tech%'
      Then 'CTO'
    When lower(prs.business_title || prim_emp.job_title) Like '%president%'
      And lower(prs.business_title || prim_emp.job_title) Not Like '%vice%' -- Not vice president
      Then 'President'
    When prs.business_title || prim_emp.job_title Like '%EVP%'
      Or lower(prs.business_title) Like '%exec%vice%' Or lower(prim_emp.job_title) Like '%exec%vice%'
      Or lower(prs.business_title) Like '%exec%vp%' Or lower(prim_emp.job_title) Like '%exec%vp%'
      Then 'EVP'
    When lower(prs.business_title) Like '%exec%dir%' Or lower(prim_emp.job_title) Like '%exec%dir%'
      Or lower(prs.business_title) Like '%manag%dir%' Or lower(prim_emp.job_title) Like '%manag%dir%'
      Then 'Mng/Exec Dir'
    When lower(prs.business_title || prim_emp.job_title) Like '%partner%'
      Then 'Partner'
    When lower(prs.business_title || prim_emp.job_title) Like '%principal%'
      Then 'Principal'
    When lower(prs.business_title || prim_emp.job_title) Like '%chairman%'
      Or lower(prs.business_title || prim_emp.job_title) Like '%chairwoman%'
      Or lower(prs.business_title || prim_emp.job_title) Like '%chairperson%'
      Then 'Chairperson'
    End As high_level_job_title
From nu_prs_trp_prospect prs
Inner Join v_entity_ksm_degrees v On v.id_number = prs.id_number
Left Join prim_emp On prim_emp.id_number = prs.id_number
