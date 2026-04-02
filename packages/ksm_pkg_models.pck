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
Type rec_ksm_model_alumni_engagement Is Record (
  donor_id svc_kellogg_alumni_reporting.tbl_ksm_model_ae.id_number%type
  , segment_code svc_kellogg_alumni_reporting.tbl_ksm_model_ae.segment_code%type
  , description svc_kellogg_alumni_reporting.tbl_ksm_model_ae.segment_name%type
  , segment_year svc_kellogg_alumni_reporting.tbl_ksm_model_ae.segment_year%type
  , segment_month svc_kellogg_alumni_reporting.tbl_ksm_model_ae.segment_month%type
  , score svc_kellogg_alumni_reporting.tbl_ksm_model_ae.xcomment%type
);

--------------------------------------
Type rec_ksm_model_student_supporter Is Record (
  donor_id svc_kellogg_alumni_reporting.tbl_ksm_model_ss.id_number%type
  , segment_code svc_kellogg_alumni_reporting.tbl_ksm_model_ss.segment_code%type
  , description svc_kellogg_alumni_reporting.tbl_ksm_model_ss.segment_name%type
  , segment_year svc_kellogg_alumni_reporting.tbl_ksm_model_ss.segment_year%type
  , segment_month svc_kellogg_alumni_reporting.tbl_ksm_model_ss.segment_month%type
  , score svc_kellogg_alumni_reporting.tbl_ksm_model_ss.xcomment%type
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
  , mg_id_description varchar2(60)
  , mg_id_score number
  , mg_pr_code varchar2(20)
  , mg_pr_description varchar2(60)
  , mg_pr_score number
  , mg_probability number
  , af_10k_code varchar2(20)
  , af_10k_description varchar2(60)
  , af_10k_score number
  , af_pr_code varchar2(20)
  , af_pr_description varchar2(60)
  , af_pr_score number
  , alumni_engagement_code varchar2(20)
  , alumni_engagement_description varchar2(60)
  , alumni_engagement_score number
  , student_supporter_code varchar2(20)
  , student_supporter_description varchar2(60)
  , student_supporter_score number
  , etl_update_date date
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type ksm_model_mg Is Table Of rec_ksm_model_mg;
Type ksm_model_af_10k Is Table Of rec_ksm_model_af_10k;
Type ksm_model_alumni_engagement Is Table Of rec_ksm_model_alumni_engagement;
Type ksm_model_student_supporter Is Table Of rec_ksm_model_student_supporter;
Type ksm_models Is Table Of rec_ksm_models;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

Function tbl_ksm_model_mg
  Return ksm_model_mg Pipelined;
  
Function tbl_ksm_model_af_10k
  Return ksm_model_af_10k Pipelined;

Function tbl_ksm_model_af_pr
  Return ksm_model_af_10k Pipelined;

Function tbl_ksm_model_alumni_engagement
  Return ksm_model_alumni_engagement Pipelined;

Function tbl_ksm_model_student_supporter
  Return ksm_model_student_supporter Pipelined;

Function tbl_ksm_models
  Return ksm_models Pipelined;

Function tbl_ksm_models_hh
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

Cursor c_ksm_model_af_pr Is
  Select
    e.donor_id
    , 2026 As segment_year
    , 3 As segment_month
    , 'AFPR' As segment_code
    , m.af_fy26_tier
      As description
    , m.af_fy26_score
      As score
  From af_fy26_model m
  Inner Join mv_entity e
    On e.household_id_ksm = m.household_id_ksm
    And e.household_primary_ksm = 'Y'
;

--------------------------------------
-- All alumni engagement model scores
Cursor c_ksm_model_alumni_engagement Is
  Select *
  From tbl_ksm_model_ae
;

--------------------------------------
-- All student supporter model scores
Cursor c_ksm_model_student_supporter Is
  Select *
  From tbl_ksm_model_ss
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
  
  , afpr As (
    Select
      pr.donor_id
      , pr.segment_year
      , pr.segment_month
      , pr.segment_code
      , pr.description
      , pr.score
    From table(ksm_pkg_models.tbl_ksm_model_af_pr) pr
  )
  
  , ae As (
    Select
      alen.donor_id
      , alen.segment_year
      , alen.segment_month
      , alen.segment_code
      , alen.description
      , alen.score
    From table(ksm_pkg_models.tbl_ksm_model_alumni_engagement) alen
  )
  
  , ss As (
    Select
      alss.donor_id
      , alss.segment_year
      , alss.segment_month
      , alss.segment_code
      , alss.description
      , alss.score
    From table(ksm_pkg_models.tbl_ksm_model_student_supporter) alss
  )
  
  , allids As (
    Select donor_id From mg
    Union
    Select donor_id From af
    Union
    Select donor_id From afpr
    Union
    Select donor_id From ae
    Union
    Select donor_id From ss
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
    -- MGID
    , mg.id_code
      As mg_id_code
    , mg.id_segment
      As mg_id_description
    , mg.id_score
      As mg_id_score
    -- MGPR
    , mg.pr_code
      As mg_pr_code
    , mg.pr_segment
      As mg_pr_description
    , mg.pr_score
      As mg_pr_score
    , mg.est_probability
      As mg_probability
    -- AF
    , af.segment_code
      As af_10k_code
    , af.description
      As af_10k_description
    , af.score
      As af_10k_score
    -- AFPR
    , afpr.segment_code
      As af_pr_code
    , afpr.description
      As af_pr_description
    , afpr.score
      As af_pr_score
    -- AE
    , ae.segment_code
      As alumni_engagement_code
    , ae.description
      As alumni_engagement_description
    , ae.score
      As alumni_engagement_score
    -- AESS
    , ss.segment_code
      As student_supporter_code
    , ss.description
      As student_supporter_description
    , ss.score
      As student_supporter_score
    , to_date('20250504', 'yyyymmdd')
      As etl_update_date
  From allids
  Inner Join mv_entity mve
    On mve.donor_id = allids.donor_id
  Left Join mg
    On mg.donor_id = allids.donor_id
  Left Join af
    On af.donor_id = allids.donor_id
  Left Join afpr
    On afpr.donor_id = allids.donor_id
  Left Join ae
    On ae.donor_id = allids.donor_id
  Left Join ss
    On ss.donor_id = allids.donor_id
;

--------------------------------------
-- Merged model scores, householded

Cursor c_ksm_models_hh Is

  With
  
  model As (
    Select *
    From table(ksm_pkg_models.tbl_ksm_models)
  )
  
  , hh_max_score As (
    Select Distinct
      household_id_ksm
      , max(household_primary_ksm)
        As household_primary_ksm
      -- Sort by higher score, then HH primary
      -- MGID
      , max(mg_id_code) keep(dense_rank First Order By mg_id_score Desc Nulls Last, household_primary_ksm Desc)
        As mg_id_code
      , max(mg_id_description) keep(dense_rank First Order By mg_id_score Desc Nulls Last, household_primary_ksm Desc)
        As mg_id_description
      , max(mg_id_score) keep(dense_rank First Order By mg_id_score Desc Nulls Last, household_primary_ksm Desc)
        As mg_id_score
      -- MGPR
      , max(mg_pr_code) keep(dense_rank First Order By mg_pr_score Desc Nulls Last, household_primary_ksm Desc)
        As mg_pr_code
      , max(mg_pr_description) keep(dense_rank First Order By mg_pr_score Desc Nulls Last, household_primary_ksm Desc)
        As mg_pr_description
      , max(mg_pr_score) keep(dense_rank First Order By mg_pr_score Desc Nulls Last, household_primary_ksm Desc)
        As mg_pr_score
      , max(mg_probability) keep(dense_rank First Order By mg_pr_score Desc Nulls Last, household_primary_ksm Desc)
        As mg_probability
      -- AF
      , max(af_10k_code) keep(dense_rank First Order By af_10k_score Desc Nulls Last, household_primary_ksm Desc)
        As af_10k_code
      , max(af_10k_description) keep(dense_rank First Order By af_10k_score Desc Nulls Last, household_primary_ksm Desc)
        As af_10k_description
      , max(af_10k_score) keep(dense_rank First Order By af_10k_score Desc Nulls Last, household_primary_ksm Desc)
        As af_10k_score
      -- AFPR
      , max(af_pr_code) keep(dense_rank First Order By af_pr_score Desc Nulls Last, household_primary_ksm Desc)
        As af_pr_code
      , max(af_pr_description) keep(dense_rank First Order By af_pr_score Desc Nulls Last, household_primary_ksm Desc)
        As af_pr_description
      , max(af_pr_score) keep(dense_rank First Order By af_pr_score Desc Nulls Last, household_primary_ksm Desc)
        As af_pr_score
      -- AE
      , max(alumni_engagement_code) keep(dense_rank First Order By alumni_engagement_score Desc Nulls Last, household_primary_ksm Desc)
        As alumni_engagement_code
      , max(alumni_engagement_description) keep(dense_rank First Order By alumni_engagement_score Desc Nulls Last, household_primary_ksm Desc)
        As alumni_engagement_description
      , max(alumni_engagement_score) keep(dense_rank First Order By alumni_engagement_score Desc Nulls Last, household_primary_ksm Desc)
        As alumni_engagement_score
      -- AESS
      , max(student_supporter_code) keep(dense_rank First Order By student_supporter_score Desc Nulls Last, household_primary_ksm Desc)
        As student_supporter_code
      , max(student_supporter_description) keep(dense_rank First Order By student_supporter_score Desc Nulls Last, household_primary_ksm Desc)
        As student_supporter_description
      , max(student_supporter_score) keep(dense_rank First Order By student_supporter_score Desc Nulls Last, household_primary_ksm Desc)
        As student_supporter_score
      -- ETL
      , max(etl_update_date)
        As etl_update_date
    From model
    Group By household_id_ksm
  )
  
  Select
    model.donor_id
    , model.household_id
    , model.household_primary
    , hms.household_id_ksm
    , hms.household_primary_ksm
    , model.sort_name
    , model.primary_record_type
    , model.institutional_suffix
    -- MGID
    , hms.mg_id_code
    , hms.mg_id_description
    , hms.mg_id_score
    -- MGPR
    , hms.mg_pr_code
    , hms.mg_pr_description
    , hms.mg_pr_score
    , hms.mg_probability
    -- AF
    , hms.af_10k_code
    , hms.af_10k_description
    , hms.af_10k_score
    -- AFPR
    , hms.af_pr_code
    , hms.af_pr_description
    , hms.af_pr_score
    -- AE
    , hms.alumni_engagement_code
    , hms.alumni_engagement_description
    , hms.alumni_engagement_score
    -- AESS
    , hms.student_supporter_code
    , hms.student_supporter_description
    , hms.student_supporter_score
    -- ETL
    , model.etl_update_date
  From hh_max_score hms
  Inner Join model
    On model.household_id_ksm = hms.household_id_ksm
    And model.household_primary_ksm = hms.household_primary_ksm
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
Function tbl_ksm_model_af_pr
  Return ksm_model_af_10k Pipelined As
  -- Declarations
  af ksm_model_af_10k;
  
  Begin
    Open c_ksm_model_af_pr;
      Fetch c_ksm_model_af_pr Bulk Collect Into af;
    Close c_ksm_model_af_pr;
    For i in 1..(af.count) Loop
      Pipe row(af(i));
    End Loop;
    Return;
  End;

--------------------------------------
Function tbl_ksm_model_alumni_engagement
  Return ksm_model_alumni_engagement Pipelined As
  -- Declarations
  ae ksm_model_alumni_engagement;
  
  Begin
    Open c_ksm_model_alumni_engagement;
      Fetch c_ksm_model_alumni_engagement Bulk Collect Into ae;
    Close c_ksm_model_alumni_engagement;
    For i in 1..(ae.count) Loop
      Pipe row(ae(i));
    End Loop;
    Return;
  End;
  
--------------------------------------
Function tbl_ksm_model_student_supporter
  Return ksm_model_student_supporter Pipelined As
  -- Declarations
  ss ksm_model_student_supporter;
  
  Begin
    Open c_ksm_model_student_supporter;
      Fetch c_ksm_model_student_supporter Bulk Collect Into ss;
    Close c_ksm_model_student_supporter;
    For i in 1..(ss.count) Loop
      Pipe row(ss(i));
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

--------------------------------------
Function tbl_ksm_models_hh
  Return ksm_models Pipelined As
  -- Declarations
  km ksm_models;
  
  Begin
    Open c_ksm_models_hh;
      Fetch c_ksm_models_hh Bulk Collect Into km;
    Close c_ksm_models_hh;
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
