/*************************************************************************
Continents and KSM continent definition
*************************************************************************/

Create Or Replace View v_addr_continents As

Select *
From table(ksm_pkg_contact_info.tbl_continents)
;
