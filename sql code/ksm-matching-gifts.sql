/*

Matching Gift Report: fields requested 

ID 
Spouse ID
Donor Name
Spouse Donor Name
Program/Grad Year
Spouse Program/Grad Year
Address info (all the columns)
Email special handling codes (do not email) for primary donor
Email special handling codes for spouse
Restrictions/do not contact for primary donor
Restrictions/do not contact for spouse
Gift information for CY FY and PY FY
-  Fiscal year
-  Gift date
-  Gift amount
-  Allocation
Matching gift received amount
Matching gift received date
LGO
MGO*/ 


WITH h AS (SELECT *
FROM rpt_pbh634.v_entity_ksm_households_fast),

d as (select *
from rpt_pbh634.v_entity_ksm_degrees),

a as (select assign.id_number,
       assign.prospect_manager,
       assign.lgos,
       assign.managers,
       assign.curr_ksm_manager
from rpt_pbh634.v_assignment_summary assign),

s as (select *
from rpt_pbh634.v_entity_special_handling spec),

--- spouse special handling 

spouse as (select h.SPOUSE_ID_NUMBER,
s.NO_CONTACT,
s.ACTIVE_WITH_RESTRICTIONS,
s.NO_EMAIL_IND,
s.NO_EMAIL_SOL_IND
from h 
inner join s on s.id_number = h.SPOUSE_ID_NUMBER),

p as (Select
         a.Id_number
      ,  tms_addr_status.short_desc AS Address_Status
      ,  tms_address_type.short_desc AS Address_Type
      ,  a.care_of
      ,  a.addr_type_code
      ,  a.addr_pref_ind
      ,  a.company_name_1
      ,  a.company_name_2
      ,  a.business_title
      ,  a.street1
      ,  a.street2
      ,  a.street3
      ,  a.foreign_cityzip
      ,  a.city
      ,  a.state_code
      ,  a.zipcode
      ,  tms_country.short_desc AS Country
      FROM address a
      INNER JOIN tms_addr_status ON tms_addr_status.addr_status_code = a.addr_status_code
      LEFT JOIN tms_address_type ON tms_address_type.addr_type_code = a.addr_type_code
      LEFT JOIN tms_country ON tms_country.country_code = a.country_code
      WHERE a.addr_pref_IND = 'Y'
      AND a.addr_status_code IN('A','K')),
      
GIVING_TRANS as (SELECT HH.HOUSEHOLD_ID,
                  HH.HOUSEHOLD_RPT_NAME,
                  HH.ID_NUMBER,
                  HH.REPORT_NAME,
                  HH.ANONYMOUS,
                  HH.TX_NUMBER,
                  HH.TX_SEQUENCE,
                  HH.TRANSACTION_TYPE_CODE,
                  HH.TRANSACTION_TYPE,
                  HH.TX_GYPM_IND,
                  HH.ASSOCIATED_CODE,
                  HH.ASSOCIATED_DESC,
                  HH.PLEDGE_NUMBER,
                  HH.PLEDGE_FISCAL_YEAR,
                  HH.MATCHED_TX_NUMBER,
                  HH.MATCHED_FISCAL_YEAR,
                  HH.PAYMENT_TYPE,
                  HH.ALLOCATION_CODE,
                  HH.ALLOC_SHORT_NAME,
                  HH.KSM_FLAG,
                  HH.AF_FLAG,
                  HH.CRU_FLAG,
                  HH.GIFT_COMMENT,
                  HH.PROPOSAL_ID,
                  HH.PLEDGE_STATUS,
                  HH.DATE_OF_RECORD,
                  HH.FISCAL_YEAR,
                  HH.LEGAL_AMOUNT,
                  HH.CREDIT_AMOUNT,
                  HH.RECOGNITION_CREDIT,
                  HH.STEWARDSHIP_CREDIT_AMOUNT,
                  HH.HH_CREDIT,
                  HH.HH_RECOGNITION_CREDIT,
                  HH.HH_STEWARDSHIP_CREDIT,
                  HH.today,
                  HH.yesterday,
                  HH.curr_fy
,ROW_NUMBER() OVER(PARTITION BY hh.HOUSEHOLD_ID ORDER BY hh.DATE_OF_RECORD DESC)RW
FROM rpt_pbh634.v_ksm_giving_trans_hh HH
cross join rpt_pbh634.v_current_calendar cal
 where (hh.fiscal_year = cal.CURR_FY - 0 
or hh.fiscal_year = cal.CURR_FY - 1)
and hh.TX_GYPM_IND = 'M'
 ),

 
