/*** Proposal pipeline (Tableau edition) ***/

Create Or Replace View vt_ksm_proposal_pipeline As

With

-- Proposal data
proposals As (
  Select
    phf.proposal_id
    , phf.prospect_id
    -- Open CFY, Open beyond CFY, and Closed CFY flags
    , Case
        -- Current FY and in progress
        When phf.proposal_in_progress = 'Y'
          And phf.close_fy = cal.curr_fy
          Then 'Open (CFY)'
        -- Future FY and in progress
        When phf.proposal_in_progress = 'Y'
          And phf.close_fy > cal.curr_fy
          Then 'Open (Beyond)'
        -- Current FY and not in progress
        When phf.proposal_in_progress Is Null
          And phf.close_fy = cal.curr_fy
          Then 'Closed (CFY)'
        Else NULL
        End
      As proposal_group
    , phf.prospect_name_sort
    , phf.prospect_name
    , phf.university_strategy
    , phf.proposal_manager_id
    , phf.proposal_manager
    , phf.curr_ksm_proposal_manager
    , phf.curr_ksm_team
    , phf.proposal_assist
    , phf.proposal_status_code
    , phf.proposal_status
    , phf.hierarchy_order
    , phf.proposal_active
    , phf.proposal_in_progress
    , phf.proposal_active_calc
    , phf.proposal_title
    , phf.proposal_description
    , phf.other_programs
    -- Split proposal indicator for anything besides financial aid
    , Case
        When  phf.other_programs Is Not Null
          And trim(phf.other_programs) <> 'Financial Aid'
          Then '*'
        End
      As split_proposal
    , phf.start_date
    , phf.ask_date
    , phf.total_ask_amt
    , phf.ksm_ask
    , phf.ksm_or_univ_ask
    , phf.ksm_af_ask
    , phf.close_date
    , phf.probability
    , phf.total_granted_amt
    , phf.total_anticipated_amt
    , phf.ksm_anticipated
    , phf.ksm_or_univ_anticipated
    , phf.ksm_af_anticipated
    , phf.proposal_type
    -- Date objects
    , cal.yesterday
    , cal.curr_fy
    , cal.curr_py
      As performance_year
    , cal.curr_py_start
    , cal.next_py_start
  From v_proposal_history_fast phf
  Cross Join v_current_calendar cal
  Where
    -- KSM proposals only
    phf.ksm_proposal_ind = 'Y'
)

, pe As (
  Select
    prospect_id
    , id_number
  From prospect_entity
  Where primary_ind = 'Y'
)

, numeric_evals As (
  Select
    short_desc As rating
    , rpt_pbh634.ksm_pkg.get_number_from_dollar(short_desc) As rating_numeric
  From tms_rating
)

, prs As (
  Select Distinct
    id_number
    , p.prospect_id
    , p.contact_date As last_visit_date
    , p.evaluation_date
    , p.evaluation_rating
    , evr.rating_numeric As evaluation_numeric
    , p.officer_rating
    , ofr.rating_numeric As officer_numeric
  From nu_prs_trp_prospect p
  Left Join numeric_evals evr
    On evr.rating = p.evaluation_rating
  Left Join numeric_evals ofr
    On ofr.rating = p.officer_rating
)

