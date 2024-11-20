Create Or Replace Package ksm_pkg_prospect Is

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_prospect';

-- Model segments
seg_af_10k Constant segment.segment_code%type := 'KMAA_'; -- AF $10K model pattern
seg_mg_id Constant segment.segment_code%type := 'KMID_'; -- MG identification model pattern
seg_mg_pr Constant segment.segment_code%type := 'KMPR_'; -- MG prioritization model

-- Most recent models
seg_af_10k_mo Constant integer := 9;
seg_af_10k_yr Constant integer := 2022;
seg_mg_mo Constant integer := 9;
seg_mg_yr Constant Integer := 2024;

/*************************************************************************
Public type declarations
*************************************************************************/

Type university_strategy Is Record (
  prospect_id prospect.prospect_id%type
  , university_strategy task.task_description%type
  , strategy_sched_date task.sched_date%type
  , strategy_responsible varchar2(1024)
  , strategy_modified_date task.sched_date%type
  , strategy_modified_name entity.report_name%type
);

Type numeric_capacity Is Record (
    rating_code tms_rating.rating_code%type
    , rating_desc tms_rating.short_desc%type
    , numeric_rating number
    , numeric_bin number
);

Type modeled_score Is Record (
  id_number segment.id_number%type
  , segment_year segment.segment_year%type
  , segment_month segment.segment_month%type
  , segment_code segment.segment_code%type
  , description segment_header.description%type
  , score segment.xcomment%type
);

Type prospect_entity_active Is Record (
  prospect_id prospect.prospect_id%type
  , id_number entity.id_number%type
  , report_name entity.report_name%type
  , primary_ind prospect_entity.primary_ind%type
);

