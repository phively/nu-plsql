With

rep_end_alloc As (
  Select
    a.allocation_code
    , a.short_name
    , a.long_name
    , a.alloc_school
    , tp.short_desc As alloc_purpose
    , a.steward_id_number
    , e.report_name As steward_report_name
  From allocation a
  Left Join tms_purpose tp
    On tp.purpose_code = a.alloc_purpose
  Left Join entity e
    On e.id_number = a.steward_id_number
  Where steward_reporting_code = 'RP'
    And (
      alloc_school = 'KM' -- Kellogg accounts
      Or steward_id_number = '0000697410' -- Kellogg steward ID
    )
    And agency = 'END'
)

, hh_stewardees As (
  Select 
    als.id_number As household_id
    , listagg(rea.allocation_code, ', ') Within Group (Order By als.allocation_code)
      As stewardee_alloc_code
    , listagg(rea.short_name, ', ') Within Group (Order By als.allocation_code)
      As stewardee_alloc_short_name
    , listagg(rea.long_name, ', ') Within Group (Order By als.allocation_code)
      As stewardee_alloc_long_name
    , listagg(rea.alloc_purpose, ', ') Within Group (Order By als.allocation_code)
      As stewardee_alloc_purpose
    , listagg(tss.short_desc, ', ') Within Group (Order By als.allocation_code)
      As stewardee_status
    , listagg(steward_id_number, ', ') Within Group (Order By als.allocation_code)
      As steward_id_number
    , listagg(steward_report_name, ', ') Within Group (Order By als.allocation_code)
      As steward_report_name
    From allocation_stewardee als
    Inner Join rep_end_alloc rea
      On als.allocation_code = rea.allocation_code
    Left Join tms_stewardee_status tss
      On tss.stewardee_status = als.stewardee_status_code
    Group By als.id_number
)

, hh_end_trans As (
  Select gft.*
  From rpt_pbh634.v_ksm_giving_campaign_trans_hh gft
  Where
  -- Reportable Endowed allocations per Rep_End_Alloc subquery
  gft.allocation_code In (Select Distinct allocation_code From Rep_End_Alloc)
)

, hh_end_donors As (
  Select
    trans.household_id
    , sum(trans.hh_recognition_credit) As total_to_end
  From hh_end_trans trans
  Group By trans.household_id
)

, spouse As (
  Select 
    e.id_number
    , e.spouse_id_number
    , se.record_status_code
    , se.pref_mail_name
    , se.first_name
    , se.last_name
  From entity e
  Left Join entity se
    On e.spouse_id_number = se.id_number
  Where se.record_status_code = 'A'
)

, sally_salut As (
  Select
    id_number
    , max(salutation) keep(dense_rank First Order By ID_number Asc, date_modified)
      As latest_sal
  From salutation
  Where signer_id_number = '0000299349'
    And active_ind = 'Y'
    And salutation != '%and%'
  Group By id_number
  Order By id_number
)

, prefaddress As (
  Select 
    a.id_number
    , tms_addr_status.short_desc
      As address_status
    , tms_address_type.short_desc
      As address_type
    , a.addr_pref_ind
    , a.company_name_1
    , a.company_name_2
    , a.street1
    , a.street2
    , a.street3
    , a.foreign_cityzip
    , a.city
    , a.state_code
    , a.zipcode
    , tms_country.short_desc
      As country
  From address a
  Inner Join tms_addr_status
    On tms_addr_status.addr_status_code = a.addr_status_code
  Left Join tms_address_type
    On tms_address_type.addr_type_code = a.addr_type_code
  Left Join tms_country
    On tms_country.country_code = a.country_code
  Where a.addr_pref_ind = 'Y'
  And a.addr_status_code In ('A','K')
)

, seas_address As (
  Select *
  From rpt_dgz654.v_seasonal_addr sa
  Where current_date Between sa.real_start_date1 And sa.real_stop_date1 
    Or current_date Between sa.real_start_date2 And sa.real_stop_date2
)

, prospect_manager As (
  Select
    a.prospect_id
    , pet.id_number
    , a.assignment_id_number
    , e.pref_mail_name
  From assignment a
  Inner Join prospect_entity pet
    On a.prospect_id = pet.prospect_id
  Inner Join entity e
   On a.assignment_id_number = e.id_number
  Where a.assignment_type = 'PM'
  And a.active_ind = 'Y'
)

, prog_prospect_manager As (
  Select 
    a.prospect_id
    , pet.id_number
    , listagg(a.assignment_id_number, ', ') Within Group (Order By a.assignment_id_number Asc)
      As ppm_ids
    , listagg(e.pref_mail_name, ', ') Within Group (Order By a.assignment_id_number Asc)
      As ppm_names
  From assignment a
  Inner Join prospect_entity pet
    On a.prospect_id = pet.prospect_id
  Inner Join entity e
  On a.assignment_id_number = e.id_number
  Where a.assignment_type = 'PP'
    And a.active_ind = 'Y'
    And pet.primary_ind = 'Y'
  Group By
    a.prospect_id
    , pet.id_number
)

