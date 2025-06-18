/*************************************************************************
Aggregated committee helper views
*************************************************************************/

Create Or Replace View v_committees_concat As
Select *
From table(ksm_pkg_committee.tbl_committees_concat)
;

/*************************************************************************
Non-aggregated committee helper views
*************************************************************************/

Create Or Replace View v_committee_gab As
Select *
From table(ksm_pkg_committee.tbl_committee_members('committee_gab'))
;

Create Or Replace View v_committee_kac As
Select *
From table(ksm_pkg_committee.tbl_committee_members('committee_kac'))
;

Create Or Replace View v_committee_phs As
Select *
From table(ksm_pkg_committee.tbl_committee_members('committee_phs'))
;

Create Or Replace View v_committee_kfn As
Select *
From table(ksm_pkg_committee.tbl_committee_members('committee_kfn'))
;

Create Or Replace View v_committee_realEstCouncil As
Select *
From table(ksm_pkg_committee.tbl_committee_members('committee_realEstCouncil'))
;

Create Or Replace View v_committee_amp As
Select *
From table(ksm_pkg_committee.tbl_committee_members('committee_amp'))
;

Create Or Replace View v_committee_trustee As
Select *
From table(ksm_pkg_committee.tbl_committee_members('committee_trustee'))
;

Create Or Replace View v_committee_healthcare As
Select *
From table(ksm_pkg_committee.tbl_committee_members('committee_healthcare'))
;

Create Or Replace View v_committee_womensLeadership As
Select *
From table(ksm_pkg_committee.tbl_committee_members('committee_womensLeadership'))
;

Create Or Replace View v_committee_privateEquity As
Select *
From table(ksm_pkg_committee.tbl_committee_members('committee_privateEquity'))
;

Create Or Replace View v_committee_pe_asia As
Select *
From table(ksm_pkg_committee.tbl_committee_members('committee_pe_asia'))
;

Create Or Replace View v_committee_asia As
Select *
From table(ksm_pkg_committee.tbl_committee_members('committee_asia'))
;

Create Or Replace View v_committee_mbai As
Select *
From table(ksm_pkg_committee.tbl_committee_members('committee_mbai'))
;

Create Or Replace View v_committee_yab As
Select *
From table(ksm_pkg_committee.tbl_committee_members('committee_yab'))
;

Create Or Replace View v_committee_tech As
Select *
From table(ksm_pkg_committee.tbl_committee_members('committee_tech'))
;
