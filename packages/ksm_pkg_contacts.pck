Create Or Replace Package ksm_pkg_contacts Is

/*************************************************************************
Author  : PBH634
Created : 7/10/2025
Purpose : Combined address, phone, email, social media contact information
  per entity record.
Dependencies: dw_pkg_base, mv_entity (ksm_pkg_entity), ksm_pkg_calendar,
  ksm_pkg_special_handling (mv_special_handling)

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

Type rec_email Is Record (
  account_salesforce_id stg_alumni.ucinn_ascendv2__email__c.ucinn_ascendv2__account__c%type
    , contact_salesforce_id stg_alumni.ucinn_ascendv2__email__c.ucinn_ascendv2__contact__c%type
    , donor_id dm_alumni.dim_constituent.constituent_donor_id%type
    , email_record_id stg_alumni.ucinn_ascendv2__email__c.name%type
    , email_type stg_alumni.ucinn_ascendv2__email__c.ucinn_ascendv2__type__c%type
    , email_status stg_alumni.ucinn_ascendv2__email__c.ucinn_ascendv2__status__c%type
    , email_preferred_indicator stg_alumni.ucinn_ascendv2__email__c.ucinn_ascendv2__is_preferred__c%type
    , email_address stg_alumni.ucinn_ascendv2__email__c.ucinn_ascendv2__email_address__c%type
    , email_data_source stg_alumni.ucinn_ascendv2__email__c.ucinn_ascendv2__data_source__c%type
    , email_start_date stg_alumni.ucinn_ascendv2__email__c.ucinn_ascendv2__start_date__c%type
    , email_stop_date stg_alumni.ucinn_ascendv2__email__c.ucinn_ascendv2__end_date__c%type
    , email_modified_date stg_alumni.ucinn_ascendv2__email__c.lastmodifieddate%type
    , etl_update_date stg_alumni.ucinn_ascendv2__email__c.etl_update_date%type
);

--------------------------------------
Type rec_address Is Record (
  donor_id dm_alumni.dim_address.address_donor_id%type
  , address_record_id dm_alumni.dim_address.address_record_id%type
  , address_relation_record_id dm_alumni.dim_address.address_relation_record_id%type
  , address_type dm_alumni.dim_address.address_type%type
  , address_status dm_alumni.dim_address.address_status%type
  , address_preferred_indicator dm_alumni.dim_address.address_prefered_indicator%type
  , address_primary_home_indicator dm_alumni.dim_address.address_primary_home_indicator%type
  , address_primary_business_indicator dm_alumni.dim_address.address_primary_business_indicator%type
  , address_seasonal_indicator dm_alumni.dim_address.address_seasonal_indicator%type
  , is_campus_indicator dm_alumni.dim_address.is_campus_indicator%type
  , address_line_1 dm_alumni.dim_address.address_line_1%type
  , address_line_2 dm_alumni.dim_address.address_line_2%type
  , address_line_3 dm_alumni.dim_address.address_line_3%type
  , address_line_4 dm_alumni.dim_address.address_line_4%type
  , address_city dm_alumni.dim_address.address_city%type
  , address_state dm_alumni.dim_address.address_state%type
  , address_postal_code dm_alumni.dim_address.address_postal_code%type
  , address_country dm_alumni.dim_address.address_country%type
  , address_latitude dm_alumni.dim_address.address_location_latitude%type
  , address_longitude dm_alumni.dim_address.address_location_longitude%type
  , address_start_date dm_alumni.dim_address.address_start_date%type
  , address_end_date dm_alumni.dim_address.address_end_date%type
  , address_seasonal_start varchar2(8)
  , address_seasonal_end varchar2(8)
  , address_seasonal_start_date dm_alumni.dim_address.address_start_date%type
  , address_seasonal_end_date dm_alumni.dim_address.address_end_date%type
  , address_modified_date dm_alumni.dim_address.address_modified_date%type
  , address_relation_modified_date dm_alumni.dim_address.address_relation_modified_date%type
  , etl_update_date dm_alumni.dim_address.etl_update_date%type
);

--------------------------------------
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

--------------------------------------
Type rec_contact_info Is Record (
  donor_id mv_entity.donor_id%type
  , sort_name mv_entity.sort_name%type
  , linkedin_url stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__url__c%type
  , home_address_line_1 dm_alumni.dim_address.address_line_1%type
  , home_address_line_2 dm_alumni.dim_address.address_line_2%type
  , home_address_line_3 dm_alumni.dim_address.address_line_3%type
  , home_address_line_4 dm_alumni.dim_address.address_line_4%type
  , home_address_city dm_alumni.dim_address.address_city%type
  , home_address_state dm_alumni.dim_address.address_state%type
  , home_address_postal_code dm_alumni.dim_address.address_postal_code%type
  , home_address_country dm_alumni.dim_address.address_country%type
  , home_address_latitude dm_alumni.dim_address.address_location_latitude%type
  , home_address_longitude dm_alumni.dim_address.address_location_longitude%type
  , business_address_line_1 dm_alumni.dim_address.address_line_1%type
  , business_address_line_2 dm_alumni.dim_address.address_line_2%type
  , business_address_line_3 dm_alumni.dim_address.address_line_3%type
  , business_address_line_4 dm_alumni.dim_address.address_line_4%type
  , business_address_city dm_alumni.dim_address.address_city%type
  , business_address_state dm_alumni.dim_address.address_state%type
  , business_address_postal_code dm_alumni.dim_address.address_postal_code%type
  , business_address_country dm_alumni.dim_address.address_country%type
  , business_address_latitude dm_alumni.dim_address.address_location_latitude%type
  , business_address_longitude dm_alumni.dim_address.address_location_longitude%type
  , email_preferred_type stg_alumni.ucinn_ascendv2__email__c.ucinn_ascendv2__type__c%type
  , email_preferred stg_alumni.ucinn_ascendv2__email__c.ucinn_ascendv2__email_address__c%type
  , email_personal stg_alumni.ucinn_ascendv2__email__c.ucinn_ascendv2__email_address__c%type
  , email_business stg_alumni.ucinn_ascendv2__email__c.ucinn_ascendv2__email_address__c%type
  , emails_concat varchar2(2000)
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type email Is Table Of rec_email;
Type address Is Table Of rec_address;
Type linkedin Is Table Of rec_linkedin;
Type contact_info Is Table Of rec_contact_info;

/*************************************************************************
Public function declarations
*************************************************************************/

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

