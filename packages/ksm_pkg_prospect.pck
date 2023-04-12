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
seg_mg_mo Constant integer := 10;
seg_mg_yr Constant Integer := 2019;

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

Type prospect_categories Is Record (
  prospect_id prospect.prospect_id%type
  , primary_ind prospect_entity.primary_ind%type
  , id_number entity.id_number%type
  , report_name entity.report_name%type
  , person_or_org entity.person_or_org%type
  , prospect_category_code tms_prospect_category.prospect_category_code%type
  , prospect_category tms_prospect_category.short_desc%type
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type t_university_strategy Is Table Of university_strategy;
Type t_numeric_capacity Is Table Of numeric_capacity;
Type t_modeled_score Is Table Of modeled_score;
Type t_prospect_entity_active Is Table Of prospect_entity_active;
Type t_prospect_categories Is Table Of prospect_categories;

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

-- Return pipelined table of Top 150/300 KSM prospects
Function tbl_entity_top_150_300
  Return t_prospect_categories Pipelined;

-- Return pipelined tasks (including overall strategy)
Function tbl_university_strategy
  Return t_university_strategy Pipelined;

-- Return pipelined numeric ratings
Function tbl_numeric_capacity_ratings
  Return t_numeric_capacity Pipelined;

-- Return pipelined model scores
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
Cursor ct_numeric_capacity_ratings Is
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

-- Definition of top 150/300 KSM campaign prospects
Cursor c_entity_top_150_300 Is
  Select
    pc.prospect_id
    , pe.primary_ind
    , pe.id_number
    , entity.report_name
    , entity.person_or_org
    , pc.prospect_category_code
    , tms_pc.short_desc As prospect_category
  From prospect_entity pe
  Inner Join prospect_category pc On pc.prospect_id = pe.prospect_id
  Inner Join entity On pe.id_number = entity.id_number
  Inner Join tms_prospect_category tms_pc On tms_pc.prospect_category_code = pc.prospect_category_code
  Where pc.prospect_category_code In ('KT1', 'KT3')
  Order By pe.prospect_id Asc, pe.primary_ind Desc
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
  -- Main query; uses nu_prs_trp_prospect fields if available
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

End ksm_pkg_prospect;
/
Create Or Replace Package Body ksm_pkg_prospect Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

-- Extract from the segment table given the passed year, month, and segment code
Cursor c_segment_extract(year In integer, month In integer, code In varchar2) Is
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

-- Pipelined function returning Kellogg top 150/300 Campaign prospects
-- Coded in Prospect Categories; see cursor for definition 
Function tbl_entity_top_150_300
  Return t_prospect_categories Pipelined As
  -- Declarations
  prospects t_prospect_categories;
  
  Begin
    Open c_entity_top_150_300;
      Fetch c_entity_top_150_300 Bulk Collect Into prospects;
    Close c_entity_top_150_300;
    For i in 1..(prospects.count) Loop
      Pipe row(prospects(i));
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
    Open ct_numeric_capacity_ratings;
      Fetch ct_numeric_capacity_ratings Bulk Collect Into caps;
    Close ct_numeric_capacity_ratings;
    For i in 1..(caps.count) Loop
      Pipe row(caps(i));
    End Loop;
    Return;
  End;

-- Generic function returning matching segment(s)
Function segment_extract(year In integer, month In integer, code In varchar2)
Return t_modeled_score As
-- Declarations
score t_modeled_score;

-- Return table results
Begin
    Open c_segment_extract(year => year, month => month, code => code);
    Fetch c_segment_extract Bulk Collect Into score;
    Close c_segment_extract;
    Return score;
End;

-- AF 10K model
Function tbl_model_af_10k(model_year In integer, model_month In integer)
Return t_modeled_score Pipelined As
-- Declarations
score t_modeled_score;

Begin
    score := segment_extract(year => model_year, month => model_month, code => seg_af_10k);
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
    Open c_segment_extract(year => model_year, month => model_month, code => seg_mg_id);
    Fetch c_segment_extract Bulk Collect Into score;
    Close c_segment_extract;
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
    Open c_segment_extract(year => model_year, month => model_month, code => seg_mg_pr);
    Fetch c_segment_extract Bulk Collect Into score;
    Close c_segment_extract;
    For i in 1..(score.count) Loop
    Pipe row(score(i));
    End Loop;
    Return;
End;

End ksm_pkg_prospect;
/
