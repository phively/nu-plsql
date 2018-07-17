-- Based on "principal gifts checklist _20180316.sql"

--Create Or Replace View v_pg_checklist As

/* N.B. this view uses @catrackstobi connector -- DO NOT RUN OUTSIDE OF BUSINESS HOURS! */

With

-- Entity tables from @catrackstobi
bi_entity As (
  Select
    de.id_number
    , de.primary_record_type_desc
    , de2.primary_record_type_desc sp_record_type
    , de.birth_dt
    , Case
        -- Age not computed for deceased
        When de.record_status_code = 'D' 
          Then NULL
        Else floor(
          -- If date of birth is entered, find months between DOB and now
          -- If no DOB, age is NULL
          months_between(
            sysdate
            , Case
                When de.birth_date_age_basis = de.birth_dt And de.birth_dt <> '00000000'
                  Then to_date(de.birth_dt, 'YYYYMMDD')
                Else NULL
              End) / 12
          )
      End As age 
    , de.pref_class_year
    , de.email_address
    , de.phone_area_code
    , de.phone_number
    , de.giving_affiliation_desc
    , de.pref_mail_name
    , de.pref_name_sort
    , de.person_or_org
    , de.spouse_id_number
  From dm_ard.dim_entity@catrackstobi de
  Left Join dm_ard.dim_entity@catrackstobi de2
    On de.spouse_id_number = de2.id_number
    And de2.current_indicator = 'Y'
    And de2.deleted_flag = 'N'
  Where de.current_indicator = 'Y' 
    And de.deleted_flag = 'N'
    And de.person_or_org = 'P' -- added 2/22/2018
    And de.id_number Not In ('0' , ' ', '-1')
)

-- Per-entity preferred address region
, addresses As (
  Select
    address.id_number
    , Case
        -- USA is usually blank country code
        When address.country_code In (' ', 'US')
          Then tms_states.short_desc
        Else  tc.short_desc
      End As category  
  From address
  Inner Join entity e
    On e.id_number = address.id_number
    And e.record_status_code = 'A'
  Left Join tms_states
    On tms_states.state_code = address.state_code
  Left Join tms_country tc
    On tc.country_code = address.country_code
  Where address.addr_status_code = 'A'
    And address.addr_pref_ind = 'Y'
)

-- Prospect tables from @catrackstobi
, bi_prospects As (
  Select
    coalesce( -- Replace prospect ID = 0 with blank
      Case
        When to_char(dp.prospect_id) = '0'
          Then ' ' 
        Else to_char(dp.prospect_id)
      End
      , ' '
      ) As prospect_id
    , prospect_name
    , prospect_team_desc
    , rating_desc
    , research_evaluation_desc
    , qualification_desc
    , last_contact_report_date
    , last_visit_date
    , visit_count
    , last_pledge_date
    , last_pledge_payment_date
    , prospect_manager_name
    , prospect_manager_id_number
    , prospect_managed_flag
    , active_ind
    , coalesce(rating_desc, ' ') As uor_rating 
    , athletics_prog_flag
    , bienen_prog_flag
    , block_prog_flag
    , center_inst_prog_flag
    , communication_prog_flag
    , feinberg_prog_flag
    , kellogg_prog_flag
    , law_prog_flag
    , library_prog_flag
    , mccormick_prog_flag
    , medill_prog_flag
    , nmh_prog_flag
    , scs_prog_flag
    , sesp_prog_flag
    , stu_life_prog_flag
    , tbd_prog_flag
    , tgs_prog_flag
    , univ_unrs_prog_flag
    , weinberg_prog_flag  
  From dm_ard.dim_prospect@catrackstobi dp
  Inner Join prospect_entity -- added this and below lines on 2/24/2018
    On prospect_entity.prospect_id = dp.prospect_id@catrackstobi
  Inner Join entity
    On entity.id_number = prospect_entity.id_number
  Where dp.deleted_flag = 'N'
    And dp.current_indicator = 'Y'
    And dp.active_ind = 'Y' -- this was previously commented out. changed 2/24/2018. Did not impact count 
    And dp.prospect_id > 0
    And entity.person_or_org = 'P'
    And prospect_entity.primary_ind = 'Y'
)

