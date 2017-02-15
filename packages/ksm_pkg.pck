Create Or Replace Package ksm_pkg Is

/*************************************************************************
Author  : PBH634
Created : 2/8/2017 5:43:38 PM
Purpose : Kellogg-specific package with lots of fun functions

Suggested naming convetions:
  Pure functions: [function type]_[description] e.g.
    math_mod
  Data retrieval: get_[object type]_[action or description] e.g.
    get_entity_degrees_concat_ksm
    get_gift_source_donor_ksm
*************************************************************************/

/*************************************************************************
Public type declarations
*************************************************************************/
Type t_varchar2_long Is Table Of varchar2(512);
  
/*************************************************************************
Public constant declarations
*************************************************************************/

/*************************************************************************
Public variable declarations
*************************************************************************/

/*************************************************************************
Public function declarations
*************************************************************************/

/* Mathematical modulo operator */
Function math_mod(
  m In number,
  n In number)
  Return number; -- m % n
  
/* Fiscal year to date indicator */
Function fytd_indicator(
  dt In date,
  day_offset In number Default -1) -- default offset in days; -1 means up to yesterday is year-to-date, 0 up to today, etc.
  Return character; -- Y or N

/* Return concatenated Kellogg degrees as a string */
Function get_entity_degrees_concat_ksm(
  id In varchar2, -- entity id_number
  verbose In varchar2 Default 'FALSE')  -- if TRUE, then preferentially return short_desc instead of code where unclear
  Return varchar2; -- e.g. 2014 MBA KSM JDMBA

/* Return specified address information */
Function get_entity_address(
  id In varchar2, -- entity id_number
  field In varchar2, -- address item to pull, including city, state_code, country, etc.
  debug In boolean Default FALSE) -- if TRUE, debug output is printed via dbms_output.put_line()
  Return varchar2; -- matched address piece

/* Take receipt number and return id_number of entity to receive primary Kellogg gift credit */
Function get_gift_source_donor_ksm(
  receipt In varchar2,
  debug In boolean Default FALSE) -- if TRUE, debug output is printed via dbms_output.put_line()
  Return varchar2; -- entity id_number

/* Return Kellogg Annual Fund allocations, both active and historical, as a pipelined function, e.g.
   Select * From table(ksm_pkg.get_alloc_annual_fund_ksm);
   Seems that the pipelining is super impractical, and I'd be better off with a view, but it's cool so I'm keeping it. */
Function get_alloc_annual_fund_ksm
  Return t_varchar2_long Pipelined; -- returns list of matching values

end ksm_pkg;
/
Create Or Replace Package Body ksm_pkg Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

/* Definition of current and historical Kellogg Annual Fund allocations */
Cursor c_alloc_annual_fund_ksm Is
  Select Distinct allocation_code
  From allocation
  Where annual_sw = 'Y'
  And alloc_school = 'KM';

/*************************************************************************
Private type declarations
*************************************************************************/

/*************************************************************************
Private constant declarations
*************************************************************************/
fy_start_month Constant number := 9; -- fiscal start month, 9 = September

/*************************************************************************
Private variable declarations
*************************************************************************/

/*************************************************************************
Functions
*************************************************************************/

/* Calculates the modulo function; needed to correct Oracle mod() weirdness
   2017-02-08 */
Function math_mod(m In number, n In number)
  Return number Is
  -- Declarations
  remainder number;

  Begin
    remainder := mod(m - n * floor(m/n), n);
    Return(remainder);
  End;

/* Fiscal year to date indicator: Takes as an argument any date object and returns Y/N
   2017-02-08 */
Function fytd_indicator(dt In date, day_offset In number)
  Return character Is
  -- Declarations
  output character;
  today_fisc_day number;
  today_fisc_mo number;
  dt_fisc_day number;
  dt_fisc_mo number;

  Begin
    -- extract dt fiscal month and day
    today_fisc_day := extract(day from sysdate);
    today_fisc_mo  := math_mod(m => extract(month from sysdate) - fy_start_month, n => 12) + 1;
    dt_fisc_day    := extract(day from dt);
    dt_fisc_mo     := math_mod(m => extract(month from dt) - fy_start_month, n => 12) + 1;
    -- logic to construct output
    If dt_fisc_mo < today_fisc_mo Then
      -- if dt_fisc_mo is earlier than today_fisc_mo no need to continue checking
      output := 'Y';
    ElsIf dt_fisc_mo > today_fisc_mo Then
      output := 'N';
    ElsIf dt_fisc_mo = today_fisc_mo Then
      If dt_fisc_day <= today_fisc_day + day_offset Then
        output := 'Y';
      Else
        output := 'N';
      End If;
    Else
      -- fallback condition
      output := '#ERR';
    End If;
    
    Return(output);
  End;

