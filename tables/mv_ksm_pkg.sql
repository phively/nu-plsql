--------------------------------------
-- ksm_pkg_entity
-- tbl_entity
Create Materialized View mv_entity
Refresh Complete
Start With sysdate
-- 7:30 AM tomorrow
Next (trunc(sysdate) + 1 + 7.5/24)
As
Select
  entity.*
  , sysdate as mv_last_refresh
From table(ksm_pkg_entity.tbl_entity) entity
;

--------------------------------------
-- ksm_pkg_degrees
-- tbl_entity_ksm_degrees
Create Materialized View mv_entity_ksm_degrees
Refresh Complete
Start With sysdate
-- 7:30 AM tomorrow
Next (trunc(sysdate) + 1 + 7.5/24)
As
Select
  deg.*
  , sysdate as mv_last_refresh
From table(ksm_pkg_degrees.tbl_entity_ksm_degrees) deg
;

--------------------------------------
-- ksm_pkg_designation
-- tbl_ksm_designation
Create Materialized View mv_ksm_designation
Refresh Complete
Start With sysdate
-- 7:30 AM tomorrow
Next (trunc(sysdate) + 1 + 7.5/24)
As
Select
  des.*
  , sysdate as mv_last_refresh
From table(ksm_pkg_designation.tbl_ksm_designation) des
;

--------------------------------------
-- ksm_pkg_gifts
-- tbl_ksm_transactions
Create Materialized View mv_ksm_transactions
Refresh Complete
Start With sysdate
-- 7:30 AM tomorrow
Next (trunc(sysdate) + 1 + 7.5/24)
As
Select
  des.*
  , sysdate as mv_last_refresh
From table(ksm_pkg_gifts.tbl_ksm_transactions) des
;
