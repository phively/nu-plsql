CREATE OR REPLACE VIEW V_KSM_REUNION_MILESTONE_2 AS
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
group by gt.id_number)

--- Commitments - We want annual fund (CRU), but since we wants committments, we wants the pledges
,c as (select gt.id_number,
sum(Case When gt.cru_flag = 'Y' and gt.fiscal_year = '2019' Then gt.hh_credit Else 0 End) as total_committment_19,
sum(Case When gt.cru_flag = 'Y' and gt.fiscal_year = '2020' Then gt.hh_credit Else 0 End) as total_committment_20,
sum(Case When gt.cru_flag = 'Y' and gt.fiscal_year = '2021' Then gt.hh_credit Else 0 End) as total_committment_21,
sum(Case When gt.cru_flag = 'Y' and gt.fiscal_year = '2022' Then gt.hh_credit Else 0 End) as total_committment_22,
sum(Case When gt.cru_flag = 'Y' and gt.fiscal_year = '2023' Then gt.hh_credit Else 0 End) as total_committment_23
from gt
--- Exclude Pledge Payments
Where gt.tx_gypm_ind <> 'Y'
group by gt.id_number),

stewardship as (select gt.id_number
   , sum(Case When gt.cru_flag = 'Y' and gt.fiscal_year = '2019'     Then hh_stewardship_credit Else 0 End) As stewardship_19
    , sum(Case When gt.cru_flag = 'Y' and gt.fiscal_year = '2020' Then hh_stewardship_credit Else 0 End) As stewardship_20
    , sum(Case When gt.cru_flag = 'Y' and gt.fiscal_year = '2021' Then hh_stewardship_credit Else 0 End) As stewardship_21
    , sum(Case When gt.cru_flag = 'Y' and gt.fiscal_year = '2022' Then hh_stewardship_credit Else 0 End) As stewardship_22
    , sum(Case When gt.cru_flag = 'Y' and gt.fiscal_year = '2023' Then hh_stewardship_credit Else 0 End) As stewardship_23
from gt
group by gt.id_number),

--- Bringing together - CRU Cash, total cash and committments
final_giving as (select distinct d.id_number,
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
c.total_committment_23,
stewardship.stewardship_19,
stewardship.stewardship_20,
stewardship.stewardship_21,
stewardship.stewardship_22,
stewardship.stewardship_23
from rpt_pbh634.v_entity_ksm_degrees d
left join cru on cru.id_number = d.id_number
left join c on c.id_number = d.id_number
left join stewardship on stewardship.id_number = d.id_number),


final_query as (SELECT DISTINCT
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
,fg.stewardship_19
,fg.stewardship_20
,fg.stewardship_21
,fg.stewardship_22
,fg.stewardship_23
,case when fg.cru_cash_19 > 0 then 'Y' end as donor_af_FY_19
,case when fg.cru_cash_20 > 0 then 'Y' end as donor_af_FY_20
,case when fg.cru_cash_21 > 0 then 'Y' end as donor_af_FY_21
,case when fg.cru_cash_22 > 0 then 'Y' end as donor_af_FY_22
,case when fg.cru_cash_23 > 0 then 'Y' end as donor_af_FY_23
FROM A
Inner Join KSM_DEGREES d on d.id_number = a.id_number
left join final_giving fg on fg.id_number = a.id_number
left join REUNION_2023_PARTICIPANTS r23 on r23.id_number = a.id_number
left join REUNION_2022_PARTICIPANTS r221 on r221.id_number = a.id_number
left join REUNION_2022_PARTICIPANTS_2 r222 on r222.id_number = a.id_number
left join REUNION_2019_PARTICIPANTS r19 on r19.id_number = a.id_number)


