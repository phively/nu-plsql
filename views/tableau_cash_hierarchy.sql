Create Or Replace View tableau_cash_hierarchy As

With

attr_cash As (
  Select
    kgc.*
    -- All past managed grouped into Unmanaged
    , Case
        When substr(managed_hierarchy, 1, 9) = 'Unmanaged'
          Then 'Unmanaged'
        When managed_hierarchy = 'CFR'
          Then 'NU'
        Else managed_hierarchy
        End
      As managed_grp
    , mve.household_id
      As src_donor_hhid
  From v_ksm_gifts_cash kgc
  Inner Join mv_entity mve
    On mve.donor_id = kgc.source_donor_id
)

, grouped_cash As (
  Select
    attr_cash.cash_category
    , attr_cash.src_donor_hhid
      As household_id
    , attr_cash.fiscal_year
    , attr_cash.managed_grp
    , sum(attr_cash.cash_countable_amount)
      As sum_cash_countable_amount
    , sum(Case When attr_cash.fytd_indicator = 'Y' Then attr_cash.cash_countable_amount Else 0 End)
      As sum_cash_countable_amount_ytd
    , count(attr_cash.src_donor_hhid) Over(Partition By cash_category, attr_cash.src_donor_hhid, fiscal_year)
      As n_managed_in_group
  From attr_cash
  Group By
    attr_cash.cash_category
    , attr_cash.src_donor_hhid
    , attr_cash.fiscal_year
    , attr_cash.managed_grp
)

, pivot_cash As (
  -- Pivot cash category/household/fiscal year by managed group, for later use with board dues
  Select *
  From (
    Select
      cash_category
      , household_id
      , fiscal_year
      , managed_grp
      , sum_cash_countable_amount
      , n_managed_in_group
  From grouped_cash
  ) Pivot (
    sum(sum_cash_countable_amount)
    For managed_grp In ('Unmanaged', 'MGO', 'LGO', 'KSM', 'NU')
  )
)

, pivot_cash_ytd As (
  -- Pivot cash category/household/fiscal year by managed group, for later use with board dues
  Select *
  From (
    Select
      cash_category
      , household_id
      , fiscal_year
      , managed_grp
      , sum_cash_countable_amount_ytd
      , n_managed_in_group
  From grouped_cash
  ) Pivot (
    sum(sum_cash_countable_amount_ytd)
    For managed_grp In ('Unmanaged', 'MGO', 'LGO', 'KSM', 'NU')
  )
)

, pivot_retention As (
  -- Pivot sum(cash_countable_amount) by fiscal year, to compute retained status
  Select *
  From (
    Select
      household_id
      , fiscal_year
      , sum_cash_countable_amount
    From grouped_cash
  ) Pivot (
    sum(sum_cash_countable_amount)
    For fiscal_year In (2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027, 2028, 2029, 2030)
  )
)

, pivot_retention_ytd As (
  -- Pivot sum(cash_countable_amount) by fiscal year, to compute retained status
  Select *
  From (
    Select
      household_id
      , fiscal_year
      , sum_cash_countable_amount_ytd
    From grouped_cash
  ) Pivot (
    sum(sum_cash_countable_amount_ytd)
    For fiscal_year In (2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027, 2028, 2029, 2030)
  )
)

, cash_retention As (
    Select 
      pivot_retention.household_id
      , Case When "2022" > 0 And "2021" > 0 Then 'Y' End As "2022"
      , Case When "2023" > 0 And "2022" > 0 Then 'Y' End As "2023"
      , Case When "2024" > 0 And "2023" > 0 Then 'Y' End As "2024"
      , Case When "2025" > 0 And "2024" > 0 Then 'Y' End As "2025"
      , Case When "2026" > 0 And "2025" > 0 Then 'Y' End As "2026"
      , Case When "2027" > 0 And "2026" > 0 Then 'Y' End As "2027"
      , Case When "2028" > 0 And "2027" > 0 Then 'Y' End As "2028"
      , Case When "2029" > 0 And "2028" > 0 Then 'Y' End As "2029"
      , Case When "2030" > 0 And "2029" > 0 Then 'Y' End As "2030"
    From pivot_retention
)

