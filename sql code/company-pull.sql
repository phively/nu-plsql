With
-- Employment table subquery
employ As (
  Select id_number, job_title, 
    -- If there's an employer ID filled in, use the entity name
    Case
      When employer_id_number Is Not Null And employer_id_number != ' ' Then (
        Select pref_mail_name
        From entity
        Where id_number = employer_id_number
      )
      -- Otherwise use the write-in field
      Else trim(employer_name1 || ' ' || employer_name2)
    End As employer_name
  From employment
  Where employment.primary_emp_ind = 'Y'
)

Select
  -- Entity fields
  deg.id_number, entity.report_name, entity.record_status_code, entity.institutional_suffix,
  deg.degrees_concat, deg.first_ksm_year, trim(deg.program_group) As program,
  -- Employment fields
  prs.business_title, trim(prs.employer_name1 || ' ' || prs.employer_name2) As business_company,
  employ.job_title, employ.employer_name,
  prs.business_city, prs.business_state, prs.business_country,
  -- Prospect fields
  prs.prospect_manager, prs.team
From table(rpt_pbh634.ksm_pkg.tbl_entity_degrees_concat_ksm) deg -- KSM alumni definition
Inner Join entity On deg.id_number = entity.id_number
  Left Join employ On deg.id_number = employ.id_number
  Left Join nu_prs_trp_prospect prs On deg.id_number = prs.id_number
Where
  -- Matches pattern; user beware (Apple vs. Snapple)
  lower(employ.employer_name) Like lower('%' || '&company_name_pattern' || '%')
  Or lower(prs.employer_name1) Like lower('%' || '&company_name_pattern' || '%')