-- Final query
, final As (
  Select
    pe.id_number
    , hh.report_name
    , proposals.prospect_id
    , prospect_name_sort
    , prospect_name
    , hh.institutional_suffix
    , hh.household_state
    , hh.degrees_concat
    , hh.program_group
    , hh.spouse_id_number
    , hh.spouse_report_name
    , hh.spouse_suffix
    , hh.spouse_degrees_concat
    , hh.spouse_program_group
    , university_strategy
    , mg.id_segment
    , mg.id_score
    , mg.pr_segment
    , mg.pr_score
    , vas.prospect_manager_id
    , vas.prospect_manager
    , vas.managers
    , prs.last_visit_date
    , prs.evaluation_date
    , prs.evaluation_rating
    , prs.evaluation_numeric
    , prs.officer_rating
    , prs.officer_numeric
    , proposal_group
    , proposal_id
    , proposal_manager_id
    , proposal_manager
    , curr_ksm_proposal_manager
    , curr_ksm_team
    , proposal_assist
    , proposal_status_code
    , proposal_status
    , hierarchy_order
    , proposal_active
    , proposal_in_progress
    , proposal_active_calc
    , proposal_title
    , proposal_description
    , other_programs
    , split_proposal
    , start_date
    , ask_date
    , total_ask_amt
    , ksm_ask
    , ksm_or_univ_ask
    , ksm_af_ask
    , close_date
    , probability
    , total_granted_amt
    , total_anticipated_amt
    , ksm_anticipated
    , ksm_or_univ_anticipated
    , ksm_af_anticipated
    , proposal_type
    -- Audits
    -- Check whether split proposals have a suitable KSM amount
    , Case
        When split_proposal Is Not Null
          -- KSM ask should be less than overall ask
          And (
            ksm_ask = 0
            Or ksm_or_univ_ask = total_ask_amt
          )
          Then 'Split gift: check ask'
        End
      As audit_split_ask
    , Case
        When split_proposal Is Not Null
          -- KSM anticipated should be less than overall anticipated
          And (
            ksm_anticipated = 0
            Or ksm_or_univ_anticipated = total_anticipated_amt
          )
          Then 'Split gift: check anticipated'
        End
      As audit_split_anticipated
    -- Check whether PM is blank
    , Case
        When proposal_manager Is Null
          Then 'Proposal manager missing'
        End
      As audit_pm
    -- Check ask dates
    , Case
        -- No ask date
        When ask_date Is Null
          Then 'Ask date missing'
        -- Submitted through Approved, ask in the future
        When hierarchy_order Between 20 And 60
          And ask_date > yesterday
          Then 'Ask date in future, check date and stage'
        -- Anticipated, ask in the past
        When proposal_status_code = 'A'
          And ask_date <= yesterday
          Then 'Ask date in past, check date and stage'
        -- Ask date after close date
        When ask_date > close_date
          Then 'Ask date after close date, check date and stage'
        End
      As audit_ask_dt
    -- Check close dates
    , Case
        -- No close date
        When close_date Is Null
          Then 'Close date missing'
        -- Closed, close date in future
        When proposal_active = 'N'
          And close_date > yesterday
          Then 'Close date in future, check date and stage'
        -- Open, close date in past
        When proposal_active = 'Y'
          And close_date < yesterday 
          Then 'Close date in past, check date and stage'
        End
      As audit_close_dt
    -- Check proposal status
    , Case
      -- Closed, in progress status
      When proposal_active = 'N'
        And proposal_in_progress = 'Y'
        Then 'Proposal stage does not match active flag'
      -- Open, not in progress status
      When proposal_active = 'Y'
        And proposal_in_progress Is Null
        Then 'Proposal stage does not match active flag'
      End
      As audit_status
    -- Date objects
    , yesterday
    , curr_fy
    , performance_year
    , rpt_pbh634.ksm_pkg.get_performance_year(start_date)
      As start_py
    , rpt_pbh634.ksm_pkg.get_performance_year(ask_date)
      As ask_py
    , rpt_pbh634.ksm_pkg.get_performance_year(close_date)
      As close_py
    , curr_py_start
    , next_py_start
  From proposals
  Left Join pe
    On pe.prospect_id = proposals.prospect_id
  Left Join v_entity_ksm_households hh
    On hh.id_number = pe.id_number
  Left Join v_assignment_summary vas
    On vas.id_number = pe.id_number
  Left Join prs
    On prs.id_number = pe.id_number
  -- Model scores
  Left Join rpt_pbh634.v_ksm_model_mg mg
    On mg.id_number = pe.id_number
  Order By
    proposal_group Desc
    , total_granted_amt Desc
    , ksm_or_univ_ask Desc
    , hierarchy_order Desc
    , close_date Asc
)

