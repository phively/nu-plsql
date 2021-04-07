create or replace view vt_alumni_market_sheet as

With
-- Employment table subquery
employ As (
  Select id_number
  , job_title
  , employment.fld_of_work_code
  , fow.short_desc As fld_of_work
  , employer_name1,
    -- If there's an employer ID filled in, use the entity name
    Case
      When employer_id_number Is Not Null And employer_id_number != ' ' Then (
        Select pref_mail_name
        From entity
        Where id_number = employer_id_number)
      -- Otherwise use the write-in field
      Else trim(employer_name1 || ' ' || employer_name2)
    End As employer_name
  From employment
  Left Join tms_fld_of_work fow
       On fow.fld_of_work_code = employment.fld_of_work_code
  Where employment.primary_emp_ind = 'Y'
),

--- Prospect 1Mil + - Used for Ben's New Map (4/7/2021)

Prospect_1M_Plus AS (
Select distinct TP.ID_NUMBER,
       TP.EVALUATION_RATING,
       TP.OFFICER_RATING

From nu_prs_trp_prospect TP

Where TP.EVALUATION_RATING IN ('A7 $1M - $1.9M','A6 $2M - $4.9M','A5 $5M - $9.9M',

'A4 $10M - $24.9M','A3 $25M - $49.9M')

Or

TP.OFFICER_RATING IN ('A7 $1M - $1.9M',

'A6 $2M - $4.9M', 'A5 $5M - $9.9M', 'A4 $10M - $24.9M', 'A3 $25M - $49.9M')),

--- KSM Assignments: LGO, PM, Manager

ksm_assignment as (select distinct assign.id_number,
assign.prospect_manager,
assign.lgos,
assign.managers
from rpt_pbh634.v_assignment_summary assign)

--- Degree Fields

Select Distinct
rpt_pbh634.v_entity_ksm_degrees.ID_NUMBER,

rpt_pbh634.v_entity_ksm_degrees.REPORT_NAME,

rpt_pbh634.v_entity_ksm_degrees.RECORD_STATUS_CODE,

rpt_pbh634.v_entity_ksm_degrees.FIRST_KSM_YEAR,

rpt_pbh634.v_entity_ksm_degrees.PROGRAM,

rpt_pbh634.v_entity_ksm_degrees.PROGRAM_GROUP,

--- Gender Code

Entity.Gender_Code,

--- Employment

Employ.fld_of_work_code,

Employ.fld_of_work,

Employ.employer_name,

Employ.job_title,

--- City, State, Zip, Geo Codes By Household

rpt_pbh634.v_entity_ksm_households.HOUSEHOLD_CITY,

rpt_pbh634.v_entity_ksm_households.HOUSEHOLD_STATE,

rpt_pbh634.v_entity_ksm_households.HOUSEHOLD_ZIP,

rpt_pbh634.v_entity_ksm_households.HOUSEHOLD_GEO_CODES,

rpt_pbh634.v_entity_ksm_households.HOUSEHOLD_COUNTRY,

rpt_pbh634.v_entity_ksm_households.HOUSEHOLD_CONTINENT,

ksm_assignment.prospect_manager,

ksm_assignment.lgos,

ksm_assignment.managers,

Prospect_1M_Plus.EVALUATION_RATING,

Prospect_1M_Plus.OFFICER_RATING

From rpt_pbh634.v_entity_ksm_degrees

---- Join Entity --- For Gender Code

Inner Join Entity on rpt_pbh634.v_entity_ksm_degrees.ID_NUMBER = Entity.Id_Number

---- Join Households --- For Address

Left Join rpt_pbh634.v_entity_ksm_households On rpt_pbh634.v_entity_ksm_degrees.ID_NUMBER = rpt_pbh634.v_entity_ksm_households.ID_NUMBER

---- Join Employment

Left Join Employ On rpt_pbh634.v_entity_ksm_degrees.ID_NUMBER = Employ.Id_Number

---- Join Assignment

Left Join ksm_assignment on ksm_assignment.id_number = rpt_pbh634.v_entity_ksm_degrees.ID_NUMBER

--- Join 1 Mil Prospect Plus 

Left Join Prospect_1M_Plus on Prospect_1M_Plus.id_number = rpt_pbh634.v_entity_ksm_degrees.ID_NUMBER

---- Active Alumni

Where rpt_pbh634.v_entity_ksm_degrees.Record_Status_Code = 'A'
;
