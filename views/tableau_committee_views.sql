Create Or Replace View rpt_pbh634.vt_advisory_committees_report As

With

ksm_allocations As (
  Select allocation_code
  From allocation
  Where alloc_school = 'KM'
)

, af_allocations As (
  Select allocation_code
  From table(rpt_pbh634.ksm_pkg.tbl_alloc_annual_fund_ksm)
)

, ksm_campaign_giving As (
  Select *
  From rpt_pbh634.v_ksm_giving_campaign
)

, af_giving As (
  Select
    id_number
    , sum(legal_amount) As legal_total
    , sum(credit_amount) As credit_total
  From nu_gft_trp_gifttrans
  Inner Join af_allocations
    On af_allocations.allocation_code = nu_gft_trp_gifttrans.allocation_code
  Where tx_gypm_ind != 'P'
    And credit_amount > 0
    And fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar)
  Group By id_number
)

, af_giving_fy_2 As (
  Select
    id_number
    , sum(legal_amount) As legal_total
    , sum(credit_amount) As credit_total
  From nu_gft_trp_gifttrans
  Inner Join af_allocations
    On af_allocations.allocation_code = nu_gft_trp_gifttrans.allocation_code
  Where tx_gypm_ind != 'P'
    And credit_amount > 0
    And fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar) - 2
  Group By id_number
),

af_giving_fy_1 As (
  Select
    id_number
    , sum(legal_amount) As legal_total
    , sum(credit_amount) As credit_total
  From nu_gft_trp_gifttrans
  Inner Join af_allocations
    On af_allocations.allocation_code = nu_gft_trp_gifttrans.allocation_code
  Where tx_gypm_ind != 'P'
    And credit_amount > 0
    And fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar) - 1
  Group By id_number
)

, af_giving_currentfy As (
  Select
    id_number
    , sum(legal_amount) As legal_total
    , sum(credit_amount) As credit_total
  From nu_gft_trp_gifttrans
  Inner Join af_allocations
    On af_allocations.allocation_code = nu_gft_trp_gifttrans.allocation_code
  Where tx_gypm_ind != 'P'
    And credit_amount > 0
    And fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar)
  Group By id_number
)

, ksm_lt_giving As (
  Select *
  From rpt_pbh634.v_ksm_giving_lifetime
)

, ksm_giving As (
  Select
    id_number
    , sum(legal_amount) As legal_total
    , sum(credit_amount) As credit_total
  From nu_gft_trp_gifttrans nugft
  Inner Join ksm_allocations
    On ksm_allocations.allocation_code = nugft.allocation_code
  Where tx_gypm_ind != 'Y'
    And credit_amount > 0 
    And nugft.fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar)
  GROUP BY ID_number
)

, ksm_giving_fy_1 As (
  Select
    id_number
    , sum(legal_amount) As legal_total
    , sum(credit_amount) As credit_total
  From nu_gft_trp_gifttrans
  Inner Join ksm_allocations
    On ksm_allocations.allocation_code = nu_gft_trp_gifttrans.allocation_code
  Where tx_gypm_ind != 'Y'
    And credit_amount > 0
    And fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar) - 1
  Group By id_number
)

, ksm_giving_fy_2 As (
  Select
    id_number
    , sum(legal_amount) As legal_total
    , sum(credit_amount) As credit_total
  From nu_gft_trp_gifttrans
  Inner Join ksm_allocations
    On ksm_allocations.allocation_code = nu_gft_trp_gifttrans.allocation_code
  Where tx_gypm_ind != 'Y'
    And credit_amount > 0
    And fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar) - 2
  Group By id_number
)