-- To flag prospects with at least one active proposal
, active_proposals As (
  Select Distinct prospect_id
  From proposal p
  Where p.active_ind = 'Y'
)

-- To flag prospects with active high ask proposals
, active_proposals1m As (
  Select Distinct prospect_id
  From proposal p
  Where p.active_ind = 'Y'
    And p.ask_amt > 1000000 --changed from $2m to $1m 2/22/2018
)

-- Giving data from @catrackstobi
, bi_gift_transactions As (
  Select
    entity_id_number As id_number
    , gift_credit_amount
    , trans_id_number
    , to_date(day_mm_s_dd_s_yyyy_date, 'mm/dd/yyyy') As date_of_record
    , year_of_giving
    , trans.transaction_sub_group_code
    , annual_sw
    , matching_gift_credit_amount + pledge_credit_disc_amount +
        Case When transaction_group_code = 'G' Then gift_credit_amount Else 0 End
      As ncg
    , alloc.alloc_short_name
    , p.pledge_status_code
  From dm_ard.fact_giving_trans@catrackstobi gv
  Left Join dm_ard.dim_date@catrackstobi dt
    On dt.day_date_key = date_of_record_key
  Left Join dm_ard.dim_transaction_group@catrackstobi trans
    On trans.transaction_group_sid = gv.transaction_group_sid
  Left Join dm_ard.dim_allocation@catrackstobi alloc
    On alloc.allocation_sid = gv.allocation_sid
    And alloc.deleted_flag = 'N'
    And alloc.current_indicator = 'Y'
  Left Join dm_ard.dim_primary_pledge@catrackstobi p
    On trans_id_number = p.pledge_number
  Inner Join entity e
    On e.id_number = gv.entity_id_number
    And e.record_status_code = 'A'
  Where transaction_sub_group_code In ('GC', 'YC', 'PC', 'MC') -- Gift, Pledge Payment, Pledge, Matching Gift
)

-- PBH: Consider whether the rest of the giving subqueries can be rolled into bi_gift_transactions

-- Completed major gift of $250K or more 
-- (can include either an outright gift or a pledge, but the pledge must be paid in full) 
, bi_gift_transactions_single As (
  Select Distinct id_number
  From bi_gift_transactions
  Where transaction_sub_group_code In ('GC', 'PC') -- outright gifts & pledges
    And (
      (
        NCG > 250000
        And transaction_sub_group_code = 'GC'
      ) Or (
        NCG > 250000
        And transaction_sub_group_code = 'PC'
        And pledge_status_code = 'P'
      )
    )
)

-- Derived years of giving
, distinct_years As (
  Select
    id_number
    , count(Distinct year_of_giving) As ct
  From bi_gift_transactions
  Group By id_number
)

-- Calculate current fiscal year
, curr_fy As (
  Select
    -- Start with current calendar year, then add 1 if month is 9 through 12
    extract(year From sysdate) +
      (Case When extract(month From sysdate) >= 9 Then 1 Else 0 End)
    As fy
  From DUAL
)

-- Derived years of giving out of last 3
, distinct_years_last_3 As (
  Select
    id_number
    , count(Distinct year_of_giving) As ct
  From bi_gift_transactions
  Cross Join curr_fy
  Where year_of_giving Between -- Must be between (this year - n) and (this year)
    curr_fy.fy - 2 And curr_fy.fy
  Group By id_number
)

-- Made a $25K+ AF gift, based on @catrackstobi
-- added 2/23/2018
, annual_25k As (
  Select entity_key
  From dm_ard.fact_donor_summary@catrackstobi
  Where annual_fund_flag = 'Y'
    And reporting_area = 'NA'
    And (
      max_fyear_giftcredit >= 25000
      Or max_fyear_pledgecredit >= 25000
    )
)