-- With row numbers
Select 
  final.*
  , rownum
    As row_number
From final
;

/*** Portfolio time series view ***/

Create Or Replace View vt_go_portfolio_time_series As

With

/******
This view returns point-in-time portfolio information. The filled_date field gives the point-in-time date,
and all portfolio metrics are as of the LAST DAY of that month.
******/

-- Custom parameters/definitions
params As (
  Select
    100000 As mg_level -- Minimum amount for a major gift
    , 100000 As placeholder_level -- Anticipated amount of placeholder solicitations
    , to_date('20200831', 'yyyymmdd') -- Close date of placeholder solicitations
      As placeholder_date
  From DUAL
)

-- Assignment history
, assignments As (
  Select
    rownum As rn -- Number each row; important for assn_dense
    , prospect_id
    , vah.id_number
    , vah.report_name
    , household_id
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
  From v_assignment_history vah
  Cross Join rpt_pbh634.v_current_calendar cal
  Inner Join rpt_pbh634.v_entity_ksm_households hh On hh.id_number = vah.id_number
  Where assignment_type In ('PM', 'PP') -- PM and PPM only
    And primary_ind = 'Y' -- Primary prospect entity only
)

-- Assignment history by month between start_dt and stop_dt
, assn_dense As (
  Select
    prospect_id
    , id_number
    , report_name
    , household_id
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
        , trunc(stop_dt, 'month')
      ) As filled_date
    , level As months_assigned_strict -- Reset months_assigned to 1 for each new row in the assignment table
    , assignment_active_calc
    , assignment_id_number
    , assignment_report_name
  From assignments
  Connect By
    level <= months_assigned -- Hierarchical query
    And Prior rn = rn -- Restart when prospect/manager changes, since each prospect/pm combo has its own row
    And Prior dbms_random.value != 1 -- Always true, as 0 < dbms_random.value < 1
)

-- Deduped assignments; choose PM over PPM assignment if available
, assn_dedupe As (
  Select
    prospect_id
    , id_number
    , report_name
    , household_id
    , min(assignment_type) keep(dense_rank First Order By assignment_type Asc)
      As assignment_type
    , min(assignment_type_desc) keep(dense_rank First Order By assignment_type Asc)
      As assignment_type_desc
    , min(start_dt)
      As start_dt
    , max(stop_dt)
      As stop_dt
    , filled_date
    -- Grouping date to identify non-consecutive months
    , add_months(filled_date, -1 * row_number() Over (Partition By prospect_id, assignment_id_number Order By filled_date Asc))
      As date_grouper
    , min(assignment_active_calc)
      As assignment_active_calc
    , assignment_id_number
    , assignment_report_name
  From assn_dense
  Group By
    prospect_id
    , id_number
    , report_name
    , household_id
    , filled_date
    , assignment_id_number
    , assignment_report_name
)

, assn_final As (
  Select
    prospect_id
    , id_number
    , report_name
    , household_id
    , assignment_type
    , assignment_type_desc
    , start_dt
    , stop_dt
    , filled_date
    -- Reset months_assigned to 1 if a filled_date is skipped
    , row_number() Over(Partition By prospect_id, assignment_id_number, date_grouper Order By filled_date Asc)
      As months_assigned
    , assignment_active_calc
    , assignment_id_number
    , assignment_report_name
  From assn_dedupe
  -- Drop rows with impossible dates (typo)
  Where filled_date >= to_date('19000101', 'yyyymmdd')
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
    , e.evaluator_id_number
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
    , contact_credit_type
    , Case
        When vcrf.prospect_id Is Not Null Then vcrf.prospect_id
        When pe.prospect_id Is Not Null Then pe.prospect_id
      End
      As prospect_id
    , contact_date
    , contact_type_category
    , visit_type
  From rpt_pbh634.v_contact_reports_fast vcrf
  Left Join table(ksm_pkg.tbl_prospect_entity_active) pe
    On pe.id_number = vcrf.id_number
  Where ard_staff = 'Y'
    And (
      pe.prospect_id Is Not Null
      Or vcrf.prospect_id Is Not Null
    )
)

