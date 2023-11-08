CREATE OR REPLACE VIEW V_KSM_REUNION_MILESTONE_RECAP AS 

WITH a AS (SELECT *
FROM AFFILIATION A
WHERE A.AFFIL_CODE = 'KM'
AND A.AFFIL_LEVEL_CODE = 'RG')

---- Reunion Participants

--- Reunion 2019

,REUNION_2019_PARTICIPANTS AS (
Select ep_participant.id_number,
ep_event.event_id
From ep_event
Left Join EP_Participant
ON ep_participant.event_id = ep_event.event_id
where ep_event.event_id = '21120'
)

--- Weekend 1: Make up Reunions for 2020 and 2021 

,REUNION_2022_PARTICIPANTS AS (
Select ep_participant.id_number
From ep_event
Left Join EP_Participant
ON ep_participant.event_id = ep_event.event_id
Where ep_event.event_name Like '%KSM 2022 Reunion Weekend One - April 23 & 24%'
)

--- Weekend 2: the "Real 2022 Reunion" 

,REUNION_2022_PARTICIPANTS_2 AS (
Select ep_participant.id_number
From ep_event
Left Join EP_Participant
ON ep_participant.event_id = ep_event.event_id
Where ep_event.event_name Like '%KSM 2022 Reunion Weekend Two - April 30 & May 1st%'
)

--- Reunion 2023 

,REUNION_2023_PARTICIPANTS AS (
Select ep_participant.id_number
From ep_event
Left Join EP_Participant
ON ep_participant.event_id = ep_event.event_id
Where ep_event.event_name Like '%KSM23 Reunion Weekend%')

,KSM_DEGREES AS (
 SELECT
   KD.ID_NUMBER
   ,KD.PROGRAM
   ,KD.PROGRAM_GROUP
   ,KD.CLASS_SECTION
   ,KD.first_masters_year
 FROM RPT_PBH634.V_ENTITY_KSM_DEGREES KD
 WHERE KD."PROGRAM" IN ('EMP', 'EMP-FL', 'EMP-IL', 'EMP-CAN', 'EMP-GER', 'EMP-HK', 'EMP-ISR', 'EMP-JAN', 'EMP-CHI', 'FT', 'FT-1Y', 'FT-2Y', 'FT-CB', 'FT-EB', 'FT-JDMBA', 'FT-MMGT', 'FT-MMM', 'FT-MBAi', 'TMP', 'TMP-SAT',
'TMP-SATXCEL', 'TMP-XCEL')
)
-- Using Paul's Transaction View - Only want $$$ Since 2019
,gt as (select *
from rpt_pbh634.v_ksm_giving_trans_hh
where rpt_pbh634.v_ksm_giving_trans_hh.fiscal_year >= 2019)

--- AF = Current Use - No Pledges
--- Cash = Everything - No Pledges 

,CRU as (Select
  gt.id_number 
  , sum(Case When gt.fiscal_year = '2019' and gt.cru_flag = 'Y' Then gt.hh_credit Else 0 END) as cru_cash_19
  , sum(Case When gt.fiscal_year = '2020' and gt.cru_flag = 'Y' Then gt.hh_credit Else 0 END) as cru_cash_20
  , sum(Case When gt.fiscal_year = '2021' and gt.cru_flag = 'Y' Then gt.hh_credit Else 0 END) as cru_cash_21
  , sum(Case When gt.fiscal_year = '2022' and gt.cru_flag = 'Y' Then gt.hh_credit Else 0 END) as cru_cash_22
  , sum(Case When gt.fiscal_year = '2023' and gt.cru_flag = 'Y' Then gt.hh_credit Else 0 END) as cru_cash_23
  -- casj 
  , sum(Case When gt.fiscal_year = '2019' Then gt.hh_credit Else 0 END) as cash_19
  , sum(Case When gt.fiscal_year = '2020' Then gt.hh_credit Else 0 END) as cash_20
  , sum(Case When gt.fiscal_year = '2021' Then gt.hh_credit Else 0 END) as cash_21
  , sum(Case When gt.fiscal_year = '2022' Then gt.hh_credit Else 0 END) as cash_22
  , sum(Case When gt.fiscal_year = '2023' Then gt.hh_credit Else 0 END) as cash_23
From gt
--- Does not equal pledges and 2019 onwards
Where gt.tx_gypm_ind <> 'P'
  And gt.fiscal_year >= 2019
Group By gt.id_number)

