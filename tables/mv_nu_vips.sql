-- Drop old materialized view
Drop Materialized View mv_nu_vips;

-- Create new materialized view
Create Materialized View mv_nu_vips As

With

-- Data table; update as needed
nu_dates As (
  Select 'notarealid' As id_number, 'noaffil' As affil, NULL As start_dt, NULL As stop_dt From DUAL
  Union
  Select '0000573302', 'President', to_date('20090901', 'yyyymmdd'), NULL From DUAL -- MOS
  Union 
  Select '0000299349', 'KSM Dean', to_date('20100701', 'yyyymmdd'), to_date('20180831', 'yyyymmdd') From DUAL -- SB
  Union
  Select '0000246649', 'KSM Dean', to_date('20180901', 'yyyymmdd'), NULL From DUAL -- KH
)

Select
  nu_dates.id_number
  , entity.report_name
  , affil
  , nu_dates.start_dt
  , nu_dates.stop_dt
From nu_dates
Inner Join entity On entity.id_number = nu_dates.id_number
Order By entity.report_name Asc
;
