/*
Select *
From dm_alumni.fact_giving_credit_details gc
Where gc.source_type = 'Matching Gift Payment'
;

Select
  gc.source
  , gc.source_type
  , sum(gc.full_transaction_amount) As trns
  , sum(gc.full_cash_amount) As cash
  , sum(gc.full_commitment_amount) As comm
  , sum(gc.full_ngc_amount) As ngc
From dm_alumni.fact_giving_credit_details gc
Where gc.giving_source_donor_sid Is Not Null
Group By
  gc.source
  , gc.source_type
;

Select
  gc.opportunity_sid
  , opp.opportunity_record_id
  , gc.receipt_number
  , gc.hard_and_soft_credit_record_id
  , gc.credit_amount
  , gc.hard_credit_amount
  , gc.hard_credit_countable_amount
  , gc.hard_credit_discounted_pledge_amount
  , gc.soft_credit_discounted_pledge_amount
  , gc.credit_date
  , gc.fiscal_year
  , gc.credit_type
  , gc.source
  , gc.source_type
  , Case
      When gc.source_type = 'Outright Gift' Then 'G'
      When gc.source_type = 'Matching Gift Payment' Then 'M'
      When gc.source_type = 'Pledge' Then 'P'
      When gc.source_type Like '%Payment%' Then 'Y'
      End
    As gypm_ind
  , des.designation_record_id
  , des.designation_name
  , des.legacy_allocation_code
  , gc.payment_record_id
  , don.donor_id
  , don.donor_name
  , don.constituent_or_organization
  , srcdon.donor_id
    As bi_source_donor_id
  , srcdon.donor_name
    As bi_source_donor_name
--------------------
, kdes.cash_category
, kdes.full_circle_campaign_priority
--------------------
From dm_alumni.fact_giving_credit_details gc
Left Join dm_alumni.dim_opportunity opp
  On opp.opportunity_sid = gc.opportunity_sid
Left Join dm_alumni.dim_donor don
  On don.donor_sid = gc.donor_sid
Left Join dm_alumni.dim_donor srcdon
  On srcdon.donor_sid = gc.giving_source_donor_sid
Left Join dm_alumni.dim_designation des
  On des.designation_sid = gc.designation_sid
--------------------
INNER JOIN mv_ksm_designation kdes
ON kdes.designation_record_id = des.designation_record_id
WHERE gc.fiscal_year BETWEEN 2022 AND 2024
;
*/
/*
-- Experimenting with combined pull
With
gc As (
  Select
    gc.hard_and_soft_credit_salesforce_id
    , gc.receipt_number
    , gc.hard_and_soft_credit_record_id
    , gc.credit_amount
    , gc.hard_credit_amount
    , gc.hard_credit_countable_amount
    , gc.hard_credit_discounted_pledge_amount
    , gc.soft_credit_discounted_pledge_amount
    , gc.credit_date
    , gc.fiscal_year
    , gc.credit_type
    , gc.source
    , gc.source_type
    -- GYPM deliberately leaves some source as NULL
    -- Business purpose is to distinguish between GYM cash and GPM NGC
    , Case
        When gc.source_type = 'Outright Gift' Then 'G'
        When gc.source_type = 'Matching Gift Payment' Then 'M'
        When gc.source_type = 'Pledge' Then 'P'
        When gc.source_type Like '%Payment%' Then 'Y'
        End
      As gypm_ind
    , gc.opportunity_salesforce_id
    , gc.designation_salesforce_id
    , gc.payment_record_id
    , don.donor_id
    , don.donor_name
    , don.constituent_or_organization
    , srcdon.donor_id
      As bi_source_donor_id
    , srcdon.donor_name
      As bi_source_donor_name
  From dm_alumni.fact_giving_credit_details gc
  Left Join dm_alumni.dim_donor don
    On don.donor_sid = gc.donor_sid
  Left Join dm_alumni.dim_donor srcdon
    On srcdon.donor_sid = gc.giving_source_donor_sid
)

Select
  gc.receipt_number
  , gc.hard_and_soft_credit_record_id
  , gc.credit_amount
  , gc.hard_credit_amount
  , gc.hard_credit_countable_amount
  , gc.hard_credit_discounted_pledge_amount
  , gc.soft_credit_discounted_pledge_amount
  , gc.credit_date
  , opp.credit_date
    As opp_credit_date
  , gc.fiscal_year
  , opp.fiscal_year
    As opp_fiscal_year
  , gc.credit_type
  , gc.source
  , gc.source_type
  , gypm_ind
  , gc.payment_record_id
  , gc.donor_id
  , gc.donor_name
  , gc.bi_source_donor_id
  , gc.bi_source_donor_name
  , opp.opportunity_record_id
  , opp.legacy_receipt_number
  , opp.opportunity_record_type
  , opp.opportunity_type
  , opp.is_anonymous_indicator
  , opp.anonymous_type
  , d.designation_record_id
  , d.designation_name
  , d.designation_status
  , d.legacy_allocation_code
  , d.cash_category
  , d.full_circle_campaign_priority
  , d.ksm_af_flag
From gc
Inner Join table(dw_pkg_base.tbl_opportunity) opp
  On opp.opportunity_salesforce_id = gc.opportunity_salesforce_id
Inner Join mv_ksm_designation d
  On d.designation_salesforce_id = gc.designation_salesforce_id
Where gc.fiscal_year Between 2022 And 2024
;
*/
/*
-- Rewrite from base object
-- Appears that donor info is only filled in when it diverges from the opportunity interestingly
-- So hard and soft credit should not try to map out all gift credit linkages; leave that for ksm_pkg layer
Select
    hsc.id
    As hard_and_soft_credit_salesforce_id
  , hsc.ucinn_ascendv2__receipt_number__c
    As receipt_number
  , hsc.name
    As hard_and_soft_credit_record_id
  , hsc.ucinn_ascendv2__credit_amount__c
    As credit_amount
    -- Hard credit calculation
  , Case
      When hsc.ucinn_ascendv2__credit_type__c = 'Hard'
        Then hsc.ucinn_ascendv2__credit_amount__c
        Else 0
      End
    As hard_credit_amount
  , hsc.ucinn_ascendv2__credit_date_formula__c
    As credit_date
  , hsc.nu_fiscal_year__c
    As fiscal_year
  , hsc.ucinn_ascendv2__credit_type__c
    As credit_type
  , hsc.ucinn_ascendv2__source__c
  , hsc.ucinn_ascendv2__opportunity__c
    As opportunity_salesforce_id
  , hsc.ucinn_ascendv2__designation__c
    As designation_salesforce_id
  , hsc.ucinn_ascendv2__designation_code_formula__c
    As designation_record_id
  , hsc.ucinn_ascendv2__credit_id__c
    As donor_salesforce_id
  , e.donor_id
  , e.full_name
    As donor_name
  , hsc.ucinn_ascendv2__hard_credit_recipient_account__c
    As hard_credit_salesforce_id
  , e2.donor_id
    As hard_credit_donor_id
  , hsc.ucinn_ascendv2__hard_credit_formula__c
    As hard_credit_donor_name
From stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c hsc
Left Join mv_entity e
  On e.salesforce_id = hsc.ucinn_ascendv2__credit_id__c
Left Join mv_entity e2
  On e2.salesforce_id = hsc.ucinn_ascendv2__hard_credit_recipient_account__c
INNER JOIN mv_ksm_designation des
  ON des.designation_salesforce_id = hsc.ucinn_ascendv2__designation__c
  AND hsc.nu_fiscal_year__c BETWEEN 2022 AND 2024
;
*/
/*
With

gcred As (
  Select
      hsc.id
      As hard_and_soft_credit_salesforce_id
    , hsc.ucinn_ascendv2__receipt_number__c
      As receipt_number
    , hsc.name
      As hard_and_soft_credit_record_id
    , hsc.ucinn_ascendv2__credit_amount__c
      As credit_amount
      -- Hard credit calculation
    , Case
        When hsc.ucinn_ascendv2__credit_type__c = 'Hard'
          Then hsc.ucinn_ascendv2__credit_amount__c
          Else 0.0
        End
      As hard_credit_amount
    , hsc.ucinn_ascendv2__credit_date_formula__c
      As credit_date
    , hsc.nu_fiscal_year__c
      As fiscal_year
    , hsc.ucinn_ascendv2__credit_type__c
      As credit_type
    , hsc.ucinn_ascendv2__source__c
      As source
    , hsc.ucinn_ascendv2__opportunity__c
      As opportunity_salesforce_id
    , hsc.ucinn_ascendv2__designation__c
      As designation_salesforce_id
    , hsc.ucinn_ascendv2__designation_code_formula__c
      As designation_record_id
    , hsc.ucinn_ascendv2__contact_name_and_donor_id_formula__c
      As donor_name_and_id
    , regexp_substr(substr(hsc.ucinn_ascendv2__contact_name_and_donor_id_formula__c, -10), '[0-9]+')
      As donor_id
    , hsc.ucinn_ascendv2__credit_id__c
      As donor_salesforce_id
    , e.donor_id
      As entity_donor_id
    , e.full_name
      As donor_name
    , hsc.ucinn_ascendv2__hard_credit_recipient_account__c
      As hard_credit_salesforce_id
    , e2.donor_id
      As hard_credit_donor_id
    , hsc.ucinn_ascendv2__hard_credit_formula__c
      As hard_credit_donor_name
  From stg_alumni.ucinn_ascendv2__hard_and_soft_credit__c hsc
  Left Join mv_entity e
    On e.salesforce_id = hsc.ucinn_ascendv2__credit_id__c
  Left Join mv_entity e2
    On e2.salesforce_id = hsc.ucinn_ascendv2__hard_credit_recipient_account__c
)

Select
    gcred.donor_name_and_id
  , gcred.donor_id
  , gcred.entity_donor_id
    As credited_donor_id
  , gcred.donor_name
    As credited_donor_name
  , opp.opportunity_donor_id
  , opp.opportunity_donor_name
  , mve.donor_id
    As entity_donor_id
  , mve.full_name
    As entity_donor_name
  , opp.opportunity_record_id
  , opp.anonymous_type
  , opp.legacy_receipt_number
    As opp_receipt_number
  , opp.opportunity_stage
  , opp.opportunity_record_type
  , opp.opportunity_type
  -- GYPM deliberately leaves some source as NULL
  -- Business purpose is to distinguish between GYM cash and GPM NGC
  , Case
      When gcred.source = 'Outright Gift' Then 'G'
      When gcred.source = 'Matching Gift Payment' Then 'M'
      When gcred.source = 'Pledge' Then 'P'
      When gcred.source Like '%Payment%' Then 'Y'
      End
    As gypm_ind
  , gcred.hard_and_soft_credit_salesforce_id
  , gcred.receipt_number
    As credit_receipt_number
  , opp.matched_gift_record_id
  , Case
      When gcred.source = 'Pledge'
        Then opp.opportunity_record_id
      End
    As pledge_record_id
  , opp.linked_proposal_record_id
  , kdes.designation_record_id
  , kdes.designation_status
  , kdes.legacy_allocation_code
  , kdes.designation_name
  , kdes.ksm_af_flag
  , kdes.ksm_cru_flag
  , kdes.cash_category
  , kdes.full_circle_campaign_priority
  , gcred.credit_date
  , gcred.fiscal_year
  , gcred.credit_type
  , gcred.credit_amount
  , gcred.hard_credit_amount
From table(dw_pkg_base.tbl_opportunity) opp
Inner Join gcred
  On gcred.opportunity_salesforce_id = opp.opportunity_salesforce_id
Inner Join mv_ksm_designation kdes
  On kdes.designation_salesforce_id = gcred.designation_salesforce_id
Left Join mv_entity mve
  On mve.donor_id = opp.opportunity_donor_id
Where gcred.fiscal_year Between 2022 And 2024
--Where gcred.hard_and_soft_credit_record_id = 'Credit-250126-9195172'
;

-- How does the custom donor name/id field work?
With gcd As (
Select Distinct donor_name_and_id
, substr(donor_name_and_id, -10)
  As did
, regexp_substr(substr(donor_name_and_id, -10), '[0-9]+')
  As expdid
From dm_alumni.fact_giving_credit_details gcd
)
Select *
From gcd
Where substr(did, 1, 1) != '0'
;
*/