, cash_retention_ytd As (
    Select 
      pivot_retention_ytd.household_id
      , Case When "2022" > 0 And "2021" > 0 Then 'Y' End As "2022"
      , Case When "2023" > 0 And "2022" > 0 Then 'Y' End As "2023"
      , Case When "2024" > 0 And "2023" > 0 Then 'Y' End As "2024"
      , Case When "2025" > 0 And "2024" > 0 Then 'Y' End As "2025"
      , Case When "2026" > 0 And "2025" > 0 Then 'Y' End As "2026"
      , Case When "2027" > 0 And "2026" > 0 Then 'Y' End As "2027"
      , Case When "2028" > 0 And "2027" > 0 Then 'Y' End As "2028"
      , Case When "2029" > 0 And "2028" > 0 Then 'Y' End As "2029"
      , Case When "2030" > 0 And "2029" > 0 Then 'Y' End As "2030"
    From pivot_retention_ytd
)

, retention_flag As (
  Select Distinct *
  From cash_retention
  Unpivot (
    retained
    For retained_year In ("2022", "2023", "2024", "2025", "2026", "2027", "2028", "2029", "2030")
  )
)

, retention_flag_ytd As (
  Select Distinct *
  From cash_retention_ytd
  Unpivot (
    retained
    For retained_year In ("2022", "2023", "2024", "2025", "2026", "2027", "2028", "2029", "2030")
  )
)

, cash_years As (
  Select Distinct fiscal_year
  From attr_cash
)

, boards_data As (
  Select
      ca.constituent_donor_id
      As donor_id
    , ca.involvement_code
    , ca.involvement_name
    , ca.involvement_role
    , ca.involvement_status
    , ca.involvement_start_date
    , ca.involvement_end_date
    , nvl(ca.involvement_start_fy, 2021)
      As fy_start
    , nvl(ca.involvement_end_fy, 9999)
      As fy_stop
    -- Start date is used, if present; else fill in Sep 1 for partial dates
    , Case
        When ca.involvement_start_date Is Not Null
          Then ca.involvement_start_date
        When ca.involvement_start_date Is Null
          Then ksm_pkg_utility.to_date_parse(ca.involvement_start_date, fallback_dt => to_date('20200901', 'yyyymmdd'))
        End
      As start_dt_calc
    -- Stop date is used if present; else fill in Aug 31 for partial dates; else for past participation use date modified
    -- If committee status is current use a far future date (year 9999)
    , Case
        When ca.involvement_end_date Is Not Null
          Then ca.involvement_end_date
        When ca.involvement_status <> 'Current' And ca.involvement_end_date Is Not Null
          Then ksm_pkg_utility.to_date_parse(ca.involvement_end_date, fallback_dt => to_date('20200831', 'yyyymmdd'))
        When ca.involvement_status = 'Current'
          Then to_date('99991231', 'yyyymmdd')
        End
      As stop_dt_calc
    , trunc(ca.etl_update_date)
      As etl_update_date
  From v_committees_all ca
  Where
    (
      -- Select boards
      ca.involvement_code In (
        'COM-KEBA' -- ebfa
        , 'COM-KAMP' -- amp
        , 'COM-KREAC' -- real estate
        , 'COM-HAK' -- healthcare
        , 'COM-KPETC' -- peac
        , 'VOL-KACNA' -- kac
        , 'COM-KWLC' -- kwlc
      ) Or (
        -- GAB but not GAB Life
        ca.involvement_code = 'COM-U' -- gab
        And ca.involvement_role <> 'Former' -- Life Member
      )
    ) And (
      -- Include only board membership within the cash counting period
      involvement_start_fy >= (Select min(fiscal_year) From cash_years)
      Or involvement_end_fy >= (Select min(fiscal_year) From cash_years)
    )
)

, board_ids As (
  Select Distinct donor_id
  From boards_data
)

