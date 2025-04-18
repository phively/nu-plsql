Create Or Replace Package ksm_pkg_degrees Is

/*************************************************************************
Author  : PBH634
Created : 4/17/2025
Purpose : Kellogg alumni definition, program hierarchy, and degree strings.
Dependencies: dw_pkg_base

Suggested naming conventions:
  Pure functions: [function type]_[description]
  Row-by-row retrieval (slow): get_[object type]_[action or description] e.g.
  Table or cursor retrieval (fast): tbl_[object type]_[action or description]
*************************************************************************/

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_degrees';

/*************************************************************************
Public type declarations
*************************************************************************/

Type rec_entity_degrees_concat Is Record (
  id_number entity.id_number%type
  , report_name entity.report_name%type
  , record_status_code entity.record_status_code%type
  , degrees_verbose varchar2(1024)
  , degrees_concat varchar2(512)
  , first_ksm_grad_dt degrees.grad_dt%type
  , first_ksm_year degrees.degree_year%type
  , first_masters_year degrees.degree_year%type
  , last_masters_year degrees.degree_year%type
  , last_noncert_year degrees.degree_year%type
  , stewardship_years varchar2(80)
  , program tms_dept_code.short_desc%type
  , program_group varchar2(20)
  , program_group_rank number
  , class_section varchar2(80)
  , majors_concat varchar2(512)
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type entity_degrees_concat Is Table Of rec_entity_degrees_concat;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

Function tbl_entity_degrees_concat
  Return entity_degrees_concat Pipelined;

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

End ksm_pkg_degrees;
/
Create Or Replace Package Body ksm_pkg_degrees Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

-- Kellogg degrees concatenated
Cursor c_entity_degrees_concat Is
  With
  -- Double check academic organization inclusions
  acaorg As (
    Select id
    From stg_alumni.ucinn_ascendv2__academic_organization__c
    Where ucinn_ascendv2__code__c In (
        '95BCH', '96BEV' -- College of Commerce
        , 'AMP', 'AMPI', 'EDP', 'KSMEE' -- KSMEE certificate
      )
  )
  -- Concatenated degrees subqueries
  , deg_data As (
    Select
      deg.constituent_donor_id
      , deg.constituent_name
      , deg.degree_record_id
      , deg.degree_grad_date
      , deg.degree_year
      , deg.degree_reunion_year
      , deg.degree_status
      , deg.degree_level
      , deg.degree_code
      , deg.degree_name
      , deg.degree_school_name
      , deg.department_code
      , Case
          When deg.department_code = '01MDB' -- Joint Feinberg
            Then 'MDMBA'
          When deg.department_code Like '01%' -- Full-time, joint full-time
            Then substr(deg.department_code, 3)
          When deg.department_code = '13JDM' -- Joint Law
            Then 'JDMBA'
          When deg.department_code = '13LCM' -- Law certificate
            Then 'LLM'
          When deg.department_code Like '41%' -- EMBA and IEMBA
            Then substr(deg.department_code, 3)
          When deg.department_code = '95BCH' -- College of Commerce 1
            Then 'BCH'
          When deg.department_code = '96BEV' -- College of Commerce 2
            Then 'BEV'
          When deg.department_code In ('AMP', 'AMPI', 'EDP', 'KSMEE')  -- KSM certificates
            Then deg.department_code
          When deg.department_code = '01MBI' -- Joint McCormick
            Then 'MBAI'
          When deg.department_code = '0000000' -- None
            Then ''
          Else deg.department_desc
        End As department_desc_short
      , deg.department_desc_full
      , deg.degree_program_code
      , deg.degree_program
      , trim(
          trim(
            deg.degree_major_1 ||
            Case When deg.degree_major_2 Is Not Null Then ', ' End ||
            deg.degree_major_2
          ) || Case When deg.degree_major_3 Is Not Null Then ', ' End ||
          deg.degree_major_3
        ) As majors
    From tmp_mv_degree deg
    Where deg.nu_indicator = 'Y' -- Northwestern University
      And (
        deg.degree_school_name In ('Kellogg', 'Undergraduate Business') -- Kellogg and College of Business school codes
        Or deg.degree_code = 'MBAI' -- MBAI
        Or deginf.ap_academic_group__c In (Select id From acaorg)
      )
  )
  /*
  -- Listagg all degrees, including incomplete
  , concat As (
    Select
      id_number
      -- Verbose degrees
      , Listagg(
          trim(degree_year || ' ' || nongrad || degree_level || ' ' || degree_desc || ' ' || school_code ||
            ' ' || dept_desc || ' ' || class_section_desc)
          , '; '
        ) Within Group (Order By degree_year) As degrees_verbose
      -- Terse degrees
      , Listagg(
          trim(degree_year || ' ' || nongrd || degree_code || ' ' || school_code || ' ' || dept_short_desc ||
            -- Class section code
            ' ' || class_section)
          , '; '
        ) Within Group (Order By degree_year) As degrees_concat
      -- Class sections
      , Listagg(
          trim(Case When trim(class_section) Is Not Null Then dept_short_desc End || ' ' || class_section)
          , '; '
        ) Within Group (Order By degree_year) As class_section
      -- Majors
      , Listagg(
        trim(majors)  
        , '; '
      ) Within Group (Order By degree_year) As majors_concat
      -- First Kellogg grad date
      , min(grad_dt) keep(dense_rank First Order By non_grad_code Desc, degree_year Asc, grad_dt Asc)
        As first_ksm_grad_dt
      -- First Kellogg year: exclude non-grad years
      , min(trim(Case When non_grad_code = 'N' Then NULL Else degree_year End))
        As first_ksm_year
      -- First MBA or other Master's year: exclude non-grad years
      , min(Case
          When degree_level_code = 'M' -- Master's level
            Or degree_code In('MBA', 'MMGT', 'MS', 'MSDI', 'MSHA', 'MSMS') -- In case of data errors
            Then trim(Case When non_grad_code = 'N' Then NULL Else degree_year End)
          Else NULL
        End)
        As first_masters_year
      , max(Case
          When degree_level_code = 'M' -- Master's level
            Or degree_code In('MBA', 'MMGT', 'MS', 'MSDI', 'MSHA', 'MSMS') -- In case of data errors
            Then trim(Case When non_grad_code = 'N' Then NULL Else degree_year End)
          Else NULL
        End)
        As last_masters_year
      -- Last non-certificate year, e.g. for young alumni status, excluding non-grad years
      , max(Case
          When degree_level_code In('B', 'D', 'M')
          Then trim(Case When non_grad_code = 'N' Then NULL Else degree_year End)
          Else NULL
        End)
        As last_noncert_year
      From deg_data
      Group By id_number
    )
    -- Completed degrees only
    -- ***** IMPORTANT: If updating, update concat.degrees_concat above as well *****
    , clean_concat As (
      Select
        id_number
        -- Verbose degrees
      , Listagg(
          trim(degree_year || ' ' || nongrad || degree_level || ' ' || degree_desc || ' ' || school_code ||
            ' ' || dept_desc || ' ' || class_section_desc)
          , '; '
        ) Within Group (Order By degree_year) As clean_degrees_verbose
        -- Terse degrees
        , Listagg(
          trim(degree_year || ' ' || nongrd || degree_code || ' ' || school_code || ' ' || dept_short_desc ||
            -- Class section code
            ' ' || class_section)
          , '; '
        ) Within Group (Order By degree_year) As clean_degrees_concat
      From deg_data
      Where non_grad_code = ' ' Or non_grad_code Is Null
      Group By id_number
    )
    -- Extract program
    , prg As (
      Select
        concat.id_number
        , Case
            -- Account for certificate degree level/degree program mismatch by choosing exec ed
            When last_noncert_year Is Null And clean_degrees_concat Is Not Null Then
              Case
                When clean_degrees_concat Like '%KSM AEP%' Then 'CERT-AEP'
                When clean_degrees_concat Like '%KSMEE%' Then 'EXECED'
                When clean_degrees_concat Like '%CERT%' Then 'EXECED'
                When clean_degrees_concat Like '%Institute for Mgmt%' Then 'EXECED'
                When clean_degrees_concat Like '%LLM%' Then 'CERT-LLM'
                When clean_degrees_verbose Like '%Certificate%' Then 'CERT'
                Else 'EXECED'
              End
            -- People who have a completed degree
            -- ***** IMPORTANT: Keep in same order as below *****
            When clean_degrees_concat Like '%KGS2Y%' Then 'FT-2Y'
            When clean_degrees_concat Like '%KGS1Y%' Then 'FT-1Y'
            When clean_degrees_concat Like '%JDMBA%' Then 'FT-JDMBA'
            When clean_degrees_concat Like '%MMM%' Then 'FT-MMM'
            When clean_degrees_concat Like '%MDMBA%' Then 'FT-MDMBA'
            When clean_degrees_concat Like '%MBAI%' Then 'FT-MBAi'
            When clean_degrees_concat Like '%KSM KEN%' Then 'FT-KENNEDY'
            When clean_degrees_concat Like '%KSM TMP%' Then 'TMP'
            When clean_degrees_concat Like '%KSM PTS%' Then 'TMP-SAT'
            When clean_degrees_concat Like '%KSM PSA%' Then 'TMP-SATXCEL'
            When clean_degrees_concat Like '%KSM PTA%' Then 'TMP-XCEL'
            When clean_degrees_concat Like '%KSM NAP%' Then 'EMP-IL'
            When clean_degrees_concat Like '%KSM WHU%' Then 'EMP-GER'
            When clean_degrees_concat Like '%KSM SCH%' Then 'EMP-CAN'
            When clean_degrees_concat Like '%KSM LAP%' Then 'EMP-FL'
            When clean_degrees_concat Like '%KSM HK%' Then 'EMP-HK'
            When clean_degrees_concat Like '%KSM JNA%' Then 'EMP-JAN'
            When clean_degrees_concat Like '%KSM RU%' Then 'EMP-ISR'
            When clean_degrees_concat Like '%KSM PKU%' Then 'EMP-CHI'
            When clean_degrees_concat Like '% EMP%' Then 'EMP'
            When clean_degrees_concat Like '%KGS%' Then 'FT'
            When clean_degrees_concat Like '%BEV%' Then 'FT-EB'
            When clean_degrees_concat Like '%BCH%' Then 'FT-CB'
            When clean_degrees_concat Like '%PHD%' Then 'PHD'
            When clean_degrees_concat Like '%KSM AEP%' Then 'CERT-AEP'
            When clean_degrees_concat Like '%KSMEE%' Then 'EXECED'
            When clean_degrees_concat Like '%MBA %' Then 'FT'
            When clean_degrees_concat Like '%CERT%' Then 'EXECED'
            When clean_degrees_concat Like '%Institute for Mgmt%' Then 'EXECED'
            When clean_degrees_concat Like '%MS %' Then 'FT-MS'
            When clean_degrees_concat Like '%LLM%' Then 'CERT-LLM'
            When clean_degrees_concat Like '%MMGT%' Then 'FT-MMGT'
            When clean_degrees_verbose Like '%Certificate%' Then 'CERT'
            -- People who don't have a completed degree
            -- ***** IMPORTANT: Keep in same order as above *****
            When degrees_concat Like '%KGS2Y%' Then 'FT-2Y NONGRD'
            When degrees_concat Like '%KGS1Y%' Then 'FT-1Y NONGRD'
            When degrees_concat Like '%JDMBA%' Then 'FT-JDMBA NONGRD'
            When degrees_concat Like '%MMM%' Then 'FT-MMM NONGRD'
            When degrees_concat Like '%MDMBA%' Then 'FT-MDMBA NONGRD'
            When degrees_concat Like '%MBAI%' Then 'FT-MBAi NONGRD'
            When degrees_concat Like '%KSM KEN%' Then 'FT-KENNEDY NONGRD'
            When degrees_concat Like '%KSM TMP%' Then 'TMP NONGRD'
            When degrees_concat Like '%KSM PTS%' Then 'TMP-SAT NONGRD'
            When degrees_concat Like '%KSM PSA%' Then 'TMP-SATXCEL NONGRD'
            When degrees_concat Like '%KSM PTA%' Then 'TMP-XCEL NONGRD'
            When degrees_concat Like '% EMP%' Then 'EMP NONGRD'
            When degrees_concat Like '%KSM NAP%' Then 'EMP-IL NONGRD'
            When degrees_concat Like '%KSM WHU%' Then 'EMP-GER NONGRD'
            When degrees_concat Like '%KSM SCH%' Then 'EMP-CAN NONGRD'
            When degrees_concat Like '%KSM LAP%' Then 'EMP-FL NONGRD'
            When degrees_concat Like '%KSM HK%' Then 'EMP-HK NONGRD'
            When degrees_concat Like '%KSM JNA%' Then 'EMP-JAN NONGRD'
            When degrees_concat Like '%KSM RU%' Then 'EMP-ISR NONGRD'
            When degrees_concat Like '%KGS%' Then 'FT NONGRD'
            When degrees_concat Like '%BEV%' Then 'FT-EB NONGRD'
            When degrees_concat Like '%BCH%' Then 'FT-CB NONGRD'
            When degrees_concat Like '%PHD%' Then 'PHD NONGRD'
            When degrees_concat Like '%KSM AEP%' Then 'CERT-AEP NONGRD'
            When degrees_concat Like '%KSMEE%' Then 'EXECED NONGRD'
            When degrees_concat Like '%MBA %' Then 'FT NONGRD'
            When degrees_concat Like '%CERT%' Then 'EXECED NONGRD'
            When degrees_concat Like '%Institute for Mgmt%' Then 'EXECED NONGRD'
            When degrees_concat Like '%MS %' Then 'FT-MS NONGRD'
            When degrees_concat Like '%LLM%' Then 'CERT-LLM NONGRD'
            When degrees_concat Like '%MMGT%' Then 'FT-MMGT NONGRD'
            When degrees_verbose Like '%Certificate%' Then 'CERT NONGRD'
            Else 'UNK' -- Unable to determine program
          End As program
      From concat
      Left Join clean_concat On concat.id_number = clean_concat.id_number
    )
    -- Final results
    Select
      concat.id_number
      , entity.report_name
      , entity.record_status_code
      , degrees_verbose
      , degrees_concat
      , first_ksm_grad_dt
      , first_ksm_year
      , first_masters_year
      , last_masters_year
      , last_noncert_year
      , prg.program
      -- program_group and program_group_rank: make sure to keep entries in the same order
      , Case
          When program Like '%NONGRD%' Then 'NONGRD'
          When program Like 'FT%' Then  'FT'
          When program Like 'TMP%' Then 'TMP'
          When program Like 'EMP%' Then 'EMP'
          When program Like 'PHD%' Then 'PHD'
          When program Like 'EXEC%' Or program Like 'CERT%' Then 'EXECED'
          Else program
        End As program_group
      , Case
          When program Like '%NONGRD%' Then 100000
          When program Like 'FT%' Then 10
          When program Like 'TMP%' Then 20
          When program Like 'EMP%' Then 30
          When program Like 'PHD%' Then 40
          When program Like 'EXEC%' Or program Like 'CERT%' Then 100
          Else 9999999999
        End As program_group_rank
      , class_section
      , majors_concat
    From concat
    Inner Join entity On entity.id_number = concat.id_number
    Inner Join prg On concat.id_number = prg.id_number
    ;


/*************************************************************************
Pipelined functions
*************************************************************************/

-- Table function
Function tbl_entity_degrees_concat
  Return entity_degrees_concat Pipelined As
  -- Declarations
  deg entity_degrees_concat;
    
  Begin
    Open c_entity_degrees_concat;
      Fetch c_entity_degrees_concat Bulk Collect Into deg;
    Close c_entity_degrees_concat;
    -- Pipe out the rows
    For i in 1..(deg.count) Loop
      Pipe row(deg(i));
    End Loop;
    Return;
  End;

End ksm_pkg_degrees;
/
