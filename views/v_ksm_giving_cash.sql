-- Create Or Replace View v_ksm_giving_cash As

With

hhf As (
  Select *
  From v_entity_ksm_households_fast
)

, allocs As (
  Select
    allocation.allocation_code
    , allocation.short_name As alloc_name
    , allocation.status_code
    , allocation.alloc_school
    , Case
        -- Inactive
        When allocation.status_code <> 'A'
          Then 'Inactive'
        -- Kellogg Education Center
        When allocation.allocation_code = '3203006213301GFT'
          Then 'KEC'
        -- Global Hub
        When allocation.allocation_code In ('3303002280601GFT', '3303002283701GFT', '3203004284701GFT')
          Then 'Hub Campaign Cash'
        -- Gift In Kind
        When allocation.allocation_code = '3303001899301GFT'
          Then 'Gift In Kind'
        -- All endowed
        When allocation.agency = 'END'
          Then 'Endowed'
        -- All current use
        When cru.allocation_code Is Not Null
          Then 'Expendable'
        -- Grant chartstring
        When allocation.account Like '6%'
          Then 'Grants'
        --  Fallback - to reconcile
        Else 'Other/TBD'
      End
      As cash_category
  From allocation
  Left Join v_alloc_curr_use cru
    On cru.allocation_code = allocation.allocation_code
  Where
    -- KSM allocations
    alloc_school = 'KM'
)

, funded_proposal_credit As (
  Select
    proposal_id
    , assignment_id_number
  From table(rpt_pbh634.metrics_pkg.tbl_funded_count(ask_amt => 0.01, funded_count => 0.01))
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
    And gt.fiscal_year = 2023
)

Select
  attr_cash.*
  , assignment_id_number As proposal_mgr
  , NULL As assigned_pm
  , NULL As assigned_lgo
From attr_cash
Left Join funded_proposal_credit fpc
  On fpc.proposal_id = attr_cash.proposal_id
