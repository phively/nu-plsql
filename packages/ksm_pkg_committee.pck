Create Or Replace Package ksm_pkg_committee Is

/*************************************************************************
Author  : PBH634
Created : 4/29/2025
Purpose : Combined definitions for committee participation and expected dues.
Dependencies: dw_pkg_base, ksm_pkg_calendar

Suggested naming conventions:
  Pure functions: [function type]_[description]
  Row-by-row retrieval (slow): get_[object type]_[action or description] e.g.
  Table or cursor retrieval (fast): tbl_[object type]_[action or description]
*************************************************************************/

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_committee';

--------------------------------------
-- Committees
committee_gab Constant stg_alumni.ucinn_ascendv2__involvement_value__c.ucinn_ascendv2__code__c%type := 'COM-U'; -- Kellogg Global Advisory Board committee code
committee_kac Constant stg_alumni.ucinn_ascendv2__involvement_value__c.ucinn_ascendv2__code__c%type := 'VOL-KACNA'; -- Kellogg Alumni Council committee code
committee_phs Constant stg_alumni.ucinn_ascendv2__involvement_value__c.ucinn_ascendv2__code__c%type := 'VOL-KPH'; -- KSM Pete Henderson Society
committee_kfn Constant stg_alumni.ucinn_ascendv2__involvement_value__c.ucinn_ascendv2__code__c%type := 'COM-KFN'; -- Kellogg Finance Network code
committee_womenSummit Constant stg_alumni.ucinn_ascendv2__involvement_value__c.ucinn_ascendv2__code__c%type := 'VOL-KGWS'; -- KSM Global Women's Summit code
committee_realEstCouncil Constant stg_alumni.ucinn_ascendv2__involvement_value__c.ucinn_ascendv2__code__c%type := 'COM-KREAC'; -- Real Estate Advisory Council code
committee_amp Constant stg_alumni.ucinn_ascendv2__involvement_value__c.ucinn_ascendv2__code__c%type := 'COM-KAMP'; -- AMP Advisory Council code
committee_trustee Constant stg_alumni.ucinn_ascendv2__involvement_value__c.ucinn_ascendv2__code__c%type := 'COM-TBOT'; -- NU Board of Trustees code
committee_healthcare Constant stg_alumni.ucinn_ascendv2__involvement_value__c.ucinn_ascendv2__code__c%type := 'COM-HAK'; -- Healthcare at Kellogg Advisory Council
committee_womensLeadership Constant stg_alumni.ucinn_ascendv2__involvement_value__c.ucinn_ascendv2__code__c%type := 'COM-KWLC'; -- Women's Leadership Advisory Council
committee_privateEquity Constant stg_alumni.ucinn_ascendv2__involvement_value__c.ucinn_ascendv2__code__c%type := 'COM-KPETC'; -- Kellogg Private Equity Taskforce Council
committee_pe_asia Constant stg_alumni.ucinn_ascendv2__involvement_value__c.ucinn_ascendv2__code__c%type := 'COM-APEAC'; -- KSM Asia Private Equity Advisory Council
committee_asia Constant stg_alumni.ucinn_ascendv2__involvement_value__c.ucinn_ascendv2__code__c%type := 'COM-KEBA'; -- Kellogg Executive Board for Asia
committee_mbai Constant stg_alumni.ucinn_ascendv2__involvement_value__c.ucinn_ascendv2__code__c%type := 'COM-MBAAC'; -- MBAi Advisory Council 
committee_yab Constant stg_alumni.ucinn_ascendv2__involvement_value__c.ucinn_ascendv2__code__c%type := 'COM-KAYAB'; -- Kellogg Young Alumni Board
--committee_tech Constant stg_alumni.ucinn_ascendv2__involvement_value__c.ucinn_ascendv2__code__c%type := 'KTC'; -- Kellogg Alumni Tech Council

--------------------------------------
-- Committee dues
dues_gab Constant number := 25.0E3;
dues_gab_life Constant number := 10.0E3;
dues_ebfa Constant number := 25.0E3;
dues_amp Constant number := 20.0E3;
dues_privateequity Constant number := 10.0E3;
dues_realestate Constant number := 7.5E3;
dues_healthcare Constant number := 5.0E3;
dues_healthcare_nonalum Constant number := 1.0E3;
dues_kac Constant number := 2.5E3;
dues_womensleadership Constant number := 2.5E3;

