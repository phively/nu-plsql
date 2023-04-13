Create Or Replace Package ksm_pkg_gifts Is

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_gifts';

/*************************************************************************
Public type declarations
*************************************************************************/

-- Discounted pledge amounts
Type plg_disc Is Record (
  pledge_number pledge.pledge_pledge_number%type
  , pledge_sequence pledge.pledge_sequence%type
  , prim_pledge_type primary_pledge.prim_pledge_type%type
  , prim_pledge_status primary_pledge.prim_pledge_status%type
  , status_change_date primary_pledge.status_change_date%type
  , proposal_id primary_pledge.proposal_id%type
  , pledge_comment primary_pledge.prim_pledge_comment%type
  , pledge_amount pledge.pledge_amount%type
  , pledge_associated_credit_amt pledge.pledge_associated_credit_amt%type
  , prim_pledge_amount primary_pledge.prim_pledge_amount%type
  , prim_pledge_amount_paid primary_pledge.prim_pledge_amount_paid%type
  , prim_pledge_remaining_balance primary_pledge.prim_pledge_amount%type
  , prim_pledge_original_amount primary_pledge.prim_pledge_original_amount%type
  , discounted_amt primary_pledge.prim_pledge_amount%type
  , legal primary_pledge.prim_pledge_amount%type
  , credit primary_pledge.prim_pledge_amount%type
  , recognition_credit pledge.pledge_amount%type
);

