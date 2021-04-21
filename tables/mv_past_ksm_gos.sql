-- Drop old materialized view
Drop Materialized View mv_past_ksm_gos;

-- Create new materialized view
Create Materialized View mv_past_ksm_gos As

With

-- Data table; update as needed
adv_dates As (
  Select 'notarealid' As id_number, 'notateam' As team, NULL As start_dt, NULL As stop_dt From DUAL
  Union All Select '0000562844', 'MG', to_date('20080808', 'yyyymmdd'), to_date('20150601', 'yyyymmdd') From DUAL
  Union All Select '0000235591', 'AF', to_date('20160501', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000482962', 'MG', to_date('20030619', 'yyyymmdd'), to_date('20110511', 'yyyymmdd') From DUAL
  Union All Select '0000510455', 'MG', to_date('20081001', 'yyyymmdd'), to_date('20110920', 'yyyymmdd') From DUAL
  Union All Select '0000609581', 'MG', to_date('20110501', 'yyyymmdd'), to_date('20130901', 'yyyymmdd') From DUAL
  Union All Select '0000565395', 'AF', to_date('20140901', 'yyyymmdd'), to_date('20170801', 'yyyymmdd') From DUAL
  Union All Select '0000634311', 'MG', to_date('20120601', 'yyyymmdd'), to_date('20160430', 'yyyymmdd') From DUAL
  Union All Select '0000514693', 'MG', to_date('20080501', 'yyyymmdd'), to_date('20140101', 'yyyymmdd') From DUAL
  Union All Select '0000772350', 'MG', to_date('20170306', 'yyyymmdd'), to_date('20171101', 'yyyymmdd') From DUAL
  Union All Select '0000220843', 'MG', to_date('20161101', 'yyyymmdd'), to_date('20200831', 'yyyymmdd') From DUAL
  Union All Select '0000482601', 'AF', to_date('20120101', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000532713', 'MG', to_date('20120201', 'yyyymmdd'), to_date('20140701', 'yyyymmdd') From DUAL
  Union All Select '0000740856', 'AF', to_date('20171001', 'yyyymmdd'), to_date('20201211', 'yyyymmdd') From DUAL
  Union All Select '0000737745', 'MG', to_date('20151101', 'yyyymmdd'), to_date('20170401', 'yyyymmdd') From DUAL
  Union All Select '0000642888', 'MG', to_date('20160901', 'yyyymmdd'), to_date('20190927', 'yyyymmdd') From DUAL
  Union All Select '0000784241', 'AF', to_date('20170901', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000779347', 'MG', to_date('20170701', 'yyyymmdd'), to_date('20200831', 'yyyymmdd') From DUAL
  Union All Select '0000664033', 'MG', to_date('20131101', 'yyyymmdd'), to_date('20160401', 'yyyymmdd') From DUAL
  Union All Select '0000405472', 'MG', to_date('20090401', 'yyyymmdd'), to_date('20100501', 'yyyymmdd') From DUAL
  Union All Select '0000765494', 'AF', to_date('20161001', 'yyyymmdd'), to_date('20190701', 'yyyymmdd') From DUAL
  Union All Select '0000541522', 'MG', to_date('20061101', 'yyyymmdd'), to_date('20130101', 'yyyymmdd') From DUAL
  Union All Select '0000776709', 'MG', to_date('20170401', 'yyyymmdd'), to_date('20200831', 'yyyymmdd') From DUAL
  Union All Select '0000561243', 'MG', to_date('20110701', 'yyyymmdd'), to_date('20200831', 'yyyymmdd') From DUAL
  Union All Select '0000732336', 'AF', to_date('20171101', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000549376', 'MG', to_date('20070801', 'yyyymmdd'), to_date('20200831', 'yyyymmdd') From DUAL
  Union All Select '0000772028', 'MG', to_date('20170201', 'yyyymmdd'), to_date('20190301', 'yyyymmdd') From DUAL
  Union All Select '0000716237', 'MG', to_date('20150201', 'yyyymmdd'), to_date('20160801', 'yyyymmdd') From DUAL
  Union All Select '0000565742', 'MG', to_date('20080901', 'yyyymmdd'), to_date('20200831', 'yyyymmdd') From DUAL
  Union All Select '0000562459', 'MG', to_date('20080801', 'yyyymmdd'), to_date('20200831', 'yyyymmdd') From DUAL
  Union All Select '0000444799', 'AF', to_date('20131001', 'yyyymmdd'), to_date('20170501', 'yyyymmdd') From DUAL
  Union All Select '0000322256', 'MG', to_date('20080101', 'yyyymmdd'), to_date('20101231', 'yyyymmdd') From DUAL
  Union All Select '0000425673', 'MG', to_date('20070701', 'yyyymmdd'), to_date('20141001', 'yyyymmdd') From DUAL
  Union All Select '0000686713', 'MG', to_date('20140401', 'yyyymmdd'), to_date('20170108', 'yyyymmdd') From DUAL
  Union All Select '0000633474', 'MG', to_date('20120701', 'yyyymmdd'), to_date('20150301', 'yyyymmdd') From DUAL
  Union All Select '0000780506', 'AF', to_date('20180101', 'yyyymmdd'), to_date('20190927', 'yyyymmdd') From DUAL
  Union All Select '0000783777', 'AF', to_date('20171001', 'yyyymmdd'), to_date('20190724', 'yyyymmdd') From DUAL
  Union All Select '0000693538', 'AF', to_date('20181203', 'yyyymmdd'), to_date('20200831', 'yyyymmdd') From DUAL
  Union All Select '0000292130', 'ADV', to_date('20170206', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000760399', 'ADV', to_date('20160815', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000818901', 'AF', to_date('20190903', 'yyyymmdd'), to_date('20200103', 'yyyymmdd') From DUAL
  Union All Select '0000752673', 'AF', to_date('20191021', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000752085', 'AF', to_date('20200106', 'yyyymmdd'), to_date('20200831', 'yyyymmdd') From DUAL
  Union All Select '0000436760', 'ADV', to_date('20011101', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000529430', 'MG', to_date('20200106', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000296692', 'MG', to_date('20200601', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000837709', 'MG', to_date('20201005', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000838308', 'AF', to_date('20201102', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000838571', 'AF', to_date('20201109', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000838656', 'MG', to_date('20201111', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000364856', 'MG', to_date('20201116', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000841644', 'AF', to_date('20210315', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000842004', 'MG', to_date('20210419', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
)

Select
  adv_dates.id_number
  , entity.report_name
  , entity.record_status_code
  , team
  , adv_dates.start_dt
  , adv_dates.stop_dt
From adv_dates adv_dates
Inner Join entity On entity.id_number = adv_dates.id_number
Order By entity.report_name Asc
;

-- Check results
Select *
From mv_past_ksm_gos
;

