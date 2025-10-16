Create Or Replace Package ksm_pkg_entity Is

/*************************************************************************
Author  : PBH634
Created : 4/15/2025
Purpose : Combine all constituent and organization records into a single table, with
  standardized fields.
Dependencies: dw_pkg_base

Suggested naming conventions:
  Pure functions: [function type]_[description]
  Row-by-row retrieval (slow): get_[object type]_[action or description] e.g.
  Table or cursor retrieval (fast): tbl_[object type]_[action or description]
*************************************************************************/

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_entity';

/*************************************************************************
Public type declarations
*************************************************************************/

--------------------------------------
Type rec_entity Is Record (
  person_or_org varchar2(1)
  , salesforce_id dm_alumni.dim_constituent.constituent_salesforce_id%type
  , household_id dm_alumni.dim_constituent.constituent_household_account_salesforce_id%type
  , household_primary dm_alumni.dim_constituent.household_primary_constituent_indicator%type
  , household_id_ksm dm_alumni.dim_constituent.constituent_household_account_salesforce_id%type
  , household_primary_ksm dm_alumni.dim_constituent.household_primary_constituent_indicator%type
  , donor_id dm_alumni.dim_constituent.constituent_donor_id%type
  , ses_id stg_alumni.contact.ucinn_ascendv2__student_information_system_id__c%type
  , full_name dm_alumni.dim_constituent.full_name%type
  , sort_name dm_alumni.dim_constituent.full_name%type
  , salutation dm_alumni.dim_constituent.salutation%type
  , first_name dm_alumni.dim_constituent.full_name%type
  , middle_name dm_alumni.dim_constituent.middle_name%type
  , last_name dm_alumni.dim_constituent.full_name%type
  , is_deceased_indicator dm_alumni.dim_constituent.is_deceased_indicator%type
  , lost_indicator varchar2(1)
  , donor_advised_fund_indicator varchar2(1)
  , primary_record_type dm_alumni.dim_constituent.primary_constituent_type%type
  , institutional_suffix dm_alumni.dim_constituent.institutional_suffix%type
  , spouse_donor_id dm_alumni.dim_constituent.spouse_constituent_donor_id%type
  , spouse_name dm_alumni.dim_constituent.spouse_name%type
  , spouse_institutional_suffix dm_alumni.dim_constituent.spouse_instituitional_suffix%type
  , org_ult_parent_donor_id dm_alumni.dim_organization.organization_ultimate_parent_donor_id %type
  , org_ult_parent_name dm_alumni.dim_organization.organization_ultimate_parent_name%type
  , preferred_address_status dm_alumni.dim_constituent.preferred_address_status%type
  , preferred_address_type dm_alumni.dim_constituent.preferred_address_type%type
  , preferred_address_line_1 dm_alumni.dim_constituent.preferred_address_line_1%type
  , preferred_address_line_2 dm_alumni.dim_constituent.preferred_address_line_2%type
  , preferred_address_line_3 dm_alumni.dim_constituent.preferred_address_line_3%type
  , preferred_address_line_4 dm_alumni.dim_constituent.preferred_address_line_4%type
  , preferred_address_city dm_alumni.dim_constituent.preferred_address_city%type
  , preferred_address_state dm_alumni.dim_constituent.preferred_address_state%type
  , preferred_address_postal_code dm_alumni.dim_constituent.preferred_address_postal_code%type
  , preferred_address_country dm_alumni.dim_constituent.preferred_address_country_name%type
  , gender_identity dm_alumni.dim_constituent.gender_identity%type
  , gender_code varchar2(1)
  , citizenship dm_alumni.dim_constituent.citizenship_list%type
  , ethnicity dm_alumni.dim_constituent.ethnicity%type
  , university_overall_rating dm_alumni.dim_constituent.constituent_university_overall_rating%type
  , research_evaluation dm_alumni.dim_constituent.constituent_research_evaluation%type
  , research_evaluation_date dm_alumni.dim_constituent.constituent_research_evaluation_date%type
  , etl_update_date dm_alumni.dim_constituent.etl_update_date%type
);