/*************************************************************************
Public type declarations
*************************************************************************/

--------------------------------------
Type rec_committee_member Is Record (
    constituent_donor_id dm_alumni.dim_involvement.constituent_donor_id%type
    , constituent_name dm_alumni.dim_involvement.constituent_name%type
    , involvement_record_id dm_alumni.dim_involvement.involvement_record_id%type
    , involvement_code stg_alumni.ucinn_ascendv2__involvement_value__c.ucinn_ascendv2__code__c%type
    , involvement_name dm_alumni.dim_involvement.involvement_name%type
    , involvement_status dm_alumni.dim_involvement.involvement_status%type
    , involvement_type dm_alumni.dim_involvement.involvement_type%type
    , involvement_role dm_alumni.dim_involvement.involvement_role%type
    , involvement_business_unit dm_alumni.dim_involvement.involvement_business_unit%type
    , involvement_start_fy integer
    , involvement_end_fy integer
    , involvement_start_date dm_alumni.dim_involvement.involvement_start_date%type
    , involvement_end_date dm_alumni.dim_involvement.involvement_end_date%type
    , involvement_comment stg_alumni.ucinn_ascendv2__involvement__c.nu_comments__c%type
    , etl_update_date dm_alumni.dim_involvement.etl_update_date%type
);
/*
--------------------------------------
Type rec_committee_agg Is Record (
    id_number committee.id_number%type
    , report_name entity.report_name%type
    , committee_code stg_alumni.ucinn_ascendv2__involvement_value__c.ucinn_ascendv2__code__c%type
    , short_desc committee_header.short_desc%type
    , start_dt varchar2(512)
    , stop_dt varchar2(512)
    , status tms_committee_status.short_desc%type
    , role varchar2(1024)
    , committee_title varchar2(1024)
    , committee_short_desc varchar2(40)
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type committee_members Is Table Of rec_committee_member;
--Type committee_agg Is Table Of rec_committee_agg;

/*************************************************************************
Public function declarations
*************************************************************************/

-- Returns public constants
Function get_string_constant(
  const_name In varchar2 -- Quoted name of constant to retrieve
) Return varchar2 Deterministic;

Function get_numeric_constant(
  const_name In varchar2 -- Name of constant to retrieve
) Return number Deterministic;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

-- Return committee members by committee code
Function tbl_committee_members(
  my_involvement_cd In varchar2
) Return committee_members Pipelined;
/*
-- All roles listagged to one per line
Function tbl_committee_agg(
  my_involvement_cd In varchar2
  , shortname In varchar2 Default NULL
) Return committee_agg Pipelined;
*/
End ksm_pkg_committee;
/
Create Or Replace Package Body ksm_pkg_committee Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

--------------------------------------
Cursor c_committee_member(my_involvement_cd In varchar2) Is
  Select
    inv.constituent_donor_id
    , inv.constituent_name
    , inv.involvement_record_id
    , inv.involvement_code
    , inv.involvement_name
    , inv.involvement_status
    , inv.involvement_type
    , inv.involvement_role
    , inv.involvement_business_unit
    , ksm_pkg_calendar.get_fiscal_year(inv.involvement_start_date)
      As involvement_start_fy
    , ksm_pkg_calendar.get_fiscal_year(inv.involvement_end_date)
      As involvement_end_fy
    , inv.involvement_start_date
    , inv.involvement_end_date
    , inv.involvement_comment
    , inv.etl_update_date
  From table(dw_pkg_base.tbl_involvement) inv
  Where inv.involvement_status = 'Current'
    And inv.involvement_code = my_involvement_cd
  ;