-- New gifts & commitments
, ksm_ngc As (
  Select Distinct
    gt.household_id
    , gt.tx_number
    , gt.tx_gypm_ind
    , gt.af_flag
    , gt.cru_flag
    , gt.proposal_id
    , gt.date_of_record
    , gt.hh_recognition_credit
    , pd.prim_pledge_original_amount
  From rpt_pbh634.v_ksm_giving_trans_hh gt
  -- Include discounted pledge original amounts
  Left Join table(rpt_pbh634.ksm_pkg.plg_discount) pd On pd.pledge_number = gt.tx_number
  Where gt.tx_gypm_ind <> 'Y' -- NGC excludes payments
    And gt.hh_recognition_credit = gt.recognition_credit -- Exclude spouses
)

-- Aggregated point-in-time giving
, ksm_giving As (
  Select
    assn.household_id
    , assn.assignment_id_number
    , assn.filled_date
    -- KSM giving to present
    , sum(Case When ngc.date_of_record <= last_day(assn.filled_date) Then ngc.hh_recognition_credit Else 0 End)
      As ksm_lifetime_giving
    -- Giving in last 24-month window
    , sum(Case When ngc.date_of_record Between add_months(assn.filled_date, -24) And last_day(assn.filled_date)
        Then ngc.hh_recognition_credit Else 0 End)
      As ksm_giving_last_24_mo
    -- Major gifts
    , Count(Distinct
        Case When ngc.hh_recognition_credit >= (Select mg_level From params)
        And ngc.date_of_record <= last_day(assn.filled_date)
        Then ngc.tx_number End)
      As ksm_mg_count
    -- Major gifts since assignment
    , Count(Distinct
        Case When ngc.hh_recognition_credit >= (Select mg_level From params)
        And (
          -- Gifts between start/stop date from assignment table
          ngc.date_of_record Between assn.start_dt And last_day(assn.filled_date)
          -- Gifts since prospect entered portfolio, across start/stop date rows in assignment table
          Or ngc.date_of_record Between add_months(assn.filled_date, -1 * (months_assigned - 1))
            And last_day(assn.filled_date)
        )
        Then ngc.tx_number End)
      As ksm_mg_since_assign
    -- Major gifts in last 24 months
    , Count(Distinct
          Case When ngc.hh_recognition_credit >= (Select mg_level From params)
          And ngc.date_of_record Between add_months(assn.filled_date, -24) And last_day(assn.filled_date)
          Then ngc.tx_number End)
      As ksm_mg_last_24_mo
  From assn_final assn
  Inner Join ksm_ngc ngc On ngc.household_id = assn.household_id
  Group By
    assn.household_id
    , assn.assignment_id_number
    , assn.filled_date
)

