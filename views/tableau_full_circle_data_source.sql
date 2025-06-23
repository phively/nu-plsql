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
  , ngc.person_or_org
  , ngc.full_circle_campaign_priority
From v_ksm_gifts_ngc ngc
Cross Join params
-- Include/exclude
Where ngc.full_circle_campaign_priority Is Not Null
/*) Union (
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
  , As fiscal_year
  , prp.total_ask_amt
  , prp.total_anticipated_amt As legal_or_anticipated_amt
  , prp.proposal_description As alloc_or_proposal
  , hhf.person_or_org
  , NULL As full_circle_campaign_priority
From rpt_pbh634.vt_ksm_proposal_pipeline prp
Cross Join params
Inner Join v_entity_ksm_households_fast hhf
  On hhf.id_number = prp.id_number
-- Include/exclude
Where prp.close_date >= params.campaign_start_dt
  And prp.proposal_active_calc = 'Active'
*/) Union (
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
From dummydata
)
