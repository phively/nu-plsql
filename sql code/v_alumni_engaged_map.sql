Create or Replace view v_alumni_engaged_map as 
--- The purpose of this view is to create a heat map for alumni that are engaged to their local clubs
--- Create a subquery for engagement over time 
--- Join with Household view to get Geocodes
--- Make sure to trim Zip code for the Tableau Map
--- I can use this view and use calculations in Tableau to modify my heat map 

with engage as (select e.id_number,
o.event_organizer_name,
o.kellogg_club,
e.start_fy_calc
from rpt_pbh634.v_nu_event_participants e
Left Join EP_Event_Organizer On EP_Event_Organizer.Event_Id = e.Event_Id
Left Join rpt_pbh634.v_nu_event_organizers o on o.event_organizer_id = EP_Event_Organizer.Organization_Id
Inner Join rpt_pbh634.v_entity_ksm_degrees deg on deg.id_number = e.id_number
where o.kellogg_club = 'Y' )

select distinct engage.id_number,
engage.event_organizer_name,
engage.start_fy_calc,
house.HOUSEHOLD_ZIP,
substr(house.HOUSEHOLD_ZIP, 1, 5) AS zip_trim,
case when engage.id_number is not null then house.HOUSEHOLD_GEO_CODES else '' END as Household_Geocode
from engage
inner join rpt_pbh634.v_entity_ksm_households house on house.ID_NUMBER = engage.id_number
