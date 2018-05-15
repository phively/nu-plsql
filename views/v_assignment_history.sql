/**************************************
NU historical assignments, including inactive
**************************************/

Create Or Replace View v_assignment_history As

Select
  assignment.prospect_id
  , prospect_entity.id_number
  , entity.report_name
  , prospect_entity.primary_ind
  , assignment.assignment_id
  , assignment.assignment_type
  , assignment.proposal_id
  , tms_at.short_desc As assignment_type_desc
  , trunc(assignment.start_date) As start_date
  , trunc(assignment.stop_date) As stop_date
  -- Calculated start date: use date_added if start_date unavailable
  , Case
      When assignment.start_date Is Not Null Then trunc(assignment.start_date)
      -- For proposal managers (PA), use start date of the associated proposal
      When assignment.start_date Is Null And assignment.assignment_type = 'PA' Then 
        Case
          When proposal.start_date Is Not Null Then trunc(proposal.start_date)
          Else trunc(proposal.date_added)
        End
      -- Fallback
      Else trunc(assignment.date_added)
    End As start_dt_calc
  -- Calculated stop date: use date_modified if stop_date unavailable
  , Case
      When assignment.stop_date Is Not Null Then trunc(assignment.stop_date)
      -- For proposal managers (PA), use stop date of the associated proposal
      When assignment.stop_date Is Null And assignment.assignment_type = 'PA' Then 
        Case
          When proposal.stop_date Is Not Null Then trunc(proposal.stop_date)
          When proposal.active_ind <> 'Y' Then trunc(proposal.date_modified)
          Else NULL
        End
      -- For inactive assignments with null date use date_modified
      When assignment.active_ind <> 'Y' Then trunc(assignment.date_modified)
      Else NULL
    End As stop_dt_calc
  -- Active or inactive assignment
  , assignment.active_ind As assignment_active_ind
  -- Active or inactive computation
  , Case
      When assignment.active_ind = 'Y' And proposal.active_ind = 'Y' Then 'Active'
      When assignment.active_ind = 'Y' And proposal.active_ind = 'N' Then 'Inactive'
      When assignment.active_ind = 'Y' And assignment.stop_date Is Null Then 'Active'
      When assignment.active_ind = 'Y' And assignment.stop_date > cal.yesterday Then 'Active'
      Else 'Inactive'
    End As assignment_active_calc
  , assignment.assignment_id_number
  , assignee.report_name As assignment_report_name
  , assignment.xcomment As description
From assignment
Cross Join v_current_calendar cal
Inner Join tms_assignment_type tms_at On tms_at.assignment_type = assignment.assignment_type
Left Join entity assignee On assignee.id_number = assignment.assignment_id_number
Left Join prospect_entity On prospect_entity.prospect_id = assignment.prospect_id
Left Join entity On entity.id_number = prospect_entity.id_number
Left Join proposal On proposal.proposal_id = assignment.proposal_id