-- Point-in-time proposal managers
, prop_mgrs As (
  Select
    rownum As rn
    , ah.prospect_id
    , ah.report_name
    , ah.proposal_id
    , ah.start_dt_calc As assignment_start_dt
    , Case When ah.stop_dt_calc Is Null Then last_day(cal.today) Else ah.stop_dt_calc End
      As assignment_stop_dt
    -- Number of months from start_dt_calc to stop_dt_calc, rounded up
    , ceil(
        months_between(
          last_day(Case
            -- If assignment history stop date is before proposal close date, use assignment history stop date
            When ah.stop_dt_calc <= ph.close_dt_calc Then ah.stop_dt_calc
            -- If assignment history stop date is after proposal close date, use proposal close date
            When ah.stop_dt_calc > ph.close_dt_calc Then ph.close_dt_calc
            -- When both are null use last day of this month
            When ah.stop_dt_calc Is Null And ph.close_dt_calc Is Null Then last_day(cal.today)
            -- When just assignment history stop date is null use proposal close date
            When ah.stop_dt_calc Is Null And ph.close_dt_calc Is Not Null Then ph.close_dt_calc
            -- Fallback
            Else ah.stop_dt_calc
          End)
        , trunc(ah.start_dt_calc, 'month')
        )
      ) As assignment_months_assigned
    , ah.assignment_active_calc
    , ph.close_dt_calc
    , ph.proposal_active_calc
    , ah.assignment_id_number
    , ah.assignment_report_name
    , ph.start_date
    , ph.ask_date
    , ph.proposal_status_code
    , ph.total_ask_amt
    , ph.total_anticipated_amt
    , ph.total_granted_amt
    , ph.ksm_or_univ_ask
    , ph.ksm_or_univ_orig_ask
    , ph.ksm_or_univ_anticipated
    , ph.ksm_linked_amounts
    , ph.ksm_date_of_record
  From v_assignment_history ah
  Cross Join rpt_pbh634.v_current_calendar cal
  Inner Join v_proposal_history ph On ph.proposal_id = ah.proposal_id
  Where assignment_type = 'PA' -- Proposal Manager (PM is taken by Prospect Manager)
    And primary_ind = 'Y' -- Primary prospect only
    -- Drop rows with impossible dates (typo)
    And (ah.start_dt_calc Is Null Or ah.start_dt_calc >= to_date('19000101', 'yyyymmdd'))
    And (ah.stop_dt_calc Is Null Or ah.stop_dt_calc >= to_date('19000101', 'yyyymmdd'))
)
-- Fill in dates
, prop_mgrs_dense As (
  Select
    prospect_id
    , report_name
    , proposal_id
    , assignment_start_dt
    , assignment_stop_dt
    , assignment_active_calc
    , assignment_id_number
    , assignment_report_name
    -- Take either 1 month in the future from last row, or the stop_dt, whichever is smaller
    , least(
        Case
          When level = 1 Then trunc(assignment_start_dt, 'month') -- First filled_date is start_dt month
          When level = assignment_months_assigned Then trunc( -- Last filled date is stop_dt month
            least(assignment_stop_dt, close_dt_calc) -- If close date was before assignment stop date, use close date
            , 'month')
          Else trunc(add_months(assignment_start_dt, level - 1), 'month') -- Subsequent are 1st of month after previous row
        End
        , trunc(assignment_stop_dt, 'month')
      ) As assignment_filled_date
    , close_dt_calc
    , proposal_active_calc
    , start_date
    , ask_date
    , proposal_status_code
    , total_ask_amt
    , total_anticipated_amt
    , total_granted_amt
    , ksm_or_univ_ask
    , ksm_or_univ_orig_ask
    , ksm_or_univ_anticipated
    , ksm_linked_amounts
    , ksm_date_of_record
  From prop_mgrs pm
  Connect By
    level <= greatest(assignment_months_assigned, 1) -- Hierarchical query, but proposal forced to be active for at least 1 month
    And Prior rn = rn -- Restart when prospect/manager changes, since each prospect/pm combo has its own row
    And Prior dbms_random.value != 1 -- Always true, as 0 < dbms_random.value < 1
)
-- Dedupe multiple assignments on same date
, prop_mgrs_dedupe As (
  Select
    prospect_id
    , report_name
    , proposal_id
    , min(assignment_start_dt) As assignment_start_dt
    , max(assignment_stop_dt) As assignment_stop_dt
    , min(assignment_active_calc) As assignment_active_calc
    , assignment_id_number
    , assignment_report_name
    , assignment_filled_date
    , close_dt_calc
    , start_date
    , ask_date
    , proposal_status_code
    , total_ask_amt
    , total_anticipated_amt
    , total_granted_amt
    , ksm_or_univ_ask
    , ksm_or_univ_orig_ask
    , ksm_or_univ_anticipated
    , ksm_linked_amounts
    , ksm_date_of_record
  From prop_mgrs_dense
  Group By
    prospect_id
    , report_name
    , proposal_id
    , assignment_id_number
    , assignment_report_name
    , assignment_filled_date
    , close_dt_calc
    , start_date
    , ask_date
    , proposal_status_code
    , total_ask_amt
    , total_anticipated_amt
    , total_granted_amt
    , ksm_or_univ_ask
    , ksm_or_univ_orig_ask
    , ksm_or_univ_anticipated
    , ksm_linked_amounts
    , ksm_date_of_record
)
-- Final aggregated proposal stats
, prop_final As (
  Select
    prospect_id
    , assignment_id_number
    , assignment_filled_date
    , count(proposal_id) As proposal_count
    , count(Case When ksm_or_univ_anticipated = (Select placeholder_level From params)
        And close_dt_calc = (Select placeholder_date From params)
        Then proposal_id End)
      As proposal_placeholder_count
    , sum(total_ask_amt) As nu_asks
    , sum(total_anticipated_amt) As nu_anticipated
    , sum(total_granted_amt) As nu_granted
    , sum(ksm_or_univ_ask) As proposal_asks
    , sum(ksm_or_univ_orig_ask) As proposal_orig_asks
    , sum(ksm_or_univ_anticipated) As proposal_anticipated
    -- Count as new ask when ask date was this month, or proposal start date was this month
    -- Only count statuses B (Letter of Inquiry), C (Submitted), 5 (Approved), 7 (Funded), 8 (Declined)
    , count(Distinct
        Case
          When ask_date Between assignment_filled_date And last_day(assignment_filled_date)
            And proposal_status_code In ('B', 'C', '5', '7', '8')
            Then proposal_id
          When ask_date Is Null
            And proposal_status_code In ('B', 'C', '5', '7', '8')
            And start_date Between assignment_filled_date And last_day(assignment_filled_date)
            Then proposal_id
        End
      )
      As asks_this_mo
    -- Count linked amount only when date of record is in month
    , sum(Case When ksm_date_of_record Between assignment_filled_date And last_day(assignment_filled_date)
        Then ksm_linked_amounts Else 0 End)
      As proposal_linked_this_mo
    -- Was a KSM MG made this month?
    , sum(Case
        When ksm_linked_amounts >= (Select mg_level From params)
          And ksm_date_of_record Between assignment_filled_date And last_day(assignment_filled_date)
          Then ksm_linked_amounts
        Else 0
      End) As ksm_mg_dollars_this_mo
  From prop_mgrs_dedupe
  Group By
    prospect_id
    , assignment_id_number
    , assignment_filled_date
)

