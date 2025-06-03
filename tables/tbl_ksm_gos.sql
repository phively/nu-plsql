-- Drop old materialized view
Drop Materialized View tbl_ksm_gos;

-- Create new materialized view
Create Materialized View tbl_ksm_gos As

With

-- Data table; update as needed
dates As (
  Select 'notarealid' As donor_id, 'notateam' As team, NULL As start_dt, NULL As stop_dt From DUAL
  Union All Select '0000562844', 'MG', to_date('20080808', 'yyyymmdd'), to_date('20150601', 'yyyymmdd') From DUAL
  Union All Select '0000235591', 'MG', to_date('20160501', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
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
  Union All Select '0000784241', 'AF', to_date('20170901', 'yyyymmdd'), to_date('20221018', 'yyyymmdd') From DUAL
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
  Union All Select '0000768730', 'ADV', to_date('20161205', 'yyyymmdd'), to_date('20221130', 'yyyymmdd') From DUAL
  Union All Select '0000818901', 'AF', to_date('20190903', 'yyyymmdd'), to_date('20200103', 'yyyymmdd') From DUAL
  Union All Select '0000752673', 'AF', to_date('20191021', 'yyyymmdd'), to_date('20230605', 'yyyymmdd') From DUAL
  Union All Select '0000752085', 'AF', to_date('20200106', 'yyyymmdd'), to_date('20200831', 'yyyymmdd') From DUAL
  Union All Select '0000436760', 'ADV', to_date('20011101', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000529430', 'MG', to_date('20200106', 'yyyymmdd'), to_date('20221109', 'yyyymmdd') From DUAL
  Union All Select '0000296692', 'MG', to_date('20200601', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000837709', 'MG', to_date('20201005', 'yyyymmdd'), to_date('20230714', 'yyyymmdd') From DUAL
  Union All Select '0000838308', 'AF', to_date('20201102', 'yyyymmdd'), to_date('20221122', 'yyyymmdd') From DUAL
  Union All Select '0000838571', 'AF', to_date('20201109', 'yyyymmdd'), to_date('20230208', 'yyyymmdd') From DUAL
  Union All Select '0000838656', 'MG', to_date('20201111', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000364856', 'MG', to_date('20201116', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000841644', 'AF', to_date('20210315', 'yyyymmdd'), to_date('20230814', 'yyyymmdd') From DUAL
  Union All Select '0000842004', 'MG', to_date('20210419', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000857030', 'MG', to_date('20211208', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000777423', 'AR', to_date('20211122', 'yyyymmdd'), to_date('20250314', 'yyyymmdd') From DUAL
  Union All Select '0000860423', 'AF', to_date('20220404', 'yyyymmdd'), to_date('20240920', 'yyyymmdd') From DUAL
  Union All Select '0000819851', 'AF', to_date('20190930', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000887951', 'AF', to_date('20220919', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000889141', 'AF', to_date('20221128', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000889424', 'AF', to_date('20221205', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000809084', 'AR', to_date('20221117', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000757346', 'AF', to_date('20230424', 'yyyymmdd'), to_date('20230915', 'yyyymmdd') From DUAL
  Union All Select '0000767254', 'AF', to_date('20230705', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000897607', 'MG', to_date('20230717', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000311972', 'MG', to_date('20230717', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000910689', 'AF', to_date('20231127', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000911216', 'AF', to_date('20240108', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000911218', 'AF', to_date('20231213', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000521222', 'ADV', to_date('20220119', 'yyyymmdd'), to_date('20250321', 'yyyymmdd') From DUAL
  Union All Select '0000793042', 'ADV', to_date('20220221', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000856353', 'ADV', to_date('20211115', 'yyyymmdd'), to_date('20250103', 'yyyymmdd') From DUAL
  Union All Select '0000712447', 'MG', to_date('20240318', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
  Union All Select '0000888785', 'AF', to_date('20241118', 'yyyymmdd'), to_date(NULL, 'yyyymmdd') From DUAL
)

, user_donor_map As (
  Select NULL As donor_id, NULL As user_id From DUAL
  Union All Select '0000562844', '005Uz000008gxNUIAY' From DUAL
  Union All Select '0000235591', '005Uz000008gwc8IAA' From DUAL
  Union All Select '0000235591', '005Uz000008kAG7IAM' From DUAL
  Union All Select '0000482962', '005Uz000008gs3EIAQ' From DUAL
  Union All Select '0000510455', '005Uz000008gwImIAI' From DUAL
  Union All Select '0000818901', '005Uz000008gvqEIAQ' From DUAL
  Union All Select '0000752673', '005Uz000008gxCeIAI' From DUAL
  Union All Select '0000838571', '005Uz000008gxjpIAA' From DUAL
  Union All Select '0000838656', '005Uz000008gwGOIAY' From DUAL
  Union All Select '0000364856', '005Uz000007VVCAIA4' From DUAL
  Union All Select '0000436760', '005Uz000008gxaQIAQ' From DUAL
  Union All Select '0000292130', '005Uz000001NTiHIAW' From DUAL
  Union All Select '0000609581', '005Uz000008gwGyIAI' From DUAL
  Union All Select '0000565395', '005Uz000008gxayIAA' From DUAL
  Union All Select '0000565395', '005Uz000008kAGVIA2' From DUAL
  Union All Select '0000565395', '005Uz000009OckDIAS' From DUAL
  Union All Select '0000634311', '005Uz000008gy0jIAA' From DUAL
  Union All Select '0000514693', '005Uz000008gxBcIAI' From DUAL
  Union All Select '0000772350', '005Uz000008gwRlIAI' From DUAL
  Union All Select '0000220843', '005Uz000008gwRhIAI' From DUAL
  Union All Select '0000482601', '005Uz000008k9lrIAA' From DUAL
  Union All Select '0000482601', '005Uz000008gxCVIAY' From DUAL
  Union All Select '0000768730', '005Uz000008gvr4IAA' From DUAL
  Union All Select '0000712447', '005Uz000007VVBsIAO' From DUAL
  Union All Select '0000712447', '005Uz000009OkRcIAK' From DUAL
  Union All Select '0000837709', '005Uz000008gxjSIAQ' From DUAL
  Union All Select '0000760399', '005Uz000008gwYHIAY' From DUAL
  Union All Select '0000760399', '005Uz000009O5KnIAK' From DUAL
  Union All Select '0000760399', '005Uz000008kAGGIA2' From DUAL
  Union All Select '0000532713', '005Uz000008gy0IIAQ' From DUAL
  Union All Select '0000819851', '005Uz000008gwGBIAY' From DUAL
  Union All Select '0000842004', '005Uz000007VVCEIA4' From DUAL
  Union All Select '0000740856', '005Uz000008gwHuIAI' From DUAL
  Union All Select '0000777423', '005Uz000008k9m6IAA' From DUAL
  Union All Select '0000777423', '005Uz000008gvoYIAQ' From DUAL
  Union All Select '0000737745', '005Uz000008gvofIAA' From DUAL
  Union All Select '0000780506', '005Uz000008gwy1IAA' From DUAL
  Union All Select '0000311972', '005Uz000008gxiTIAQ' From DUAL
  Union All Select '0000642888', '005Uz000008gy00IAA' From DUAL
  Union All Select '0000888785', '005Dn000007paupIAA' From DUAL
  Union All Select '0000767254', '005Uz0000084GCrIAM' From DUAL
  Union All Select '0000693538', '005Uz000008gwGiIAI' From DUAL
  Union All Select '0000521222', '005Uz000007VVC8IAO' From DUAL
  Union All Select '0000897607', '005Uz000008gxNTIAY' From DUAL
  Union All Select '0000784241', '005Uz000008gwRpIAI' From DUAL
  Union All Select '0000779347', '005Uz000008gkx2IAA' From DUAL
  Union All Select '0000664033', '005Uz000008gwasIAA' From DUAL
  Union All Select '0000841644', '005Uz000008gvsDIAQ' From DUAL
  Union All Select '0000405472', '005Uz000008gwfJIAQ' From DUAL
  Union All Select '0000765494', '005Uz000008gwb1IAA' From DUAL
  Union All Select '0000541522', '005Uz000008gvrWIAQ' From DUAL
  Union All Select '0000776709', '005Uz000008gwHIIAY' From DUAL
  Union All Select '0000783777', '005Uz000008gvqTIAQ' From DUAL
  Union All Select '0000911216', '005Uz000007VVBpIAO' From DUAL
  Union All Select '0000561243', '005Uz000009OoxpIAC' From DUAL
  Union All Select '0000561243', '005Uz000008gkwWIAQ' From DUAL
  Union All Select '0000561243', '005Uz000008k9lUIAQ' From DUAL
  Union All Select '0000732336', '005Uz000007VVBlIAO' From DUAL
  Union All Select '0000860423', '005Uz000008gwyGIAQ' From DUAL
  Union All Select '0000549376', '005Uz000008gxDCIAY' From DUAL
  Union All Select '0000887951', '005Uz000009OozxIAC' From DUAL
  Union All Select '0000887951', '005Uz000007VVBkIAO' From DUAL
  Union All Select '0000529430', '005Uz000008gxiwIAA' From DUAL
  Union All Select '0000752085', '005Uz000008gpQAIAY' From DUAL
  Union All Select '0000910689', '005Uz000008gxiUIAQ' From DUAL
  Union All Select '0000910689', '005Uz000008kAH1IAM' From DUAL
  Union All Select '0000772028', '005Uz000008gwIVIAY' From DUAL
  Union All Select '0000296692', '005Uz000008gvsOIAQ' From DUAL
  Union All Select '0000716237', '005Uz000008gvpyIAA' From DUAL
  Union All Select '0000565742', '005Uz000008gwyYIAQ' From DUAL
  Union All Select '0000889424', '005Uz0000082J3ZIAU' From DUAL
  Union All Select '0000757346', '005Uz000008gkxBIAQ' From DUAL
  Union All Select '0000562459', '005Uz000008gxAoIAI' From DUAL
  Union All Select '0000838308', '005Uz000008gwbIIAQ' From DUAL
  Union All Select '0000444799', '005Uz000008k9lmIAA' From DUAL
  Union All Select '0000322256', '005Uz000008gxaOIAQ' From DUAL
  Union All Select '0000809084', '005Uz000007VVCmIAO' From DUAL
  Union All Select '0000889141', '005Uz000007VVBwIAO' From DUAL
  Union All Select '0000425673', '005Uz000008gxBXIAY' From DUAL
  Union All Select '0000686713', '005Uz000008gwHPIAY' From DUAL
  Union All Select '0000911218', '005Uz000008gxiuIAA' From DUAL
  Union All Select '0000857030', '005Uz000007VVBrIAO' From DUAL
  Union All Select '0000633474', '005Uz000008gwG2IAI' From DUAL
)

Select
  dates.donor_id
  , mve.sort_name
  , dates.team
  , dates.start_dt
  , dates.stop_dt
  , udm.user_id
  , utbl.name As user_name
From dates
Inner Join mv_entity mve
  On mve.donor_id = dates.donor_id
Left Join user_donor_map udm
  On udm.donor_id = dates.donor_id
Left Join stg_alumni.user_tbl utbl
  On utbl.id = udm.user_id
Order By mve.sort_name Asc
;

-- Check results
Select *
From tbl_ksm_gos
;

