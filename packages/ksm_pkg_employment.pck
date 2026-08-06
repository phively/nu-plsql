Create Or Replace Package ksm_pkg_employment Is

/*************************************************************************
Author  : PBH634
Created : 7/15/2026
Purpose : Combined definitions for employment and industry.
Dependencies: dw_pkg_base, ksm_pkg_entity (mv_entity)

Suggested naming conventions:
  Pure functions: [function type]_[description]
  Row-by-row retrieval (slow): get_[object type]_[action or description] e.g.
  Table or cursor retrieval (fast): tbl_[object type]_[action or description]
*************************************************************************/

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_employment';

--------------------------------------
Type employment Is Record (
  affiliation_salesforce_id dm_alumni.dim_affiliation.affiliation_salesforce_id%type
  , affiliation_record_id dm_alumni.dim_affiliation.affiliation_record_id%type
  , donor_id dm_alumni.dim_constituent.constituent_donor_id%type
  , full_name dm_alumni.dim_constituent.full_name%type
  , sort_name dm_alumni.dim_constituent.full_name%type
  , job_title dm_alumni.dim_affiliation.employee_job_title%type
  , employer_donor_id dm_alumni.dim_affiliation.employer_organization_donor_id%type
  , employer_name dm_alumni.dim_affiliation.employer_organization_name%type
  , employer_ult_parent_id dm_alumni.dim_affiliation.employer_ultimate_parent_organization_donor_id%type
  , employer_ult_parent_name dm_alumni.dim_affiliation.employer_ultimate_parent_organization_donor_name%type
  , employment_status dm_alumni.dim_affiliation.employment_status%type
  , primary_employment_indicator dm_alumni.dim_affiliation.primary_employment_indicator%type
  , on_leave_indicator dm_alumni.dim_affiliation.on_leave_indicator%type
  , employment_start_date stg_alumni.ucinn_ascendv2__affiliation__c.ucinn_ascendv2__start_date__c%type
  , employment_end_date stg_alumni.ucinn_ascendv2__affiliation__c.ucinn_ascendv2__end_date__c%type
  , employment_data_source stg_alumni.ucinn_ascendv2__affiliation__c.ucinn_ascendv2__data_source__c%type
  , employment_notes stg_alumni.ucinn_ascendv2__affiliation__c.ucinn_ascendv2__notes__c%type
  , etl_update_date dm_alumni.dim_affiliation.etl_update_date%type
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type t_employment Is Table Of employment;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

-- Return pipelined table of company employees with Kellogg degrees
--   N.B. uses matches pattern, user beware!
Function tbl_entity_employment
  Return t_employment Pipelined;

/*************************************************************************
Public cursors -- data definitions
*************************************************************************/

End ksm_pkg_employment;
/
Create Or Replace Package Body ksm_pkg_employment Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

--------------------------------------
Cursor c_entity_employees Is
  Select 
    e.affiliation_salesforce_id
    , e.affiliation_record_id
    , mve.donor_id
    , mve.full_name
    , mve.sort_name
    , e.employee_job_title As job_title
    , e.employer_organization_donor_id As employer_donor_id
    , e.employer_organization_name As employer_name
    , e.org_ult_parent_id As employer_ult_parent_id
    , e.org_ult_parent_name As employer_ult_parent_name
    , e.employment_status
    , e.primary_employment_indicator
    , e.on_leave_indicator
    , e.employment_start_date
    , e.employment_end_date
    , e.employment_data_source
    , e.employment_notes
    , e.etl_update_date
  From table(dw_pkg_base.tbl_employment) e
  Inner Join mv_entity mve
    On mve.donor_id = e.constituent_donor_id
;

/*************************************************************************
Pipelined functions
*************************************************************************/

-- Pipelined function returning Kellogg alumni (per c_entity_degrees_concat_ksm) who
-- work for the specified company
Function tbl_entity_employment
  Return t_employment Pipelined As
  -- Declarations
  employees t_employment;
  
  Begin
    Open c_entity_employees;
      Fetch c_entity_employees Bulk Collect Into employees;
    Close c_entity_employees;
    For i in 1..(employees.count) Loop
      Pipe row(employees(i));
    End Loop;
    Return;
  End;

End ksm_pkg_employment;
/
