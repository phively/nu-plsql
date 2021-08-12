CREATE OR REPLACE VIEW TMP_KSM_STW_CORNERSTONE AS 

WITH last_contact AS (
Select id_number
     , row_number() OVER(PARTITION BY ID_NUMBER ORDER BY CONTACT_DATE DESC) RW
     , contacted_name
     , contact_date
     , contact_type
     , credited_name
     , description
     , summary
FROM RPT_PBH634.V_CONTACT_REPORTS_FAST
GROUP BY id_number, contacted_name, contact_date, contact_type, credited_name, description, summary
),

GAB As (
Select id_number
     , short_desc
     , status
     , role
     , start_dt
     From table(rpt_pbh634.ksm_pkg.tbl_committee_gab)
),

Trustee As (
Select id_number, report_name, institutional_suffix
     From entity
     Where institutional_suffix Like '%Trustee%'
)

Select e.id_number
     , e.pref_mail_name
     , hh.household_id
     , hh.HOUSEHOLD_PRIMARY
     , hh.SPOUSE_ID_NUMBER
     , hh.SPOUSE_REPORT_NAME
     , gc.gift_club_code
     , RPT_PBH634.KSM_PKG.to_date2(gc.gift_club_start_date, 'YYYYMMDD') As gift_club_start_date
     , RPT_PBH634.KSM_PKG.to_date2(gc.gift_club_end_date, 'YYYYMMDD') As gift_club_end_date
     , gc.gift_club_status
     , gc.school_code AS "Role_code"
     , tms.short_desc AS "Role"
     , p.EVALUATION_RATING
     , p.OFFICER_RATING
     , p.prospect_manager
     , gab.short_desc AS GAB_Desc
     , gab.status AS GAB_Status
     , Trustee.institutional_suffix AS Trustee_Info
     , giv.LAST_GIFT_DATE
     , giv.LAST_GIFT_TYPE
     , giv.last_gift_alloc
     , giv.LAST_GIFT_RECOGNITION_CREDIT
     , lc.contacted_name
     , lc.contact_date
     , lc.contact_type
     , lc.credited_name
     , lc.description
     , lc.summary
From gift_clubs gc
-- Role is apparently saved under school_code; don't ask
Left Join nu_mem_v_tmsclublevel tms
     On tms.level_code = gc.school_code
Inner Join entity e
     On e.id_number = gc.gift_club_id_number
Inner Join rpt_pbh634.v_entity_ksm_households hh
     On e.id_number = hh.id_number
Left Join GAB
     On GAB.id_number = e.id_number
Left Join Trustee
     On Trustee.id_number = e.id_number
Left Join last_contact lc
     On lc.id_number = e.id_number
Left Join NU_PRS_TRP_PROSPECT P
     On gc.gift_club_id_number = P.id_number
Left Join rpt_pbh634.v_ksm_giving_summary giv
     On gc.gift_club_id_number = giv.id_number
Where gc.gift_club_code = 'KCD'
And LC.RW = 1
