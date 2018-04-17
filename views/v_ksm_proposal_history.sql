/**************************************
NU historical proposals, including inactive
**************************************/

Create Or Replace View v_proposal_history As

With

-- Gifts with linked proposals
linked As (
  Select
    proposal_id
    , sum(legal_amount) As ksm_linked_amounts
  From v_ksm_giving_trans
  Where proposal_id Is Not Null
    And legal_amount > 0
    And tx_gypm_ind <> 'Y' -- Payment linked but pledge not is a data issue
  Group By proposal_id
)
, linked_receipts As (
  Select
    proposal_id
    , Listagg(tx_number, '; ') Within Group (Order By tx_number Asc) As ksm_linked_receipts
  From (
    Select Distinct
      proposal_id
      , tx_number
    From v_ksm_giving_trans
    Where proposal_id Is Not Null
      And legal_amount > 0
      And tx_gypm_ind <> 'Y' -- Payment linked but pledge not is a data issue
  )
  Group By proposal_id
)
, linkednu As (
  Select
    proposal_id
    , sum(prim_pledge_amount) As nu_linked_amounts
  From (
    Select proposal_id, prim_pledge_amount From primary_pledge
    Union All
    Select proposal_id, prim_gift_amount From primary_gift Where pledge_payment_ind = 'N'
  )
  Where proposal_id Is Not Null
  Group By proposal_id
)

-- Current calendar
, cal As (
  Select *
  From table(rpt_pbh634.ksm_pkg.tbl_current_calendar)
)

-- Proposal purpose
, ksm_purps As (
  Select
    pp.proposal_id
    , pp.xsequence
    , tms_pp.short_desc As prop_purpose
    , tms_pi.short_desc As initiative
    , pp.prospect_interest_code As initiative_cd
    , pp.ask_amt As program_ask
    , pp.original_ask_amt As program_orig_ask
    , pp.granted_amt As program_anticipated
  From proposal_purpose pp
  Left Join tms_prop_purpose tms_pp On tms_pp.prop_purpose_code = pp.prop_purpose_code
  Left Join tms_prospect_interest tms_pi On tms_pi.prospect_interest_code = pp.prospect_interest_code
  Where program_code = 'KM'
)
, ksm_purp As (
  Select
    proposal_id
    , Listagg(prop_purpose, '; ') Within Group (Order By xsequence Asc) As prop_purposes
    , Listagg(initiative, '; ') Within Group (Order By xsequence Asc) initiatives
    , sum(program_ask) As ksm_ask
    , sum(program_orig_ask) As ksm_orig_ask
    , sum(program_anticipated) As ksm_anticipated
    , sum(Case When initiative Like '%KSM Annual Fund%' Then program_ask Else 0 End) As ksm_af_ask
    , sum(Case When initiative Like '%KSM Annual Fund%' Then program_anticipated Else 0 End) As ksm_af_anticipated
    , sum(Case When initiative_cd = 'KFC' Then program_ask Else 0 End) As ksm_facilities_ask
    , sum(Case When initiative_cd = 'KFC' Then program_anticipated Else 0 End) As ksm_facilities_anticipated
  From ksm_purps
  Group By proposal_id
)
, other_purp As (
  Select
    pp.proposal_id
    , Listagg(tms_program.short_desc, '; ') Within Group (Order By pp.xsequence Asc) As other_programs
  From proposal_purpose pp
  Inner Join tms_program On tms_program.program_code = pp.program_code
  Where pp.program_code <> 'KM'
  Group By pp.proposal_id
)

