/* Cleaned up visits view */
Create Or Replace View v_nu_visits As

With

/*
Visits from the beginning of the previous fiscal year to yesterday
Only inlcudes living entities, but prospect records may have since been deactivated
*/

/* VIP visits */
vips As (
  Select
    id_number
    , affil
    , start_dt
    , nvl(stop_dt, cal.next_fy_start)
      As stop_dt
  From mv_nu_vips
  Cross Join v_current_calendar cal
)

/* TMS values for purpose (e.g. qualification, solicitation, ...) */
, tms_cpurp As (
  Select
    contact_purpose_code
    , short_desc
  From tms_contact_rpt_purpose
)

/* Current calendar view */
, cal As (
  Select *
  From v_current_calendar
)

/* Numeric rating bins */
, rating_bins As (
  Select *
  From table(ksm_pkg.tbl_numeric_capacity_ratings)
)

/* Main query */
Select
  contact_rpt_credit.id_number As credited
  , staff.report_name As credited_name
  , tms_crc.contact_credit_type
  , tms_crc.short_desc As contact_credit_desc
  , tms_cpurp.short_desc As contact_purpose
  -- Contact report fields
  , contact_report.report_id
  , contact_report.id_number
  , contact_report.contacted_name
  , prs.prospect_id
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
      When officer_rating <> ' ' Then uor.numeric_bin
      When evaluation_rating <> ' ' Then eval.numeric_bin
      Else 0
    End As rating_bin
  , Case
      When vips.affil = 'President'
        And contact_report.contact_date Between start_dt And stop_dt
        Then 'Y'
      End
    As president_visit
  , Case
      When vips.affil = 'KSM Dean'
        And contact_report.contact_date Between start_dt And stop_dt
        Then 'Y'
      End
    As ksm_dean_visit
  , cal.curr_fy
From contact_report
Cross Join cal
Inner Join contact_rpt_credit On contact_rpt_credit.report_id = contact_report.report_id
Inner Join tms_cpurp On tms_cpurp.contact_purpose_code = contact_report.contact_purpose_code
Inner Join entity staff
  On staff.id_number = contact_rpt_credit.id_number
Left Join tms_contact_rpt_credit_type tms_crc On tms_crc.contact_credit_type = contact_rpt_credit.contact_credit_type
Left Join nu_prs_trp_prospect prs On prs.id_number = contact_report.id_number
Left Join table(ksm_pkg.tbl_university_strategy) strat On strat.prospect_id = contact_report.prospect_id
Left Join vips On vips.id_number = contact_rpt_credit.id_number
Left Join rating_bins eval On eval.rating_desc = prs.evaluation_rating
Left Join rating_bins uor On uor.rating_desc = prs.officer_rating
Where contact_report.contact_date Between cal.prev_fy_start And cal.yesterday
  And contact_report.contact_type = 'V'
;

/* Kellogg-specific visits */
Create Or Replace View v_ksm_visits As

/* Only the visits made by Kellogg frontline staff */

Select
  credited
  , staff.report_name As credited_name
  , contact_credit_type
  , contact_credit_desc
  , staff.job_title
  , contact_purpose
  -- Contact report fields
  , report_id
  , id_number
  , contacted_name
  , prospect_id
  , contact_date
  , fiscal_year
  , description
  , summary
  -- Prospect fields
  , officer_rating
  , evaluation_rating
  , university_strategy
  -- Custom variables
  , visit_type
  , rating_bin
  , curr_fy
From v_nu_visits
Inner Join table(ksm_pkg.tbl_frontline_ksm_staff) staff On staff.id_number = v_nu_visits.credited
;
