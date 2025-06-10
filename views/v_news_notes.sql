create or replace view v_news_notes as 

with news as (select n.ap_constituent__c,
       n.ap_note_author__c,
       n.ap_note_date__c,
       n.ap_note_description__c,
       n.ap_created_by_name_formula__c,
       n.ap_note_text__c,
       n.ap_note_type__c,
       n.createdbyid,
       n.createddate,
       n.id,
       n.lastmodifiedbyid,
       n.lastmodifieddate,
       n.ap_data_source__c,
       n.name,
       n.ownerid,
       n.recordtypeid
from stg_alumni.ap_note__c n
where n.ap_note_type__c like '%News%'
and n.ap_data_source__c like '%Kellogg%')

select c.ucinn_ascendv2__donor_id__c,
c.firstname,
c.lastname,
news.ap_note_type__c,
news.ap_note_date__c,
news.ap_note_description__c,
news.ap_note_text__c,
news.ap_data_source__c
from stg_alumni.contact c 
inner join news on news.ap_constituent__c = c.id