/* Takes an entity id_number and returns concatenated Kellogg degrees as a string
   2017-02-09 */
Function get_entity_degrees_concat_ksm(id In varchar2, verbose In varchar2)
  Return varchar2 Is
  -- Declarations
  deg_conc varchar2(1024); -- hold concatenated degree string
  
  Begin
    Select Listagg( -- Concatenated degrees string
      -- Use this when verbose is FALSE (default)
      Case
        -- Trimmed degree row, verbose
        When upper(verbose) In ('T', 'TR', 'TRU', 'TRUE') Then
          trim(degree_year || ' ' || degree_code || ' ' || school_code || ' ' ||
            tms_dept_code.short_desc || ' ' || tms_class_section.short_desc)
        -- Trimmed degree row, terse
        Else
          trim(degree_year || ' ' || degree_code || ' ' || school_code || ' ' || 
            -- Special handler for KSM and EMBA departments
            Case
              When degrees.dept_code = '01MDB' Then 'MDMBA'
              When degrees.dept_code Like '01%' Then substr(degrees.dept_code, 3)
              When degrees.dept_code = '13JDM' Then 'JDMBA'
              When degrees.dept_code = '13LLM' Then 'LLM'
              When degrees.dept_code Like '41%' Then substr(degrees.dept_code, 3)
              When degrees.dept_code = '95BCH' Then 'BCH'
              When degrees.dept_code = '96BEV' Then 'BEV'
              When degrees.dept_code In ('AMP', 'AMPI', 'EDP', 'KSMEE') Then degrees.dept_code
              When degrees.dept_code = '0000000' Then ''
              Else tms_dept_code.short_desc
            End
            -- Class section code
            || ' ' || class_section)
        -- End of terse/verbose
        End,
      '; ') Within Group (Order By degree_year) As degrees_concat
    Into deg_conc
    From degrees
      Left Join tms_class_section -- For class section short_desc
        On degrees.class_section = tms_class_section.section_code
      Left Join tms_dept_code -- For department short_desc
        On degrees.dept_code = tms_dept_code.dept_code
    Where institution_code = '31173' -- Northwestern institution code
      And school_code in('BUS', 'KSM')
      And id_number = id
    Group By id_number;

    Return(deg_conc);
  End;

/* Takes an ID and returns xsequence of master address, defined as preferred if available, else home,
   else business.
   2017-02-15 */
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

/* Takes an ID and field and returns active address part from master address. Standardizes input
   fields to lower-case.
   2017-02-15 */
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
    If xseq = 0 Then Return('#NA'); -- failsafe condition
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

/* Takes an receipt number and returns the ID number of the entity who should receive primary Kellogg gift credit.
   Relies on nu_gft_trp_gifttrans, which combines gifts and matching gifts into a single table.
   Kellogg alumni status is defined as get_entity_degrees_concat_ksm(id_number) returning a non-null result.
   2017-02-09 */