-- Main query
Select Distinct
  -- Assignment history dense fields
  asn.prospect_id
  , asn.id_number
  , asn.report_name
  , asn.household_id
  , asn.assignment_type
  , asn.assignment_type_desc
  , asn.start_dt
  , asn.stop_dt
  , asn.filled_date
  , asn.months_assigned
  , asn.assignment_active_calc
  , asn.assignment_id_number
  , asn.assignment_report_name
  -- Point-in-time stage history
  , stg_hist.stage_desc
  -- UOR
  , nvl(uor_hist.rating_lower_bound, 0) As uor_lower_bound
  , Case
      When uor_hist.evaluator_id_number = asn.assignment_id_number
        Then 'Y'
      End
    As uor_by_assigned
  , Case
      When uor_hist.evaluator_id_number = asn.assignment_id_number
        Then uor_hist.eval_start_dt
      End
    As uor_by_assigned_dt
  -- Eval rating
  , nvl(evl_hist.rating_lower_bound, 0) As eval_lower_bound
  -- Primary visits
  , Count(Distinct Case When ac.contact_type_category = 'Visit'
      And ac.contact_credit_type = 1
      Then ac.report_id End)
      Over(Partition By ac.prospect_id, ac.credited_id, asn.filled_date)
    As cr_visits_by_assigned
  -- Primary visits last N montths
  , Count(Distinct Case When ac.contact_type_category = 'Visit'
      And ac.contact_credit_type = 1
      And ac.contact_date >= add_months(asn.filled_date, -24) Then ac.report_id End)
      Over(Partition By ac.prospect_id, ac.credited_id, asn.filled_date)
    As cr_visits_last_24_mo
  , Count(Distinct Case When ac.contact_type_category = 'Visit'
      And ac.contact_credit_type = 1
      And ac.contact_date >= add_months(asn.filled_date, -12) Then ac.report_id End)
      Over(Partition By ac.prospect_id, ac.credited_id, asn.filled_date)
    As cr_visits_last_12_mo
  -- Primary visits per month assigned
  , Count(Distinct Case When ac.contact_type_category = 'Visit'
      And ac.contact_credit_type = 1
      Then ac.report_id End)
      Over(Partition By ac.prospect_id, ac.credited_id, asn.filled_date)
      / asn.months_assigned
    As cr_visits_per_mo_assigned
  -- Visit this month, while assigned
  , Count(Distinct Case When ac.contact_type_category = 'Visit'
      And ac.contact_credit_type = 1
      And ac.contact_date Between
        greatest(asn.start_dt + 1, asn.filled_date) -- Visit on assignment start date doesn't count
        And least(asn.stop_dt, last_day(asn.filled_date))
      Then ac.report_id End)
      Over(Partition By ac.prospect_id, ac.credited_id, asn.filled_date)
    As cr_visits_this_mo
  -- Primary contacts last N montths
  , Count(Distinct Case When ac.contact_type_category <> 'Visit'
      And ac.contact_credit_type = 1
      And ac.contact_date >= add_months(asn.filled_date, -12) Then ac.report_id End)
      Over(Partition By ac.prospect_id, ac.credited_id, asn.filled_date)
    As cr_contacts_last_12_mo
  , Count(Distinct Case When ac.contact_type_category <> 'Visit'
      And ac.contact_credit_type = 1
      And ac.contact_date >= add_months(asn.filled_date, -6) Then ac.report_id End)
      Over(Partition By ac.prospect_id, ac.credited_id, asn.filled_date)
    As cr_contacts_last_6_mo
    -- Non-visit contacts this month, while assigned
    , Count(Distinct Case When ac.contact_type_category <> 'Visit'
      And ac.contact_credit_type = 1
      And ac.contact_date Between
        greatest(asn.start_dt + 1, asn.filled_date) -- Visit on assignment start date doesn't count
        And least(asn.stop_dt, last_day(asn.filled_date))
      Then ac.report_id End)
      Over(Partition By ac.prospect_id, ac.credited_id, asn.filled_date)
    As cr_contacts_this_mo
  -- Visits
  , Count(Distinct Case When ac.contact_type_category = 'Visit'
      And ac.contact_date >= add_months(asn.filled_date, -24) Then ac.report_id End)
      Over(Partition By ac.prospect_id, ac.credited_id, asn.filled_date)
    As cr_all_visits_last_24_mo
  -- Events
  , Count(Distinct Case When ac.contact_type_category = 'Event'
      And ac.contact_date >= add_months(asn.filled_date, -24) Then ac.report_id End)
      Over(Partition By ac.prospect_id, ac.credited_id, asn.filled_date)
    As cr_events_last_24_mo
  -- Attempted outreach
  , Count(Distinct Case When ac.contact_type_category = 'Attempted, E-mail, or Social'
      And ac.contact_date >= add_months(asn.filled_date, -24) Then ac.report_id End)
      Over(Partition By ac.prospect_id, ac.credited_id, asn.filled_date)
    As cr_emails_attempts_last_24_mo
  -- Phone calls
  , Count(Distinct Case When ac.contact_type_category = 'Phone'
      And ac.contact_date >= add_months(asn.filled_date, -24) Then ac.report_id End)
      Over(Partition By ac.prospect_id, ac.credited_id, asn.filled_date)
    As cr_phone_last_24_mo
  -- Correspondence
  , Count(Distinct Case When ac.contact_type_category = 'Correspondence'
      And ac.contact_date >= add_months(asn.filled_date, -24) Then ac.report_id End)
      Over(Partition By ac.prospect_id, ac.credited_id, asn.filled_date)
    As cr_correspondence_last_24_mo
  -- Aggregated giving
  , nvl(gft.ksm_mg_count, 0) As ksm_mg_count
  , nvl(gft.ksm_mg_since_assign, 0) As ksm_mg_since_assign
  , nvl(gft.ksm_mg_last_24_mo, 0) As ksm_mg_last_24_mo
  , nvl(gft.ksm_lifetime_giving, 0) As ksm_lifetime_giving
  , nvl(gft.ksm_giving_last_24_mo, 0) As ksm_giving_last_24_mo
  -- Active proposal stats
  , nvl(prp.proposal_count, 0) As proposal_count
  , nvl(prp.proposal_placeholder_count, 0) As proposal_placeholder_count
  , nvl(prp.proposal_asks, 0) As proposal_asks
  , nvl(prp.proposal_orig_asks, 0) As proposal_orig_asks
  , nvl(prp.proposal_anticipated, 0) As proposal_anticipated
  , nvl(prp.asks_this_mo, 0) As proposal_asked_this_mo
  , nvl(prp.proposal_linked_this_mo, 0) As proposal_linked_this_mo
  , nvl(prp.ksm_mg_dollars_this_mo, 0) As ksm_mg_dollars_this_mo
  , nvl(prp.nu_asks, 0) As nu_asks
  , nvl(prp.nu_anticipated, 0) As nu_anticipated
  , nvl(prp.nu_granted, 0) As nu_granted
  -- MG model scores
  , scores.id_score
  , scores.id_segment
  , scores.pr_score
  , scores.pr_segment
