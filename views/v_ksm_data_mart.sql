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

-- KSM degrees view
-- Includes Kellogg degrees
Select
  id_number As catracks_id
  , school_code
  -- Date added
  -- Date modified
  -- Etc.
From degrees
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
