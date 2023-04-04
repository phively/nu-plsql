---------------------------
-- ksm_pkg_address tests
---------------------------

-- Table functions
Select *
From table(ksm_pkg_address.tbl_geo_code_primary)
;

-- Functions
Select
    id_number
    , ksm_pkg_address.get_entity_address(id_number, 'city')
From entity
Where entity.record_status_code = 'A'
;

---------------------------
-- ksm_pkg tests
---------------------------

-- Table functions
Select *
From table(ksm_pkg_tst.tbl_geo_code_primary)
;
