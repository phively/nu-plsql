Create Or Replace Package ksm_pkg_special_handling Is

/*************************************************************************
Author  : PBH634
Created : 5-27-2025
Purpose : Combined service indicators, committees, and other special handling
  indicators for mailing and other contact lists
Dependencies: dw_pkg_base, ksm_pkg_entity (mv_entity),
  ksm_pkg_special_handling (mv_special_handling)

Suggested naming conventions:
  Pure functions: [function type]_[description]
  Row-by-row retrieval (slow): get_[object type]_[action or description] e.g.
  Table or cursor retrieval (fast): tbl_[object type]_[action or description]
*************************************************************************/

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_special_handling';

/*************************************************************************
Public type declarations
*************************************************************************/

Type rec_special_handling Is Record (
    household_id mv_entity.household_id%type
    , donor_id mv_entity.donor_id%type
    , spouse_donor_id mv_entity.spouse_donor_id%type
    , service_indicators_concat varchar2(1600)
    , service_indicators_codes varchar2(400)
    , is_deceased_indicator mv_entity.is_deceased_indicator%type
    , gab varchar2(16)
    , trustee varchar2(16)
    , ebfa varchar2(16)
    , no_contact varchar2(1)
    , no_solicit varchar2(1)
    , no_release varchar2(1)
    , active_with_restrictions varchar2(1)
    , never_engaged_forever varchar2(1)
    , never_engaged_reunion varchar2(1)
    , anonymous_donor varchar2(1)
    , no_af_sol_ind varchar2(1)
    , no_phone_ind varchar2(1)
    , no_phone_sol_ind varchar2(1)
    , no_email_ind varchar2(1)
    , no_email_sol_ind varchar2(1)
    , no_mail_ind varchar2(1)
    , no_mail_sol_ind varchar2(1)
    , no_texts_ind varchar2(1)
    , no_texts_sol_ind varchar2(1)
    --, ksm_stewardship_issue varchar2(1)
    , etl_update_date mv_entity.etl_update_date%type
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type special_handling Is Table Of rec_special_handling;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

-- Return pipelined special handling preferences
Function tbl_special_handling
    Return special_handling Pipelined;

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

End ksm_pkg_special_handling;
/
Create Or Replace Package Body ksm_pkg_special_handling Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

Cursor c_special_handling Is


  With
  -- Special handling entities
  svc_ind As (
    Select
      mve.donor_id
      , mve.spouse_donor_id
      , Listagg(
          si.service_indicator ||  
            Case
              When lower(si.business_unit) = 'university'
                Then ''
              When lower(si.business_unit) Like '%kellogg%'
                Then ' (KSM)'
              Else ' (' || si.business_unit || ')'
              End
          , '; '
        )
        As service_indicators_concat
      , Listagg(
          si.service_indicator_code ||
            Case
                When lower(si.business_unit) = 'university'
                  Then ''
                When lower(si.business_unit) Like '%kellogg%'
                  Then ' (KSM)'
                Else ' (' || si.business_unit || ')'
                End
            , '; '
        )
        As service_indicators_codes
      -- No contact
      , max(Case When si.service_indicator_code = 'NC' Then 'Y' End)
        As no_contact
      -- No solicit
      , max(Case When si.service_indicator_code = 'NS' Then 'Y' End)
        As no_solicit
      -- No release
      , max(Case When si.service_indicator_code = 'DNR' Then 'Y' End)
        As no_release
      -- Active with restrictions
      , max(Case When si.service_indicator_code Like 'AWR%' Then 'Y' End)
        As active_with_restrictions
      -- Never engaged forever
      , max(Case When si.service_indicator_code = 'NEF' Then 'Y' End)
        As never_engaged_forever
      -- Never engaged reunion
      , max(Case When si.service_indicator_code = 'NER' Then 'Y' End)
        As never_engaged_reunion
      -- No phone
      , max(Case When si.service_indicator_code = 'NP' Then 'Y' End)
        As no_phone
      -- No phone solicitation
      , max(Case When si.service_indicator_code = 'NPS' Then 'Y' End)
        As no_phone_solicit
      -- No email
      , max(Case When si.service_indicator_code = 'NE' Then 'Y' End)
        As no_email
      -- No email solicitation
      , max(Case When si.service_indicator_code = 'NES' Then 'Y' End)
        As no_email_solicit
      -- No postal mail
      , max(Case When si.service_indicator_code = 'NM' Then 'Y' End)
        As no_mail
      -- No postal solicitation
      , max(Case When si.service_indicator_code = 'NMS' Then 'Y' End)
        As no_mail_solicit
      -- No texts
      , max(Case When si.service_indicator_code = 'NT' Then 'Y' End)
        As no_texts
      -- No text solicitation
      , max(Case When si.service_indicator_code = 'NTS' Then 'Y' End)
        As no_texts_solicit
      -- Anonymous donor
      , max(Case When si.service_indicator_code = 'ANON' Then 'Y' End)
        As anonymous_donor
      , max(si.etl_update_date)
        As etl_update_date
    From table(dw_pkg_base.tbl_service_indicators) si
    Inner Join mv_entity mve
      On mve.salesforce_id = si.constituent_salesforce_id
    -- Active handling only
    Where si.active_ind = 'Y'
      And (
        -- University or KSM
        lower(si.business_unit) = 'university'
        Or lower(si.business_unit) Like '%kellogg%'
      )
    Group By
      mve.donor_id
      , mve.spouse_donor_id
  )
  
  -- Alerts ("Knowtify" TBD)
/*  , all_alerts As (
    Select
      id_number
      , start_date
      , stop_date
      , message
      -- Kellogg Stewardship Issue indicator
      , Case
          When lower(message) Like '%ksm%stewardship%issue%'
            Or lower(message) Like '%kellogg%stewardship%issue%'
            Then 'Y'
          End
        As ksm_stewardship_issue
    From zz_alert_message
  )
  , alerts As (
    Select
      all_alerts.id_number
      , e.spouse_id_number
      , start_date
      , stop_date
      , message As alert_message
      , ksm_stewardship_issue
    From all_alerts
    Inner Join entity e
      On e.id_number = all_alerts.id_number
    Where
      ksm_stewardship_issue = 'Y'
      -- Or other indicators, if ever added
  ) */

  -- Committees  
  , gab As (
    Select
      c.constituent_donor_id
        As donor_id
      , e.spouse_donor_id
      , 'Y' As flag
    From v_committee_gab c
    Inner Join mv_entity e
      On e.donor_id = c.constituent_donor_id
  )
  , trustee As (
    Select
      c.constituent_donor_id
        As donor_id
      , e.spouse_donor_id
      , 'Y' As flag
    From v_committee_trustee c
    Inner Join mv_entity e
      On e.donor_id = c.constituent_donor_id
  )
  , ebfa As (
    Select
      c.constituent_donor_id
        As donor_id
      , e.spouse_donor_id
      , 'Y' As flag
    From v_committee_asia c
    Inner Join mv_entity e
      On e.donor_id = c.constituent_donor_id
  )
  , committees_merged As (
    Select donor_id, spouse_donor_id
    From gab
    Union
    Select donor_id, spouse_donor_id
    From trustee
    Union
    Select donor_id, spouse_donor_id
    From ebfa
  )
  
  -- All IDs
  , ids As (
    Select donor_id, spouse_donor_id
    From svc_ind
    /*Union
    Select id_number, spouse_id_number
    From alerts*/
    Union
    Select donor_id, spouse_donor_id
    From committees_merged
    Union
    Select spouse_donor_id, donor_id
    From committees_merged
  )
  
  -- Universal no contact or no solicit
  -- Anyone with one of a few select codes should NEVER be contacted or solicited
  , unc_ids As (
    Select
      svc_ind.donor_id
      , svc_ind.spouse_donor_id
      , Case
          When no_contact = 'Y'
            Or active_with_restrictions = 'Y'
            Then 'Y'
          End
        As univ_no_contact
      , Case
          When no_contact = 'Y'
            Or active_with_restrictions = 'Y'
            Or no_solicit = 'Y'
            Then 'Y'
          End
        As univ_no_solicit
    From svc_ind
  )
  
  -- Main query
  Select
    mve.household_id
    , ids.donor_id
    , ids.spouse_donor_id
    , svc_ind.service_indicators_concat
    , svc_ind.service_indicators_codes
    -- Entity flags
    , mve.is_deceased_indicator
    , Case
        When gab.flag = 'Y'
          Then 'GAB'
        When gab_s.flag = 'Y'
          Then 'GAB Spouse'
      End As gab
    , Case
        When trustee.flag = 'Y'
          Then 'Trustee'
        When trustee_s.flag = 'Y'
          Then 'Trustee Spouse'
      End As trustee
    , Case
        When ebfa.flag = 'Y'
          Then 'EBFA'
        When ebfa_s.flag = 'Y'
          Then 'EBFA Spouse'
      End As ebfa
    -- Overall special handling indicators
    , svc_ind.no_contact
    , svc_ind.no_solicit
    , svc_ind.no_release
    , svc_ind.active_with_restrictions
    , svc_ind.never_engaged_forever
    , svc_ind.never_engaged_reunion
    , svc_ind.anonymous_donor
    -- No AF sol combined
    , Case
        When no_contact = 'Y'
          Or active_with_restrictions = 'Y'
          Or no_solicit = 'Y'
          Then 'Y'
        End
      As no_af_sol_ind
    -- No phone combined
    , Case
        When univ_no_contact = 'Y'
          Or no_phone = 'Y'
          Then 'Y'
      End As no_phone_ind
    -- No phone solicit combined
    , Case
        When univ_no_contact = 'Y'
          Or no_phone = 'Y'
          Or univ_no_solicit = 'Y'
          Or no_phone_solicit = 'Y'
          Then 'Y'
      End As no_phone_sol_ind
    -- No email combined
    , Case
        When univ_no_contact = 'Y'
          Or no_email = 'Y'
          Then 'Y'
      End As no_email_ind
    -- No email solicit combined
    , Case
        When univ_no_contact = 'Y'
          Or no_email = 'Y'
          Or univ_no_solicit = 'Y'
          Or no_email_solicit = 'Y'
          Then 'Y'
      End As no_email_sol_ind
    -- No mail combined
    , Case
        When univ_no_contact = 'Y'
          Or no_mail = 'Y'
          Then 'Y'
      End As no_mail_ind
    -- No mail solicit combined
    , Case
        When univ_no_contact = 'Y'
          Or no_mail = 'Y'
          Or univ_no_solicit = 'Y'
          Or no_mail_solicit = 'Y'
          Then 'Y'
      End As no_mail_sol_ind
    -- No texts combined
    , Case
        When univ_no_contact = 'Y'
          Or no_texts = 'Y'
          Then 'Y'
      End As no_texts_ind
    -- No texts solicit combined
    , Case
        When univ_no_contact = 'Y'
          Or no_texts = 'Y'
          Or univ_no_solicit = 'Y'
          Or no_texts_solicit = 'Y'
          Then 'Y'
      End As no_texts_sol_ind
    -- Alerts
    --, alerts.ksm_stewardship_issue
    , Case
        When svc_ind.etl_update_date Is Not Null
          Then svc_ind.etl_update_date
        Else mve.etl_update_date
        End
      As etl_update_date
  From unc_ids ids
  Inner Join mv_entity mve
    On mve.donor_id = ids.donor_id
  Left Join svc_ind
    On svc_ind.donor_id = ids.donor_id
  --Left Join alerts On alerts.id_number = ids.id_number
  Left Join gab
    On gab.donor_id = ids.donor_id
  Left Join gab gab_s
    On gab_s.donor_id = ids.spouse_donor_id
  Left Join trustee
    On trustee.donor_id = ids.donor_id
  Left Join trustee trustee_s
    On trustee_s.donor_id = ids.spouse_donor_id
  Left Join ebfa
    On ebfa.donor_id = ids.donor_id
  Left Join ebfa ebfa_s
    On ebfa_s.donor_id = ids.spouse_donor_id
;

/*************************************************************************
Pipelined functions
*************************************************************************/

-- Concatenated special handling preferences
Function tbl_special_handling
    Return special_handling Pipelined As
    -- Declarations
    hnd special_handling;
    
    Begin
      Open c_special_handling;
        Fetch c_special_handling Bulk Collect Into hnd;
      Close c_special_handling;
      For i in 1..(hnd.count) Loop
        Pipe row(hnd(i));
      End Loop;
      Return;
    End;

End ksm_pkg_special_handling;
/