-- Total Unique Years of Giving
, bi_gift_transactions_summary As (
  Select
    id_number
    , gift_credit_amount
    , trans_id_number
    , date_of_record
    , year_of_giving
    , row_number() Over (Partition By id_number Order By date_of_record Desc)
      As rownumber
    , count(Distinct year_of_giving) Over (Partition By id_number)
      As yr_count
  From bi_gift_transactions
)

-- Lifetime giving from @catrackstobi
-- overall giving summaries, aggregated
-- FY should be set to current fy, per BI logic
, giving_lifetime As (
  Select
    entity_key As id_number
    , lifetime_gift_credit_amount
    , to_char(last_gift_year) As last_gift_year
    , gift_credit_yrs_in_prev5
    , prevyears_giftcredit_1000
    , lifetime_newgift_cmit_w_spouse
    , campaign_newgift_cmit_credit
    , active_pledge_balance
  From dm_ard.fact_donor_summary@catrackstobi
  Where annual_fund_flag = 'N'
    And reporting_area = 'NA'
)

-- NU degrees concatenated
, all_NU_degrees As (
  Select
    id_number
    , listagg(tms_school.short_desc || ' , ' || degree_code || ', ' || degree_year ,  ' ; ' )
        Within Group (Order By id_number)
        As schoolslist
  From degrees
  Left Join tms_school
    On tms_school.school_code = degrees.school_code
  Where degrees.degree_year != ' '
    And (
      -- NU grads code
      degrees.institution_code = '31173'
      Or local_ind = 'Y'
    )
  Group By id_number
)

-- Entity contact reports
, contact_reports As (
  Select
    contact_report.id_number
    , e.pref_mail_name
    , contact_date
    , contact_type
    , p.short_desc As contact_purpose
    , contact_report.author_id_number
  From contact_report
  Left Join entity e
    On e.id_number = contact_report.author_id_number
  Left Join tms_contact_rpt_purpose p
    On p.contact_purpose_code = contact_report.contact_purpose_code
  Where contact_report.id_number <> ' '
Union All
  Select
    contact_report.id_number_2
    , e.pref_mail_name
    , contact_date
    , contact_type
    , p.short_desc as contact_purpose
    , contact_report.author_id_number
  From contact_report
  Left Join entity e
    On e.id_number = contact_report.author_id_number
  Left Join tms_contact_rpt_purpose p
    On p.contact_purpose_code = contact_report.contact_purpose_code
  Where contact_report.id_number_2 <> ' '
)

-- Contact report summary info
, contact_summary As (
  Select
    id_number
    -- Most recent contact report
    , max(contact_date) As last_contact_date
    -- Most recent visit
    , max(Case When contact_type = 'V' Then contact_date End) As last_visit_date
    -- Count of all contact reports
    , count(id_number) As contact_rpt_count
    -- Count of all visits
    , count(Case When contact_type = 'V' Then id_number End) As visit_count
    -- Count of last year's contact reports
    , count(Case When contact_date >= sysdate - 365 Then id_number End)
      As contact_rpt_count_last_yr
    -- Count of last year's visits
    , count(Case When contact_date >= sysdate - 365 And contact_type = 'V' Then id_number End)
      As visit_count_last_yr
    -- President visits
    , count(Case When author_id_number = '0000573302' And contact_type = 'V' Then id_number End)
      As mos_visit
  From contact_reports
  Group By id_number
)

-- All contact reports per contacted entity and author
, contacts As (
  Select
    id_number
    , pref_mail_name
    , contact_date
    , contact_type
    , contact_purpose
    , author_id_number
    , row_number() Over (Partition By id_number, author_id_number Order By contact_date Desc)
      As rownumber
    , row_number() Over (Partition By id_number, author_id_number, contact_type Order By contact_date Desc)
      As rownumber2
    , row_number() Over (Partition By id_number, contact_type Order By contact_date Desc)
      As rownumber3
  From contact_reports
)

