Create Or Replace Package ksm_pkg_committee Is

/*************************************************************************
Initial procedures
*************************************************************************/

/*************************************************************************
Public type declarations
*************************************************************************/

-- Committee member list, for committee results
Type committee_member Is Record (
  id_number committee.id_number%type
  , committee_code committee_header.committee_code%type
  , short_desc committee_header.short_desc%type
  , start_dt committee.start_dt%type
  , stop_dt committee.stop_dt%type
  , status tms_committee_status.short_desc%type
  , role tms_committee_role.short_desc%type
  , committee_title committee.committee_title%type
  , xcomment committee.xcomment%type
  , date_modified committee.date_modified%type
  , operator_name committee.operator_name%type
  , spouse_id_number entity.spouse_id_number%type
);

Type committee_agg Is Record (
    id_number committee.id_number%type
    , report_name entity.report_name%type
    , committee_code committee.committee_code%type
    , short_desc committee_header.short_desc%type
    , start_dt varchar2(512)
    , stop_dt varchar2(512)
    , status tms_committee_status.short_desc%type
    , role varchar2(1024)
    , committee_title varchar2(1024)
    , committee_short_desc varchar2(40)
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type t_committee_members Is Table Of committee_member;
Type t_committee_agg Is Table Of committee_agg;

/*************************************************************************
Public constant declarations
*************************************************************************/

/* Committees */
committee_gab Constant committee.committee_code%type := 'U'; -- Kellogg Global Advisory Board committee code
committee_kac Constant committee.committee_code%type := 'KACNA'; -- Kellogg Alumni Council committee code
committee_phs Constant committee.committee_code%type := 'KPH'; -- KSM Pete Henderson Society
committee_KFN Constant committee.committee_code%type := 'KFN'; -- Kellogg Finance Network code
committee_CorpGov Constant committee.committee_code%type := 'KCGN'; -- KSM Corporate Governance Network code
committee_WomenSummit Constant committee.committee_code%type := 'KGWS'; -- KSM Global Women's Summit code
committee_DivSummit Constant committee.committee_code%type := 'KCDO'; -- KSM chief Diversity Officer Summit code
committee_RealEstCouncil Constant committee.committee_code%type := 'KREAC'; -- Real Estate Advisory Council code
committee_AMP Constant committee.committee_code%type := 'KAMP'; -- AMP Advisory Council code
committee_trustee Constant committee.committee_code%type := 'TBOT'; -- NU Board of Trustees code
committee_healthcare Constant committee.committee_code%type := 'HAK'; -- Healthcare at Kellogg Advisory Council
committee_WomensLeadership Constant committee.committee_code%type := 'KWLC'; -- Women's Leadership Advisory Council
committee_KALC Constant committee.committee_code%type := 'KALC'; -- Kellogg Admissions Leadership Council
committee_kic Constant committee.committee_code%type := 'KIC'; -- Kellogg Inclusion Coalition
committee_privateequity Constant committee.committee_code%type := 'KPETC'; -- Kellogg Private Equity Taskforce Council
committee_pe_asia Constant committee.committee_code%type := 'APEAC'; -- KSM Asia Private Equity Advisory Council
committee_asia Constant committee.committee_code%type := 'KEBA'; -- Kellogg Executive Board for Asia
committee_mbai Constant committee.committee_code%type := 'MBAAC'; -- MBAi Advisory Council 

/*************************************************************************
Public variable declarations
*************************************************************************/

/*************************************************************************
Public function declarations
*************************************************************************/

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

/*********************** About pipelined functions ***********************
Q: What is a pipelined function?

A: Pipelined functions are used to return the results of a cursor row by row.
This is an efficient way to re-use a cursor between multiple programs. Pipelined
tables can be queried in SQL exactly like a table when embedded in the table()
function. My experience has been that thanks to the magic of the Oracle compiler,
joining on a table() function scales hugely better than running a function once
on each element of a returned column. Note that the exact columns returned need
to be specified as a public type, which I did in the type and table declarations
above, or the pipelined function can't be run in pure SQL. Alternately, the
pipelined function could return a generic table, but the columns would still need
to be individually named.

Examples: 
Select ksm_af.*
From table(rpt_pbh634.ksm_pkg.tbl_alloc_annual_fund_ksm) ksm_af;
Select cal.*
From table(rpt_pbh634.ksm_pkg.tbl_current_calendar) cal;
*************************************************************************/

-- Return pipelined table of committee members
-- All roles listagged to one per line
Function tbl_committee_agg (
  my_committee_cd In varchar2
  , shortname In varchar2 Default NULL
) Return t_committee_agg Pipelined;

-- Individual committees
Function tbl_committee_gab
  Return t_committee_members Pipelined;

Function tbl_committee_phs
  Return t_committee_members Pipelined;
    
Function tbl_committee_kac
  Return t_committee_members Pipelined;

Function tbl_committee_KFN
  Return t_committee_members Pipelined;
  
 Function tbl_committee_CorpGov
  Return t_committee_members Pipelined;
  
 Function tbl_committee_WomenSummit
  Return t_committee_members Pipelined;
  
 Function tbl_committee_DivSummit
  Return t_committee_members Pipelined;
  
 Function tbl_committee_RealEstCouncil
  Return t_committee_members Pipelined;
  
 Function tbl_committee_AMP
  Return t_committee_members Pipelined;

Function tbl_committee_trustee
  Return t_committee_members Pipelined;

Function tbl_committee_healthcare
  Return t_committee_members Pipelined;
  
Function tbl_committee_WomensLeadership
  Return t_committee_members Pipelined;

Function tbl_committee_KALC
  Return t_committee_members Pipelined;

Function tbl_committee_kic
  Return t_committee_members Pipelined;
  
Function tbl_committee_privateequity
  Return t_committee_members Pipelined;

Function tbl_committee_pe_asia
  Return t_committee_members Pipelined;
  
Function tbl_committee_asia
  Return t_committee_members Pipelined;
  
Function tbl_committee_mbai
  Return t_committee_members Pipelined;

/*************************************************************************
End of package
*************************************************************************/

End ksm_pkg_committee;
/
Create Or Replace Package Body ksm_pkg_committee Is

/*************************************************************************
Private cursor tables -- data definitions; update indicated sections as needed
*************************************************************************/

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

Cursor c_committee_members (my_committee_cd In varchar2) Is
  -- Same as comm subquery in c_committee_agg, below
  Select
    comm.id_number
    , comm.committee_code
    , hdr.short_desc
    , comm.start_dt
    , comm.stop_dt
    , tms_status.short_desc As status
    , tms_role.short_desc As role
    , comm.committee_title
    , comm.xcomment
    , comm.date_modified
    , comm.operator_name
    , trim(entity.spouse_id_number) As spouse_id_number
  From committee comm
  Inner Join entity
    On entity.id_number = comm.id_number
  Left Join tms_committee_status tms_status On comm.committee_status_code = tms_status.committee_status_code
  Left Join tms_committee_role tms_role On comm.committee_role_code = tms_role.committee_role_code
  Left Join committee_header hdr On comm.committee_code = hdr.committee_code
  Where comm.committee_code = my_committee_cd
    And comm.committee_status_code In ('C', 'A') -- 'C'urrent or 'A'ctive; 'A' is deprecated
  ;

Cursor c_committee_agg (
    my_committee_cd In varchar2
    , shortname In varchar2
  ) Is
  With
  c As (
    -- Same as c_committee_members, above
      Select
        comm.id_number
        , comm.committee_code
        , hdr.short_desc
        , comm.start_dt
        , comm.stop_dt
        , tms_status.short_desc As status
        , tms_role.short_desc As role
        , comm.committee_title
        , comm.xcomment
        , comm.date_modified
        , comm.operator_name
        , trim(entity.spouse_id_number) As spouse_id_number
        , shortname As committee_short_desc
      From committee comm
      Inner Join entity
        On entity.id_number = comm.id_number
      Left Join tms_committee_status tms_status On comm.committee_status_code = tms_status.committee_status_code
      Left Join tms_committee_role tms_role On comm.committee_role_code = tms_role.committee_role_code
      Left Join committee_header hdr On comm.committee_code = hdr.committee_code
      Where comm.committee_code = my_committee_cd
        And comm.committee_status_code In ('C', 'A') -- 'C'urrent or 'A'ctive; 'A' is deprecated
  )
  -- Main query
  Select
    c.id_number
    , entity.report_name
    , c.committee_code
    , c.short_desc
    , listagg(c.start_dt, '; ') Within Group (Order By c.start_dt Asc, c.stop_dt Asc, c.role Asc)
      As start_dt
    , listagg(c.stop_dt, '; ') Within Group (Order By c.start_dt Asc, c.stop_dt Asc, c.role Asc)
      As stop_dt
    , c.status
    , listagg(c.role, '; ') Within Group (Order By c.start_dt Asc, c.stop_dt Asc, c.role Asc)
      As role
    , listagg(c.committee_title, '; ') Within Group (Order By c.start_dt Asc, c.stop_dt Asc, c.role Asc)
      As committee_title
    , shortname
      As committee_short_desc
  From c
  Inner Join entity
    On entity.id_number = c.id_number
  Group By
    c.id_number
    , entity.report_name
    , c.committee_code
    , c.short_desc
    , c.status
  ;

/*************************************************************************
Private type declarations
*************************************************************************/

/*************************************************************************
Private table declarations
*************************************************************************/

/*************************************************************************
Private constant declarations
*************************************************************************/

/*************************************************************************
Private variable declarations
*************************************************************************/

/*************************************************************************
Functions
*************************************************************************/

/*************************************************************************
Pipelined functions
*************************************************************************/

  -- Generic function returning 'C'urrent or 'A'ctive (deprecated) committee members
  Function committee_members (my_committee_cd In varchar2)
    Return t_committee_members As
    -- Declarations
    committees t_committee_members;
    
    -- Return table results
    Begin
      Open c_committee_members (my_committee_cd => my_committee_cd);
        Fetch c_committee_members Bulk Collect Into committees;
      Close c_committee_members;
      Return committees;
    End;

    
  -- Generic committee_agg function, similar to committee_members
  Function committee_agg_members (
    my_committee_cd In varchar2
    , shortname In varchar2 Default NULL
  )
  Return t_committee_agg As
  -- Declarations
  committees_agg t_committee_agg;
  
  -- Return table results
  Begin
    Open c_committee_agg (my_committee_cd => my_committee_cd
      , shortname => shortname
    );
      Fetch c_committee_agg Bulk Collect Into committees_agg;
      Close c_committee_agg;
      Return committees_agg;
    End;
    
  -- All roles listagged to one per line
  Function tbl_committee_agg (
    my_committee_cd In varchar2
    , shortname In varchar2
  ) Return t_committee_agg Pipelined As
  committees_agg t_committee_agg;
  
    Begin
      committees_agg := committee_agg_members (
        my_committee_cd => my_committee_cd
        , shortname => shortname
      );
      For i in 1..committees_agg.count Loop
        Pipe row(committees_agg(i));
      End Loop;
      Return;
    End;

  -- GAB
  Function tbl_committee_gab
    Return t_committee_members Pipelined As
    committees t_committee_members;
    
    Begin
      committees := committee_members (my_committee_cd => committee_gab);
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;
  
  -- KAC
  Function tbl_committee_kac
    Return t_committee_members Pipelined As
    committees t_committee_members;
    
    Begin
      committees := committee_members (my_committee_cd => committee_kac);
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;

  -- PHS
  Function tbl_committee_phs
    Return t_committee_members Pipelined As
    committees t_committee_members;
    
    Begin
      committees := committee_members (my_committee_cd => committee_phs);
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;

  -- KFN
  Function tbl_committee_KFN
    Return t_committee_members Pipelined As
    committees t_committee_members;
    
    Begin
      committees := committee_members (my_committee_cd => committee_KFN);
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;

  -- CorpGov
  Function tbl_committee_CorpGov
    Return t_committee_members Pipelined As
    committees t_committee_members;
    
    Begin
      committees := committee_members (my_committee_cd => committee_CorpGov);
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;
    
  -- GlobalWomenSummit
  Function tbl_committee_WomenSummit
    Return t_committee_members Pipelined As
    committees t_committee_members;
    
    Begin
      committees := committee_members (my_committee_cd => committee_WomenSummit);
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;
    
  -- DivSummit
  Function tbl_committee_DivSummit
    Return t_committee_members Pipelined As
    committees t_committee_members;
    
    Begin
      committees := committee_members (my_committee_cd => committee_DivSummit);
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;
    
  -- RealEstCouncil
  Function tbl_committee_RealEstCouncil
    Return t_committee_members Pipelined As
    committees t_committee_members;
    
    Begin
      committees := committee_members (my_committee_cd => committee_RealEstCouncil);
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;

  -- AMP
  Function tbl_committee_AMP
    Return t_committee_members Pipelined As
    committees t_committee_members;
    
    Begin
      committees := committee_members (my_committee_cd => committee_AMP);
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;

  -- Trustees
  Function tbl_committee_trustee
    Return t_committee_members Pipelined As
    committees t_committee_members;
    
    Begin
      committees := committee_members (my_committee_cd => committee_trustee);
      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;

    -- Healthcare
    Function tbl_committee_healthcare
      Return t_committee_members Pipelined As
      committees t_committee_members;
      
      Begin
        committees := committee_members (my_committee_cd => committee_healthcare);
        For i in 1..committees.count Loop
          Pipe row(committees(i));
        End Loop;
        Return;
      End;

    -- Women's leadership
    Function tbl_committee_WomensLeadership
      Return t_committee_members Pipelined As
      committees t_committee_members;
      
      Begin
        committees := committee_members (my_committee_cd => committee_WomensLeadership);
        For i in 1..committees.count Loop
          Pipe row(committees(i));
        End Loop;
        Return;
      End;
      
    -- Kellogg Admissions Leadership Council
    Function tbl_committee_KALC
      Return t_committee_members Pipelined As
      committees t_committee_members;
      
      Begin
        committees := committee_members (my_committee_cd => committee_KALC);
        For i in 1..committees.count Loop
          Pipe row(committees(i));
        End Loop;
        Return;
      End;
    
    -- Kellogg Inclusion Coalition
    Function tbl_committee_kic
      Return t_committee_members Pipelined As
      committees t_committee_members;
      
      Begin
        committees := committee_members (my_committee_cd => committee_kic);
        For i in 1..committees.count Loop
          Pipe row(committees(i));
        End Loop;
        Return;
      End;
      
    --  Kellogg Private Equity Taskforce Council
    Function tbl_committee_privateequity
      Return t_committee_members Pipelined As
      committees t_committee_members;
        
      Begin
        committees := committee_members (my_committee_cd => committee_privateequity);
        For i in 1..committees.count Loop
          Pipe row(committees(i));
        End Loop;
        Return;
      End;

    --  Kellogg Private Equity Taskforce Council
    Function tbl_committee_pe_asia
      Return t_committee_members Pipelined As
      committees t_committee_members;
        
      Begin
        committees := committee_members (my_committee_cd => committee_pe_asia);
        For i in 1..committees.count Loop
          Pipe row(committees(i));
        End Loop;
        Return;
      End;

    --  Kellogg Executive Board for Asia
    Function tbl_committee_asia
      Return t_committee_members Pipelined As
      committees t_committee_members;
        
      Begin
        committees := committee_members (my_committee_cd => committee_asia);
        For i in 1..committees.count Loop
          Pipe row(committees(i));
        End Loop;
        Return;
      End;
      
    --  Kellogg Executive Board for Asia
    Function tbl_committee_mbai
      Return t_committee_members Pipelined As
      committees t_committee_members;
        
      Begin
        committees := committee_members (my_committee_cd => committee_mbai);
        For i in 1..committees.count Loop
          Pipe row(committees(i));
        End Loop;
        Return;
      End;

End ksm_pkg_committee;
/
