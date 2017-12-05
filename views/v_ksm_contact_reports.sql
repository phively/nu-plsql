Create Or Replace View v_ksm_contact_reports As

With

/* Current calendar view */
cal As (
  Select *
  From v_current_calendar
)

/* Main query */
Select
  contact_rpt_credit.id_number As credited
  , staff.report_name As credited_name
  , staff.job_title
  , tms_ctype.short_desc As contact_type
  , tms_cpurp.short_desc As contact_purpose
  -- Contact report fields
  , contact_report.report_id
  , contact_report.id_number
  , contact_report.contacted_name
  , contact_report.prospect_id
  , contact_report.contact_date
  , rpt_pbh634.ksm_pkg.get_fiscal_year(contact_report.contact_date) As fiscal_year
  , contact_report.description
  , dbms_lob.substr(contact_report.summary, 2000, 1) As summary
  -- Prospect fields
  , prs.officer_rating
  , prs.evaluation_rating
  , strat.university_strategy
  -- Custom variables
  , Case When contact_report.contact_purpose_code = '1' Then 'Qualification' Else 'Visit' End As visit_type
  , Case
      When rpt_pbh634.ksm_pkg.get_prospect_rating_numeric(prs.id_number) >= 10 Then 10
      When rpt_pbh634.ksm_pkg.get_prospect_rating_numeric(prs.id_number) = 0.25 Then 0.1
      When rpt_pbh634.ksm_pkg.get_prospect_rating_numeric(prs.id_number) < 0.1 Then 0
      Else rpt_pbh634.ksm_pkg.get_prospect_rating_numeric(prs.id_number)
    End As rating_bin
  , cal.curr_fy
From contact_report
Cross Join cal
Inner Join contact_rpt_credit On contact_rpt_credit.report_id = contact_report.report_id
Inner Join tms_contact_rpt_purpose tms_cpurp On tms_cpurp.contact_purpose_code = contact_report.contact_purpose_code
Inner Join tms_contact_rpt_type tms_ctype On tms_ctype.contact_type = contact_report.contact_type
Inner Join nu_prs_trp_prospect prs On prs.id_number = contact_report.id_number
Inner Join table(ksm_pkg.tbl_frontline_ksm_staff) staff On staff.id_number = contact_rpt_credit.id_number
Left Join table(ksm_pkg.tbl_university_strategy) strat On strat.prospect_id = contact_report.prospect_id
Where contact_report.contact_date Between cal.prev_fy_start And cal.yesterday