-- Parent affiliation
, parents As (
  Select Distinct id_number
  From affiliation
  Left Join tms_affil_code tac
    On tac.affil_code = affiliation.affil_code
  Where affil_level_code = 'PR' -- Parent
    And affil_status_code In ('C', 'P') -- Current or Past
)

-- Committee participation
, committees As (
  Select id_number
  From committee
  Inner Join committee_header
    On committee_header.committee_code = committee.committee_code
    And committee_header.committee_type_code In ('TB', 'AB') -- Trustee Board, Advisory Board
    And committee_header.status_code = 'A'
  Where committee.committee_status_code In ('C', 'F') -- Current or Former
Union
  Select id_number
  From affiliation
  Where affiliation.affil_code = 'TR' -- Trustee
  And affiliation.affil_status_code In ('C', 'P') -- Current or Past
)

-- Season ticket holders
-- updated season tickets logic 2/22/2018. Now looks for people who have 3+ years of season tickets
, seasontickets As (
  Select Distinct id_number
  From activity
  Where activity_code In ('BBSEA', 'FBSEA') -- Basketball and Football season tickets
  Having count(Distinct substr(start_dt, 1, 4)) > 2 -- 2 or more years
  Group By id_number 
)

-- Affinity score segment
, affinity_score_all_rows As
(
  Select
    segment.id_number
    , segment_code
    , Case
        When nvl(length(trim(translate(xcomment, '0123456789.-', ' '))), 0) = 0
          Then round(to_number(rtrim(ltrim(xcomment))))
        Else NULL
      End As affinity_score
    , Case
        When nvl(length(trim(translate(xcomment, '0123456789.-', ' '))), 0) = 0
          Then to_number(rtrim(ltrim(xcomment)))
        Else NULL
      End As affinity_score_detail
  From segment
  Where segment.segment_code Like 'AFF__'
)

-- Return a single affinity score
-- entity merges can create multiple rows for same entity
, affinity_score_value As (
  Select
    id_number
    , max(segment_code) As affinity_segment
    , max(affinity_score) As affinity_score
    , max(affinity_score_detail) As affinity_score_detail
  From affinity_score_all_rows
  Group By id_number
)

-- Flag home addresses in the Chicago geo area
-- chicago_home added 2/22/2018. 
, chi_t1_home As (
  Select address.id_number
  From address
  Inner Join address_geo
    On address.id_number = address_geo.id_number
    And address.xsequence = address_geo.xsequence 
  Inner Join geo_code
    On address_geo.geo_code = geo_code.geo_code
  Where address.addr_type_code = 'H'
    And address.addr_status_code = 'A'
    And address_geo.geo_code = 'T1CH' -- Tier 1 Chicago
)