From assn_final asn
-- Prospect stage history
Left Join stage_history stg_hist
  On stg_hist.prospect_id = asn.prospect_id
  And last_day(asn.filled_date) Between stg_hist.stage_start_dt And stg_hist.stage_stop_dt
-- Entity evaluation history
Left Join eval_history evl_hist
  On evl_hist.id_number = asn.id_number
  And evl_hist.prospect_id Is Null
  And evl_hist.evaluation_type = 'PR'
  And last_day(asn.filled_date) Between evl_hist.eval_start_dt And evl_hist.eval_stop_dt
-- UOR history
Left Join eval_history uor_hist
  On uor_hist.prospect_id = asn.prospect_id
  And uor_hist.prospect_id Is Not Null
  And uor_hist.evaluation_type = 'UR'
  And last_day(asn.filled_date) Between uor_hist.eval_start_dt And uor_hist.eval_stop_dt
-- Contact reports
Left Join ard_contact ac
  On ac.prospect_id = asn.prospect_id
  And ac.credited_id = asn.assignment_id_number
  And ac.contact_date <= last_day(asn.filled_date)
-- Aggregated giving
Left Join ksm_giving gft
  On gft.household_id = asn.household_id
  And gft.assignment_id_number = asn.assignment_id_number
  And gft.filled_date = asn.filled_date
-- Proposal managers
Left Join prop_final prp
  On prp.prospect_id = asn.prospect_id
  And prp.assignment_id_number = asn.assignment_id_number
  And prp.assignment_filled_date = asn.filled_date
-- Latest model scores
Left Join v_ksm_model_mg scores
  On scores.id_number = asn.id_number
-- Sort results
Order By
  asn.assignment_report_name Asc
  , asn.report_name Asc
  , asn.filled_date Asc
;
