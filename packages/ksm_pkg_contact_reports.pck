Create Or Replace Package ksm_pkg_contact_reports Is

/*************************************************************************
Author  : PBH634
Created : 10/27/2025
Purpose : Contact report helper view linking contact report relations and
  fundraiser contact report relations.
Dependencies: dw_pkg_base

Suggested naming conventions:
  Pure functions: [function type]_[description]
  Row-by-row retrieval (slow): get_[object type]_[action or description] e.g.
  Table or cursor retrieval (fast): tbl_[object type]_[action or description]
*************************************************************************/

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_contact_reports';

/*************************************************************************
Public type declarations
*************************************************************************/

/*************************************************************************
Public table declarations
*************************************************************************/

/*************************************************************************
Public function declarations
*************************************************************************/

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

/*********************** About pipelined functions ***********************
Q: What is a pipelined function?

A: Pipelined functions are used to return the results of a cursor row by row.
This is an efficient way to re-use a cursor between multiple programs. Pipelined
tables can be queried in SQL exactly like a table when embedded in the table()
function. My experience has been that thanks to the magic of the Oracle compiler,
joining on a table() function scales hugely better than running a function once
on each element of a returned column. Note that the exact columns returned need
to be specified as a public type, which I did in the type and table declarations
above, or the pipelined function can't be run in pure SQL. Alternately, the
pipelined function could return a generic table, but the columns would still need
to be individually named.
*************************************************************************/

/*************************************************************************
End of package
*************************************************************************/

End ksm_pkg_contact_reports;
/
Create Or Replace Package Body ksm_pkg_contact_reports Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

Cursor c_contact_reports Is
  Select
    cr.contact_report_salesforce_id
    , cr.contact_report_record_id
    , cr.contact_report_author_salesforce_id
      As cr_author_salesforce_id
  --  , mve_author.donor_id
  --    As cr_author_donor_id
  --  , mve_author.full_name
  --    As cr_author_full_name
  --  , mve_author.sort_name
  --    As cr_author_sort_name
    , fcr.fundraiser_cr_record_id
    , fcr.fundraiser_salesforce_id
  --  , mve_fcr.donor_id
  --    As fundraiser_donor_id
  --  , mve_fcr.full_name
  --    As fundraiser_full_name
  --  , mve_fcr.sort_name
  --    As fundraiser_sort_name
    , fcr.fundraiser_role
    , crr.cr_relation_record_id
    , crr.cr_relation_salesforce_id
    , mve_crr.donor_id
      As cr_relation_donor_id
    , mve_crr.full_name
      As cr_relation_full_name
    , mve_crr.sort_name
      As cr_relation_sort_name
    , crr.contact_role
    , cr.contact_report_type
    , cr.contact_report_purpose
    , cr.contact_report_visit_flag
    , cr.contact_report_date
    , cr.contact_report_description
    , cr.contact_report_body
  From table(dw_pkg_base.tbl_contact_report) cr
  Left Join table(dw_pkg_base.tbl_contact_report_relation) crr
    On crr.contact_report_salesforce_id = cr.contact_report_salesforce_id
  Left Join table(dw_pkg_base.tbl_fundraiser_contact_report_relation) fcr
    On fcr.contact_report_salesforce_id = cr.contact_report_salesforce_id
  Left Join mv_entity mve_crr
    On mve_crr.salesforce_id = crr.contact_salesforce_id
;

/*************************************************************************
Private functions
*************************************************************************/

/*************************************************************************
Pipelined functions
*************************************************************************/


End ksm_pkg_contact_reports;
/
