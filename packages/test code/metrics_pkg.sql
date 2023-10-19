Select *
From table(rpt_pbh634.metrics_pkg.tbl_universal_proposals_data)
;

Select count(*)
From table(rpt_pbh634.metrics_pkg.tbl_funded_count)
;

Select count(*)
From table(rpt_pbh634.metrics_pkg_tst.tbl_funded_count)
;

Select count(*)
From table(rpt_pbh634.metrics_pkg_tst.tbl_funded_count(0.01, 0.01))
