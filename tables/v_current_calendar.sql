/*************************************************************************
ksm_pkg_calendar helper view
*************************************************************************/

Create Or Replace View v_current_calendar As

Select *
From table(ksm_pkg_calendar.tbl_current_calendar)
;
