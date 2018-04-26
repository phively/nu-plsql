-- Create Or Replace View vt_go_portfolio_time_series As

With

-- Custom parameters/definitions
params As (
  Select
    100000 As mg_level -- Minimum amount for a major gift
  From DUAL
)

-- Assignment history
, assignments As (
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
      ) As months_assigned
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
          When level = 1 Then trunc(start_dt, 'month') -- First filled_date is start_dt month
          When level = months_assigned Then trunc(stop_dt, 'month') -- Last filled date is stop_dt month
          Else trunc(add_months(start_dt, level - 1), 'month') -- Subsequent are 1st of month after previous row
        End
        , stop_dt
      ) As filled_date
    , level As months_assigned
    , assignment_active_calc
    , assignment_id_number
    , assignment_report_name
  From assignments
  Connect By
    level <= months_assigned -- Hierarchical query
    And Prior rn = rn -- Restart when prospect/manager changes, since each prospect/pm combo has its own row
    And Prior dbms_random.value != 1 -- Always true, as 0 < dbms_random.value < 1
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

-- Evaluation rating
, eval_history As (
  Select
    e.id_number
    , e.prospect_id
    , e.evaluation_type
    , tet.short_desc As eval_type_desc
    , trunc(e.evaluation_date) As eval_start_dt
    -- Computed stop date for most recent active eval is just the end of this month
    -- For inactive evals, take the day before the next rating as the current rating's stop date
    -- If null, fill in modified date
    , Case
        When active_ind = 'Y' And evaluation_date = max(evaluation_date)
          Over(Partition By Case When prospect_id Is Not Null Then to_char(prospect_id) Else id_number End)
          Then last_day(cal.today)
        Else nvl(
          min(trunc(evaluation_date))
            Over(Partition By Case When prospect_id Is Not Null Then to_char(prospect_id) Else id_number End
              Order By evaluation_date Asc Rows Between 1 Following And Unbounded Following) - 1
          , trunc(e.date_modified)
        )
      End As eval_stop_dt
    , e.active_ind
    , e.rating_code
    , trt.short_desc As rating_desc
    , e.xcomment As rating_comment
    -- Numeric value of lower end of eval rating range, using regular expressions
    , Case
        When trt.rating_code = 0 Then 0 -- Under $10K becomes 0
        Else rpt_pbh634.ksm_pkg.get_number_from_dollar(trt.short_desc)
      End As rating_lower_bound
  From evaluation e
  Cross Join rpt_pbh634.v_current_calendar cal
  Inner Join tms_evaluation_type tet On tet.evaluation_type = e.evaluation_type
  Inner Join tms_rating trt On trt.rating_code = e.rating_code
  Where tet.evaluation_type In ('PR', 'UR') -- Research, UOR
)

-- Contact reports
, ard_contact As (
  Select
    report_id
    , credited As credited_id
    , prospect_id
    , contact_date
    , contact_type_category
    , visit_type
  From rpt_pbh634.v_contact_reports_fast
  Where prospect_id Is Not Null
    And ard_staff = 'Y'
)

-- Proposals, count and dollars


-- Major gifts, count and dollars
/*, gifts As (
  Select *
  From rpt_pbh634.v_ksm_giving_trans_hh gt
  Where gt.recognition_credit >= (Select mg_level From params)
)*/

-- Main query
Select Distinct
  asn.*
  , stg_hist.stage_desc
  -- UOR
  , uor_hist.rating_lower_bound As uor_lower_bound
  -- Eval rating
  , evl_hist.rating_lower_bound As eval_lower_bound
  -- Visits
  , Count(Distinct Case When ac.contact_type_category = 'Visit'
      Then ac.report_id End)
      Over(Partition By ac.prospect_id, ac.credited_id, asn.assignment_type, asn.filled_date)
    As cr_visits
  -- Events
  , Count(Distinct Case When ac.contact_type_category = 'Event'
      Then ac.report_id End)
      Over(Partition By ac.prospect_id, ac.credited_id, asn.assignment_type, asn.filled_date)
    As cr_events
  -- Attempted outreach
  , Count(Distinct Case When ac.contact_type_category = 'Attempted, E-mail, or Social'
      Then ac.report_id End)
      Over(Partition By ac.prospect_id, ac.credited_id, asn.assignment_type, asn.filled_date)
    As cr_emails_attempts_social
  -- Phone calls
  , Count(Distinct Case When ac.contact_type_category = 'Phone'
      Then ac.report_id End)
      Over(Partition By ac.prospect_id, ac.credited_id, asn.assignment_type, asn.filled_date)
    As cr_phone
From assn_dense asn
-- Prospect stage history
Left Join stage_history stg_hist
  On stg_hist.prospect_id = asn.prospect_id
  And asn.filled_date Between stg_hist.stage_start_dt And stg_hist.stage_stop_dt
-- Entity evaluation history
Left Join eval_history evl_hist
  On evl_hist.id_number = asn.id_number
  And evl_hist.prospect_id Is Null
  And evl_hist.evaluation_type = 'PR'
  And asn.filled_date Between evl_hist.eval_start_dt And evl_hist.eval_stop_dt
-- UOR history
Left Join eval_history uor_hist
  On uor_hist.prospect_id = asn.prospect_id
  And uor_hist.prospect_id Is Not Null
  And uor_hist.evaluation_type = 'UR'
  And asn.filled_date Between uor_hist.eval_start_dt And uor_hist.eval_stop_dt
-- Contact reports
Left Join ard_contact ac
  On ac.prospect_id = asn.prospect_id
  And ac.credited_id = asn.assignment_id_number
  And ac.contact_date Between asn.start_dt And asn.filled_date
Order By
  asn.assignment_report_name Asc
  , asn.report_name Asc
  , asn.filled_date Asc
