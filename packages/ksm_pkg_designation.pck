Create Or Replace Package ksm_pkg_designation Is

/*************************************************************************
Author  : PBH634
Created : 4/22/2025
Purpose : Kellogg NGC, expendable cash, and campaign priority definitions.
Dependencies: dw_pkg_base, ksm_pkg_utility

Suggested naming conventions:
  Pure functions: [function type]_[description]
  Row-by-row retrieval (slow): get_[object type]_[action or description] e.g.
  Table or cursor retrieval (fast): tbl_[object type]_[action or description]
*************************************************************************/

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_designation';
campaign_kfc_start_fy Constant integer := 2022;

/*************************************************************************
Public type declarations
*************************************************************************/

--------------------------------------
Type rec_designation_list Is Record (
  designation_record_id dm_alumni.dim_designation.designation_record_id%type
  , designation_name dm_alumni.dim_designation.designation_name%type
  , designation_status dm_alumni.dim_designation.designation_status%type
  , legacy_allocation_code dm_alumni.dim_designation.legacy_allocation_code%type
  , ksm_af_flag varchar2(1)
  , ksm_cru_flag varchar2(1)
);

--------------------------------------
Type rec_cash_designation Is Record (
  designation_record_id dm_alumni.dim_designation.designation_record_id%type
  , designation_name dm_alumni.dim_designation.designation_name%type
  , designation_status dm_alumni.dim_designation.designation_status%type
  , legacy_allocation_code dm_alumni.dim_designation.legacy_allocation_code%type
  , ksm_af_flag varchar2(1)
  , ksm_cru_flag varchar2(1)
  , cash_category varchar2(64)
);

