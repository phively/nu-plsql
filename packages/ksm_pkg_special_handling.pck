Create Or Replace Package ksm_pkg_special_handling Is

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_special_handling';

/*************************************************************************
Public type declarations
*************************************************************************/

Type special_handling Is Record (
     id_number entity.id_number%type
     , spouse_id_number entity.spouse_id_number%type
     , special_handling_concat varchar2(1024)
     , spec_hnd_codes varchar2(1024)
     , mailing_list_concat varchar2(1024)
     , ml_codes varchar2(1024)
     , record_status_code entity.record_status_code%type
     , gab varchar2(16)
     , trustee varchar2(16)
     , ebfa varchar2(16)
     , no_contact varchar2(1)
     , no_solicit varchar2(1)
     , no_release varchar2(1)
     , active_with_restrictions varchar2(1)
     , never_engaged_forever varchar2(1)
     , never_engaged_reunion varchar2(1)
     , has_opt_ins_opt_outs varchar2(1)
     , anonymous_donor varchar2(1)
     , exc_all_comm varchar2(1)
     , exc_all_sols varchar2(1)
     , exc_surveys varchar2(1)
     , last_survey_dt date
     , no_af_sol_ind varchar2(1)
     , no_survey_ind varchar2(1)
     , no_phone_ind varchar2(1)
     , no_phone_sol_ind varchar2(1)
     , no_email_ind varchar2(1)
     , no_email_sol_ind varchar2(1)
     , no_mail_ind varchar2(1)
     , no_mail_sol_ind varchar2(1)
     , no_texts_ind varchar2(1)
     , no_texts_sol_ind varchar2(1)
     , ksm_stewardship_issue varchar2(1)
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type t_special_handling Is Table Of special_handling;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

-- Return pipelined special handling preferences
Function tbl_special_handling_concat
    Return t_special_handling Pipelined;

/*************************************************************************
Public cursors -- data definitions
*************************************************************************/

/* Special handling concatenated definition */
Cursor c_special_handling_concat Is
  With
  -- Special handling entities
  spec_hnd As (
    Select
      h.id_number
      , e.spouse_id_number
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
      -- Active with restrictions
      , max(Case When h.hnd_type_code = 'AWR' Then 'Y' End)
        As active_with_restrictions
      -- Never engaged forever
      , max(Case When h.hnd_type_code = 'NED' Then 'Y' End)
        As never_engaged_forever
      -- Never engaged reunion
      , max(Case When h.hnd_type_code = 'NDR' Then 'Y' End)
        As never_engaged_reunion
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
      -- Anonymous donor
      , max(Case When h.hnd_type_code = 'AN' Then 'Y' End)
        As anonymous_donor
    From handling h
    Inner Join entity e On e.id_number = h.id_number
    Inner Join tms_handling_type ht On ht.handling_type = h.hnd_type_code
    Left Join tms_data_source ds On ds.data_source_code = h.data_source_code
    Where h.hnd_status_code = 'A'
      And h.hnd_type_code Not In ( -- Interest codes list
        'CPG', 'ENT', 'FB', 'FW', 'HF', 'MAR', 'MCE', 'MFU', 'MLC'
        , 'NYF', 'NYW', 'PER', 'SPC', 'SRC', 'TEC', 'TF', 'VC'
      )
    Group By
      h.id_number
      , e.spouse_id_number
  )
  -- Survey appeals
  , surveys As (
    Select
      ah.appeal_group
      , ah.appeal_code
      , ah.description
      , a.id_number
      , a.appeal_month
      , a.appeal_year
      , ksm_pkg_utility.to_date2(a.appeal_year || a.appeal_month || '01', 'yyyymmdd')
        As appeal_date
    From appeals a
    Inner Join appeal_header ah
      On ah.appeal_code = a.appeal_code
      And ah.appeal_group = 'SY' -- Survey
  )
  , last_survey As (
    Select
      id_number
      , count(appeal_date)
        As past_surveys
      , max(appeal_date)
        As last_survey_dt
      , Case
          When add_months(max(appeal_date), 4) >= max(cal.today)
            Then 'Y'
          End
        As surveyed_last_4_months
    From surveys
    Cross Join table(ksm_pkg_calendar.tbl_current_calendar) cal
    Where appeal_date <= cal.today
    Group By id_number
  )
  -- Mailing list entities
  , mailing_lists As (
    Select
      ml.id_number
      , e.spouse_id_number
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
      -- AF solicitation
      , max(Case When ml.mail_list_code = 'NAF' And ml.mail_list_ctrl_code = 'EXC' Then 'Y' End)
        As no_af_solicit
      -- Surveys
      , max(Case When ml.mail_list_code = 'SURV' And ml.mail_list_ctrl_code = 'EXC' Then 'Y' End)
        As exc_surveys
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
    Inner Join entity e On e.id_number = ml.id_number
    Inner Join tms_mail_list_code mlc On ml.mail_list_code = mlc.mail_list_code_code
    Left Join tms_unit_code uc On ml.unit_code = uc.unit_code
    Left Join tms_mail_list_ctrl c On ml.mail_list_ctrl_code = c.mail_list_ctrl_code
    Where ml.mail_list_status_code = 'A'
       And (
         -- Must be a KSM mailing list, or blank with one of the exclusion preferences
         ml.unit_code = 'KM'
         Or (
          ml.unit_code = ' '
          And ml.mail_list_code In ('AC', 'AS', 'PC', 'PS', 'EC', 'ES', 'MC', 'MS', 'SURV')
         )
       )
    Group By
      ml.id_number
      , e.spouse_id_number
  )
  -- Alerts
  , all_alerts As (
    Select
      id_number
      , start_date
      , stop_date
      , message
      -- Kellogg Stewardship Issue indicator
      , Case
          When lower(message) Like '%ksm%stewardship%issue%'
            Or lower(message) Like '%kellogg%stewardship%issue%'
            Then 'Y'
          End
        As ksm_stewardship_issue
    From zz_alert_message
  )
  , alerts As (
    Select
      all_alerts.id_number
      , e.spouse_id_number
      , start_date
      , stop_date
      , message As alert_message
      , ksm_stewardship_issue
    From all_alerts
    Inner Join entity e
      On e.id_number = all_alerts.id_number
    Where
      ksm_stewardship_issue = 'Y'
      -- Or other indicators, if ever added
  )
  -- Committees
  , gab As (
    Select
      gab.id_number
      , e.spouse_id_number
      , 'Y' As flag
    From table(ksm_pkg_committee.tbl_committee_members(
      ksm_pkg_committee.get_string_constant('committee_gab')
    )) gab
    Inner Join entity e
      On e.id_number = gab.id_number
  )
  , trustee As (
    Select
      tr.id_number
      , e.spouse_id_number
      , 'Y' As flag
    From table(ksm_pkg_committee.tbl_committee_members(
      ksm_pkg_committee.get_string_constant('committee_trustee')
    )) tr
    Inner Join entity e
      On e.id_number = tr.id_number
  )
  , ebfa As (
    Select
      ebfa.id_number
      , e.spouse_id_number
      , 'Y' As flag
    From table(ksm_pkg_committee.tbl_committee_members(
      ksm_pkg_committee.get_string_constant('committee_asia')
    )) ebfa
    Inner Join entity e
      On e.id_number = ebfa.id_number
  )
  , committees_merged As (
    Select id_number, spouse_id_number
    From gab
    Union
    Select id_number, spouse_id_number
    From trustee
    Union
    Select id_number, spouse_id_number
    From ebfa
  )
  -- All IDs
  , ids As (
    Select id_number, spouse_id_number
    From spec_hnd
    Union
    Select id_number, spouse_id_number
    From mailing_lists
    Union
    Select id_number, spouse_id_number
    From alerts
    Union
    Select id_number, spouse_id_number
    From committees_merged
  )
  -- Universal no contact or no solicit
  -- Anyone with one of a few select codes should NEVER be contacted or solicited
  , unc_ids As (
    Select
      ids.id_number
      , ids.spouse_id_number
      , Case
          When no_contact = 'Y'
            Or exc_all_comm = 'Y'
            Or active_with_restrictions = 'Y'
            Then 'Y'
          End
        As univ_no_contact
      , Case
          When no_contact = 'Y'
            Or exc_all_comm = 'Y'
            Or active_with_restrictions = 'Y'
            Or no_solicit = 'Y'
            Or exc_all_sols = 'Y'
            Then 'Y'
          End
        As univ_no_solicit
    From ids
    Left Join spec_hnd On spec_hnd.id_number = ids.id_number
    Left Join mailing_lists On mailing_lists.id_number = ids.id_number
  )
  -- Main query
  Select
    ids.id_number
    , trim(ids.spouse_id_number) As spouse_id_number
    , spec_hnd.special_handling_concat
    , spec_hnd.spec_hnd_codes
    , mailing_lists.mailing_list_concat
    , mailing_lists.ml_codes
    -- Entity flags
    , entity.record_status_code
    , Case
        When gab.flag = 'Y'
          Then 'GAB'
        When gab_s.flag = 'Y'
          Then 'GAB Spouse'
      End As gab
    , Case
        When trustee.flag = 'Y'
          Then 'Trustee'
        When trustee_s.flag = 'Y'
          Then 'Trustee Spouse'
      End As trustee
    , Case
        When ebfa.flag = 'Y'
          Then 'EBFA'
        When ebfa_s.flag = 'Y'
          Then 'EBFA Spouse'
      End As ebfa
    -- Overall special handling indicators
    , spec_hnd.no_contact
    , spec_hnd.no_solicit
    , spec_hnd.no_release
    , spec_hnd.active_with_restrictions
    , spec_hnd.never_engaged_forever
    , spec_hnd.never_engaged_reunion
    , spec_hnd.has_opt_ins_opt_outs
    , spec_hnd.anonymous_donor
    -- Overall mailing list indicators
    , exc_all_comm
    , exc_all_sols
    , exc_surveys
    , last_survey.last_survey_dt
    -- No AF sol combined
    , Case
        When no_contact = 'Y'
          Or exc_all_comm = 'Y'
          Or active_with_restrictions = 'Y'
          Or no_solicit = 'Y'
          Or exc_all_sols = 'Y'
          Or no_af_solicit = 'Y'
          Then 'Y'
        End
      As no_af_sol_ind
    -- No surveys combined
    -- Based on p. 7 of Alumni Survey Request Guidelines and Procedures
    -- (v0.7 updated 6/24/2015)
    , Case
        When univ_no_contact = 'Y'
          Or spec_hnd.no_release = 'Y'
          Or exc_surveys = 'Y'
          Or last_survey.surveyed_last_4_months = 'Y' 
          Then 'Y'
      End As no_survey_ind
    -- No phone combined
    , Case
        When univ_no_contact = 'Y'
          Or no_phone = 'Y'
          Then 'Y'
      End As no_phone_ind
    -- No phone solicit combined
    , Case
        When univ_no_contact = 'Y'
          Or no_phone = 'Y'
          Or univ_no_solicit = 'Y'
          Or no_phone_solicit = 'Y'
          Then 'Y'
      End As no_phone_sol_ind
    -- No email combined
    , Case
        When univ_no_contact = 'Y'
          Or no_email = 'Y'
          Or exc_email_comm = 'Y'
          Then 'Y'
      End As no_email_ind
    -- No email solicit combined
    , Case
        When univ_no_contact = 'Y'
          Or no_email = 'Y'
          Or univ_no_solicit = 'Y'
          Or no_email_solicit = 'Y'
          Or exc_email_comm = 'Y'
          Or exc_email_sols = 'Y'
          Then 'Y'
      End As no_email_sol_ind
    -- No mail combined
    , Case
        When univ_no_contact = 'Y'
          Or no_mail = 'Y'
          Or exc_mail_comm = 'Y'
            Then 'Y'
      End As no_mail_ind
    -- No mail solicit combined
    , Case
        When univ_no_contact = 'Y'
          Or no_mail = 'Y'
          Or univ_no_solicit = 'Y'
          Or no_mail_solicit = 'Y'
          Or exc_mail_comm = 'Y'
          Or exc_mail_sols = 'Y'
            Then 'Y'
      End As no_mail_sol_ind
    -- No texts combined
    , Case
        When univ_no_contact = 'Y'
          Or no_texts = 'Y'
          Then 'Y'
      End As no_texts_ind
    -- No texts solicit combined
    , Case
        When univ_no_contact = 'Y'
          Or no_texts = 'Y'
          Or univ_no_solicit = 'Y'
          Or no_texts_solicit = 'Y'
          Then 'Y'
      End As no_texts_sol_ind
    -- Alerts
    , alerts.ksm_stewardship_issue
  From unc_ids ids
  Inner Join entity On entity.id_number = ids.id_number
  Left Join spec_hnd On spec_hnd.id_number = ids.id_number
  Left Join mailing_lists On mailing_lists.id_number = ids.id_number
  Left Join alerts On alerts.id_number = ids.id_number
  Left Join last_survey On last_survey.id_number = ids.id_number
  Left Join gab On gab.id_number = ids.id_number
  Left Join gab gab_s On gab_s.id_number = ids.spouse_id_number
  Left Join trustee On trustee.id_number = ids.id_number
  Left Join trustee trustee_s On trustee_s.id_number = ids.spouse_id_number
  Left Join ebfa On ebfa.id_number = ids.id_number
  Left Join ebfa ebfa_s On ebfa_s.id_number = ids.spouse_id_number
  ;

End ksm_pkg_special_handling;
/

Create Or Replace Package Body ksm_pkg_special_handling Is

/*************************************************************************
Pipelined functions
*************************************************************************/

-- Concatenated special handling preferences
Function tbl_special_handling_concat
    Return t_special_handling Pipelined As
    -- Declarations
    hnd t_special_handling;
    
    Begin
      Open c_special_handling_concat;
        Fetch c_special_handling_concat Bulk Collect Into hnd;
      Close c_special_handling_concat;
      For i in 1..(hnd.count) Loop
        Pipe row(hnd(i));
      End Loop;
      Return;
    End;

End ksm_pkg_special_handling;
/
