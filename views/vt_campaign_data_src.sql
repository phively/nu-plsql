-- Combines proposal and giving data for campaign totals

Create Or Replace View vt_campaign_data_src As

With

params As (
  Select
    to_date('20210901', 'yyyymmdd') As campaign_start_dt
  From DUAL
)

, gift_excl As (
  Select '0002872022' As excl From DUAL -- Complexity Institute
)

, prs As (
  Select
    id_number
    , Case When prospect_id <> 0
        Then prospect_id
      End
      As prospect_id
  From nu_prs_trp_prospect
)

(
Select
  'Giving' As data_source
  , gpc.src_donor_id As src_donor_or_hhid
  , gpc.id_number
  , gpc.report_name
  , prs.prospect_id
  , gpc.rcpt_or_plg_number As rcpt_or_proposal_id
  , gpc.transaction_type
  , NULL As proposal_status
  , NULL As ask_date
  , gpc.date_of_record As date_of_record_or_close_dt
  , NULL As ask_amount
  , gpc.amount As legal_or_anticipated_amt
  , gpc.allocation_name As alloc_or_proposal
  , gpc.person_or_org
From rpt_pbh634.v_ksm_giving_post_campaign_ytd gpc
Cross Join params
Left Join prs
  On prs.id_number = gpc.id_number
-- Include/exclude
Where gpc.date_of_record >= params.campaign_start_dt
  And gpc.rcpt_or_plg_number Not In (
    Select excl From gift_excl
  )
) Union (
Select
  'Proposal' As data_source
  , hhf.household_id As src_donor_or_hhid
  , prp.id_number
  , prp.report_name
  , prp.prospect_id
  , to_char(prp.proposal_id) As rcpt_or_proposal_id
  , prp.proposal_type
  , prp.proposal_status
  , prp.ask_date
  , prp.close_date As date_of_record_or_close_dt
  , prp.total_ask_amt
  , prp.total_anticipated_amt As legal_or_anticipated_amt
  , prp.proposal_description As alloc_or_proposal
  , hhf.person_or_org
From rpt_pbh634.vt_ksm_proposal_pipeline prp
Cross Join params
Inner Join v_entity_ksm_households_fast hhf
  On hhf.id_number = prp.id_number
-- Include/exclude
Where prp.close_date >= params.campaign_start_dt
  And prp.proposal_active_calc = 'Active'
)