, AMP As (
  Select
    id_number
    , short_desc
    , listagg(start_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
      As start_dt
    , listagg(stop_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
      As stop_dt
    , status
    , listagg(role, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
      As role
  From table(rpt_pbh634.ksm_pkg.tbl_committee_AMP)
  Group By
    id_number
    , short_desc
    , status
)

, RealEstCouncil As (
  Select
    id_number
    , short_desc
    , listagg(start_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
      As start_dt
    , listagg(stop_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
      As stop_dt
    , status
    , listagg(role, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
      As role
  From table(rpt_pbh634.ksm_pkg.tbl_committee_RealEstCouncil)
  Group By
    id_number
    , short_desc
    , status
)

, DivSummit As (
  Select
    id_number
    , short_desc
    , listagg(start_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
      As start_dt
    , listagg(stop_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
      As stop_dt
    , status
    , listagg(role, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
      As role
  From table(rpt_pbh634.ksm_pkg.tbl_committee_DivSummit)
  Group By
    id_number
    , short_desc
    , status
)

, WomenSummit As (
  Select
    id_number
    , short_desc
    , listagg(start_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
      As start_dt
    , listagg(stop_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
      As stop_dt
    , status
    , listagg(role, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
      As role
  From table(rpt_pbh634.ksm_pkg.tbl_committee_WomenSummit)
  Group By
    id_number
    , short_desc
    , status
)

, CorpGov As (
  Select
    id_number
    , short_desc
    , listagg(start_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
      As start_dt
    , listagg(stop_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
      As stop_dt
    , status
    , listagg(role, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
      As role
  From table(rpt_pbh634.ksm_pkg.tbl_committee_CorpGov)
  Group By
    id_number
    , short_desc
    , status
)

, KFN As (
  Select
    id_number
    , short_desc
    , listagg(start_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
      As start_dt
    , listagg(stop_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
      As stop_dt
    , status
    , listagg(role, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
      As role
  From table(rpt_pbh634.ksm_pkg.tbl_committee_KFN)
  Group By
    id_number
    , short_desc
    , status
)

, GAB As (
  Select
    id_number
    , short_desc
    , listagg(start_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
      As start_dt
    , listagg(stop_dt, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
      As stop_dt
    , status
    , listagg(role, '; ') Within Group (Order By start_dt Asc, stop_dt Asc, role Asc)
      As role
  From table(rpt_pbh634.ksm_pkg.tbl_committee_gab)
  Group By
    id_number
    , short_desc
    , status
)

, all_committees As (
  Select id_number From AMP
  Union
  Select id_number From RealEstCouncil
  Union
  Select id_number From DivSummit
  Union
  Select id_number From WomenSummit
  Union
  Select id_number From CorpGov
  Union
  Select id_number From KFN
  Union
  Select id_number From GAB
)

, all_committee_data As (
  Select * From AMP
  Union
  Select * From RealEstCouncil
  Union
  Select * From DivSummit
  Union
  Select * From WomenSummit
  Union
  Select * From CorpGov
  Union
  Select * From KFN
  Union
  Select * From GAB
)

, KSMdegree As (
  Select
    id_number
    , degrees_concat
  From table(rpt_pbh634.ksm_pkg.tbl_entity_degrees_concat_ksm)
)

, NU_LT_Giving As (
  Select
    prs.id_number
    , prs.giving_total
  From nu_prs_trp_prospect prs
  Inner Join All_Committees
    On All_Committees.id_number = prs.id_number
)

, CFY_NULT_Giving As (
  Select
    nugft.id_number
    , sum(nugft.credit_amount) As cfy_nult_giving
  From nu_gft_trp_gifttrans nugft
  Inner Join All_Committees On All_Committees.id_number = nugft.id_number
  Where tx_gypm_ind != 'Y'
    And fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar)
  Group By nugft.id_number
)

, LFY_NULT_Giving As (
  Select
    nugft.id_number
    , sum(nugft.credit_amount) As lfy_nult_giving
  From nu_gft_trp_gifttrans nugft
  Inner Join All_Committees
    On All_Committees.id_number = nugft.id_number
  Where tx_gypm_ind != 'Y'
    And fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar) - 1
  Group By nugft.id_number
)

, LFY2_NULT_Giving As (
  Select
    nugft.id_number
    , sum(nugft.credit_amount) As lfy2_nult_giving
  From nu_gft_trp_gifttrans nugft
  Inner Join All_Committees
    On All_Committees.id_number = nugft.id_number
  Where tx_gypm_ind != 'Y' And fiscal_year = (Select curr_fy From rpt_pbh634.v_current_calendar) - 2
  Group By nugft.ID_Number
)

, ksmprop As (
  Select proposal_ID
  From proposal_purpose
  Where program_code = 'KM' 
)

, ActiveProposals As (
  Select
    p.proposal_id
    , p.prospect_id
    , Case
        When p.original_ask_amt >= 100000
          Or p.ask_amt >= 100000
          Or p.anticipated_amt >= 100000
          Then 'Y'
        Else 'N'
        End
      As MajorGift
  From proposal p
  Inner Join ksmprop
    On ksmprop.proposal_id = p.proposal_id
  Where active_ind = 'Y'
)

, ProposalCount As (
  Select
    prospect_id
    , count(proposal_id) As proposalcount
  From activeproposals
  Where majorgift = 'Y'
  Group By prospect_id
)

Select Distinct
  prs.id_number
  , prs.pref_mail_name
  , ksmdegree.degrees_concat
  , prs.employer_name1
  , prs.business_title
  , prs.pref_city
  , prs.pref_state
  , prs.pref_zip
  , prs.preferred_country
  , prs.prospect_id
  , prs.prospect_manager
  , prs.evaluation_rating
  , prs.evaluation_date
  , prs.officer_rating
--      , All_Committee_Data.short_desc
--      , All_Committee_Data.start_dt
--      , All_Committee_Data.stop_dt
--      , All_Committee_Data.status
--      , All_Committee_Data.role
  , Case When gab.short_desc = 'KSM Global Advisory Board' Then 'Y' Else 'N' End
    As gab_ind
  , gab.start_dt As gab_start_date
  , gab.stop_dt As gab_stop_date
  , gab.status As gab_status
  , gab.role As gab_role
  , Case When KFN.short_desc = 'Kellogg Finance Network' Then 'Y' Else 'N' End
    As kfn_ind
  , kfn.start_dt As kfn_start_date
  , kfn.stop_dt As kfn_stop_date
  , kfn.status As kfn_status
  , kfn.role As kfn_role
  , Case When corpgov.short_desc = 'KSM Corporate Governance Committee' Then 'Y' Else 'N' End
    As corpgov_ind
  , corpgov.start_dt As corpgov_start_date
  , corpgov.stop_dt As corpgov_stop_date
  , corpgov.status As corpgov_status
  , corpgov.role As corpgov_role
--      , Case When WomenSummit.short_desc Like 'KSM Global W%s Summit' Then 'Y' Else 'N' 
--            End WomenSummit_Ind
--      , WomenSummit.Start_dt As "WS_START_DATE"
--      , Womensummit.Stop_dt As "WS_STOP_DATE"
--      , Womensummit.status As "WS_STATUS"
--      , Womensummit.Role As "WS_ROLE"
  , Case When divsummit.short_desc = 'KSM Chief Diversity Officer Summit' Then 'Y' Else 'N' End
    As divsummit_ind
  , divsummit.start_dt As ds_start_date
  , divsummit.stop_dt As ds_stop_date
  , divsummit.status As ds_status
  , divsummit.role As ds_role
  , Case When RealEstCouncil.short_desc = 'Real Estate Advisory Council' Then 'Y' Else 'N' End
    As realest_ind
  , realestcouncil.start_dt As rec_start_date
  , realestcouncil.stop_dt As rec_stop_date
  , realestcouncil.status As rec_status
  , realestcouncil.role As rec_role
  , Case When amp.short_desc = 'AMP Advisory Council' Then 'Y' Else 'N' End
    As amp_ind
  , amp.start_dt As amp_start_date
  , amp.stop_dt As amp_stop_date
  , amp.status As amp_status
  , amp.role As amp_role
  , nvl(nu_lt_giving.giving_total, 0) As nu_lt_giving
  , nvl(cfy_nult_giving.cfy_nult_giving, 0) As cfy_nult_giving
  , nvl(lfy_nult_giving.lfy_nult_giving, 0) As lfy_nult_giving
  , nvl(lfy2_nult_giving.lfy2_nult_giving, 0) As lfy2_nult_giving
  , nvl(ksm_lt_giving.credit_amount, 0) As ksm_lt_giving
  , nvl(ksm_campaign_giving.campaign_giving,0) As ksm_campaign_giving
  , nvl(proposalcount.proposalcount, 0) As proposal_count
  , nvl(af_giving_currentfy.legal_total, 0) As af_cfy_legal
  , nvl(af_giving_currentfy.credit_total, 0) As af_cfy_sftcredit
  , nvl(af_giving_fy_1.legal_total, 0) As af_lyfy_legal
  , nvl(af_giving_fy_1.credit_total, 0) As af_lyfy_sftcredit
  , nvl(af_giving_fy_2.legal_total, 0) As af_lyfy2_legal
  , nvl(af_giving_fy_2.credit_total, 0) As af_lyfy2_sftcredit
  , nvl(ksm_giving.legal_total, 0) As ksm_cfy_legal
  , nvl(ksm_giving.credit_total, 0) As ksm_cfy_sftcredit
  , nvl(ksm_giving_fy_1.legal_total, 0) As ksm_lyfy_legal
  , nvl(ksm_giving_fy_1.credit_total, 0) As ksm_lyfy_sftcredit
  , nvl(ksm_giving_fy_2.legal_total, 0) As ksm_lyfy2_legal
  , nvl(ksm_giving_fy_2.credit_total, 0) As ksm_lyfy2_sftcredit
  , nvl(ksm_campaign_giving.campaign_cfy, 0) As campaign_cfy
  , nvl(ksm_campaign_giving.campaign_pfy1, 0) As campaign_pfy1 
  , nvl(ksm_campaign_giving.campaign_pfy2, 0) As campaign_pfy2
  , nvl(ksm_campaign_giving.campaign_pfy3, 0) As campaign_pfy3
From nu_prs_trp_prospect prs
Inner Join all_committee_data
  On all_committee_data.id_number = prs.id_number
Inner Join all_committees
  On all_committees.id_number = prs.id_number
Left Join amp
  On amp.id_number = all_committees.id_number
Left Join realestcouncil
  On realestcouncil.id_number = all_committees.id_number
Left Join divsummit
  On divsummit.id_number = all_committees.id_number
Left Join womensummit
  On womensummit.id_number = all_committees.id_number
Left Join corpgov
  On corpgov.id_number = all_committees.id_number
Left Join kfn
  On kfn.id_number = all_committees.id_number
Left Join gab
  On gab.id_number = all_committees.id_number
Left Join ksmdegree
  On ksmdegree.id_number = prs.id_number
Left Join proposalcount
  On proposalcount.prospect_id = prs.prospect_id
Left Join af_giving_currentfy
  On all_committees.id_number = af_giving_currentfy.id_number
Left Join af_giving_fy_2
  On all_committees.id_number = af_giving_fy_2.id_number
Left Join af_giving_fy_1
  On all_committees.id_number = af_giving_fy_1.id_number
Left Join ksm_giving
  On all_committees.id_number = ksm_giving.id_number
Left Join ksm_giving_fy_1
  On all_committees.id_number = ksm_giving_fy_1.id_number
Left Join ksm_giving_fy_2
  On all_committees.id_number = ksm_giving_fy_2.id_number
Left Join ksm_campaign_giving
  On all_committees.id_number = ksm_campaign_giving.id_number
Left Join ksm_lt_giving
  On all_committees.id_number = ksm_lt_giving.id_number
Left Join nu_lt_giving
  On all_committees.id_number = nu_lt_giving.id_number
Left Join ksm_campaign_giving
  On all_committees.id_number = ksm_campaign_giving.id_number
Left Join cfy_nult_giving
  On all_committees.id_number = cfy_nult_giving.id_number
Left Join lfy_nult_giving
  On all_committees.id_number = lfy_nult_giving.id_number
Left Join lfy2_nult_giving
  On all_committees.id_number = lfy2_nult_giving.id_number
;
