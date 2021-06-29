/******************************************

Assorted views for the KSM mobile entity
Conventions:
- KAC members are the test base
- v_ksm_mobile_entity
- v_ksm_mobile_realtionship
- v_ksm_mobile_address
- v_ksm_mobile_committee
- v_ksm__mobile_contact_report
- v_ksm_mobile_gift
- v_ksm_mobile_proposal

************************************************************************/

--- Entities: 

Create or Replace View v_ksm_mobile_entity as

With KSM_Email AS (select email.id_number,
       email.email_address,
       email.preferred_ind,
       email.forwards_to_email_address
From email
Where email.preferred_ind = 'Y'),

pm_manager as (select assign.id_number,
assign.prospect_manager
from rpt_pbh634.v_assignment_summary assign),

linked as (select distinct ec.id_number,
max(ec.start_dt) keep(dense_rank First Order By ec.start_dt Desc, ec.econtact asc) As Max_Date,
max (ec.econtact) keep(dense_rank First Order By ec.start_dt Desc, ec.econtact asc) as linkedin_address
from econtact ec
where  ec.econtact_status_code = 'A'
and  ec.econtact_type_code = 'L'
Group By ec.id_number),

ksm_give as (select give.ID_NUMBER,
       give.NGC_LIFETIME
From rpt_pbh634.v_ksm_giving_summary give),

KSM_telephone AS (Select t.id_number, t.area_code, t.telephone_number, t.telephone_type_code
From telephone t)

select distinct
       entity.id_number,
       entity.report_name,
       entity.institutional_suffix,
       linked.linkedin_address,
       pm_manager.prospect_manager,
       KSM_Email.email_address,
       KSM_telephone.area_code as preferred_area_code,
       KSM_telephone.telephone_number as preferred_phone,
       ksm_give.NGC_LIFETIME      
from entity 
left join KSM_Email on KSM_Email.id_number = entity.ID_NUMBER
left join pm_manager on pm_manager.id_number = entity.ID_NUMBER
left join KSM_telephone on KSM_telephone.id_number = entity.ID_NUMBER
left join linked on linked.id_number = entity.ID_NUMBER
left join entity on entity.id_number = entity.ID_NUMBER
left join ksm_give on ksm_give.id_number = entity.ID_NUMBER
Inner Join table(rpt_pbh634.ksm_pkg.tbl_committee_kac) kac
      On kac.id_number = entity.id_number
;


--- Relationships

Create or Replace View v_ksm_mobile_realtionship as

select relationship.id_number,
       relationship.relation_id_number,
       TMS_RELATIONSHIPS.short_desc as relationship_type,
       case when relationship.relation_name = ' 'then entity2.pref_mail_name
         when relationship.relation_name is not null then relationship.relation_name
           else ' ' End as realtionship_name,
        entity2.institutional_suffix,
        entity2.birth_dt
    from relationship
left join entity on entity.id_number = relationship.id_number   
left join entity entity2 on entity2.id_number = relationship.relation_id_number
left join TMS_RELATIONSHIPS on TMS_RELATIONSHIPS.relation_type_code = relationship.relation_type_code
Inner Join table(rpt_pbh634.ksm_pkg.tbl_committee_kac) kac
      On kac.id_number = relationship.id_number
order by relationship.id_number ASC
;

--- Addresses/Telephone

Create or Replace View v_ksm_mobile_contact as

With KSM_telephone AS (Select t.id_number, t.area_code, t.telephone_number, t.telephone_type_code
From telephone t)

Select
         a.Id_number
      ,  house.report_name
      ,  a.xsequence
      ,  tms_addr_status.short_desc AS Address_Status
      ,  a.addr_type_code
      ,  tms_address_type.short_desc AS Address_Type
      --- Preferred Address Indicator Added
      ,  a.addr_pref_ind
      ,  a.street1
      ,  a.street2
      ,  a.street3
      ,  a.foreign_cityzip
      ,  a.city
      ,  a.state_code
      ,  a.zipcode
      ,  tms_country.short_desc AS Country
      ,  KSM_telephone.telephone_type_code AS Telephone_Type
      ,  KSM_telephone.area_code
      ,  KSM_telephone.telephone_number
      FROM address a
      INNER JOIN tms_addr_status ON tms_addr_status.addr_status_code = a.addr_status_code
      Inner Join table(rpt_pbh634.ksm_pkg.tbl_committee_kac) kac
      On kac.id_number = a.id_number
      LEFT JOIN tms_address_type ON tms_address_type.addr_type_code = a.addr_type_code
      LEFT JOIN tms_country ON tms_country.country_code = a.country_code
      LEFT JOIN KSM_telephone on KSM_telephone.telephone_type_code = a.addr_type_code 
      and KSM_telephone.id_number = a.id_number
      INNER JOIN rpt_pbh634.v_entity_ksm_households house ON house.ID_NUMBER = a.id_number
      --- Active Addreess
      Where a.addr_status_code IN('A')
      --- Addresses: Home, Business, Alt Home, Alt Business
      and a.addr_type_code IN ('H','B','AH','AB');
      
