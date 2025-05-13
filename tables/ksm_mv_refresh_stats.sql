Create Or Replace View ksm_mv_refresh_stats As

-- Name headers
Select
  NULL As view_name
  , NULL As mv_last_refresh
  , NULL As max_etl_update_date
  , NULL As min_etl_update_date
From DUAL
Where 1 = 0
-- 7:30 AM
Union
Select 'mv_involvement', min(mv_last_refresh), max(etl_update_date), min(etl_update_date)
From mv_involvement
Union
Select 'mv_entity', min(mv_last_refresh), max(etl_update_date), min(etl_update_date)
From mv_entity
Union
Select 'mv_entity_ksm_degrees', min(mv_last_refresh), max(etl_update_date), min(etl_update_date)
From mv_entity_ksm_degrees
Union
Select 'mv_ksm_designation', min(mv_last_refresh), max(etl_update_date), min(etl_update_date)
From mv_ksm_designation
-- 7:40 AM
Union
Select 'mv_ksm_transactions', min(mv_last_refresh), max(max_etl_update_date), min(min_etl_update_date)
From mv_ksm_transactions
;

Select *
From ksm_mv_refresh_stats
;
