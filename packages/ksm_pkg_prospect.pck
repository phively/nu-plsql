Create Or Replace Package ksm_pkg_prospect Is

/*************************************************************************
Author  : PBH634
Created : 5/30/2025
Purpose : Compile key prospect engagement and solicitation data
Dependencies: dw_pkg_base, ksm_pkg_calendar

Suggested naming conventions:
  Pure functions: [function type]_[description]
  Row-by-row retrieval (slow): get_[object type]_[action or description] e.g.
  Table or cursor retrieval (fast): tbl_[object type]_[action or description]
*************************************************************************/

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_prospect';

-- Model segments
/*seg_af_10k Constant segment.segment_code%type := 'KMAA_'; -- AF $10K model pattern
seg_mg_id Constant segment.segment_code%type := 'KMID_'; -- MG identification model pattern
seg_mg_pr Constant segment.segment_code%type := 'KMPR_'; -- MG prioritization model

/*************************************************************************
Public type declarations
*************************************************************************/

/*--------------------------------------
Type modeled_score Is Record (
  id_number segment.id_number%type
  , segment_year segment.segment_year%type
  , segment_month segment.segment_month%type
  , segment_code segment.segment_code%type
  , description segment_header.description%type
  , score segment.xcomment%type
);
*/

--------------------------------------
Type rec_assignment_history Is Record (
  household_id dm_alumni.dim_constituent.constituent_household_account_salesforce_id%type
  , household_primary dm_alumni.dim_constituent.household_primary_constituent_indicator%type
  , donor_id dm_alumni.dim_constituent.constituent_donor_id%type
  , sort_name dm_alumni.dim_constituent.full_name%type
  , assignment_record_id stg_alumni.ucinn_ascendv2__assignment__c.name%type
  , assignment_type stg_alumni.ucinn_ascendv2__assignment__c.ucinn_ascendv2__assignment_type__c%type
  , assignment_code varchar2(8)
  , start_date stg_alumni.ucinn_ascendv2__assignment__c.ucinn_ascendv2__assignment_start_date__c%type
  , end_date stg_alumni.ucinn_ascendv2__assignment__c.ucinn_ascendv2__assignment_end_date__c%type
  , is_active_indicator stg_alumni.ucinn_ascendv2__assignment__c.ap_is_active__c%type
  , assignment_active_calc varchar2(1)
  , staff_user_salesforce_id stg_alumni.user_tbl.id%type
  , staff_username stg_alumni.user_tbl.username%type
  , staff_name stg_alumni.user_tbl.name%type
  , assignment_business_unit stg_alumni.ucinn_ascendv2__assignment__c.ap_business_unit__c%type
  , ksm_flag varchar2(1)
  , etl_update_date stg_alumni.ap_unit_strategy_assignment__c.etl_update_date%type
);

Type rec_assignment_summary Is Record (
  household_id dm_alumni.dim_constituent.constituent_household_account_salesforce_id%type
  , donor_id dm_alumni.dim_constituent.constituent_donor_id%type
  , sort_name dm_alumni.dim_constituent.full_name%type
  , household_primary dm_alumni.dim_constituent.household_primary_constituent_indicator%type
  , prospect_manager_user_id varchar2(1600)
  , prospect_manager_name varchar2(1600)
  , prospect_manager_business_unit varchar2(1600)
  , lagm_user_id varchar2(1600)
  , lagm_name varchar2(1600)
  , lagm_business_unit varchar2(1600)
  , ksm_manager_flag varchar2(1)
  , etl_update_date stg_alumni.ap_unit_strategy_assignment__c.etl_update_date%type
);

/*************************************************************************
Public table declarations
*************************************************************************/

--Type t_modeled_score Is Table Of modeled_score;
Type assignment_history Is Table Of rec_assignment_history;
Type assignment_summary Is Table Of rec_assignment_summary;

/*************************************************************************
Public function declarations
*************************************************************************/

-- Returns package constants
Function get_string_constant(
  const_name In varchar2 -- Name of constant to retrieve
) Return varchar2 Deterministic;

Function get_numeric_constant(
  const_name In varchar2 -- Name of constant to retrieve
) Return number Deterministic;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/


-- Return model scores
-- Cursor accessor
/*Function c_segment_extract(year In integer, month In integer, code In varchar2)
  Return t_modeled_score;*/

-- Pipelined functions
Function tbl_assignment_history
  Return assignment_history Pipelined;

Function tbl_assignment_summary
  Return assignment_summary Pipelined;

End ksm_pkg_prospect;
/
Create Or Replace Package Body ksm_pkg_prospect Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