Function get_gift_source_donor_ksm(receipt In varchar2, debug In boolean Default FALSE)
  Return varchar2 Is
  -- Declarations
  gift_type char(1); -- GPYM indicator
  donor_type char(1); -- record type of primary associated donor
  id_tmp varchar2(10); -- temporary holder for id_number or receipt
  
  -- Cursor to store donors credited on the current gift
  -- Needs to be sorted in preferred order, so that KSM alumni with earlier degree years appear higher
  -- on the list and non-KSM alumni are sorted by lower id_number (as a proxy for age of record)
  Cursor t_donor Is
    Select
      id_number, get_entity_degrees_concat_ksm(id_number) As ksm_degrees,
      person_or_org, associated_code, credit_amount
    From nu_gft_trp_gifttrans
    Where tx_number = receipt
      And associated_code Not In ('H', 'M') -- Exclude In Honor Of and In Memory Of from consideration
    -- People with earlier KSM degree years take precedence over those with later ones
    -- People with smaller ID numbers take precedence over those with larger oens
    Order By get_entity_degrees_concat_ksm(id_number) Asc, id_number Asc;
    
  -- Table type corresponding to above cursor
  Type t_results Is Table Of t_donor%rowtype;
    results t_results;

  Begin
    -- Check if the receipt is a matching gift
    Select Distinct gift.tx_gypm_ind
    Into gift_type
    From nu_gft_trp_gifttrans gift
    Where gift.tx_number = receipt;

  -- For matching gifts, recursively run this function but replace the matching gift receipt with matched receipt
    If gift_type = 'M' Then
      -- If debug, mention that it's a matched gift
      If debug Then
        dbms_output.put_line('==== Matching Gift! ====' || chr(10) || '*Matching receipt: ' || receipt);
      End If;
      -- Pull the matched receipt into id_tmp
      Select gift.matched_receipt_nbr
      Into id_tmp
      From nu_gft_trp_gifttrans gift
      Where gift.tx_number = receipt;
      -- Run id_tmp through this function
      id_tmp := get_gift_source_donor_ksm(receipt => id_tmp,  debug => debug);
      -- Return found ID and break out of function
      Return(id_tmp);
    End If;

  -- For any other type of gift, proceed through the hierarchy of potential source donors

    -- Retrieve t_donor cursor results
    Open t_donor;
      Fetch t_donor Bulk Collect Into results;
    Close t_donor;
    
    -- Debug -- test that the cursors worked --
    If debug Then
      dbms_output.put_line('==== Cursor Results ====' || chr(10) || '*Gift receipt: ' || receipt);
      -- Loop through the lists
      For i In 1..(results.count) Loop
        -- Concatenate output
        dbms_output.put_line(results(i).id_number || '; ' || results(i).ksm_degrees || '; ' || results(i).person_or_org || '; ' ||
          results(i).associated_code || '; ' || results(i).credit_amount);
      End Loop;
    End If;

    -- Check if the primary donor has a KSM degree
    For i In 1..(results.count) Loop
      If results(i).associated_code = 'P' Then
        -- Store the record type of the primary donor
        donor_type := results(i).person_or_org;
        -- If the primary donor is a KSM alum we're done
        If results(i).ksm_degrees Is Not Null Then
          Return(results(i).id_number);
        -- Otherwise jump to next check
        Else Exit;
        End If;
      End If;
    End Loop;
    
    -- Check if any non-primary donors have a KSM degree; grab first that has a non-null l_degrees
    -- IMPORTANT: this means the cursor t_donor needs to be sorted in preferred order!
    For i In 1..(results.count) Loop
      -- If we find a KSM alum we're done
      If results(i).ksm_degrees Is Not Null Then
        Return(results(i).id_number);
      End If;
    End Loop;
    
    -- Check if the primary donor is an organization; if so, grab first person who's associated
    -- IMPORTANT: this means the cursor t_donor needs to be sorted in preferred order!
    -- If primary record type is not person, continue
    If donor_type != 'P' Then  
      For i In 1..(results.count) Loop
        If results(i).person_or_org = 'P' Then
          return(results(i).id_number);
        End If;
      End Loop;  
    End If;
    
    -- Fallback is to use the existing primary donor ID
    For i In 1..(results.count) Loop
      -- If we find a KSM alum we're done
      If results(i).associated_code = 'P' Then
        Return(results(i).id_number);
      End If;
    End Loop;
    -- If we got all the way to the end, return null
    Return(NULL);
    
  End;

/* Pipeline function returning Kellogg Annual Fund allocations, both active and historical
   2017-02-09 */
Function get_alloc_annual_fund_ksm
  Return t_varchar2_long Pipelined As
    -- Declarations
    allocs t_varchar2_long;

  Begin
    -- Grab allocations
    Open c_alloc_annual_fund_ksm; -- Annual Fund allocations cursor
      Fetch c_alloc_annual_fund_ksm Bulk Collect Into allocs;
    Close c_alloc_annual_fund_ksm;
    -- Pipe out the allocations
    For i in 1..(allocs.count) Loop
      Pipe row(allocs(i));
    End Loop;
    
    Return;
  End;

End ksm_pkg;
/
