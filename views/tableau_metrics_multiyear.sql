Create Or Replace View tableau_metrics_multiyear As

With

base_data As (
  Select
    mgo.historical_pm_user_id
    , mgo.historical_pm_name
    , mgo.goal_desc
    , mgo.perf_year
    , mgo.progress
    , mgo.py_goal
  From tableau_mgo_progress mgo
  Inner Join tbl_ksm_gos gos
    On gos.user_id = mgo.historical_pm_user_id
  Where gos.team = 'MG'
)

(
  Select
    historical_pm_user_id
    , historical_pm_name
    , goal_desc
    , perf_year
    , 'Progress' As type
    , sum(progress) As counts
  From base_data
  Group By
    historical_pm_user_id
    , historical_pm_name
    , goal_desc
    , perf_year
) Union (
  Select
    historical_pm_user_id
    , historical_pm_name
    , goal_desc
    , perf_year
    , 'Goal' As type
    , max(py_goal) as counts
  From base_data
  Group By
    historical_pm_user_id
    , historical_pm_name
    , goal_desc
    , perf_year
)
