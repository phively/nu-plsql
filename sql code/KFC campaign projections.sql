-- All FC campaign gifts
Select
  ngc.donor_id
  , ngc.sort_name
  , ngc.source_donor_id
  , ngc.source_donor_name
  , ngc.tx_id
  , ngc.credit_date
  , ngc.fiscal_year
  , ngc.hard_credit_amount
  , ngc.gypm_ind
  , ngc.opportunity_type
  , ngc.source_type_detail
  , ngc.designation_record_id
  , ngc.designation_name
  , ngc.full_circle_campaign_priority
  , ngc.cash_category
  , Case
      When ngc.linked_proposal_record_id Is Not Null
        Then 'Y'
      End
    As linked_proposal
  , ngc.linked_proposal_record_id
  , pr.historical_pm_name
  , pr.historical_pm_role
  , pr.historical_pm_business_unit
  , pr.historical_proposal_manager_team
From v_ksm_gifts_ngc ngc
Left Join mv_proposals pr
  On pr.proposal_record_id = ngc.linked_proposal_record_id
Where ngc.full_circle_campaign_priority Is Not Null
  And ngc.hard_credit_amount > 0
;
