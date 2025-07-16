Create Or Replace Package ksm_pkg_committee Is

/*************************************************************************
Author  : PBH634
Created : 4/29/2025
Purpose : Combined definitions for committee participation and expected dues.
Dependencies: dw_pkg_base (mv_involvement), ksm_pkg_calendar

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
committee_tech Constant stg_alumni.ucinn_ascendv2__involvement_value__c.ucinn_ascendv2__code__c%type := 'COM-KTC'; -- Kellogg Alumni Tech Council

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



--------------------------------------
Type rec_committees_concat Is Record (
  donor_id dm_alumni.dim_involvement.constituent_donor_id%type
  , committees_and_roles varchar2(1600)
  , committee_start_dates varchar2(500)
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type committee_members Is Table Of rec_committee_member;
Type committees_concat Is Table Of rec_committees_concat;

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

--------------------------------------
-- Return committee members by committee code
Function tbl_committee_members(
  my_involvement_cd In varchar2
) Return committee_members Pipelined;

--------------------------------------
Function tbl_committees_all
  Return committee_members Pipelined;

--------------------------------------
Function tbl_committees_concat
  Return committees_concat Pipelined;

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
  From mv_involvement inv
  Where inv.involvement_status = 'Current'
    And inv.involvement_code = my_involvement_cd
;

--------------------------------------
Cursor c_committees_all Is

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
  From mv_involvement inv
  Where inv.involvement_code In (
    Select ksm_pkg_committee.get_string_constant('committee_gab') From DUAL
    Union Select ksm_pkg_committee.get_string_constant('committee_kac') From DUAL
    Union Select ksm_pkg_committee.get_string_constant('committee_phs') From DUAL
    Union Select ksm_pkg_committee.get_string_constant('committee_kfn') From DUAL
    Union Select ksm_pkg_committee.get_string_constant('committee_realEstCouncil') From DUAL
    Union Select ksm_pkg_committee.get_string_constant('committee_amp') From DUAL
    Union Select ksm_pkg_committee.get_string_constant('committee_trustee') From DUAL
    Union Select ksm_pkg_committee.get_string_constant('committee_healthcare') From DUAL
    Union Select ksm_pkg_committee.get_string_constant('committee_privateEquity') From DUAL
    Union Select ksm_pkg_committee.get_string_constant('committee_pe_asia') From DUAL
    Union Select ksm_pkg_committee.get_string_constant('committee_asia') From DUAL
    Union Select ksm_pkg_committee.get_string_constant('committee_mbai') From DUAL
    Union Select ksm_pkg_committee.get_string_constant('committee_yab') From DUAL
    Union Select ksm_pkg_committee.get_string_constant('committee_tech') From DUAL
    Union Select ksm_pkg_committee.get_string_constant('committee_womensLeadership') From DUAL
  )
;

--------------------------------------
Cursor c_committees_concat Is

    Select
      constituent_donor_id As donor_id
      , Listagg(
          trim(involvement_name || ' ' || involvement_role)
          , '; ' || chr(13)
        ) Within Group (Order By involvement_start_date, involvement_name, involvement_record_id)
        As committees_and_roles
      , Listagg(to_char(involvement_start_date, 'yyyy-mm-dd'), '; ' || chr(13)) Within Group (Order By involvement_start_date, involvement_name, involvement_record_id)
        As committee_start_dates
    From table(ksm_pkg_committee.tbl_committees_all) cmte
    Where cmte.involvement_status = 'Current'
    Group By constituent_donor_id
;
    
/*************************************************************************
Functions
*************************************************************************/

--------------------------------------
-- Retrieve one of the named string constants from the package
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
-- Retrieve one of the named numeric constants from the package
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
  inv_code varchar2(255);
  committees committee_members;
  
  Begin 
  -- Check if my_involvement_cd is actually a named pkg constant
  Begin
    inv_code := ksm_pkg_committee.get_string_constant(my_involvement_cd);
    Exception
      When Others Then
        inv_code := my_involvement_cd;
    End;
     
    Open c_committee_member(my_involvement_cd => inv_code);
      Fetch c_committee_member Bulk Collect Into committees;
    Close c_committee_member;
    For i in 1..(committees.count) Loop
      Pipe row(committees(i));
    End Loop;
    Return;
  End;

--------------------------------------
Function tbl_committees_all
  Return committee_members Pipelined As
    -- Declarations
    ca committee_members;

  Begin
    Open c_committees_all;
      Fetch c_committees_all Bulk Collect Into ca;
    Close c_committees_all;
    For i in 1..(ca.count) Loop
      Pipe row(ca(i));
    End Loop;
    Return;
  End;

--------------------------------------
Function tbl_committees_concat
  Return committees_concat Pipelined As
    -- Declarations
    cc committees_concat;

  Begin
    Open c_committees_concat;
      Fetch c_committees_concat Bulk Collect Into cc;
    Close c_committees_concat;
    For i in 1..(cc.count) Loop
      Pipe row(cc(i));
    End Loop;
    Return;
  End;

End ksm_pkg_committee;
/