-- Main query
Select
  be.id_number As "Primary Entity ID"
  , p.prospect_id As "Prospect ID"
  , p.prospect_name As "Prospect Name"
  , p.qualification_desc As "Qualification Level"
  , a.category As "Pref State US/ Country (Int)"
  , nvl(all_nu_degrees.schoolslist, ' ') As "All NU Degrees"
  , nvl(nu_deg_spouse.schoolslist, ' ') As "All NU Degrees Spouse" 
  , Case
      When ap.prospect_id Is Not NULL
        Then 1
      Else 0
    End As "Active Prop Indicator"
  -- Y/N inds
  , Case When be.age > 59 Then 1 Else 0 End
    As Age
  , Case When c_v_prmgr.contact_date > sysdate - (2 * 365) Then 1 Else 0 End
    As "PM Visit Last 2Yrs"
  , Case When contact_summary.visit_count >= 5 Then 1 Else 0 End
    As "5 + Visits C Rpts"
  , Case When annual_25k.entity_key Is Not NULL Then 1 Else 0 End
    As "25K To Annual"
  , Case When (dy.ct >= 10 And dy3.ct >= 1) Then 1 Else 0 End
    As "10+ Dist Yrs 1 Gft in Last 3"
  , Case When bi_gift_transactions_single.id_number Is Not NULL Then 1 Else 0 End
    As "MG $250000 or more"
  , Case When contact_summary.mos_visit > 0 Then 1 Else 0 End
    As "Morty Visit"
  , Case When committees.id_number Is Not NULL Then 1 Else 0 End
    As "Trustee or Advisory BD"
  , Case When p2.id_number Is Not NULL Then 1 Else 0 End
    As "Past or Current Parent"
  , Case When be.primary_record_type_desc = 'Alumnus/Alumna' Then 1 Else 0 End
    As "Alumnus"
  , Case When be.primary_record_type_desc = 'Alumnus/Alumna' And sp_record_type = 'Alumnus/Alumna' Then 1 Else 0 End
    As "Double-Alum"
  , Case When st.id_number Is Not NULL Then 1 Else 0 End
    As "3 Year Season-Ticket Holder"
  , Case When chi_t1_home.id_number Is Not NULL Then 1 Else 0 End
    As chicago_home
  , p.prospect_manager_name As "Prospect Manager"
  , af.affinity_score As "Affinity Score"
  , gl.campaign_newgift_cmit_credit
  , gl.active_pledge_balance
  , be.pref_name_sort
  , pias.multi_or_single_interest
  , pias.potential_interest_areas
From bi_prospects p
Left Join prospect_entity pe
  On pe.prospect_id = p.prospect_id
  And pe.primary_ind = 'Y'
Left Join bi_entity be
  On be.id_number = pe.id_number
Left Join active_proposals ap
  On ap.prospect_id = p.prospect_id
Left Join chi_t1_home -- added 2/22/2018
  On chi_t1_home.id_number = be.id_number
Left Join annual_25k -- added 2/22/2018
  On annual_25k.entity_key=be.id_number
Left Join distinct_years dy
  On dy.id_number = be.id_number
Left Join contact_summary
  On be.id_number = contact_summary.id_number
Left Join committees
  On committees.id_number = be.id_number
Left Join parents p2
  On p2.id_number = be.id_number
Left Join seasontickets st
  On st.id_number = be.id_number
Left Join bi_gift_transactions_single
  On bi_gift_transactions_single.id_number = be.id_number
Left Join distinct_years_last_3 dy3
  On dy3.id_number = be.id_number
Left Join addresses a
  On a.id_number = be.id_number
Left Join all_NU_Degrees
  On all_NU_Degrees.id_number = be.id_number
Left Join all_NU_Degrees nu_deg_spouse
  On nu_deg_spouse.id_number = be.spouse_id_number
Left Join affinity_score_value af
  On af.id_number = be.id_number 
Left Join giving_lifetime gl
  On gl.id_number = be.id_number
Left Join advance_nu_rpt.prospect_interest_area_summary pias -- added 3/16/2018
  On pias.prospect_id=p.prospect_id
Left Join contacts c -- last contact by prospect manager
  On c.id_number = be.id_number
  And c.rownumber = 1
  And c.author_id_number = p.prospect_manager_id_number
Left Join contacts c_v_prmgr -- last visit by prospect manager
  On c_v_prmgr.id_number = be.id_number
  And c_v_prmgr.rownumber2 = 1
  And c_v_prmgr.contact_type = 'V'
  And c_v_prmgr.author_id_number = p.prospect_manager_id_number
Where (
    ( -- updated 2/22/2018 to include $1M +
      p.qualification_desc In ('A1 $100M+', 'A2 $50M - 99.9M', 'A3 $25M - $49.9M', 'A4 $10M - $24.9M'
        , 'A5 $5M - $9.9M', 'A6 $2M - $4.9M', 'A7 $1M - $1.9M')
      And p.active_ind = 'Y'
    ) Or (
      p.prospect_id > 0 
      And p.prospect_id In (Select prospect_id From active_proposals1m)
    )
  )
  And p.prospect_name Not Like  '%Anonymous%'
