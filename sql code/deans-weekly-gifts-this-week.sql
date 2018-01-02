-- Dean's Weekly gifts this week

With

-- Update dates before running
dts As (
  Select
      to_date('20171215', 'yyyymmdd') As start_dt
    , to_date('20180102', 'yyyymmdd') As stop_dt
  From DUAL
)

Select
  gft.id_number
  , gft.tx_number
  , gft.tx_gypm_ind
  , tms_rt.short_desc As record_type
  , entity.pref_mail_name
  , gft.date_of_record
  , gft.allocation_code
  , gft.alloc_short_name
  , gft.legal_amount
  , prp.proposal_manager
From v_ksm_giving_trans gft
Cross Join dts
Inner Join entity On gft.id_number = entity.id_number
Inner Join tms_record_type tms_rt On tms_rt.record_type_code = entity.record_type_code
Left Join v_ksm_proposal_history prp On gft.proposal_id = prp.proposal_id
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