--------------------------------------
Type rec_campaign_designation Is Record (
  designation_record_id dm_alumni.dim_designation.designation_record_id%type
  , designation_name dm_alumni.dim_designation.designation_name%type
  , designation_status dm_alumni.dim_designation.designation_status%type
  , designation_start_date dm_alumni.dim_designation.gl_effective_date%type
  , designation_stop_date dm_alumni.dim_designation.gl_expiration_date%type
  , legacy_allocation_code dm_alumni.dim_designation.legacy_allocation_code%type
  , ksm_af_flag varchar2(1)
  , ksm_cru_flag varchar2(1)
  , campaign_priority varchar2(64)
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type designation_list Is Table Of rec_designation_list;
Type cash_designation Is Table Of rec_cash_designation;
Type campaign_designation Is Table Of rec_campaign_designation;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

-- Table functions
Function tbl_designation_ksm_af
  Return designation_list Pipelined;

Function tbl_designation_ksm_cru
  Return designation_list Pipelined;

Function tbl_designation_cash
  Return cash_designation Pipelined;

Function tbl_designation_campaign_kfc
  Return campaign_designation Pipelined;

End ksm_pkg_designation;
/
Create Or Replace Package Body ksm_pkg_designation Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

--------------------------------------
-- Definition of current and historical Kellogg Annual Fund allocations
-- Add any custom allocations in the indicated section below
Cursor c_designation_ksm_af Is
  Select Distinct
    designation_record_id
    , designation_name
    , designation_status
    , legacy_allocation_code
    , 'Y' As ksm_af_flag
    , 'Y' As ksm_cru_flag
  From table(dw_pkg_base.tbl_designation) des
  Where
    -- KSM AF-flagged allocations
    (
      nu_af_flag = 'Y'
      And ksm_flag = 'Y'
    )
    -- Include additional funds
    Or legacy_allocation_code In (
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

--------------------------------------
Cursor c_designation_ksm_cru Is
  Select Distinct
    des.designation_record_id
    , des.designation_name
    , des.designation_status
    , des.legacy_allocation_code
    , af.ksm_af_flag
    , 'Y' As ksm_cru_flag
  From table(dw_pkg_base.tbl_designation) des
  Left Join table(ksm_pkg_designation.tbl_designation_ksm_af) af
    On af.designation_record_id = des.designation_record_id
  Where (
      -- Base CRU definition
      ksm_flag = 'Y'
      And designation_tier_1 = 'Current Use'
    ) Or (
      -- Additional AF funds, if any
      des.designation_record_id In af.designation_record_id
    )
  ;

--------------------------------------
-- Definition of KSM cash allocation categories for reconciliation with Finance counting rules
Cursor c_designation_cash Is
    Select
      des.designation_record_id
      , des.designation_name
      , des.designation_status
      , des.legacy_allocation_code
      , cru.ksm_af_flag
      , cru.ksm_cru_flag
      , Case
          -- Inactive
          When des.designation_status != 'Active'
            Then 'Inactive'
          -- Exceptions
          When des.legacy_allocation_code In ('3203006993001GFT')
            Then 'Other/TBD'
          -- Kellogg Education Center
          When des.legacy_allocation_code In ('3203006213301GFT', '3203000860801GFT')
            Then 'KEC'
          -- Global Hub
          When des.legacy_allocation_code In ('3303002280601GFT', '3303002283701GFT', '3203004284701GFT')
            Then 'Hub Campaign Cash'
          -- Gift In Kind
          When des.legacy_allocation_code = '3303001899301GFT'
            Then 'Gift In Kind'
          -- All endowed
          When des.fin_fund_id Like '4%'
            Then 'Endowed'
          -- All current use
          When cru.ksm_cru_flag Is Not Null
            Then 'Expendable'
          -- Grant chartstring
          When des.fin_fund_id Like '6%'
            Then 'Grants'
          --  Fallback - to reconcile
          Else 'Other/TBD'
        End
        As cash_category
    From table(dw_pkg_base.tbl_designation) des
    Left Join table(ksm_pkg_designation.tbl_designation_ksm_cru) cru
      On cru.designation_record_id = des.designation_record_id
    Where ksm_flag = 'Y'
    ;

--------------------------------------
-- Definition of KSM 2022 campaign allocation categories
Cursor c_designation_campaign_kfc Is
  Select
    des.designation_record_id 
    , des.designation_name
    , des.designation_status
    , des.gl_effective_date
      As designation_start_date
    , des.gl_expiration_date
      As designation_stop_date
    , des.legacy_allocation_code
    , cru.ksm_af_flag
    , cru.ksm_cru_flag
    , Case
        When des.legacy_allocation_code In ('3203006114801GFT', '3203000855901GFT', '3203006747901GFT', '3203006433001GFT', '3203006709701GFT', '3203003574701GFT', '4104006715701END', '4104006525601END', '3203000860901GFT', '3203000855601GFT', '3203005655701GFT', '6506005492001GFT', '3203006362401GFT', '4104006934801END', '4314000112001END', '3203003083401GFT', '3203005356101GFT', '3203006799101GFT', '4824004951701ANN', '4824006221501ANN', '4824006221401ANN', '3203006067101GFT', '3203006800301GFT', '3203005973601GFT', '3203003691101GFB', '6506006016501GFT', '6506006363201GFT', '6506006655701GFT', '6506006774801GFT', '3203006305801GFT', '6506004996701GFT', '6506004769701GFT', '6506005839501GFT', '3203005924801GFT', '4824006221701ANN', '650CBCAWARDGF3', '4824006221601ANN', '3203000859901GFT', '3203000860201GFT', '4104002474401END', '3203004013501GFT', '6506006620901GFT', '3203005114401GFT', '3203006030801GFT', '3203006790401GFT', '3203002727201GFT', '3203006079901GFT', '3203000855301GFT', '3203000857401GFT', '3203000856501GFT', '3203002527201GFT', '3203006730801GFT', '3203006132201GFT', '3203004957901GFT', '3203003156801GFT', '3203006227301GFT', '6506006669801GFT', '3203005807801GFT', '4104000458301END', '3203006709501GFT', '4104006166601END', '3203004673301GFT', '4104006648601END'
          , '3203007028801GFT', '3203007025701GFT', '4104007025901END'
          , '4104007025901END', '3203007026801GFT')
          Then 'Faculty'
        When des.legacy_allocation_code In ('3203006213301GFT')
          Then 'KEC'
        When des.legacy_allocation_code In ('3203000860801GFT', '3203000860701GFT', '3203000859301GFT', '3203004290301GFT', '3203004471101GFT', '3203000970801GFT', '3203000854501GFT', '3203003655701GFT', '3203003655601GFT', '3303000891301GFT', '3203003203701GFT', '3203006289601GFT', '3303000990101GFT', '3203005797501GFT', '3203003764501GFT', '3203003805101GFT', '3203005590301GFT', '3203003655501GFT', '3203005597901GFT', '3203004284701GFT'
          , '3303001899301GFT')
          Then 'Kellogg Fund'
        When des.legacy_allocation_code In ('3203003212701GFT', '3203000861201GFT', '3203005815201GFT', '3203003635801GFT', '3203006426401GFT', '3203000856201GFT', '3203003613401GFT', '3203005990501GFT', '3203004716601GFT', '3203005795201GFT', '4104000492201END', '3203006453601GFT', '6506006351701GFT', '3203005619301GFT', '6506006770001GFT', '4104006648701END', '4314000118601END', '3203006720401GFT', '3203006549401GFT', '3203000857301GFT', '4104000152601END', '4104002558701END', '3203000861601GFT', '4104005797801END', '3203000862201GFT', '4104006633201END', '4104003636501END', '3203005214601GFT', '3203002858501GFT', '4104000172101END', '4104002785101END', '3203004984101GFT', '4104006326501END', '4104000137601END', '4104000025801END', '4104006497101END', '3203004993001GFT', '3203002775901GFT', '4104006012801END', '4204000118701END', '4104000492301END', '3203006508501GFT', '4104005597801END', '4104006389001END', '3203000861501GFT', '4314000519701END', '4104003382601END', '3203005334201GFT', '3203006530101GFT', '3203003685201GFT', '3203005848101GFT', '3203003225301GFT', '3203006379001GFT', '3203006715801GFT', '3203006361801GFT', '3203006498701GFT', '3203006386201GFT', '3203004034701GFT', '3203006735301GFT', '3203002818801GFT', '3203002954201GFT', '3203005228401GFT', '3203003203801GFT', '3203006312201GFT', '3203006328301GFT', '3203000862401GFT', '3203002830801GFT', '3203006341301GFT', '3203006328501GFT', '3203005261001GFT', '3203006817801GFT', '4104003692801END', '4104003483901END', '4104004762501END', '4314003004901END', '4104006525401END', '3203006525501GFT', '4314002927701END', '3203004525701GFT', '4104005177601END', '4104000427501END', '3203004334701GFT', '4104002551901END', '3203000861701GFT', '4104000516901EN1', '4104000135701END', '4104006936401END', '3203000872401GFT', '4314000089801END', '3203006233401GFT', '3203004707901GFT', '3203006114401GFT', '3203006469401GFT', '3203005448001GFT', '3203005137401GFT', '4104000467801END', '4104001011701END', '3203000861901GFT', '3203006166701GFT', '3203006756601GFT', '3203006149601GFT', '4104000492901END', '4104000421401END', '4104002442901END', '3203004600201GFT', '4104005811301END', '4104006730701END', '3203002978801GFT', '4724005603301LFT'
          , '4104006954301END', '3203006954501GFT', '3203007012501GFT', '3203006983701GFT', '3203006993001GFT'
          , '4104007027001END', '4104003342201END', '4104007038201END', '4104007073301END')
          Then 'Students'
        Else 'TBD'
        End
      As campaign_priority
  From table(dw_pkg_base.tbl_designation) des
  Left Join table(ksm_pkg_designation.tbl_designation_ksm_cru) cru
    On cru.designation_record_id = des.designation_record_id
  Where ksm_flag = 'Y'
  ;

/*************************************************************************
Pipelined functions
*************************************************************************/

--------------------------------------
Function tbl_designation_ksm_af
  Return designation_list Pipelined As
    -- Declarations
    dl designation_list;

  Begin
    Open c_designation_ksm_af; -- Annual Fund allocations cursor
      Fetch c_designation_ksm_af Bulk Collect Into dl;
    Close c_designation_ksm_af;
    -- Pipe out the allocations
    For i in 1..(dl.count) Loop
      Pipe row(dl(i));
    End Loop;
    Return;
  End;

--------------------------------------
Function tbl_designation_ksm_cru
  Return designation_list Pipelined As
    -- Declarations
    dl designation_list;

  Begin
    Open c_designation_ksm_cru; -- Annual Fund allocations cursor
      Fetch c_designation_ksm_cru Bulk Collect Into dl;
    Close c_designation_ksm_cru;
    -- Pipe out the allocations
    For i in 1..(dl.count) Loop
      Pipe row(dl(i));
    End Loop;
    Return;
  End;

--------------------------------------
Function tbl_designation_cash
  Return cash_designation Pipelined As
    -- Declarations
    cd cash_designation;

  Begin
    Open c_designation_cash; -- Annual Fund allocations cursor
      Fetch c_designation_cash Bulk Collect Into cd;
    Close c_designation_cash;
    -- Pipe out the allocations
    For i in 1..(cd.count) Loop
      Pipe row(cd(i));
    End Loop;
    Return;
  End;

--------------------------------------
Function tbl_designation_campaign_kfc
  Return campaign_designation Pipelined As
    -- Declarations
    allocs campaign_designation;

  Begin
    Open c_designation_campaign_kfc; -- Annual Fund allocations cursor
      Fetch c_designation_campaign_kfc Bulk Collect Into allocs;
    Close c_designation_campaign_kfc;
    -- Pipe out the allocations
    For i in 1..(allocs.count) Loop
      Pipe row(allocs(i));
    End Loop;
    Return;
  End;

End ksm_pkg_designation;
/
