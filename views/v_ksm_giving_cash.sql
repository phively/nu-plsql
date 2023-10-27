Create Or Replace View v_ksm_giving_cash As

With

params As (
  Select
    2021 As start_yr
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
From attr_cash
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
