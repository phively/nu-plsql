Create Or Replace Package ksm_pkg_contacts Is

/*************************************************************************
Author  : PBH634
Created : 7/10/2025
Purpose : Combined address, phone, email, social media contact information
  per entity record.
Dependencies: dw_pkg_base, mv_entity (ksm_pkg_entity)

Suggested naming conventions:
  Pure functions: [function type]_[description]
  Row-by-row retrieval (slow): get_[object type]_[action or description] e.g.
  Table or cursor retrieval (fast): tbl_[object type]_[action or description]
*************************************************************************/

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_contacts';

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

End ksm_pkg_contacts;
/
Create Or Replace Package Body ksm_pkg_contacts Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

--------------------------------------
Cursor c_geo_codes Is
  Select NULL
  From DUAL
;

--------------------------------------
Cursor c_phone Is
  Select NULL
  From DUAL
;

--------------------------------------
Cursor c_email Is
  Select NULL
  From DUAL
;

--------------------------------------
Cursor c_address Is
  Select NULL
  From DUAL
;

--------------------------------------
Cursor c_linkedin Is
  Select NULL
  From DUAL
;

/*************************************************************************
Private functions
*************************************************************************/

/*************************************************************************
Pipelined functions
*************************************************************************/


End ksm_pkg_contacts;
/