--- Commitments - We want annual fund (CRU), but since we wants committments, we wants the pledges 
,c as (select gt.id_number,
sum(Case When gt.cru_flag = 'Y' and gt.fiscal_year = '2019' Then gt.hh_credit Else 0 End) as total_committment_19,
sum(Case When gt.cru_flag = 'Y' and gt.fiscal_year = '2020' Then gt.hh_credit Else 0 End) as total_committment_20,
sum(Case When gt.cru_flag = 'Y' and gt.fiscal_year = '2021' Then gt.hh_credit Else 0 End) as total_committment_21,
sum(Case When gt.cru_flag = 'Y' and gt.fiscal_year = '2022' Then gt.hh_credit Else 0 End) as total_committment_22,
sum(Case When gt.cru_flag = 'Y' and gt.fiscal_year = '2023' Then gt.hh_credit Else 0 End) as total_committment_23
from gt
group by gt.id_number)

--- Bringing together - CRU Cash, total cash and committments 
,final_giving as (select distinct d.id_number,
cru.cru_cash_19,
cru.cru_cash_20,
cru.cru_cash_21,
cru.cru_cash_22,
cru.cru_cash_23,
cru.cash_19,
cru.cash_20,
cru.cash_21,
cru.cash_22,
cru.cash_23,
c.total_committment_19,
c.total_committment_20,
c.total_committment_21,
c.total_committment_22,
c.total_committment_23
from rpt_pbh634.v_entity_ksm_degrees d
left join cru on cru.id_number = d.id_number
left join c on c.id_number = d.id_number)


SELECT DISTINCT 
 D.id_number
,D.PROGRAM
,D.PROGRAM_GROUP
,A.class_year

/* 
MILESTONE ATTENDANCE OVER THE PAST 5 YEARS 
THIS CASE WHEN WILL ALLOW ME TO DO TOTAL COUNTS OF ATTENDEES PLUS PARTICIPATION RATES BY CLASS
EXAMPLE: 

--- 50TH MILESTONES

1969 = REUNION 2019
1970 = REUNION 2020 (AKA REUNION WEEKEND 1 OF 2022)
1971 = REUNION 2021 (AKA REUNION WEEKEND 1 OF 2021)
1972 = REUNION 2022 (AKA REUNION WEEKEND 2 OF 2022)
1973 = REUNION 2023 (AKA REUNION WEEKEND 3 OF 2022)
*/

,CASE WHEN A.CLASS_YEAR = '1969' AND r19.id_number is not null  
 OR (A.CLASS_YEAR = '1970' AND r221.id_number is not null)
 OR (A.CLASS_YEAR = '1971' AND r221.id_number is not null)
 OR (A.CLASS_YEAR = '1972' AND r222.id_number is not null)
 OR (A.CLASS_YEAR = '1973' AND r23.id_number is not null) then 'Y' end as Reunion_50TH_MILESTONE
--- 45TH MILESTONES
,CASE WHEN A.CLASS_YEAR = '1974' AND r19.id_number is not null  
 OR (A.CLASS_YEAR = '1975' AND r221.id_number is not null)
 OR (A.CLASS_YEAR = '1976' AND r221.id_number is not null)
 OR (A.CLASS_YEAR = '1977' AND r222.id_number is not null)
 OR (A.CLASS_YEAR = '1978' AND r23.id_number is not null) then 'Y' end as Reunion_45TH_MILESTONE
  
 
 --- 40TH MILESTONES
,CASE WHEN A.CLASS_YEAR = '1979' AND r19.id_number is not null  
 OR (A.CLASS_YEAR = '1980' AND r221.id_number is not null)
 OR (A.CLASS_YEAR = '1981' AND r221.id_number is not null)
 OR (A.CLASS_YEAR = '1982' AND r222.id_number is not null)
 OR (A.CLASS_YEAR = '1983' AND r23.id_number is not null) then 'Y' end as Reunion_40TH_MILESTONE
 
  --- 35TH MILESTONES
,CASE WHEN A.CLASS_YEAR = '1984' AND r19.id_number is not null  
 OR (A.CLASS_YEAR = '1985' AND r221.id_number is not null)
 OR (A.CLASS_YEAR = '1986' AND r221.id_number is not null)
 OR (A.CLASS_YEAR = '1987' AND r222.id_number is not null)
 OR (A.CLASS_YEAR = '1988' AND r23.id_number is not null) then 'Y' end as Reunion_35TH_MILESTONE
  --- 30TH MILESTONES