Function tbl_email
    Return email Pipelined;

Function tbl_address
  Return address Pipelined;

Function tbl_linkedin
  Return linkedin Pipelined;

Function tbl_entity_contact_info
  Return contact_info Pipelined;

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
  Select
    e.ucinn_ascendv2__account__c
      As account_salesforce_id
    , e.ucinn_ascendv2__contact__c
      As contact_salesforce_id
    , dc.constituent_donor_id
      As donor_id
    , e.name
      As email_record_id
    , e.ucinn_ascendv2__type__c
      As email_type
    , e.ucinn_ascendv2__status__c
      As email_status
    , e.ucinn_ascendv2__is_preferred__c
      As email_preferred_indicator
    , e.ucinn_ascendv2__email_address__c
      As email_address
    , e.ucinn_ascendv2__data_source__c
      As email_data_source
    , e.ucinn_ascendv2__start_date__c
      As email_start_date
    , e.ucinn_ascendv2__end_date__c
      As email_stop_date
    , e.lastmodifieddate
      As email_modified_date
    , e.etl_update_date
  From stg_alumni.ucinn_ascendv2__email__c e
  Left Join dm_alumni.dim_constituent dc
    On dc.constituent_salesforce_id = e.ucinn_ascendv2__contact__c
;

--------------------------------------
Cursor c_address_current Is
  Select
    address_donor_id As donor_id
    , a.address_record_id
    , a.address_relation_record_id
    , a.address_type
    , a.address_status
    , a.address_preferred_indicator
    , a.address_primary_home_indicator
    , a.address_primary_business_indicator
    , a.address_seasonal_indicator
    , a.is_campus_indicator
    , a.address_line_1
    , a.address_line_2
    , a.address_line_3
    , a.address_line_4
    , a.address_city
    , a.address_state
    , a.address_postal_code
    , a.address_country
    , a.address_location_latitude
    , a.address_location_longitude
    , a.address_start_date
    , a.address_end_date
    -- Seasonal address to_date logic
    , a.address_seasonal_start
    , a.address_seasonal_end
    , NULL
      As address_seasonal_start_date
    , NULL
      As address_seasonal_end_date
    , a.address_modified_date
    , a.address_relation_modified_date
    , a.etl_update_date
  From table(dw_pkg_base.tbl_address) a
  Cross Join table(ksm_pkg_calendar.tbl_current_calendar) cal
  Where a.address_status = 'Current'
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

