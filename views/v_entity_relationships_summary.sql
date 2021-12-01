Create Or Replace View v_entity_relationships_summary As
-- Relationships view - for each id_number, list spouse (whether or not ID is included), spouse salutation(s), spouse degrees,
-- children (concatenated), children salutation(s), children degrees

With

salutations As (
  -- Active KSM salutations only
  Select
    id_number
    , signer_id_number
    , salutation_type_code
    , salutation
    , active_ind
    , trunc(date_added)
      As date_added
  From salutation
  Where salutation_type_code = 'KM' -- Dean of Kellogg School of Management
    And active_ind = 'Y'
)

, sal_distinct As (
  -- Deduped salutations
  Select Distinct
    id_number
    , trim(salutation)
      As ksm_salutation
  From salutations  
)

, sal_concat As (
  Select
    id_number
    , count(ksm_salutation)
      As n
    , Listagg(trim(ksm_salutation), chr(10)) Within Group (Order By ksm_salutation Asc)
      As ksm_salutations
  From sal_distinct
  Group By id_number
)

, spouse As (
  Select
    entity.id_number
    , entity.marital_status_code
    , tms_ms.short_desc
      As marital_status
    , trim(entity.spouse_id_number)
      As spouse_id_number
    , entity_spouse.report_name
      As spouse_report_name
    , entity_spouse.institutional_suffix
      As spouse_institutional_suffix
    -- For entities, use spouse's pref_mail_name
    , Case
        When trim(entity.spouse_id_number) Is Not Null
          Then entity_spouse.pref_mail_name
        Else trim(entity.spouse_name)
        End
      As spouse_name
    , sal_concat.ksm_salutations
      As spouse_ksm_salutations
    , entity.marital_status_chg_dt
    , rpt_pbh634.ksm_pkg.to_date2(entity.marital_status_chg_dt)
      As marital_status_dt
  From entity
  Left Join tms_marital_status tms_ms
    On tms_ms.marital_status_code = entity.marital_status_code
  Left Join entity entity_spouse
    On entity_spouse.id_number = entity.spouse_id_number
  --Left Join salutations
  Left Join sal_concat
    On sal_concat.id_number = entity_spouse.id_number
  Where
    trim(entity.spouse_id_number) Is Not Null
    Or trim(entity.spouse_name) Is Not Null
)

, relationship_children As (
  -- Children coded under relationship
  Select *
  From relationship
)

, children_table As (
  -- Children coded under children
  Select *
  From children
)

-- Combined/concatenated children

Select
  entity.id_number
  , entity.record_status_code
  , entity.report_name
  , entity.institutional_suffix
  , entity.pref_mail_name
  , sal_concat.ksm_salutations
  , spouse.marital_status
  , spouse.spouse_id_number
  , spouse.spouse_name
  , spouse.spouse_ksm_salutations
  , spouse.spouse_report_name
  , spouse.spouse_institutional_suffix
From entity
Left Join sal_concat
  On sal_concat.id_number = entity.id_number
Left Join spouse
  On spouse.id_number = entity.id_number
-- Children joins
;

