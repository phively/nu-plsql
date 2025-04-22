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
