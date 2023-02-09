Create Or Replace View v_entity_nametags As

With

dean_sals As (
  -- Pull all first name salutations from the dean salutations view
  Select
    vds.id_number
    , vds.p_pref_mail_name
    , vds.p_dean_salut
    , vds.p_dean_source
    , vds.spouse_id_number
    , vds.spouse_pref_name
    , vds.spouse_dean_salut
    , vds.spouse_dean_source
    , vds.joint_dean_salut
  From rpt_zrc8929.v_dean_salutation vds
)

, degrees_data As (
  -- Pull all completed Northwestern degrees
  Select
    id_number
    , degree_type
    , school_code
    , degree_year
    , degree_code
    , degree_level_code
    , dept_code
    , division_code
    , honorary_alumnus_ind
    , Case
        When school_code = 'KSM'
          Or school_code = 'BUS'
          Then 'Y'
        End
        As ksm_degree
    , Case
        When dept_code = '01MDB' -- MD/MBA
          Then 'MDMBA'
        When dept_code = '13JDM' -- JD/MBA
          Then 'JDMBA'
        When division_code = 'MMM' -- MMM
          Then 'MMM'
        End
      As joint_program
  From degrees
  Where institution_code = '31173' -- Northwestern University
    And trim(degree_year) Is Not Null -- Exclude rows with blank year
    And non_grad_code <> 'N' -- Exclude nongrads
)

, degrees_clean As (
  -- Parse degree year abbreviations and designation strings
  Select
    id_number
    , degree_type
    , Case
        When degree_type = 'U'
          Then 'Y'
        Else 'N'
        End
      As undergrad_flag
    , school_code
    , degree_year
    , degree_code
    , honorary_alumnus_ind
    , joint_program
    , ksm_degree
    -- Logic for single degree
    -- H for honorary, NULL for undergrad, cKSM for Kellogg certificates,
    -- CERT for NU certificates, MBA for MBA and MMGT (KSM),
    -- else degree abbreviation: NULL for 'UNKN'
    , Case
        When honorary_alumnus_ind = 'Y' -- Honorary degree types
          Then 'H'
        When degree_type = 'U' -- Undergrad degree types
          Then ''
        When ksm_degree = 'Y' -- Kellogg certificates
          And (
            degree_code = 'CERT'
            Or degree_level_code = 'C'
          )
          Then 'cKSM'
        When degree_code = 'CERT' -- Non-Kellogg certificates
          Or degree_level_code = 'C'
          Then 'CERT'
        When degree_code = 'UNKN' -- Replace UNKN with blank
          Then ''
        When degree_code In ('MBA', 'MMGT') -- Older MMGT designated as MBA
          Then 'MBA'
        Else degree_code
        End
    As degree_string
  From degrees_data
)

, degrees_group_by_year As (
  -- Group undergraduate year strings, and graduate year strings, in the same year together
  -- Degree strings in same year ordered alphabetically
  Select
    id_number
    , degree_year
    , undergrad_flag
    , '''' || substr(degree_year, -2) -- 'YY class year: rightmost 2 digits
      As year_abbr
    , Listagg(trim(degree_string), ', ') Within Group (Order By degree_string Asc)
      As degree_strings
  From degrees_clean
  Group By
    id_number
    , degree_year
    , undergrad_flag
)

, degrees_concat As (
  -- Group all degrees by id_number, ordered by year, then undergrad, then degree_strings
  Select
    id_number
    , Listagg(
        trim(year_abbr || ' ' || degree_strings)
        , ', '
      ) Within Group (Order By degree_year Asc, degree_strings Asc)
    As nu_degrees_string
  From degrees_group_by_year
  Group By
    id_number
)

, children_degs As (
  Select
    children.id_number
    , children.child_id_number
    , degrees_clean.degree_year
    , '''' || substr(degrees_clean.degree_year, -2) -- 'YY class year: rightmost 2 digits
      As year_abbr
  From children
  Inner Join degrees_clean -- Intentionally inner join; ignore non-alumni children
    On degrees_clean.id_number = children.child_id_number
  Where children.child_relation_code In ('CP', 'SP') -- child/parent, stepchild/parent
    And trim(children.child_id_number) Is Not Null
)

, children_deg As (
  Select
    cd.id_number
    , cd.child_id_number
    , min(cd.year_abbr) keep(dense_rank First Order By cd.degree_year Asc)
      As child_first_degree_yr_abbr
    , min(cd.degree_year) keep(dense_rank First Order By cd.degree_year Asc)
      As child_first_degree_yr
    , Listagg(cd.year_abbr, ', ') Within Group (Order By cd.degree_year Asc)
      As child_degrees
  From children_degs cd
  Group By cd.id_number
    , cd.child_id_number
)

, children_deg_concat As (
  Select
    cd.id_number
    , count(Distinct cd.child_id_number)
      As children_with_nu_deg
    , Listagg(child_first_degree_yr, ', ') Within Group (Order By child_first_degree_yr Asc)
      As children_first_degs_abbr
    , Listagg(child_first_degree_yr_abbr, ', ') Within Group (Order By child_first_degree_yr Asc)
      As children_first_degs_concat
  From children_deg cd
  Group By cd.id_number
)

Select
  entity.id_number
  , entity.pref_mail_name
  , entity.record_status_code
  , entity.institutional_suffix
  , deg.degrees_concat
  , cdc.children_with_nu_deg
  , cdc.children_first_degs_concat
  , dean_sals.p_dean_source As pref_first_name_source
  , Case
      When p_dean_salut Is Not Null
        Then p_dean_salut
      Else entity.first_name
      End
    As pref_first_name
  , entity.first_name
  , entity.middle_name
  , entity.last_name As last_name
  , entity.pers_suffix
  , degrees_concat.nu_degrees_string
From entity
Inner Join dean_sals
  On dean_sals.id_number = entity.id_number
Left Join degrees_concat
  On degrees_concat.id_number = entity.id_number
Left Join rpt_pbh634.v_entity_ksm_degrees deg
  On deg.id_number = entity.id_number
Left Join children_deg_concat cdc
  On cdc.id_number = entity.id_number
Where entity.person_or_org = 'P'
  And entity.record_status_code Not In ('X', 'I')
;

/*
-- Test cases
Select *
From v_entity_nametags
Where id_number In (
'0000040296' -- '52 CERT
, '0000342515' -- '73, '77 MBA
, '0000308975' -- '91 MBA
, '0000299349' -- DSB
)
*/