/*
-- Example: union to dedupe, 2 columns subquery with ID and MILESTONE_YEAR
-- This subquery becomes your base table in the final query
SELECT ID_NUMBER, MILESTONE_YEAR
FROM final_query FQ
WHERE FQ.REUNION_1ST_MILESTONE IS NULL OR FQ.REUNION_5TH_MILESTONE IS NULL
UNION
SELECT ID_NUMBER, 'Reunion_1ST_Milestone'
FROM final_query FQ
WHERE FQ.REUNION_1ST_MILESTONE IS NOT NULL AND FQ.REUNION_5TH_MILESTONE IS NOT NULL
UNION
SELECT ID_NUMBER, 'Reunion_5TH_Milestone'
FROM final_query FQ
WHERE FQ.REUNION_1ST_MILESTONE IS NOT NULL AND FQ.REUNION_5TH_MILESTONE IS NOT NULL



Unions to consider the following 1st and 5th issue

1. Entity went to either the 1st OR their 5th!

WHERE FQ.REUNION_1ST_MILESTONE IS NOT NULL OR FQ.REUNION_5TH_MILESTONE IS NOT NULL

2. Entity went to BOTH the 1st OR 5th

WHERE FQ.REUNION_1ST_MILESTONE IS NOT NULL AND FQ.REUNION_5TH_MILESTONE IS NOT NULL

3. Entity not part of the issue

WHERE FQ.REUNION_1ST_MILESTONE IS NULL OR FQ.REUNION_5TH_MILESTONE IS NULL


*/


SELECT DISTINCT
 fq.id_number
,fq.PROGRAM
,fq.PROGRAM_GROUP
,fq.class_year
--- Vertical Stacking ofthe Data
,case when fq.Reunion_1ST_MILESTONE is not null then 'Reunion 1ST MILESTONE'
when fq.Reunion_5TH_MILESTONE is not null then 'Reunion 5TH MILESTONE'
when fq.Reunion_10TH_MILESTONE is not null then 'Reunion 10TH MILESTONE'
when fq.Reunion_15TH_MILESTONE is not null then 'Reunion 15TH MILESTONE'
when fq.Reunion_20TH_MILESTONE is not null then 'Reunion 20TH MILESTONE'
when fq.Reunion_25TH_MILESTONE is not null then 'Reunion 25TH MILESTONE'
when fq.Reunion_30TH_MILESTONE is not null then 'Reunion 30TH MILESTONE'
when fq.Reunion_35TH_MILESTONE is not null then 'Reunion 35TH MILESTONE'
when fq.Reunion_40TH_MILESTONE is not null then 'Reunion 40TH MILESTONE'
when fq.Reunion_45TH_MILESTONE is not null then 'Reunion 45TH MILESTONE'
when fq.Reunion_45TH_MILESTONE is not null then 'Reunion 50TH MILESTONE'
End as Milestone_year
--- add an eligible flag - used for Tableau later
,case when fq.id_number is not null then 'Y' end as eligible_IND
,fq.cash_19
,fq.cash_20
,fq.cash_21
,fq.cash_22
,fq.cash_23
,fq.cru_cash_19
,fq.cru_cash_20
,fq.cru_cash_21
,fq.cru_cash_22
,fq.cru_cash_23
,fq.total_committment_19
,fq.total_committment_20
,fq.total_committment_21
,fq.total_committment_22
,fq.total_committment_23
,fq.stewardship_19
,fq.stewardship_20
,fq.stewardship_21
,fq.stewardship_22
,fq.stewardship_23
,fq.donor_af_FY_19
,fq.donor_af_FY_20
,fq.donor_af_FY_21
,fq.donor_af_FY_22
,fq.donor_af_FY_23
FROM final_query fq
WHERE FQ.REUNION_1ST_MILESTONE IS NULL OR FQ.REUNION_5TH_MILESTONE IS NULL

--- Have to Union All for 1st and 5th

--- I intentionally want dupes for those that attended both 1st and 5th.
--- I will use the dupes for my dataset in Tableau.

UNION ALL

select fq.id_number
,fq.PROGRAM
,fq.PROGRAM_GROUP
,fq.class_year
--- Vertical Stacking ofthe Data
,case when fq.Reunion_1ST_MILESTONE is not null then 'Reunion 1ST MILESTONE'
End as Milestone_year
--- add an eligible flag - used for Tableau later
,case when fq.id_number is not null then 'Y' end as eligible_IND
,fq.cash_19
,fq.cash_20
,fq.cash_21
,fq.cash_22
,fq.cash_23
,fq.cru_cash_19
,fq.cru_cash_20
,fq.cru_cash_21
,fq.cru_cash_22
,fq.cru_cash_23
,fq.total_committment_19
,fq.total_committment_20
,fq.total_committment_21
,fq.total_committment_22
,fq.total_committment_23
,fq.stewardship_19
,fq.stewardship_20
,fq.stewardship_21
,fq.stewardship_22
,fq.stewardship_23
,fq.donor_af_FY_19
,fq.donor_af_FY_20
,fq.donor_af_FY_21
,fq.donor_af_FY_22
,fq.donor_af_FY_23
FROM final_query FQ
--- Went to both 1st and 5th milestone Reunions
WHERE FQ.REUNION_1ST_MILESTONE IS NOT NULL AND FQ.REUNION_5TH_MILESTONE IS NOT NULL

