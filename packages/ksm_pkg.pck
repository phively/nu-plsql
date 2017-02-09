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

Function math_mod( -- mathematical modulo operator, m % n
  m In number,
  n In number)
  Return number;
  
Function fytd_indicator( -- fiscal year to date indicator
  dt In date,
  day_offset In number Default -1) -- default offset in days; -1 means up to yesterday, 0 up to today, etc.
  Return character; -- Y or N

Function get_entity_degrees_concat_ksm( -- Returns concatenated Kellogg degrees as string, e.g. 2014 MBA KSM JDMBA
  id In varchar2, -- entity id_number
  verbose In varchar2 Default 'FALSE')  -- if TRUE, then preferentially return short_desc instead of code where unclear
  Return varchar2;

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
Function get_degrees_concat_ksm(id In varchar2, verbose In varchar2)
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

End ksm_pkg;
/