-- Entity transaction for credit
Type trans_entity Is Record (
  id_number entity.id_number%type
  , report_name entity.report_name%type
  , anonymous gift.gift_associated_anonymous%type
  , tx_number gift.gift_receipt_number%type
  , tx_sequence gift.gift_sequence%type
  , transaction_type_code varchar2(10)
  , transaction_type varchar2(40)
  , tx_gypm_ind varchar2(1)
  , associated_code tms_association.associated_code%type
  , associated_desc tms_association.short_desc%type
  , pledge_number pledge.pledge_pledge_number%type
  , pledge_fiscal_year pledge.pledge_year_of_giving%type
  , matched_tx_number matching_gift.match_gift_matched_receipt%type
  , matched_fiscal_year number
  , payment_type tms_payment_type.short_desc%type
  , allocation_code allocation.allocation_code%type
  , alloc_short_name allocation.short_name%type
  , ksm_flag varchar2(1)
  , af_flag varchar2(1)
  , cru_flag varchar2(1)
  , gift_comment primary_gift.prim_gift_comment%type
  , proposal_id primary_pledge.proposal_id%type
  , pledge_status primary_pledge.prim_pledge_status%type
  , date_of_record gift.gift_date_of_record%type
  , fiscal_year number
  , legal_amount gift.gift_associated_amount%type
  , credit_amount gift.gift_associated_amount%type
  , recognition_credit gift.gift_associated_amount%type
  , stewardship_credit_amount gift.gift_associated_amount%type
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type t_plg_disc Is Table Of plg_disc;
Type t_trans_entity Is Table Of trans_entity;

/*************************************************************************
Public function declarations
*************************************************************************/

-- Take receipt number and return id_number of entity to receive primary Kellogg gift credit
Function get_gift_source_donor_ksm(
  receipt In varchar2
  , debug In boolean Default FALSE -- if TRUE, debug output is printed via dbms_output.put_line()
) Return varchar2; -- entity id_number

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

-- Returns pipelined table of Kellogg transactions
Function plg_discount
  Return t_plg_disc Pipelined;

Function tbl_gift_credit
  Return t_trans_entity Pipelined;

Function tbl_gift_credit_ksm
  Return t_trans_entity Pipelined;

/*************************************************************************
Public cursors -- data definitions
*************************************************************************/



End ksm_pkg_gifts;
/
Create Or Replace Package Body ksm_pkg_gifts Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

-- Definition of Kellogg gift source donor
Cursor c_source_donor_ksm (receipt In varchar2) Is
  Select
    gft.tx_number
    , gft.id_number
    , get_entity_degrees_concat_fast(id_number) As ksm_degrees
    , gft.person_or_org
    , gft.associated_code
    , gft.credit_amount
  From nu_gft_trp_gifttrans gft
  Where gft.tx_number = receipt
    And associated_code Not In ('H', 'M') -- Exclude In Honor Of and In Memory Of from consideration
  Order By
    -- People with earlier KSM degree years take precedence over those with later ones
    get_entity_degrees_concat_fast(id_number) Asc
    -- People with smaller ID numbers take precedence over those with larger ones
    , id_number Asc
  ;

-- Definition of discounted pledge amounts
Cursor c_plg_discount Is
  Select
    pledge.pledge_pledge_number As pledge_number
    , pledge.pledge_sequence
    , pplg.prim_pledge_type
    , pplg.prim_pledge_status
    , trim(pplg.status_change_date)
      As status_change_date
    , pplg.proposal_id
    , pplg.prim_pledge_comment
    , pledge.pledge_amount
    , pledge.pledge_associated_credit_amt
    , pplg.prim_pledge_amount
    , pplg.prim_pledge_amount_paid
    , Case
        When pplg.prim_pledge_status = 'A'
          Then pplg.prim_pledge_amount - pplg.prim_pledge_amount_paid
        Else 0
        End
      As prim_pledge_remaining_balance
    , pplg.prim_pledge_original_amount
    , pplg.discounted_amt
    -- Discounted pledge legal amounts
    , Case
        -- Not inactive, not a BE or LE
        When (pplg.prim_pledge_status Is Null Or pplg.prim_pledge_status = 'A')
          And pplg.prim_pledge_type Not In ('BE', 'LE') Then pledge.pledge_amount
        -- Not inactive, is BE or LE; make sure to allocate proportionally to program code allocation
        When (pplg.prim_pledge_status Is Null Or pplg.prim_pledge_status = 'A')
          And pplg.prim_pledge_type In ('BE', 'LE') Then pplg.discounted_amt * pledge.pledge_amount /
            (Case When pplg.prim_pledge_amount = 0 Then 1 Else pplg.prim_pledge_amount End)
        -- If inactive, take amount paid
        Else Case
          When pplg.prim_pledge_amount > 0
            Then pplg.prim_pledge_amount_paid * pledge.pledge_amount / pplg.prim_pledge_amount
          When pledge.pledge_amount > 0
            Then pplg.prim_pledge_amount_paid
          Else 0
        End
      End As legal
    -- Discounted pledge credit amounts
    , Case
        -- Not inactive, not a BE or LE
        When (pplg.prim_pledge_status Is Null Or pplg.prim_pledge_status = 'A')
          And pplg.prim_pledge_type Not In ('BE', 'LE') Then pledge.pledge_associated_credit_amt
        -- Not inactive, is BE or LE; make sure to allocate proportionally to program code allocation
        When (pplg.prim_pledge_status Is Null Or pplg.prim_pledge_status = 'A')
          And pplg.prim_pledge_type In ('BE', 'LE') Then pplg.discounted_amt * pledge.pledge_associated_credit_amt /
            (Case When pplg.prim_pledge_amount = 0 Then 1 Else pplg.prim_pledge_amount End)
        -- If inactive, take amount paid
        Else Case
          When pledge.pledge_amount = 0 And pplg.prim_pledge_amount > 0
            Then pplg.prim_pledge_amount_paid * pledge.pledge_associated_credit_amt / pplg.prim_pledge_amount
          When pplg.prim_pledge_amount > 0
            Then pplg.prim_pledge_amount_paid * pledge.pledge_amount / pplg.prim_pledge_amount
          Else pplg.prim_pledge_amount_paid
        End
      End As credit
    -- Discounted pledge credit with face value on bequests
    , Case
      -- All active pledges
        When (pplg.prim_pledge_status Is Null Or pplg.prim_pledge_status = 'A') Then pledge.pledge_associated_credit_amt
        -- If not active, take amount paid
        Else Case
          When pledge.pledge_amount = 0 And pplg.prim_pledge_amount > 0
            Then pplg.prim_pledge_amount_paid * pledge.pledge_associated_credit_amt / pplg.prim_pledge_amount
          When pplg.prim_pledge_amount > 0
            Then pplg.prim_pledge_amount_paid * pledge.pledge_amount / pplg.prim_pledge_amount
          Else pplg.prim_pledge_amount_paid
        End
      End As recognition_credit
  From primary_pledge pplg
  Inner Join pledge On pledge.pledge_pledge_number = pplg.prim_pledge_number
  Where pledge.pledge_program_code = 'KM'
    Or pledge_alloc_school = 'KM'
  ;

-- Rework of match + matched + gift + payment + pledge union definition
-- Intended to replace nu_gft_trp_gifttrans with KSM-specific fields 
-- Shares significant code with c_gift_credit_ksm below
Cursor c_gift_credit Is
  With
  plg_discount As (
    Select *
    From table(plg_discount)
  )
  , ksm_allocs As (
    Select
      allocation.allocation_code
      , allocation.short_name
      , Case When alloc_school = 'KM' Then 'Y' End As ksm_flag
      , Case When ksm_cru_allocs.af_flag Is Not Null Then 'Y' End As cru_flag
      , Case When ksm_cru_allocs.af_flag = 'Y' Then 'Y' End As af_flag
    From allocation
    Left Join table(tbl_alloc_curr_use_ksm) ksm_cru_allocs
      On ksm_cru_allocs.allocation_code = allocation.allocation_code
  )
  , tms_trans As (
    (
      Select
        transaction_type_code
        , short_desc As transaction_type
      From tms_transaction_type
    ) Union All (
      Select
        pledge_type_code
        , short_desc
      From tms_pledge_type
    )
  )
    , tms_pmt_type As (
    Select
      payment_type_code
      , short_desc As payment_type
    From tms_payment_type
  )
  , tms_assoc As (
    Select
      associated_code
      , short_desc As associated_desc
    From tms_association
  )
  (
      -- Matching gift matching company
    Select
      match_gift_company_id
      , entity.report_name
      , gftanon.anon
      , match_gift_receipt_number
      , match_gift_matched_sequence
      , NULL As transaction_type_code
      , 'Matching Gift' As transaction_type
      , 'M' As tx_gypm_ind
      , 'MG' As associated_code
      , 'Matching Gift' As associated_desc
      , NULL As pledge_number
      , NULL As pledge_fiscal_year
      , match_gift_matched_receipt As matched_tx_number
      , to_number(gift.gift_year_of_giving) As matched_fiscal_year
      , tms_pmt_type.payment_type
      , match_gift_allocation_name
      , ksm_allocs.short_name
      , ksm_flag
      , af_flag
      , cru_flag
      , matching_gift.match_gift_comment
      , NULL As proposal_id
      , NULL As pledge_status
      , match_gift_date_of_record
      , get_fiscal_year(match_gift_date_of_record)
      -- Full legal amount to matching company
      , match_gift_amount
      , match_gift_amount
      , match_gift_amount
      , match_gift_amount As stewardship_credit_amount
    From matching_gift
    Inner Join entity On entity.id_number = matching_gift.match_gift_company_id
    -- Matched gift data
    Left Join gift On gift.gift_receipt_number = match_gift_matched_receipt
    -- Only KSM allocations
    Inner Join ksm_allocs On ksm_allocs.allocation_code = matching_gift.match_gift_allocation_name
    -- Anonymous association on the matched gift
    Inner Join (
        Select
          gift_receipt_number
          , gift_sequence
          , gift_associated_anonymous As anon
        From gift
      ) gftanon On gftanon.gift_receipt_number = matching_gift.match_gift_matched_receipt
          And gftanon.gift_sequence = matching_gift.match_gift_matched_sequence
    -- Trans payment descriptions
    Left Join tms_pmt_type On tms_pmt_type.payment_type_code = matching_gift.match_payment_type
  ) Union ( -- NOT Union All as we need to dedupe so the company does not get double credit
  -- Matching gift matched donors
    Select
      gft.id_number
      , entity.report_name
      , gftanon.anon
      , match_gift_receipt_number
      , match_gift_matched_sequence
      , NULL As transaction_type_code
      , 'Matching Gift' As transaction_type
      , 'M' As tx_gypm_ind
      , 'MG' As associated_code
      , 'Matching Gift' As associated_desc
      , NULL As pledge_number
      , NULL As pledge_fiscal_year
      , match_gift_matched_receipt As matched_tx_number
      , to_number(gift.gift_year_of_giving) As matched_fiscal_year
      , tms_pmt_type.payment_type
      , match_gift_allocation_name
      , ksm_allocs.short_name
      , ksm_flag
      , af_flag
      , cru_flag
      , matching_gift.match_gift_comment
      , NULL As proposal_id
      , NULL As pledge_status
      , match_gift_date_of_record
      , get_fiscal_year(match_gift_date_of_record)
      -- 0 legal amount to matched donors
      , Case When gft.id_number = match_gift_company_id Then match_gift_amount Else 0 End As legal_amount
      , match_gift_amount
      , match_gift_amount
      , match_gift_amount As stewardship_credit_amount
    From matching_gift
    -- Matched gift data
    Left Join gift On gift.gift_receipt_number = match_gift_matched_receipt
    -- Inner join to add all attributed donor IDs on the original gift
    Inner Join (
        Select
          gift_donor_id As id_number
          , gift.gift_receipt_number
        From gift
      ) gft On matching_gift.match_gift_matched_receipt = gft.gift_receipt_number
    Inner Join entity On entity.id_number = gft.id_number
    -- Only KSM allocations
    Inner Join ksm_allocs On ksm_allocs.allocation_code = matching_gift.match_gift_allocation_name
    -- Anonymous association on the matched gift
    Inner Join (
        Select
          gift_donor_id
          , gift_receipt_number
          , gift_sequence
          , gift_associated_anonymous As anon
        From gift
      ) gftanon On gftanon.gift_receipt_number = matching_gift.match_gift_matched_receipt
          And gftanon.gift_sequence = matching_gift.match_gift_matched_sequence
    -- Trans payment descriptions
    Left Join tms_pmt_type On tms_pmt_type.payment_type_code = matching_gift.match_payment_type
  ) Union All (
  -- Outright gifts and payments
    Select
      gift.gift_donor_id As id_number
      , entity.report_name
      , gift.gift_associated_anonymous As anon
      , gift.gift_receipt_number As tx_number
      , gift.gift_sequence As tx_sequence
      , gift.gift_transaction_type As transaction_type_code
      , tms_trans.transaction_type
      , Case
          When gift.pledge_payment_ind = 'Y'
            Then 'Y' -- Y = pledge payment
          Else 'G' -- G = outright gift
          End
        As tx_gypm_ind
      , gift.gift_associated_code
      , tms_assoc.associated_desc
      , trim(primary_gift.prim_gift_pledge_number) As pledge_number
      , primary_pledge.prim_pledge_year_of_giving As pledge_fiscal_year
      , NULL As matched_tx_number
      , NULL As matched_fiscal_year
      , tms_pmt_type.payment_type
      , gift.gift_associated_allocation As allocation_code
      , allocation.short_name As alloc_short_name
      , ksm_flag
      , af_flag
      , cru_flag
      , primary_gift.prim_gift_comment As gift_comment
      , Case When primary_gift.proposal_id <> 0 Then primary_gift.proposal_id End As proposal_id
      , NULL As pledge_status
      , gift.gift_date_of_record As date_of_record
      , get_fiscal_year(gift.gift_date_of_record) As fiscal_year
      , gift.gift_associated_amount As legal_amount
      , gift.gift_associated_credit_amt As credit_amount
      -- Recognition credit; for $0 internal transfers, extract dollar amount stated in comment
      , Case
          When tms_pmt_type.payment_type = 'Internal Transfer'
            And gift.gift_associated_credit_amt = 0
            Then get_number_from_dollar(primary_gift.prim_gift_comment)
          Else gift.gift_associated_credit_amt
        End As recognition_credit
      -- Stewardship credit, where pledge payments are counted at face value provided the pledge
      -- was made in an earlier fiscal year
      , Case
          -- Internal transfers logic
          When tms_pmt_type.payment_type = 'Internal Transfer'
            And gift.gift_associated_credit_amt = 0
            Then get_number_from_dollar(primary_gift.prim_gift_comment)
          -- When no associated pledge use credit amount
          When primary_pledge.prim_pledge_number Is Null
            Then gift.gift_associated_credit_amt
          -- When a pledge transaction type, check the year
          Else Case
            -- Zero out when pledge fiscal year and payment fiscal year are the same
            When primary_pledge.prim_pledge_year_of_giving = get_fiscal_year(gift.gift_date_of_record)
              Then 0
            Else gift.gift_associated_credit_amt
            End
        End As stewardship_credit_amount
    From gift
    Inner Join entity On entity.id_number = gift.gift_donor_id
    -- Allocation
    Inner Join allocation On allocation.allocation_code = gift.gift_associated_allocation
    -- Anonymous association and linked proposal
    Inner Join primary_gift On primary_gift.prim_gift_receipt_number = gift.gift_receipt_number
    -- Primary pledge fiscal year
    Left Join primary_pledge On primary_pledge.prim_pledge_number = primary_gift.prim_gift_pledge_number
    -- Trans type descriptions
    Left Join tms_trans On tms_trans.transaction_type_code = gift.gift_transaction_type
    Left Join tms_pmt_type On tms_pmt_type.payment_type_code = gift.gift_payment_type
    Left Join tms_assoc On tms_assoc.associated_code = gift.gift_associated_code
    -- KSM Annual Fund indicator
    Left Join ksm_allocs On ksm_allocs.allocation_code = gift.gift_associated_allocation
  ) Union All (
  -- Pledges, including BE and LE program credit
    Select
      pledge_donor_id
      , entity.report_name
      , pledge_anonymous
      , pledge_pledge_number
      , pledge.pledge_sequence
      , pledge.pledge_pledge_type As transaction_type_code
      , tms_trans.transaction_type
      , 'P' As tx_gypm_ind
      , pledge.pledge_associated_code
      , tms_assoc.associated_desc
      , pledge.pledge_pledge_number As pledge_number
      , pledge.pledge_year_of_giving As pledge_fiscal_year
      , NULL As matched_tx_number
      , NULL As matched_fiscal_year
      , NULL As payment_type
      , pledge.pledge_allocation_name
      , Case
          When ksm_allocs.short_name Is Not Null Then ksm_allocs.short_name
          When ksm_allocs.short_name Is Null Then allocation.short_name
        End As short_name
      -- Include KSM allocations as well as the BE/LE account gifts where the gift is counted toward the KM program
      , Case
          When pledge_allocation_name In ('BE', 'LE') -- BE and LE discounted amounts
            And pledge_program_code = 'KM'
            Then 'Y'
          Else ksm_flag
          End
        As ksm_flag
      , ksm_allocs.af_flag
      , cru_flag
      , pledge_comment
      , Case When proposal_id <> 0 Then proposal_id End As proposal_id
      , prim_pledge_status
      , pledge_date_of_record
      , get_fiscal_year(pledge_date_of_record)
      , plgd.legal
      , plgd.credit
      , plgd.recognition_credit
      , plgd.recognition_credit As stewardship_credit_amount
    From pledge
    Inner Join entity On entity.id_number = pledge.pledge_donor_id
    -- Trans type descriptions
    Inner Join tms_trans On tms_trans.transaction_type_code = pledge.pledge_pledge_type
    Left Join tms_assoc On tms_assoc.associated_code = pledge.pledge_associated_code
    -- Allocation name backup
    Inner Join allocation On allocation.allocation_code = pledge.pledge_allocation_name
    -- Discounted pledge amounts where applicable
    Left Join plg_discount plgd On plgd.pledge_number = pledge.pledge_pledge_number
      And plgd.pledge_sequence = pledge.pledge_sequence
    -- KSM AF flag
    Left Join ksm_allocs On ksm_allocs.allocation_code = pledge.pledge_allocation_name
  )
  ;

-- Definition of KSM giving transactions for summable credit
-- Shares significant code with c_gift_credit above but uses inner joins for a ~3x speedup
Cursor c_gift_credit_ksm Is
  With
  /* Primary pledge discounted amounts */
  plg_discount As (
    Select *
    From table(plg_discount)
  )
  /* KSM allocations */
  , ksm_cru_allocs As (
    Select *
    From table(tbl_alloc_curr_use_ksm) cru
  )
  , ksm_allocs As (
    Select
      allocation.allocation_code
      , allocation.short_name
      , Case When ksm_cru_allocs.af_flag Is Not Null Then 'Y' End As cru_flag
      , Case When ksm_cru_allocs.af_flag = 'Y' Then 'Y' End As af_flag
    From allocation
    Left Join ksm_cru_allocs On ksm_cru_allocs.allocation_code = allocation.allocation_code
    Where alloc_school = 'KM'
  )
  /* Transaction and pledge TMS table definition */
  , tms_trans As (
    (
      Select
        transaction_type_code
        , short_desc As transaction_type
      From tms_transaction_type
    ) Union All (
      Select
        pledge_type_code
        , short_desc
      From tms_pledge_type
    )
  )
  /* Payment types */
  , tms_pmt_type As (
    Select
      payment_type_code
      , short_desc As payment_type
    From tms_payment_type
  )
  , tms_assoc As (
    Select
      associated_code
      , short_desc As associated_desc
    From tms_association
  )
  /* Kellogg transactions list */
  (
      -- Matching gift matching company
    Select
      match_gift_company_id
      , entity.report_name
      , gftanon.anon
      , match_gift_receipt_number
      , match_gift_matched_sequence
      , NULL As transaction_type_code
      , 'Matching Gift' As transaction_type
      , 'M' As tx_gypm_ind
      , 'MG' As associated_code
      , 'Matching Gift' As associated_desc
      , NULL As pledge_number
      , NULL As pledge_fiscal_year
      , match_gift_matched_receipt As matched_tx_number
      , to_number(gift.gift_year_of_giving) As matched_fiscal_year
      , tms_pmt_type.payment_type
      , match_gift_allocation_name
      , ksm_allocs.short_name
      , 'Y' As ksm_flag
      , af_flag
      , cru_flag
      , matching_gift.match_gift_comment
      , NULL As proposal_id
      , NULL As pledge_status
      , match_gift_date_of_record
      , get_fiscal_year(match_gift_date_of_record)
      -- Full legal amount to matching company
      , match_gift_amount
      , match_gift_amount
      , match_gift_amount
      , match_gift_amount As stewardship_credit_amount
    From matching_gift
    Inner Join entity On entity.id_number = matching_gift.match_gift_company_id
    -- Matched gift data
    Left Join gift On gift.gift_receipt_number = match_gift_matched_receipt
    -- Only KSM allocations
    Inner Join ksm_allocs On ksm_allocs.allocation_code = matching_gift.match_gift_allocation_name
    -- Anonymous association on the matched gift
    Inner Join (
        Select
          gift_receipt_number
          , gift_sequence
          , gift_associated_anonymous As anon
        From gift
      ) gftanon On gftanon.gift_receipt_number = matching_gift.match_gift_matched_receipt
          And gftanon.gift_sequence = matching_gift.match_gift_matched_sequence
    -- Trans payment descriptions
    Left Join tms_pmt_type On tms_pmt_type.payment_type_code = matching_gift.match_payment_type
  ) Union ( -- NOT Union All as we need to dedupe so the company does not get double credit
  -- Matching gift matched donors
    Select
      gft.id_number
      , entity.report_name
      , gftanon.anon
      , match_gift_receipt_number
      , match_gift_matched_sequence
      , NULL As transaction_type_code
      , 'Matching Gift' As transaction_type
      , 'M' As tx_gypm_ind
      , 'MG' As associated_code
      , 'Matching Gift' As associated_desc
      , NULL As pledge_number
      , NULL As pledge_fiscal_year
      , match_gift_matched_receipt As matched_tx_number
      , to_number(gift.gift_year_of_giving) As matched_fiscal_year
      , tms_pmt_type.payment_type
      , match_gift_allocation_name
      , ksm_allocs.short_name
      , 'Y' As ksm_flag
      , af_flag
      , cru_flag
      , matching_gift.match_gift_comment
      , NULL As proposal_id
      , NULL As pledge_status
      , match_gift_date_of_record
      , get_fiscal_year(match_gift_date_of_record)
      -- 0 legal amount to matched donors
      , Case When gft.id_number = match_gift_company_id Then match_gift_amount Else 0 End As legal_amount
      , match_gift_amount
      , match_gift_amount
      , match_gift_amount As stewardship_credit_amount
    From matching_gift
    -- Matched gift data
    Left Join gift On gift.gift_receipt_number = match_gift_matched_receipt
    -- Inner join to add all attributed donor IDs on the original gift
    Inner Join (
        Select
          gift_donor_id As id_number
          , gift.gift_receipt_number
        From gift
      ) gft On matching_gift.match_gift_matched_receipt = gft.gift_receipt_number
    Inner Join entity On entity.id_number = gft.id_number
    -- Only KSM allocations
    Inner Join ksm_allocs On ksm_allocs.allocation_code = matching_gift.match_gift_allocation_name
    -- Anonymous association on the matched gift
    Inner Join (
        Select
          gift_donor_id
          , gift_receipt_number
          , gift_sequence
          , gift_associated_anonymous As anon
        From gift
      ) gftanon On gftanon.gift_receipt_number = matching_gift.match_gift_matched_receipt
          And gftanon.gift_sequence = matching_gift.match_gift_matched_sequence
    -- Trans payment descriptions
    Left Join tms_pmt_type On tms_pmt_type.payment_type_code = matching_gift.match_payment_type
  ) Union All (
  -- Outright gifts and payments
    Select
      gift.gift_donor_id As id_number
      , entity.report_name
      , gift.gift_associated_anonymous As anon
      , gift.gift_receipt_number As tx_number
      , gift.gift_sequence As tx_sequence
      , gift.gift_transaction_type As transaction_type_code
      , tms_trans.transaction_type
      , Case
          When gift.pledge_payment_ind = 'Y'
            Then 'Y' -- Y = pledge payment
          Else 'G' -- G = outright gift
          End
        As tx_gypm_ind
      , tms_assoc.associated_code
      , tms_assoc.associated_desc
      , trim(primary_gift.prim_gift_pledge_number) As pledge_number
      , primary_pledge.prim_pledge_year_of_giving As pledge_fiscal_year
      , NULL As matched_tx_number
      , NULL As matched_fiscal_year
      , tms_pmt_type.payment_type
      , gift.gift_associated_allocation As allocation_code
      , allocation.short_name As alloc_short_name
      , 'Y' As ksm_flag
      , af_flag
      , cru_flag
      , primary_gift.prim_gift_comment As gift_comment
      , Case When primary_gift.proposal_id <> 0 Then primary_gift.proposal_id End As proposal_id
      , NULL As pledge_status
      , gift.gift_date_of_record As date_of_record
      , get_fiscal_year(gift.gift_date_of_record) As fiscal_year
      , gift.gift_associated_amount As legal_amount
      , gift.gift_associated_credit_amt As credit_amount
      -- Recognition credit; for $0 internal transfers, extract dollar amount stated in comment
      , Case
          When tms_pmt_type.payment_type = 'Internal Transfer'
            And gift.gift_associated_credit_amt = 0
            Then get_number_from_dollar(primary_gift.prim_gift_comment)
          Else gift.gift_associated_credit_amt
        End As recognition_credit
      -- Stewardship credit, where pledge payments are counted at face value provided the pledge
      -- was made in an earlier fiscal year
      , Case
          -- Internal transfers logic
          When tms_pmt_type.payment_type = 'Internal Transfer'
            And gift.gift_associated_credit_amt = 0
            Then get_number_from_dollar(primary_gift.prim_gift_comment)
          -- When no associated pledge use credit amount
          When primary_pledge.prim_pledge_number Is Null
            Then gift.gift_associated_credit_amt
          -- When a pledge transaction type, check the year
          Else Case
            -- Zero out when pledge fiscal year and payment fiscal year are the same
            When primary_pledge.prim_pledge_year_of_giving = get_fiscal_year(gift.gift_date_of_record)
              Then 0
            Else gift.gift_associated_credit_amt
            End
        End As stewardship_credit_amount
    From gift
    Inner Join entity On entity.id_number = gift.gift_donor_id
    -- Allocation
    Inner Join allocation On allocation.allocation_code = gift.gift_associated_allocation
    -- Anonymous association and linked proposal
    Inner Join primary_gift On primary_gift.prim_gift_receipt_number = gift.gift_receipt_number
    -- Primary pledge fiscal year
    Left Join primary_pledge On primary_pledge.prim_pledge_number = primary_gift.prim_gift_pledge_number
    -- Trans type descriptions
    Left Join tms_trans On tms_trans.transaction_type_code = gift.gift_transaction_type
    Left Join tms_pmt_type On tms_pmt_type.payment_type_code = gift.gift_payment_type
    Left Join tms_assoc On tms_assoc.associated_code = gift.gift_associated_code
    -- KSM Annual Fund indicator
    Left Join ksm_allocs On ksm_allocs.allocation_code = gift.gift_associated_allocation
    Where alloc_school = 'KM'
  ) Union All (
  -- Pledges, including BE and LE program credit
    Select
      pledge_donor_id
      , entity.report_name
      , pledge_anonymous
      , pledge_pledge_number
      , pledge.pledge_sequence
      , pledge.pledge_pledge_type As transaction_type_code
      , tms_trans.transaction_type
      , 'P' As tx_gypm_ind
      , tms_assoc.associated_code
      , tms_assoc.associated_desc
      , pledge.pledge_pledge_number As pledge_number
      , pledge.pledge_year_of_giving As pledge_fiscal_year
      , NULL As matched_tx_number
      , NULL As matched_fiscal_year
      , NULL As payment_type
      , pledge.pledge_allocation_name
      , Case
          When ksm_allocs.short_name Is Not Null Then ksm_allocs.short_name
          When ksm_allocs.short_name Is Null Then allocation.short_name
        End As short_name
      , 'Y' As ksm_flag
      , ksm_allocs.af_flag
      , cru_flag
      , pledge_comment
      , Case When proposal_id <> 0 Then proposal_id End As proposal_id
      , prim_pledge_status
      , pledge_date_of_record
      , get_fiscal_year(pledge_date_of_record)
      , plgd.legal
      , plgd.credit
      , plgd.recognition_credit
      , plgd.recognition_credit As stewardship_credit_amount
    From pledge
    Inner Join entity On entity.id_number = pledge.pledge_donor_id
    -- Trans type descriptions
    Inner Join tms_trans On tms_trans.transaction_type_code = pledge.pledge_pledge_type
    Inner Join tms_assoc On tms_assoc.associated_code = pledge.pledge_associated_code
    -- Allocation name backup
    Inner Join allocation On allocation.allocation_code = pledge.pledge_allocation_name
    -- Discounted pledge amounts where applicable
    Left Join plg_discount plgd On plgd.pledge_number = pledge.pledge_pledge_number
      And plgd.pledge_sequence = pledge.pledge_sequence
    -- KSM AF flag
    Left Join ksm_allocs On ksm_allocs.allocation_code = pledge.pledge_allocation_name
    -- Include KSM allocations as well as the BE/LE account gifts where the gift is counted toward the KM program
    Where ksm_allocs.allocation_code Is Not Null
      Or (
      -- KSM program code
        pledge_allocation_name In ('BE', 'LE') -- BE and LE discounted amounts
        And pledge_program_code = 'KM'
      )
  )
  ;

/*************************************************************************
Functions
*************************************************************************/



/*************************************************************************
Pipelined functions
*************************************************************************/



End ksm_pkg_gifts;
/
