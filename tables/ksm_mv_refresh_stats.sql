Create Or Replace View ksm_mv_refresh_stats As

-- Name headers
Select
  NULL As view_name
  , NULL As min_etl_update_date
  , NULL As mv_last_refresh
From DUAL
Where 1 = 0
-- 7:30 AM
Union
Select 'mv_entity', min(etl_update_date), min(mv_last_refresh)
From mv_entity
Union
Select 'mv_entity_ksm_degrees', min(etl_update_date), min(mv_last_refresh)
From mv_entity_ksm_degrees
Union
Select 'mv_ksm_designation', min(etl_update_date), min(mv_last_refresh)
From mv_ksm_designation
-- 7:40 AM
Union
Select 'mv_ksm_transactions', min(etl_update_date), min(mv_last_refresh)
From mv_ksm_transactions
;

Select *
From v_ksm_mv_refresh_stats
;
