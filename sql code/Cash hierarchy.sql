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

, board_ids As (
  Select id_number From table(ksm_pkg_tmp.tbl_committee_gab)
  Union
  Select id_number From table(ksm_pkg_tmp.tbl_committee_amp)
  Union
  Select id_number From table(ksm_pkg_tmp.tbl_committee_realEstCouncil)
  Union
  Select id_number From table(ksm_pkg_tmp.tbl_committee_kac)
  Union
  Select id_number From table(ksm_pkg_tmp.tbl_committee_healthcare)
)

, entity_boards As (
  Select
  entity.id_number
  , entity.report_name
  , entity.institutional_suffix
  , Case When gab.id_number Is Not Null Then 'Y' End As gab
  , Case When amp.id_number Is Not Null Then 'Y' End As amp
  , Case When re.id_number Is Not Null Then 'Y' End As re
  , Case When kac.id_number Is Not Null Then 'Y' End As kac
  , Case When health.id_number Is Not Null Then 'Y' End As health
  From board_ids
  Inner Join entity
    On entity.id_number = board_ids.id_number
  Left Join table(ksm_pkg_tmp.tbl_committee_gab) gab
    On gab.id_number = entity.id_number
  Left Join table(ksm_pkg_tmp.tbl_committee_amp) amp
    On amp.id_number = entity.id_number
  Left Join table(ksm_pkg_tmp.tbl_committee_realEstCouncil) re
    On re.id_number = entity.id_number
  Left Join table(ksm_pkg_tmp.tbl_committee_kac) kac
    On kac.id_number = entity.id_number
  Left Join table(ksm_pkg_tmp.tbl_committee_healthcare) health
    On health.id_number = entity.id_number
)

, boards As (
  Select
    id_number
    , gab
    , amp
    , re
    , kac
    , health
    , Case When gab Is Not Null Then ksm_pkg_committee.get_numeric_constant('dues_gab') Else 0 End
      + Case When amp Is Not Null Then ksm_pkg_committee.get_numeric_constant('dues_amp') Else 0 End
      + Case When re Is Not Null Then ksm_pkg_committee.get_numeric_constant('dues_realestate') Else 0 End
      + Case When kac Is Not Null Then ksm_pkg_committee.get_numeric_constant('dues_kac') Else 0 End
      + Case When health Is Not Null Then ksm_pkg_committee.get_numeric_constant('dues_healthcare') Else 0 End
      As total_dues
  From entity_boards
  Where gab Is Not Null
    Or amp Is Not Null
    Or re Is Not Null
    Or kac Is Not Null
    Or health Is Not Null
)

, boards_hh As (
  Select
    hhf.household_id
    , sum(boards.total_dues)
      As total_dues_hh
    , count(boards.gab) As gab
    , count(boards.amp) As amp
    , count(boards.re) As re
    , count(boards.kac) As kac
    , count(boards.health) As health
  From boards
  Inner Join hhf
    On hhf.id_number = boards.id_number
  Group By hhf.household_id
)

, assigned As (
  Select
    vas.id_number
    , hhf.household_id
    , vas.curr_ksm_manager
    , vas.prospect_manager_id
    , vas.prospect_manager
    , vas.lgos
    , Case
        When vas.curr_ksm_manager Is Null
          And vas.prospect_manager_id Is Not Null
            Then 'NU'
        When vas.curr_ksm_manager Is Not Null
          Then
          Case 
            -- Active MGOs
            When vas.prospect_manager_id In (Select id_number From table(ksm_pkg_tmp.tbl_frontline_ksm_staff) Where team = 'MG' And former_staff Is Null)
              Then 'MGO'
            -- Any LGO
            When vas.lgos Is Not Null
              Then 'LGO'
            When vas.prospect_manager_id In (Select id_number From table(ksm_pkg_tmp.tbl_frontline_ksm_staff) Where team = 'AF' And former_staff Is Null)
              Then 'LGO'
            -- Any other KSM staff
            When vas.prospect_manager_id In (Select id_number From table(ksm_pkg_tmp.tbl_frontline_ksm_staff) Where former_staff Is Null)
              Then 'Unmanaged'
            Else 'NU'
            End
        When vas.prospect_manager Is Null
          And vas.lgos Is Null
          Then 'Unmanaged'
        End
        As managed_hierarchy
  From v_assignment_summary vas
  Inner Join hhf
    On hhf.id_number = vas.id_number
)

, assigned_hh As (
  Select
    household_id
    , max(curr_ksm_manager) As curr_ksm_manager
    , max(prospect_manager_id) As prospect_manager_id
    , max(prospect_manager) As prospect_manager
    , max(lgos) As lgos
    , max(managed_hierarchy) As managed_hierarchy
  From assigned
  Group By household_id
)

, attr_cash As (
  Select
    gt.tx_number
    , ksm_pkg_tmp.get_gift_source_donor_ksm(gt.tx_number)
      As id_number
    , gt.allocation_code
    , gt.fiscal_year
    , gt.legal_amount
    , Case
        When gt.payment_type = 'Gift-in-Kind'
          Then 'Gift In Kind'
        Else allocs.cash_category
        End 
      As cash_category
  From v_ksm_giving_trans gt
  Inner Join allocs
    On allocs.allocation_code = gt.allocation_code
  Where gt.legal_amount > 0
    And gt.tx_gypm_ind <> 'P'
    And gt.fiscal_year = 2023
)

, grouped_cash As (
  Select
    attr_cash.cash_category
    , hhf.household_id
    , attr_cash.id_number
    , attr_cash.fiscal_year
    , sum(attr_cash.legal_amount) As sum_legal_amount
  From attr_cash
  Inner Join hhf
    On hhf.id_number = attr_cash.id_number
  Group By
    attr_cash.cash_category
    , hhf.household_id
    , attr_cash.id_number
    , attr_cash.fiscal_year
)

, merge_ids As (
  Select household_id
  From boards_hh
  Union
  Select household_id
  From assigned_hh
)

, merge_flags As (
  Select
    merge_ids.household_id
    , boards_hh.gab
    , boards_hh.amp
    , boards_hh.re
    , boards_hh.kac
    , boards_hh.health
    , boards_hh.total_dues_hh
    , assigned_hh.curr_ksm_manager
    , assigned_hh.prospect_manager_id
    , assigned_hh.prospect_manager
    , assigned_hh.lgos
    , nvl(assigned_hh.managed_hierarchy, 'Unmanaged')
      As managed_hierarchy
    From merge_ids
    Left Join boards_hh
      On boards_hh.household_id = merge_ids.household_id
    Left Join assigned_hh
      On assigned_hh.household_id = merge_ids.household_id
)

Select
  gc.cash_category
  , gc.household_id
  , gc.id_number
  , gc.fiscal_year
  , gc.sum_legal_amount
  , merge_flags.gab
  , merge_flags.amp
  , merge_flags.re
  , merge_flags.kac
  , merge_flags.health
  , merge_flags.total_dues_hh
  , merge_flags.curr_ksm_manager
  , merge_flags.prospect_manager_id
  , merge_flags.prospect_manager
  , merge_flags.lgos
  , merge_flags.managed_hierarchy
From grouped_cash gc
Left Join merge_flags
  On merge_flags.household_id = gc.household_id