UNION ALL

select fq.id_number
,fq.PROGRAM
,fq.PROGRAM_GROUP
,fq.class_year
--- Vertical Stacking ofthe Data
, case when fq.Reunion_5TH_MILESTONE is not null then 'Reunion 5TH MILESTONE'
End as Milestone_year
--- add an eligible flag - used for Tableau later
,case when fq.id_number is not null then 'Y' end as eligible_IND
,fq.cash_19
,fq.cash_20
,fq.cash_21
,fq.cash_22
,fq.cash_23
,fq.cru_cash_19
,fq.cru_cash_20
,fq.cru_cash_21
,fq.cru_cash_22
,fq.cru_cash_23
,fq.total_committment_19
,fq.total_committment_20
,fq.total_committment_21
,fq.total_committment_22
,fq.total_committment_23
,fq.stewardship_19
,fq.stewardship_20
,fq.stewardship_21
,fq.stewardship_22
,fq.stewardship_23
,fq.donor_af_FY_19
,fq.donor_af_FY_20
,fq.donor_af_FY_21
,fq.donor_af_FY_22
,fq.donor_af_FY_23
FROM final_query FQ
WHERE FQ.REUNION_1ST_MILESTONE IS NOT NULL AND FQ.REUNION_5TH_MILESTONE IS NOT NULL


UNION

select fq.id_number
,fq.PROGRAM
,fq.PROGRAM_GROUP
,fq.class_year
--- Vertical Stacking ofthe Data
,case when fq.Reunion_1ST_MILESTONE is not null then 'Reunion 1ST MILESTONE'
when fq.Reunion_5TH_MILESTONE is not null then 'Reunion 5TH MILESTONE'
when fq.Reunion_10TH_MILESTONE is not null then 'Reunion 10TH MILESTONE'
when fq.Reunion_15TH_MILESTONE is not null then 'Reunion 15TH MILESTONE'
when fq.Reunion_20TH_MILESTONE is not null then 'Reunion 20TH MILESTONE'
when fq.Reunion_25TH_MILESTONE is not null then 'Reunion 25TH MILESTONE'
when fq.Reunion_30TH_MILESTONE is not null then 'Reunion 30TH MILESTONE'
when fq.Reunion_35TH_MILESTONE is not null then 'Reunion 35TH MILESTONE'
when fq.Reunion_40TH_MILESTONE is not null then 'Reunion 40TH MILESTONE'
when fq.Reunion_45TH_MILESTONE is not null then 'Reunion 45TH MILESTONE'
when fq.Reunion_45TH_MILESTONE is not null then 'Reunion 50TH MILESTONE'
End as Milestone_year
--- add an eligible flag - used for Tableau later
,case when fq.id_number is not null then 'Y' end as eligible_IND
,fq.cash_19
,fq.cash_20
,fq.cash_21
,fq.cash_22
,fq.cash_23
,fq.cru_cash_19
,fq.cru_cash_20
,fq.cru_cash_21
,fq.cru_cash_22
,fq.cru_cash_23
,fq.total_committment_19
,fq.total_committment_20
,fq.total_committment_21
,fq.total_committment_22
,fq.total_committment_23
,fq.stewardship_19
,fq.stewardship_20
,fq.stewardship_21
,fq.stewardship_22
,fq.stewardship_23
,fq.donor_af_FY_19
,fq.donor_af_FY_20
,fq.donor_af_FY_21
,fq.donor_af_FY_22
,fq.donor_af_FY_23
FROM final_query FQ
WHERE FQ.REUNION_1ST_MILESTONE IS NOT NULL OR FQ.REUNION_5TH_MILESTONE IS NOT NULL
;
