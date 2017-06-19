--Create Or Replace View v_stewardship_daily_gift_log As

With

/* Date range to use */
dts As (
--  Select prev_month_start As dt1, yesterday As dt2
  /* Alternate date ranges for debugging */
  Select to_date('06/12/2017', 'mm/dd/yyyy') As dt1, to_date('06/12/2017', 'mm/dd/yyyy') As dt2 -- point-in-time
--  Select something or other -- check joint_name for DAF donors
--  Select something or other -- check spouse faculty/staff or both faculty/staff
  From rpt_pbh634.v_current_calendar
),

/* KSM degrees and programs */
ksm_deg As (
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
  Inner Join ksm_deg
    On ksm_deg.id_number = dean.id_number
  Where signer_id_number = '0000299349' -- Dean Sally Blount
    And active_ind = 'Y'
),

/* Current faculty and staff */
facstaff As (
  Select Distinct af.id_number, tms_af.short_desc
  From Affiliation af
  Inner Join tms_affiliation_level tms_af
    On af.affil_level_code = tms_af.affil_level_code
  Where af.affil_level_code In ('ES', 'EF') -- Staff, Faculty
    And af.affil_status_code = 'C'
),

/* Preferred address */
addr As (
  Select id_number, line_1, line_2, line_3, line_4, line_5, line_6, line_7, line_8
  From address
  Where addr_pref_ind = 'Y'
),

/* Transaction and pledge TMS table definition */
tms_trans As (
  (
    Select transaction_type_code, short_desc As transaction_type
    From tms_transaction_type
  ) Union All (
    Select pledge_type_code, short_desc
    From tms_pledge_type
  )
),

/* Joint gift indicator, cleaned up from ADVANCE_NU.NU_RPT_PKG_SCHOOL_TRANSACTION */
joint_ind As (
  Select gft.tx_number, gft.tx_sequence, 'Y' As joint_ind
  From nu_gft_trp_gifttrans gft
  Where
    Exists (
      Select *
      From nu_gft_trp_gifttrans g
      Where gft.tx_number = g.tx_number
        And g.associated_code In ('J', 'K')
    ) And Exists (
      Select *
      From entity e
      Inner Join nu_gft_trp_gifttrans g
        On e.id_number = g.id_number
      Where gft.tx_number = g.tx_number
        And e.id_number = g.id_number
        And e.spouse_id_number = gft.id_number
        And e.marital_status_code In ('M', 'P')
    )
)

/* Main query */
Select
  -- Recategorize BE and LE, as suggested by ADVANCE_NU.NU_RPT_PKG_SCHOOL_TRANSACTION
  Case When gft.transaction_type In ('BE', 'LE') And gft.nwu_std_alloc_group = 'UO'
    Then pledge.pledge_program_code
    Else gft.nwu_std_alloc_group
  End As nwu_std_alloc_group,
  -- All gift table fields
  gft.id_number, entity.pref_mail_name,
  -- Faculty/staff indicator
  Case
    When joint_ind.joint_ind Is Null Then facstaff.short_desc
    When (facstaff.short_desc || jfacstaff.short_desc) Is Not Null
      Then facstaff.short_desc || ', ' || jfacstaff.short_desc
  End As faculty_staff_ind,
  -- Joint gift data
  Case When joint_ind.joint_ind Is Not Null Then 'Y' Else 'N' End As joint_ind,
  Case When joint_ind.joint_ind Is Not Null Then entity.spouse_id_number End As joint_id_number,
  Case When joint_ind.joint_ind Is Not Null
    Then (
      Select e.pref_mail_name
      From entity e
      Where entity.spouse_id_number = e.id_number
    ) End As joint_name,
  -- Biodata
  tms_rt.short_desc As record_type,
  ksm_deg.program_group As ksm_program,
  Case When joint_ind.joint_ind Is Not Null Then jksm_deg.program_group End As joint_ksm_program,
  -- Address data
  -- Transaction data
  gft.tx_number,
  gft.pmt_on_pledge_number,
  tms_trans.transaction_type,
  gft.date_of_record,
  gft.legal_amount,
  gft.alloc_short_name,
  gft.*
-- Gift reporting table
From nu_gft_trp_gifttrans gft
-- Entity table
Inner Join entity
  On entity.id_number = gft.id_number
-- Entity record type TMS definition
Inner Join tms_record_type tms_rt
  On tms_rt.record_type_code = gft.record_type_code
-- Transaction type TMS definition
Inner Join tms_trans
  On tms_trans.transaction_type_code = gft.transaction_type
-- Date range
Cross Join dts
-- Faculty/staff
Left Join facstaff
  On facstaff.id_number = gft.id_number
Left Join facstaff jfacstaff
  On jfacstaff.id_number = entity.spouse_id_number
-- Joint gifts
Left Join joint_ind
  On joint_ind.tx_number = gft.tx_number And joint_ind.tx_sequence = gft.tx_sequence
-- Pledge table
Left Join pledge
  On pledge.pledge_pledge_number = gft.tx_number
  And pledge.pledge_sequence = gft.tx_sequence
-- Degree info
Left Join ksm_deg
  On ksm_deg.id_number = gft.id_number
Left Join ksm_deg jksm_deg
  On jksm_deg.id_number = entity.spouse_id_number
-- Preferred addresses
Left Join addr
  On addr.id_number = gft.id_number
-- Filters
Where
  trunc(gft.first_processed_date) Between dts.dt1 And dts.dt2
  And gft.legal_amount > 0
  And (
    nwu_std_alloc_group = 'KM'
    Or (gft.transaction_type In ('BE', 'LE') And gft.nwu_std_alloc_group = 'UO' And pledge.pledge_program_code = 'KM')
  )
