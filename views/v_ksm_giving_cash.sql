Create Or Replace View v_ksm_giving_cash As

With

params As (
  Select
    2020 As start_yr
  From DUAL
)

, hhf As (
  Select *
  From v_entity_ksm_households_fast
)

, allocs As (
  Select *
  From table(rpt_pbh634.ksm_pkg_allocation_tst.tbl_cash_alloc_groups)
)

, funded_proposal_credit As (
  Select
    proposal_id
    , assignment_id_number
    , entity.report_name As assignment_report_name
  From table(rpt_pbh634.metrics_pkg.tbl_funded_count(ask_amt => 0.01, funded_count => 0.01))
  Inner Join entity
    On entity.id_number = assignment_id_number
)

, historical_mgrs As (
  Select
    id_number
    , assignment_type
    , assignment_id_number
    , assignment_report_name
    , start_dt_calc
    , nvl(stop_dt_calc, to_date('9999-01-01', 'yyyy-mm-dd'))
      As stop_dt_calc
  From v_assignment_history
  Where assignment_type In ('PM', 'LG')
)

, attr_cash As (
  Select
    gt.tx_number
    , ksm_pkg_tmp.get_gift_source_donor_ksm(gt.tx_number)
      As id_number
    , gt.allocation_code
    , gt.alloc_short_name
    , gt.tx_gypm_ind
    , gt.transaction_type
    , gt.fiscal_year
    , gt.date_of_record
    , gt.legal_amount
    , Case
        When gt.payment_type = 'Gift-in-Kind'
          Then 'Gift In Kind'
        Else allocs.cash_category
        End 
      As cash_category
    , gt.pledge_number
    -- Use proposal ID directly if available; if a pledge payment type look for pledge proposal ID
    , Case
        When gt.proposal_id Is Not Null
          Then gt.proposal_id
        When gt.pledge_number Is Not Null
          Then primary_pledge.proposal_id
        End
      As proposal_id
  From v_ksm_giving_trans gt
  Inner Join allocs
    On allocs.allocation_code = gt.allocation_code
  Left Join primary_pledge
    On primary_pledge.prim_pledge_number = gt.pledge_number
  Where gt.legal_amount > 0
    And gt.tx_gypm_ind <> 'P'
    And gt.fiscal_year >= (Select start_yr From params)
)

, historical_pms As (
  Select Distinct
    hm.id_number
    , hm.assignment_type
    , hm.assignment_id_number
    , hm.assignment_report_name
    , hm.start_dt_calc
    , hm.stop_dt_calc
    , ac.date_of_record
    , ac.tx_number
  From historical_mgrs hm
  Inner Join attr_cash ac
    On ac.id_number = hm.id_number
    And ac.date_of_record Between hm.start_dt_calc And hm.stop_dt_calc
  Where hm.assignment_type = 'PM'
)

, historical_lgos As (
  Select Distinct
    hm.id_number
    , hm.assignment_type
    , hm.assignment_id_number
    , hm.assignment_report_name
    , hm.start_dt_calc
    , hm.stop_dt_calc
    , ac.date_of_record
    , ac.tx_number
  From historical_mgrs hm
  Inner Join attr_cash ac
    On ac.id_number = hm.id_number
    And ac.date_of_record Between hm.start_dt_calc And hm.stop_dt_calc
  Where hm.assignment_type = 'LG'
)

, ranked_historical_mgrs As (
  Select historical_pms.*
    -- For each entity, tiebreak whoever started as manager earlier, then whoever ended as manager later
    , row_number() Over(Partition By id_number, tx_number Order By start_dt_calc Asc, stop_dt_calc Desc)
      As assign_rank
  From historical_pms
  Union
  Select historical_lgos.*
    -- For each entity, tiebreak whoever started as manager earlier, then whoever ended as manager later
    , row_number() Over(Partition By id_number, tx_number Order By start_dt_calc Asc, stop_dt_calc Desc)
      As assign_rank
  From historical_lgos
)

