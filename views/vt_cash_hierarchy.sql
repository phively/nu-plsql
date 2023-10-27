With

hhf As (
  Select *
  From v_entity_ksm_households_fast
)

, allocs As (
  Select *
  From table(rpt_pbh634.ksm_pkg_allocation.tbl_cash_alloc_groups)
)

, board_ids As (
  Select id_number From table(ksm_pkg_tmp.tbl_committee_gab)
  Union
  Select id_number From table(ksm_pkg_tmp.tbl_committee_asia)
  Union
  Select id_number From table(ksm_pkg_tmp.tbl_committee_amp)
  Union
  Select id_number From table(ksm_pkg_tmp.tbl_committee_realEstCouncil)
  Union
  Select id_number From table(ksm_pkg_tmp.tbl_committee_healthcare)
  Union
  Select id_number From table(ksm_pkg_tmp.tbl_committee_privateEquity)
  Union
  Select id_number From table(ksm_pkg_tmp.tbl_committee_kac)
  Union
  Select id_number From table(ksm_pkg_tmp.tbl_committee_womensLeadership)
)

, entity_boards As (
  Select
  entity.id_number
  , entity.report_name
  , entity.institutional_suffix
  , Case When gab.id_number Is Not Null Then 'Y' End As gab
  , Case When ebfa.id_number Is Not Null Then 'Y' End As ebfa
  , Case When amp.id_number Is Not Null Then 'Y' End As amp
  , Case When re.id_number Is Not Null Then 'Y' End As re
  , Case When health.id_number Is Not Null Then 'Y' End As health
  , Case When peac.id_number Is Not Null Then 'Y' End As peac
  , Case When kac.id_number Is Not Null Then 'Y' End As kac
  , Case When kwlc.id_number Is Not Null Then 'Y' End As kwlc
  From board_ids
  Inner Join entity
    On entity.id_number = board_ids.id_number
  Left Join table(ksm_pkg_tmp.tbl_committee_gab) gab
    On gab.id_number = entity.id_number
  Left Join table(ksm_pkg_tmp.tbl_committee_asia) ebfa
    On ebfa.id_number = entity.id_number
  Left Join table(ksm_pkg_tmp.tbl_committee_amp) amp
    On amp.id_number = entity.id_number
  Left Join table(ksm_pkg_tmp.tbl_committee_realEstCouncil) re
    On re.id_number = entity.id_number
  Left Join table(ksm_pkg_tmp.tbl_committee_healthcare) health
    On health.id_number = entity.id_number
  Left Join table(ksm_pkg_tmp.tbl_committee_privateEquity) peac
    On peac.id_number = entity.id_number
  Left Join table(ksm_pkg_tmp.tbl_committee_kac) kac
    On kac.id_number = entity.id_number
  Left Join table(ksm_pkg_tmp.tbl_committee_womensLeadership) kwlc
    On kwlc.id_number = entity.id_number
)

, boards As (
  Select
    id_number
    , gab
    , ebfa
    , amp
    , re
    , health
    , peac
    , kac
    , kwlc
    , Case When gab Is Not Null Then ksm_pkg_committee.get_numeric_constant('dues_gab') Else 0 End
      + Case When ebfa Is Not Null Then ksm_pkg_committee.get_numeric_constant('dues_ebfa') Else 0 End
      + Case When amp Is Not Null Then ksm_pkg_committee.get_numeric_constant('dues_amp') Else 0 End
      + Case When re Is Not Null Then ksm_pkg_committee.get_numeric_constant('dues_realestate') Else 0 End
      + Case When health Is Not Null Then ksm_pkg_committee.get_numeric_constant('dues_healthcare') Else 0 End
      + Case When peac Is Not Null Then ksm_pkg_committee.get_numeric_constant('dues_privateequity') Else 0 End
      + Case When kac Is Not Null Then ksm_pkg_committee.get_numeric_constant('dues_kac') Else 0 End
      + Case When kwlc Is Not Null Then ksm_pkg_committee.get_numeric_constant('dues_womensleadership') Else 0 End
      As total_dues
  From entity_boards
  Where gab Is Not Null
    Or ebfa Is Not Null
    Or amp Is Not Null
    Or re Is Not Null
    Or health Is Not Null
    Or peac Is Not Null
    Or kac Is Not Null
    Or kwlc Is Not Null
)