,CASE WHEN A.CLASS_YEAR = '1989' AND r19.id_number is not null  
 OR (A.CLASS_YEAR = '1990' AND r221.id_number is not null)
 OR (A.CLASS_YEAR = '1991' AND r221.id_number is not null)
 OR (A.CLASS_YEAR = '1992' AND r222.id_number is not null)
 OR (A.CLASS_YEAR = '1993' AND r23.id_number is not null) then 'Y' end as Reunion_30TH_MILESTONE
   --- 25TH MILESTONES
,CASE WHEN A.CLASS_YEAR = '1994' AND r19.id_number is not null  
 OR (A.CLASS_YEAR = '1995' AND r221.id_number is not null)
 OR (A.CLASS_YEAR = '1996' AND r221.id_number is not null)
 OR (A.CLASS_YEAR = '1997' AND r222.id_number is not null)
 OR (A.CLASS_YEAR = '1998' AND r23.id_number is not null) then 'Y' end as Reunion_25TH_MILESTONE
 
    --- 20TH MILESTONES
,CASE WHEN A.CLASS_YEAR = '1999' AND r19.id_number is not null  
 OR (A.CLASS_YEAR = '2000' AND r221.id_number is not null)
 OR (A.CLASS_YEAR = '2001' AND r221.id_number is not null)
 OR (A.CLASS_YEAR = '2002' AND r222.id_number is not null)
 OR (A.CLASS_YEAR = '2003' AND r23.id_number is not null) then 'Y' end as Reunion_20TH_MILESTONE
 
 
     --- 15TH MILESTONES
,CASE WHEN A.CLASS_YEAR = '2004' AND r19.id_number is not null  
 OR (A.CLASS_YEAR = '2005' AND r221.id_number is not null)
 OR (A.CLASS_YEAR = '2006' AND r221.id_number is not null)
 OR (A.CLASS_YEAR = '2007' AND r222.id_number is not null)
 OR (A.CLASS_YEAR = '2008' AND r23.id_number is not null) then 'Y' end as Reunion_15TH_MILESTONE
 
      --- 10TH MILESTONES
,CASE WHEN A.CLASS_YEAR = '2009' AND r19.id_number is not null  
 OR (A.CLASS_YEAR = '2010' AND r221.id_number is not null)
 OR (A.CLASS_YEAR = '2011' AND r221.id_number is not null)
 OR (A.CLASS_YEAR = '2012' AND r222.id_number is not null)
 OR (A.CLASS_YEAR = '2013' AND r23.id_number is not null) then 'Y' end as Reunion_10TH_MILESTONE
 
       --- 5TH MILESTONES
,CASE WHEN A.CLASS_YEAR = '2014' AND r19.id_number is not null  
 OR (A.CLASS_YEAR = '2015' AND r221.id_number is not null)
 OR (A.CLASS_YEAR = '2016' AND r221.id_number is not null)
 OR (A.CLASS_YEAR = '2017' AND r222.id_number is not null)
 OR (A.CLASS_YEAR = '2018' AND r23.id_number is not null) then 'Y' end as Reunion_5TH_MILESTONE
 
   --- 1st MILESTONES
,CASE WHEN A.CLASS_YEAR = '2018' AND r19.id_number is not null  
 OR (A.CLASS_YEAR = '2019' AND r221.id_number is not null)
 OR (A.CLASS_YEAR = '2020' AND r221.id_number is not null)
 OR (A.CLASS_YEAR = '2021' AND r222.id_number is not null)
 OR (A.CLASS_YEAR = '2022' AND r23.id_number is not null) then 'Y' end as Reunion_1ST_MILESTONE
,fg.cash_19
,fg.cash_20
,fg.cash_21
,fg.cash_22
,fg.cash_23
--- CRU Cash 
,fg.cru_cash_19 
,fg.cru_cash_20 
,fg.cru_cash_21 
,fg.cru_cash_22 
,fg.cru_cash_23
--- Committment 
,fg.total_committment_19
,fg.total_committment_20
,fg.total_committment_21
,fg.total_committment_22
,fg.total_committment_23
FROM A
Inner Join KSM_DEGREES d on d.id_number = a.id_number
left join final_giving fg on fg.id_number = a.id_number 
left join REUNION_2023_PARTICIPANTS r23 on r23.id_number = a.id_number
left join REUNION_2022_PARTICIPANTS r221 on r221.id_number = a.id_number
left join REUNION_2022_PARTICIPANTS_2 r222 on r222.id_number = a.id_number
left join REUNION_2019_PARTICIPANTS r19 on r19.id_number = a.id_number

