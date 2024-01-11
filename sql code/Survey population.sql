With

pref_email As (
  Select
    id_number
    , trim(email_address) As email_address
    , 'Y' As pref_email
    , Case
        When email_address Not Like '%northwestern.edu%'
        Then 'Y'
        End
      As non_nu_pref_email
  From email
  Where email_status_code = 'A'
    And email.preferred_ind = 'Y'
)

, gab As (
  Select
    id_number
    , 'Y' As gab
  From table(ksm_pkg.tbl_committee_gab) gab
)

, gab_s As (
  Select
    entity.spouse_id_number As id_number
    , 'Y' As gab_spouse
  From table(ksm_pkg.tbl_committee_gab) gab
  Inner Join entity
    On entity.id_number = gab.id_number
  Where trim(entity.spouse_id_number) Is Not Null
)

, tr As (
  Select
    id_number
    , institutional_suffix
    , Case
        When institutional_suffix Like '%Trustee SP%'
          Then 'S'
        When institutional_suffix like '%Trustee%'
          Then 'Y'
        End
      As trustee
  From entity
  Where institutional_suffix Like '%Trust%'
)

Select
  deg.id_number
  , deg.report_name
  , deg.record_status_code
  , deg.first_masters_year
  , deg.program_group
  , deg.program
  , entity.gender_code
  , gab.gab
  , gab_s.gab_spouse
  , tr.trustee
  , sh.no_email_ind
  , sh.special_handling_concat
  , sh.mailing_list_concat
  , pref_email.pref_email
  , pref_email.non_nu_pref_email
From v_entity_ksm_degrees deg
Inner Join entity
  On entity.id_number = deg.id_number
Left Join pref_email
  On pref_email.id_number = deg.id_number
Left Join gab
  On gab.id_number = deg.id_number
Left Join gab_s
  On gab_s.id_number = deg.id_number
Left Join tr
  On tr.id_number = deg.id_number
Left Join v_entity_special_handling sh
  On sh.id_number = deg.id_number
Where
  -- Living alumni only
  deg.record_status_code = 'A'
  -- MBA or PhD
  And (
    -- PhD
    deg.program_group = 'PHD'
    -- MBA
    Or (
      deg.first_masters_year Is Not Null
      -- Exclude IEMBA
      And program Not In ('EMP-ISR', 'EMP-CAN', 'EMP-HK', 'EMP-GER', 'EMP-CHI')
    )
  )
  
