-- Dean's Weekly gifts this week

With

-- ** Update dates before running **

dts As (
  Select
      to_date('20200221', 'yyyymmdd') As start_dt
    , to_date('20200228', 'yyyymmdd') As stop_dt
  From DUAL
)

, gt As (
  Select *
  From rpt_pbh634.v_ksm_giving_trans
)

-- Pulling all associated donors related to a gift

, ad As (
SELECT  gt.tx_number
      , listagg(entity.pref_mail_name, chr(13)) Within Group (order by entity.pref_mail_name) as all_associated_donors
From gt
Inner Join entity ON gt.id_number = entity.id_number
Group By gt.tx_number
)


-- Base Table
Select
    gft.id_number
  , gft.tx_number
  , gft.tx_gypm_ind
  , tms_rt.short_desc As record_type
  , entity.pref_mail_name As primary_donor
  , ad.all_associated_donors
  , gft.date_of_record
  , gft.allocation_code
  , gft.alloc_short_name
  , NULL As empty_column
  , gft.legal_amount
  , prp.proposal_manager
From gt gft
Cross Join dts
Inner Join ad On gft.tx_number = ad.tx_number
Inner Join entity On gft.id_number = entity.id_number
Inner Join tms_record_type tms_rt On tms_rt.record_type_code = entity.record_type_code
Left Join rpt_pbh634.v_ksm_proposal_history prp On gft.proposal_id = prp.proposal_id
Where
  -- Only in the date range
  gft.date_of_record Between dts.start_dt And dts.stop_dt
  -- Only $10K+
  And gft.legal_amount >= 10000
  -- Only outright gifts and pledges; ignore payments, match
  And gft.tx_gypm_ind In ('G', 'P')
Order By
  gft.legal_amount Desc
, gft.date_of_record Desc