Select Distinct
  -- First (no special handling) or second (special handling restrictions) tab
  Case
    -- This returns people who do not have special handling restrictions
    When e.record_status_code = 'A'
      And sph.no_contact Is Null
      And sph.no_mail_ind Is Null
      Then 'Mailable'
    -- People who are No Contact status, or Active and not mailable
    When e.record_status_code In ('A', 'C')
      And (sph.no_contact = 'Y'
        Or sph.no_mail_ind = 'Y')
      Then 'Special Handling'
    Else 'Removed'
    End
    As stewardee_tab
  , e.id_number As "Household ID"
  , e.report_name As "P Report Name"
  , e.first_name As "P First Name"
  , psal.latest_sal As "P Sally Salut"
  , e.pref_mail_name As "P_Pref_Name"
  , e.record_status_code As "P Record Status" 
  , d.degrees_concat As p_degrees_concat
  , e.spouse_id_number As "Spouse ID"
  , s.record_status_code As "Spouse_Status"
  , s.pref_mail_name As "Spouse_Pref_Name"
  , s.first_name As "Spouse_First_Name"
  , s.pref_mail_name As "Spouse_Pref_Name"
  , ssal.latest_sal As "Sally_Spouse_Salut"
  , e.jnt_salutation As "Joint Salutation"
  , pm.pref_mail_name As "Prospect Manager"
  , pp.ppm_names As "Program Prospect Manager"
  , hh.stewardee_alloc_code
  , hh.stewardee_alloc_short_name
  , hh.stewardee_alloc_long_name
  , hh.steward_id_number
  , hh.steward_report_name
  , hh.stewardee_alloc_purpose
  , hh.stewardee_status
  -- Seasonal address chooser
  , Case
      When sa.address_type = 'Seasonal'
        Then 'Seasonal'
      When PA.Address_type Is Not Null
        Then 'Preferred'
      Else Null
      End
    As addr_type
  , Case
      When sa.address_type = 'Seasonal'
        Then sa.company_name_1
      When pa.address_type Is Not Null
        Then pa.company_name_1
      Else Null
      End
    As company_name_1
  , Case
      When sa.address_type = 'Seasonal'
        Then sa.company_name_2
      When pa.address_type Is Not Null
        Then pa.company_name_2
      Else Null
      End
    As company_name_2
  , Case
      When sa.address_type = 'Seasonal'
        Then sa.street1
      When pa.address_type Is Not Null
        Then pa.street1
      Else Null
      End
    As street1
  , Case
      When sa.address_type = 'Seasonal'
        Then sa.street2
      When pa.address_type Is Not Null
        Then pa.street2
      Else Null
      End
    As street2
  , Case
      When sa.address_type = 'Seasonal'
        Then sa.street3
      When pa.address_type Is Not Null
        Then pa.street3
      Else Null
      End
    As street3
  , Case
      When sa.address_type = 'Seasonal'
        Then sa.foreign_cityzip
      When pa.address_type Is Not Null
        Then pa.foreign_cityzip
      Else Null
      End
    As foreign_zipcode
  , Case
      When sa.address_type = 'Seasonal'
        Then sa.city
      When pa.address_type Is Not Null
        Then pa.city
      Else Null
      End
    As city
  , Case
      When sa.address_type = 'Seasonal'
        Then sa.state_code
      When pa.address_type Is Not Null
        Then pa.state_code
      Else Null
      End
    As state
  , Case
      When sa.address_type = 'Seasonal'
        Then sa.zipcode
      When pa.address_type Is Not Null
        Then pa.zipcode
      Else null
      End
    As zipcode
  , Case
      When sa.address_type = 'Seasonal'
        Then sa.country
      When pa.address_type Is Not Null
        Then pa.country
      Else Null
      End
    As country
  , sph.*
  , e.pref_name_sort
From entity e
Inner Join hh_stewardees hh
  On e.id_number = hh.household_id
Left Join rpt_pbh634.v_entity_ksm_degrees d
  On hh.household_id = d.id_number
Left Join hh_end_donors don
  On hh.household_id = don.household_id
Left Join prefaddress pa
  On e.id_number = pa.id_number
Left Join seas_address sa
  On e.id_number = sa.id_number
Left Join table(rpt_pbh634.ksm_pkg.tbl_special_handling_concat) sph
  On e.id_number = sph.id_number
Left Join spouse s
  On e.id_number = s.id_number
Left Join sally_salut psal
  On e.id_number = psal.id_number
Left Join prospect_manager pm
  On e.id_number = pm.id_number
Left Join sally_salut psal
  On e.id_number = psal.id_number
Left Join sally_salut ssal
  On e.spouse_id_number = ssal.id_number
Left Join prospect_manager pm
  On e.id_number = pm.id_number
Left Join prog_prospect_manager pp
  On e.id_number = pp.id_number
