Drop Table tbl_IR_FY21_cornerstone
;

Create Table tbl_IR_FY21_cornerstone (
  -- entity.id_number to include
  id_number varchar2(10)
)
;

Insert All
  Into tbl_IR_FY21_cornerstone Values('0123456789') -- This person gets the <CORNERSTONE> tag

-- Commit table
Select * From DUAL
;
Commit Work
;

-- Check results
Select
  cornerstone.id_number
  , entity.report_name
  , spouse.report_name As spouse_name
From tbl_IR_FY21_cornerstone cornerstone
Inner Join entity
  On entity.id_number = cornerstone.id_number
Left Join entity spouse
  On entity.spouse_id_number = spouse.id_number
;