/*
--------------------------------------
Cursor c_committee_agg(
    my_involvement_cd In varchar2
    , shortname In varchar2
  ) Is
  With
  c As (
    -- Same as c_committee_member, above
      Select
        comm.id_number
        , comm.committee_code
        , hdr.short_desc
        , comm.start_dt
        , comm.stop_dt
        , tms_status.short_desc As status
        , tms_role.short_desc As role
        , comm.committee_title
        , comm.xcomment
        , comm.date_modified
        , comm.operator_name
        , trim(entity.spouse_id_number) As spouse_id_number
        , shortname As committee_short_desc
      From committee comm
      Inner Join entity
        On entity.id_number = comm.id_number
      Left Join tms_committee_status tms_status On comm.committee_status_code = tms_status.committee_status_code
      Left Join tms_committee_role tms_role On comm.committee_role_code = tms_role.committee_role_code
      Left Join committee_header hdr On comm.committee_code = hdr.committee_code
      Where comm.committee_code = my_involvement_cd
        And comm.committee_status_code In ('C', 'A') -- 'C'urrent or 'A'ctive: 'A' is deprecated
  )
  -- Main query
  Select
    c.id_number
    , entity.report_name
    , c.committee_code
    , c.short_desc
    , listagg(c.start_dt, '; ') Within Group (Order By c.start_dt Asc, c.stop_dt Asc, c.role Asc)
      As start_dt
    , listagg(c.stop_dt, '; ') Within Group (Order By c.start_dt Asc, c.stop_dt Asc, c.role Asc)
      As stop_dt
    , c.status
    , listagg(c.role, '; ') Within Group (Order By c.start_dt Asc, c.stop_dt Asc, c.role Asc)
      As role
    , listagg(c.committee_title, '; ') Within Group (Order By c.start_dt Asc, c.stop_dt Asc, c.role Asc)
      As committee_title
    , shortname
      As committee_short_desc
  From c
  Inner Join entity
    On entity.id_number = c.id_number
  Group By
    c.id_number
    , entity.report_name
    , c.committee_code
    , c.short_desc
    , c.status
  ;

/*************************************************************************
Functions
*************************************************************************/

--------------------------------------
-- Retrieve one of the named constants from the package
-- Requires a quoted constant name
Function get_string_constant(const_name In varchar2)
  Return varchar2 Deterministic Is
  -- Declarations
  val varchar2(255);
  var varchar2(255);
  
  Begin
    -- If const_name doesn't include ksm_pkg, prepend it
    If substr(lower(const_name), 1, length(pkg_name)) <> pkg_name
      Then var := pkg_name || '.' || const_name;
    Else
      var := const_name;
    End If;
    Execute Immediate
      'Begin :val := ' || var || '; End;'
      Using Out val;
      Return val;
  End;

--------------------------------------
-- Requires a quoted constant name
Function get_numeric_constant(const_name In varchar2)
  Return number Deterministic Is
  -- Declarations
  val number;
  var varchar2(255);
  
  Begin
    -- If const_name doesn't include ksm_pkg, prepend it
    If substr(lower(const_name), 1, length(pkg_name)) <> pkg_name
      Then var := pkg_name || '.' || const_name;
    Else
      var := const_name;
    End If;
    Execute Immediate
      'Begin :val := ' || var || '; End;'
      Using Out val;
      Return val;
  End;

/*************************************************************************
Pipelined functions
*************************************************************************/

--------------------------------------
-- Generic function returning 'Current' committee members
Function tbl_committee_members(my_involvement_cd In varchar2)
  Return committee_members Pipelined As
  -- Declarations
  committees committee_members;
    
  Begin
    Open c_committee_member(my_involvement_cd => my_involvement_cd);
      Fetch c_committee_member Bulk Collect Into committees;
    Close c_committee_member;
    For i in 1..(committees.count) Loop
      Pipe row(committees(i));
    End Loop;
    Return;
  End;
/*
--------------------------------------
-- Generic rec_committee_agg function, similar to committee_members
Function committee_agg_members (
  my_involvement_cd In varchar2
  , shortname In varchar2 Default NULL
)
Return committee_agg As
-- Declarations
committees_agg committee_agg;
  
Begin
  Open c_committee_agg(my_involvement_cd => my_involvement_cd
    , shortname => shortname
  );
    Fetch c_committee_agg Bulk Collect Into committees_agg;
    Close c_committee_agg;
    Return committees_agg;
  End;

--------------------------------------
-- All roles listagged to one per line
Function tbl_committee_agg (
  my_involvement_cd In varchar2
  , shortname In varchar2
) Return committee_agg Pipelined As
committees_agg committee_agg;
  
  Begin
    committees_agg := committee_agg_members (
      my_involvement_cd => my_involvement_cd
      , shortname => shortname
    );
    For i in 1..committees_agg.count Loop
      Pipe row(committees_agg(i));
    End Loop;
    Return;
  End;
*/
End ksm_pkg_committee;
/
