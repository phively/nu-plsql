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

Type rec_linkedin Is Record (
  contact_salesforce_id stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__contact__c%type 
  , donor_id stg_alumni.contact.ucinn_ascendv2__donor_id__c%type
  , social_media_record_id stg_alumni.ucinn_ascendv2__social_media__c.name%type 
  , status stg_alumni.ucinn_ascendv2__social_media__c.ap_status__c%type 
  , platform stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__platform__c%type 
  , linkedin_url stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__url__c%type
  , notes stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__notes__c%type 
  , last_modified_date stg_alumni.ucinn_ascendv2__social_media__c.lastmodifieddate%type 
  , etl_update_date stg_alumni.ucinn_ascendv2__social_media__c.etl_update_date%type 
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type linkedin Is Table Of rec_linkedin;

/*************************************************************************
Public function declarations
*************************************************************************/

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

Function tbl_linkedin
  Return linkedin Pipelined;

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
  Select
    sm.contact_salesforce_id
    , sm.donor_id
    , sm.social_media_record_id
    , sm.status
    , sm.platform
    , sm.social_media_url
      As linkedin_url
    , sm.notes
    , sm.last_modified_date
    , sm.etl_update_date
  From table(dw_pkg_base.tbl_social_media) sm
  Where lower(platform) Like '%linked%in%'
;

/*************************************************************************
Private functions
*************************************************************************/

/*************************************************************************
Pipelined functions
*************************************************************************/

--------------------------------------
Function tbl_linkedin
  Return linkedin Pipelined As
    -- Declarations
    li linkedin;

  Begin
    Open c_linkedin;
      Fetch c_linkedin Bulk Collect Into li;
    Close c_linkedin;
    For i in 1..(li.count) Loop
      Pipe row(li(i));
    End Loop;
    Return;
  End;

End ksm_pkg_contacts;
/
