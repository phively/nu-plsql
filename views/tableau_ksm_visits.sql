Create Or Replace View v_ksm_visits As

With
tms_cpurp As (
  Select contact_purpose_code, short_desc
  From tms_contact_rpt_purpose
)

Select
  contact_rpt_credit.id_number As credited,
  entity.report_name As credited_name,
  tms_cpurp.short_desc As contact_purpose,
  -- Contact report fields
  contact_report.report_id, contact_report.id_number, contact_report.contacted_name, contact_report.prospect_id, contact_report.contact_date,
  rpt_pbh634.ksm_pkg.get_fiscal_year(contact_report.contact_date) As fiscal_year,
  -- Prospect fields
  prs.officer_rating, prs.evaluation_rating,
  -- Custom variables
  Case When contact_report.contact_purpose_code = '1' Then 'Qualification' Else 'Visit' End As visit_type,
  Case
    -- If officer rating exists
    When officer_rating <> ' ' Then
      Case
        When trim(substr(officer_rating, 1, 2)) = 'A1' Then 10
        When trim(substr(officer_rating, 1, 2)) = 'A2' Then 10
        When trim(substr(officer_rating, 1, 2)) = 'A3' Then 10
        When trim(substr(officer_rating, 1, 2)) = 'A4' Then 10
        When trim(substr(officer_rating, 1, 2)) = 'A5' Then 5
        When trim(substr(officer_rating, 1, 2)) = 'A6' Then 2
        When trim(substr(officer_rating, 1, 2)) = 'A7' Then 1
        When trim(substr(officer_rating, 1, 2)) = 'B' Then 0.5
        When trim(substr(officer_rating, 1, 2)) = 'C' Then 0.1
        When trim(substr(officer_rating, 1, 2)) = 'D' Then 0.1
        Else 0
      End
    -- Else use evaluation rating
    When evaluation_rating <> ' ' Then
      Case
        When trim(substr(evaluation_rating, 1, 2)) = 'A1' Then 10
        When trim(substr(evaluation_rating, 1, 2)) = 'A2' Then 10
        When trim(substr(evaluation_rating, 1, 2)) = 'A3' Then 10
        When trim(substr(evaluation_rating, 1, 2)) = 'A4' Then 10
        When trim(substr(evaluation_rating, 1, 2)) = 'A5' Then 5
        When trim(substr(evaluation_rating, 1, 2)) = 'A6' Then 2
        When trim(substr(evaluation_rating, 1, 2)) = 'A7' Then 1
        When trim(substr(evaluation_rating, 1, 2)) = 'B' Then 0.5
        When trim(substr(evaluation_rating, 1, 2)) = 'C' Then 0.1
        When trim(substr(evaluation_rating, 1, 2)) = 'D' Then 0.1
        Else 0 
      End
    Else 0
  End As rating_bin
From rpt_pbh634.v_current_calendar cur_cal, contact_report
Inner Join contact_rpt_credit On contact_rpt_credit.report_id = contact_report.report_id
Inner Join tms_cpurp On tms_cpurp.contact_purpose_code = contact_report.contact_purpose_code
Inner Join nu_prs_trp_prospect prs On prs.id_number = contact_report.id_number
Inner Join entity On entity.id_number = contact_rpt_credit.id_number
Where contact_report.contact_date Between cur_cal.prev_fy_start And cur_cal.yesterday
  And contact_report.contact_type = 'V'
  And contact_rpt_credit.id_number In ('0000565395', '0000220843', '0000737745', '0000642888', '0000561243', '0000549376', '0000565742', '0000562459', '0000772028')
