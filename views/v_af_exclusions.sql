-- Create Or Replace View v_af_exclusions As

With

-- Manual exclusions
manual_exclusions_pre As (
  Select
    id_number
    , report_name
  From entity
  Where id_number In (
    NULL
------ ADD ID NUMBERS BELOW HERE ------
    , '0000299349' -- DSB
    , '0000225195' -- DDJ
    , '0000499489' -- DDJ spouse
------ ADD ID NUMBERS ABOVE HERE ------
  )
)
, manual_exclusions As (
    Select
      id_number
      , 'Y' As manual_exclusion
    From manual_exclusions_pre
  Union
    Select
      entity.id_number
      , 'Y' As manual_exclusion
    From entity
    Inner Join manual_exclusions_pre mep On mep.id_number = entity.spouse_id_number
)

-- Special handling
, spec_hnd As (
  Select
    id_number
    , spouse_id_number
    , special_handling_concat
    , mailing_list_concat
    , no_contact
    , no_solicit
    , never_engaged_forever
    , exc_all_comm
    , exc_all_sols
  From table(ksm_pkg.tbl_special_handling_concat) shc
  Where no_contact = 'Y'
    Or no_solicit = 'Y'
    Or never_engaged_forever = 'Y'
    Or exc_all_comm = 'Y'
    Or exc_all_sols = 'Y'
)

-- Global Advisory Board
, gab As (
  Select
    id_number
    , Listagg(
        trim('GAB ' || role)
      , '; ') Within Group (Order By tcg.role Asc)
      As gab
  From table(ksm_pkg.tbl_committee_gab) tcg
  Group By id_number
)

-- Trustee
, trustee As (
  Select
    id_number
    , Listagg(
        Case
          When a.affil_code = 'TR' Then
            Case
              When tms_al.affil_level_code Is Not Null Then tms_al.short_desc
              Else 'Trustee'
            End
          When a.affil_code = 'TS' Then trim(tms_ac.short_desc || ' ' || tms_al.short_desc)
        End
      , '; ') Within Group (Order By a.affil_code Asc)
      As trustee
  From affiliation a
  Left Join tms_affil_code tms_ac On tms_ac.affil_code = a.affil_code
  Left Join tms_affiliation_level tms_al On tms_al.affil_level_code = a.affil_level_code
  Where a.affil_code In ('TR', 'TS') -- Trustee and Trustee Relation
    And a.affil_status_code In ('C', 'A') -- Current and Active (deprecated) only
  Group By id_number
)

-- Merged ids
, ids As (
    -- Manual exclusions
    Select id_number
    From manual_exclusions
  Union
    -- Special handling
    Select id_number
    From spec_hnd
  Union
    -- Spouse special handling
    Select spouse_id_number
    From spec_hnd
    Where no_contact = 'Y'
      Or exc_all_comm = 'Y'
      Or never_engaged_forever = 'Y'
  Union
    -- Current GAB members
    Select id_number
    From gab
  Union
    -- Current trustees/spouses
    Select id_number
    From trustee
)

-- Final query
Select
  entity.id_number
  , entity.report_name
  , me.manual_exclusion
  , sh.special_handling_concat
  , shs.special_handling_concat As special_handling_spouse
  , sh.no_contact 
  , shs.no_contact As no_contact_spouse
  , sh.no_solicit 
  , shs.no_solicit As no_solicit_spouse
  , sh.never_engaged_forever
  , shs.never_engaged_forever As never_engaged_forever_spouse
  , sh.exc_all_comm
  , shs.exc_all_comm As exc_all_comm_spouse
  , sh.exc_all_sols
  , shs.exc_all_sols As exc_all_sols_spouse
  , gab.gab
  , trustee.trustee
From ids
Inner Join entity On entity.id_number = ids.id_number
Left Join manual_exclusions me On me.id_number = ids.id_number
Left Join spec_hnd sh On sh.id_number = ids.id_number
Left Join spec_hnd shs On shs.spouse_id_number = ids.id_number
Left Join gab On gab.id_number = ids.id_number
Left Join trustee On trustee.id_number = ids.id_number
