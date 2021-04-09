Drop Table tbl_IR_FY21_custom_name
;

Create Table tbl_IR_FY21_custom_name (
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
  Into tbl_IR_FY21_custom_name Values('1234567890', 'Example Guy ''09 and Nonalum<LOYAL>', 'Y')
  -- main SQL script will still append <LOYAL> and <KLC> if applicable
  Into tbl_IR_FY21_custom_name Values('1234567891', 'Example Gal ''09 and Nonalum', '')
  -- be sure to include any <DECEASED> tags
  Into tbl_IR_FY21_custom_name Values('1234567892', 'Surviving Alum ''60 and Passed Away ''45<DECEASED>', '')
-- Commit table
Select * From DUAL
;
Commit Work
;

-- Test results
With
hr_names As (
  Select
    id_number
    , trim(pref_name) As honor_roll_name
    , Case
        -- If prefix is at start of name then remove it
        When pref_name Like (prefix || '%')
          Then trim(
            regexp_replace(pref_name, prefix, '', 1) -- Remove first occurrence only
          )
        Else pref_name
        End
      As honor_roll_name_no_prefix
  From name
  Where name_type_code = 'HR'
)

Select
  cust_name.id_number
  , entity.report_name
  , entity.spouse_name
  , custom_name
  , override_suffixes
  , hr_names.honor_roll_name_no_prefix
  , Case
      When lower(custom_name) Like '%anonymous%'
        Then 'Y'
      When honor_roll_name_no_prefix Is NULL
        Then NULL
      When regexp_like(custom_name, honor_roll_name_no_prefix, 'c')
        Then NULL
      Else 'Y'
      End
    As check_by_hand
From tbl_IR_FY21_custom_name cust_name
Inner Join entity
  On entity.id_number = cust_name.id_number
Left Join hr_names
  On hr_names.id_number = cust_name.id_number
;
