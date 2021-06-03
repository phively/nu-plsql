-- Dean's Weekly gifts this week

With

-- ** Update dates before running **

dts As (
  Select
      to_date('20210517', 'yyyymmdd') As start_dt
    , to_date('20210524', 'yyyymmdd') As stop_dt
  From DUAL
)

, gt As (
  Select *
  From rpt_pbh634.v_ksm_giving_trans
)

-- Pulling all associated donors related to a gift

, pre_ad As (
  Select Distinct gt.tx_number
  , case when gt.anonymous IN ('1', '2', '3') then 'Anonymous' else entity.pref_mail_name end as pref_mail_name
  From gt
  Inner Join entity On gt.id_number = entity.id_Number
)

, count_anonymous AS (
select tx_number
      , count(pref_mail_name) as pref_mail_name_counts
      , sum(case when pref_mail_name = 'Anonymous' then 1 else 0 end) as anonymous_counts 
from pre_ad
group by tx_number
)

, final_names AS (
select pre_ad.tx_number
      ,pre_ad.pref_mail_name
      ,ca.pref_mail_name_counts
      ,ca.anonymous_counts
FROM pre_ad
INNER JOIN count_anonymous ca ON ca.tx_number = pre_ad.tx_number 
WHERE ca.pref_mail_name_counts = ca.anonymous_counts
OR pre_ad.pref_mail_name <> 'Anonymous' 
)

, ad As (
  Select tx_number
        , listagg(pref_mail_name, chr(13)) Within Group (order by pref_mail_name) as all_associated_donors
  From final_names
  Group By tx_number
)

, payment_years As (
  Select
    ps.payment_schedule_pledge_nbr
    , count(distinct extract(year from rpt_pbh634.ksm_pkg.to_date2(ps.payment_schedule_date, 'yyyymmdd'))) As payment_schedule_year_count
  From payment_schedule ps 
  Group By ps.payment_schedule_pledge_nbr
)

-- Base Table
Select Distinct
    gft.tx_number
  , gft.id_number
  , gft.tx_gypm_ind
  , tms_rt.short_desc As record_type
  , entity.pref_mail_name As primary_donor
  , ad.all_associated_donors
  , gft.date_of_record
  , gft.allocation_code
  , gft.alloc_short_name
  , NULL As empty_column
  , gft.legal_amount
  , py.payment_schedule_year_count  
  , prp.proposal_manager
From gt gft
Cross Join dts
Inner Join ad On gft.tx_number = ad.tx_number
Inner Join entity On gft.id_number = entity.id_number
Inner Join tms_record_type tms_rt On tms_rt.record_type_code = entity.record_type_code
Left Join rpt_pbh634.v_ksm_proposal_history prp On gft.proposal_id = prp.proposal_id
Left Join nu_gft_trp_gifttrans g On gft.tx_number = g.tx_number
Left Join payment_years py On gft.tx_number = py.payment_schedule_pledge_nbr
Where
  -- Only in the date range
 (
        (gft.date_of_record Between dts.start_dt And dts.stop_dt)
     Or (g.first_processed_date Between dts.start_dt And dts.stop_dt)
 )
  And gft.fiscal_year = '2021'
  -- Only $10K+
  And gft.legal_amount >= 10000
  -- Only outright gifts and pledges; ignore payments, match
  And gft.tx_gypm_ind In ('G', 'P')
Order By
  gft.legal_amount Desc
, gft.date_of_record Desc
