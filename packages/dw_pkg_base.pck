Create Or Replace Package dw_pkg_base Is

/*************************************************************************
Author  : PBH634
Created : 4/9/2025
Purpose : description
Dependencies: none

Suggested naming conventions:
  Pure functions: [function type]_[description]
  Row-by-row retrieval (slow): get_[object type]_[action or description] e.g.
  Table or cursor retrieval (fast): tbl_[object type]_[action or description]
*************************************************************************/

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'dw_pkg_base';

/*************************************************************************
Public type declarations
*************************************************************************/

Type rec_constituent Is Record (
  salesforce_id dm_alumni.dim_constituent.constituent_salesforce_id%type
  , household_id dm_alumni.dim_constituent.constituent_household_account_salesforce_id%type
  , household_primary dm_alumni.dim_constituent.household_primary_constituent_indicator%type
  , donor_id dm_alumni.dim_constituent.constituent_donor_id%type
  , full_name dm_alumni.dim_constituent.full_name%type
  , sort_name dm_alumni.dim_constituent.full_name%type
  , is_deceased_indicator dm_alumni.dim_constituent.is_deceased_indicator%type
  , primary_constituent_type dm_alumni.dim_constituent.primary_constituent_type%type
  , institutional_suffix dm_alumni.dim_constituent.institutional_suffix%type
  , spouse_donor_id dm_alumni.dim_constituent.spouse_constituent_donor_id%type
  , spouse_name dm_alumni.dim_constituent.spouse_name%type
  , spouse_instituitional_suffix dm_alumni.dim_constituent.spouse_instituitional_suffix%type
  , preferred_address_city dm_alumni.dim_constituent.preferred_address_city%type
  , preferred_address_state dm_alumni.dim_constituent.preferred_address_state%type
  , preferred_address_country_name dm_alumni.dim_constituent.preferred_address_country_name%type
  , etl_update_date dm_alumni.dim_constituent.etl_update_date%type
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type constituent Is Table Of rec_constituent;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

Function tbl_constituent
  Return constituent Pipelined;

/*********************** About pipelined functions ***********************
Q: What is a pipelined function?

A: Pipelined functions are used to return the results of a cursor row by row.
This is an efficient way to re-use a cursor between multiple programs. Pipelined
tables can be queried in SQL exactly like a table when embedded in the table()
function. My experience has been that thanks to the magic of the Oracle compiler,
joining on a table() function scales hugely better than running a function once
on each element of a returned column. Note that the exact columns returned need
to be specified as a public type, which I did in the type and table declarations
above, or the pipelined function can't be run in pure SQL. Alternately, the
pipelined function could return a generic table, but the columns would still need
to be individually named.
*************************************************************************/

/*************************************************************************
End of package
*************************************************************************/

End dw_pkg_base;
/
Create Or Replace Package Body dw_pkg_base Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

Cursor c_constituent Is
  Select
      constituent_salesforce_id
      As salesforce_id
    , constituent_household_account_salesforce_id
      As household_id
    , household_primary_constituent_indicator
      As household_primary
    , constituent_donor_id
      As donor_id
    , full_name
    , trim(trim(last_name || ', ' || first_name) || ' ' || Case When middle_name != '-' Then middle_name End)
      As sort_name
    , is_deceased_indicator
    , primary_constituent_type
    , institutional_suffix
    , spouse_constituent_donor_id
      As spouse_donor_id
    , spouse_name
    , spouse_instituitional_suffix
    , preferred_address_city
    , preferred_address_state
    , preferred_address_country_name
    , trunc(etl_update_date)
      As etl_update_date
  From dm_alumni.dim_constituent entity
;

/*************************************************************************
Pipelined functions
*************************************************************************/

-- Returns a pipelined table
Function tbl_constituent
  Return constituent Pipelined As
    -- Declarations
    c constituent;

  Begin
    Open c_constituent; -- Annual Fund allocations cursor
      Fetch c_constituent Bulk Collect Into c;
    Close c_constituent;
    -- Pipe out the allocations
    For i in 1..(c.count) Loop
      Pipe row(c(i));
    End Loop;
    Return;
  End;

End dw_pkg_base;
/
