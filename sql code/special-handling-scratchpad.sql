With
-- Special handling entities
spec_hnd As (
  Select
    id_number
    , Listagg(
        ht.short_desc ||
        Case
          When ds.short_desc Is Not Null Then ' (' || ds.short_desc || ')'
          Else NULL
        End
        , '; '
      ) Within Group (Order By ht.short_desc Asc)
      As special_handling_concat
    , Listagg(h.hnd_type_code, '; ') Within Group (Order By ht.short_desc Asc)
      As spec_hnd_codes
    -- No contact
    , max(Case When h.hnd_type_code = 'NC' Then 'Y' End)
      As no_contact
    -- No solicit
    , max(Case When h.hnd_type_code = 'DNS' Then 'Y' End)
      As no_solicit
    -- No release
    , max(Case When h.hnd_type_code = 'DNR' Then 'Y' End)
      As no_release
    -- Has opt-outs
    , max(Case When h.hnd_type_code = 'OOO' Or h.hnd_type_code = 'OIO' Then 'Y' End)
      As has_opt_ins_opt_outs
    -- No phone
    , max(Case When h.hnd_type_code = 'DNP' Then 'Y' End)
      As no_phone
    -- No phone solicitation
    , max(Case When h.hnd_type_code = 'NPS' Then 'Y' End)
      As no_phone_solicit
    -- No email
    , max(Case When h.hnd_type_code = 'NE' Then 'Y' End)
      As no_email
    -- No email solicitation
    , max(Case When h.hnd_type_code = 'NES' Then 'Y' End)
      As no_email_solicit
    -- No postal mail
    , max(Case When h.hnd_type_code = 'NM' Then 'Y' End)
      As no_mail
    -- No postal solicitation
    , max(Case When h.hnd_type_code = 'NMS' Then 'Y' End)
      As no_mail_solicit
    -- No texts
    , max(Case When h.hnd_type_code = 'NTX' Then 'Y' End)
      As no_texts
    -- No text solicitation
    , max(Case When h.hnd_type_code = 'NTS' Then 'Y' End)
      As no_texts_solicit
  From handling h
  Inner Join tms_handling_type ht On ht.handling_type = h.hnd_type_code
  Left Join tms_data_source ds On ds.data_source_code = h.data_source_code
  Where h.hnd_status_code = 'A'
    And h.hnd_type_code Not In ( -- Interest codes list
      'CPG'
      , 'ENT'
      , 'FB'
      , 'FW'
      , 'HF'
      , 'MAR'
      , 'MCE'
      , 'MFU'
      , 'MLC'
      , 'NYF'
      , 'NYW'
      , 'PER'
      , 'SPC'
      , 'SRC'
      , 'TEC'
      , 'TF'
      , 'VC'
    )
  Group By id_number
)
-- Mailing list entities
, mailing_lists As (
  Select
    id_number
    , Listagg(
        trim(
          mlc.short_desc || Case When uc.unit_code <> ' ' Then ' ' End || trim(uc.unit_code)
          || Case When c.short_desc Is Not Null Then ' (' || c.short_desc || ')' End
        )
        , '; '
      ) Within Group (Order By mlc.short_desc Asc)
      As mailing_list_concat
    , Listagg(
        trim(
          ml.mail_list_code || Case When ml.unit_code <> ' ' Then ' ' End || trim(ml.unit_code)
          || ' ' || ml.mail_list_ctrl_code
        )
        , '; '
      ) Within Group (Order By mlc.short_desc Asc)
      As ml_codes
    -- All communication
    , max(Case When ml.mail_list_code = 'AC' And ml.mail_list_ctrl_code = 'EXC' Then 'Y' End)
      As exc_all_comm
    -- All solicitation
    , max(Case When ml.mail_list_code = 'AS' And ml.mail_list_ctrl_code = 'EXC' Then 'Y' End)
      As exc_all_sols
    -- Phonathon communication
    , max(Case When ml.mail_list_code = 'PC' And ml.mail_list_ctrl_code = 'EXC' Then 'Y' End)
      As exc_phone_comm
    -- Phonathon solicitation
    , max(Case When ml.mail_list_code = 'PS' And ml.mail_list_ctrl_code = 'EXC' Then 'Y' End)
      As exc_phone_sols
    -- Email communication
    , max(Case When ml.mail_list_code = 'EC' And ml.mail_list_ctrl_code = 'EXC' Then 'Y' End)
      As exc_email_comm
    -- Email solicitation
    , max(Case When ml.mail_list_code = 'ES' And ml.mail_list_ctrl_code = 'EXC' Then 'Y' End)
      As exc_email_sols
    -- Mail communication
    , max(Case When ml.mail_list_code = 'MC' And ml.mail_list_ctrl_code = 'EXC' Then 'Y' End)
      As exc_mail_comm
    -- Mail solicitation
    , max(Case When ml.mail_list_code = 'MS' And ml.mail_list_ctrl_code = 'EXC' Then 'Y' End)
      As exc_mail_sols
  From mailing_list ml
  Inner Join tms_mail_list_code mlc On ml.mail_list_code = mlc.mail_list_code_code
  Left Join tms_unit_code uc On ml.unit_code = uc.unit_code
  Left Join tms_mail_list_ctrl c On ml.mail_list_ctrl_code = c.mail_list_ctrl_code
  Where ml.mail_list_status_code = 'A'
     And (
       -- Must be a KSM mailing list, or blank with one of the exclusion preferences
       ml.unit_code = 'KM'
       Or (
        ml.unit_code = ' '
        And ml.mail_list_code In ('AC', 'AS', 'PC', 'PS', 'EC', 'ES', 'MC', 'MS')
       )
     )
  Group By id_number
)
-- All IDs
, ids As (
  Select id_number
  From spec_hnd
  Union
  Select id_number
  From mailing_lists
)
-- Main query
Select
  ids.id_number
  , spec_hnd.special_handling_concat
  , spec_hnd.spec_hnd_codes
  , mailing_lists.mailing_list_concat
  , mailing_lists.ml_codes
  -- Overall special handling indicators
  , spec_hnd.no_contact
  , spec_hnd.no_solicit
  , spec_hnd.no_release
  , spec_hnd.has_opt_ins_opt_outs
  -- No phone combined
  , Case
      When no_contact = 'Y' Or no_phone = 'Y' Then 'Y'
    End As no_phone_ind
  -- No phone solicit combined
  , Case
      When no_contact = 'Y' Or no_phone = 'Y' Then 'Y'
      When no_solicit = 'Y' Or no_phone_solicit = 'Y' Then 'Y'
    End As no_phone_sol_ind
  -- No email combined
  , Case
      When no_contact = 'Y' Or no_email = 'Y' Then 'Y'
      When exc_all_comm = 'Y' Or exc_email_comm = 'Y' Then 'Y'
    End As no_email_ind
  -- No email solicit combined
  , Case
      When no_contact = 'Y' Or no_email = 'Y' Then 'Y'
      When no_solicit = 'Y' Or no_email_solicit = 'Y' Then 'Y'
      When exc_all_comm = 'Y' Or exc_email_comm = 'Y' Then 'Y'
      When exc_all_sols = 'Y' Or exc_email_sols = 'Y' Then 'Y'
    End As no_email_sol_ind
  -- No mail combined
  , Case
      When no_contact = 'Y' Or no_mail = 'Y' Then 'Y'
      When exc_all_comm = 'Y' Or exc_mail_comm = 'Y' Then 'Y'
    End As no_mail_ind
  -- No mail solicit combined
  , Case
      When no_contact = 'Y' Or no_mail = 'Y' Then 'Y'
      When no_solicit = 'Y' Or no_mail_solicit = 'Y' Then 'Y'
      When exc_all_comm = 'Y' Or exc_mail_comm = 'Y' Then 'Y'
      When exc_all_sols = 'Y' Or exc_mail_sols = 'Y' Then 'Y'
    End As no_mail_sol_ind
  -- No texts combined
  , Case
      When no_contact = 'Y' Or no_texts = 'Y' Then 'Y'
      When exc_all_comm = 'Y' Then 'Y'
    End As no_texts_ind
  -- No texts solicit combined
  , Case
      When no_contact = 'Y' Or no_texts = 'Y' Then 'Y'
      When no_solicit = 'Y' Or no_texts_solicit = 'Y' Then 'Y'
      When exc_all_comm = 'Y' Then 'Y'
      When exc_all_sols = 'Y' Then 'Y'
    End As no_texts_sol_ind
From ids
Left Join spec_hnd On spec_hnd.id_number = ids.id_number
Left Join mailing_lists On mailing_lists.id_number = ids.id_number
-- KSM alumni only (to query faster)
Inner Join v_entity_ksm_degrees v On v.id_number = ids.id_number
