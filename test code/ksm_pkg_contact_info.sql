---------------------------
-- ksm_pkg_contact_info tests
---------------------------

Select *
From table(ksm_pkg_contact_info.tbl_phone)
;

Select *
From table(ksm_pkg_contact_info.tbl_email)
;

Select *
From table(ksm_pkg_contact_info.tbl_address)
;

Select *
From table(ksm_pkg_contact_info.tbl_linkedin)
;

Select *
From table(ksm_pkg_contact_info.tbl_entity_contact_info)
;

Select *
From table(ksm_pkg_contact_info.tbl_continents)
;

---------------------------
-- mv tests and data check
---------------------------

-- Check for blank country/continent pairs
Select *
From v_addr_continents
Where continent = 'CHECK'
Order By n_rows Desc
;

-- Check for duplicate rows
Select
  'No duplicates' As explanation
  , Case When count(donor_id) = count(distinct donor_id) Then 'Y' Else 'FALSE' End
    As pass
  , count(donor_id)
  , count(distinct donor_id)
From mv_entity_contact_info ci
;

-- Check NO EMAIL and NO PHONE
(
Select
  ci.donor_id
  , ci.sort_name
  , ci.service_indicators_concat
  , ci.phone_preferred_type
  , ci.phone_preferred
  , ci.email_preferred_type
  , ci.email_preferred
From mv_entity_contact_info ci
Where ci.email_preferred = 'DO NOT EMAIL'
  And ROWNUM <= 5
) Union (
Select
  ci.donor_id
  , ci.sort_name
  , ci.service_indicators_concat
  , ci.phone_preferred_type
  , ci.phone_preferred
  , ci.email_preferred_type
  , ci.email_preferred
From mv_entity_contact_info ci
Where ci.phone_preferred = 'DO NOT PHONE'
  And ROWNUM <= 5
)
;
