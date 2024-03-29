Create Or Replace Package ksm_pkg_address Is

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_address';
collect_default_limit Constant pls_integer := 100;

/*************************************************************************
Public type declarations
*************************************************************************/

Type geo_code_primary Is Record (
  id_number address.id_number%type
  , xsequence address.xsequence%type
  , addr_pref_ind address.addr_pref_ind%type
  , geo_codes varchar2(1024)
  , geo_code_primary geo_code.geo_code%type
  , geo_code_primary_desc geo_code.description%type
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type t_geo_code_primary Is Table Of geo_code_primary;

/*************************************************************************
Public function declarations
*************************************************************************/

-- Return specified master address information, defined as preferred if available, else home if available, else business.
-- The field parameter should match an address table field or tms table name, e.g. street1, state_code, country, etc.
Function get_entity_address(
  id In varchar2 -- entity id_number
  , field In varchar2 -- address item to pull, including city, state_code, country, etc.
  , debug In boolean Default FALSE -- if TRUE, debug output is printed via dbms_output.put_line()
) Return varchar2; -- matched address piece


/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

Function tbl_geo_code_primary(
  limit_size In pls_integer Default collect_default_limit
)
  Return t_geo_code_primary Pipelined;

/*************************************************************************
Public cursors -- data definitions
*************************************************************************/

-- Definition of primary geo code
Cursor c_geo_code_primary Is 
  Select
    address.id_number
    , address.xsequence
    , address.addr_pref_ind
    , Listagg(trim(geo_code.description), '; ') Within Group (Order By geo_code.description Asc)
      As geo_codes
    , min(geo_code.geo_code) keep(dense_rank First Order By geo_type.hierarchy_order Desc, address_geo.date_added Asc, geo_code.geo_code Asc)
      As geo_code_primary
    , min(geo_code.description) keep(dense_rank First Order By geo_type.hierarchy_order Desc, address_geo.date_added Asc, geo_code.geo_code Asc)
      As geo_code_primary_desc
  From address
  Inner Join address_geo
    On address.id_number = address_geo.id_number
    And address.xsequence = address_geo.xsequence
  Inner Join geo_code
    On geo_code.geo_code = address_geo.geo_code
  Inner Join geo_type
    On geo_type.geo_type = geo_code.geo_type
  Where 
    address.addr_status_code = 'A' -- Active addresses only
    And address_geo.geo_type In (100, 110) -- Tier 1 Region, Club
    And address_geo.geo_code Not In (
      'C035' -- Lake Arc 
      , 'C068' -- SF without SJ
      , 'C069' -- San Jose
      , 'C046' -- North Carolina
      , 'C011' -- Chi city only
      , 'C074' -- Miami-Ft Laud combined
    )
  Group By
    address.id_number
    , address.xsequence
    , address.addr_pref_ind
;

End ksm_pkg_address;
/

Create Or Replace Package Body ksm_pkg_address Is

/*************************************************************************
Functions
*************************************************************************/

-- Takes an ID and returns xsequence of master address, defined as preferred if available, else home,
-- else business.
Function get_entity_address_master_xseq(id In varchar2, debug In Boolean Default FALSE)
  Return number Is
  -- Declarations
  xseq number(6); -- final xsequence of address to retrieve
  
  -- Address types available for consideration as master/primary address
  Cursor c_address_types Is
    With
    pref As (
      Select id_number, xsequence As pref_xseq
      From address
      Where addr_status_code = 'A' And addr_pref_ind = 'Y'
    ),
    home As (
      Select id_number, xsequence As home_xseq
      From address
      Where addr_status_code = 'A' And addr_type_code = 'H'
    ),
    bus As (
      Select id_number, xsequence As bus_xseq
      From address
      Where addr_status_code = 'A' And addr_type_code = 'B'
    )
    -- Combine preferred, home, and business xseq into a row
    Select pref_xseq, home_xseq, bus_xseq
    From entity
      Left Join pref On entity.id_number = pref.id_number
      Left Join home On entity.id_number = home.id_number
      Left Join bus On entity.id_number = bus.id_number
    Where entity.id_number = id;

  -- Table to hold address xsequence numbers
  Type t_number Is Table Of c_address_types%rowtype;
    t_xseq t_number;
  
  Begin
    -- Determine which xsequence to use for master address
    Open c_address_types;
      Fetch c_address_types Bulk Collect Into t_xseq;
    Close c_address_types;
    
    -- Debug -- print the retrieved address xsequence numbers
    If debug Then
      dbms_output.put_line('P: ' || t_xseq(1).pref_xseq || '; H: ' || t_xseq(1).home_xseq ||
        '; B: ' || t_xseq(1).bus_xseq);
    End If;
    
    -- Store best choice in xseq
    If t_xseq(1).pref_xseq Is Not Null Then xseq := t_xseq(1).pref_xseq;
    ElsIf t_xseq(1).home_xseq Is Not Null Then xseq := t_xseq(1).home_xseq;
    ElsIf t_xseq(1).bus_xseq Is Not Null Then xseq := t_xseq(1).bus_xseq;
    Else xseq := 0;
    End If;
    
    Return xseq;
  End;

-- Takes an ID and field and returns active address part from master address. Standardizes input
--   fields to lower-case.
Function get_entity_address(id In varchar2, field In varchar2, debug In Boolean Default FALSE)
  Return varchar2 Is
  -- Declarations
  master_addr varchar2(120); -- final output
  field_ varchar2(60) := lower(field); -- lower-case field
  xseq number; -- stores master address xsequence
   
  Begin
    -- Determine the xsequence of the master address
    xseq := get_entity_address_master_xseq(id => id, debug => debug);
    -- Debug -- print the retrieved master address sequence and field type
    If debug Then dbms_output.put_line(xseq || ' ' || field || ' is: ');
    End If;
    -- Retrieve the master address
    If xseq = 0 Then Return('LOST_ALUMNI'); -- failsafe condition
    End If;
     -- Big Case-When to fill in the appropriate field
    Select Case
      When field_ = 'care_of' Then care_of
      When field_ = 'company_name_1' Then company_name_1
      When field_ = 'company_name_2' Then company_name_2
      When field_ = 'business_title' Then business_title
      When field_ = 'street1' Then street1
      When field_ = 'street2' Then street2
      When field_ = 'street3' Then street3
      When field_ = 'foreign_cityzip' Then foreign_cityzip
      When field_ = 'city' Then city
      When field_ = 'state_code' Then address.state_code
      When field_ Like 'state%' Then tms_states.short_desc
      When field_ = 'zipcode' Then zipcode
      When field_ = 'zip_suffix' Then zip_suffix
      When field_ = 'postnet_zip' Then postnet_zip
      When field_ = 'county_code' Then address.county_code
      When field_ Like 'county%' Then tms_county.full_desc
      When field_ = 'country_code' Then address.country_code
      When field_ Like 'country%' Then tms_country.short_desc
    End
    Into master_addr
    From address
      Left Join tms_country On address.country_code = tms_country.country_code
      Left Join tms_states On address.state_code = tms_states.state_code
      Left Join tms_county On address.county_code = tms_county.county_code
    Where id_number = id And xsequence = xseq;
    
    Return(master_addr);
  End;

/*************************************************************************
Pipelined functions
*************************************************************************/

-- Pipelined function returning concatenated geo codes for all addresses
Function tbl_geo_code_primary(
  limit_size In pls_integer Default collect_default_limit
)
  Return t_geo_code_primary Pipelined As
  -- Declarations
  geo t_geo_code_primary;
  
  Begin
    If c_geo_code_primary %ISOPEN then
      Close c_geo_code_primary;
    End If;
    Open c_geo_code_primary;
    Loop
      Fetch c_geo_code_primary Bulk Collect Into geo Limit limit_size;
      Exit When geo.count = 0;
      For i in 1..(geo.count) Loop
        Pipe row(geo(i));
      End Loop;
    End Loop;
    Close c_geo_code_primary;
    Return;
  End;

End ksm_pkg_address;
/