--------------------------------------
Type rec_entity_relationship Is Record (
  relationship_record_id stg_alumni.ucinn_ascendv2__relationship__c.name%type
  , relationship_status stg_alumni.ucinn_ascendv2__relationship__c.ucinn_ascendv2__status__c%type
  , primary_donor_id stg_alumni.contact.ucinn_ascendv2__donor_id__c%type
  , primary_full_name dm_alumni.dim_constituent.full_name%type
  , primary_sort_name dm_alumni.dim_constituent.full_name%type
  , primary_institutional_suffix dm_alumni.dim_constituent.institutional_suffix%type
  , primary_role stg_alumni.ucinn_ascendv2__relationship__c.ucinn_ascendv2__contact_role_formula__c%type
  , primary_role_type varchar2(30)
  , relationship_donor_id stg_alumni.ucinn_ascendv2__relationship__c.ucinn_ascendv2__related_contact_donor_id_formula__c%type
  , relationship_full_name dm_alumni.dim_constituent.full_name%type
  , relationship_sort_name dm_alumni.dim_constituent.full_name%type
  , relationship_institutional_suffix dm_alumni.dim_constituent.institutional_suffix%type
  , relationship_role stg_alumni.ucinn_ascendv2__relationship__c.ucinn_ascendv2__related_contact_role__c%type
  , relationship_notes stg_alumni.ucinn_ascendv2__relationship__c.ucinn_ascendv2__notes__c%type
  , etl_update_date stg_alumni.ucinn_ascendv2__relationship__c.etl_update_date%type
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type entity Is Table Of rec_entity;
Type entity_relationships Is Table Of rec_entity_relationship;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

Function tbl_entity
  Return entity Pipelined;

Function tbl_entity_relationships
  Return entity_relationships Pipelined;

End ksm_pkg_entity;
/
Create Or Replace Package Body ksm_pkg_entity Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

--------------------------------------
-- Households minus the slow address information
Cursor c_entity Is
  (
  Select
    'P' As person_or_org
    , c.salesforce_id
    , c.household_id
    , c.household_primary
    , least(c.household_id, nvl(c.spouse_household_id, c.household_id))
      As household_id_ksm
    , Case
        When c.household_primary = 'N'
          Then 'N'
        When c.household_id = least(c.household_id, nvl(c.spouse_household_id, c.household_id))
          Then 'Y'
        Else 'N'
        End
      As household_primary_ksm
    , c.donor_id
    , ct.ses_id
    , c.full_name
    , c.sort_name
    , c.salutation
    , c.first_name
    , c.middle_name
    , c.last_name
    , c.is_deceased_indicator
    , Case When preferred_address_status Is Null Then 'Y' Else 'N' End
      As lost_indicator
    , NULL As donor_advised_fund_indicator
    , c.primary_constituent_type As primary_record_type
    , institutional_suffix
    , spouse_donor_id
    , spouse_name
    , spouse_instituitional_suffix
    , NULL As org_ult_parent_donor_id
    , NULL As org_ult_parent_name
    , preferred_address_status
    , preferred_address_type
    , preferred_address_line_1
    , preferred_address_line_2
    , preferred_address_line_3
    , preferred_address_line_4
    , preferred_address_city
    , preferred_address_state
    , preferred_address_postal_code
    , preferred_address_country
    , gender_identity
    , Case
        When gender_identity Like '%Man - Unspecified%'
          Then 'M'
        When gender_identity Like '%Woman - Unspecified%'
          Then 'F'
        Else 'U'
        End
      As gender_code
    , citizenship
    , ethnicity
    , constituent_university_overall_rating As university_overall_rating
    , constituent_research_evaluation As research_evaluation
    , constituent_research_evaluation_date As research_evaluation_date
    , c.etl_update_date
  From table(dw_pkg_base.tbl_constituent) c
  Left Join table(dw_pkg_base.tbl_contact) ct
    On ct.donor_id = c.donor_id
  ) Union All ( 
  Select 
    'O' As person_or_org
    , o.salesforce_id
    , o.ult_parent_id As household_id
    , o.org_primary
    , o.ult_parent_id
      As household_id_ksm
    , o.org_primary
      As household_primary_ksm
    , o.donor_id
    , ct.ses_id
    , o.organization_name
    , o.sort_name
    , NULL As salutation
    , o.organization_name As first_name
    , NULL As middle_name
    , NULL As last_name
    , o.organization_inactive_indicator
    , Case When preferred_address_status Is Null Then 'Y' Else 'N' End
      As lost_indicator
    , Case When donor_advised_fund_indicator = 'true' Then 'Y' End
      As donor_advised_fund_indicator
    , o.organization_type As primary_record_type
    , NULL As institutional_suffix
    , NULL As spouse_donor_id
    , NULL As spouse_name
    , NULL As spouse_institutional_suffix
    , o.org_ult_parent_donor_id
    , o.org_ult_parent_name
    , preferred_address_status
    , preferred_address_type
    , preferred_address_line_1
    , preferred_address_line_2
    , preferred_address_line_3
    , preferred_address_line_4
    , preferred_address_city
    , preferred_address_state
    , preferred_address_postal_code
    , preferred_address_country
    , NULL As gender_identity
    , NULL As gender_code
    , NULL As citizenship
    , NULL As ethnicity
    , organization_university_overall_rating As university_overall_rating
    , organization_research_evaluation As research_evaluation
    , organization_research_evaluation_date As research_evaluation_date
    , o.etl_update_date
  From table(dw_pkg_base.tbl_organization) o
  Left Join table(dw_pkg_base.tbl_contact) ct
    On ct.donor_id = o.donor_id
  )
;

--------------------------------------
-- Relationships helper cursor
Cursor c_entity_relationships Is
  Select
    rel.relationship_record_id
    , rel.relationship_status
    , rel.primary_donor_id
    , me_pri.full_name
      As primary_full_name
    , me_pri.sort_name
      As primary_sort_name
    , me_pri.institutional_suffix
      As primary_institutional_suffix
    , rel.primary_role
    , rel.primary_role_type
    , rel.relationship_donor_id
    , me_rel.full_name
      As relationship_full_name
    , me_rel.sort_name
      As relationship_sort_name
    , me_rel.institutional_suffix
      As relationship_institutional_suffix
    , rel.relationship_role
    , rel.relationship_notes
    , rel.etl_update_date
  From table(dw_pkg_base.tbl_relationships) rel
  Inner Join mv_mini_entity me_pri
    On me_pri.donor_id = rel.primary_donor_id
  Inner Join mv_mini_entity me_rel
    On me_rel.donor_id = rel.relationship_donor_id
;

/*************************************************************************
Pipelined functions
*************************************************************************/

--------------------------------------
Function tbl_entity
  Return entity Pipelined As
  -- Declarations
  ent entity;

  Begin
    Open c_entity;
      Fetch c_entity Bulk Collect Into ent;
    Close c_entity;
    For i in 1..(ent.count) Loop
      Pipe row(ent(i));
    End Loop;
    Return;
  End;

--------------------------------------
Function tbl_entity_relationships
  Return entity_relationships Pipelined As
  -- Declarations
  rel entity_relationships;

  Begin
    Open c_entity_relationships;
      Fetch c_entity_relationships Bulk Collect Into rel;
    Close c_entity_relationships;
    For i in 1..(rel.count) Loop
      Pipe row(rel(i));
    End Loop;
    Return;
  End;

End ksm_pkg_entity;
/
