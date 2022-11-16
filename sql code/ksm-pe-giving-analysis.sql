create or replace view v_ksm_pe_analysis as
With pe AS (select k.id_number,
       k.role,
       k.committee_title,
       k.short_desc,
       rpt_pbh634.ksm_pkg_tmp.get_fiscal_year (k.start_dt) as FY_Joined_pe,
       k.start_dt,
       k.stop_dt
From table (rpt_pbh634.ksm_pkg_tmp.tbl_committee_privateequity) k),

--- Giving Summary

g as (select n.ID_NUMBER,
n.CASH_CFY,
n.CASH_PFY1,
n.CASH_PFY2,
n.CASH_PFY3,
n.CASH_PFY4,
n.CASH_PFY5,
n.CRU_CFY,
n.CRU_PFY1,
n.CRU_PFY2,
n.CRU_PFY3,
n.CRU_PFY4,
n.CRU_PFY5
from rpt_pbh634.v_ksm_giving_summary n),

--- Subquery to indicate year of joining PE, which will be used for the before/after giving subquery

pe_Give_Ind As (select pe.ID_NUMBER,
Max(Case When cal.curr_fy = FY_Joined_pe Then 'Yes' Else NULL End) as joined_pe_cfy,
Max(Case When cal.curr_fy = FY_Joined_pe + 1 Then 'Yes' Else NULL End) as joined_pe_pfy1,
Max(Case When cal.curr_fy = FY_Joined_pe + 2 Then 'Yes' Else NULL End) as joined_pe_pfy2,
Max(Case When cal.curr_fy = FY_Joined_pe + 3 Then 'Yes' Else NULL End) as joined_pe_pfy3,
Max(Case When cal.curr_fy = FY_Joined_pe + 4 Then 'Yes' Else NULL End) as joined_pe_pfy4,
Max(Case When cal.curr_fy = FY_Joined_pe + 5 Then 'Yes' Else NULL End) as joined_pe_pfy5
from pe
cross join rpt_pbh634.v_current_calendar cal
group BY pe.ID_NUMBER),

--- Count Total PE Years

pe_count As (Select distinct pe.ID_NUMBER,
Sum (cal.curr_fy - FY_Joined_pe) as years_in_pe
from pe
cross join rpt_pbh634.v_current_calendar cal
GROUP BY pe.ID_NUMBER),

before_pe as ( select pe_Give_Ind.id_number,

--- Before Joining PE
Case when pe_Give_Ind.joined_pe_cfy  is not null then g.cash_pfy1
when pe_Give_Ind.joined_pe_pfy1 is not null then g.cash_pfy2
when pe_Give_Ind.joined_pe_pfy2 is not null then g.cash_pfy3
when pe_Give_Ind.joined_pe_pfy3 is not null then g.cash_pfy4
when pe_Give_Ind.joined_pe_pfy4 is not null then g.cash_pfy5  else 0 END as Cash_Year_Before_pe,
Case when pe_Give_Ind.joined_pe_cfy  is not null then g.CRU_PFY1
when pe_Give_Ind.joined_pe_pfy1 is not null then g.CRU_PFY2
when pe_Give_Ind.joined_pe_pfy2 is not null then g.CRU_PFY3
when pe_Give_Ind.joined_pe_pfy3 is not null then g.CRU_PFY4
when pe_Give_Ind.joined_pe_pfy4 is not null then g.CRU_PFY5  else 0 END as CRU_Year_Before_pe
from pe_Give_Ind
left join g on g.id_number = pe_Give_Ind.id_number ),

--- After Joining PE

After_pe as (Select pe_Give_Ind.id_number,
Case when pe_Give_Ind.joined_pe_pfy1 is not null then g.cash_cfy
when pe_Give_Ind.joined_pe_pfy2 is not null then g.cash_pfy1
when pe_Give_Ind.joined_pe_pfy3 is not null then g.cash_pfy2
when pe_Give_Ind.joined_pe_pfy4 is not null then g.cash_pfy3
when pe_Give_Ind.joined_pe_pfy5 is not null then g.cash_pfy4 else 0 END as Cash_Year_After_pe,
Case when pe_Give_Ind.joined_pe_pfy1 is not null then g.cru_cfy
when pe_Give_Ind.joined_pe_pfy2 is not null then g.cru_pfy1
when pe_Give_Ind.joined_pe_pfy3 is not null then g.cru_pfy2
when pe_Give_Ind.joined_pe_pfy4 is not null then g.cru_pfy3
when pe_Give_Ind.joined_pe_pfy5 is not null then g.cru_pfy4 else 0 END as CRU_Year_After_pe
from pe_Give_Ind
left join g on g.id_number = pe_Give_Ind.id_number),

--- Giving in the Year of Joining PE

Year_Joined as (Select pe_Give_Ind.id_number,
Case when pe_Give_Ind.joined_pe_cfy is not null then g.cash_cfy
when pe_Give_Ind.joined_pe_pfy1 is not null then g.cash_pfy1
when pe_Give_Ind.joined_pe_pfy2 is not null then g.cash_pfy2
when pe_Give_Ind.joined_pe_pfy3 is not null then g.cash_pfy3
when pe_Give_Ind.joined_pe_pfy4 is not null then g.cash_pfy4
when pe_Give_Ind.joined_pe_pfy5 is not null then g.cash_pfy5 else 0 END as cash_Year_Joined_pe,
Case when pe_Give_Ind.joined_pe_cfy is not null then g.cru_cfy
when pe_Give_Ind.joined_pe_pfy1 is not null then g.cru_pfy1
when pe_Give_Ind.joined_pe_pfy2 is not null then g.cru_pfy2
when pe_Give_Ind.joined_pe_pfy3 is not null then g.cru_pfy3
when pe_Give_Ind.joined_pe_pfy4 is not null then g.cru_pfy4
when pe_Give_Ind.joined_pe_pfy5 is not null then g.cru_pfy5 else 0 END as CRU_Year_Joined_pe
from pe_Give_Ind
left join g on g.id_number = pe_Give_Ind.id_number)

Select distinct pe.ID_NUMBER,
entity.first_name,
entity.last_name,
--- Start of PE Fiscal Year Date
--- CASH
pe.FY_Joined_PE,
before_pe.Cash_Year_Before_pe,
after_pe.Cash_Year_After_pe,
--- CRU
Before_pe.cru_Year_Before_PE,
Year_Joined.cru_Year_Joined_PE,
After_pe.cru_Year_After_PE,
pe_Give_Ind.joined_pe_cfy,
pe_Give_Ind.joined_pe_pfy1,
pe_Give_Ind.joined_pe_pfy2,
pe_Give_Ind.joined_pe_pfy3,
pe_Give_Ind.joined_pe_pfy4,
pe_Give_Ind.joined_pe_pfy5,
--- KLC Total Years on Record
pe_COUNT.years_in_pe
from pe
left join entity on entity.id_number = pe.id_number
left join pe_Count on pe_Count.ID_NUMBER = pe.ID_NUMBER
left join pe_Give_Ind on pe_Give_Ind.ID_NUMBER = pe.ID_NUMBER
left join before_pe on before_pe.id_number = pe.ID_number
left join after_pe on after_pe.id_number = pe.ID_number
left join Year_Joined on Year_Joined.id_number = pe.ID_number
;