---- Committees 

Create or Replace View v_ksm_mobile_committee as 

Select
  committee.id_number
--  , id_number
  , ch.short_desc As committee_name
  , committee.start_dt
  , committee.stop_dt
  , tcr.short_desc As committee_role
  , tcs.short_desc As committee_status
  , committee.committee_title
From committee
Inner Join committee_header ch
  On ch.committee_code = committee.committee_code
Inner Join table(rpt_pbh634.ksm_pkg.tbl_committee_kac) kac
  On kac.id_number = committee.id_number
Left Join tms_committee_role tcr
  On tcr.committee_role_code = committee.committee_role_code
  And tcr.committee_role_code <> 'U'
Left Join tms_committee_status tcs
  On tcs.committee_status_code = committee.committee_status_code;
  
--- Contact Reports

Create or Replace View v_ksm__mobile_contact_report as 

Select
    crf.id_number
  , house.report_name
  , crf.report_id
  , crf.contact_type
  , crf.contact_purpose
  , crf.contact_date
  , crf.credited_name
  , crf.description
  , crf.summary
From rpt_pbh634.v_contact_reports_fast crf
Inner Join table(rpt_pbh634.ksm_pkg.tbl_committee_kac) kac
on kac.id_number = crf.id_number
INNER JOIN rpt_pbh634.v_entity_ksm_households house ON house.ID_NUMBER = crf.id_number
Where crf.fiscal_year >= 2017
;

---- Gifts

Create or Replace View v_ksm_mobile_gift As

SELECT
   NGFT.ID_NUMBER
  ,NGFT.TX_NUMBER
  ,NGFT.DATE_OF_RECORD
  ,NGFT.DATE_OF_RECEIPT 
  ,NGFT.LEGAL_AMOUNT
  ,NGFT.CREDIT_AMOUNT
  ,NGFT.PLEDGE_BALANCE
  ,NGFT.PLEDGE_STATUS
  ,NGFT.ALLOCATION_CODE
  ,NGFT.ALLOC_SHORT_NAME  
  ,TAS.short_desc AS ALLOC_SCHOOL  
  ,TTT.short_desc AS TRANS_TYPE
  ,PG.PROPOSAL_ID
  ,AFCRU."AF_FLAG"
  ,CASE WHEN AFCRU."ALLOCATION_CODE" IS NOT NULL THEN 'Y' ELSE ' ' END AS "CURRENT_USE_FLAG"
  ,AFCRU."ALLOCATION_CODE" AS ALLOCATION_CODE_INDICATOR
  ,TA.short_desc AS ASSOCIATION 
FROM NU_GFT_TRP_GIFTTRANS NGFT
INNER JOIN TABLE(RPT_PBH634.KSM_PKG.tbl_committee_kac) KAC
ON NGFT.ID_NUMBER = KAC.ID_NUMBER
LEFT JOIN TMS_TRANSACTION_TYPE TTT
ON NGFT.TRANSACTION_TYPE = TTT.transaction_type_code
LEFT JOIN PRIMARY_GIFT PG
ON NGFT.TX_NUMBER = PG.PRIM_GIFT_RECEIPT_NUMBER
LEFT JOIN TMS_ASSOCIATION TA
ON NGFT.ASSOCIATED_CODE = TA.associated_code
LEFT JOIN TMS_ALLOC_SCHOOL TAS
ON NGFT.ALLOC_SCHOOL = TAS.alloc_school_code
LEFT JOIN rpt_pbh634.v_alloc_curr_use AFCRU
ON NGFT.ALLOCATION_CODE = AFCRU."ALLOCATION_CODE"
Where date_of_record >= to_date('20160901', 'yyyymmdd')
ORDER BY NGFT.ID_NUMBER, NGFT.DATE_OF_RECORD DESC;
;

--- proposal 

Create or Replace View v_ksm_mobile_proposal as

SELECT
   e.id_number
  ,PHF.proposal_id
  ,CASE WHEN PHF.KSM_PROPOSAL_IND = 'Y' THEN 'Kellogg' ELSE ' ' END AS PROGRAM
  ,PHF.other_programs
  ,PHF.proposal_status
  ,PHF.ask_date
  ,PHF.close_date
  ,PHF.total_ask_amt
FROM ENTITY E
INNER JOIN TABLE(RPT_PBH634.KSM_PKG.tbl_committee_kac) KAC
ON E.ID_NUMBER = KAC.ID_NUMBER
INNER JOIN PROSPECT_ENTITY PE
ON E.ID_NUMBER = PE.ID_NUMBER
INNER JOIN PROSPECT P
ON PE.PROSPECT_ID = P.PROSPECT_ID
  AND P.ACTIVE_IND = 'Y'
INNER JOIN RPT_PBH634.V_PROPOSAL_HISTORY_FAST PHF
ON PE.PROSPECT_ID = PHF.PROSPECT_ID 
WHERE PHF.proposal_active = 'Y'
ORDER BY E.ID_NUMBER
;




