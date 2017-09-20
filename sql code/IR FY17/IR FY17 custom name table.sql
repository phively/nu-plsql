Drop Table tbl_IR_FY17_custom_name;
/
Create Table tbl_IR_FY17_custom_name (
  id_number varchar2(10), -- entity.id_number to link custom name to record
  custom_name varchar2(500), -- customized recognition name, with <DECEASED> tag if applicable
  override_suffixes varchar2(1) -- enter a character if we do not want to reconstruct the <LOYAL><KLC> strings
);
/
Insert All
  Into tbl_IR_FY17_custom_name Values('1234567890', 'Example Guy ''09 and Nonalum<LOYAL>', 'Y') -- overrides <LOYAL> and <KLC> designations from main script
  Into tbl_IR_FY17_custom_name Values('1234567891', 'Example Gal ''09 and Nonalum', '') -- main SQL script will still append <LOYAL> and <KLC> if applicable
  Into tbl_IR_FY17_custom_name Values('1234567892', 'Surviving Alum ''60 and Passed Away ''45<DECEASED>', '') -- be sure to include any <DECEASED> tags
-- Commit table
Select * From DUAL;
Commit Work;
/ 
Select *
From tbl_ir_fy17_custom_name;