--------------------------------------
Cursor c_assignment_history Is

  With
  
  entity As (
    Select *
    From table(dw_pkg_base.tbl_mini_entity)
  )

  Select
    entity.household_id
    , entity.household_primary
    , assign.assignee_donor_id
      As donor_id
    , entity.sort_name
    , assign.assignment_record_id
    , assign.assignment_type
    , assign.assignment_code
    , assign.start_date
    , assign.end_date 
    , assign.is_active_indicator
    , Case
        When assign.is_active_indicator = 'true'
          And (
            assign.end_date Is Null
            Or assign.end_date > cal.yesterday
          )
          Then 'Y'
        End
      As assignment_active_calc
    , assign.staff_user_salesforce_id
    , assign.staff_username
    , assign.staff_name
    , assign.assignment_business_unit
    , assign.ksm_flag
    , assign.etl_update_date
  From table(dw_pkg_base.tbl_assignments) assign
  Cross Join table(ksm_pkg_calendar.tbl_current_calendar) cal
  Inner Join entity
    On entity.donor_id = assign.assignee_donor_id
  Where assign.staff_user_salesforce_id Not In (
    -- Users to suppress
    '005Uz0000015JKoIAM' -- Data Migration User
  )
;

--------------------------------------
Cursor c_assignment_summary Is

  With

  assign As (
    Select *
    From table(ksm_pkg_prospect.tbl_assignment_history)
  )

  , pm As (
    Select * 
    From assign
    Where assign.is_active_indicator = 'true'
      And assign.assignment_code = 'PRM'
  )

  , pms As (
    Select
      household_id
      , Listagg(Distinct staff_user_salesforce_id, '; ') Within Group (Order By staff_name)
        As prospect_manager_user_id
      , Listagg(Distinct staff_name, '; ') Within Group (Order By staff_name)
        As prospect_manager_name
      , Listagg(Distinct assignment_business_unit, '; ' ) Within Group (Order By staff_name)
        As prospect_manager_business_unit
      , max(ksm_flag)
        As ksm_flag
      , max(etl_update_date)
        As etl_update_date
    From pm
    Group By household_id
  )

  , lgo As (
    Select *
    From assign
    Where assign.is_active_indicator = 'true'
      And assign.assignment_code = 'LAGM'
  )

  , lgos As (
    Select
      household_id
      , Listagg(Distinct staff_user_salesforce_id, '; ') Within Group (Order By staff_name)
        As lagm_user_id
      , Listagg(Distinct staff_name, '; ') Within Group (Order By staff_name)
        As lagm_name
      , Listagg(Distinct assignment_business_unit, '; ' ) Within Group (Order By staff_name)
        As lagm_business_unit
      , max(ksm_flag)
        As ksm_flag
      , max(etl_update_date)
        As etl_update_date
    From lgo
    Group By household_id
  )

  , donor_ids As (
    Select household_id, donor_id, sort_name, household_primary
    From pm
    Union
    Select household_id, donor_id, sort_name, household_primary
    From lgo
  )

  Select
    d.household_id
    , d.donor_id
    , d.sort_name
    , d.household_primary
    , pms.prospect_manager_user_id
    , pms.prospect_manager_name
    , pms.prospect_manager_business_unit
    , lgos.lagm_user_id
    , lgos.lagm_name
    , lgos.lagm_business_unit
    , Case
        When pms.ksm_flag = 'Y'
          Or lgos.ksm_flag = 'Y'
          Then 'Y'
        End
      As ksm_manager_flag
    , greatest(
        nvl(pms.etl_update_date, to_date('18000101', 'yyyymmdd'))
        , nvl(lgos.etl_update_date, to_date('18000101', 'yyyymmdd'))
      )
      As etl_update_date
  From donor_ids d
  Left Join pms
    On pms.household_id = d.household_id
  Left Join lgos
    On lgos.household_id = d.household_id
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
  val varchar2(100);
  var varchar2(100);
  
  Begin
    -- If const_name doesn't include ksm_pkg, prepend it
    If substr(lower(const_name), 1, length(pkg_name)) <> pkg_name
      Then var := pkg_name || '.' || const_name;
    Else
      var := const_name;
    End If;
    -- Run command
    Execute Immediate
      'Begin :val := ' || var || '; End;'
      Using Out val;
      Return val;
  End;

Function get_numeric_constant(const_name In varchar2)
  Return number Deterministic Is
  -- Declarations
  val number;
  var varchar2(100);
  
  Begin
    -- If const_name doesn't include ksm_pkg, prepend it
    If substr(lower(const_name), 1, length(pkg_name)) <> pkg_name
      Then var := pkg_name || '.' || const_name;
    Else
      var := const_name;
    End If;
    -- Run command
    Execute Immediate
      'Begin :val := ' || var || '; End;'
      Using Out val;
      Return val;
  End;

/*************************************************************************
Pipelined functions
*************************************************************************/

--------------------------------------
Function tbl_assignment_history
  Return assignment_history Pipelined As
  -- Declarations
  assn assignment_history;
  
  Begin
    Open c_assignment_history;
      Fetch c_assignment_history Bulk Collect Into assn;
    Close c_assignment_history;
    For i in 1..(assn.count) Loop
      Pipe row(assn(i));
    End Loop;
    Return;
  End;

--------------------------------------
Function tbl_assignment_summary
  Return assignment_summary Pipelined As
  -- Declarations
  asm assignment_summary;
  
  Begin
    Open c_assignment_summary;
      Fetch c_assignment_summary Bulk Collect Into asm;
    Close c_assignment_summary;
    For i in 1..(asm.count) Loop
      Pipe row(asm(i));
    End Loop;
    Return;
  End;

End ksm_pkg_prospect;
/