, entity_boards As (
  -- Year-by-year board membership; one year + donor_id per row
  Select
    cash_years.fiscal_year
    , mve.household_id
    , mve.donor_id
    , mve.sort_name
    , mve.institutional_suffix
    , Case When gab.donor_id Is Not Null Then 'Y' End
      As gab
    , Case When ebfa.donor_id Is Not Null Then 'Y' End
      As ebfa
    , Case When amp.donor_id Is Not Null Then 'Y' End
      As amp
      , Case When re.donor_id Is Not Null Then 'Y' End
      As re
      , Case When health.donor_id Is Not Null Then 'Y' End
      As health
      , Case When peac.donor_id Is Not Null Then 'Y' End
      As peac
      , Case When kac.donor_id Is Not Null Then 'Y' End
      As kac
    , Case When kwlc.donor_id Is Not Null Then 'Y' End
      As kwlc
  From board_ids
  Cross Join cash_years
  Inner Join mv_entity mve
    On mve.donor_id = board_ids.donor_id
  Left Join boards_data gab
    On gab.donor_id = mve.donor_id
    And cash_years.fiscal_year Between gab.fy_start And gab.fy_stop
    And gab.involvement_code = 'COM-U'
  Left Join boards_data ebfa
    On ebfa.donor_id = mve.donor_id
    And cash_years.fiscal_year Between ebfa.fy_start And ebfa.fy_stop
    And ebfa.involvement_code = 'COM-KEBA'
  Left Join boards_data amp
    On amp.donor_id = mve.donor_id
    And cash_years.fiscal_year Between amp.fy_start And amp.fy_stop
    And amp.involvement_code = 'COM-KAMP'
  Left Join boards_data re
    On re.donor_id = mve.donor_id
    And cash_years.fiscal_year Between re.fy_start And re.fy_stop
    And re.involvement_code = 'COM-KREAC'
  Left Join boards_data health
    On health.donor_id = mve.donor_id
    And cash_years.fiscal_year Between health.fy_start And health.fy_stop
    And health.involvement_code = 'COM-HAK'
  Left Join boards_data peac
    On peac.donor_id = mve.donor_id
    And cash_years.fiscal_year Between peac.fy_start And peac.fy_stop
    And peac.involvement_code = 'COM-KPETC'
  Left Join boards_data kac
    On kac.donor_id = mve.donor_id
    And cash_years.fiscal_year Between kac.fy_start And kac.fy_stop
    And kac.involvement_code = 'VOL-KACNA'
  Left Join boards_data kwlc
    On kwlc.donor_id = mve.donor_id
    And cash_years.fiscal_year Between kwlc.fy_start And kwlc.fy_stop
    And kwlc.involvement_code = 'COM-KWLC'
  Order By
    mve.sort_name Asc
    , cash_years.fiscal_year Asc
)

, boards As (
  Select
    fiscal_year
    , household_id
    , donor_id
    , gab
    , ebfa
    , amp
    , re
    , health
    , peac
    , kac
    , kwlc
    -- Sum board dues per person based on memberships that year
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
    boards.household_id
    , boards.fiscal_year
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
  Group By
    boards.household_id
    , boards.fiscal_year
  Order By
    boards.household_id Asc
    , boards.fiscal_year Asc
)

, merged_data As (
  Select
    gc.cash_category
    , gc.household_id
    , gc.fiscal_year
    , gc.n_managed_in_group
    , boards_hh.gab
    , boards_hh.ebfa
    , boards_hh.amp
    , boards_hh.re
    , boards_hh.health
    , boards_hh.peac
    , boards_hh.kac
    , boards_hh.kwlc
    -- Board dues should come out of Expendable funds
    , Case
        When gc.cash_category = 'Expendable'
          Then boards_hh.total_dues_hh
        End
      As total_dues_hh
    -- Board dues: first take from unmanaged, then KSM, then NU, then MGO, then LGO
    -- For expendable, board_amt is at least sum_cash_countable_amount up to total_dues_hh
    , Case
        When cash_category = 'Expendable'
          And total_dues_hh Is Not Null
          Then
        -- Check if Unmanaged >= total_dues_hh
        Case
          When nvl("'Unmanaged'", 0) >= boards_hh.total_dues_hh
            Then 'U'
        -- Check if Unmanaged + KSM >= total_dues_hh
          When nvl("'Unmanaged'", 0) + nvl("'KSM'", 0) >= boards_hh.total_dues_hh
            Then 'UK'
        -- Check if Unmanaged + KSM + NU >= total_dues_hh
          When nvl("'Unmanaged'", 0) + nvl("'KSM'", 0) + nvl("'NU'", 0) >= boards_hh.total_dues_hh
            Then 'UKN'
        -- Check if Unmanaged + KSM + NU + MGO >= total_dues_hh
          When nvl("'Unmanaged'", 0) + nvl("'KSM'", 0) + nvl("'NU'", 0) + nvl("'MGO'", 0) >= boards_hh.total_dues_hh
            Then 'UKNM'
        -- Fallback: take from everything
          Else 'UKNML'
          End
        End
      As boards_cash_source
    , nvl(gc."'Unmanaged'", 0)
      As U
    , nvl(gc."'MGO'", 0)
      As M
    , nvl(gc."'LGO'", 0)
      As L
    , nvl(gc."'KSM'", 0)
      As K
    , nvl(gc."'NU'", 0)
      As N
  From pivot_cash gc
  Left Join boards_hh
    On boards_hh.household_id = gc.household_id
    And boards_hh.fiscal_year = gc.fiscal_year
)

