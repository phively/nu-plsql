Create Or Replace View tableau_nametags As 

With

k As (
  Select
    constituent_donor_id
    , constituent_name
    , degree_school_name
    , degree_level
    , degree_year
    , degree_code
    , degree_name
    , degree_program
  From table(dw_pkg_base.tbl_degrees)
  -- Northwestern Related Degrees Only
  Where nu_indicator = 'Y'
    -- Let's remove students
    And degree_code Not Like '%STU%'
)

, e As (
  Select
    constituent_donor_id
    , constituent_name
    , Case When degree_school_name Like '%Kellogg%' Then 'Y' End
      As ksm_degree
    , degree_level
    , degree_year
    , degree_code
  From k
)

-- Clean Degrees
-- Assign MBA, certificate and non MBA
, degrees_clean As (
  Select
    constituent_donor_id
    , degree_year
    , degree_level
    , degree_code
    , ksm_degree
    , Case
      -- Honorary degrees
      When degree_code = 'Honorary'
        Then 'H'
      -- Undergrad degrees
      When degree_code = 'Undergraduate Degree'
        Then ''
      -- Certificate
      When ksm_degree = 'Y'
        And degree_code Like '%CERT%'
        Then 'cKSM'
      -- MBA and MMGT
      When degree_code In ('MBA','MMGT')
        Then 'MBA'
      --- Account for students
      When degree_code Like '%STU%'
        Then ''
      -- Account for unknown 
      When degree_code Like '%UNKN%'
        Then ''
      Else degree_code
      -- degree strings - will be the degree abbrivation.... honorary, undergrad, cert, mba
      End
    As degree_string
  From e
)


, degrees_group_by_year As (
  Select
    constituent_donor_id
    , degree_year
    , '''' || substr(degree_year, -2) -- Last two digits of Year on Nametag
      As year_abbr
    -- Listagg multiple years - Order by degree asc
    , Listagg(Distinct trim(degree_string), ', ') Within Group (Order By degree_year Asc)
      As degree_strings
    , Listagg(Distinct trim(degree_level), ', ') Within Group (Order By degree_year Asc)
      As degree_levels
  From degrees_clean dc
  Group By
    constituent_donor_id
    , degree_year
)

-- Final concat
, degrees_concat As (
  Select
    constituent_donor_id
  , Listagg(Distinct trim(year_abbr || ' ' || degree_strings), ', ')
    Within Group (Order By degree_year Asc, degree_strings Asc)
    As nu_degrees_string
  , Listagg(Distinct trim(year_abbr || ' ' || degree_levels), ', ')
    Within Group (Order By degree_year Asc, degree_strings Asc)
    As degree_levels
  From degrees_group_by_year
  Group By constituent_donor_id
)

Select Distinct
  k.constituent_donor_id
  , k.constituent_name
  , c.primary_constituent_type
  , c.salutation
  , c.first_name
  , c.middle_name
  , c.last_name
  , dean.p_dean_salut
  , dean.p_full_name
  , dean.p_dean_source
  , c.institutional_suffix
  , d.degrees_verbose
  , d.degrees_concat
  , d.first_ksm_year
  , d.first_masters_year
  , d.last_masters_year
  , d.program
  , d.program_group
  , d.class_section
  , dc.degree_levels
  , dc.nu_degrees_string
From k
Inner Join degrees_concat dc
  On dc.constituent_donor_id = k.constituent_donor_id
-- get first name, record type, suffix
Inner Join dm_alumni.dim_constituent c
  On c.constituent_donor_id = k.constituent_donor_id
-- Data Points from Paul's View
Left Join mv_entity_ksm_degrees d
  On d.donor_id = k.constituent_donor_id
-- Check Joint Degree Programs - Test Case 
Left Join v_entity_salutations dean
  On dean.donor_id = k.constituent_donor_id
;
