Create Or Replace Package ksm_pkg_allocation Is

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_allocation';

/*************************************************************************
Public type declarations
*************************************************************************/

Type alloc_list Is Record (
  allocation_code allocation.allocation_code%type
  , status_code allocation.status_code%type
  , short_name allocation.short_name%type
  , af_flag allocation.annual_sw%type
);

Type alloc_info Is Record (
  allocation_code allocation.allocation_code%type
  , status_code allocation.status_code%type
  , short_name allocation.short_name%type
  , af_flag allocation.annual_sw%type
  , sweepable allocation.annual_sw%type
  , budget_relieving allocation.annual_sw%type 
);

Type thresh_alloc Is Record (
    allocation_code  allocation.allocation_code%type
    , short_name allocation.short_name%type
    , max_gift nu_gft_trp_gifttrans.legal_amount%type
);

Type t_cash_alloc Is Record (
  allocation_code allocation.allocation_code%type
  , alloc_name allocation.short_name%type
  , status_code allocation.status_code%type
  , alloc_school allocation.alloc_school%type
  , cash_category varchar2(64)
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type t_alloc_list Is Table Of alloc_list;
Type t_alloc_info Is Table Of alloc_info;
Type t_thresh_allocs Is Table Of thresh_alloc;
Type t_cash_alloc_groups Is Table Of t_cash_alloc;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

-- Table functions
Function tbl_alloc_annual_fund_ksm
  Return t_alloc_list Pipelined;

Function tbl_alloc_curr_use_ksm
  Return t_alloc_info Pipelined;

Function tbl_threshold_allocs
  Return t_thresh_allocs Pipelined;
  
Function tbl_cash_alloc_groups
  Return t_cash_alloc_groups Pipelined;

/*************************************************************************
Public cursors -- data definitions
*************************************************************************/

-- Definition of current and historical Kellogg Annual Fund allocations
-- Add any custom allocations in the indicated section below
Cursor c_alloc_annual_fund_ksm Is
  Select Distinct
    allocation_code
    , status_code
    , short_name
    , 'Y' As af_flag
  From allocation
  Where
    -- KSM af-flagged allocations
    (annual_sw = 'Y' And alloc_school = 'KM')
    -- Include additional fields
    Or allocation_code In (
      /************ UPDATE BELOW HERE ************/
        '3203003665401GFT' -- Expendable Excellence Grant (JRF)
      , '3203004227201GFT' -- Expendable Excellence Grant (DC)
      , '3203000861201GFT' -- Real Estate Conference
      , '3203004707901GFT' -- GIM Trip Scholarship (LS)
      , '3203002954201GFT' -- KSM Student Club Support
      , '3303001899301GFT' -- KSM Gift-In-Kind
      , '3203000859901GFT' -- Center for Nonprofit Management
      , '3203004959801GFT' -- Collaboration Plaza fund (MS -- building support)
      , '3203004993001GFT' -- GIM Trip Scholarships (general)
      , '3203003655501GFT' -- EMP Scholarships
      , '3203004984101GFT' -- Deloitte Scholarship
      , '3203005137401GFT' -- Expendable Excellence Grant (TMS)
      , '3203005214601GFT' -- Class of 1989 Scholarship
      , '3203005228501GFT' -- KFN Scholarship
      , '3203005334201GFT' -- KSM 1Y Class of 2019 Scholar
      , '3203005590301GFT' -- KSM Student Assistance Fund
      , '3203005848101GFT' -- KSM DEI PE Scholarship
      , '3203005797501GFT' -- KSM DEI Scholarship Fund
      , '3203005795201GFT' -- KSM DEI Programmatic Fund
      , '3203005856201GFT' -- John R. Flanagan Scholarship
      , '3203002858501GFT' -- Cox-Cohen Scholarship
      , '3203004600201GFT' -- Woodsum Student Travel
      , '3203005990501GFT' -- Finance Fellows Program
      , '3203003655701GFT' -- KSM PT Program Annual Fund
      , '3203004334701GFT' -- Non Profit Program Scholarship
      , '3203005261001GFT' -- Kellogg-Recanati EMBA AF
      , '3203006289601GFT' -- E/W Scholarship (expendable)
      , '3203003083401GFT' -- MMM Program General Fund
      , '3203003805101GFT' -- KSM MMM Scholarships
      , '3203002775901GFT' -- GM Minority/Women Scholarship
      , '3203006233401GFT' -- Fund for Inclusion (similar to GIM/LS)
      , '3203006379001GFT' -- KSM Expendable Scholarship (RG)
      , '3203006386201GFT' -- KSM Expendable Scholarship (JM)
      , '3203006453601GFT' -- Lowry DEI
      , '3203006469401GFT' -- Scholarship Fund (RS)
      , '3203006114401GFT' -- Finance Scholarship (MS)
      , '3203005228401GFT' -- Student Life
      , '3203002402701GFT' -- Unrestricted expendable (SH)
      , '3203006149601GFT' -- Vivo DEI
      , '3203006498701GFT' -- Unrestricted scholarships (VK)
      /************ UPDATE ABOVE HERE ************/
    )
  ;

-- Definition of Kellogg Current Use allocations for Annual Giving
Cursor c_alloc_curr_use_ksm Is
  With
  ksm_af As (
    Select *
    From table(ksm_pkg_allocation.tbl_alloc_annual_fund_ksm)
  )
  , sweepable As (
    Select
      allocation.allocation_code
      , allocation.short_name
      , allocation.long_name
      , Case
          -- Unrestricted scholarships
          When allocation.alloc_purpose In (
              'SFO' -- Scholarships/Fellowships: General
            , 'SFG' -- Scholarships/Fellowships: Graduate
          )
            Then 'Y'
          -- Allocation name contains
          When lower(allocation.long_name) Like '%excellence%'
            Or lower(allocation.long_name) Like '%kellogg%annual%fund%'
            Or lower(allocation.long_name) Like '%discretionary%'
            Or lower(allocation.long_name) Like '%dean%innovation%'
            Or lower(allocation.long_name) Like '%to%be%designated%'
            Or lower(allocation.long_name) Like '%unrestricted%bequest%'
            Or lower(allocation.long_name) Like '%provost%fund%kellogg%'
            Then 'Y'
          -- Fallback: not sweepable
          Else 'N'
          End
        As sweepable
    From allocation
  )
  , br As (
    Select
      allocation.allocation_code
      , allocation.short_name
      , allocation.long_name
      , sweepable.sweepable
      , Case
          -- Is sweepable
          When sweepable.sweepable = 'Y'
            Then 'Y'
          -- Fund name contains
          When lower(allocation.long_name) Like '%class of%'
            Or lower(allocation.long_name) Like '%class%gift%'
            Then 'Y'
          -- Fund name exclude
          When lower(allocation.long_name) Like '%event%'
            Or lower(allocation.long_name) Like '%conference%'
            Or lower(allocation.long_name) Like '%summit%'
            Or lower(allocation.long_name) Like '%challenge%'
            Or lower(allocation.long_name) Like '%competition%'
            Then 'N'
          -- Alloc purpose is:
          -- Lectures & Seminars - Women's Summit only
          When allocation.alloc_purpose = 'LSM'
            Then Case
              When lower(allocation.long_name) Like '%women%leadership%'
                Then 'Y'
              Else 'N'
              End
          -- Alloc purpose is:
          When allocation.alloc_purpose In (
                'MNT' -- Maintenance
              , 'CIS' -- Center & Institute Support
              , 'SLF' -- Student Life
            )
            Then 'Y'
          -- Alloc purpose exclude
          When allocation.alloc_purpose In (
              'NAA' -- Non-Academic Administration
            , 'NCP' -- Named Chairs & Professorships
            , 'PRZ' -- Prizes
            , 'SFU' -- Scholarships/Fellowships: Undergraduate
            , 'TBD' -- TBD/Miscellaneous
          )
            Then 'N'
          -- Center/priority, but flagged department
          When allocation.allocation_code In (
              '3203000855901GFT' -- HCAK
            , '3203000860901GFT' -- AMP
            , '3203004013501GFT' -- KIEI
            , '3203005114401GFT' -- GPRL
            , '3203005795201GFT' -- DEI
            , '3203004957901GFT' -- Ward Center
          )
            Then 'Y'
          -- CFAE purpose is
          When allocation.cfae_purpose_code In (
            'CU' -- Current Operations - Unrestricted
          )
            Then 'Y'
          -- Fallback
          Else 'N'
          End
        As budget_relieving
    From allocation
    Inner Join sweepable
      On sweepable.allocation_code = allocation.allocation_code
  )
  Select Distinct
    alloc.allocation_code
    , alloc.status_code
    , alloc.short_name
    , nvl(af_flag, 'N') As af_flag
    , br.sweepable
    , br.budget_relieving
  From allocation alloc
  Left Join ksm_af On ksm_af.allocation_code = alloc.allocation_code
  Left Join br On br.allocation_code = alloc.allocation_code
  Where (agency = 'CRU' And alloc_school = 'KM'
      And alloc.allocation_code <> '3303002283701GFT' -- Exclude Envision building gifts
    )
    Or alloc.allocation_code In ksm_af.allocation_code -- Include AF allocations that happen to not match criteria
  ;

End ksm_pkg_allocation;
/
Create Or Replace Package Body ksm_pkg_allocation Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

-- AF thresholded allocations: count up to max_gift dollars
Cursor c_thresh_allocs Is
  Select
    allocation.allocation_code
    , allocation.short_name
    , 100E3 As max_gift
  From allocation
  Where allocation_code In (
    '3203006213301GFT' -- KEC Fund
  )
  ;

-- Definition of KSM cash allocation categories for reconciliation with Finance counting rules
Cursor c_cash_alloc_groups Is
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
  ;

/*************************************************************************
Pipelined functions
*************************************************************************/

-- Returns a pipelined table
Function tbl_alloc_annual_fund_ksm
  Return t_alloc_list Pipelined As
    -- Declarations
    allocs t_alloc_list;

  Begin
    Open c_alloc_annual_fund_ksm; -- Annual Fund allocations cursor
      Fetch c_alloc_annual_fund_ksm Bulk Collect Into allocs;
    Close c_alloc_annual_fund_ksm;
    -- Pipe out the allocations
    For i in 1..(allocs.count) Loop
      Pipe row(allocs(i));
    End Loop;
    Return;
  End;

-- Returns a pipelined table
Function tbl_alloc_curr_use_ksm
  Return t_alloc_info Pipelined As
    -- Declarations
    allocs t_alloc_info;

  Begin
    Open c_alloc_curr_use_ksm; -- Annual Fund allocations cursor
      Fetch c_alloc_curr_use_ksm Bulk Collect Into allocs;
    Close c_alloc_curr_use_ksm;
    -- Pipe out the allocations
    For i in 1..(allocs.count) Loop
      Pipe row(allocs(i));
    End Loop;
    Return;
  End;

-- Returns a pipelined table
Function tbl_threshold_allocs
  Return t_thresh_allocs Pipelined As
    -- Declarations
    allocs t_thresh_allocs;

  Begin
    Open c_thresh_allocs; -- Annual Fund allocations cursor
      Fetch c_thresh_allocs Bulk Collect Into allocs;
    Close c_thresh_allocs;
    -- Pipe out the allocations
    For i in 1..(allocs.count) Loop
      Pipe row(allocs(i));
    End Loop;
    Return;
  End;

-- Returns a pipelined table
Function tbl_cash_alloc_groups
  Return t_cash_alloc_groups Pipelined As
    -- Declarations
    allocs t_cash_alloc_groups;

  Begin
    Open c_cash_alloc_groups; -- Annual Fund allocations cursor
      Fetch c_cash_alloc_groups Bulk Collect Into allocs;
    Close c_cash_alloc_groups;
    -- Pipe out the allocations
    For i in 1..(allocs.count) Loop
      Pipe row(allocs(i));
    End Loop;
    Return;
  End;

End ksm_pkg_allocation;
/
