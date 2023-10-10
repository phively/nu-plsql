With

allocs As (
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

, assigned As (
  Select
    vas.id_number
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
)

, grouped_cash As (
  Select
    allocs.cash_category
    , gth.household_id
    , gth.id_number
    , gth.fiscal_year
    , sum(gth.hh_credit) As sum_hh_credit
    , sum(gth.hh_recognition_credit) As sum_hh_recognition_credit
  From v_ksm_giving_trans_hh gth
  Inner Join allocs
    On allocs.allocation_code = gth.allocation_code
  Where gth.hh_credit > 0
    And tx_gypm_ind <> 'P'
    And gth.fiscal_year = 2023
  Group By
    allocs.cash_category
    , gth.household_id
    , gth.id_number
    , gth.fiscal_year
)

Select
  gc.cash_category
  , gc.household_id
  , gc.id_number
  , gc.sum_hh_credit
  , gc.sum_hh_recognition_credit
  , boards.gab
  , boards.amp
  , boards.re
  , boards.kac
  , boards.health
  , boards.total_dues
From grouped_cash gc
Left Join boards
  On boards.id_number = gc.id_number
Left Join assigned
  On assigned.id_number = gc.id_number
  
  
