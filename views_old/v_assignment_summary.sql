Create Or Replace View v_assignment_summary As

With
-- View creating concatenated assignment strings, including both MG and AF officers, from v_assignment_history

-- Prospect assignments
assign As (
  Select Distinct
    ah.prospect_id
    , ah.id_number
    , ah.assignment_id_number
    , ah.assignment_report_name
    , ah.assignment_type
    , Case When gos.id_number Is Not Null Then 'Y' End
      As curr_ksm_assignment
  From v_assignment_history ah
  Left Join table(ksm_pkg_tmp.tbl_frontline_ksm_staff) gos
    On gos.id_number = ah.assignment_id_number
    And gos.former_staff Is Null
  Where ah.assignment_active_calc = 'Active' -- Active assignments only
    And assignment_type In
      -- Program Manager (PP), Prospect Manager (PM), Leadership Giving Officer (LG)
      -- Annual Fund Officer (AF) is defunct as of 2020-04-14; removed
      ('PP', 'PM', 'LG')
    And ah.assignment_report_name Is Not Null -- Real managers only
)

-- Prospect manager
, pm As (
  Select Distinct
    prospect_id
    , Listagg(assignment_id_number, ';  ') Within Group (Order By assignment_report_name) As prospect_manager_id
    , Listagg(assignment_report_name, ';  ') Within Group (Order By assignment_report_name) As prospect_manager
  From ( -- Dedupe prospect IDs with multiple associated entities
    Select Distinct
      prospect_id
      , assignment_id_number
      , assignment_report_name
      , assignment_type
    From assign
  )
  Where prospect_id Is Not Null
    And assignment_type = 'PM'
  Group By prospect_id
)

-- LGO
, lgo As (
  Select Distinct
    id_number
    , Listagg(assignment_id_number, ';  ') Within Group (Order By assignment_report_name) As lgo_ids
    , Listagg(assignment_report_name, ';  ') Within Group (Order By assignment_report_name) As lgos
  From ( -- Dedupe prospect IDs with multiple associated entities
    Select Distinct
      id_number
      , assignment_id_number
      , assignment_report_name
      , assignment_type
    From assign
  )
  Where assignment_type = 'LG'
  Group By id_number
)

-- Concatenate by prospect ID
, assign_conc As (
  Select Distinct
    prospect_id
    , Listagg(assignment_id_number, ';  ') Within Group (Order By assignment_report_name) As manager_ids
    , Listagg(assignment_report_name, ';  ') Within Group (Order By assignment_report_name) As managers
    , max(curr_ksm_assignment) As curr_ksm_manager
  From ( -- Dedupe prospect IDs with multiple associated entities
    Select Distinct
      prospect_id
      , assignment_id_number
      , assignment_report_name
      , curr_ksm_assignment
    From assign
  )
  Where prospect_id Is Not Null
  Group By prospect_id
)

-- Concatenate by entity ID
, assign_conc_entity As (
  Select Distinct
    id_number
    , Listagg(assignment_report_name, ';  ') Within Group (Order By assignment_report_name) As managers
    , Listagg(assignment_id_number, ';  ') Within Group (Order By assignment_report_name) As manager_ids
    , max(curr_ksm_assignment) As curr_ksm_manager
  From assign
  Where prospect_id Is Null
  Group By id_number
)

-- Main query
Select Distinct
  assign.prospect_id
  , assign.id_number
  -- Concatenated managers on prospect or entity ID as appropriate
  , pm.prospect_manager_id
  , pm.prospect_manager
  , lgo.lgo_ids
  , lgo.lgos
  , Case
      When assign_conc.manager_ids Is Not Null
        Then assign_conc.manager_ids
      Else assign_conc_entity.manager_ids
      End
    As manager_ids
  , Case
      When assign_conc.manager_ids Is Not Null
        Then assign_conc.managers
      Else assign_conc_entity.managers
      End
    As managers
  , Case
      When assign_conc.manager_ids Is Not Null
        Then assign_conc.curr_ksm_manager
      Else assign_conc_entity.curr_ksm_manager
      End
    As curr_ksm_manager
From assign
Left Join pm
  On pm.prospect_id = assign.prospect_id
Left Join lgo
  On lgo.id_number = assign.id_number
Left Join assign_conc
  On assign_conc.prospect_id = assign.prospect_id
Left Join assign_conc_entity
  On assign_conc_entity.id_number = assign.id_number
;
