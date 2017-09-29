-- Code to pull university strategy from the task table; BI method plus a cancelled/completed exclusion
Select prospect_id,
  -- Pull first upcoming University Overall Strategy
  min(task_description) keep(dense_rank First Order By sched_date Asc, task_id Asc) As university_strategy,
  min(sched_date) keep(dense_rank First Order By sched_date Asc, task_id Asc) As strategy_sched_date
From task
Cross Join v_current_calendar cal
Where task_code = 'ST' -- University Overall Strategy
  And trunc(sched_date) >= cal.today -- Scheduled in the future
  And task_status_code Not In (4, 5) -- Not Completed (4) or Cancelled (5) status
Group By prospect_id
