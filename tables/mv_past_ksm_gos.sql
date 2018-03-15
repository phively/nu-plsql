-- Drop old materialized view
Drop Materialized View mv_past_ksm_gos;

-- Create new materialized view
Create Materialized View mv_past_ksm_gos As

With

-- Data table; update as needed
adv_dates As (
  Select 'notarealid' As id_number, NULL As start_dt, NULL As stop_dt From DUAL
  Union All Select '0000562844', to_date('20080808', 'yyyymmdd'), to_date('20150601', 'yyyymmdd') From DUAL
  Union All Select '0000235591', to_date('20160501', 'yyyymmdd'), NULL From DUAL
  Union All Select '0000482962', to_date('20030619', 'yyyymmdd'), to_date('20110511', 'yyyymmdd') From DUAL
  Union All Select '0000510455', to_date('20081001', 'yyyymmdd'), to_date('20110920', 'yyyymmdd') From DUAL
  Union All Select '0000609581', to_date('20110501', 'yyyymmdd'), to_date('20130901', 'yyyymmdd') From DUAL
  Union All Select '0000565395', to_date('20140901', 'yyyymmdd'), to_date('20170801', 'yyyymmdd') From DUAL
  Union All Select '0000634311', to_date('20120601', 'yyyymmdd'), to_date('20160430', 'yyyymmdd') From DUAL
  Union All Select '0000514693', to_date('20080501', 'yyyymmdd'), to_date('20140101', 'yyyymmdd') From DUAL
  Union All Select '0000772350', to_date('20170306', 'yyyymmdd'), to_date('20171101', 'yyyymmdd') From DUAL
  Union All Select '0000220843', to_date('20161101', 'yyyymmdd'), NULL From DUAL
  Union All Select '0000482601', to_date('20120101', 'yyyymmdd'), NULL From DUAL
  Union All Select '0000532713', to_date('20120201', 'yyyymmdd'), to_date('20140701', 'yyyymmdd') From DUAL
  Union All Select '0000740856', to_date('20171001', 'yyyymmdd'), NULL From DUAL
  Union All Select '0000737745', to_date('20151101', 'yyyymmdd'), to_date('20170401', 'yyyymmdd') From DUAL
  Union All Select '0000642888', to_date('20160901', 'yyyymmdd'), NULL From DUAL
  Union All Select '0000784241', to_date('20170901', 'yyyymmdd'), NULL From DUAL
  Union All Select '0000779347', to_date('20170701', 'yyyymmdd'), NULL From DUAL
  Union All Select '0000664033', to_date('20131101', 'yyyymmdd'), to_date('20160401', 'yyyymmdd') From DUAL
  Union All Select '0000405472', to_date('20090401', 'yyyymmdd'), to_date('20100501', 'yyyymmdd') From DUAL
  Union All Select '0000765494', to_date('20161001', 'yyyymmdd'), NULL From DUAL
  Union All Select '0000541522', to_date('20061101', 'yyyymmdd'), to_date('20130101', 'yyyymmdd') From DUAL
  Union All Select '0000776709', to_date('20170401', 'yyyymmdd'), NULL From DUAL
  Union All Select '0000561243', to_date('20110701', 'yyyymmdd'), NULL From DUAL
  Union All Select '0000732336', to_date('20171101', 'yyyymmdd'), NULL From DUAL
  Union All Select '0000549376', to_date('20070801', 'yyyymmdd'), NULL From DUAL
  Union All Select '0000772028', to_date('20170201', 'yyyymmdd'), NULL From DUAL
  Union All Select '0000716237', to_date('20150201', 'yyyymmdd'), to_date('20160801', 'yyyymmdd') From DUAL
  Union All Select '0000565742', to_date('20080901', 'yyyymmdd'), NULL From DUAL
  Union All Select '0000562459', to_date('20080801', 'yyyymmdd'), NULL From DUAL
  Union All Select '0000444799', to_date('20131001', 'yyyymmdd'), to_date('20170501', 'yyyymmdd') From DUAL
  Union All Select '0000322256', to_date('20080101', 'yyyymmdd'), to_date('20101231', 'yyyymmdd') From DUAL
  Union All Select '0000425673', to_date('20070701', 'yyyymmdd'), to_date('20141001', 'yyyymmdd') From DUAL
  Union All Select '0000686713', to_date('20140401', 'yyyymmdd'), to_date('20170108', 'yyyymmdd') From DUAL
  Union All Select '0000633474', to_date('20120701', 'yyyymmdd'), to_date('20150301', 'yyyymmdd') From DUAL
  Union All Select '0000780506', to_date('20180101', 'yyyymmdd'), NULL From DUAL
  Union All Select '0000783777', to_date('20171001', 'yyyymmdd'), NULL From DUAL
)

Select
  adv_dates.id_number
  , entity.report_name
  , adv_dates.start_dt
  , adv_dates.stop_dt
From adv_dates adv_dates
Inner Join entity On entity.id_number = adv_dates.id_number
Order By entity.report_name Asc
;
