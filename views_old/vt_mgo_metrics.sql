CREATE OR REPLACE VIEW VT_MGO_METRICS AS
WITH base_data AS (
SELECT mgo.id_number
      ,mgo.report_name
      ,mgo.goal_desc
      ,mgo.perf_year
      ,mgo.progress
      ,mgo.py_goal
FROM rpt_pbh634.v_mgo_goals_monthly mgo
INNER JOIN rpt_pbh634.v_frontline_ksm_staff ksm ON mgo.id_number = ksm.ID_NUMBER
WHERE ksm.former_staff IS NULL
AND ksm.team = 'MG'
)

SELECT id_number
      ,report_name
      ,goal_desc
      ,perf_year
      ,'Progress' As type
      ,sum(progress) as counts
FROM base_data
GROUP BY id_number, report_name, goal_desc, perf_year
UNION
SELECT id_number
      ,report_name
      ,goal_desc
      ,perf_year
      ,'Goal' As type
      ,max(py_goal) as counts
FROM base_data
GROUP BY id_number, report_name, goal_desc, perf_year
