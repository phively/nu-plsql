/****************************
All ARD contact reports
****************************/

Create Or Replace View v_ard_contact_reports As

/* Main query */
Select
  contact_rpt_credit.id_number As credited
  , ard_staff.report_name As credited_name
  , ard_staff.job_title
  , ard_staff.employer_unit
  , tms_ctype.short_desc As contact_type
  , tms_cpurp.short_desc As contact_purpose
  -- Contact report fields
  , contact_report.report_id
  , contact_report.id_number
  , contact_report.contacted_name
  , contacted_entity.report_name
  , contact_report.prospect_id
  , prospect_entity.primary_ind
  , prospect.prospect_name
  , prospect.prospect_name_sort
  , contact_report.contact_date
  , rpt_pbh634.ksm_pkg.get_fiscal_year(contact_report.contact_date) As fiscal_year
  , contact_report.description
  , dbms_lob.substr(contact_report.summary, 2000, 1) As summary
  -- Prospect fields
  , prs.officer_rating
  , prs.evaluation_rating
  , strat.university_strategy
  -- Custom variables
  , Case When ksm_staff.report_name Is Not Null Then 'Y' End As frontline_ksm_staff
  , Case
      When tms_ctype.contact_type In ('A', 'E') Then 'Attempted, E-mail, or Social'
      Else tms_ctype.short_desc
    End As contact_type_category
  , Case When contact_report.contact_type = 'V' Then
      Case When contact_report.contact_purpose_code = '1' Then 'Qualification' Else 'Visit' End
      Else Null
    End As visit_type
  , rpt_pbh634.ksm_pkg.get_prospect_rating_bin(prs.id_number) As rating_bin
  , cal.curr_fy
  , cal.prev_fy_start
  , cal.curr_fy_start
  , cal.next_fy_start
  , cal.yesterday
  , cal.ninety_days_ago
From contact_report
Cross Join v_current_calendar cal
Inner Join contact_rpt_credit On contact_rpt_credit.report_id = contact_report.report_id
Inner Join tms_contact_rpt_purpose tms_cpurp On tms_cpurp.contact_purpose_code = contact_report.contact_purpose_code
Inner Join tms_contact_rpt_type tms_ctype On tms_ctype.contact_type = contact_report.contact_type
Inner Join nu_prs_trp_prospect prs On prs.id_number = contact_report.id_number
Inner Join entity contacted_entity On contacted_entity.id_number = contact_report.id_number
-- Only NU ARD staff
Inner Join table(ksm_pkg.tbl_nu_ard_staff) ard_staff On ard_staff.id_number = contact_rpt_credit.id_number
Left Join table(ksm_pkg.tbl_frontline_ksm_staff) ksm_staff On ksm_staff.id_number = ard_staff.id_number
Left Join prospect On prospect.prospect_id = prs.prospect_id
Left Join prospect_entity On prospect_entity.id_number = prs.id_number
Left Join table(ksm_pkg.tbl_university_strategy) strat On strat.prospect_id = contact_report.prospect_id
;

/****************************
KSM-specific contact reports
Only recent FY
****************************/

Create Or Replace View v_ksm_contact_reports As

/* Main query */
Select
  credited
  , credited_name
  , job_title
  , employer_unit
  , contact_type
  , contact_purpose
  , report_id
  , id_number
  , contacted_name
  , report_name
  , prospect_id
  , primary_ind
  , prospect_name
  , prospect_name_sort
  , contact_date
  , fiscal_year
  , description
  , summary
  , officer_rating
  , evaluation_rating
  , university_strategy
  , frontline_ksm_staff
  , contact_type_category
  , visit_type
  , rating_bin
  , curr_fy
  , prev_fy_start
  , curr_fy_start
  , next_fy_start
  , yesterday
  , ninety_days_ago
From v_ard_contact_reports ard
Where frontline_ksm_staff = 'Y'
  And contact_date Between prev_fy_start And yesterday
;
