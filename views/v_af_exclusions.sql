Create Or Replace View v_af_exclusions As

With

-- Manual exclusions
manual_exclusions_pre As (
  Select
    id_number
    , report_name
  From entity
  Where id_number In (
    NULL
------ ADD ID NUMBERS BELOW HERE ------
    , '0000299349' -- DSB
    , '0000225195' -- DDJ
    , '0000499489' -- DDJ spouse
    , '0000804796' -- DFC
------ ADD ID NUMBERS ABOVE HERE ------
  )
)
, manual_exclusions As (
    Select
      id_number
      , 'Y' As manual_exclusion
    From manual_exclusions_pre
  Union
    Select
      entity.id_number
      , 'Y' As manual_exclusion
    From entity
    Inner Join manual_exclusions_pre mep On mep.id_number = entity.spouse_id_number
)

-- Deceased
, deceased As (
  Select
    id_number
    , record_status_code As deceased
  From entity
  Where record_status_code = 'D'
)

-- Special handling
, spec_hnd As (
  Select
    id_number
    , spouse_id_number
    , special_handling_concat
    , mailing_list_concat
    , no_contact
    , no_solicit
    , never_engaged_forever
    , never_engaged_reunion
    , exc_all_comm
    , exc_all_sols
  From table(ksm_pkg.tbl_special_handling_concat) shc
  Where no_contact = 'Y'
    Or no_solicit = 'Y'
    Or never_engaged_forever = 'Y'
    Or never_engaged_reunion = 'Y'
    Or exc_all_comm = 'Y'
    Or exc_all_sols = 'Y'
)

-- Global Advisory Board
, gab As (
  Select
    id_number
    , Listagg(
        trim('GAB ' || role)
      , '; ') Within Group (Order By tcg.role Asc)
      As gab
  From table(ksm_pkg.tbl_committee_gab) tcg
  Group By id_number
)

-- Trustee
, trustee As (
  Select
    id_number
    , Listagg(
        Case
          When a.affil_code = 'TR' Then
            Case
              When tms_al.affil_level_code Is Not Null Then tms_al.short_desc
              Else 'Trustee'
            End
          When a.affil_code = 'TS' Then trim(tms_ac.short_desc || ' ' || tms_al.short_desc)
        End
      , '; ') Within Group (Order By a.affil_code Asc)
      As trustee
  From affiliation a
  Left Join tms_affil_code tms_ac On tms_ac.affil_code = a.affil_code
  Left Join tms_affiliation_level tms_al On tms_al.affil_level_code = a.affil_level_code
  Where a.affil_code In ('TR', 'TS') -- Trustee and Trustee Relation
    And a.affil_status_code In ('C', 'A') -- Current and Active (deprecated) only
  Group By id_number
)

-- Pledges/recurring gifts
, nu_pledges As (
    -- Pledge donor
    Select
      p.pledge_donor_id As id_number
      , p.pledge_pledge_number As pledge_number
      , p.pledge_pledge_type As pledge_type
      , a.allocation_code
      , a.alloc_school
      , tms_pt.short_desc As pledge_type_desc
    From pledge p
    Inner Join primary_pledge pp On p.pledge_pledge_number = pp.prim_pledge_number
    Inner Join allocation a On a.allocation_code = p.pledge_allocation_name
    Inner Join tms_pledge_type tms_pt On tms_pt.pledge_type_code = p.pledge_pledge_type
    Where pp.prim_pledge_status = 'A' -- Active pledges only
      And p.pledge_pledge_type Not In ('BE', 'LE') -- Ignore planned giving
  Union
    -- Pledge donor spouse
    Select
      e.id_number
      , p.pledge_pledge_number As pledge_number
      , p.pledge_pledge_type As pledge_type
      , a.allocation_code
      , a.alloc_school
      , tms_pt.short_desc As pledge_type_desc
    From entity e
    Inner Join pledge p On p.pledge_donor_id = e.spouse_id_number
    Inner Join primary_pledge pp On p.pledge_pledge_number = pp.prim_pledge_number
    Inner Join allocation a On a.allocation_code = p.pledge_allocation_name
    Inner Join tms_pledge_type tms_pt On tms_pt.pledge_type_code = p.pledge_pledge_type
    Where pp.prim_pledge_status = 'A' -- Active pledges only
      And p.pledge_pledge_type Not In ('BE', 'LE') -- Ignore planned giving
)
, pledge_counts As (
  Select
    id_number
    , count(Distinct pledge_number)
      As active_pledges
  From nu_pledges
  Where alloc_school = 'KM' -- Kellogg only
  Group By id_number
)

