/*************************************************************************
No dependencies
7:20 AM
7:30 AM
*************************************************************************/

--------------------------------------
-- dw_pkg_base
-- tbl_involvement
-- Drop Materialized View mv_involvement;
Create Materialized View mv_involvement
Refresh Complete
Start With sysdate
-- 7:30 AM tomorrow
Next (trunc(sysdate) + 1 + 7.5/24)
As
Select
  inv.*
  , sysdate as mv_last_refresh
From table(dw_pkg_base.tbl_involvement) inv
;

-- tbl_designation_detail
-- Drop Materialized View mv_designation_detail;
Create Materialized View mv_designation_detail
Refresh Complete
Start With sysdate
-- 7:30 AM tomorrow
Next (trunc(sysdate) + 1 + 7.5/24)
As
Select
  dd.*
  , sysdate as mv_last_refresh
From table(dw_pkg_base.tbl_designation_detail) dd
;

-- tbl_mini_entity
-- Drop Materialized View mv_mini_entity;
Create Materialized View mv_mini_entity
Refresh Complete
Start With sysdate
-- 7:20 AM tomorrow
Next (trunc(sysdate) + 1 + 7.333/24)
As
Select
  me.*
  , sysdate as mv_last_refresh
From table(dw_pkg_base.tbl_mini_entity) me
;

--------------------------------------
-- ksm_pkg_entity
-- tbl_entity
-- Drop Materialized View mv_entity;
Create Materialized View mv_entity
Refresh Complete
Start With sysdate
-- 7:20 AM tomorrow
Next (trunc(sysdate) + 1 + 7.333/24)
As
Select
  entity.*
  , sysdate as mv_last_refresh
From table(ksm_pkg_entity.tbl_entity) entity
;

-- tbl_entity_relationships
-- Drop Materialized View mv_entity_relationships;
Create Materialized View mv_entity_relationships
Refresh Complete
Start With sysdate
-- 7:30 AM tomorrow
Next (trunc(sysdate) + 1 + 7.5/24)
As
Select
  rel.*
  , sysdate as mv_last_refresh
From table(ksm_pkg_entity.tbl_entity_relationships) rel
;

--------------------------------------
-- ksm_pkg_degrees
-- tbl_entity_ksm_degrees
-- Drop Materialized View mv_entity_ksm_degrees;
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
-- Drop Materialized View mv_ksm_designation;
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
-- ksm_pkg_transactions
-- tbl_transactions
-- Drop Materialized View mv_transactions;
Create Materialized View mv_transactions
Refresh Complete
Start With sysdate
-- 7:30 AM tomorrow
Next (trunc(sysdate) + 1 + 7.5/24)
As
Select
  tr.*
  , sysdate as mv_last_refresh
From table(ksm_pkg_transactions.tbl_transactions) tr
;

-- tbl_matches
-- Drop Materialized View mv_matches;
Create Materialized View mv_matches
Refresh Complete
Start With sysdate
-- 7:30 AM tomorrow
Next (trunc(sysdate) + 1 + 7.5/24)
As
Select
  m.*
  , sysdate as mv_last_refresh
From table(ksm_pkg_transactions.tbl_matches) m
;

/*************************************************************************
Level 1 dependencies
7:30 AM
*************************************************************************/

--------------------------------------
-- ksm_pkg_prospect
-- tbl_assignment_summary
-- Drop Materialized View mv_assignments;
Create Materialized View mv_assignments
Refresh Complete
Start With sysdate
-- 7:35 AM tomorrow
Next (trunc(sysdate) + 1 + 7.583/24)
As
Select
  assign.*
  , sysdate as mv_last_refresh
From table(ksm_pkg_prospect.tbl_assignment_summary) assign
;

-- tbl_assignment_history
-- Drop Materialized View mv_assignment_history;
Create Materialized View mv_assignment_history
Refresh Complete
Start With sysdate
-- 7:30 AM tomorrow
Next (trunc(sysdate) + 1 + 7.583/24)
As
Select
  ah.*
  , sysdate as mv_last_refresh
From table(ksm_pkg_prospect.tbl_assignment_history) ah
;

--------------------------------------
-- ksm_pkg_contact_reports
-- tbl_contact_reports
-- Drop Materialized View mv_contact_reports;
Create Materialized View mv_contact_reports
Refresh Complete
Start With sysdate
-- 7:30 AM tomorrow
Next (trunc(sysdate) + 1 + 7.5/24)
As
Select
  cr.*
  , sysdate as mv_last_refresh
