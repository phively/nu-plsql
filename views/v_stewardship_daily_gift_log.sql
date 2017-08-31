Create Or Replace View v_stewardship_daily_gift_log As

With

/* Date range to use */
dts As (
--  Select prev_month_start As dt1, yesterday As dt2, curr_fy
  /* Alternate date ranges for debugging */
  Select cal.prev_fy_start As dt1, yesterday As dt2, curr_fy -- multi year data
--  Select to_date('06/29/2017', 'mm/dd/yyyy') As dt1, to_date('06/29/2017', 'mm/dd/yyyy') As dt2, curr_fy -- point-in-time
/* Check spouse faculty/staff or both faculty/staff */
--  Select to_date('06/29/2017', 'mm/dd/yyyy') As dt1, to_date('06/29/2017', 'mm/dd/yyyy') As dt2, curr_fy
--  Select something or other -- GAB members
  From rpt_pbh634.v_current_calendar cal
),

/* KSM degrees and programs */
ksm_deg As ( -- Defined in ksm_pkg
  Select ksm.id_number, ksm.degrees_concat, trim(ksm.program_group) As program_group
  From table(rpt_pbh634.ksm_pkg.tbl_entity_degrees_concat_ksm) ksm
),

/* GAB indicator */
gab As ( -- GAB membership defined by ksm_pkg
  Select gab.id_number, trim(gab.status || ' ' || gab.role) As gab_role
  From table(rpt_pbh634.ksm_pkg.tbl_committee_gab) gab
),
gab_ind As ( -- Include all receipts where at least one GAB member is associated
  Select gft.tx_number, gab.gab_role
  From nu_gft_trp_gifttrans gft
  Inner Join gab
    On gab.id_number = gft.id_number
),

/* KLC gift club */
klc As (
  Select gift_club_id_number As id_number, substr(gift_club_end_date, 0, 4) As fiscal_year
  From gift_clubs
  Where gift_club_code = 'LKM'
),
klc_years As (
Select id_number,
  listagg(fiscal_year, ', ') Within Group (Order By fiscal_year Desc) As klc_years
From klc
Group By id_number
),

/* Dean's salutations */
dean_sal As ( -- id_number 0000299349 = Dean Sally Blount
  Select dean.id_number, dean.salutation_type_code, dean.salutation, dean.active_ind
  From salutation dean
  Inner Join ksm_deg
    On ksm_deg.id_number = dean.id_number
  Where signer_id_number = '0000299349'
    And active_ind = 'Y'
),

