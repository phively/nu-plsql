Create Or Replace Package ksm_pkg_degrees Is

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_degrees';
collect_default_limit Constant pls_integer := 50;

/*************************************************************************
Public type declarations
*************************************************************************/

Type degreed_alumni Is Record (
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

Type t_degreed_alumni Is Table Of degreed_alumni;

/*************************************************************************
Public functions declarations
*************************************************************************/

-- Quick SQL-only retrieval of KSM degrees concat
Function get_entity_degrees_concat_fast(
  id In varchar2
) Return varchar2;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

-- Table functions
Function tbl_entity_degrees_concat_ksm(
    limit_size In pls_integer Default collect_default_limit
  )
  Return t_degreed_alumni Pipelined;

/*************************************************************************
Public cursors -- data definitions
*************************************************************************/

-- Kellogg degrees concatenated
Cursor c_entity_degrees_concat_ksm Is
  With
  -- Stewardship concatenated years: uses Distinct to de-dupe multiple degrees in one year
  stwrd_yrs As (
    Select Distinct
      id_number
      , degree_year
      , trim('''' || substr(trim(degree_year), -2)) As degree_yr
    From degrees
    Where institution_code = '31173' -- Northwestern institution code
      And (
        degrees.school_code In ('KSM', 'BUS') -- Kellogg and College of Business school codes
        Or degrees.dept_code = '01MBI' -- MBAi
      )
      And degree_year <> ' ' -- Exclude rows with blank year
      And non_grad_code <> 'N' -- Exclude non-grads
  )
  , stwrd_deg As (
    Select Distinct
      id_number
      , Listagg(degree_yr, ', ') Within Group (Order By degree_year Asc) As stewardship_years
    From stwrd_yrs
    Where degree_year <> ''''
    Group By id_number
  )
  -- Concatenated degrees subqueries
  , deg_data As (
    Select
      degrees.id_number
      , grad_dt
      , degree_year
      , non_grad_code
      , Case When non_grad_code = 'N' Then 'Nongrad ' End As nongrad
      , Case When non_grad_code = 'N' Then 'NONGRD ' End As nongrd
      , degrees.degree_level_code
      , tms_degree_level.short_desc As degree_level
      , degrees.degree_code
      , tms_degrees.short_desc As degree_desc
      , degrees.school_code
      , degrees.dept_code
      , tms_dept_code.short_desc As dept_desc
      , degrees.division_code
      , tms_division.short_desc As division_desc
      , Case
          When degrees.dept_code = '01MDB' Then 'MDMBA'
          When degrees.dept_code Like '01%' Then substr(degrees.dept_code, 3)
          When degrees.dept_code = '13JDM' Then 'JDMBA'
          When degrees.dept_code = '13LLM' Then 'LLM'
          When degrees.dept_code Like '41%' Then substr(degrees.dept_code, 3)
          When degrees.dept_code = '95BCH' Then 'BCH'
          When degrees.dept_code = '96BEV' Then 'BEV'
          When degrees.dept_code In ('AMP', 'AMPI', 'EDP', 'KSMEE') Then degrees.dept_code
          When degrees.dept_code = '01MBI' Then 'MBAi'
          When degrees.dept_code = '0000000' Then ''
          Else tms_dept_code.short_desc
        End As dept_short_desc
      , class_section
      , tms_class_section.short_desc As class_section_desc
      -- Concatenated majors: separate by , within a single degree
      , trim(
          trim(
            m1.short_desc ||
            Case When m2.short_desc Is Not Null Then ', ' End ||
            m2.short_desc
          ) || Case When m3.short_desc Is Not Null Then ', ' End ||
          m3.short_desc
        ) As majors
    -- Table joins, etc.
    From degrees
    Left Join tms_class_section -- For class section short_desc
      On degrees.class_section = tms_class_section.section_code
    Left Join tms_dept_code -- For department short_desc
      On degrees.dept_code = tms_dept_code.dept_code
    Left Join tms_division -- For division short_desc
      On degrees.division_code = tms_division.division_code
    Left Join tms_degree_level -- For degree level short_desc
      On degrees.degree_level_code = tms_degree_level.degree_level_code
    Left Join tms_degrees -- For degreee short_desc (to replace degree_code)
      On degrees.degree_code = tms_degrees.degree_code
    -- Major codes
    Left Join tms_majors m1
      On m1.major_code = degrees.major_code1
    Left Join tms_majors m2
      On m2.major_code = degrees.major_code2
    Left Join tms_majors m3
      On m3.major_code = degrees.major_code3
    Where institution_code = '31173' -- Northwestern institution code
      And (
        degrees.school_code In ('KSM', 'BUS') -- Kellogg and College of Business school codes
        Or degrees.dept_code = '01MBI' -- MBAi
      )
  )
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
      , stwrd_deg.stewardship_years
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
    Left Join stwrd_deg On stwrd_deg.id_number = concat.id_number
    ;

End ksm_pkg_degrees;
/

Create Or Replace Package Body ksm_pkg_degrees Is

/*************************************************************************
Functions
*************************************************************************/

-- Row by row degree years concat
Function get_entity_degrees_concat_fast(id In varchar2)
  Return varchar2 Is
  -- Declarations
  deg_conc varchar2(1024);
  
  Begin
  
    Select
      -- Concatenated degrees string
      Listagg(
        trim(degree_year || ' ' || degree_code || ' ' || school_code || ' ' || 
          tms_dept_code.short_desc || ' ' || class_section), '; '
      ) Within Group (Order By degree_year) As degrees_concat
    Into deg_conc
    From degrees
      Left Join tms_dept_code On degrees.dept_code = tms_dept_code.dept_code
    Where institution_code = '31173'
      And school_code in('BUS', 'KSM')
      And id_number = id
    Group By id_number;
    
    Return deg_conc;
  End;

/*************************************************************************
Pipelined functions
*************************************************************************/

-- Table function
Function tbl_entity_degrees_concat_ksm(
    limit_size In pls_integer Default collect_default_limit
  )
  Return t_degreed_alumni Pipelined As
  -- Declarations
  degrees t_degreed_alumni;
    
  Begin
    If c_entity_degrees_concat_ksm %ISOPEN then
      Close c_entity_degrees_concat_ksm;
    End If;
    Open c_entity_degrees_concat_ksm;
    Loop
      Fetch c_entity_degrees_concat_ksm Bulk Collect Into degrees Limit limit_size;
      Exit When degrees.count = 0;
      For i in 1..(degrees.count) Loop
        Pipe row(degrees(i));
      End Loop;
    End Loop;
    Close c_entity_degrees_concat_ksm;
    Return;
  End;

End ksm_pkg_degrees;
/
