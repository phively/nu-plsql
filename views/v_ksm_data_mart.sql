/************************************************************************
Assorted views for the KSM data mart

Conventions:
- id_number renamed to catracks_id
- Code fields end in _code
- Translated values of the code fields end in _desc for description
- Include both string and converted date versions of e.g. start/stop date
  E.g. interest_start_dt
- Always include date added and modified in the disaggregated data views
************************************************************************/

Create Or Replace View v_datamart_degrees As
-- KSM degrees view
-- Includes Kellogg degrees
Select
  degrees.id_number As catracks_id
  , degrees.institution_code
  , institution.institution_name
  , degrees.school_code
  , tms_sch.short_desc As school_desc
  , degrees.campus_code
  , tms_cmp.short_desc As campus_desc
  , degrees.degree_code
  , tms_deg.short_desc As degree_desc
  , degrees.degree_year
  , degrees.grad_dt
  , rpt_pbh634.ksm_pkg.to_date2(degrees.grad_dt) As grad_date
  , degrees.class_section
  , tms_cs.short_desc As class_section_desc
  , degrees.dept_code
  , tms_dc.short_desc As dept_desc
  , degrees.major_code1
  , degrees.major_code2
  , degrees.major_code3
  , m1.short_desc As major_desc1
  , m2.short_desc As major_desc2
  , m3.short_desc As major_desc3
  , degrees.date_added
  , degrees.date_modified
  , degrees.operator_name
From degrees
Inner Join v_entity_ksm_degrees deg -- Alumni only
  On deg.id_number = degrees.id_number
Left Join institution
  On institution.institution_code = degrees.institution_code
Left Join tms_school tms_sch
  On tms_sch.school_code = degrees.school_code
Left Join tms_campus tms_cmp
  On tms_cmp.campus_code = degrees.campus_code
Left Join tms_degrees tms_deg
  On tms_deg.degree_code = degrees.degree_code
Left Join tms_class_section tms_cs
  On tms_cs.section_code = degrees.class_section
Left Join tms_dept_code tms_dc
  On tms_dc.dept_code = degrees.dept_code
Left Join tms_majors m1
  On m1.major_code = degrees.major_code1
Left Join tms_majors m2
  On m2.major_code = degrees.major_code2
Left Join tms_majors m3
  On m3.major_code = degrees.major_code3
;

-- KSM entity view
-- Core alumni table which includes summary information and current fields from the other views
-- Aggregated to return one unique alum per line
Select
  deg.id_number As catracks_id
  , deg.degrees_concat
  , deg.degrees_verbose
  , deg.program
  , deg.program_group
  -- Concatenated majors
  , deg.record_status_code
  , tms_rs.short_desc As record_status_desc
  -- Current home address info
  -- Current business address info
  -- Current employment info
  -- Concatenated interests
From v_entity_ksm_degrees deg
Left Join tms_record_status tms_rs
  On tms_rs.record_status_code = deg.record_status_code
Where deg.record_status_code In ('A', 'C', 'L', 'D')
;
