--- Goal: Inviting prospects to cultivation events in other cities in addition to their preferred home/work region.
--- We will utilize existing Kellogg Alumni Club committee codes to track alternate regions.
--- *** Code will be dependant on Advancement's entry of comment code, KARP in committees. ***

Create or Replace View v_ksm_alternate_regions AS

With alternate_region As (Select comm.id_number,
       comm.stop_dt,
       comm.committee_code,
       tms.short_desc,
       comm.start_dt,
       comm.committee_status_code,
       comm.committee_title,
       comm.geo_code,
       comm.xcomment
FROM  committee comm
Inner Join rpt_pbh634.v_entity_ksm_degrees deg on deg.ID_NUMBER = comm.id_number
Left Join TMS_COMMITTEE_TABLE tms on tms.committee_code = comm.committee_code
where  comm.committee_status_code = 'C'  
and comm.xcomment = 'KARP'
Order by tms.short_desc ASC)

Select deg.ID_NUMBER,
       deg.REPORT_NAME,
       deg.RECORD_STATUS_CODE,
       deg.DEGREES_VERBOSE,
       deg.FIRST_KSM_YEAR,
       deg.LAST_MASTERS_YEAR,
       deg.PROGRAM,
       deg.CLASS_SECTION,
       prospect.INSTITUTIONAL_SUFFIX,
       house.HOUSEHOLD_CITY,
       house.HOUSEHOLD_STATE,
       house.HOUSEHOLD_ZIP,
       house.HOUSEHOLD_GEO_CODES,
       house.HOUSEHOLD_GEO_PRIMARY,
       house.HOUSEHOLD_GEO_PRIMARY_DESC,
       house.HOUSEHOLD_COUNTRY,
       alternate_region.short_desc,
       alternate_region.start_dt,
       alternate_region.committee_status_code,
       alternate_region.xcomment
From rpt_pbh634.v_entity_ksm_degrees deg
Left Join rpt_pbh634.v_ksm_prospect_pool prospect on prospect.ID_NUMBER = deg.ID_NUMBER
Left Join rpt_pbh634.v_entity_ksm_households house on house.ID_NUMBER = deg.ID_NUMBER
Inner Join alternate_region on alternate_region.id_number = deg.id_number
Order By deg.REPORT_NAME ASC
