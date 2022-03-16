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

-- Children coded under relationship
, relationship_table As (
  Select
    relationship.id_number
    , relationship.relation_id_number
      As child_id_number
    , relationship.relation_name
    , relationship.relation_type_code
    , tms_r.short_desc
      As relation_type
    , relationship.relation_status_code
    , entity.gender_code
      As child_gender_code
    , relationship.last_name
    , relationship.first_name
    , Case
        When trim(relationship.relation_id_number) Is Not Null
          Then entity.pref_mail_name
        When trim(relationship.relation_name) Is Not Null
          Then relationship.relation_name
        Else trim(
          trim(relationship.first_name) || ' ' || trim(relationship.last_name)
        )
        End
      As child_name
    , Case
        When entity.institutional_suffix Is Not Null
          Then entity.institutional_suffix
        Else ' '
        End
      As child_institutional_suffix
  From relationship
  Inner Join tms_relationships tms_r
    On tms_r.relation_type_code = relationship.relation_type_code
  Left Join entity
    On entity.id_number = relationship.relation_id_number
  Where relationship.relation_type_code In ('CP', 'SP') -- child/parent, stepchild/parent
)

-- Children coded under children
, children_table As (
  Select
    children.id_number
    , children.child_id_number
    , children.preferred_name
    , children.child_relation_code
    , tms_r.short_desc
      As relation_type
    , children.record_status_type
    , Case
        When entity.gender_code Is Not Null
          Then entity.gender_code
        Else children.gender_code
        End
      As child_gender_code
    , children.last_name
    , children.first_name
    , Case
      When trim(children.child_id_number) Is Not Null
        Then entity.pref_mail_name
      When trim(children.preferred_name) Is Not Null
        Then children.preferred_name
      Else trim(
        trim(children.first_name) || ' ' || trim(children.last_name)
      )
      End
    As child_name
  , Case
      When entity.institutional_suffix Is Not Null
        Then entity.institutional_suffix
      Else ' '
      End
    As child_institutional_suffix
  From children
  Inner Join tms_relationships tms_r
    On tms_r.relation_type_code = children.child_relation_code
  Left Join entity
    On entity.id_number = children.child_id_number
  Where children.child_relation_code In ('CP', 'SP') -- child/parent, stepchild/parent
)

-- Combined children
-- Goal: dedupe based on id_number where available, otherwise name and gender
, children_combined As (
  -- Select relevant fields
  Select
    id_number
    , child_id_number
    , child_gender_code
    , relation_type
    , child_name
    , child_institutional_suffix
  From children_table
  Union
  Select 
    id_number
    , child_id_number
    , child_gender_code
    , relation_type
    , child_name
    , child_institutional_suffix
  From relationship_table
)

-- Concatenated children
, children_concat As (
  Select
    id_number
    , count(child_name)
      As deduped_children_count
    , sum(Case When child_institutional_suffix Is Not Null Then 1 Else 0 End)
      As deduped_children_nu_count
    , Listagg(child_id_number, chr(13)) Within Group (Order By child_id_number Asc, child_name Asc)
      As child_id_numbers
    , Listagg(child_name, chr(13)) Within Group (Order By child_id_number Asc, child_name Asc)
      As child_names
    , Listagg(child_institutional_suffix, chr(13)) Within Group (Order By child_id_number Asc, child_name Asc)
      As child_institutional_suffixes
    , Listagg(relation_type, chr(13)) Within Group (Order By child_id_number Asc, child_name Asc)
      As child_relation_types
    , Listagg(child_gender_code, chr(13)) Within Group (Order By child_id_number Asc, child_name Asc)
      As child_gender_codes
  From children_combined
  Group By
    id_number
)

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
  , children_concat.deduped_children_count
  , children_concat.deduped_children_nu_count
  , children_concat.child_id_numbers
  , children_concat.child_names
  , children_concat.child_institutional_suffixes
  , children_concat.child_relation_types
  , children_concat.child_gender_codes
From entity
Left Join sal_concat
  On sal_concat.id_number = entity.id_number
Left Join spouse
  On spouse.id_number = entity.id_number
Left Join children_concat
  On children_concat.id_number = entity.id_number
;

