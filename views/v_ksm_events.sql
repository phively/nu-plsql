-- Event organizers
Create Or Replace View v_nu_event_organizers As

Select Distinct
  -- Use event_organizer if possible, otherwise event_organization
    Case
      When entity.report_name Is Not Null
        Then eo.id_number
      Else eo.organization_id
      End
    As event_organizer_id
  , Case
      When entity.report_name Is Not Null
        Then entity.report_name
      Else ento.report_name
      End
    As event_organizer_name
  , Case
      When lower(entity.report_name) Like lower('%Kellogg%')
        And entity.person_or_org = 'O'
        Then 'Y'
      When lower(ento.report_name) Like lower('%Kellogg%')
        And ento.person_or_org = 'O'
        Then 'Y'
      End
    As kellogg_club
From ep_event_organizer eo
Left Join entity
  On entity.id_number = eo.id_number
Left Join entity ento
  On ento.id_number = eo.organization_id
Where entity.person_or_org Is Null
  Or entity.person_or_org = 'O'
;

-- Events summary from ep_events
Create Or Replace View v_nu_events As

With

-- All event organizers
organizers As (
  Select
    eo.event_id
    , Case
        When neo1.event_organizer_id Is Not Null
          Then neo1.event_organizer_id
        Else neo2.event_organizer_id
      End
      As event_organizer_id
    , Case
        When neo1.event_organizer_id Is Not Null
          Then neo1.event_organizer_name
        Else neo2.event_organizer_name
        End
      As event_organizer_name
    , Case
        When neo1.event_organizer_id Is Not Null
          Then neo1.kellogg_club
        Else neo2.kellogg_club
        End
      As kellogg_club
  From ep_event_organizer eo
  Left Join v_nu_event_organizers neo1
    On eo.id_number = neo1.event_organizer_id
  Left Join v_nu_event_organizers neo2
    On eo.organization_id = neo2.event_organizer_id
)

-- Organizers concatenated
, organizers_concat As (
  Select
    event_id
    , max(kellogg_club)
      As kellogg_organizers
    , Listagg(event_organizer_name, '; ') Within Group (Order By event_organizer_name)
      As event_organizers
  From organizers
  Group By event_id
)

-- Event codes concatenated
, event_codes_concat As (
  Select
    ec.event_id
    , Listagg(tms_ec.short_desc || ' (' || ec.event_code || ')', '; ') Within Group (Order By ec.date_added)
      As event_codes_concat
    , max(Case When tms_ec.short_desc Like '%KSM%' Or tms_ec.short_desc Like '%Kellogg%' Then 'Y' End)
      As ksm_event_codes
  From ep_event_codes ec
  Inner Join tms_event_code tms_ec
    On tms_ec.event_code = ec.event_code
  Group By event_id
)

-- Event IDs with a KSM organizer, OR a KSM organization
, ksm_organizers As (
  Select Distinct
    event_id
  From organizers
  Where kellogg_club = 'Y'
)

Select
  event.event_id
  , event.event_name
  , event.event_type
  , tms_et.short_desc
    As event_type_desc
  , trunc(event.event_start_datetime)
    As start_dt
  , trunc(event.event_stop_datetime)
    As stop_dt
  -- Assume events are one day, so if stop or start date is missing, use the other 
  -- If both are missing could fall back to date added (noisy) or omit
  , Case
      When event.event_start_datetime Is Not Null
        Then trunc(event.event_start_datetime)
      When event.event_stop_datetime Is Not Null
        Then trunc(event.event_stop_datetime)
      Else trunc(event.date_added)
      End
    As start_dt_calc
  , Case
      When event.event_stop_datetime Is Not Null
        Then trunc(event.event_stop_datetime)
      When event.event_start_datetime Is Not Null
        Then trunc(event.event_start_datetime)
      Else trunc(event.date_added)
      End
    As stop_dt_calc
  , ksm_pkg_tmp.get_fiscal_year(
      Case
        When event.event_start_datetime Is Not Null
          Then trunc(event.event_start_datetime)
        When event.event_stop_datetime Is Not Null
          Then trunc(event.event_stop_datetime)
        End
    )
    As start_fy_calc
  , ksm_pkg_tmp.get_fiscal_year(
      Case
        When event.event_stop_datetime Is Not Null
          Then trunc(event.event_stop_datetime)
        When event.event_start_datetime Is Not Null
          Then trunc(event.event_start_datetime)
        End
    )
    As stop_fy_calc
  -- Check whether event is KSM-specific
  , Case
      When event.event_name Like '%KSM%'
        Or event.event_name Like '%Kellogg%'
        Or ksm_org.event_id Is Not Null
        Or event_codes_concat.ksm_event_codes Is Not Null
        Then 'Y'
      End
    As ksm_event
  -- Organizers
  , organizers_concat.event_organizers
  , organizers_concat.kellogg_organizers
  -- Event codes
  , event_codes_concat.event_codes_concat
  -- Master event information
  , event.master_event_id
  , master_event.event_name
    As master_event_name
  , trunc(master_event.event_start_datetime)
    As master_event_start_dt
  , trunc(master_event.event_stop_datetime)
    As master_event_stop_dt
