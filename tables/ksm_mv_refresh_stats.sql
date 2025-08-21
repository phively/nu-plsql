Create Or Replace View ksm_mv_refresh_stats As

-- Name headers
Select
  NULL As refresh_level
  , NULL As view_name
  , NULL As n_rows
  , NULL As mv_last_refresh
  , NULL As max_etl_update_date
  , NULL As min_etl_update_date
From DUAL
Where 1 = 0
-- 7:30 AM
Union
Select 0, 'mv_involvement', count(*), min(mv_last_refresh), max(etl_update_date), min(etl_update_date)
From mv_involvement
Union
Select 0, 'mv_entity', count(*), min(mv_last_refresh), max(etl_update_date), min(etl_update_date)
From mv_entity
Union
Select 0, 'mv_entity_ksm_degrees', count(*), min(mv_last_refresh), max(etl_update_date), min(etl_update_date)
From mv_entity_ksm_degrees
Union
Select 0, 'mv_ksm_designation', count(*), min(mv_last_refresh), max(etl_update_date), min(etl_update_date)
From mv_ksm_designation
Union
Select 0, 'mv_transactions', count(*), min(mv_last_refresh), max(max_etl_update_date), min(max_etl_update_date)
From mv_transactions
Union
Select 0, 'mv_matches', count(*), min(mv_last_refresh), max(etl_update_date), min(etl_update_date)
From mv_matches
Union
Select 0, 'mv_assignments', count(*), min(mv_last_refresh), max(etl_update_date), min(etl_update_date)
From mv_assignments
Union
Select 0, 'mv_assignment_history', count(*), min(mv_last_refresh), max(etl_update_date), min(etl_update_date)
From mv_assignment_history
Union
Select 0, 'mv_proposals', count(*), min(mv_last_refresh), max(etl_update_date), min(etl_update_date)
From mv_proposals
-- 7:40 AM
Union
Select 1, 'mv_households', count(*), min(mv_last_refresh), max(etl_update_date), min(etl_update_date)
From mv_households
Union
Select 1, 'mv_ksm_transactions', count(*), min(mv_last_refresh), max(max_etl_update_date), min(max_etl_update_date)
From mv_ksm_transactions
Union
Select 1, 'mv_source_donor', count(*), min(mv_last_refresh), max(etl_update_date), min(etl_update_date)
From mv_source_donor
Union
Select 1, 'mv_special_handling', count(*), min(mv_last_refresh), max(etl_update_date), min(etl_update_date)
From mv_special_handling
-- 7:50 AM
Union
Select 2, 'mv_ksm_giving_summary', count(*), min(mv_last_refresh), max(etl_update_date), min(etl_update_date)
From mv_ksm_giving_summary
Union
Select 2, 'mv_entity_contact_info', count(*), min(mv_last_refresh), max(max_etl_update_date), min(max_etl_update_date)
From mv_entity_contact_info
;

Select *
From ksm_mv_refresh_stats
;
