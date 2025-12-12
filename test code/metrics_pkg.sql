---------------------------
-- metrics_pkg tests
---------------------------

-- Constants
Select
    metrics_pkg.get_numeric_constant('mg_ask_amt') As mg_ask_amt
  , metrics_pkg.get_numeric_constant('mg_ask_amt_ksm_outright') As mg_ask_amt_ksm_outright
  , metrics_pkg.get_numeric_constant('mg_ask_amt_ksm_plg') As mg_ask_amt_ksm_plg
  , metrics_pkg.get_numeric_constant('mg_granted_amt') As mg_granted_amt
  , metrics_pkg.get_numeric_constant('mg_funded_count') As mg_funded_count
  , metrics_pkg.get_numeric_constant('metrics_pkg.mg_ask_amt') As mg_ask_amt
  , metrics_pkg.get_numeric_constant('metrics_pkg.mg_ask_amt_ksm_outright') As mg_ask_amt_ksm_outright
  , metrics_pkg.get_numeric_constant('metrics_pkg.mg_ask_amt_ksm_plg') As mg_ask_amt_ksm_plg
  , metrics_pkg.get_numeric_constant('metrics_pkg.mg_granted_amt') As mg_granted_amt
  , metrics_pkg.get_numeric_constant('metrics_pkg.mg_funded_count') As mg_funded_count
From DUAL
;

-- Table functions
Select *
From table(metrics_pkg.tbl_universal_proposals_data)
;

Select *
From table(metrics_pkg.tbl_funded_count)
;

Select *
From table(metrics_pkg.tbl_funded_dollars)
;

Select *
From table(metrics_pkg.tbl_asked_count)
;

Select *
From table(metrics_pkg.tbl_asked_count_ksm)
;

Select *
From table(metrics_pkg.tbl_contact_reports)
;

Select *
From table(metrics_pkg.tbl_contact_count)
;
