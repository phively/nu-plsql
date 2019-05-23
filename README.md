# NU and Kellogg PL/SQL definitions

Contains SQL and PL/SQL code for various Kellogg data definitions and best practices.

# Important views

## Utility views

 * [v_current_calendar](https://github.com/phively/nu-plsql/blob/master/views/ksm_utility_views.sql) = self-updating dates, e.g. yesterday, today, curr_week_start
 * [v_frontline_ksm_staff](https://github.com/phively/nu-plsql/blob/master/views/ksm_utility_views.sql) = list of current and past KSM prospect managers

## Definitions

 * [v_entity_ksm_households](https://github.com/phively/nu-plsql/blob/master/views/ksm_utility_views.sql) = householding definition; earliest KSM grad is the primary household member, with lower entity ID number as the tiebreaker
 * [v_entity_ksm_degrees](https://github.com/phively/nu-plsql/blob/master/views/ksm_utility_views.sql) = KSM alumni definition, plus concatenated degrees and name tag strings
 * [v_ksm_prospect_pool](https://github.com/phively/nu-plsql/blob/master/views/v_ksm_prospect_pool.sql) = KSM prospect pool definition: alumni, donors, and prospects

## Giving views

 * [v_alloc_curr_use](https://github.com/phively/nu-plsql/blob/master/views/ksm_utility_views.sql) = KSM current use allocation definition
 * [v_ksm_giving_summary](https://github.com/phively/nu-plsql/blob/master/views/ksm_giving_trans_views.sql) = householded giving totals, including KSM lifetime, yearly ngc, yearly cash, yearly af and klc totals and categories, etc.
 * [v_ksm_giving_trans_hh](https://github.com/phively/nu-plsql/blob/master/views/ksm_giving_trans_views.sql) = householded KSM giving transactions
 * [v_ksm_giving_campaign](https://github.com/phively/nu-plsql/blob/master/views/ksm_giving_trans_views.sql) = householded KSM campaign giving totals, stewardship totals, and broken out by year
 * [v_ksm_giving_campaign_trans_hh](https://github.com/phively/nu-plsql/blob/master/views/ksm_giving_trans_views.sql) = householded KSM campaign giving transactions
 * [v_ksm_pledge_balances](https://github.com/phively/nu-plsql/blob/master/views/v_ksm_pledge_balances.sql) = KSM amounts due by allocation on currently active pledges

## Prospect views

 * [v_assignment_history](https://github.com/phively/nu-plsql/blob/master/views/v_assignment_history.sql) = gift officer current and historical portfolio assignments
 * [v_ksm_proposal_history_fast](https://github.com/phively/nu-plsql/blob/master/views/v_ksm_proposal_history.sql) = current and historical proposals
 * [v_contact_reports_fast](https://github.com/phively/nu-plsql/blob/master/views/v_ksm_contact_reports.sql) = historical contact reports, including up to 2000 characters of the text
 * [v_nu_visits](https://github.com/phively/nu-plsql/blob/master/views/v_ksm_visits.sql) = historical visit contact reports, including up to 2000 characters of the text