From table(ksm_pkg_contact_reports.tbl_contact_reports) cr
;

--------------------------------------
-- ksm_pkg_contacts
-- mv_entity_contact_info
-- Drop Materialized View mv_address;
Create Materialized View mv_address
Refresh Complete
Start With sysdate
-- 7:30 AM tomorrow
Next (trunc(sysdate) + 1 + 7.5/24)
As
Select
  addr.*
  , sysdate as mv_last_refresh
From table(ksm_pkg_contact_info.tbl_address) addr
;

--------------------------------------
-- ksm_pkg_proposals
-- tbl_proposals
-- Drop Materialized View mv_proposals;
Create Materialized View mv_proposals
Refresh Complete
Start With sysdate
-- 7:30 AM tomorrow
Next (trunc(sysdate) + 1 + 7.5/24)
As
Select
  prp.*
  , sysdate as mv_last_refresh
From table(ksm_pkg_proposals.tbl_proposals) prp
;

--------------------------------------
-- ksm_pkg_models
-- tbl_ksm_models
-- Drop Materialized View mv_ksm_models;
Create Materialized View mv_ksm_models
Refresh Complete
Start With sysdate
-- 7:30 AM tomorrow
Next (trunc(sysdate) + 1 + 7.5/24)
As
Select
  km.*
  , sysdate as mv_last_refresh
From table(ksm_pkg_models.tbl_ksm_models) km
;

/*************************************************************************
Level 2 dependencies
7:40 AM
*************************************************************************/

--------------------------------------
-- ksm_pkg_households
-- tbl_entity_households
-- Drop Materialized View mv_households;
Create Materialized View mv_households
Refresh Complete
Start With sysdate
-- 7:40 AM tomorrow
Next (trunc(sysdate) + 1 + 7.667/24)
As
Select
  hh.*
  , sysdate as mv_last_refresh
From table(ksm_pkg_households.tbl_households) hh
;

--------------------------------------
-- ksm_pkg_gifts
-- tbl_ksm_transactions
-- Drop Materialized View mv_ksm_transactions;
Create Materialized View mv_ksm_transactions
Refresh Complete
Start With sysdate
-- 7:40 AM tomorrow
Next (trunc(sysdate) + 1 + 7.667/24)
As
Select
  trn.*
  , sysdate as mv_last_refresh
From table(ksm_pkg_gifts.tbl_ksm_transactions) trn
;

-- tbl_source_donor
-- Drop Materialized View mv_source_donor;
Create Materialized View mv_source_donor
Refresh Complete
Start With sysdate
-- 7:40 AM tomorrow
Next (trunc(sysdate) + 1 + 7.667/24)
As
Select
  srcd.*
  , sysdate as mv_last_refresh
From table(ksm_pkg_gifts.tbl_source_donors) srcd
;

--------------------------------------
-- ksm_pkg_special_handling
-- tbl_special_handling
-- Drop Materialized View mv_special_handling;
Create Materialized View mv_special_handling
Refresh Complete
Start With sysdate
-- 7:40 AM tomorrow
Next (trunc(sysdate) + 1 + 7.667/24)
As
Select
  sh.*
  , sysdate as mv_last_refresh
From table(ksm_pkg_special_handling.tbl_special_handling) sh
;

/*************************************************************************
Level 2 dependencies
7:50 AM
*************************************************************************/

--------------------------------------
-- ksm_pkg_giving_summary
-- Drop Materialized View mv_ksm_giving_summary;
Create Materialized View mv_ksm_giving_summary
Refresh Complete
Start With sysdate
-- 7:50 AM tomorrow
Next (trunc(sysdate) + 1 + 7.833/24)
As
Select
  gs.*
  , sysdate as mv_last_refresh
From table(ksm_pkg_giving_summary.tbl_ksm_giving_summary) gs
;

--------------------------------------
-- ksm_pkg_contacts
-- mv_entity_contact_info
-- Drop Materialized View mv_entity_contact_info;
Create Materialized View mv_entity_contact_info
Refresh Complete
Start With sysdate
-- 7:50 AM tomorrow
Next (trunc(sysdate) + 1 + 7.833/24)
As
Select
  eci.*
  , sysdate as mv_last_refresh
From table(ksm_pkg_contact_info.tbl_entity_contact_info) eci
;
