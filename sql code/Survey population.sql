With

pref_email As (
  Select
    id_number
    , trim(email_address) As email_address
    , 'Y' As pref_email
    , Case
        When lower(email_address) Not Like '%northwestern.edu%'
        Then 'Y'
        End
      As non_nu_pref_email
  From email
  Where email_status_code = 'A'
    And email.preferred_ind = 'Y'
)

-- Look up other FY24 survey recipients for exclusions

Select
  deg.id_number
  , deg.report_name
  , deg.record_status_code
  , deg.first_masters_year
  , deg.program_group
  , deg.program
  , entity.gender_code
  , sh.gab
  , sh.ebfa
  , sh.trustee
  , sh.no_email_ind
  , sh.no_survey_ind
  , sh.special_handling_concat
  , sh.mailing_list_concat
  , pref_email.pref_email
  , pref_email.non_nu_pref_email
From v_entity_ksm_degrees deg
Inner Join entity
  On entity.id_number = deg.id_number
Left Join pref_email
  On pref_email.id_number = deg.id_number
Left Join v_entity_special_handling sh
  On sh.id_number = deg.id_number
Where
  -- Active alumni only
  deg.record_status_code = 'A'
  -- MBA only, dropping PHD for 2024
  And deg.first_masters_year Is Not Null
  -- Exclude international alumni
  And program Not In ('EMP-ISR', 'EMP-CAN', 'EMP-HK', 'EMP-GER', 'EMP-CHI')
  
