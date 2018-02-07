Create Or Replace View vt_ksm_prs_pool_gos As

/* Assigned v_ksm_prospect_pool joined with KSM current frontline staff activity
per prospect */

Select
  pool.*
  , mgo.gift_officer
  , mgo.assigned
  , mgo.visits_last_365_days
  , mgo.quals_last_365_days
  , mgo.visits_this_py
  , mgo.quals_this_py
  , mgo.total_open_proposals
  , mgo.total_open_asks
  , mgo.total_open_ksm_asks
  , mgo.total_cfy_ksm_ant_ask
  , mgo.total_cfy_ksm_verbal
  , mgo.total_cfy_ksm_funded
  , mgo.total_cpy_ant_ask
  , mgo.total_cpy_verbal
  , mgo.total_cpy_funded
From vt_ksm_prs_pool pool
Inner Join v_ksm_mgo_own_activity_by_prs mgo On mgo.prospect_id = pool.prospect_id
