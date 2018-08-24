Drop Table tbl_IR_FY18_custom_name
;

Create Table tbl_IR_FY18_custom_name (
  -- entity.id_number to link custom name to record
  id_number varchar2(10)
  -- customized recognition name, with <DECEASED> tag if applicable
  , custom_name varchar2(500)
  -- enter a character if we do not want to reconstruct the <LOYAL><KLC> strings
  , override_suffixes varchar2(1)
)
;

Insert All
  -- overrides <LOYAL> and <KLC> designations from main script
  Into tbl_IR_FY18_custom_name Values('1234567890', 'Example Guy ''09 and Nonalum<LOYAL>', 'Y')
  -- main SQL script will still append <LOYAL> and <KLC> if applicable
  Into tbl_IR_FY18_custom_name Values('1234567891', 'Example Gal ''09 and Nonalum', '')
  -- be sure to include any <DECEASED> tags
  Into tbl_IR_FY18_custom_name Values('1234567892', 'Surviving Alum ''60 and Passed Away ''45<DECEASED>', '')
-- Commit table
Select * From DUAL
;
Commit Work
;

-- Test results
Select cust_name.id_number, entity.report_name, entity.spouse_name, custom_name, override_suffixes
From tbl_IR_FY18_custom_name cust_name
Inner Join entity On entity.id_number = cust_name.id_number
;
