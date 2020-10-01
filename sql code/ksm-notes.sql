WITH KSM_ENGAGEMENT AS (Select DISTINCT event.id_number,
       max (start_dt_calc) keep (dense_rank First Order By start_dt_calc DESC) As Date_Recent_Event,
       max (event.event_id) keep (dense_rank First Order By start_dt_calc DESC) As Recent_Event_ID,
       max (event.event_name) keep(dense_rank First Order By start_dt_calc DESC) As Recent_Event_Name
from rpt_pbh634.v_nu_event_participants event
where event.ksm_event = 'Y'
and event.degrees_concat is not null
Group BY event.id_number
Order By Date_Recent_Event ASC)

,KSM_Model as (select DISTINCT mg.id_number,
       mg.id_score,
       mg.pr_code,
       mg.pr_segment,
       mg.pr_score
From rpt_pbh634.v_ksm_model_mg mg)

,KSM_GIVING AS (SELECT GIVE.ID_NUMBER,
                      GIVE.HOUSEHOLD_ID,
                      GIVE.NGC_LIFETIME,
                      GIVE.LAST_GIFT_DATE,
                      GIVE.LAST_GIFT_ALLOC,
                      GIVE.LAST_GIFT_RECOGNITION_CREDIT
FROM rpt_pbh634.v_ksm_giving_summary GIVE)

,KSM_MANAGER AS (SELECT SUMMARY.id_number,
                 SUMMARY.prospect_manager,
                 SUMMARY.lgos
From rpt_pbh634.v_assignment_summary SUMMARY
Where SUMMARY.curr_ksm_manager = 'Y')

,KSM_NOTES AS (select notes.note_id,
       notes.id_number,
       notes.note_date,
       notes.description,
       notes.brief_note,
       notes.date_added
from notes
inner join rpt_pbh634.v_entity_ksm_degrees deg on deg.id_number = notes.id_number
Where notes.note_type = 'NE'
and notes.date_added >= To_Date ('09/01/2020','mm/dd/yyyy'))

,KSM_LAST_Contact AS (Select Distinct
p.id_number
, p.contact_author
, entity.pref_mail_name
, p.contact_date As last_visit_date
, p.giving_total
From nu_prs_trp_prospect p
left join entity on entity.id_number = p.contact_author)

SELECT DISTINCT HOUSE.ID_NUMBER,
       HOUSE.REPORT_NAME,
       KSM_NOTES.note_date,
       KSM_NOTES.description,
       KSM_NOTES.brief_note,
       KSM_NOTES.date_added,
       KSM_LAST_Contact.contact_author,
       KSM_LAST_Contact.pref_mail_name,
       KSM_LAST_Contact.last_visit_date,
       KSM_LAST_Contact.giving_total,
       HOUSE.RECORD_STATUS_CODE,
       HOUSE.FIRST_KSM_YEAR,
       HOUSE.PROGRAM,
       HOUSE.PROGRAM_GROUP,
       HOUSE.INSTITUTIONAL_SUFFIX,
       HOUSE.HOUSEHOLD_CITY,
       HOUSE.HOUSEHOLD_STATE,
       HOUSE.HOUSEHOLD_ZIP,
       HOUSE.HOUSEHOLD_GEO_CODES,
       HOUSE.HOUSEHOLD_COUNTRY,
       HOUSE.HOUSEHOLD_CONTINENT,
       KSM_MANAGER.prospect_manager,
       KSM_MANAGER.lgos,
       KSM_ENGAGEMENT.Date_Recent_Event,
       KSM_ENGAGEMENT.Recent_Event_ID,
       KSM_ENGAGEMENT.Recent_Event_Name,
       KSM_Model.pr_segment,
       KSM_Model.pr_score,
       KSM_GIVING.NGC_LIFETIME,
       KSM_GIVING.LAST_GIFT_DATE,
       KSM_GIVING.LAST_GIFT_ALLOC,
       KSM_GIVING.LAST_GIFT_RECOGNITION_CREDIT
FROM rpt_pbh634.v_entity_ksm_households HOUSE
LEFT JOIN KSM_ENGAGEMENT ON KSM_ENGAGEMENT.ID_NUMBER = HOUSE.ID_NUMBER
LEFT JOIN KSM_Model ON KSM_Model.ID_NUMBER = HOUSE.ID_NUMBER
LEFT JOIN KSM_GIVING ON KSM_GIVING.HOUSEHOLD_ID = HOUSE.ID_NUMBER
LEFT JOIN KSM_MANAGER ON KSM_MANAGER.ID_NUMBER = HOUSE.ID_NUMBER
LEFT JOIN KSM_LAST_Contact ON KSM_LAST_Contact.ID_NUMBER = HOUSE.ID_NUMBER
INNER JOIN KSM_NOTES ON KSM_NOTES.ID_NUMBER = HOUSE.ID_NUMBER
Order BY KSM_NOTES.note_date ASC
