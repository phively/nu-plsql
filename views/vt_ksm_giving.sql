Create Or Replace View vt_ksm_giving_dei As

With

params As (
  Select
    to_date('20200601', 'yyyymmdd') -- Time-bound alloc start date
    As tb_start_dt
  From DUAL
)

Select
  gt.*
  , Case
      -- Full allocations
      When gt.allocation_code In (
          '3203005797501GFT' -- KSM DEI Scholarship Fund
        , '4104005655401END' -- Anonymous Scholarship
        , '3203002858501GFT' -- Named scholarship fund (CC)
        , '4104005824501END' -- Named scholarship fund (W)
        , '3203005848101GFT' -- DEI PE
        , '4104005859001END' -- Named scholarship (S)
        , '3203005856201GFT' -- Named scholarship (Fl)
        , '6506005776801GFT' -- GM scholarship 2020
        , '6509000000901GFT' -- GM scholarship 2021
        , '4104006012801END' -- Named scholarship (G)
        , '3203005795201GFT' -- DEI programmatic
        , '3203004707901GFT' -- GIM (S)
        , '3203004600201GFT' -- GIM (W)
        , '3203004993001GFT' -- GIM - general
        , '4104000458301END' -- Named DEI (C)
        , '3203006030801GFT' -- Named social impact fund (G)
        , '3203005973601GFT' -- Venture Equity Course
      )
        Then 'Y'
      -- Time-bound allocations
      When gt.allocation_code In (
          '6506004996701GFT'
        , '6506004769701GFT'
        , '6506005013601GFT'
      )
        And gt.date_of_record >= params.tb_start_dt
        Then 'Y'
      -- Specific gifts/bequests
      When gt.allocation_code = '3203004290301GFT' -- Unrestricted Bequest
        And tx_number = '0002795095' -- (K)
        Then 'Y'
      When gt.allocation_code = '3203000970801GFT' -- Dean's Scholarship
        And tx_number = '0002850780' -- (bequest, Fd)
        Then 'Y'
    End
    As dei_flag
From v_ksm_giving_trans gt
Cross Join params
Where gt.allocation_code
-- Include allocs
In (
  '3203005797501GFT' -- KSM DEI Scholarship Fund
  ,'4104005655401END' -- Anonymous Scholarship
  ,'3203004290301GFT'
  ,'3203005797501GFT'
  ,'3203002858501GFT'
  ,'4104005824501END'
  ,'3203005848101GFT'
  ,'4104005859001END'
  ,'3203005856201GFT'
  ,'6506005776801GFT'
  ,'6509000000901GFT'
  ,'3203000970801GFT'
  ,'4104006012801END'
  ,'3203005795201GFT'
  ,'3203004707901GFT'
  ,'3203004600201GFT'
  ,'3203004993001GFT'
  ,'4104000458301END'
  ,'6506004996701GFT'
  ,'6506004769701GFT'
  ,'6506005013601GFT'
  ,'3203006030801GFT'
  ,'3203005973601GFT'
  ,'3303000891601GFT'
)
Order By date_of_record Desc
;
