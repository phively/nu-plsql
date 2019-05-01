CREATE OR REPLACE VIEW RPT_DGZ654.V_MGO_PROGRESS AS
WITH

Prospect_Manager AS (
     SELECT
     Assignment_ID_number
     , count(prospect_ID) AS Portfolio_count
     FROM assignment
     WHERE Assignment_type = 'PM' AND Active_IND = 'Y'
     GROUP BY Assignment_ID_Number
)

, all_activity As (
  Select *
  From rpt_pbh634.v_mgo_goals_monthly
)

SELECT Distinct
       E.Pref_Mail_Name
       , MGM."ID_NUMBER",MGM."REPORT_NAME",MGM."GOAL_TYPE",MGM."GOAL_DESC",MGM."CAL_YEAR",MGM."CAL_MONTH",MGM."FISCAL_YEAR",MGM."FISCAL_QUARTER",MGM."PERF_YEAR",MGM."PERF_QUARTER",MGM."FY_GOAL",MGM."PY_GOAL",MGM."PROGRESS",MGM."ADJUSTED_PROGRESS"
       , cal."TODAY",cal."YESTERDAY",cal."NINETY_DAYS_AGO",cal."CURR_FY",cal."PREV_FY_START",cal."CURR_FY_START",cal."NEXT_FY_START",cal."CURR_PY",cal."PREV_PY_START",cal."CURR_PY_START",cal."NEXT_PY_START",cal."PREV_FY_TODAY",cal."NEXT_FY_TODAY",cal."PREV_WEEK_START",cal."CURR_WEEK_START",cal."NEXT_WEEK_START",cal."PREV_MONTH_START",cal."CURR_MONTH_START",cal."NEXT_MONTH_START"
       , CASE WHEN MGM.perf_year = cal.curr_py
              THEN cal.yesterday - cal.curr_py_start
              ELSE 365
        END PY_Prog_Days
--       , to_date(lpad(cal_month, 2, '0') || '/01/' || cal_year, 'mm/dd/yyyy')
--         AS calendar_date
       , CASE
            WHEN MGM.id_number IN ('0000549376', '0000562459', '0000776709') THEN 'Midwest'
            WHEN MGM.id_number IN ('0000642888', '0000561243') THEN 'East'
            WHEN MGM.id_number IN ('0000565742', '0000220843', '0000779347') THEN 'West'
            WHEN MGM.id_number = '0000772028' THEN 'All'
              ELSE 'Non-KSM'
                END KSM_Region
        , PM.portfolio_count
FROM all_activity MGM
LEFT JOIN entity E
ON E.id_number = MGM.id_number
LEFT JOIN prospect_manager PM
ON PM.assignment_id_number = MGM.id_number
CROSS JOIN rpt_pbh634.v_current_calendar cal
ORDER BY MGM.Report_name, MGM.CAL_YEAR, MGM.cal_month
;