, boards_hh As (
  Select
    hhf.household_id
    , sum(boards.total_dues)
      As total_dues_hh
    , count(boards.gab) As gab
    , count(boards.ebfa) As ebfa
    , count(boards.amp) As amp
    , count(boards.re) As re
    , count(boards.health) As health
    , count(boards.peac) As peac
    , count(boards.kac) As kac
    , count(boards.kwlc) As kwlc
  From boards
  Inner Join hhf
    On hhf.id_number = boards.id_number
  Group By hhf.household_id
)

, ksm_mgrs As (
  Select
    id_number
    , team
  From table(ksm_pkg_tmp.tbl_frontline_ksm_staff)
  Where former_staff Is Null
)

, ksm_lgos As (
  Select id_number
  From ksm_mgrs
  Where team = 'AF'
)

, ksm_mgos As (
  Select id_number
  From ksm_mgrs
  Where team = 'MG'
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
            When vas.prospect_manager_id In (Select id_number From ksm_mgos)
              Then 'MGO'
            -- Any LGO
            When vas.lgos Is Not Null
              Then 'LGO'
            When vas.prospect_manager_id In (Select id_number From ksm_lgos)
              Then 'LGO'
            -- Any other KSM staff
            When vas.prospect_manager_id In (Select id_number From ksm_mgrs)
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
    , assigned_hh.managed_hierarchy
    From merge_ids
    Left Join boards_hh
      On boards_hh.household_id = merge_ids.household_id
    Left Join assigned_hh
      On assigned_hh.household_id = merge_ids.household_id
)

, prefinal_data As (
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
    -- Board dues should come out of Expendable funds
    , Case
        When gc.cash_category = 'Expendable'
          Then merge_flags.total_dues_hh
        End
      As total_dues_hh
    , merge_flags.curr_ksm_manager
    , merge_flags.prospect_manager_id
    , merge_flags.prospect_manager
    , merge_flags.lgos
    , nvl(merge_flags.managed_hierarchy, 'Unmanaged')
      As managed_hierarchy
    -- For managed_hierarchy = LGO, fill in LGO or PM; otherwise PM
    , Case
        When merge_flags.managed_hierarchy = 'LGO'
          And merge_flags.lgos Is Not Null
            Then merge_flags.lgos
        Else prospect_manager
        End
      As credited_manager
    -- For expendable, board_amt is at least sum_legal_amount up to total_dues_hh
    , Case
        When cash_category = 'Expendable'
          And total_dues_hh Is Not Null
          Then least(gc.sum_legal_amount, merge_flags.total_dues_hh)
        Else 0
        End
      As board_amt
    -- For expendable, nonboard_amt is at most sum_legal_amount - total_dues_hh
    , Case
        When cash_category = 'Expendable'
          And total_dues_hh Is Not Null
          Then greatest(gc.sum_legal_amount - merge_flags.total_dues_hh, 0)
        Else gc.sum_legal_amount
        End
      As nonboard_amt
  From grouped_cash gc
  Left Join merge_flags
    On merge_flags.household_id = gc.household_id
)

(
-- All rows where board_amt > 0, based on total_dues_hh
Select
  prefinal_data.*
  , 'Boards' As giving_source
  , board_amt As final_amt
From prefinal_data
Where board_amt > 0
) Union (
-- All rows where nonboard_amt > 0
Select
  prefinal_data.*
  , managed_hierarchy As giving_source
  , nonboard_amt As final_amt
From prefinal_data
Where nonboard_amt > 0
)
