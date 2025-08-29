/*************************************************************************
Campaign a.k.a. appeal performance
*************************************************************************/

Create Or Replace View v_campaign_appeal As

Select *
From table(dw_pkg_base.tbl_campaign_appeal)
;
