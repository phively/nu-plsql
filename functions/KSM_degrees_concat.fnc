Create Or Replace Function advance.ksm_degrees_concat(id In varchar2, verbose In varchar2 Default 'FALSE')
Return varchar2 Is

/*
Created by pbh634
Takes an ID number and returns concatenated Kellogg degrees as a string
Sample output (verbose => 'FALSE' vs. verbose => 'TRUE'):
MBA 2014 KSM JDMBA                     MBA 2014 KSM Law/Kellogg - JD/MBA
MBA 2014 KSM KGS2Y FT62                MBA 2014 KSM KSM - 2-Year MBA FT Section 62
BBA 1969 BUS BEV; MBA 1970 KSM KGS1Y   BBA 1969 BUS Business - EV; MBA 1970 KSM KSM - 1-Year MBA
*/

-- Declarations
deg_conc varchar2(1024);
verbose_ char(1);
  
Begin

  -- Set verbose
  If Upper(verbose) In ('T', 'TR', 'TRU', 'TRUE') Then
    verbose_ := 'T';
  End If;

  -- Main query
  Select
    -- Concatenated degrees string
    Listagg(
      -- Use this when verbose is FALSE (default)
      Case
        -- Trimmed degree row, verbose
        When verbose_ = 'T' Then
          trim(
            degree_code || ' ' || degree_year || ' ' || school_code || ' ' ||
            tms_dept_code.short_desc || ' ' || tms_class_section.short_desc
          )
        -- Trimmed degree row, terse
        Else trim(
          degree_code || ' ' || degree_year || ' ' || school_code || ' ' || 
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
          || ' ' || class_section)
        -- End of terse/verbose
        End
      -- ; is the degree delimiter
      , '; '
    )
    Within Group (Order By degree_year) As degrees_concat
  Into deg_conc
  From degrees
    Left Join tms_class_section
      On degrees.class_section = tms_class_section.section_code
    Left Join tms_dept_code
      On degrees.dept_code = tms_dept_code.dept_code
  Where institution_code = '31173'
    And school_code in('BUS', 'KSM')
    And id_number = id
  Group By id_number;

Return(deg_conc);

End ksm_degrees_concat;
/
