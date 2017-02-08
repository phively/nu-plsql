Create Materialized View advance_nu_rpt.mv_ksm_source_donor
  Refresh Force On Demand
  As

/* Pulls receipts from nu_gft_trp_gifttrans table and appends ksm_source_donor id_number */

Select Distinct gift.tx_number, advance.ksm_source_donor(gift.tx_number) As ksm_source_donor, gift.last_modified_date
From nu_gft_trp_gifttrans gift, rpt_pbh634.current_calendar cal
Where gift.fiscal_year = cal.curr_fy
  And gift.alloc_school = 'KM';
