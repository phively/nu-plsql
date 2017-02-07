Create Or Replace Function advance.ksm_source_donor(receipt In varchar2)
Return varchar2 Is

/*
Created by pbh634
Takes an receipt number and returns the ID number of the entity who should receive
primary Kellogg gift credit.

Relies on nu_gft_trp_gifttrans, which combines gifts and matching gifts into a single table.
Kellogg alumni status is defined as [...]
*/

-- Debugging flag
debug boolean := TRUE;

-- Declarations
id_final varchar2(10); -- id_number of entity to receive credit
gift_type char(1); -- GPYM indicator
id_tmp varchar2(10); -- temporary holder for id_number or receipt

-- Cursor to store potential donors
Cursor t_donor Is
  Select
    -- varchar2 fields
    id_number, advance.ksm_degrees_concat(id_number) As ksm_degrees,
    -- char(1) fields
    person_or_org,
    -- numeric fields
    legal_amount, credit_amount
  From nu_gft_trp_gifttrans
  Where tx_number = receipt;

-- Collections corresponding to above cursor
-- varchar2(10) fields
Type t_ids Is Table Of varchar2(10);
  l_id_number t_ids;
-- varchar2 fields
Type t_degrees Is Table Of varchar2(1024);
  l_degrees t_degrees;
-- char(1) fields
Type t_person_org Is Table Of nu_gft_trp_gifttrans.person_or_org%type;
  l_person_org t_person_org;
-- numeric fields
Type t_dollars Is Table Of nu_gft_trp_gifttrans.legal_amount%type;
  l_legal_amount t_dollars;
  l_credit_amount t_dollars;

Begin

  -- Check if the receipt is a matching gift
  Select Distinct gift.tx_gypm_ind
  Into gift_type
  From nu_gft_trp_gifttrans gift
  Where gift.tx_number = receipt;

-- For matching gifts, recursively run this function but replace the matching gift receipt with matched receipt
  If gift_type = 'M' Then
    -- Pull the matched receipt into id_tmp
    Select gift.matched_receipt_nbr
    Into id_tmp
    From nu_gft_trp_gifttrans gift
    Where gift.tx_number = receipt;
    -- Run id_tmp through this function
    id_final := ksm_source_donor(receipt => id_tmp);
    -- Return found ID and break out of function
    Return(id_final);
  End If;

-- For any other type of gift, proceed through the hierarchy of potential source donors

  -- Retrieve t_donor cursor results
  Open t_donor;
    Fetch t_donor
      Bulk Collect Into l_id_number, l_degrees, l_person_org, l_legal_amount, l_credit_amount;
  Close t_donor;

/* Debug -- test that the cursors worked */
  If debug Then
    dbms_output.put_line('==== Cursor Results ====');
    -- Loop through the lists
    For i In 1..(l_id_number.count) Loop
      -- Concatenate output
      dbms_output.put_line(l_id_number(i) || '; ' || l_degrees(i) || '; ' || l_person_org(i) || '; ' ||
        l_legal_amount(i) || '; ' || l_credit_amount(i));
    End Loop;
  End If;

  -- etc.

Return(id_final);

End ksm_source_donor;
/
