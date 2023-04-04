Create Or Replace Package ksm_pkg_households Is

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_households';
collect_default_limit Constant pls_integer := 100;

/*************************************************************************
Public type declarations
*************************************************************************/

Type household_fast Is Record (
  id_number entity.id_number%type
  , report_name entity.report_name%type
  , pref_mail_name entity.pref_mail_name%type
  , record_status_code entity.record_status_code%type
  , degrees_concat varchar2(512)
  , first_ksm_year degrees.degree_year%type
  , last_noncert_year degrees.degree_year%type
  , program varchar2(20)
  , program_group varchar2(20)
  , institutional_suffix entity.institutional_suffix%type
  , spouse_id_number entity.spouse_id_number%type
  , spouse_report_name entity.report_name%type
  , spouse_pref_mail_name entity.pref_mail_name%type
  , spouse_suffix entity.institutional_suffix%type
  , spouse_degrees_concat varchar2(512)
  , spouse_first_ksm_year degrees.degree_year%type
  , spouse_program varchar2(20)
  , spouse_program_group varchar2(20)
  , spouse_last_noncert_year degrees.degree_year%type
  , household_id entity.id_number%type
);

Type household Is Record (
  id_number entity.id_number%type
  , report_name entity.report_name%type
  , pref_mail_name entity.pref_mail_name%type
  , record_status_code entity.record_status_code%type
  , degrees_concat varchar2(512)
  , first_ksm_year degrees.degree_year%type
  , program varchar2(20)
  , program_group varchar2(20)
  , last_noncert_year degrees.degree_year%type
  , institutional_suffix entity.institutional_suffix%type
  , spouse_id_number entity.spouse_id_number%type
  , spouse_report_name entity.report_name%type
  , spouse_pref_mail_name entity.pref_mail_name%type
  , spouse_suffix entity.institutional_suffix%type
  , spouse_degrees_concat varchar2(512)
  , spouse_first_ksm_year degrees.degree_year%type
  , spouse_program varchar2(20)
  , spouse_program_group varchar2(20)
  , spouse_last_noncert_year degrees.degree_year%type
  , fmr_spouse_id entity.id_number%type
  , fmr_spouse_name entity.report_name%type
  , fmr_marital_status tms_marital_status.short_desc%type
  , household_id entity.id_number%type
  , household_primary varchar2(1)
  , household_record entity.record_type_code%type
  , person_or_org entity.person_or_org%type
  , household_name entity.pref_mail_name%type
  , household_rpt_name entity.report_name%type
  , household_spouse_id entity.id_number%type
  , household_spouse entity.pref_mail_name%type
  , household_spouse_rpt_name entity.report_name%type
  , household_list_first entity.id_number%type
  , household_list_second entity.id_number%type
  , household_suffix entity.institutional_suffix%type
  , household_spouse_suffix entity.institutional_suffix%type
  , household_ksm_year degrees.degree_year%type
  , household_masters_year degrees.degree_year%type
  , household_last_masters_year degrees.degree_year%type
  , household_program varchar2(20)
  , household_program_group varchar2(20)
  , xsequence address.xsequence%type
  , household_city address.city%type
  , household_state address.state_code%type
  , household_zip address.zipcode%type
  , household_geo_codes varchar2(512)
  , household_geo_primary geo_code.geo_code%type
  , household_geo_primary_desc geo_code.description%type
  , household_country tms_country.short_desc%type
  , household_continent varchar2(80)
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type t_household_fast Is Table Of household_fast;
Type t_household Is Table Of household;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

-- Table functions
Function tbl_households_fast(
    limit_size In pls_integer Default collect_default_limit
  )
    Return t_household_fast Pipelined;

Function tbl_entity_households_ksm(
    limit_size In pls_integer Default collect_default_limit
  )
  Return t_household Pipelined;

/*************************************************************************
Public cursors -- data definitions
*************************************************************************/

Cursor c_entity_households Is
With
  -- Entities and spouses, with Kellogg degrees concat fields
  degs As (
    Select deg.*
    From table(ksm_pkg_degrees.tbl_entity_degrees_concat_ksm) deg
  )
  , couples As (
    Select
      -- Entity fields
      entity.id_number
      , entity.pref_mail_name
      , entity.report_name
      , entity.record_type_code
      , entity.gender_code
      , entity.person_or_org
      , entity.record_status_code
      , entity.institutional_suffix
      , edc.degrees_concat
      , edc.first_ksm_year
      , edc.first_masters_year
      , edc.last_masters_year
      , edc.last_noncert_year
      , edc.program
      , edc.program_group
      , edc.program_group_rank
      -- Spouse fields
      , entity.spouse_id_number
      , spouse.pref_mail_name As spouse_pref_mail_name
      , spouse.report_name As spouse_report_name
      , spouse.gender_code As spouse_gender_code
      , spouse.institutional_suffix As spouse_suffix
      , sdc.degrees_concat As spouse_degrees_concat
      , sdc.first_ksm_year As spouse_first_ksm_year
      , sdc.first_masters_year As spouse_first_masters_year
      , sdc.last_masters_year As spouse_last_masters_year
      , sdc.last_noncert_year As spouse_last_noncert_year
      , sdc.program As spouse_program
      , sdc.program_group As spouse_program_group
      , sdc.program_group_rank As spouse_program_group_rank
    From entity
    Left Join degs edc On entity.id_number = edc.id_number
    Left Join degs sdc On entity.spouse_id_number = sdc.id_number
    Left Join entity spouse On entity.spouse_id_number = spouse.id_number
  )
  , household As (
    Select
      id_number
      , report_name
      , record_status_code
      , pref_mail_name
      , institutional_suffix
      , degrees_concat
      , first_ksm_year
      , last_noncert_year
      , program
      , program_group
      , spouse_id_number
      , spouse_report_name
      , spouse_pref_mail_name
      , spouse_suffix
      , spouse_degrees_concat
      , spouse_first_ksm_year
      , spouse_program
      , spouse_program_group
      , spouse_last_noncert_year
      -- Choose which spouse is primary based on program_group
      , Case
          When length(spouse_id_number) < 10 Or spouse_id_number Is Null Then id_number -- if no spouse, use id_number
          -- if same program (or both null), use lower id_number
          When program_group = spouse_program_group Or program_group Is Null And spouse_program_group Is Null Then
            Case When id_number < spouse_id_number Then id_number Else spouse_id_number End
          When spouse_program_group Is Null Then id_number -- if no spouse program, use id_number
          When program_group Is Null Then spouse_id_number -- if no self program, use spouse_id_number
          When program_group_rank < spouse_program_group_rank Then id_number
          When spouse_program_group_rank < program_group_rank Then spouse_id_number
        End As household_id
      -- Compute last master's degree year in household
      , Case
          When spouse_last_masters_year Is Null Then last_masters_year
          When last_masters_year Is Null Then spouse_last_masters_year
          When last_masters_year >= spouse_last_masters_year Then last_masters_year
          When spouse_last_masters_year >= last_masters_year Then spouse_last_masters_year
        End As household_last_masters_year
    From couples
  )
  -- Address info
/*  , geo As (
    Select *
    From table(ksm_pkg_tmp.tbl_geo_code_primary)
    Where addr_pref_ind = 'Y'
  )
*/  -- Individual preferred addresses
  , pref_addr As (
    Select
      addr.id_number
      , addr.xsequence
      , addr.city As pref_city
      , addr.state_code As pref_state
      , addr.zipcode
      , NULL as geo_codes -- geo.geo_codes
      , NULL as geo_code_primary -- geo.geo_code_primary
      , NULL as geo_code_primary_desc -- geo.geo_code_primary_desc
      , cont.country As pref_country
      , cont.continent As pref_continent
    From address addr
    Left Join v_addr_continents cont On addr.country_code = cont.country_code
--    Left Join geo On geo.id_number = addr.id_number
    Where addr.addr_pref_ind = 'Y'
      And addr.addr_status_code = 'A'
  )
  -- Deceased spouse logic
  , deceased_spouses As (
    Select Distinct
      id_number
      , spouse_id_number
      , marital_status_chg_dt
      , xsequence
      , tms.short_desc As marital_status
    From former_spouse
    Inner Join tms_marital_status tms On tms.marital_status_code = former_spouse.marital_status_code
    Where
      -- Marriage ended by death, married at time of death, widowed, widowed at time of death, former spouse
      -- If updated, also change below in fmr_spouse query
      tms.marital_status_code In ('I', 'Q', 'Z', 'W', 'N', 'F', ' ')
  )
  -- Deduping
  , deceased_spouse As (
    Select
      ds.id_number
      -- If multiple keep only most recent (determined by change date, then xsequence) deceased spouse
      , min(spouse_id_number) keep(dense_rank First Order By marital_status_chg_dt Desc, xsequence Desc) As spouse_id_number
    From deceased_spouses ds
    Group By ds.id_number
  )
  , fmr_spouse As (
    Select
      entity.id_number
      , entity.report_name
      , tms.short_desc As record_status
      , tms_ms.short_desc As marital_status
      , ds.spouse_id_number
      , spouse.report_name As spouse_name
      , tmsd.short_desc As spouse_record_status
      , tms_sms.short_desc As spouse_marital_status
    From entity
    Inner Join tms_record_status tms On tms.record_status_code = entity.record_status_code
    Left Join deceased_spouse ds On ds.id_number = entity.id_number
    Left Join tms_marital_status tms_ms On tms_ms.marital_status_code = entity.marital_status_code
    Left Join entity spouse On spouse.id_number = ds.spouse_id_number
    Inner Join tms_record_status tmsd On tmsd.record_status_code = spouse.record_status_code
    Left Join tms_marital_status tms_sms On tms_sms.marital_status_code = spouse.marital_status_code
    Inner Join (Select id_number From deceased_spouse Union Select spouse_id_number From deceased_spouse) ds
      On ds.id_number = entity.id_number
    -- If updated, also change above in deceased_spouses query
    Where entity.marital_status_code In ('I', 'Q', 'Z', 'W', 'N', 'F', ' ')
      And spouse.marital_status_code In ('I', 'Q', 'Z', 'W', 'N', 'F', ' ')
  )
  -- Spouse order for mailing lists, etc.
  , mailing_order As (
    Select Distinct
      household.household_id
      , Case
          -- Check whether household spouse ID exists
          When trim(household.spouse_id_number) Is Not Null
            Then Case
              -- Check whether male is alum and female is nonalum
              When couples.gender_code = 'M'
                And couples.first_ksm_year Is Not Null
                And couples.spouse_gender_code = 'F'
                And couples.spouse_first_ksm_year Is Null
                  Then household_id
              When couples.gender_code = 'F'
                And couples.first_ksm_year Is Null
                And couples.spouse_gender_code = 'M'
                And couples.spouse_first_ksm_year Is Not Null
                  Then couples.spouse_id_number
              -- Check whether one record is male and one female
              When couples.gender_code = 'M'
                And couples.spouse_gender_code = 'F'
                  Then couples.spouse_id_number
              When couples.gender_code = 'F'
                And couples.spouse_gender_code = 'M'
                  Then household_id
              -- Check whether one record is alum and one nonalum
              When couples.first_ksm_year Is Not Null
                And couples.spouse_first_ksm_year Is Null
                  Then household_id
              When couples.first_ksm_year Is Null
                And couples.spouse_first_ksm_year Is Not Null
                  Then couples.spouse_id_number
              -- Alpha order as a fallback
              When lower(couples.report_name) <= lower(couples.spouse_report_name)
                Then household_id
              When lower(couples.report_name) > lower(couples.spouse_report_name)
                Then couples.spouse_id_number
              Else '#ERROR'
            End
          -- When no household spouse ID use household ID
          Else household_id
          End
        As household_list_first
    From household
    Inner Join couples On household.household_id = couples.id_number
  )
  -- Main query
  Select
    household.id_number
    , household.report_name
    , household.pref_mail_name
    , household.record_status_code
    , household.degrees_concat
    , household.first_ksm_year
    , household.program
    , household.program_group
    , household.last_noncert_year
    , household.institutional_suffix
    , household.spouse_id_number
    , household.spouse_report_name
    , household.spouse_pref_mail_name
    , household.spouse_suffix
    , household.spouse_degrees_concat
    , household.spouse_first_ksm_year
    , household.spouse_program
    , household.spouse_program_group
    , household.spouse_last_noncert_year
    , fmr_spouse.spouse_id_number As fmr_spouse_id
    , fmr_spouse.spouse_name As fmr_spouse_name
    , fmr_spouse.marital_status As fmr_marital_status
    , household.household_id
    , Case When household.household_id = household.id_number Then 'Y' End
      As household_primary
    , couples.record_type_code As household_record
    , couples.person_or_org
    , couples.pref_mail_name As household_name
    , couples.report_name As household_rpt_name
    , couples.spouse_id_number As household_spouse_id
    , couples.spouse_pref_mail_name As household_spouse
    , couples.spouse_report_name As household_spouse_rpt_name
    , mailing_order.household_list_first
    , Case
        When mailing_order.household_list_first <> household.household_id
          Then household.household_id
        Else trim(couples.spouse_id_number)
        End
      As household_list_second
    , couples.institutional_suffix As household_suffix
    , couples.spouse_suffix As household_spouse_suffix
    , couples.first_ksm_year As household_ksm_year
    , couples.first_masters_year As household_masters_year
    -- Household last non-certificate year, for (approximate) young alumni designation
    , household.household_last_masters_year
    , couples.program As household_program
    , couples.program_group As household_program_group
    -- HH preferred address logic
    , Case When pa_prim.xsequence Is Not Null Then pa_prim.xsequence Else pa_sp.xsequence End
      As xsequence
    , Case When pa_prim.xsequence Is Not Null Then pa_prim.pref_city Else pa_sp.pref_city End
      As pref_city
    , Case When pa_prim.xsequence Is Not Null Then pa_prim.pref_state Else pa_sp.pref_state End
      As pref_state
    , Case When pa_prim.xsequence Is Not Null Then pa_prim.zipcode Else pa_sp.zipcode End
      As zipcode
    , Case When pa_prim.xsequence Is Not Null Then pa_prim.geo_codes Else pa_sp.geo_codes End
      As geo_codes
    , Case When pa_prim.xsequence Is Not Null Then pa_prim.geo_code_primary Else pa_sp.geo_code_primary End
      As geo_code_primary
    , Case When pa_prim.xsequence Is Not Null Then pa_prim.geo_code_primary_desc Else pa_sp.geo_code_primary_desc End
      As geo_code_primary_desc
    , Case When pa_prim.xsequence Is Not Null Then pa_prim.pref_country Else pa_sp.pref_country End
      As pref_country
    , Case When pa_prim.xsequence Is Not Null Then pa_prim.pref_continent Else pa_sp.pref_continent End
      As pref_continent
  From household
  Inner Join couples On household.household_id = couples.id_number
  Left Join mailing_order On household.household_id = mailing_order.household_id
  Left Join pref_addr pa_prim On household.household_id = pa_prim.id_number
  Left Join pref_addr pa_sp On couples.spouse_id_number = pa_sp.id_number
  Left Join fmr_spouse On household.id_number = fmr_spouse.id_number
;

End ksm_pkg_households;
/
Create Or Replace Package Body ksm_pkg_households Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

-- Kellogg householding definition
Cursor households_fast Is
With
  -- Entities and spouses, with Kellogg degrees concat fields
  degs As (
    Select deg.*
    From table(ksm_pkg_degrees.tbl_entity_degrees_concat_ksm) deg
  )
  , couples As (
    Select
      -- Entity fields
      entity.id_number
      , entity.pref_mail_name
      , entity.report_name
      , entity.record_type_code
      , entity.gender_code
      , entity.person_or_org
      , entity.record_status_code
      , entity.institutional_suffix
      , edc.degrees_concat
      , edc.first_ksm_year
      , edc.first_masters_year
      , edc.last_masters_year
      , edc.last_noncert_year
      , edc.program
      , edc.program_group
      , edc.program_group_rank
      -- Spouse fields
      , entity.spouse_id_number
      , spouse.pref_mail_name As spouse_pref_mail_name
      , spouse.report_name As spouse_report_name
      , spouse.gender_code As spouse_gender_code
      , spouse.institutional_suffix As spouse_suffix
      , sdc.degrees_concat As spouse_degrees_concat
      , sdc.first_ksm_year As spouse_first_ksm_year
      , sdc.first_masters_year As spouse_first_masters_year
      , sdc.last_masters_year As spouse_last_masters_year
      , sdc.last_noncert_year As spouse_last_noncert_year
      , sdc.program As spouse_program
      , sdc.program_group As spouse_program_group
      , sdc.program_group_rank As spouse_program_group_rank
    From entity
    Left Join degs edc On entity.id_number = edc.id_number
    Left Join degs sdc On entity.spouse_id_number = sdc.id_number
    Left Join entity spouse On entity.spouse_id_number = spouse.id_number
  )
  Select
    id_number
    , report_name
    , pref_mail_name
    , record_status_code
    , degrees_concat
    , first_ksm_year
    , last_noncert_year
    , program
    , program_group
    , institutional_suffix
    , spouse_id_number
    , spouse_report_name
    , spouse_pref_mail_name
    , spouse_suffix
    , spouse_degrees_concat
    , spouse_first_ksm_year
    , spouse_program
    , spouse_program_group
    , spouse_last_noncert_year
    -- Choose which spouse is primary based on program_group
    , Case
        When length(spouse_id_number) < 10 Or spouse_id_number Is Null Then id_number -- if no spouse, use id_number
        -- if same program (or both null), use lower id_number
        When program_group = spouse_program_group Or program_group Is Null And spouse_program_group Is Null Then
        Case When id_number < spouse_id_number Then id_number Else spouse_id_number End
        When spouse_program_group Is Null Then id_number -- if no spouse program, use id_number
        When program_group Is Null Then spouse_id_number -- if no self program, use spouse_id_number
        When program_group_rank < spouse_program_group_rank Then id_number
        When spouse_program_group_rank < program_group_rank Then spouse_id_number
    End As household_id
  From couples
;

/*************************************************************************
Pipelined functions
*************************************************************************/

-- Returns a pipelined table
Function tbl_households_fast(
    limit_size In pls_integer Default collect_default_limit
  )
    Return t_household_fast Pipelined As
    -- Declarations
    households t_household_fast;

  Begin
    If households_fast %ISOPEN then
      Close households_fast;
    End If;
    Open households_fast;
    Loop
      Fetch households_fast Bulk Collect Into households Limit limit_size;
      Exit When households.count = 0;
      For i in 1..(households.count) Loop
        Pipe row(households(i));
      End Loop;
    End Loop;
    Close households_fast;
    Return;
  End;

Function tbl_entity_households_ksm(
    limit_size In pls_integer Default collect_default_limit
  )
  Return t_household Pipelined As
  -- Declarations
  households t_household;

  Begin
    If c_entity_households %ISOPEN then
      Close c_entity_households;
    End If;
    Open c_entity_households;
    Loop
      Fetch c_entity_households Bulk Collect Into households Limit limit_size;
      Exit When households.count = 0;
      For i in 1..(households.count) Loop
        Pipe row(households(i));
      End Loop;
    End Loop;
    Close c_entity_households;
    Return;
  End;

End ksm_pkg_households;
/
