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
