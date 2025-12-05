-- Combines proposal and giving data for campaign totals

Create Or Replace View tableau_full_circle_data_source As

With

-------------------------
-- OK to edit this
-------------------------

params As (
  Select
    to_date(
      -- KFC campaign start FY
      to_char(ksm_pkg_gifts.get_numeric_constant('campaign_kfc_start_fy') - 1)
      || '0901'
      , 'yyyymmdd'
    ) As campaign_start_dt
  From DUAL
)

, dummydata As (
  Select 75E6 As amount From DUAL
  Union
  Select 50E6 As amount From DUAL
  Union
  Select 20E6 As amount From DUAL
  Union
  Select 10E6 As amount From DUAL
  Union
  Select 5E6 As amount From DUAL
)

-------------------------
-- Do not edit below this
-------------------------

(
Select
  'Giving' As data_source
  , ngc.source_donor_id
  , ngc.source_donor_name
  , ngc.donor_id
  , ngc.sort_name
  , ngc.opportunity_record_id As opportunity_or_proposal_id
  , ngc.source_type
  , ngc.source_type_detail
  , NULL As proposal_status
  , NULL As ask_date
  , ngc.credit_date As credit_date_or_close_dt
  , ngc.fiscal_year As fiscal_year
  , NULL As ask_amount
  , ngc.hard_credit_amount As hard_credit_or_anticipated_amt
  , ngc.designation_name As designation_or_proposal
  , ngc.designation_name As designation_or_proposal_desc
  , ngc.person_or_org
  , ngc.full_circle_campaign_priority
From v_ksm_gifts_ngc ngc
Cross Join params
-- Include/exclude
Where ngc.full_circle_campaign_priority Is Not Null
) Union (
Select
  'Proposal' As data_source
  , prp.donor_id As source_donor_id
  , prp.full_name
  , prp.donor_id
  , prp.sort_name
  , prp.proposal_record_id As opportunity_or_proposal_id
  , prp.proposal_type
  , prp.proposal_type
  , prp.proposal_stage
  , prp.proposal_submitted_date
  , prp.proposal_close_date As credit_date_or_close_dt
  , prp.proposal_close_fy As fiscal_year
  , prp.proposal_submitted_amount
  , Case
      When prp.proposal_anticipated_amount Is Not Null
        Then prp.proposal_anticipated_amount
      Else prp.proposal_amount
      End
    As legal_or_anticipated_amt
  , prp.proposal_name As designation_or_proposal
  , prp.proposal_description As designation_or_proposal_desc
  , prp.person_or_org
  , NULL As full_circle_campaign_priority
From mv_proposals prp
Cross Join params
-- Include/exclude
Where prp.proposal_close_date >= params.campaign_start_dt
  And prp.proposal_active_indicator = 'Y'
  And prp.ksm_flag = 'Y'
) Union (
-- Dummy proposals
Select
  'Dummy' As data_source
  , NULL
  , NULL
  , NULL
  , NULL
  , NULL
  , NULL
  , NULL
  , 'Dummy' As proposal_status
  , NULL
  , NULL
  , NULL
  , NULL
  , amount As legal_or_anticipated_amt
  , NULL
  , NULL
  , NULL
  , NULL
From dummydata
)