, prefinal_data As (
  Select
    merged_data.cash_category
    , merged_data.household_id
    , merged_data.fiscal_year
    , merged_data.n_managed_in_group
    , merged_data.gab
    , merged_data.ebfa
    , merged_data.amp
    , merged_data.re
    , merged_data.health
    , merged_data.peac
    , merged_data.kac
    , merged_data.kwlc
    , merged_data.total_dues_hh
    , merged_data.boards_cash_source
    , U
    , K
    , N
    , M
    , L
    -- Compute board dues based on the boards_cash_source string
    -- Use least() function to ensure amount is at most total_dues_hh
    , Case
        When boards_cash_source = 'U'
          Then nullif(least(U, total_dues_hh), 0)
        When boards_cash_source = 'UK'
          Then nullif(least(U + K, total_dues_hh), 0)
        When boards_cash_source = 'UKN'
          Then nullif(least(U + K + N, total_dues_hh), 0)            
        When boards_cash_source = 'UKNM'
          Then nullif(least(U + K + N + M, total_dues_hh), 0)
        When boards_cash_source = 'UKNML'
          Then nullif(least(U + K + N + M + L, total_dues_hh), 0)
        End
      As "Boards"
    -- Zero (null) out the corresponding column if boards_cash_source found that amount is needed for dues
    -- Use greatest() function to ensure remaining amount is at least 0
    , Case
        When boards_cash_source = 'U'
          Then nullif(greatest(U - total_dues_hh, 0), 0)
        When regexp_like(boards_cash_source, 'K|N|M|L')
          Then Null
        Else nullif(U, 0)
        End
      As "Unmanaged"
    , Case
        When boards_cash_source Like '%K'
          Then nullif(greatest(U + K - total_dues_hh, 0), 0)
        When regexp_like(boards_cash_source, 'N|M|L')
          Then Null
        Else nullif(K, 0)
        End
      As "KSM"
    , Case
        When boards_cash_source Like '%N'
          Then nullif(greatest(U + K + N - total_dues_hh, 0), 0)
        When regexp_like(boards_cash_source, 'M|L')
          Then Null
        Else nullif(N, 0)
        End
      As "NU"
    , Case
        When boards_cash_source Like '%M'
          Then nullif(greatest(U + K + N + M - total_dues_hh, 0), 0)
        When regexp_like(boards_cash_source, 'L')
          Then Null
        Else nullif(M, 0)
        End
      As "MGO"
    , Case
        When boards_cash_source Like '%L'
          Then nullif(greatest(U + K + N + M + L - total_dues_hh, 0), 0)
        Else nullif(L, 0)
        End
      As "LGO"
  From merged_data
)