, cash_plus_mgrs As (
  Select
    attr_cash.tx_number
    , attr_cash.id_number
    , entity.report_name As primary_donor_report_name
    , attr_cash.allocation_code
    , attr_cash.alloc_short_name
    , attr_cash.tx_gypm_ind
    , attr_cash.transaction_type
    , attr_cash.fiscal_year
    , attr_cash.date_of_record
    , rpt_pbh634.ksm_pkg_calendar.fytd_indicator(attr_cash.date_of_record)
      As fytd_ind
    , attr_cash.legal_amount
    , attr_cash.cash_category
    , attr_cash.pledge_number
    , attr_cash.proposal_id
    , fpc.assignment_id_number As proposal_mgr
    , fpc.assignment_report_name As proposal_mgr_name
    , pm.assignment_id_number As assigned_pm
    , pm.assignment_report_name As pm_name
    , pm.start_dt_calc As pm_start_dt
    , lgo.assignment_id_number As assigned_lgo
    , lgo.assignment_report_name As lgo_name
    , lgo.start_dt_calc As lgo_start_dt
    , cal.curr_fy
  From attr_cash
  Cross join rpt_pbh634.v_current_calendar cal
  Inner Join entity
    On entity.id_number = attr_cash.id_number
  Left Join funded_proposal_credit fpc
    On fpc.proposal_id = attr_cash.proposal_id
  Left Join ranked_historical_mgrs pm
    On pm.id_number = attr_cash.id_number
    And pm.tx_number = attr_cash.tx_number
    And pm.assign_rank = 1
    And pm.assignment_type = 'PM'
  Left Join ranked_historical_mgrs lgo
    On lgo.id_number = attr_cash.id_number
    And lgo.tx_number = attr_cash.tx_number
    And lgo.assign_rank = 1
    And lgo.assignment_type = 'LG'
)

, cash_credit As (
  Select
    cash_plus_mgrs.*
    , Case
        When proposal_mgr Is Not Null Then proposal_mgr
        When assigned_pm Is Not Null Then assigned_pm
        When assigned_lgo Is Not Null Then assigned_lgo
        End
      As primary_credited_mgr
    , Case
        When proposal_mgr Is Not Null Then proposal_mgr_name
        When assigned_pm Is Not Null Then pm_name
        When assigned_lgo Is Not Null Then lgo_name
        End
      As primary_credited_mgr_name
  From cash_plus_mgrs
)

, ksm_mgrs As (
  Select
    id_number
    , team
    , start_dt
    , stop_dt
  From rpt_pbh634.mv_past_ksm_gos
)

Select
  cash_credit.*
  , Case
      -- Unmanaged
      When primary_credited_mgr Is Null
        Or primary_credited_mgr = '0000722156' -- Pending Assignment
        Then 'Unmanaged'
      -- Active KSM MGOs
      When primary_credited_mgr In (
          Select id_number
          From ksm_mgrs
          Where team = 'MG'
            And cash_credit.date_of_record
            Between start_dt And nvl(stop_dt, to_date('99990101', 'yyyymmdd'))
        )
        Then 'MGO'
      -- Any KSM LGO
      When primary_credited_mgr In (
          Select id_number
          From ksm_mgrs
          Where team = 'AF'
            And cash_credit.date_of_record
            Between start_dt And nvl(stop_dt, to_date('99990101', 'yyyymmdd'))
        )
        Then 'LGO'
      -- Any other KSM staff
      When primary_credited_mgr In (
          Select id_number
          From ksm_mgrs
          Where team Not In ('AF', 'MG')
            And cash_credit.date_of_record
            Between start_dt And nvl(stop_dt, to_date('99990101', 'yyyymmdd'))
        )
        Then 'KSM'
      -- Active in staff table = NU
      When primary_credited_mgr In (
          Select id_number
          From staff
          Where active_ind = 'Y'
            And office_code <> 'KM'
        )
        Then 'NU'
      -- Other past KSM staff = (team)
      When primary_credited_mgr In (
          Select id_number
          From ksm_mgrs
          Where team = 'MG'
        )
        Then 'Unmanaged-MGO'
      When primary_credited_mgr In (
          Select id_number
          From ksm_mgrs
          Where team = 'AF'
        )
        Then 'Unmanaged-LGO'
      When primary_credited_mgr In (
          Select id_number
          From ksm_mgrs
          Where team Not In ('AF', 'MG')
        )
        Then 'Unmanaged-KSM'
      When primary_credited_mgr In (
          Select id_number
          From staff
          Where active_ind = 'N'
        )
        Then 'Unmanaged-NU'
      -- Fallback = NULL
      Else NULL
      End
    As managed_hierarchy
From cash_credit
