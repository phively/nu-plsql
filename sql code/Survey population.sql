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

, salutation As (
  Select
    sal.id_number
    , sal.p_dean_salut
    , sal.joint_dean_salut
  From rpt_zrc8929.v_dean_salutation sal
)

-- Look up other FY24 survey recipients for exclusions
, imcpanel As (
  Select id_number
  From tbl_imc_survey_panel_2023
)

, boardfellows As (
  Select
    id_number
    , segment
  From tbl_board_fellows_survey_2024
)

Select
  deg.id_number
  -- Dean salutation if available, else first name
  , Case
      When trim(sal.p_dean_salut) Is Not Null 
        Then trim(sal.p_dean_salut)
      Else trim(entity.first_name)
      End
    As first_name_for_qualtrics
  , entity.report_name
  , sal.p_dean_salut
  , entity.first_name
  , entity.middle_name
  , entity.last_name
  , deg.record_status_code
  , deg.first_masters_year
  , trunc(deg.first_masters_year/10) * 10
    As masters_decade
  , deg.program_group
  , deg.program
  , entity.gender_code
  , Case
      When sh.gab Is Not Null
        Or sh.ebfa Is Not Null
        Or sh.trustee Is Not Null
        Or sh.no_contact Is Not Null
        Or sh.no_email_ind Is Not Null
        Or sh.no_survey_ind Is Not Null
        Or imcpanel.id_number Is Not Null
        Or boardfellows.id_number Is Not Null
        Then 'Y'
      End
    As any_exclusion
  , sh.gab
  , sh.ebfa
  , sh.trustee
  , sh.no_email_ind
  , sh.no_survey_ind
  , Case When imcpanel.id_number Is Not Null Then 'Y' End
    As imc_panel_survey
  , boardfellows.segment
    As board_fellows_survey_segment
  , sh.special_handling_concat
  , sh.mailing_list_concat
  , pref_email.email_address
  , pref_email.pref_email
  , pref_email.non_nu_pref_email
From v_entity_ksm_degrees deg
Inner Join entity
  On entity.id_number = deg.id_number
Left Join pref_email
  On pref_email.id_number = deg.id_number
Left Join v_entity_special_handling sh
  On sh.id_number = deg.id_number
Left Join imcpanel
  On imcpanel.id_number = deg.id_number
Left Join boardfellows
  On boardfellows.id_number = deg.id_number
Left Join salutation sal
  On sal.id_number = deg.id_number
Where
  -- Active alumni only
  deg.record_status_code = 'A'
  -- MBA only, dropping PHD for 2024
  And deg.first_masters_year Is Not Null
  And deg.program_group In ('FT', 'TMP', 'EMP')
  -- Exclude international alumni
  And deg.program Not In ('EMP-ISR', 'EMP-CAN', 'EMP-HK', 'EMP-GER', 'EMP-CHI')
  
