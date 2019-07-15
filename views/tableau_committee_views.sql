Create Or Replace View rpt_pbh634.vt_advisory_committees_report As

With

AMP As (
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

, fy_nu_giving As (
  Select
    nugft.id_number
    , sum(Case When fiscal_year = cal.curr_fy - 0 Then nugft.credit_amount Else 0 End)
      As cfy_nult_giving
    , sum(Case When fiscal_year = cal.curr_fy - 1 Then nugft.credit_amount Else 0 End)
      As lfy_nult_giving
    , sum(Case When fiscal_year = cal.curr_fy - 2 Then nugft.credit_amount Else 0 End)
      As lfy2_nult_giving
  From nu_gft_trp_gifttrans nugft
  Cross Join rpt_pbh634.v_current_calendar cal
  Inner Join all_committees
    On all_committees.id_number = nugft.id_number
  Where tx_gypm_ind != 'Y' -- No pledge payments
    And fiscal_year Between cal.curr_fy - 2 And cal.curr_fy
  Group By nugft.id_number
    
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
  , v_entity_ksm_degrees.degrees_concat
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
  , Case When gab.short_desc = 'KSM Global Advisory Board' Then 'Y' Else 'N' End
    As gab_ind
  , gab.start_dt As gab_start_date
  , gab.stop_dt As gab_stop_date
  , gab.status As gab_status
  , gab.role As gab_role
  , Case When kfn.short_desc = 'Kellogg Finance Network' Then 'Y' Else 'N' End
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
  , nvl(prs.giving_total, 0) As nu_lt_giving
  , nvl(fy_nu_giving.cfy_nult_giving, 0) As cfy_nult_giving
  , nvl(fy_nu_giving.lfy_nult_giving, 0) As lfy_nult_giving
  , nvl(fy_nu_giving.lfy2_nult_giving, 0) As lfy2_nult_giving
  , nvl(v_ksm_giving_summary.ngc_lifetime_full_rec, 0) As ksm_lt_giving
  , nvl(v_ksm_giving_campaign.campaign_giving,0) As ksm_campaign_giving
  , nvl(proposalcount.proposalcount, 0) As proposal_count
  , nvl(v_ksm_giving_summary.af_cfy, 0) As af_cfy_sftcredit
  , nvl(v_ksm_giving_summary.af_pfy1, 0) As af_lyfy_sftcredit
  , nvl(v_ksm_giving_summary.af_pfy2, 0) As af_lyfy2_sftcredit
  , nvl(v_ksm_giving_summary.ngc_cfy, 0) As ksm_cfy_sftcredit
  , nvl(v_ksm_giving_summary.ngc_pfy1, 0) As ksm_lyfy_sftcredit
  , nvl(v_ksm_giving_summary.ngc_pfy2, 0) As ksm_lyfy2_sftcredit
  , nvl(v_ksm_giving_campaign.campaign_cfy, 0) As campaign_cfy
  , nvl(v_ksm_giving_campaign.campaign_pfy1, 0) As campaign_pfy1 
  , nvl(v_ksm_giving_campaign.campaign_pfy2, 0) As campaign_pfy2
  , nvl(v_ksm_giving_campaign.campaign_pfy3, 0) As campaign_pfy3
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
Left Join rpt_pbh634.v_entity_ksm_degrees
  On v_entity_ksm_degrees.id_number = prs.id_number
Left Join proposalcount
  On proposalcount.prospect_id = prs.prospect_id
Left Join rpt_pbh634.v_ksm_giving_summary
  On v_ksm_giving_summary.id_number = all_committees.id_number
Left Join v_ksm_giving_campaign
  On all_committees.id_number = v_ksm_giving_campaign.id_number
Left Join fy_nu_giving
  On all_committees.id_number = fy_nu_giving.id_number
;
