Create Or Replace View vt_advisory_committees_dues As

With

hhf As (
  Select *
  From rpt_pbh634.v_entity_ksm_households
)

, boards_data As (
  Select * From table(rpt_pbh634.ksm_pkg_tmp.tbl_committee_gab) gab
  Union 
  Select * From table(rpt_pbh634.ksm_pkg_tmp.tbl_committee_asia) -- EBFA
  Union
  Select * From table(rpt_pbh634.ksm_pkg_tmp.tbl_committee_amp)
  Union
  Select * From table(rpt_pbh634.ksm_pkg_tmp.tbl_committee_realEstCouncil)
  Union
  Select * From table(rpt_pbh634.ksm_pkg_tmp.tbl_committee_healthcare)
  Union
  Select * From table(rpt_pbh634.ksm_pkg_tmp.tbl_committee_privateEquity)
  Union
  Select * From table(rpt_pbh634.ksm_pkg_tmp.tbl_committee_womensLeadership)
  Union
  Select * From table(rpt_pbh634.ksm_pkg_tmp.tbl_committee_kac)
)

, board_ids As (
  Select
    id_number
    , Listagg(short_desc, '; ' || chr(13)) Within Group (Order By short_desc Asc)
      As boards_list
    , count(short_desc)
      As total_boards
  From boards_data
  Group By id_number
)

, entity_boards As (
  Select
    entity.id_number
    , entity.report_name
    , entity.institutional_suffix
    , board_ids.total_boards
    , board_ids.boards_list
    , Case When gab.id_number Is Not Null Then 'Y' End
      As gab
    , Case When gab_life.id_number Is Not Null Then 'Y' End
      As gab_life
    , Case When ebfa.id_number Is Not Null Then 'Y' End
      As ebfa
    , Case When amp.id_number Is Not Null Then 'Y' End
      As amp
      , Case When re.id_number Is Not Null Then 'Y' End
      As re
      , Case When health.id_number Is Not Null Then 'Y' End
      As health
      , Case When peac.id_number Is Not Null Then 'Y' End
      As peac
      , Case When kac.id_number Is Not Null Then 'Y' End
      As kac
    , Case When kwlc.id_number Is Not Null Then 'Y' End
      As kwlc
  From board_ids
  Inner Join entity
    On entity.id_number = board_ids.id_number
  Left Join boards_data gab
    On gab.id_number = entity.id_number
    And gab.role <> 'Life Member'
    And gab.committee_code = 'U'
  Left Join boards_data gab_life
    On gab_life.id_number = entity.id_number
    And gab_life.role = 'Life Member'
    And gab_life.committee_code = 'U'
  Left Join boards_data ebfa
    On ebfa.id_number = entity.id_number
    And ebfa.committee_code = 'KEBA'
  Left Join boards_data amp
    On amp.id_number = entity.id_number
    And amp.committee_code = 'KAMP'
  Left Join boards_data re
    On re.id_number = entity.id_number
    And re.committee_code = 'KREAC'
  Left Join boards_data health
    On health.id_number = entity.id_number
    And health.committee_code = 'HAK'
  Left Join boards_data peac
    On peac.id_number = entity.id_number
    And peac.committee_code = 'KPETC'
  Left Join boards_data kac
    On kac.id_number = entity.id_number
    And kac.committee_code = 'KACNA'
  Left Join boards_data kwlc
    On kwlc.id_number = entity.id_number
    And kwlc.committee_code = 'KWLC'
  Order By
    entity.report_name Asc
)

, boards As (
  Select
    id_number
    , report_name
    , institutional_suffix
    , total_boards
    , boards_list
    , gab
    , gab_life
    , ebfa
    , amp
    , re
    , health
    , peac
    , kac
    , kwlc
    -- Sum board dues per person based on memberships that year
    , Case When gab Is Not Null Then ksm_pkg_committee.get_numeric_constant('dues_gab') Else 0 End
      + Case When gab_life Is Not Null Then ksm_pkg_committee.get_numeric_constant('dues_gab_life') Else 0 End
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
    Or gab_life Is Not Null
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
    , hhf.household_rpt_name
    , sum(total_boards)
      As total_boards_hh
    , sum(boards.total_dues)
      As total_dues_hh
    , count(boards.gab) As gab
    , count(boards.gab_life) As gab_life
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
  Group By
    hhf.household_id
    , hhf.household_rpt_name
)

, boards_hh_cash As (
  Select
    gc.id_number
    , gc.fiscal_year
    , gc.cash_category
    , sum(gc.legal_amount)
      As total_legal_amt
    , sum(Case When gc.fytd_ind = 'Y' Then gc.legal_amount Else 0 End)
      As total_legal_amt_ytd
  From v_ksm_giving_cash gc
  Cross Join rpt_pbh634.v_current_calendar cal
  Where gc.fiscal_year Between cal.curr_fy - 1 And cal.curr_fy
  Group By
    gc.id_number
    , gc.fiscal_year
    , gc.cash_category
)

Select
  boards_hh.household_id
  , boards_hh.household_rpt_name
  , boards_hh.total_boards_hh
  , boards_hh.total_dues_hh
  , boards.*
  , cal.curr_fy
  , cash.fiscal_year
  , cash.cash_category
  , cash.total_legal_amt
  , cash.total_legal_amt_ytd
From boards
Cross Join rpt_pbh634.v_current_calendar cal
Inner Join hhf
  On hhf.id_number = boards.id_number
Inner Join boards_hh
  On boards_hh.household_id = hhf.household_id
-- Giving
Left Join boards_hh_cash cash
  On cash.id_number = boards.id_number