-- Unpivot final results
, finalnonytd As (
  Select
    unpiv.*
    -- Use retained_cfy to use CURRENT FY retention with CFY as the denominator
    -- e.g. count(distinct household_id) where fiscal_year = cal.cfy group by retained_cfy
    , retain_cfy.retained As retained_cfy
    , retain_cfy.retained_year As retained_cfy_year
    -- Use retained_nfy to compute NEXT FY retention with CFY as denominator
    -- e.g. count(distinct household_id) where fiscal_year = cal.cfy group by retained_nfy
    , retain_nfy.retained As retained_nfy
    , retain_nfy.retained_year As retained_nfy_year
  From (
    Select *
    From prefinal_data
    Unpivot (
      cash_countable_amount
      For managed_grp In ("Boards", "Unmanaged", "KSM", "NU", "MGO", "LGO")
    )
  ) unpiv
  Left Join retention_flag retain_cfy
    On retain_cfy.household_id = unpiv.household_id
    And retain_cfy.retained_year = unpiv.fiscal_year
  Left Join retention_flag retain_nfy
    On retain_nfy.household_id = unpiv.household_id
    And retain_nfy.retained_year - 1 = unpiv.fiscal_year
)

-- Build ytd results
, merged_data_ytd As (
  Select
    gc.cash_category
    , gc.household_id
    , gc.fiscal_year
/*    , gc.n_managed_in_group
    , boards_hh.gab
    , boards_hh.ebfa
    , boards_hh.amp
    , boards_hh.re
    , boards_hh.health
    , boards_hh.peac
    , boards_hh.kac
    , boards_hh.kwlc
*/    -- Board dues should come out of Expendable funds
    , Case
        When gc.cash_category = 'Expendable'
          Then boards_hh.total_dues_hh
        End
      As total_dues_hh
    -- Board dues: first take from unmanaged, then KSM, then NU, then MGO, then LGO
    -- For expendable, board_amt is at least sum_cash_countable_amount up to total_dues_hh
    , Case
        When cash_category = 'Expendable'
          And total_dues_hh Is Not Null
          Then
        -- Check if Unmanaged >= total_dues_hh
        Case
          When nvl("'Unmanaged'", 0) >= boards_hh.total_dues_hh
            Then 'U'
        -- Check if Unmanaged + KSM >= total_dues_hh
          When nvl("'Unmanaged'", 0) + nvl("'KSM'", 0) >= boards_hh.total_dues_hh
            Then 'UK'
        -- Check if Unmanaged + KSM + NU >= total_dues_hh
          When nvl("'Unmanaged'", 0) + nvl("'KSM'", 0) + nvl("'NU'", 0) >= boards_hh.total_dues_hh
            Then 'UKN'
        -- Check if Unmanaged + KSM + NU + MGO >= total_dues_hh
          When nvl("'Unmanaged'", 0) + nvl("'KSM'", 0) + nvl("'NU'", 0) + nvl("'MGO'", 0) >= boards_hh.total_dues_hh
            Then 'UKNM'
        -- Fallback: take from everything
          Else 'UKNML'
          End
        End
      As boards_cash_source
    , nvl(gc."'Unmanaged'", 0)
      As U
    , nvl(gc."'MGO'", 0)
      As M
    , nvl(gc."'LGO'", 0)
      As L
    , nvl(gc."'KSM'", 0)
      As K
    , nvl(gc."'NU'", 0)
      As N
  From pivot_cash_ytd gc
  Left Join boards_hh
    On boards_hh.household_id = gc.household_id
    And boards_hh.fiscal_year = gc.fiscal_year
)