With

gcred As (
  Select
    gc.*
    -- Fill in or extract Donor ID
    , Case
        When gc.donor_salesforce_id Is Not Null
          Then mv_entity.donor_id
        Else
          regexp_substr(
            -- Take last 10 characters of concatenated name/id field
            substr(donor_name_and_id, -10)
            -- Return consecutive digits
            , '[0-9]+'
          )
        End
      As credited_donor_id
  From table(dw_pkg_base.tbl_gift_credit) gc
  Left Join mv_entity
    On mv_entity.salesforce_id = gc.donor_salesforce_id
)

Select
  gcred.credited_donor_id
  , mve.full_name
    As credited_donor_name
  , mve.sort_name
    As credited_donor_sort_name
  , gcred.donor_name_and_id
    As credited_donor_audit
  , opp.opportunity_donor_id
  , opp.opportunity_donor_name
  , opp.opportunity_record_id
  , opp.anonymous_type
  , opp.legacy_receipt_number
    As opp_receipt_number
  , opp.opportunity_stage
  , opp.opportunity_record_type
  , opp.opportunity_type
  -- GYPM deliberately leaves some source as NULL
  -- Business purpose is to distinguish between GYM cash and GPM NGC
  , Case
      When gcred.source = 'Outright Gift' Then 'G'
      When gcred.source = 'Matching Gift Payment' Then 'M'
      When gcred.source = 'Pledge' Then 'P'
      When gcred.source Like '%Payment%' Then 'Y'
      End
    As gypm_ind
  , gcred.hard_and_soft_credit_salesforce_id
  , gcred.receipt_number
    As credit_receipt_number
  , opp.matched_gift_record_id
  , Case
      When gcred.source = 'Pledge'
        Then opp.opportunity_record_id
      End
    As pledge_record_id
  , opp.linked_proposal_record_id
  , kdes.designation_record_id
  , kdes.designation_status
  , kdes.legacy_allocation_code
  , kdes.designation_name
  , kdes.ksm_af_flag
  , kdes.ksm_cru_flag
  , kdes.cash_category
  , kdes.full_circle_campaign_priority
  , gcred.credit_date
  , gcred.fiscal_year
  , gcred.credit_type
  , gcred.credit_amount
  , gcred.hard_credit_amount
From table(dw_pkg_base.tbl_opportunity) opp
Inner Join gcred
  On gcred.opportunity_salesforce_id = opp.opportunity_salesforce_id
Inner Join mv_ksm_designation kdes
  On kdes.designation_salesforce_id = gcred.designation_salesforce_id
Left Join mv_entity mve
  On mve.donor_id = gcred.credited_donor_id
Where gcred.fiscal_year Between 2022 And 2024
;