-- Proposal assignments
, assn As (
  Select
    assignment.proposal_id
    , max(assignment.assignment_id_number)
        keep(dense_rank First Order By assignment.stop_date Desc, assignment.start_date Desc, assignment.date_added Desc, assignment.date_modified Desc)
        As proposal_manager_id
    , max(entity.report_name)
        keep(dense_rank First Order By assignment.stop_date Desc, assignment.start_date Desc, assignment.date_added Desc, assignment.date_modified Desc)
        As proposal_manager
    , Listagg(assignment.assignment_id_number, '; ') Within Group (Order By assignment.start_date Desc NULLS Last, assignment.date_modified Desc)
        As historical_managers_id
    , Listagg(entity.report_name, '; ') Within Group (Order By assignment.start_date Desc NULLS Last, assignment.date_modified Desc)
        As historical_managers
  From assignment
  Inner Join entity On entity.id_number = assignment.assignment_id_number
  Where assignment.assignment_type = 'PA' -- Proposal Manager (PM is taken by Prospect Manager)
  Group By assignment.proposal_id
)
, asst As (
  Select
    assignment.proposal_id
    , Listagg(entity.report_name, '; ') Within Group (Order By assignment.start_date Desc NULLS Last, assignment.date_modified Desc)
        As proposal_assist
  From assignment
  Inner Join entity On entity.id_number = assignment.assignment_id_number
  Where assignment.assignment_type = 'AS' -- Proposal Assist
  Group By assignment.proposal_id
)

-- Code to pull university strategy from the task table; BI method plus a cancelled/completed exclusion
, strat As (
  Select *
  From table(ksm_pkg.tbl_university_strategy)
)

-- Final KSM proposal amounts; if no non-KSM programs use face value, otherwise sum up KSM program amounts if able
, ksm_amts As (
  Select
    proposal.proposal_id
    , Case
        When other_purp.other_programs Is Null Then proposal.ask_amt
        When ksm_ask > 0  Then ksm_ask
        Else proposal.ask_amt
      End As ksm_or_univ_ask
    , Case
        When other_purp.other_programs Is Null Then proposal.original_ask_amt
        When ksm_orig_ask > 0 Then ksm_orig_ask
        Else proposal.original_ask_amt
      End As ksm_or_univ_orig_ask
    , Case
        When other_purp.other_programs Is Null Then proposal.anticipated_amt
        When ksm_anticipated > 0 Then ksm_anticipated
        Else proposal.anticipated_amt
      End As ksm_or_univ_anticipated
  From proposal
  Left Join ksm_purp On ksm_purp.proposal_id = proposal.proposal_id
  Left Join other_purp On other_purp.proposal_id = proposal.proposal_id
)

-- Main query
Select
  proposal.prospect_id
  , prs.prospect_name
  , prs.prospect_name_sort
  , proposal.proposal_id
  , Case When ksm_purp.proposal_id Is Not Null And ksm_amts.proposal_id Is Not Null Then 'Y' End
      As ksm_proposal_ind
  , proposal.proposal_title
  , proposal.description As proposal_description
  , assn.proposal_manager_id
  , assn.proposal_manager
  , asst.proposal_assist
  , assn.historical_managers
  , proposal.proposal_status_code
  , tms_ps.hierarchy_order
  , Case
      When proposal.proposal_status_code = 'B' Then 'Submitted' -- Letter of Inquiry Submitted
      When proposal.proposal_status_code = '5' Then 'Verbal' -- Approved by Donor
      Else tms_ps.short_desc
    End As proposal_status
  , proposal.active_ind As proposal_active
  , Case When tms_ps.hierarchy_order < 70 Then 'Y' End As proposal_in_progress -- Anticipated, Submitted, Deferred, Approved
  , ksm_purp.prop_purposes
  , ksm_purp.initiatives
  , other_purp.other_programs
  , strat.university_strategy
  , trunc(start_date) As start_date
  , ksm_pkg.get_fiscal_year(start_date) As start_fy
  , trunc(initial_contribution_date) As ask_date
  , ksm_pkg.get_fiscal_year(initial_contribution_date) As ask_fy
  , trunc(stop_date) As close_date
  , ksm_pkg.get_fiscal_year(stop_date) As close_fy
  , trunc(date_modified) As date_modified
  , linked_receipts.ksm_linked_receipts
  , linked.ksm_linked_amounts
  , linkednu.nu_linked_amounts
  , original_ask_amt As total_original_ask_amt
  , ask_amt As total_ask_amt
  , anticipated_amt As total_anticipated_amt
  , granted_amt As total_granted_amt
  , ksm_purp.ksm_ask
  , ksm_purp.ksm_anticipated
  , ksm_purp.ksm_af_ask
  , ksm_purp.ksm_af_anticipated
  , ksm_purp.ksm_facilities_ask
  , ksm_purp.ksm_facilities_anticipated
  , ksm_amts.ksm_or_univ_ask
  , ksm_amts.ksm_or_univ_orig_ask
  , ksm_amts.ksm_or_univ_anticipated
  -- Anticipated or ask amount depending on stage and data quality
  , Case
      -- Verbal uses anticipated amount if available
      When proposal.proposal_status_code = '5' And ksm_amts.ksm_or_univ_anticipated > 0 Then ksm_amts.ksm_or_univ_anticipated
      -- Otherwise use ask amount
      Else ksm_amts.ksm_or_univ_ask
    End As final_anticipated_or_ask_amt
  -- Anticipated bin: use anticipated amount if available, otherwise fall back to ask amount
  , Case
      -- Verbal uses anticipated amount if available
      When proposal.proposal_status_code = '5' And ksm_or_univ_anticipated > 0 Then
        Case
          When ksm_or_univ_anticipated >= 10000000 Then 10
          When ksm_or_univ_anticipated >=  5000000 Then 5
          When ksm_or_univ_anticipated >=  2000000 Then 2
          When ksm_or_univ_anticipated >=  1000000 Then 1
          When ksm_or_univ_anticipated >=   500000 Then 0.5
          When ksm_or_univ_anticipated >=   100000 Then 0.1
          Else 0
        End
      -- Otherwise use the ask amount
      When ksm_or_univ_ask         >= 10000000 Then 10
      When ksm_or_univ_ask         >=  5000000 Then 5
      When ksm_or_univ_ask         >=  2000000 Then 2
      When ksm_or_univ_ask         >=  1000000 Then 1
      When ksm_or_univ_ask         >=   500000 Then 0.5
      When ksm_or_univ_ask         >=   100000 Then 0.1
      Else 0
    End As ksm_bin
