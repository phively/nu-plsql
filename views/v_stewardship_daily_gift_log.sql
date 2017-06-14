--Create Or Replace View v_stewardship_daily_gift_log As

With

/* Date range to use */
dts As (
  Select prev_month_start As dt1, yesterday As dt2
  From rpt_pbh634.v_current_calendar
),

/* KSM degrees and programs */
ksm_alumni As (
  Select ksm.id_number, ksm.degrees_concat, trim(ksm.program_group) As program_group
  From table(rpt_pbh634.ksm_pkg.tbl_entity_degrees_concat_ksm) ksm
),

/* GAB indicator */
gab As (
  Select gab.id_number, trim(gab.status || ' ' || gab.role) As gab_status
  From table(rpt_pbh634.ksm_pkg.tbl_committee_gab) gab
),

/* Dean's salutations */
dean_sal As (
  Select dean.id_number, dean.salutation_type_code, dean.salutation, dean.active_ind
  From salutation dean
  Inner Join ksm_alumni
    On ksm_alumni.id_number = dean.id_number
  Where signer_id_number = '0000299349' -- Dean Sally Blount
    And active_ind = 'Y'
)

/* Main query */
Select
  -- Recategorize BE and LE, as suggested by ADVANCE_NU.NU_RPT_PKG_SCHOOL_TRANSACTION
  Case When gft.transaction_type In ('BE', 'LE') And gft.nwu_std_alloc_group = 'UO'
    Then pledge.pledge_program_code
    Else gft.nwu_std_alloc_group
    End As nwu_std_alloc_group,
  -- All gift table fields
  gft.id_number,
  gft.*
From nu_gft_trp_gifttrans gft
Cross Join dts
Left Join pledge
  On pledge.pledge_pledge_number = gft.tx_number
  And pledge.pledge_sequence = gft.tx_sequence
Where
  trunc(gft.first_processed_date) Between dts.dt1 And dts.dt2
  And (
    nwu_std_alloc_group = 'KM'
    Or (gft.transaction_type In ('BE', 'LE') And gft.nwu_std_alloc_group = 'UO' And pledge.pledge_program_code = 'KM')
  )
