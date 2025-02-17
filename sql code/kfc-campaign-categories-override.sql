-- Kellogg Full Circle campaign categories override
-- To classify TBD PGs

With

kfc As (
  Select kfc.*
  From table(ksm_pkg_allocation.tbl_alloc_campaign_kfc) kfc
)

Select src.*
, kfc.allocation_code
, kfc.alloc_name
, kfc.campaign_priority
, Case
  -- END TBD
    When kfc.allocation_code = '4604002532801END'
      Then Case
        When rcpt_or_proposal_id In ('0003085142', '0003085142', '0003085142', '0003102430', '0003102430', '0003102430')
          Then 'Faculty'
        When rcpt_or_proposal_id In ('0003094530', '0003094530', '0003094530', '0003099421', '0003099421')
          Then 'Students'
        Else 'TBD'
        End
  -- CRU TBD
    When kfc.allocation_code = '3303000891601GFT'
      Then Case
        When rcpt_or_proposal_id In ('0002999795', '0002999795')
          Then 'Faculty'
        When rcpt_or_proposal_id In ('0003094663', '0003106764', '0003106764', '0003106764', '0003108715')
          Then 'Students'
        Else 'TBD'
        End
    Else kfc.campaign_priority
    End
    As "Campaign Priority"
From vt_campaign_data_src src
Inner Join kfc
  On kfc.alloc_name = src.alloc_or_proposal