From proposal
Cross Join cal
Inner Join tms_proposal_status tms_ps On tms_ps.proposal_status_code = proposal.proposal_status_code
-- KSM proposals
Left Join ksm_purp On ksm_purp.proposal_id = proposal.proposal_id
Left Join ksm_amts On ksm_amts.proposal_id = proposal.proposal_id
-- Proposal info
Left Join other_purp On other_purp.proposal_id = proposal.proposal_id
Left Join assn On assn.proposal_id = proposal.proposal_id
Left Join asst On asst.proposal_id = proposal.proposal_id
-- Prospect info
Left Join (Select prospect_id, prospect_name, prospect_name_sort From prospect) prs
  On prs.prospect_id = proposal.prospect_id
Left Join strat On strat.prospect_id = proposal.prospect_id
-- Linked gift info
Left Join linked On linked.proposal_id = proposal.proposal_id
Left Join linked_receipts On linked_receipts.proposal_id = proposal.proposal_id
Left Join linkednu On linkednu.proposal_id = proposal.proposal_id;

/**************************************
KSM version
Filter on ksm_proposal_ind = 'Y'
**************************************/

Create Or Replace View v_ksm_proposal_history As

Select
  prospect_id
  , prospect_name
  , prospect_name_sort
  , proposal_id
  , ksm_proposal_ind
  , proposal_title
  , proposal_description
  , proposal_manager_id
  , proposal_manager
  , proposal_assist
  , proposal_status_code
  , historical_managers
  , hierarchy_order
  , proposal_status
  , proposal_active
  , proposal_in_progress
  , prop_purposes
  , initiatives
  , other_programs
  , university_strategy
  , start_date
  , start_fy
  , ask_date
  , ask_fy
  , close_date
  , close_fy
  , date_modified
  , ksm_linked_receipts
  , ksm_linked_amounts
  , nu_linked_amounts
  , total_original_ask_amt
  , total_ask_amt
  , total_anticipated_amt
  , total_granted_amt
  , ksm_ask
  , ksm_anticipated
  , ksm_af_ask
  , ksm_af_anticipated
  , ksm_facilities_ask
  , ksm_facilities_anticipated
  , ksm_or_univ_ask
  , ksm_or_univ_orig_ask
  , ksm_or_univ_anticipated
  , final_anticipated_or_ask_amt
  , ksm_bin
From v_proposal_history
Where ksm_proposal_ind = 'Y'
