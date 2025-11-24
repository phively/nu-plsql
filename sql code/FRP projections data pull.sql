-- Unmanaged expendable
Select
  fiscal_year
  , sum(ngc.hard_credit_amount)
    As expendable_unmanaged_ngc
  , 10E6 - round(sum(ngc.hard_credit_amount))
    As expendable_remainder
From v_ksm_gifts_ngc ngc
Where ngc.fiscal_year >= 2020
  And ngc.linked_proposal_record_id Is Null
  And ngc.cash_category = 'Expendable'
Group By fiscal_year
Order By fiscal_year Asc
;

-- Grouped NGC
With

ngc As (
  Select
    n.*
    , Case
        When unsplit_amount >= 5E6
          Then 5E6
        When unsplit_amount >= 1E6
          Then 1E6
        When unsplit_amount >= 250E3
          Then 250E3
        Else 1
        End
      As gift_bin
  From v_ksm_gifts_ngc n
)

Select
  fiscal_year
  , gift_bin
  , sum(ngc.hard_credit_amount)
    As ngc_raised
From ngc
Where ngc.fiscal_year >= 2020
Group By fiscal_year, gift_bin
Order By fiscal_year Asc, gift_bin Desc
;

-- Proposals
With

cal As (
  Select
    c.*
    , extract(month from c.yesterday)
      As curr_month
  From v_current_calendar c
)

Select p.*
  , Case
      When p.proposal_anticipated_amount >= 2E6
        Then 'PG'
      When p.active_proposal_manager_team = 'MG'
        Then 'MG'
      End
    As proposal_category
  , Case
      When p.proposal_stage = 'Approved by Donor'
        Then p.proposal_anticipated_amount
      When p.proposal_stage = 'Submitted'
        Then Case
          When cal.curr_month Between 9 And 12
            Then 0.23 *  p.proposal_anticipated_amount
          When cal.curr_month Between 1 And 5
            Then 0.20 *  p.proposal_anticipated_amount
          When cal.curr_month Between 6 And 7
            Then 0.15 *  p.proposal_anticipated_amount
          When cal.curr_month Between 8 And 8
            Then 0.10 *  p.proposal_anticipated_amount
          End
      When p.proposal_stage = 'Planned'
        Then Case
          When cal.curr_month Between 9 And 12
            Then 0.13 *  p.proposal_anticipated_amount
          When cal.curr_month Between 1 And 5
            Then 0.10 *  p.proposal_anticipated_amount
          When cal.curr_month Between 6 And 7
            Then 0.08 *  p.proposal_anticipated_amount
          When cal.curr_month Between 8 And 8
            Then 0.04 *  p.proposal_anticipated_amount
          End
      End
    As discounted_proposal_anticipated_amount
From mv_proposals p
Cross Join cal
Where p.proposal_close_fy In (2025, 2026)
  And p.proposal_active_indicator = 'Y'
  And p.ksm_flag = 'Y'
;
