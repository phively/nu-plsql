Select Distinct
  e.id_number
  , e.report_name
  , emp.job_title
  , emp.employer_unit
  , emp.start_dt
  , emp.stop_dt
From entity e
Inner Join employment emp On emp.id_number = e.id_number
Where (emp.employer_unit Like '%KSM%' And emp.employer_unit Like '%dvance%')
  Or (emp.employer_unit Like '%Kellog%' And emp.employer_unit Like '%dvance%')
  Or (emp.employer_unit Like '%KSM%' And emp.employer_unit Like '%ajor%')
  Or (emp.employer_unit Like '%Kellog%' And emp.employer_unit Like '%ajor%')
  Or (emp.employer_unit Like '%KSM%' And emp.employer_unit Like '%ifts%')
  Or (emp.employer_unit Like '%Kellog%' And emp.employer_unit Like '%ifts%')
  Or (emp.employer_unit Like '%KSM%' And emp.employer_unit Like '%ivin%')
  Or (emp.employer_unit Like '%Kellog%' And emp.employer_unit Like '%ivin%')
  Or (emp.employer_unit Like '%KSM%' And emp.employer_unit Like '%ampaig%')
  Or (emp.employer_unit Like '%Kellog%' And emp.employer_unit Like '%ampaig%')
  Or (emp.employer_unit Like '%KSM%' And emp.employer_unit Like '%evelop%')
  Or (emp.employer_unit Like '%Kellog%' And emp.employer_unit Like '%evelop%')
Order By
  report_name Asc
  , start_dt Asc
  , stop_dt Asc
