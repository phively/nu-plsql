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

Type rec_entity_ksm_degrees Is Record (
  donor_id dm_alumni.dim_constituent.constituent_donor_id%type
  , full_name dm_alumni.dim_constituent.full_name%type
  , sort_name dm_alumni.dim_constituent.full_name%type
  , degrees_verbose varchar2(1500)
  , degrees_concat varchar2(1500)
  , first_ksm_grad_date stg_alumni.ucinn_ascendv2__degree_information__c.ucinn_ascendv2__degree_date__c%type
  , first_ksm_year stg_alumni.ucinn_ascendv2__degree_information__c.ucinn_ascendv2__conferred_degree_year__c%type
  , first_masters_year stg_alumni.ucinn_ascendv2__degree_information__c.ucinn_ascendv2__conferred_degree_year__c%type
  , last_masters_year stg_alumni.ucinn_ascendv2__degree_information__c.ucinn_ascendv2__conferred_degree_year__c%type
  , last_noncert_year stg_alumni.ucinn_ascendv2__degree_information__c.ucinn_ascendv2__conferred_degree_year__c%type
  , program varchar2(60)
  , program_group varchar2(60)
  , program_group_rank number
  , class_section varchar2(500)
  , majors_concat varchar2(1500)
  , etl_update_date dm_alumni.dim_constituent.etl_update_date%type
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type entity_ksm_degrees Is Table Of rec_entity_ksm_degrees;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

Function tbl_entity_ksm_degrees
  Return entity_ksm_degrees Pipelined;

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
      , Case
          When deg.degree_status = 'Inactive'
            Then 'NONGRAD '
          When deg.degree_code Like '%-STU'
            Then 'STUDENT '
          End
        As nongrad
      , deg.degree_level
      , deg.degree_code
      , deg.degree_name
      , Case 
          When deg.degree_school_name Like '%J%L%Kellogg%'
            Then 'Kellogg'
          Else deg.degree_school_name
          End
        As degree_school_name
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
       , deg.etl_update_date
    From table(dw_pkg_base.tbl_degrees) deg
    Where deg.nu_indicator = 'Y' -- Northwestern University
      And (
        deg.degree_school_name Like ('%Kellogg%')
        Or deg.degree_school_name Like ('%Undergraduate Business%')
        Or deg.degree_code = 'MBAI' -- MBAI
        Or deg.degree_program_code In (Select id From acaorg)
      )
  )
  -- Listagg all degrees, including incomplete
  , concat As (
    Select
      constituent_donor_id
      , constituent_name
      -- Verbose degrees
      -- ***** IMPORTANT: If updating, make sure normal and clean definitions match *****
      , Listagg(
          trim(degree_year || ' ' || nongrad || degree_level || ' ' || degree_name || ' ' || degree_school_name ||
            ' ' || department_desc_full || ' ' || degree_program)
          , '; '
        ) Within Group (Order By degree_year)
        As degrees_verbose
      , Listagg(
          Case When nongrad Is NULL Then (
            trim(degree_year || ' ' || nongrad || degree_level || ' ' || degree_name || ' ' || degree_school_name ||
              ' ' || department_desc_full || ' ' || degree_program)
          ) End
          , '; '
        ) Within Group (Order By degree_year)
        As clean_degrees_verbose
      -- Terse degrees
      -- ***** IMPORTANT: If updating, make sure normal and clean definitions match *****
      , Listagg(
          trim(degree_year || ' ' || nongrad || degree_code || ' ' || degree_school_name || ' ' || department_desc_short ||
            ' ' || degree_program_code)
          , '; '
        ) Within Group (Order By degree_year)
        As degrees_concat
      , Listagg(
          Case When nongrad Is NULL Then (
            trim(degree_year || ' ' || nongrad || degree_code || ' ' || degree_school_name || ' ' || department_desc_short ||
              ' ' || degree_program_code)
          ) End
          , '; '
        ) Within Group (Order By degree_year)
        As clean_degrees_concat
      -- Class sections
      , Listagg(
          trim(Case When trim(degree_program) Is Not Null Then department_desc_short End || ' ' || degree_program)
          , '; '
        ) Within Group (Order By degree_year)
        As class_section
      -- Majors
      , Listagg(
          majors
          , '; '
        ) Within Group (Order By degree_year)
        As majors_concat
      -- First Kellogg grad date
      , min(degree_grad_date) keep(dense_rank First Order By nongrad Desc, degree_year Asc, degree_grad_date Asc)
        As first_ksm_grad_date
      -- First Kellogg year: exclude non-grad years
      , min(trim(Case When nongrad Is Not NULL Then NULL Else degree_year End))
        As first_ksm_year
      -- First MBA or other Master's year: exclude non-grad years
      , min(
          Case
            When degree_level = 'Masters Degree'
              Or degree_code In('MBA', 'MMGT', 'MS', 'MSDI', 'MSHA', 'MSMS', 'MMM', 'MBAI') -- In case of data errors
              Then trim(Case When nongrad Is Not NULL Then NULL Else degree_year End)
            Else NULL
          End
        ) As first_masters_year
      , max(
          Case
            When degree_level = 'Masters Degree'
              Or degree_code In('MBA', 'MMGT', 'MS', 'MSDI', 'MSHA', 'MSMS', 'MMM', 'MBAI') -- In case of data errors
              Then trim(Case When nongrad Is Not NULL Then NULL Else degree_year End)
            Else NULL
          End
        ) As last_masters_year
      -- Last non-certificate year, e.g. for young alumni status, excluding non-grad years
      , max(Case
          When degree_level In('Masters Degree', 'Doctorate Degree', 'Undergraduate Degree')
          Then trim(Case When nongrad Is Not NULL Then NULL Else degree_year End)
          Else NULL
        End)
        As last_noncert_year
      , min(etl_update_date)
        As etl_update_date
      From deg_data
      Group By
        constituent_donor_id
        , constituent_name
    )
    -- Extract program
    , prg As (
      Select
        concat.constituent_donor_id
        , Case
            -- Account for certificate degree level/degree program mismatch by choosing exec ed
            When last_noncert_year Is Null
              And clean_degrees_concat Is Not Null
              And clean_degrees_concat Not Like '%Undergraduate Business%'
              Then
                Case
                  When clean_degrees_concat Like '%Kellogg AEP%' Then 'CERT-AEP'
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
            When clean_degrees_concat Like '%Kellogg KEN%' Then 'FT-KENNEDY'
            When clean_degrees_concat Like '%Kellogg TMP%' Then 'TMP'
            When clean_degrees_concat Like '%Kellogg PTS%' Then 'TMP-SAT'
            When clean_degrees_concat Like '%Kellogg PSA%' Then 'TMP-SATXCEL'
            When clean_degrees_concat Like '%Kellogg PTA%' Then 'TMP-XCEL'
            When clean_degrees_concat Like '%Kellogg NAP%' Then 'EMP-IL'
            When clean_degrees_concat Like '%Kellogg WHU%' Then 'EMP-GER'
            When clean_degrees_concat Like '%Kellogg SCH%' Then 'EMP-CAN'
            When clean_degrees_concat Like '%Kellogg LAP%' Then 'EMP-FL'
            When clean_degrees_concat Like '%Kellogg HK%' Then 'EMP-HK'
            When clean_degrees_concat Like '%Kellogg JNA%' Then 'EMP-JAN'
            When clean_degrees_concat Like '%Kellogg RU%' Then 'EMP-ISR'
            When clean_degrees_concat Like '%Kellogg PKU%' Then 'EMP-CHI'
            When clean_degrees_concat Like '% EMP%' Then 'EMP'
            When clean_degrees_concat Like '%KGS%' Then 'FT'
            When clean_degrees_concat Like '%BEV%' Then 'FT-EB'
            When clean_degrees_concat Like '%BCH%' Then 'FT-CB'
            When clean_degrees_concat Like '%PHD%' Then 'PHD'
            When clean_degrees_concat Like '%Kellogg AEP%' Then 'CERT-AEP'
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
            When degrees_concat Like '%KGS2Y%' Then 'FT-2Y NONGRAD'
            When degrees_concat Like '%KGS1Y%' Then 'FT-1Y NONGRAD'
            When degrees_concat Like '%JDMBA%' Then 'FT-JDMBA NONGRAD'
            When degrees_concat Like '%MMM%' Then 'FT-MMM NONGRAD'
            When degrees_concat Like '%MDMBA%' Then 'FT-MDMBA NONGRAD'
            When degrees_concat Like '%MBAI%' Then 'FT-MBAi NONGRAD'
            When degrees_concat Like '%Kellogg KEN%' Then 'FT-KENNEDY NONGRAD'
            When degrees_concat Like '%Kellogg TMP%' Then 'TMP NONGRAD'
            When degrees_concat Like '%Kellogg PTS%' Then 'TMP-SAT NONGRAD'
            When degrees_concat Like '%Kellogg PSA%' Then 'TMP-SATXCEL NONGRAD'
            When degrees_concat Like '%Kellogg PTA%' Then 'TMP-XCEL NONGRAD'
            When degrees_concat Like '% EMP%' Then 'EMP NONGRAD'
            When degrees_concat Like '%Kellogg NAP%' Then 'EMP-IL NONGRAD'
            When degrees_concat Like '%Kellogg WHU%' Then 'EMP-GER NONGRAD'
            When degrees_concat Like '%Kellogg SCH%' Then 'EMP-CAN NONGRAD'
            When degrees_concat Like '%Kellogg LAP%' Then 'EMP-FL NONGRAD'
            When degrees_concat Like '%Kellogg HK%' Then 'EMP-HK NONGRAD'
            When degrees_concat Like '%Kellogg JNA%' Then 'EMP-JAN NONGRAD'
            When degrees_concat Like '%Kellogg RU%' Then 'EMP-ISR NONGRAD'
            When degrees_concat Like '%KGS%' Then 'FT NONGRAD'
            When degrees_concat Like '%BEV%' Then 'FT-EB NONGRAD'
            When degrees_concat Like '%BCH%' Then 'FT-CB NONGRAD'
            When degrees_concat Like '%PHD%' Then 'PHD NONGRAD'
            When degrees_concat Like '%Kellogg AEP%' Then 'CERT-AEP NONGRAD'
            When degrees_concat Like '%KSMEE%' Then 'EXECED NONGRAD'
            When degrees_concat Like '%MBA %' Then 'FT NONGRAD'
            When degrees_concat Like '%CERT%' Then 'EXECED NONGRAD'
            When degrees_concat Like '%Institute for Mgmt%' Then 'EXECED NONGRAD'
            When degrees_concat Like '%MS %' Then 'FT-MS NONGRAD'
            When degrees_concat Like '%LLM%' Then 'CERT-LLM NONGRAD'
            When degrees_concat Like '%MMGT%' Then 'FT-MMGT NONGRAD'
            When degrees_verbose Like '%Certificate%' Then 'CERT NONGRAD'
            -- Students
            When degrees_concat Like 'STUDENT%' Then 'STUDENT'
            -- Unable to determine program
            Else 'UNK'
          End As program
      From concat
    )
    -- Final results
    Select
        concat.constituent_donor_id
        As donor_id
      , constituent.full_name
      , constituent.sort_name
      , degrees_verbose
      , degrees_concat
      , first_ksm_grad_date
      , first_ksm_year
      , first_masters_year
      , last_masters_year
      , last_noncert_year
      , prg.program
      -- program_group and program_group_rank: make sure to keep entries in the same order
      , Case
          When program Like '%NONGRAD%' Then 'NONGRAD'
          When program Like 'FT%' Then  'FT'
          When program Like 'TMP%' Then 'TMP'
          When program Like 'EMP%' Then 'EMP'
          When program Like 'PHD%' Then 'PHD'
          When program Like 'EXEC%' Or program Like 'CERT%' Then 'EXECED'
          When program Like '%STUDENT%' Then 'STUDENT'
          Else program
        End As program_group
      , Case
          When program Like '%NONGRAD%' Then 100000
          When program Like 'FT%' Then 10
          When program Like 'TMP%' Then 20
          When program Like 'EMP%' Then 30
          When program Like 'PHD%' Then 40
          When program Like 'EXEC%' Or program Like 'CERT%' Then 100
          When program Like '%STUDENT%' Then 1000
          Else 9999999999
        End As program_group_rank
      , class_section
      , majors_concat
      , Case
          When concat.etl_update_date < constituent.etl_update_date
            Then concat.etl_update_date
            Else constituent.etl_update_date
          End
        As etl_update_date
    From concat
    Inner Join table(dw_pkg_base.tbl_constituent) constituent
      On concat.constituent_donor_id = constituent.donor_id
    Inner Join prg
      On concat.constituent_donor_id = prg.constituent_donor_id
    ;

/*************************************************************************
Pipelined functions
*************************************************************************/

Function tbl_entity_ksm_degrees
  Return entity_ksm_degrees Pipelined As
  -- Declarations
  deg entity_ksm_degrees;
    
  Begin
    Open c_entity_degrees_concat;
      Fetch c_entity_degrees_concat Bulk Collect Into deg;
    Close c_entity_degrees_concat;
    For i in 1..(deg.count) Loop
      Pipe row(deg(i));
    End Loop;
    Return;
  End;

End ksm_pkg_degrees;
/
