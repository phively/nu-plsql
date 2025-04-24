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