From ep_event event
Left Join tms_event_type tms_et
  On event.event_type = tms_et.event_type
Left Join ksm_organizers ksm_org
  On event.event_id = ksm_org.event_id
Left Join ep_event master_event
  On master_event.event_id = event.master_event_id
Left Join organizers_concat
  On organizers_concat.event_id = event.event_id
Left Join event_codes_concat
  On event_codes_concat.event_id = event.event_id
;

-- Event registrants
Create Or Replace View v_nu_event_registrants As
Select
  entity.id_number
  , entity.report_name
  , entity.person_or_org
  , entity.institutional_suffix
  , deg.degrees_concat
  , deg.first_ksm_year
  , deg.program_group
  , v_nu_events.event_id
  , v_nu_events.event_name
  , v_nu_events.ksm_event
  , tms_et.short_desc As event_type
  , reg.registration_id
  , reg.registration_status_code
  , tms_ers.short_desc As registration_status
  , ppn.participation_id
  , ppn.participation_status_code
  , tms_ps.short_desc As participation_status
  , Case When ppn.participation_status_code In (' ', 'P', 'A', 'V') -- Blank, Participated, Accepted, Virtual
      Then 'Y' End
      As participated_flag
  , start_dt
  , stop_dt
  , start_dt_calc
  , stop_dt_calc
  , start_fy_calc
  , stop_fy_calc
From ep_registration reg
Inner Join v_nu_events
  On v_nu_events.event_id = reg.event_id -- KSM events
Inner Join entity
  On entity.id_number = reg.contact_id_number
Left Join v_entity_ksm_degrees deg
  On deg.id_number = entity.id_number
Left Join ep_participant ppt
  On ppt.registration_id = reg.registration_id
Left Join ep_participation ppn
  On ppn.registration_id = ppt.registration_id
Left Join tms_event_registration_status tms_ers
  On tms_ers.registration_status_code = reg.registration_status_code
Left Join tms_event_participant_status tms_ps
  On tms_ps.participant_status_code = ppn.participation_status_code
Left Join tms_event_type tms_et
  On tms_et.event_type = v_nu_events.event_type
;

-- Event participations
Create Or Replace View v_nu_event_participants_fast As
Select
  entity.id_number
  , entity.report_name
  , entity.person_or_org
  , entity.institutional_suffix
  , deg.degrees_concat
  , deg.first_ksm_year
  , deg.program_group
  , v_nu_events.event_id
  , v_nu_events.event_name
  , v_nu_events.ksm_event
  , tms_et.short_desc As event_type
  , ppn.participation_id
  , ppn.participation_status_code
  , tms_ps.short_desc As participation_status
  , start_dt
  , stop_dt
  , start_dt_calc
  , stop_dt_calc
  , start_fy_calc
  , stop_fy_calc
From ep_participant ppt
Inner Join v_nu_events
  On v_nu_events.event_id = ppt.event_id -- KSM events
Inner Join entity
  On entity.id_number = ppt.id_number
Left Join v_entity_ksm_degrees deg
  On deg.id_number = ppt.id_number
Inner Join ep_participation ppn
  On ppn.registration_id = ppt.registration_id
Left Join tms_event_type tms_et
  On tms_et.event_type = v_nu_events.event_type
Left Join tms_event_participant_status tms_ps
  On tms_ps.participant_status_code = ppn.participation_status_code
Where ppn.participation_status_code In (' ', 'P', 'A', 'V') -- Blank, Participated, Accepted, Virtual
;

Create Or Replace View v_nu_event_participants As

Select
  hh.household_id
  , hh.household_rpt_name
  , hh.household_primary
  , hh.id_number
  , hh.report_name
  , hh.person_or_org
  , hh.institutional_suffix
  , hh.degrees_concat
  , hh.first_ksm_year
  , hh.program_group
  , epf.event_id
  , epf.event_name
  , epf.ksm_event
  , epf.event_type
  , epf.participation_id
  , epf.participation_status_code
  , epf.participation_status
  , epf.start_dt
  , epf.stop_dt
  , epf.start_dt_calc
  , epf.stop_dt_calc
  , epf.start_fy_calc
  , epf.stop_fy_calc
From v_nu_event_participants_fast epf
Inner Join v_entity_ksm_households hh
  On hh.id_number = epf.id_number
;
