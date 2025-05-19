Create Or Replace Package ksm_pkg_households Is

/*************************************************************************
Author  : PBH634
Created : 5/19/2025
Purpose : Rolled up household biodata summary information.
Dependencies: ksm_pkg_entity (mv_entity), ksm_pkg_degrees (mv_entity_ksm_degrees)

Suggested naming conventions:
  Pure functions: [function type]_[description]
  Row-by-row retrieval (slow): get_[object type]_[action or description] e.g.
  Table or cursor retrieval (fast): tbl_[object type]_[action or description]
*************************************************************************/

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_households';

/*************************************************************************
Public type declarations
*************************************************************************/

Type rec_household Is Record (
  household_id mv_entity.household_id%type
  , household_account_name mv_entity.full_name%type
  , person_or_org mv_entity.person_or_org%type
  , household_primary_donor_id mv_entity.donor_id%type
  , household_primary_full_name mv_entity.full_name%type
  , household_primary_sort_name mv_entity.sort_name%type
  , household_suffix mv_entity.institutional_suffix%type
  , household_spouse_donor_id mv_entity.spouse_donor_id%type
  , household_spouse_full_name mv_entity.spouse_name%type
  , household_spouse_suffix mv_entity.spouse_institutional_suffix%type
  , household_first_ksm_year mv_entity_ksm_degrees.first_ksm_year%type
  , household_first_masters_year mv_entity_ksm_degrees.first_masters_year%type
  , household_last_masters_year mv_entity_ksm_degrees.last_masters_year%type
  , household_program mv_entity_ksm_degrees.program%type
  , household_program_group mv_entity_ksm_degrees.program_group%type
  , etl_update_date mv_entity.etl_update_date%type
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type households Is Table Of rec_household;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

Function tbl_households
  Return households Pipelined;

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

End ksm_pkg_households;
/
Create Or Replace Package Body ksm_pkg_households Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

Cursor c_households Is

  With
  
  -- Find max degree info
  hhdeg As (
    Select
      mve.household_id
      , min(deg.first_ksm_year)
        As household_first_ksm_year
      , min(deg.first_masters_year)
        As household_first_masters_year
      , max(deg.last_masters_year)
        As household_last_masters_year
      , min(deg.program) keep(dense_rank First Order By deg.program_group_rank Asc, mve.household_primary Desc)
        As household_program
      , min(deg.program_group) keep(dense_rank First Order By deg.program_group_rank Asc, mve.household_primary Desc)
        As household_program_group
      , max(deg.etl_update_date)
        As etl_update_date
    From mv_entity_ksm_degrees deg
    Inner Join mv_entity mve
      On mve.donor_id = deg.donor_id
    Group By mve.household_id
  )

  -- Primary HH member info
  Select
    mve.household_id
    , Case
        When hh.household_account_name Is Not Null
          Then hh.household_account_name
        Else mve.full_name
      End
      As household_account_name
    , mve.person_or_org
    , mve.donor_id As household_primary_donor_id
    , mve.full_name As household_primary_full_name
    , mve.sort_name As household_primary_sort_name
    , mve.institutional_suffix As household_suffix
    , mve.spouse_donor_id As household_spouse_donor_id
    , mve.spouse_name As household_spouse_full_name
    , mve.spouse_institutional_suffix As household_spouse_suffix
    , hhdeg.household_first_ksm_year
    , hhdeg.household_first_masters_year
    , hhdeg.household_last_masters_year
    , hhdeg.household_program
    , hhdeg.household_program_group
    , greatest(mve.etl_update_date, hhdeg.etl_update_date, hh.etl_update_date)
      As etl_update_date
  From mv_entity mve
  Left Join dm_alumni.dim_household hh
    On hh.household_donor_id = mve.household_id
  Left Join hhdeg
    On hhdeg.household_id = mve.household_id
  Where mve.household_primary = 'Y'
;

/*************************************************************************
Pipelined functions
*************************************************************************/

Function tbl_households
  Return households Pipelined As
  -- Declarations
  hh households;

  Begin
    Open c_households;
      Fetch c_households Bulk Collect Into hh;
    Close c_households;
    For i in 1..(hh.count) Loop
      Pipe row(hh(i));
    End Loop;
    Return;
  End;

End ksm_pkg_households;
/
