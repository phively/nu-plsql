/*
-- Main query
Select id_number,
  -- Concatenated degrees string
  Listagg(
    -- Trimmed degree row
    trim(
      degree_code || ' ' || degree_year || ' ' || school_code || ' ' || 
      -- Special handler for KSM and EMBA departments
      Case
        When dept_code Like '01%' Then substr(dept_code, 3)
        When dept_code = '13JDM' Then 'JD/MBA'
        When dept_code = '13LLM' Then 'LLM'
        When dept_code Like '41%' Then substr(dept_code, 3)
        Else short_desc
      End
      || ' ' || class_section
    ), '; ' -- ; is the degree delimiter
  )
  Within Group (Order By degree_year) As degrees_concat
From degrees
  Left Join tms_class_section
    On degrees.class_section = tms_class_section.section_code
Where institution_code = '31173'
  And school_code in('BUS', 'KSM')
Group By id_number;
*/

/*
Select id_number, advance.ksm_degrees_concat(id_number) As Terse, advance.ksm_degrees_concat(id_number, verbose => 'T') As Verbose
From entity
Where advance.ksm_degrees_concat(id_number) Is Not Null;
*/

/*
Select Distinct d.degree_code, d.dept_code, short_desc,
  Case
    When d.dept_code = '01MDB' Then 'MDMBA'
    When d.dept_code Like '01%' Then substr(d.dept_code, 3)
    When d.dept_code = '13JDM' Then 'JDMBA'
    When d.dept_code = '13LCM' Then 'LLM'
    When d.dept_code Like '41%' Then substr(d.dept_code, 3)
    When d.dept_code = '95BCH' Then 'BCH'
    When d.dept_code = '96BEV' Then 'BEV'
    When d.dept_code In ('AMP', 'AMPI', 'EDP', 'KSMEE') Then d.dept_code
    When d.dept_code = '0000000' Then ''
    Else short_desc
  End As my_formula,
  count(id_number) As count
From tms_dept_code tms, degrees d
Where tms.dept_code = d.dept_code
  And d.school_code In ('BUS', 'KSM')
Group By d.degree_code, d.dept_code, short_desc
Order By count Desc;
*/
