Create Or Replace View tableau_metrics_contact_reports As

Select
  cr.contact_report_salesforce_id
  , cr.contact_report_record_id
  , cr.cr_credit_salesforce_id
  , cr.cr_credit_name
  , cr.cr_credit_title
  , cr.cr_credit_type
  , cr.cr_relation_record_id
  , cr.cr_relation_salesforce_id
  , cr.cr_relation_donor_id
  , cr.cr_relation_household_id_ksm
  , cr.cr_relation_full_name
  , cr.cr_relation_sort_name
  , mve.institutional_suffix
  , mve.is_deceased_indicator
  , cr.contact_role
  , cr.contact_report_type
  , cr.contact_report_purpose
  , cr.contact_report_visit_flag
  , cr.contact_report_date
  , ksm_pkg_calendar.get_performance_year(cr.contact_report_date)
    As contact_report_perf_year
  , cr.contact_report_description
  , cr.contact_report_body
  , mva.prospect_manager_user_id
  , mva.prospect_manager_name
  , mva.prospect_manager_business_unit
  , mva.lagm_user_id
  , mva.lagm_name
  , mva.lagm_business_unit
From mv_contact_reports cr
Inner Join mv_entity mve
  On mve.donor_id = cr.cr_relation_donor_id
Left Join mv_assignments mva
  On mva.donor_id = cr.cr_relation_donor_id
Where contact_report_visit_flag = 'Y' -- Only count visits
  And cr_credit_type = 'Staff Credit'
;