--------------------------------------
Cursor c_contact_info Is

  With
  
  -- Find shortest LI URL
  linkedin As (
    Select
      li.donor_id
      , min(li.linkedin_url) keep(dense_rank First Order By length(li.linkedin_url) Asc, li.linkedin_url Asc)
        As linkedin_url
    From table(ksm_pkg_contacts.tbl_linkedin) li
    Where li.status = 'Current'
    Group By li.donor_id
  )
  
  -- All active addresses
  , addr As (
    Select *
    From table(ksm_pkg_contacts.tbl_address) a
  )
    
  -- Home address; keep last primary added
  , addr_home As (
    Select
      donor_id
      , address_line_1
      , address_line_2
      , address_line_3
      , address_line_4
      , address_city
      , address_state
      , address_postal_code
      , address_country
      , address_latitude
      , address_longitude
      , row_number()
        Over (Partition By donor_id Order By address_modified_date Desc, address_record_id Desc)
        As addr_rank
    From addr
    Where addr.address_primary_home_indicator = 'Y'
  )
  
  -- Business address; keep last primary added
  , addr_bus As (
    Select
      donor_id
      , address_line_1
      , address_line_2
      , address_line_3
      , address_line_4
      , address_city
      , address_state
      , address_postal_code
      , address_country
      , address_latitude
      , address_longitude
      , row_number()
        Over (Partition By donor_id Order By address_modified_date Desc, address_record_id Desc)
        As addr_rank
    From addr
    Where addr.address_primary_business_indicator = 'Y'
  )
  
  -- All active emails
  , email As (
    Select e.*
    From table(ksm_pkg_contacts.tbl_email) e
    Where e.email_status = 'Current'
      And e.donor_id Is Not Null
  )
  
  , emails_concat As (
    -- Sort order: preferred, then recently added, then type, then alphabetical
    Select
      donor_id
      , Listagg(Distinct email_address, '; ') Within Group
        (Order By email_preferred_indicator Desc, email_start_date Desc, email_type Asc, email_address Asc)
        As emails_concat
    From email
    Group By donor_id
  )
  
  , email_personal As (
    Select
      donor_id
      , email_address
      , row_number()
        Over (Partition By donor_id
          Order By email_preferred_indicator Desc, email_start_date Desc, email_address Asc)
        As email_rank
    From email
    Where email_type = 'Personal'
  )
  
  , email_business As (
    Select
      donor_id
      , email_address
      , row_number()
        Over (Partition By donor_id
          Order By email_preferred_indicator Desc, email_start_date Desc, email_address Asc)
        As email_rank
    From email
    Where email_type = 'Business'
  )
  
  , email_preferred As (
    Select
      donor_id
      , email_type
      , email_address
    From email
    Where email_preferred_indicator = 'true'
  )
  
  Select
    mve.donor_id
    , mve.sort_name
    , linkedin.linkedin_url
    , addr_home.address_line_1 As home_address_line_1
    , addr_home.address_line_2 As home_address_line_2
    , addr_home.address_line_3 As home_address_line_3
    , addr_home.address_line_4 As home_address_line_4
    , addr_home.address_city As home_address_city
    , addr_home.address_state As home_address_state
    , addr_home.address_postal_code As home_address_postal_code
    , addr_home.address_country As home_address_country
    , addr_home.address_latitude As home_address_latitude
    , addr_home.address_longitude As home_address_longitude
    , addr_bus.address_line_1 As business_address_line_1
    , addr_bus.address_line_2 As business_address_line_2
    , addr_bus.address_line_3 As business_address_line_3
    , addr_bus.address_line_4 As business_address_line_4
    , addr_bus.address_city As business_address_city
    , addr_bus.address_state As business_address_state
    , addr_bus.address_postal_code As business_address_postal_code
    , addr_bus.address_country As business_address_country
    , addr_bus.address_latitude As business_address_latitude
    , addr_bus.address_longitude As business_address_longitude
    , email_preferred.email_type As email_preferred_type
    , email_preferred.email_address As email_preferred
    , email_personal.email_address As email_personal
    , email_business.email_address As email_business
    , emails_concat.emails_concat
  From mv_entity mve
  Left Join linkedin
    On linkedin.donor_id = mve.donor_id
  Left Join addr_home
    On addr_home.donor_id = mve.donor_id
    And addr_home.addr_rank = 1
  Left Join addr_bus
    On addr_bus.donor_id = mve.donor_id
    And addr_bus.addr_rank = 1
  Left Join emails_concat 
    On emails_concat.donor_id = mve.donor_id
  Left Join email_personal 
    On email_personal.donor_id = mve.donor_id
    And email_personal.email_rank = 1
  Left Join email_business
    On email_business.donor_id = mve.donor_id
    And email_business.email_rank = 1
  Left Join email_preferred 
    On email_preferred.donor_id = mve.donor_id
;

/*************************************************************************
Private functions
*************************************************************************/

/*************************************************************************
Pipelined functions
*************************************************************************/

--------------------------------------
Function tbl_email
  Return email Pipelined As
    -- Declarations
    em email;

  Begin
    Open c_email;
      Fetch c_email Bulk Collect Into em;
    Close c_email;
    For i in 1..(em.count) Loop
      Pipe row(em(i));
    End Loop;
    Return;
  End;
  
--------------------------------------
Function tbl_address
  Return address Pipelined As
    -- Declarations
    addr address;

  Begin
    Open c_address_current;
      Fetch c_address_current Bulk Collect Into addr;
    Close c_address_current;
    For i in 1..(addr.count) Loop
      Pipe row(addr(i));
    End Loop;
    Return;
  End;

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

--------------------------------------
Function tbl_entity_contact_info
  Return contact_info Pipelined As
    -- Declarations
    ci contact_info;

  Begin
    Open c_contact_info;
      Fetch c_contact_info Bulk Collect Into ci;
    Close c_contact_info;
    For i in 1..(ci.count) Loop
      Pipe row(ci(i));
    End Loop;
    Return;
  End;

End ksm_pkg_contacts;
/