--- Last 4 Matching Gifts
 
GI AS( select house.HOUSEHOLD_ID
     ,max(decode(RW,1,house.TRANSACTION_TYPE)) TRANSACTION_TYPE1
     ,max(decode(RW,1,house.DATE_OF_RECORD)) DATE1
     ,max(decode(RW,1,house.TX_NUMBER)) TX_NUMBER1
     ,max(decode(RW,1,house.HH_CREDIT)) CREDIT1
     ,max(decode(RW,1,house.ALLOC_SHORT_NAME)) ALLOCATION1
     ,max(decode(RW,2,house.TRANSACTION_TYPE)) TRANSACTION_TYPE2
     ,max(decode(RW,2,house.DATE_OF_RECORD)) DATE2
     ,max(decode(RW,2,house.TX_NUMBER)) TX_NUMBER2
     ,max(decode(RW,2,house.ALLOC_SHORT_NAME)) ALLOCATION2
     ,max(decode(RW,2,house.HH_CREDIT)) CREDIT2
     ,max(decode(RW,3,house.TRANSACTION_TYPE)) TRANSACTION_TYPE3
     ,max(decode(RW,3,house.DATE_OF_RECORD)) DATE3
     ,max(decode(RW,3,house.TX_NUMBER)) TX_NUMBER3
     ,max(decode(RW,3,house.ALLOC_SHORT_NAME)) ALLOCATION3
     ,max(decode(RW,3,house.HH_CREDIT)) CREDIT3
     ,max(decode(RW,4,house.TRANSACTION_TYPE)) TRANSACTION_TYPE4
     ,max(decode(RW,4,house.DATE_OF_RECORD)) DATE4
     ,max(decode(RW,4,house.TX_NUMBER)) TX_NUMBER4
     ,max(decode(RW,4,house.ALLOC_SHORT_NAME)) ALLOCATION4
     ,max(decode(RW,4,house.HH_CREDIT)) CREDIT4
 from GIVING_TRANS house
 group by HOUSE.HOUSEHOLD_ID)


Select h.ID_NUMBER,
h.HOUSEHOLD_ID,
h.REPORT_NAME,
h.FIRST_KSM_YEAR,
h.PROGRAM,
h.PROGRAM_GROUP,
h.SPOUSE_ID_NUMBER,
h.SPOUSE_REPORT_NAME,
h.SPOUSE_SUFFIX,
h.SPOUSE_FIRST_KSM_YEAR,
h.SPOUSE_PROGRAM,
h.SPOUSE_PROGRAM_GROUP,
h.HOUSEHOLD_PRIMARY,
a.prospect_manager,
a.lgos,
s.NO_CONTACT,
s.ACTIVE_WITH_RESTRICTIONS,
s.NO_EMAIL_IND,
s.NO_EMAIL_SOL_IND,
spouse.NO_CONTACT spouse_no_contact_flag,
spouse.ACTIVE_WITH_RESTRICTIONS spouse_active_withrestrictions,
spouse.NO_EMAIL_IND as spouse_no_email_ind,
spouse.NO_EMAIL_SOL_IND as spouse_no_email_sol_ind,
p.Address_Type,
p.care_of,
p.Street1,
p.Street2,
p.Street3,
p.City,
p.State_code,
p.Zipcode,
p.Country,
GI.TRANSACTION_TYPE1,
GI.DATE1,
GI.TX_NUMBER1,
GI.CREDIT1,
GI.ALLOCATION1,
GI.TRANSACTION_TYPE2,
GI.DATE2,
GI.TX_NUMBER2,
GI.CREDIT2,
GI.ALLOCATION2,
GI.TRANSACTION_TYPE3,
GI.DATE3,
GI.TX_NUMBER3,
GI.CREDIT3,
GI.ALLOCATION3,
GI.TRANSACTION_TYPE4,
GI.DATE4,
GI.TX_NUMBER4,
GI.CREDIT4,
GI.ALLOCATION4
from h
inner join d 
     on d.id_number = h.id_number
left join  a 
     on a.id_number = h.id_number  
left join s 
     on s.id_number = h.id_number
--- special handling code, but for spouses
left join  spouse 
     on spouse.SPOUSE_ID_NUMBER = h.SPOUSE_ID_NUMBER
left join p
     on p.id_number = h.id_number
inner join GI
     ON H.ID_NUMBER = GI.HOUSEHOLD_ID
