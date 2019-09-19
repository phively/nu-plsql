Drop Table tbl_IR_FY19_custom_level
;

Create Table tbl_IR_FY19_custom_level (
  -- entity.id_number to link custom level
  id_number varchar2(10)
  -- customized recognition level, one of '10M', '5M', '2.5M', '1M', '500K', '250K', '100K', '50K', '25K', '10K', '5K', '2.5K', 'Org'
  , custom_level varchar2(20)
)
;

Insert All
  Into tbl_IR_FY19_custom_level Values('1234567890', '5M') -- This person will be shifted from their current to the $5M+ giving level
  Into tbl_IR_FY19_custom_level Values('1234567891', '5M+') -- This person will also be shifted from their current to the $5M+ giving level
  Into tbl_IR_FY19_custom_level Values('1234567892', 'B. 5M+') -- This person will also be shifted from their current to the $5M+ giving level
-- Commit table
Select * From DUAL
;
Commit Work
;

-- Check results
Select
  cust_lvl.id_number
  , entity.report_name
  , spouse.report_name As spouse_name
  , cust_lvl.custom_level
From tbl_IR_FY19_custom_level cust_lvl
Inner Join entity
  On entity.id_number = cust_lvl.id_number
Left Join entity spouse
  On entity.spouse_id_number = spouse.id_number
;