/* Current faculty and staff */
facstaff As ( -- Based on NU_RPT_PKG_SCHOOL_TRANSACTION
  Select Distinct af.id_number, tms_affil.short_desc
  From Affiliation af
  Inner Join tms_affiliation_level tms_affil
    On af.affil_level_code = tms_affil.affil_level_code
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

/* First gift made to Kellogg */
first_gift As (
  Select id_number, min(date_of_record) as first_ksm_gift_dt
  From v_ksm_giving_trans
  Group By id_number
),

/* Joint gift indicator */
joint_ind As ( -- Cleaned up from ADVANCE_NU.NU_RPT_PKG_SCHOOL_TRANSACTION
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
),

/* Transactions to use */
trans As (
  Select gft.tx_number, gft.tx_sequence,
  -- Pledge comment, if applicable
  Case
    When gft.tx_gypm_ind = 'P' Then ppldg.prim_pledge_comment
    Else ppldgpay.prim_pledge_comment
  End As pledge_comment
  -- Tables
  From nu_gft_trp_gifttrans gft
  Cross Join dts -- Date ranges; 1 row only so cross join has no performance impact
  Left Join pledge
    On pledge.pledge_pledge_number = gft.tx_number
    And pledge.pledge_sequence = gft.tx_sequence
  Left Join primary_pledge ppldg On ppldg.prim_pledge_number = gft.tx_number -- For pledge trans types
  Left Join primary_pledge ppldgpay On ppldgpay.prim_pledge_number = gft.pmt_on_pledge_number -- For pledge payment trans types
  Where
    trunc(gft.first_processed_date) Between dts.dt1 And dts.dt2 -- Only selected dates
    And ( -- Only Kellogg, or BE/LE with Kellogg program code
          -- IMPORTANT: nu_gft_trp_gifttrans does NOT include the BE/LE allocations! (June 2017)
      nwu_std_alloc_group = 'KM'
      Or (gft.transaction_type In ('BE', 'LE')
          And gft.nwu_std_alloc_group = 'UO'
          And pledge.pledge_program_code = 'KM')
    )
),

/* Concatenated associated donor data */
assoc_dnrs As ( -- One id_number per line
  Select gft.tx_number, gft.tx_sequence, gft.alloc_short_name, gft.id_number, gft.donor_name, entity.institutional_suffix,
    -- Replace nulls with space
    nvl(ksm_deg.degrees_concat, ' ') As degrees_concat, nvl(gab.gab_role, ' ') As gab_role,
    nvl(facstaff.short_desc, ' ') As facstaff, nvl(klc_years.klc_years, ' ') As klc_years,
    to_char(first_gift.first_ksm_gift_dt, 'mm/dd/yyyy') As first_ksm_gift_dt
  From nu_gft_trp_gifttrans gft
  -- Only people attributed on the KSM receipts
  Inner Join trans On trans.tx_number = gft.tx_number And trans.tx_sequence = gft.tx_sequence
  Inner Join entity On entity.id_number = gft.id_number
  -- Entity indicators
  Left Join ksm_deg On ksm_deg.id_number = gft.id_number
  Left Join gab On gab.id_number = gft.id_number
  Left Join facstaff On facstaff.id_number = gft.id_number
  Left Join klc_years On klc_years.id_number = gft.id_number
  Left Join first_gift On first_gift.id_number = gft.id_number
),
assoc_concat As ( -- Multiple id_numbers per line, separated by carriage return
  Select tx_number, alloc_short_name,
    Listagg(institutional_suffix, ';  ') Within Group (Order By tx_sequence) As inst_suffixes,
    Listagg(trim(donor_name) || ' (#' || id_number || ')', ';  ') Within Group (Order By tx_sequence) As assoc_donors,
    Listagg(degrees_concat, ';  ') Within Group (Order By tx_sequence) As assoc_degrees,
    Listagg(gab_role, ';  ') Within Group (Order By tx_sequence) As assoc_gab,
    Listagg(facstaff, ';  ') Within Group (Order By tx_sequence) As assoc_facstaff,
    Listagg(klc_years, ';  ') Within Group (Order By tx_sequence) As assoc_klc,
    Listagg(first_ksm_gift_dt, ';  ') Within Group (Order By tx_sequence) As first_ksm_gifts
  From assoc_dnrs
  Group By tx_number, alloc_short_name
)

/* Main query */
Select Distinct
  -- Recategorize BE and LE, as suggested by ADVANCE_NU.NU_RPT_PKG_SCHOOL_TRANSACTION
  Case When gft.transaction_type In ('BE', 'LE') And gft.nwu_std_alloc_group = 'UO'
    Then pledge.pledge_program_code
    Else gft.nwu_std_alloc_group
  End As nwu_std_alloc_group,
  -- Entity identifiers
  gft.id_number,
  entity.pref_mail_name,
  -- Associated donors
  assoc.assoc_donors,
  Case When trim(assoc.assoc_degrees) <> ';' Then trim(assoc.assoc_degrees) End As assoc_degrees,
  assoc.inst_suffixes,
  assoc.first_ksm_gifts,
  -- Notations
  Case When trim(assoc.assoc_facstaff) <> ';' Then trim(assoc.assoc_facstaff) End As assoc_facstaff,
  Case When trim(assoc.assoc_gab) <> ';' Then trim(assoc.assoc_gab) End As assoc_gab,
  Case When trim(assoc.assoc_klc) <> ';' Then trim(assoc.assoc_klc) End As assoc_klc,
  gft.nwu_trustee_credit,
  -- Joint gift data
  Case When joint_ind.joint_ind Is Not Null Then 'Y' Else 'N' End As joint_ind,
  Case When joint_ind.joint_ind Is Not Null Then entity.spouse_id_number End As joint_id_number,
  Case When joint_ind.joint_ind Is Not Null
    Then (
      Select e.pref_mail_name
      From entity e
      Where entity.spouse_id_number = e.id_number
    ) End As joint_name,
  -- Salutations
  dean_sal.salutation As dean_salutation1,
  jdean_sal.salutation As dean_salutation2,
  entity.first_name As first_name1,
  Case When joint_ind.joint_ind Is Not Null
    Then (
      Select e.first_name
      From entity e
      Where entity.spouse_id_number = e.id_number
    ) End As first_name2,
  -- Biodata
  tms_rt.short_desc As record_type,
  Case When joint_ind.joint_ind Is Not Null Then (
    Select tms_record_type.short_desc
    From entity e
    Left Join tms_record_type On tms_record_type.record_type_code = e.record_type_code
    Where entity.spouse_id_number = e.id_number
  ) End As joint_record_type,
  entity.pref_class_year,
  tms_school.short_desc As pref_school,
  ksm_deg.program_group As ksm_program,
  ksm_deg.degrees_concat As ksm_degrees,
  Case When joint_ind.joint_ind Is Not Null Then jksm_deg.program_group End As joint_ksm_program,
  Case When joint_ind.joint_ind Is Not Null Then jksm_deg.degrees_concat End As joint_ksm_degrees,
  -- Address data
  addr.line_1,
  addr.line_2,
  addr.line_3,
  addr.line_4,
  addr.line_5,
  addr.line_6,
  addr.line_7,
  addr.line_8,
  -- Transaction data
  gft.tx_gypm_ind,
  gft.tx_number,
  gft.tx_sequence,
  tms_trans.transaction_type,
  gft.pmt_on_pledge_number,
  trans.pledge_comment,
  gft.date_of_record,
  Case When trunc(gft.date_of_record) = trunc(first_gift.first_ksm_gift_dt) Then 'Y' End As first_gift,
  gft.processed_date,
  gft.legal_amount,
  gft.alloc_short_name,
  allocation.long_name As alloc_long_name,
  gft.alloc_purpose_desc,
  Case
    When lower(gft.alloc_short_name) Like '%scholarship%' Or lower(gft.alloc_purpose_desc) Like '%scholarship%' Then 'Y'
  End As scholarship_flag,
  gft.appeal_code,
  appeal_header.description As appeal_desc,
  -- Prospect fields
  prs.prospect_manager,
  prs.team,
  -- Dates
  dts.curr_fy
-- Tables start here
-- Gift reporting table
From nu_gft_trp_gifttrans gft
-- Calendar objects
Cross Join dts
-- Only include desired receipt numbers
Inner Join trans
  On trans.tx_number = gft.tx_number
  And trans.tx_sequence = gft.tx_sequence
-- Entity table
Inner Join entity
  On entity.id_number = gft.id_number
-- Allocation table
Inner Join allocation
  On allocation.allocation_code = gft.allocation_code
-- Entity record type TMS definition
Inner Join tms_record_type tms_rt
  On tms_rt.record_type_code = gft.record_type_code
-- Transaction type TMS definition
Inner Join tms_trans
  On tms_trans.transaction_type_code = gft.transaction_type
-- Associated donor fields
Inner Join assoc_concat assoc
  On assoc.tx_number = gft.tx_number
  And assoc.alloc_short_name = gft.alloc_short_name
-- Salutations
Left Join dean_sal
  On dean_sal.id_number = gft.id_number
Left Join dean_sal jdean_sal
  On jdean_sal.id_number = entity.spouse_id_number
-- Joint gifts
Left Join joint_ind
  On joint_ind.tx_number = gft.tx_number And joint_ind.tx_sequence = gft.tx_sequence
-- Pledge table
Left Join pledge
  On pledge.pledge_pledge_number = gft.tx_number
  And pledge.pledge_sequence = gft.tx_sequence
-- Other gift attributes
Left Join first_gift
  On first_gift.id_number = gft.id_number
-- Degree info
Left Join tms_school
  On tms_school.school_code = entity.pref_school_code
Left Join ksm_deg
  On ksm_deg.id_number = gft.id_number
Left Join ksm_deg jksm_deg
  On jksm_deg.id_number = entity.spouse_id_number
-- Preferred addresses
Left Join addr
  On addr.id_number = gft.id_number
-- Prospect reporting table
Left Join nu_prs_trp_prospect prs
  On prs.id_number = gft.id_number
-- Appeal code definitions
Left Join appeal_header
  On appeal_header.appeal_code = gft.appeal_code
-- Conditions
Where gft.legal_amount > 0 -- Only legal donors
