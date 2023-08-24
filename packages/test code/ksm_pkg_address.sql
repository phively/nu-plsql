---------------------------
-- ksm_pkg_address tests
---------------------------

-- Table functions
Select *
From table(ksm_pkg_address.tbl_geo_code_primary)
Where id_number In ('0000001915', '0000002168', '0000002281', '0000002290', '0000002744')
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
Where id_number In ('0000001915', '0000002168', '0000002281', '0000002290', '0000002744')
;

-- Functions
Select
    id_number
    , ksm_pkg_tst.get_entity_address(id_number, 'city')
From entity
Where entity.record_status_code = 'A'
;
