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

-- Public type declarations
-- Type <TypeName> Is <Datatype>;
  
-- Public constant declarations
  fy_start_month Constant number := 9; -- fiscal start month, 9 = September

-- Public variable declarations
-- <VariableName> <Datatype>;

-- Public function and procedure declarations

Function math_mod( -- mathematical modulo operator
  m In number,
  n In number)
  Return number; -- m % n
  
Function fytd_indicator( -- fiscal year to date indicator
  dt In date,
  day_offset In number Default -1) -- default offset in days; -1 means up to yesterday, 0 up to today, etc.
  Return character; -- Y or N

Function get_entity_degrees_concat_ksm( -- Returns concatenated Kellogg degrees as string
  id In varchar2, -- entity id_number
  verbose In varchar2 Default 'FALSE')  -- if TRUE, then preferentially return short_desc instead of code where unclear
  Return varchar2; -- e.g. 2014 MBA KSM JDMBA

Function get_gift_source_donor_ksm( -- takes receipt number and returns id_number of entity to receive primary Kellogg gift credit
  receipt In varchar2,
  debug In boolean Default FALSE) -- if TRUE, debug output is printed via dbms_output.put_line()
  Return varchar2; -- entity id_number

end ksm_pkg;
/
Create Or Replace Package Body ksm_pkg Is

-- Private type declarations
-- type <TypeName> is <Datatype>;
  
-- Private constant declarations
-- <ConstantName> constant <Datatype> := <Value>;

-- Private variable declarations
-- <VariableName> <Datatype>;

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
      Fetch t_donor
        Bulk Collect Into results;
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

End ksm_pkg;
/
