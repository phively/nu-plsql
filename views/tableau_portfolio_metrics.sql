-- Create Or Replace View vt_go_portfolio_time_series As

With

-- '0000549376'

-- Assignment history
assignments As (
  Select
    prospect_id
    , id_number
    , report_name
    , assignment_type
    , assignment_type_desc
    , start_dt_calc
    , stop_dt_calc
    , Case When stop_dt_calc Is Null Then last_day(cal.today) Else stop_dt_calc End
      As stop_dt_calc_filled
    , assignment_active_calc
    , assignment_id_number
    , assignment_report_name
  From v_assignment_history
  Cross Join rpt_pbh634.v_current_calendar cal
  Where assignment_type In ('PM', 'PP') -- PM and PPM only
    And primary_ind = 'Y'
/****** FOR TESTING -- REMOVE LATER ******/
And assignment_id_number = '0000549376'
)

-- 
, assn_numbered As (
  Select
    rownum As rn
    , prospect_id
    , id_number
    , report_name
    , assignment_type
    , assignment_type_desc
    , start_dt_calc As start_dt
    , stop_dt_calc_filled As stop_dt
    , ceil(months_between(last_day(stop_dt_calc_filled), trunc(start_dt_calc, 'month')))
      As nmonths
    , assignment_active_calc
    , assignment_id_number
    , assignment_report_name
  From assignments
)

-- Assignment history by month between start_dt and stop_dt
, assn_dense As (
  Select
    prospect_id
    , id_number
    , report_name
    , assignment_type
    , assignment_type_desc
    , start_dt
    , stop_dt
    -- Take either 1 month in the future from last row, or the stop_dt_calc, whichever is smaller
    , least(
        Case When level = 1 Then start_dt Else trunc(add_months(start_dt, level - 1), 'month') End
        , stop_dt
      ) As filled_date
    , assignment_active_calc
    , assignment_id_number
    , assignment_report_name
  From assn_numbered
  Connect By
    level <= nmonths
    And Prior rn = rn
    And Prior dbms_random.value != 1 -- Always false; 0 < dbms_random.value < 1
)

-- Stage history
, stage_history As (
  Select
    prospect_id
    , tms_stage.stage_code
    , tms_stage.short_desc
    , trunc(stage_date) As stage_start_dt
    , min(trunc(stage_date)) -- Take the day before the next stage began as the current stage's stop date
        Over(Partition By prospect_id Order By stage_date Asc Range Between 1 Following And Unbounded Following) - 1
      As stage_stop_dt
  From stage
  Inner Join tms_stage On stage.stage_code = tms_stage.stage_code
    And tms_stage.status_code = 'A' -- Only want 
  Where program_code Is Null -- Main prospect stage only, not program stages
)

-- Main query
Select *
From assn_dense
