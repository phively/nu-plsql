Create Or Replace View vt_ksm_prs_pool_gos As

/* Assigned v_ksm_prospect_pool joined with KSM current frontline staff activity
per prospect */

Select
  pool.*
  , mgo.gift_officer
  , mgo.assigned
  -- Only fill in metrics for the primary prospect
  , Case When pool.primary_ind = 'Y' Then mgo.visits_last_365_days End
      As visits_last_365_days
  , Case When pool.primary_ind = 'Y' Then mgo.quals_last_365_days End
      As quals_last_365_days
  , Case When pool.primary_ind = 'Y' Then mgo.visits_this_py End
      As visits_this_py
  , Case When pool.primary_ind = 'Y' Then mgo.quals_this_py End
      As quals_this_py
  , Case When pool.primary_ind = 'Y' Then mgo.total_open_proposals End
      As total_open_proposals
  , Case When pool.primary_ind = 'Y' Then mgo.total_open_asks End
      As total_open_asks
  , Case When pool.primary_ind = 'Y' Then mgo.total_open_ksm_asks End
      As total_open_ksm_asks
  , Case When pool.primary_ind = 'Y' Then mgo.total_cfy_ksm_ant_ask End
      As total_cfy_ksm_ant_ask
  , Case When pool.primary_ind = 'Y' Then mgo.total_cfy_ksm_verbal End
      As total_cfy_ksm_verbal
  , Case When pool.primary_ind = 'Y' Then mgo.total_cfy_ksm_funded End
      As total_cfy_ksm_funded
  , Case When pool.primary_ind = 'Y' Then mgo.total_cpy_ant_ask End
      As total_cpy_ant_ask
  , Case When pool.primary_ind = 'Y' Then mgo.total_cpy_verbal End
      As total_cpy_verbal
  , Case When pool.primary_ind = 'Y' Then mgo.total_cpy_funded End
      As total_cpy_funded
From vt_ksm_prs_pool pool
Inner Join v_ksm_mgo_own_activity_by_prs mgo On mgo.prospect_id = pool.prospect_id
