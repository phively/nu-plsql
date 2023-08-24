-- Constant retrieval
Select
    ksm_pkg_committee.get_string_constant('committee_gab') As gab_no_pkg
  , ksm_pkg_committee.get_string_constant('ksm_pkg_committee.committee_gab') As gab_with_pkg
From DUAL
;

-- Direct cursor test
Select * From table(ksm_pkg_committee.tbl_committee_agg('U', 'GAB'))
;

Select * From table(ksm_pkg_committee.tbl_committee_members(
        ksm_pkg_committee.get_string_constant('committee_kac')
    )
)
;

-- Individual committee tests
Select * From table(ksm_pkg_tst.tbl_committee_gab)
;

Select * From table(ksm_pkg_tst.tbl_committee_phs)
;

Select * From table(ksm_pkg_tst.tbl_committee_kac)
;

Select * From table(ksm_pkg_tst.tbl_committee_kfn)
;

Select * From table(ksm_pkg_tst.tbl_committee_corpGov)
;

Select * From table(ksm_pkg_tst.tbl_committee_womenSummit)
;

Select * From table(ksm_pkg_tst.tbl_committee_divSummit)
;

Select * From table(ksm_pkg_tst.tbl_committee_realEstCouncil)
;

Select * From table(ksm_pkg_tst.tbl_committee_amp)
;

Select * From table(ksm_pkg_tst.tbl_committee_trustee)
;

Select * From table(ksm_pkg_tst.tbl_committee_healthcare)
;

Select * From table(ksm_pkg_tst.tbl_committee_womensLeadership)
;

Select * From table(ksm_pkg_tst.tbl_committee_kalc)
;

Select * From table(ksm_pkg_tst.tbl_committee_kic)
;

Select * From table(ksm_pkg_tst.tbl_committee_privateEquity)
;

Select * From table(ksm_pkg_tst.tbl_committee_pe_asia)
;

Select * From table(ksm_pkg_tst.tbl_committee_asia)
;

Select * From table(ksm_pkg_tst.tbl_committee_mbai)
;
