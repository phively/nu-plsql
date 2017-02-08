Create Or Replace Function advance.ksm_source_donor(receipt In varchar2, debug In boolean Default FALSE)
Return varchar2 Is

/*
Created by pbh634
Takes an receipt number and returns the ID number of the entity who should receive
primary Kellogg gift credit.

Relies on nu_gft_trp_gifttrans, which combines gifts and matching gifts into a single table.
Kellogg alumni status is defined as advance.ksm_degrees_concat(id_number) returning a non-null result.
*/

-- Declarations
id_final varchar2(10); -- id_number of entity to receive credit
gift_type char(1); -- GPYM indicator
donor_type char(1); -- record type of primary associated donor
id_tmp varchar2(10); -- temporary holder for id_number or receipt

-- Cursor to store potential donors
-- Needs to be sorted in preferred order, so that KSM alumni with earlier degree years appear higher
-- on the list and nonalumni are sorted by lower id_number (as a proxy for age of record)
Cursor t_donor Is
  Select
    -- varchar2 fields
    id_number, advance.ksm_degrees_concat(id_number) As ksm_degrees,
    -- char(1) fields
    person_or_org, associated_code,
    -- numeric fields
    credit_amount
  From nu_gft_trp_gifttrans
  Where tx_number = receipt
    -- Exclude In Honor Of and In Memory Of from consideration
    And associated_code Not In ('H', 'M')
  -- People with earlier degree years take precedence over those with later ones
  -- People with smaller ID numbers take precedence over those with larger oens
  Order By advance.ksm_degrees_concat(id_number) Asc, id_number Asc;

-- Collections corresponding to above cursor
-- varchar2(10) fields
Type t_ids Is Table Of varchar2(10);
  l_id_number t_ids;
-- varchar2 fields
Type t_degrees Is Table Of varchar2(1024);
  l_degrees t_degrees;
-- char(1) fields
Type t_char Is Table Of nu_gft_trp_gifttrans.person_or_org%type;
  l_person_org t_char;
  l_assoc_code t_char;
-- numeric fields
Type t_dollars Is Table Of nu_gft_trp_gifttrans.credit_amount%type;
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
      Bulk Collect Into l_id_number, l_degrees, l_person_org, l_assoc_code, l_credit_amount;
  Close t_donor;

  -- Debug -- test that the cursors worked --
  If debug Then
    dbms_output.put_line('==== Cursor Results ====');
    -- Loop through the lists
    For i In 1..(l_id_number.count) Loop
      -- Concatenate output
      dbms_output.put_line(l_id_number(i) || '; ' || l_degrees(i) || '; ' || l_person_org(i) || '; ' ||
        l_assoc_code(i) || '; ' || l_credit_amount(i));
    End Loop;
  End If;

  -- Check if the primary donor has a KSM degree
  For i In 1..(l_id_number.count) Loop
    If l_assoc_code(i) = 'P' Then
      -- Store the record type of the primary donor
      donor_type := l_person_org(i);
      -- If the primary donor is a KSM alum we're done
      If l_degrees(i) Is Not Null Then
        Return(l_id_number(i));
      -- Otherwise jump to next check
      Else Exit;
      End If;
    End If;
  End Loop;
  
  -- Check if any non-primary donors have a KSM degree; grab first that has a non-null l_degrees
  -- IMPORTANT: this means the cursor t_donor needs to be sorted in preferred order!
  For i In 1..(l_id_number.count) Loop
    -- If we find a KSM alum we're done
    If l_degrees(i) Is Not Null Then
      Return(l_id_number(i));
    End If;
  End Loop;
  
  -- Check if the primary donor is an organization; if so, grab first person who's associated
  -- IMPORTANT: this means the cursor t_donor needs to be sorted in preferred order!
  -- If primary record type is not person, continue
  If donor_type != 'P' Then  
    For i In 1..(l_id_number.count) Loop
      If l_person_org(i) = 'P' Then
        return(l_id_number(i));
      End If;
    End Loop;  
  End If;
  
  -- Fallback is to use the existing primary donor ID
  For i In 1..(l_id_number.count) Loop
    -- If we find a KSM alum we're done
    If l_assoc_code(i) = 'P' Then
      Return(l_id_number(i));
    End If;
  End Loop;

-- If we got all the way to the end, return null
Return(NULL);

End ksm_source_donor;
/
