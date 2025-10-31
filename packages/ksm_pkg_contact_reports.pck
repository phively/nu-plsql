Create Or Replace Package ksm_pkg_contact_reports Is

/*************************************************************************
Author  : PBH634
Created : 10/27/2025
Purpose : Contact report helper view linking contact report relations and
  fundraiser contact report relations.
Dependencies: dw_pkg_base, ksm_pkg_entity (mv_entity)

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

--------------------------------------
Type rec_contact_reports Is Record (
  contact_report_salesforce_id stg_alumni.ucinn_ascendv2__contact_report__c.id%type
  , contact_report_record_id stg_alumni.ucinn_ascendv2__contact_report__c.name%type
  , cr_author_salesforce_id stg_alumni.ucinn_ascendv2__contact_report__c.ap_contact_report_author_user__c%type
  , cr_author_name stg_alumni.user_tbl.name%type
  , cr_author_title stg_alumni.user_tbl.title%type
  , cr_author_constituent_salesforce_id stg_alumni.ucinn_ascendv2__contact_report__c.ap_contact_report_author_constituent__c%type
  , cr_author_constituent_donor_id mv_entity.donor_id%type
  , cr_author_constituent_name mv_entity.full_name%type
  , fundraiser_cr_record_id stg_alumni.ucinn_ascendv2__fundraiser_contact_report_relation__c.name%type
  , fundraiser_salesforce_id stg_alumni.ucinn_ascendv2__fundraiser_contact_report_relation__c.ucinn_ascendv2__fundraiser__c%type
  , fundraiser_name stg_alumni.user_tbl.name%type
  , fundraiser_title stg_alumni.user_tbl.title%type
  , fundraiser_role stg_alumni.ucinn_ascendv2__fundraiser_contact_report_relation__c.ucinn_ascendv2__fundraiser_role__c%type
  , cr_relation_record_id stg_alumni.ucinn_ascendv2__contact_report_relation__c.name%type
  , cr_relation_salesforce_id stg_alumni.ucinn_ascendv2__contact_report_relation__c.id%type
  , cr_relation_donor_id mv_entity.donor_id%type
  , cr_relation_full_name mv_entity.full_name%type
  , cr_relation_sort_name mv_entity.sort_name%type
  , contact_role stg_alumni.ucinn_ascendv2__contact_report_relation__c.ucinn_ascendv2__contact_role__c%type
  , contact_report_type stg_alumni.ucinn_ascendv2__contact_report__c.ucinn_ascendv2__contact_method__c%type
  , contact_report_purpose stg_alumni.ucinn_ascendv2__contact_report__c.ap_purpose__c%type
  , contact_report_visit_flag varchar2(1)
  , contact_report_date stg_alumni.ucinn_ascendv2__contact_report__c.ucinn_ascendv2__date__c%type
  , contact_report_description stg_alumni.ucinn_ascendv2__contact_report__c.ucinn_ascendv2__description__c%type
  , contact_report_body stg_alumni.ucinn_ascendv2__contact_report__c.ucinn_ascendv2__contact_report_body__c%type
  , etl_update_date stg_alumni.ucinn_ascendv2__contact_report__c.etl_update_date%type
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type contact_reports Is Table Of rec_contact_reports;

/*************************************************************************
Public function declarations
*************************************************************************/

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

Function tbl_contact_reports
  Return contact_reports Pipelined;

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
  Select Distinct
    cr.contact_report_salesforce_id
    , cr.contact_report_record_id
    , cr.contact_report_author_salesforce_id
      As cr_author_salesforce_id
    , user_cr.user_name
      As cr_author_name
    , user_cr.user_title
      As cr_author_title
    , cr.contact_report_author_constituent_salesforce_id
      As cr_author_constituent_salesforce_id
    , mve_author.donor_id
      As cr_author_constituent_donor_id
    , mve_author.full_name
      As cr_author_constituent_name
    , fcr.fundraiser_cr_record_id
    , fcr.fundraiser_salesforce_id
    , user_fcr.user_name
      As fundraiser_name
    , user_fcr.user_title
      As fundraiser_title
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
    , greatest(cr.etl_update_date, crr.etl_update_date, fcr.etl_update_date)
      As etl_update_date
  From table(dw_pkg_base.tbl_contact_report) cr
  Left Join table(dw_pkg_base.tbl_contact_report_relation) crr
    On crr.contact_report_salesforce_id = cr.contact_report_salesforce_id
  Left Join table(dw_pkg_base.tbl_fundraiser_contact_report_relation) fcr
    On fcr.contact_report_salesforce_id = cr.contact_report_salesforce_id
  Left Join mv_entity mve_crr
    On mve_crr.salesforce_id = crr.contact_salesforce_id
  Left Join mv_entity mve_author
    On mve_author.salesforce_id = cr.contact_report_author_constituent_salesforce_id
  Left Join table(dw_pkg_base.tbl_users) user_cr
    On user_cr.user_salesforce_id = cr.contact_report_author_salesforce_id
  Left Join table(dw_pkg_base.tbl_users) user_fcr
    On user_fcr.user_salesforce_id = fcr.fundraiser_salesforce_id
;

/*************************************************************************
Private functions
*************************************************************************/

/*************************************************************************
Pipelined functions
*************************************************************************/

--------------------------------------
Function tbl_contact_reports
  Return contact_reports Pipelined As
    -- Declarations
    cr contact_reports;

  Begin
    Open c_contact_reports;
      Fetch c_contact_reports Bulk Collect Into cr;
    Close c_contact_reports;
    For i in 1..(cr.count) Loop
      Pipe row(cr(i));
    End Loop;
    Return;
  End;

End ksm_pkg_contact_reports;
/