Type assignment_history Is Record (
  prospect_id prospect.prospect_id%type
  , id_number entity.id_number%type
  , report_name entity.report_name%type
  , primary_ind varchar2(1)
  , assignment_id assignment.assignment_id%type
  , assignment_type assignment.assignment_type%type
  , proposal_id proposal.proposal_id%type
  , assignment_type_desc tms_assignment_type.short_desc%type
  , start_date assignment.start_date%type
  , stop_date assignment.stop_date%type
  , start_dt_calc assignment.start_date%type
  , stop_dt_calc assignment.stop_date%type
  , assignment_active_ind assignment.active_ind%type
  , assignment_active_calc varchar2(8)
  , assignment_id_number assignment.assignment_id_number%type
  , assignment_report_name entity.report_name%type
  , committee_code committee_header.committee_code%type
  , committee_desc committee_header.short_desc%type
  , description assignment.xcomment%type
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type t_university_strategy Is Table Of university_strategy;
Type t_numeric_capacity Is Table Of numeric_capacity;
Type t_modeled_score Is Table Of modeled_score;
Type t_prospect_entity_active Is Table Of prospect_entity_active;
Type t_assignment_history Is Table Of assignment_history;

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


-- Take entity ID and return officer or evaluation rating bin from nu_prs_trp_prospect
Function get_prospect_rating_numeric(
  id In varchar2
) Return number;

-- Binned version of the results from get_prospect_rating_numeric
Function get_prospect_rating_bin(
  id In varchar2
) Return number;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

-- Return pipelined table of active prospect entities
Function tbl_prospect_entity_active
  Return t_prospect_entity_active Pipelined;

-- Return pipelined tasks (including overall strategy)
Function tbl_university_strategy
  Return t_university_strategy Pipelined;

-- Return pipelined numeric ratings
Function tbl_numeric_capacity_ratings
  Return t_numeric_capacity Pipelined;

-- Return model scores
-- Cursor accessor
Function c_segment_extract(year In integer, month In integer, code In varchar2)
  Return t_modeled_score;

-- Pipelined functions
Function tbl_assignment_history
  Return t_assignment_history Pipelined;

Function tbl_model_af_10k(
  model_year In integer Default seg_af_10k_yr
  , model_month In integer Default seg_af_10k_mo
) Return t_modeled_score Pipelined;

Function tbl_model_mg_identification(
  model_year In integer Default seg_mg_yr
  , model_month In integer Default seg_mg_mo
) Return t_modeled_score Pipelined;

Function tbl_model_mg_prioritization(
  model_year In integer Default seg_mg_yr
  , model_month In integer Default seg_mg_mo
) Return t_modeled_score Pipelined;

/*************************************************************************
Public cursors -- data definitions
*************************************************************************/

-- Definition of numeric capacity ratings
Cursor c_numeric_capacity_ratings Is
  With
  -- Extract numeric ratings from tms_rating.short_desc
  numeric_rating As (
    Select
      rating_code
      , short_desc As rating_desc
      , Case
          When rating_code = 0 Then 0
          Else ksm_pkg_utility.get_number_from_dollar(short_desc) / 1000000
        End As numeric_rating
    From tms_rating
  )
  -- Main query
  Select
    rating_code
    , rating_desc
    , numeric_rating
    , Case
        When numeric_rating >= 10 Then 10
        When numeric_rating = 0.25 Then 0.1
        When numeric_rating < 0.1 Then 0
        Else numeric_rating
      End As numeric_bin
  From numeric_rating
  ;

-- Definition of university strategy
Cursor c_university_strategy Is
  With
  -- Pull latest upcoming University Overall Strategy
  uos_ids As (
    Select
      prospect_id
      , min(task_id) keep(dense_rank First Order By sched_date Desc, task.task_id Asc) As task_id
    From task
    Where prospect_id Is Not Null -- Prospect strategies only
      And task_code = 'ST' -- University Overall Strategy
      And task_status_code Not In (4, 5) -- Not Completed (4) or Cancelled (5) status
    Group By prospect_id
  )
  , next_uos As (
    Select
      task.prospect_id
      , task.task_id
      , task.task_description As university_strategy
      , task.sched_date As strategy_sched_date
      , trunc(task.date_modified) As strategy_modified_date
      , task.operator_name As strategy_modified_netid
    From task
    Inner Join uos_ids
      On uos_ids.prospect_id = task.prospect_id
      And uos_ids.task_id = task.task_id
  )
  , netids As (
    Select
      ids.other_id
      , ids.id_number
      , entity.report_name
    From ids
    Inner Join entity
      On entity.id_number = ids.id_number
    Where ids_type_code = 'NET'
  )
  -- Append task responsible data to first upcoming UOS
  , next_uos_resp As (
    Select
      uos.prospect_id
      , uos.university_strategy
      , uos.strategy_sched_date
      , uos.strategy_modified_date
      , uos.strategy_modified_netid
      , netids.report_name As strategy_modified_name
      , Listagg(tr.id_number, ', ') Within Group (Order By tr.date_added Desc)
        As strategy_responsible_id
      , Listagg(entity.pref_mail_name, ', ') Within Group (Order By tr.date_added Desc)
        As strategy_responsible
    From next_uos uos
    Left Join netids
      On netids.other_id = uos.strategy_modified_netid
    Left Join task_responsible tr On tr.task_id = uos.task_id
    Left Join entity On entity.id_number = tr.id_number
    Group By
      uos.prospect_id
      , uos.university_strategy
      , uos.strategy_sched_date
      , uos.strategy_modified_date
      , uos.strategy_modified_netid
      , netids.report_name
  )
  -- Main query: uses nu_prs_trp_prospect fields if available
  Select Distinct
    uos.prospect_id
    , Case
        When prs.strategy_description Is Not Null Then prs.strategy_description
        Else uos.university_strategy
      End As university_strategy
    , Case
        When prs.strategy_description Is Not Null Then ksm_pkg_utility.to_date2(prs.strategy_date, 'mm/dd/yyyy')
        Else uos.strategy_sched_date
      End As strategy_sched_date
    , Case
        When prs.strategy_description Is Not Null Then task_resp
        Else uos.strategy_responsible
      End As strategy_responsible
    , uos.strategy_modified_date
    , uos.strategy_modified_name
  From next_uos_resp uos
  Left Join advance_nu.nu_prs_trp_prospect prs On prs.prospect_id = uos.prospect_id
  ;

-- Prospect entity table filtered for active prospects only
Cursor c_prospect_entity_active Is
  Select
    pe.prospect_id
    , pe.id_number
    , e.report_name
    , pe.primary_ind
  From prospect_entity pe
  Inner Join prospect p On p.prospect_id = pe.prospect_id
  Inner Join entity e On e.id_number = pe.id_number
  Where p.active_ind = 'Y' -- Active only
  ;

-- Extract from the segment table given the passed year, month, and segment code
Cursor segment_extract(year In integer, month In integer, code In varchar2) Is
  Select
    s.id_number
    , s.segment_year
    , s.segment_month
    , s.segment_code
    , sh.description
    , s.xcomment As score
  From segment s
  Inner Join segment_header sh On sh.segment_code = s.segment_code
  Where s.segment_code Like code
    And ksm_pkg_utility.to_number2(s.segment_year) = year
    And ksm_pkg_utility.to_number2(s.segment_month) = month
  ;

End ksm_pkg_prospect;
/
Create Or Replace Package Body ksm_pkg_prospect Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

Cursor c_assignment_history Is
  With

  -- Active prospects from prospect_entity
  active_pe As (
    Select
      pre.id_number
      , pre.prospect_id
      , pre.primary_ind
    From prospect_entity pre
    Inner Join prospect p On p.prospect_id = pre.prospect_id
    Where p.active_ind = 'Y'
  )

  Select
      -- Display prospect depending on whether prospect_id is filled in
      Case
        When trim(assignment.prospect_id) Is Not Null Then assignment.prospect_id
        When trim(active_pe.prospect_id) Is Not Null Then active_pe.prospect_id
      End As prospect_id
    -- Display entity depending on whether id_number is filled in
    , Case
        When trim(assignment.id_number) Is Not Null Then assignment.id_number
        When prospect_entity.id_number Is Not Null Then prospect_entity.id_number
      End As id_number
    , Case
        When trim(assignment.id_number) Is Not Null Then entity.report_name
        When prospect_entity.id_number Is Not Null Then pe_entity.report_name
      End As report_name
    , Case
        When trim(assignment.prospect_id) Is Not Null Then prospect_entity.primary_ind
        When trim(active_pe.prospect_id) Is Not Null Then active_pe.primary_ind
      End As primary_ind
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
    , assignment.committee_code
    , committee_header.short_desc As committee_desc
    , assignment.xcomment As description
  From assignment
  Cross Join v_current_calendar cal
  Inner Join tms_assignment_type tms_at On tms_at.assignment_type = assignment.assignment_type
  Left Join entity On entity.id_number = assignment.id_number
  Left Join entity assignee On assignee.id_number = assignment.assignment_id_number
  Left Join prospect_entity On prospect_entity.prospect_id = assignment.prospect_id
  Left Join active_pe On active_pe.id_number = assignment.id_number
  Left Join entity pe_entity On pe_entity.id_number = prospect_entity.id_number
  Left Join proposal On proposal.proposal_id = assignment.proposal_id
  Left Join committee_header On committee_header.committee_code = assignment.committee_code
  ;

/*************************************************************************
Functions
*************************************************************************/

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

-- Convert rating to numeric amount
Function get_prospect_rating_numeric(id In varchar2)
  Return number Is
  -- Delcarations
  numeric_rating number;
  
  Begin
    -- Convert officer rating or evaluation rating into numeric values
    Select Distinct
      Case
        -- If officer rating exists
        When officer_rating <> ' ' Then
          Case
            When trim(substr(officer_rating, 1, 2)) = 'H' Then 0 -- Under $10K is 0
            Else ksm_pkg_utility.get_number_from_dollar(officer_rating) / 1000000 -- Everything else in millions
          End
        -- Else use evaluation rating
        When evaluation_rating <> ' ' Then
          Case
            When trim(substr(evaluation_rating, 1, 2)) = 'H' Then 0
            Else ksm_pkg_utility.get_number_from_dollar(evaluation_rating) / 1000000 -- Everthing else in millions
          End
        Else 0
      End
    Into numeric_rating
    From nu_prs_trp_prospect
    Where id_number = id;
    Return numeric_rating;
  End;

-- Binned numeric prospect ratings
Function get_prospect_rating_bin(id In varchar2)
  Return number Is
  -- Delcarations
  numeric_rating number;
  numeric_bin number;
  
  Begin
    -- Convert officer rating or evaluation rating into numeric values
    numeric_rating := get_prospect_rating_numeric(id);
    -- Bin numeric_rating amount
    Select
      Case
        When numeric_rating >= 10 Then 10
        When numeric_rating = 0.25 Then 0.1
        When numeric_rating < 0.1 Then 0
        Else numeric_rating
      End
    Into numeric_bin
    From DUAL;
    Return numeric_bin;
  End;

/*************************************************************************
Pipelined functions
*************************************************************************/

-- Pipelined function returning prospect entity table filtered for active prospects
Function tbl_prospect_entity_active
  Return t_prospect_entity_active Pipelined As
  -- Declarations
  pe t_prospect_entity_active;
    
  Begin
    Open c_prospect_entity_active;
      Fetch c_prospect_entity_active Bulk Collect Into pe;
    Close c_prospect_entity_active;
    For i in 1..(pe.count) Loop
      Pipe row(pe(i));
    End Loop;
    Return;
  End;

-- Pipelined function returning current university strategies (per c_university_strategy)
Function tbl_university_strategy
  Return t_university_strategy Pipelined As
  -- Declarations
  task t_university_strategy;
    
  Begin
    Open c_university_strategy;
      Fetch c_university_strategy Bulk Collect Into task;
    Close c_university_strategy;
    For i in 1..(task.count) Loop
      Pipe row(task(i));
    End Loop;
    Return;
  End;

-- Pipelined function returning numeric capacity and binned capacity
Function tbl_numeric_capacity_ratings
  Return t_numeric_capacity Pipelined As
  -- Declarations
  caps t_numeric_capacity;
  
  Begin
    Open c_numeric_capacity_ratings;
      Fetch c_numeric_capacity_ratings Bulk Collect Into caps;
    Close c_numeric_capacity_ratings;
    For i in 1..(caps.count) Loop
      Pipe row(caps(i));
    End Loop;
    Return;
  End;

-- Pipelined function returning assignment history
Function tbl_assignment_history
  Return t_assignment_history Pipelined As
  -- Declarations
  assn t_assignment_history;
  
  Begin
    Open c_assignment_history;
      Fetch c_assignment_history Bulk Collect Into assn;
    Close c_assignment_history;
    For i in 1..(assn.count) Loop
      Pipe row(assn(i));
    End Loop;
    Return;
  End;

-- Generic function returning matching segment(s)
Function c_segment_extract(year In integer, month In integer, code In varchar2)
Return t_modeled_score As
-- Declarations
score t_modeled_score;

-- Return table results
Begin
    Open segment_extract(year => year, month => month, code => code);
    Fetch segment_extract Bulk Collect Into score;
    Close segment_extract;
    Return score;
End;

-- AF 10K model
Function tbl_model_af_10k(model_year In integer, model_month In integer)
Return t_modeled_score Pipelined As
-- Declarations
score t_modeled_score;

Begin
    score := c_segment_extract(year => model_year, month => model_month, code => seg_af_10k);
    For i in 1..(score.count) Loop
    Pipe row(score(i));
    End Loop;
    Return;
End;

-- MG identification model
Function tbl_model_mg_identification(model_year In integer, model_month In integer)
Return t_modeled_score Pipelined As
-- Declarations
score t_modeled_score;

Begin
    Open segment_extract(year => model_year, month => model_month, code => seg_mg_id);
    Fetch segment_extract Bulk Collect Into score;
    Close segment_extract;
    For i in 1..(score.count) Loop
    Pipe row(score(i));
    End Loop;
    Return;
End;

-- MG prioritization model
Function tbl_model_mg_prioritization(model_year In integer, model_month In integer)
Return t_modeled_score Pipelined As
-- Declarations
score t_modeled_score;

Begin
    Open segment_extract(year => model_year, month => model_month, code => seg_mg_pr);
    Fetch segment_extract Bulk Collect Into score;
    Close segment_extract;
    For i in 1..(score.count) Loop
    Pipe row(score(i));
    End Loop;
    Return;
End;

End ksm_pkg_prospect;
/
