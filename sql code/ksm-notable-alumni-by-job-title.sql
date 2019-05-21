-- Based on ksm-high-level-job-titles.sql

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
    , tms_fld.short_desc As fld_of_work
    , tms_spec1.short_desc As fld_of_spec1
    , tms_spec2.short_desc As fld_of_spec2
    , tms_spec3.short_desc As fld_of_spec3
  From employment
  Left Join tms_position_level tms_pl On tms_pl.position_level_code = employment.position_level_code
  Left Join tms_fld_of_work tms_fld On tms_fld.fld_of_work_code = employment.fld_of_work_code
  Left Join tms_fld_of_spec tms_spec1 On tms_spec1.fld_of_spec_code = employment.fld_of_spec_code1
  Left Join tms_fld_of_spec tms_spec2 On tms_spec2.fld_of_spec_code = employment.fld_of_spec_code2
  Left Join tms_fld_of_spec tms_spec3 On tms_spec3.fld_of_spec_code = employment.fld_of_spec_code3
  Where primary_emp_ind = 'Y'
  And job_status_code = 'C'
)

-- Main query
, fulldata As (
  Select
    prs.id_number
    , entity.report_name
    , deg.first_ksm_year
    , deg.program
    , deg.program_group
    , prs.prospect_manager
    , prs.business_title
    , trim(prs.employer_name1 || ' ' || prs.employer_name2) As business_name
    , prim_emp.job_title
    , prim_emp.employer_name
    , prs.pref_city
    , prs.pref_state
    , v_addr_continents.country As pref_country
    , prim_emp.matching_status_ind
    , prim_emp.position_level
    , prim_emp.fld_of_work
    , prim_emp.fld_of_spec1
    , prim_emp.fld_of_spec2
    , prim_emp.fld_of_spec3
    , Case
      -- C-suite
      When prs.business_title || prim_emp.job_title Like '%CAO%'
        Or prs.business_title || prim_emp.job_title Like '%C.A.O%'
        Or prs.business_title || prim_emp.job_title Like '%C A O%'
        Or lower(prs.business_title || prim_emp.job_title) Like '%chief_admin%'
        Then 'CAO'
      When prs.business_title || prim_emp.job_title Like '%CEO%'
        Or prs.business_title || prim_emp.job_title Like '%C.E.O%'
        Or prs.business_title || prim_emp.job_title Like '%C E O%'
        Or lower(prs.business_title || prim_emp.job_title) Like '%chief_exec%'
        Then 'CEO'
      When prs.business_title || prim_emp.job_title Like '%CFO%'
        Or prs.business_title || prim_emp.job_title Like '%C.F.O%'
        Or prs.business_title || prim_emp.job_title Like '%C F O%'
        Or lower(prs.business_title || prim_emp.job_title) Like '%chief_finan%'
        Then 'CFO'
      When prs.business_title || prim_emp.job_title Like '%CIO%'
        Or prs.business_title || prim_emp.job_title Like '%C.I.O%'
        Or prs.business_title || prim_emp.job_title Like '%C I O%'
        Or lower(prs.business_title || prim_emp.job_title) Like '%chief_info%'
        Then 'CIO'
      When prs.business_title || prim_emp.job_title Like '%CMO%'
        Or prs.business_title || prim_emp.job_title Like '%C.M.O%'
        Or prs.business_title || prim_emp.job_title Like '%C M O%'
        Or lower(prs.business_title || prim_emp.job_title) Like '%chief_market%'
        Or lower(prs.business_title || prim_emp.job_title) Like '%chief_medi%'
        Then 'CMO'
      When (prs.business_title || prim_emp.job_title Like '%COO%' And prs.business_title || prim_emp.job_title Not Like '%COORD%') -- Not coordinator
        Or prs.business_title || prim_emp.job_title Like '%C.O.O%'
        Or prs.business_title || prim_emp.job_title Like '%C O O%'
        Or lower(prs.business_title || prim_emp.job_title) Like '%chief_op%'
        Then 'COO'
      When (prs.business_title || prim_emp.job_title Like '%CTO%' And prs.business_title || prim_emp.job_title Not Like '%CTOR%') -- Not director, doctor
        Or prs.business_title || prim_emp.job_title Like '%C.T.O%'
        Or prs.business_title || prim_emp.job_title Like '%C T O%'
        Or lower(prs.business_title || prim_emp.job_title) Like '%chief_tech%'
        Then 'CTO'
      -- President, EVP
      When lower(prs.business_title || prim_emp.job_title) Like '%president%'
        And lower(prs.business_title || prim_emp.job_title) Not Like '%vice%' -- Not vice president
        Then 'President'
      When prs.business_title || prim_emp.job_title Like '%EVP%'
        Or lower(prs.business_title) Like '%exec%vice%pr%' Or lower(prim_emp.job_title) Like '%exec%vice%pr%'
        Or lower(prs.business_title) Like '%exec%vp%' Or lower(prim_emp.job_title) Like '%exec%vp%'
        Then 'EVP'
      -- Executive director
      When lower(prs.business_title) Like '%exec%dir%' Or lower(prim_emp.job_title) Like '%exec%dir%'
        Or lower(prs.business_title) Like '%manag%dir%' Or lower(prim_emp.job_title) Like '%manag%dir%'
        Then 'Mng/Exec Dir'
      -- Partner, principal, founder
      When lower(prs.business_title || prim_emp.job_title) Like '%partner%'
        Then 'Partner'
      When lower(prs.business_title || prim_emp.job_title) Like '%principal%'
        Then 'Principal'
      When lower(prs.business_title || prim_emp.job_title) Like '%founding%'
        Or lower(prs.business_title || prim_emp.job_title) Like '%founder%'
        Then 'Founder'
      -- Chairperson
      When lower(prs.business_title || prim_emp.job_title) Like '%chairman%'
        Or lower(prs.business_title || prim_emp.job_title) Like '%chairwoman%'
        Or lower(prs.business_title || prim_emp.job_title) Like '%chairperson%'
        Then 'Chairperson'
      -- U.S. politician
      When lower(prs.business_title || prim_emp.job_title) Like '%governor%'
        Then 'Governor'
      When lower(prs.business_title || prim_emp.job_title) Like '%senator%'
        Or lower(prs.business_title || prim_emp.job_title) Like '%senate%'
        Then 'Senator'
      When lower(prs.business_title || prim_emp.job_title) Like '%state%representat%'
        Or lower(prs.business_title || prim_emp.job_title) Like '%house%representat%'
        Then 'Representative'
      When lower(prs.business_title || prim_emp.job_title) Like '%mayor%'
        Then 'Mayor'
      End As high_level_job_title
  From nu_prs_trp_prospect prs
  Inner Join v_entity_ksm_degrees deg
    On deg.id_number = prs.id_number
  Inner Join entity
    On entity.id_number = prs.id_number
  Left Join prim_emp
    On prim_emp.id_number = prs.id_number
  Left Join v_addr_continents
    On v_addr_continents.country_code = prs.preferred_country
)

Select *
From fulldata
Where high_level_job_title Is Not Null
