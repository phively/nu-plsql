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

Type rec_entity Is Record (
    person_or_org varchar2(1)
    , salesforce_id dm_alumni.dim_constituent.constituent_salesforce_id%type
    , household_id dm_alumni.dim_constituent.constituent_household_account_salesforce_id%type
    , household_primary dm_alumni.dim_constituent.household_primary_constituent_indicator%type
    , donor_id dm_alumni.dim_constituent.constituent_donor_id%type
    , full_name dm_alumni.dim_constituent.full_name%type
    , sort_name dm_alumni.dim_constituent.full_name%type
    , is_deceased_indicator dm_alumni.dim_constituent.is_deceased_indicator%type
    , primary_record_type dm_alumni.dim_constituent.primary_constituent_type%type
    , institutional_suffix dm_alumni.dim_constituent.institutional_suffix%type
    , spouse_donor_id dm_alumni.dim_constituent.spouse_constituent_donor_id%type
    , spouse_name dm_alumni.dim_constituent.spouse_name%type
    , spouse_institutional_suffix dm_alumni.dim_constituent.spouse_instituitional_suffix%type
    , org_ult_parent_donor_id dm_alumni.dim_organization.organization_ultimate_parent_donor_id %type
    , org_ult_parent_name dm_alumni.dim_organization.organization_ultimate_parent_name%type
    , preferred_address_city dm_alumni.dim_constituent.preferred_address_city%type
    , preferred_address_state dm_alumni.dim_constituent.preferred_address_state%type
    , preferred_address_country dm_alumni.dim_constituent.preferred_address_country_name%type
    , etl_update_date dm_alumni.dim_constituent.etl_update_date%type
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type entity Is Table Of rec_entity;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

Function tbl_entity
  Return entity Pipelined;

End ksm_pkg_entity;
/
Create Or Replace Package Body ksm_pkg_entity Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

-- Households minus the slow address information
Cursor c_entity Is
  (
  Select
    'P' As person_or_org
    , c.salesforce_id
    , c.household_id
    , c.household_primary
    , c.donor_id
    , c.full_name
    , c.sort_name
    , c.is_deceased_indicator
    , c.primary_constituent_type As primary_record_type
    , nullif(c.institutional_suffix, '-')
      As institutional_suffix
    , nullif(c.spouse_donor_id, '-')
      As spouse_donor_id
    , nullif(c.spouse_name, '-')
      As spouse_name
    , nullif(c.spouse_instituitional_suffix, '-')
      As spouse_instituitional_suffix
    , NULL As org_ult_parent_donor_id
    , NULL As org_ult_parent_name
    , nullif(c.preferred_address_city, '-')
      As preferred_address_city
    , nullif(c.preferred_address_state, '-')
      As preferred_address_state
    , nullif(c.preferred_address_country, '-')
      As preferred_address_country
    , c.etl_update_date
  From table(dw_pkg_base.tbl_constituent) c
  ) Union All ( 
  Select 
    'O' As person_or_org
    , o.salesforce_id
    , o.ult_parent_id As household_id
    , o.org_primary
    , o.donor_id
    , o.organization_name
    , o.sort_name
    , o.organization_inactive_indicator
    , o.organization_type As primary_record_type
    , NULL As institutional_suffix
    , NULL As spouse_donor_id
    , NULL As spouse_name
    , NULL As spouse_institutional_suffix
    , o.org_ult_parent_donor_id
    , o.org_ult_parent_name
    , nullif(o.preferred_address_city, '-')
      As preferred_address_city
    , nullif(o.preferred_address_state, '-')
      As preferred_address_state
    , nullif(o.preferred_address_country, '-')
      As preferred_address_country
    , o.etl_update_date
  From table(dw_pkg_base.tbl_organization) o
  )
;

/*************************************************************************
Pipelined functions
*************************************************************************/

Function tbl_entity
  Return entity Pipelined As
  -- Declarations
  ent entity;

  Begin
    Open c_entity;
      Fetch c_entity Bulk Collect Into ent;
    Close c_entity;
    -- Pipe out the rows
    For i in 1..(ent.count) Loop
      Pipe row(ent(i));
    End Loop;
    Return;
  End;

End ksm_pkg_entity;
/
