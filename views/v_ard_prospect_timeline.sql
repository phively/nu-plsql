Create Or Replace View v_ard_prospect_timeline As

With
/* Prospect assignments and strategies over time */

-- PM assignments
assignments As (
  Select
    assignment.prospect_id
    , prospect_entity.id_number
    , entity.report_name
    , prospect_entity.primary_ind
    , 'Assignment' As type
    , assignment.assignment_id As id
    , assignment.start_date
    , assignment.stop_date
    , Case When assignment.active_ind = 'Y' Then 'Active' Else 'Inactive' End As status
    , assignment.assignment_id_number As owner_id
    , assignee.report_name As owner_report_name
    , assignment.xcomment As description
  From assignment
  Inner Join entity assignee On assignee.id_number = assignment.assignment_id_number
  Inner Join prospect_entity On prospect_entity.prospect_id = assignment.prospect_id
  Inner Join entity On entity.id_number = prospect_entity.id_number
  Where assignment_type In ('PP', 'PM', 'AF') -- Program Manager (PP), Prospect Manager (PM), Annual Fund Officer (AF)
)

-- University strategies
, strategies As (
  Select
    task.prospect_id
    , prospect_entity.id_number
    , entity.report_name
    , prospect_entity.primary_ind
    , 'Strategy' As type
    , task.task_id
    , task.sched_date
    , task.completed_date
    , tms_ts.short_desc As status
    , task.owner_id_number
    , owner.report_name As owner_report_name
    , task_description
  From task
  Inner Join tms_task_status tms_ts On tms_ts.task_status_code = task.task_status_code
  Inner Join prospect_entity On prospect_entity.prospect_id = task.prospect_id
  Inner Join entity On entity.id_number = prospect_entity.id_number
  Inner Join entity owner On owner.id_number = task.owner_id_number
  Where task_code = 'ST' -- University Overall Strategy
    And task.task_status_code <> 5 -- Not Cancelled (5) status
)

-- Main query
Select assignments.* From assignments
Union
Select strategies.* From strategies
