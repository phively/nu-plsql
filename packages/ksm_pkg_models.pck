Create Or Replace Package ksm_pkg_models Is

/*************************************************************************
Author  : PBH634
Created : 10/9/2025
Purpose : Helper package to access recent or historical Kellogg model
  score results.
Dependencies: dw_pkg_base

Suggested naming conventions:
  Pure functions: [function type]_[description]
  Row-by-row retrieval (slow): get_[object type]_[action or description] e.g.
  Table or cursor retrieval (fast): tbl_[object type]_[action or description]
*************************************************************************/

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_models';

/*************************************************************************
Public type declarations
*************************************************************************/

--------------------------------------
Type rec_ksm_model_mg Is Record (
  donor_id svc_kellogg_alumni_reporting.tbl_ksm_model_mg.donor_id%type
  , segment_year svc_kellogg_alumni_reporting.tbl_ksm_model_mg.segment_year%type
  , segment_month svc_kellogg_alumni_reporting.tbl_ksm_model_mg.segment_month%type
  , id_code svc_kellogg_alumni_reporting.tbl_ksm_model_mg.id_code%type
  , id_segment svc_kellogg_alumni_reporting.tbl_ksm_model_mg.id_segment%type
  , id_score svc_kellogg_alumni_reporting.tbl_ksm_model_mg.id_score%type
  , pr_code svc_kellogg_alumni_reporting.tbl_ksm_model_mg.pr_code%type
  , pr_segment svc_kellogg_alumni_reporting.tbl_ksm_model_mg.pr_segment%type
  , pr_score svc_kellogg_alumni_reporting.tbl_ksm_model_mg.pr_score%type
  , est_probability svc_kellogg_alumni_reporting.tbl_ksm_model_mg.est_probability%type
);

--------------------------------------
Type rec_ksm_model_af_10k Is Record (
  donor_id svc_kellogg_alumni_reporting.tbl_ksm_model_af_10k.donor_id%type
  , segment_year svc_kellogg_alumni_reporting.tbl_ksm_model_af_10k.segment_year%type
  , segment_month svc_kellogg_alumni_reporting.tbl_ksm_model_af_10k.segment_month%type
  , segment_code svc_kellogg_alumni_reporting.tbl_ksm_model_af_10k.segment_code%type
  , description svc_kellogg_alumni_reporting.tbl_ksm_model_af_10k.description%type
  , score svc_kellogg_alumni_reporting.tbl_ksm_model_af_10k.score%type
);

--------------------------------------
Type rec_ksm_models Is Record (
  donor_id mv_entity.donor_id%type
  , household_id mv_entity.household_id%type
  , household_primary mv_entity.household_primary%type
  , household_id_ksm mv_entity.household_id_ksm%type
  , household_primary_ksm mv_entity.household_primary_ksm%type
  , sort_name mv_entity.sort_name%type
  , primary_record_type mv_entity.primary_record_type%type
  , institutional_suffix mv_entity.institutional_suffix%type
  , mg_id_code varchar2(20)
  , mg_id_description varchar2(20)
  , mg_id_score number
  , mg_pr_code varchar2(20)
  , mg_pr_description varchar2(20)
  , mg_pr_score number
  , mg_probability number
  , af_10k_code varchar2(20)
  , af_10k_description varchar2(20)
  , af_10k_score number
  , etl_update_date date
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type ksm_model_mg Is Table Of rec_ksm_model_mg;
Type ksm_model_af_10k Is Table Of rec_ksm_model_af_10k;
Type ksm_models Is Table Of rec_ksm_models;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

Function tbl_ksm_model_mg
  Return ksm_model_mg Pipelined;
  
Function tbl_ksm_model_af_10k
  Return ksm_model_af_10k Pipelined;

Function tbl_ksm_models
  Return ksm_models Pipelined;

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

End ksm_pkg_models;
/
Create Or Replace Package Body ksm_pkg_models Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

--------------------------------------
-- All MG model scores
Cursor c_ksm_model_mg Is
  Select *
  From tbl_ksm_model_mg
;

--------------------------------------
-- All AF model scores
Cursor c_ksm_model_af_10k Is
  Select *
  From tbl_ksm_model_af_10k
;

--------------------------------------
-- All alumni engagement model scores
Cursor c_ksm_model_ae Is
  Select NULL
  From DUAL
;

--------------------------------------
-- All student supporter model scores
Cursor c_ksm_model_ss Is
  Select NULL
  From DUAL
;

--------------------------------------
-- Merged model scores
Cursor c_ksm_models Is

  With

  mg As (
    Select
      mg.donor_id
      , mg.segment_year
      , mg.segment_month
      , mg.id_code
      , mg.id_segment
      , mg.id_score
      , mg.pr_code
      , mg.pr_segment
      , mg.pr_score
      , mg.est_probability
    From table(ksm_pkg_models.tbl_ksm_model_mg) mg
  )
  
  , af As (
    Select
      af10k.donor_id
      , af10k.segment_year
      , af10k.segment_month
      , af10k.segment_code
      , af10k.description
      , af10k.score
    From table(ksm_pkg_models.tbl_ksm_model_af_10k) af10k
  )
  
  , allids As (
    Select donor_id From mg
    Union
    Select donor_id From af
  )
  
  Select
    allids.donor_id
    , mve.household_id
    , mve.household_primary
    , mve.household_id_ksm
    , mve.household_primary_ksm
    , mve.sort_name
    , mve.primary_record_type
    , mve.institutional_suffix
    , mg.id_code
      As mg_id_code
    , mg.id_segment
      As mg_id_description
    , mg.id_score
      As mg_id_score
    , mg.pr_code
      As mg_pr_code
    , mg.pr_segment
      As mg_pr_description
    , mg.pr_score
      As mg_pr_score
    , mg.est_probability
      As mg_probability
    , af.segment_code
      As af_10k_code
    , af.description
      As af_10k_description
    , af.score
      As af_10k_score
    , to_date('20250504', 'yyyymmdd')
      As etl_update_date
  From allids
  Inner Join mv_entity mve
    On mve.donor_id = allids.donor_id
  Left Join mg
    On mg.donor_id = allids.donor_id
  Left Join af
    On af.donor_id = allids.donor_id
;

/*************************************************************************
Private functions
*************************************************************************/

--------------------------------------
Function tbl_ksm_model_mg
  Return ksm_model_mg Pipelined As
  -- Declarations
  mg ksm_model_mg;
  
  Begin
    Open c_ksm_model_mg;
      Fetch c_ksm_model_mg Bulk Collect Into mg;
    Close c_ksm_model_mg;
    For i in 1..(mg.count) Loop
      Pipe row(mg(i));
    End Loop;
    Return;
  End;

--------------------------------------
Function tbl_ksm_model_af_10k
  Return ksm_model_af_10k Pipelined As
  -- Declarations
  af ksm_model_af_10k;
  
  Begin
    Open c_ksm_model_af_10k;
      Fetch c_ksm_model_af_10k Bulk Collect Into af;
    Close c_ksm_model_af_10k;
    For i in 1..(af.count) Loop
      Pipe row(af(i));
    End Loop;
    Return;
  End;

--------------------------------------
Function tbl_ksm_models
  Return ksm_models Pipelined As
  -- Declarations
  km ksm_models;
  
  Begin
    Open c_ksm_models;
      Fetch c_ksm_models Bulk Collect Into km;
    Close c_ksm_models;
    For i in 1..(km.count) Loop
      Pipe row(km(i));
    End Loop;
    Return;
  End;

/*************************************************************************
Pipelined functions
*************************************************************************/


End ksm_pkg_models;
/
