-- Create Or Replace View vt_go_portfolio_time_series As

With

-- Assignment history
assignments As (
  Select
    rownum As rn -- Number each row; important for assn_dense
    , prospect_id
    , id_number
    , report_name
    , assignment_type
    , assignment_type_desc
    , start_dt_calc As start_dt
    -- Fill in the end of this month if there is no stop_dt_calc
    , Case When stop_dt_calc Is Null Then last_day(cal.today) Else stop_dt_calc End
      As stop_dt
    -- Number of months from start_dt_calc to stop_dt_calc, rounded up
    , ceil(
        months_between(last_day(Case When stop_dt_calc Is Null Then last_day(cal.today) Else stop_dt_calc End)
        , trunc(start_dt_calc, 'month'))
      ) As nmonths
    , assignment_active_calc
    , assignment_id_number
    , assignment_report_name
  From v_assignment_history
  Cross Join rpt_pbh634.v_current_calendar cal
  Where assignment_type In ('PM', 'PP') -- PM and PPM only
    And primary_ind = 'Y' -- Primary prospect entity only
/****** FOR TESTING -- REMOVE LATER ******/
And assignment_id_number = '0000549376'
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
    -- Take either 1 month in the future from last row, or the stop_dt, whichever is smaller
    , least(
        Case
          When level = 1 Then start_dt -- First filled_date is start_dt
          When level = nmonths Then stop_dt -- Last filled date is stop_dt
          Else trunc(add_months(start_dt, level - 1), 'month') -- Subsequent are 1st of month after previous row
        End
        , stop_dt
      ) As filled_date
    , assignment_active_calc
    , assignment_id_number
    , assignment_report_name
  From assignments
  Connect By
    level <= nmonths -- Hierarchical query
    And Prior rn = rn -- Restart when prospect/manager changes, since each prospect/pm combo has its own row
    And Prior dbms_random.value != 1 -- Always false, as 0 < dbms_random.value < 1
)

-- Stage history
, stage_history As (
  Select
    prospect_id
    , tms_stage.stage_code
    , tms_stage.short_desc As stage_desc
    , trunc(stage_date) As stage_start_dt
    -- Take the day before the next stage began as the current stage's stop date
    -- If null, fill in end of this month
    , nvl(
        min(trunc(stage_date))
          Over(Partition By prospect_id Order By stage_date Asc Rows Between 1 Following And Unbounded Following) - 1
        , last_day(cal.today)
      ) As stage_stop_dt
  From stage
  Cross Join rpt_pbh634.v_current_calendar cal
  Inner Join tms_stage On stage.stage_code = tms_stage.stage_code
  Where program_code Is Null -- Main prospect stage only, not program stages
    And proposal_id Is Null -- Ignore proposal stages
)

-- Main query
Select Distinct
  asn.*
  , stg_hist.stage_desc
From assn_dense asn
Left Join stage_history stg_hist
  On stg_hist.prospect_id = asn.prospect_id
  And asn.filled_date Between stg_hist.stage_start_dt And stg_hist.stage_stop_dt