-- Open proposal data
, ksm_proposal_data As (
  Select
    prospect_id
    -- Submitted and approved by donor proposals
    , count(Distinct Case
        When hierarchy_order In (20, 60) -- Submitted, approved by donor
          And final_anticipated_or_ask_amt > 50000 -- Ignore ask/anticipated $50K or under
          Then proposal_id 
      End) As proposals_sub_appr
  From v_proposal_history_fast vph
  Cross Join v_current_calendar cal
  Where proposal_active = 'Y'
    And proposal_in_progress = 'Y'
    And ksm_proposal_ind = 'Y'
  Group By prospect_id
)

-- Prospect entities with proposals, active only
, ksm_proposal_counts As (
  Select
    pd.prospect_id
    , pe.id_number
    , pe.primary_ind
    , pd.proposals_sub_appr
  From ksm_proposal_data pd
  Inner Join prospect_entity pe On pe.prospect_id = pd.prospect_id
  Inner Join prospect p On p.prospect_id = pd.prospect_id
  Where p.active_ind = 'Y' -- Active only
    And pd.proposals_sub_appr > 0 -- Must have proposals
)

-- Degree removals
, degree_exclusion_ids As (
    -- Alumni with a PhD or IEMBA or certificate
    Select id_number
    From degrees
    Where institution_code = '31173'
      And school_code In ('BUS', 'KSM')
      And (
        degree_code In ('PHD', 'MSMS')
        Or campus_code In ('CAN', 'ISL', 'HK', 'GER')
        Or degree_level_code = 'C'
      )
  Minus
    -- Exclude alumni with a different degree
    Select id_number
    From degrees
    Where institution_code = '31173'
      And school_code In ('BUS', 'KSM')
      And degree_level_code Not In ('C')
      And degree_code Not In ('PHD', 'MSMS')
      And campus_code Not In ('CAN', 'ISL', 'HK', 'GER')
)
, degree_exclusion As (
  Select
    dei.id_number
    , deg.degrees_concat
    , deg.program As degree_program
  From degree_exclusion_ids dei
  Inner Join v_entity_ksm_degrees deg On deg.id_number = dei.id_number
)

-- Merged ids
, ids As (
    -- Manual exclusions
    Select id_number
    From manual_exclusions
  Union
    -- Deceased
    Select id_number
    From deceased
  Union
    -- Special handling
    Select id_number
    From spec_hnd
  Union
    -- Spouse special handling
    Select spouse_id_number
    From spec_hnd
    Where no_contact = 'Y'
      Or exc_all_comm = 'Y'
      Or never_engaged_forever = 'Y'
  Union
    -- Current GAB members
    Select id_number
    From gab
  Union
    -- Current trustees/spouses
    Select id_number
    From trustee
  Union
    -- Pledges
    Select id_number
    From pledge_counts
  Union
    -- Proposals
    Select id_number
    From ksm_proposal_counts
  Union
    -- Degrees
    Select id_number
    From degree_exclusion
)

-- Final query
Select
  entity.id_number
  , entity.report_name
  , me.manual_exclusion
  , deceased.deceased
  , sh.special_handling_concat
  , shs.special_handling_concat As special_handling_spouse
  , sh.no_contact 
  , shs.no_contact As no_contact_spouse
  , sh.no_solicit 
  , shs.no_solicit As no_solicit_spouse
  , sh.never_engaged_forever
  , shs.never_engaged_forever As never_engaged_forever_spouse
  , sh.never_engaged_reunion
  , shs.never_engaged_reunion As never_engaged_reunion_spouse
  , sh.exc_all_comm
  , shs.exc_all_comm As exc_all_comm_spouse
  , sh.exc_all_sols
  , shs.exc_all_sols As exc_all_sols_spouse
  , gab.gab
  , trustee.trustee
  , dex.degrees_concat
  , dex.degree_program
  -- Degree exclusion only when every other field is null
  , Case
      When dex.degree_program Is Not Null
        And me.id_number Is Null
        And deceased.id_number Is Null
        And sh.id_number Is Null
        And shs.spouse_id_number Is Null
        And gab.id_number Is Null
        And trustee.id_number Is Null
        And pc.id_number Is Null
        And propc.id_number Is Null
        Then 'Y'
      End
    As degree_exclusion_only
  , pc.active_pledges
  , propc.proposals_sub_appr
From ids
Inner Join entity On entity.id_number = ids.id_number
Left Join manual_exclusions me On me.id_number = ids.id_number
Left Join deceased On deceased.id_number = ids.id_number
Left Join spec_hnd sh On sh.id_number = ids.id_number
Left Join spec_hnd shs On shs.spouse_id_number = ids.id_number
Left Join gab On gab.id_number = ids.id_number
Left Join trustee On trustee.id_number = ids.id_number
Left Join degree_exclusion dex On dex.id_number = ids.id_number
Left Join pledge_counts pc On pc.id_number = ids.id_number
Left Join ksm_proposal_counts propc On propc.id_number = ids.id_number