, prefinal_data_ytd As (
  Select
    merged_data_ytd.cash_category
    , merged_data_ytd.household_id
    , merged_data_ytd.fiscal_year
    , merged_data_ytd.total_dues_hh
    , merged_data_ytd.boards_cash_source
    , U
    , K
    , N
    , M
    , L
    -- Compute board dues based on the boards_cash_source string
    -- Use least() function to ensure amount is at most total_dues_hh
    , Case
        When boards_cash_source = 'U'
          Then nullif(least(U, total_dues_hh), 0)
        When boards_cash_source = 'UK'
          Then nullif(least(U + K, total_dues_hh), 0)
        When boards_cash_source = 'UKN'
          Then nullif(least(U + K + N, total_dues_hh), 0)            
        When boards_cash_source = 'UKNM'
          Then nullif(least(U + K + N + M, total_dues_hh), 0)
        When boards_cash_source = 'UKNML'
          Then nullif(least(U + K + N + M + L, total_dues_hh), 0)
        End
      As "Boards"
    -- Zero (null) out the corresponding column if boards_cash_source found that amount is needed for dues
    -- Use greatest() function to ensure remaining amount is at least 0
    , Case
        When boards_cash_source = 'U'
          Then nullif(greatest(U - total_dues_hh, 0), 0)
        When regexp_like(boards_cash_source, 'K|N|M|L')
          Then Null
        Else nullif(U, 0)
        End
      As "Unmanaged"
    , Case
        When boards_cash_source Like '%K'
          Then nullif(greatest(U + K - total_dues_hh, 0), 0)
        When regexp_like(boards_cash_source, 'N|M|L')
          Then Null
        Else nullif(K, 0)
        End
      As "KSM"
    , Case
        When boards_cash_source Like '%N'
          Then nullif(greatest(U + K + N - total_dues_hh, 0), 0)
        When regexp_like(boards_cash_source, 'M|L')
          Then Null
        Else nullif(N, 0)
        End
      As "NU"
    , Case
        When boards_cash_source Like '%M'
          Then nullif(greatest(U + K + N + M - total_dues_hh, 0), 0)
        When regexp_like(boards_cash_source, 'L')
          Then Null
        Else nullif(M, 0)
        End
      As "MGO"
    , Case
        When boards_cash_source Like '%L'
          Then nullif(greatest(U + K + N + M + L - total_dues_hh, 0), 0)
        Else nullif(L, 0)
        End
      As "LGO"
  From merged_data_ytd
)

-- Unpivot ytd results
, finalytd As (
  Select
    unpiv.*
    -- Use retained_cfy to use CURRENT FY retention with CFY as the denominator
    -- e.g. count(distinct household_id) where fiscal_year = cal.cfy group by retained_cfy
    , retain_cfy.retained As retained_cfy
    , retain_cfy.retained_year As retained_cfy_year
    -- Use retained_nfy to compute NEXT FY retention with CFY as denominator
    -- e.g. count(distinct household_id) where fiscal_year = cal.cfy group by retained_nfy
    , retain_nfy.retained As retained_nfy
    , retain_nfy.retained_year As retained_nfy_year
  From (
    Select *
    From prefinal_data_ytd
    Unpivot (
      cash_countable_amount
      For managed_grp In ("Boards", "Unmanaged", "KSM", "NU", "MGO", "LGO")
    )
  ) unpiv
  Left Join retention_flag_ytd retain_cfy
    On retain_cfy.household_id = unpiv.household_id
    And retain_cfy.retained_year = unpiv.fiscal_year
  Left Join retention_flag_ytd retain_nfy
    On retain_nfy.household_id = unpiv.household_id
    And retain_nfy.retained_year - 1 = unpiv.fiscal_year
)

Select
  f.cash_category
  , f.household_id
  , hh.household_account_name
  , hh.household_primary_full_name
  , hh.household_spouse_full_name
  , f.fiscal_year
  , f.n_managed_in_group
  , f.gab
  , f.ebfa
  , f.amp
  , f.re
  , f.health
  , f.peac
  , f.kac
  , f.kwlc
  , f.total_dues_hh
  , f.boards_cash_source
  , f.u
  , f.k
  , f.n
  , f.m
  , f.l
  , f.managed_grp
  , f.cash_countable_amount
  , f.retained_cfy
  , f.retained_cfy_year
  , f.retained_nfy
  , f.retained_nfy_year
  -- YTD columns
  , fy.boards_cash_source
    As ytd_boards_cash_source
  , fy.u
    As ytd_u
  , fy.k
    As ytd_k
  , fy.n
    As ytd_n
  , fy.m
    As ytd_m
  , fy.l
    As ytd_l
  , fy.cash_countable_amount
    As ytd_cash_countable_amount
  , fy.retained_cfy
    As ytd_retained_cfy
  , fy.retained_cfy_year
    As ytd_retained_cfy_year
  , fy.retained_nfy
    As ytd_retained_nfy
  , fy.retained_nfy_year
    As ytd_retained_nfy_year
From finalnonytd f
Inner Join mv_households hh
  On hh.household_id = f.household_id
  And hh.household_primary = 'Y'
Left Join finalytd fy
  On fy.household_id = f.household_id
  And fy.fiscal_year = f.fiscal_year
  And fy.cash_category = f.cash_category
  And fy.managed_grp = f.managed_grp
;
