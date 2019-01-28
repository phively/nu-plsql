-- Events summary from ep_events
Create Or Replace View v_nu_event As

Select Distinct
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
  , ksm_pkg.get_fiscal_year(
      Case
        When event.event_start_datetime Is Not Null
          Then trunc(event.event_start_datetime)
        When event.event_stop_datetime Is Not Null
          Then trunc(event.event_stop_datetime)
        End
    )
    As start_fy_calc
  , ksm_pkg.get_fiscal_year(
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
        Or evo.organization_id = '0000697410' -- Kellogg Event Admin ID
        Or lower(entity.report_name) Like lower('%Kellogg%') -- Kellogg club event organizers
        Then 'Y'
      End
    As ksm_event
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
Left Join ep_event_organizer evo
  On event.event_id = evo.event_id
Left Join entity
  On entity.id_number = evo.organization_id
Left Join ep_event master_event
  On master_event.event_id = event.master_event_id
;

-- Event participations
--Create Or Replace View v_nu_event_attendees As

Select *
From ep_participant

/*
Select
  hh.household_id
  , event_ids.event_id
  , event_ids.event_name
  , event_ids.ksm_event
  , tms_et.short_desc As event_type
  , start_fy_calc
  , stop_fy_calc
From ep_participant ppt
Cross Join params
Inner Join event_ids
  On event_ids.event_id = ppt.event_id -- KSM events
Inner Join hh
  On hh.id_number = ppt.id_number
Inner Join ep_participation ppn
  On ppn.registration_id = ppt.registration_id
Left Join tms_event_type tms_et
  On tms_et.event_type = event_ids.event_type
Where ppn.participation_status_code In (' ', 'P', 'A') -- Blank, Participated, or Accepted
*/
