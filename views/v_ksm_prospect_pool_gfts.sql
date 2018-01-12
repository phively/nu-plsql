Create Or Replace View v_ksm_prospect_pool_gfts As

-- v_ksm_prospect_pool with a few giving-related fields appended
-- Fairly slow to refresh due to multiple views
Select
  prs.*
  , cmp.campaign_giving
  , cmp.campaign_steward_giving As campaign_giving_recognition
  , gft.ngc_lifetime_full_rec As ksm_lifetime_recognition
  , gft.af_status
  , gft.af_cfy
  , gft.af_pfy1
  , gft.af_pfy2
  , gft.af_pfy3
  , gft.af_pfy4
From v_ksm_prospect_pool prs
Left Join v_ksm_giving_summary gft On gft.id_number = prs.id_number
Left Join v_ksm_giving_campaign cmp On cmp.id_number = prs.id_number
