With

-- KSM event organizer
ksm As (
  Select event_id, 'Y' As ksm_event
  From ep_event_organizer
  Where organization_id = '0000697410' -- Kellogg Event Admin ID
)

-- Main query
Select ppt.id_number
  , event.event_id, event.event_name, tms_et.short_desc As event_type
  , trunc(event.event_start_datetime) As start_dt, trunc(event.event_stop_datetime) As stop_dt
  , ksm.ksm_event
From ep_participant ppt
Inner Join v_entity_ksm_degrees deg On deg.id_number = ppt.id_number -- KSM alumni
Inner Join ep_event event On ppt.event_id = event.event_id
Inner Join ep_participation ppn On ppn.registration_id = ppt.registration_id
Left Join tms_event_type tms_et On tms_et.event_type = event.event_type
Left Join ksm On ksm.event_id = event.event_id
Where ppn.participation_status_code In (' ', 'P') -- Blank or Participated
  And event.master_event_id Is Null
