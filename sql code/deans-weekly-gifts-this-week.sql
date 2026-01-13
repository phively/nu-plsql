-- Dean's Weekly gifts this week
With
-- ** Update dates before running **
dts As (
  Select
      to_date('20260106', 'yyyymmdd') As start_dt
    , to_date('20260112', 'yyyymmdd') As stop_dt
    , 2026 As fiscal_year
  From DUAL
)
-- Pulling all associated donors related to a gift
, pre_ad As (
  Select Distinct
    tx_id
    , Case When t.anonymous_type Is Not NULL Then 'Anonymous' Else t.full_name End As donor_name
    , Case When t.anonymous_type Is Not NULL Then 'Anonymous' Else e.institutional_suffix End As institutional_suffix
  From v_ksm_gifts_ngc t
  Left Join mv_entity e
    On e.donor_id = t.donor_id      
)
, count_anonymous As (
  Select
    tx_id
    , count(donor_name) as credited_donor_name_counts
    , sum(Case When donor_name = 'Anonymous' Then 1 Else 0 End) As anonymous_counts
  From pre_ad
  Group By tx_id
)
, final_names As (
  Select
    pre_ad.tx_id
    , pre_ad.donor_name
    , pre_ad.institutional_suffix
    , ca.credited_donor_name_counts
    , ca.anonymous_counts
  From pre_ad
  Inner Join count_anonymous ca
    On ca.tx_id = pre_ad.tx_id
  Where ca.credited_donor_name_counts = ca.anonymous_counts
    Or pre_ad.donor_name <> 'Anonymous'
)
, ad As (
  Select tx_id
    , listagg(donor_name, chr(13)) Within Group (Order By donor_name) As all_credited_donors
    , listagg(institutional_suffix, chr(13)) Within Group (Order By donor_name) As all_institutional_suffix
  From final_names
  Group By tx_id
)

, all_gift_officers as (
  select 
    v_ksm_gifts_ngc.tx_id,
    -- Aggregate all unique gift officer names (prospect managers first, then LAGMs if different)
    trim(chr(13) from 
      listagg(distinct prospect_manager_name, chr(13)) 
        within group (order by prospect_manager_name) ||
      chr(13) ||
      listagg(distinct case when lagm_name != prospect_manager_name then lagm_name end, chr(13)) 
        within group (order by lagm_name)
    ) as all_gift_officers
  from v_ksm_gifts_ngc
  cross join dts
  -- Join to assignments to get gift officer names
  left join mv_assignments 
    on mv_assignments.donor_id = v_ksm_gifts_ngc.donor_id
  where
    -- Filter to gifts within the date range
    (
      (v_ksm_gifts_ngc.credit_date between dts.start_dt and dts.stop_dt)
      or (v_ksm_gifts_ngc.entry_date between dts.start_dt and dts.stop_dt)
    )
    and v_ksm_gifts_ngc.fiscal_year = dts.fiscal_year
    and v_ksm_gifts_ngc.hard_credit_amount >= 10000
    and v_ksm_gifts_ngc.gypm_ind in ('P', 'G')
  group by v_ksm_gifts_ngc.tx_id
)

-- Base Table
Select
  gt.tx_id
  , gt.source_donor_id
  , gt.opportunity_type
  , gt.gypm_ind
  , gt.source_donor_name
  , ad.all_institutional_suffix
  , ad.all_credited_donors
  , gt.credit_date
  , gt.entry_date
  , Case When abs(gt.credit_date - gt.entry_date) > 14 Then 'CHECK: >2 weeks' Else NULL End As credit_date_vs_entry_date_flag
  , gt.designation_record_id
  , gt.designation_name
  , NULL As empty_column
  , gt.hard_credit_amount
  , Case When gt.gypm_ind = 'P' Then payment_schedule End As payment_schedule
  , Case When mv_proposals.active_proposal_manager_name is not null 
         then mv_proposals.active_proposal_manager_name else all_gift_officers end as manager
From v_ksm_gifts_ngc gt
Cross Join dts
left join mv_proposals 
  on mv_proposals.proposal_record_id = gt.linked_proposal_record_id
left join all_gift_officers
  on all_gift_officers.tx_id = gt.tx_id
Inner Join ad
  On ad.tx_id = gt.tx_id
Where
  -- Only in the date range
 (
        (gt.credit_date Between dts.start_dt And dts.stop_dt)
     Or (gt.entry_date Between dts.start_dt And dts.stop_dt)
 )
And gt.fiscal_year = dts.fiscal_year
And gt.hard_credit_amount >= 10000
And gt.gypm_ind In ('P', 'G')
Order By
  gt.hard_credit_amount Desc
  , gt.credit_date Desc
