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

-- Collection corresponding to above cursor
Type t_results Is Table Of t_donor%rowtype;
  results t_results;

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
      Bulk Collect Into results;
  Close t_donor;
    
  -- Debug -- test that the cursors worked --
  If debug Then
    dbms_output.put_line('==== Cursor Results ====');
    -- Loop through the lists
    For i In 1..(results.count) Loop
      -- Concatenate output
      dbms_output.put_line(results(i).id_number || '; ' || results(i).ksm_degrees || '; ' || results(i).person_or_org || '; ' ||
        results(i).associated_code || '; ' || results(i).credit_amount);
    End Loop;
  End If;

  -- Check if the primary donor has a KSM degree
  For i In 1..(results.count) Loop
    If results(i).associated_code = 'P' Then
      -- Store the record type of the primary donor
      donor_type := results(i).person_or_org;
      -- If the primary donor is a KSM alum we're done
      If results(i).ksm_degrees Is Not Null Then
        Return(results(i).id_number);
      -- Otherwise jump to next check
      Else Exit;
      End If;
    End If;
  End Loop;
  
  -- Check if any non-primary donors have a KSM degree; grab first that has a non-null l_degrees
  -- IMPORTANT: this means the cursor t_donor needs to be sorted in preferred order!
  For i In 1..(results.count) Loop
    -- If we find a KSM alum we're done
    If results(i).ksm_degrees Is Not Null Then
      Return(results(i).id_number);
    End If;
  End Loop;
  
  -- Check if the primary donor is an organization; if so, grab first person who's associated
  -- IMPORTANT: this means the cursor t_donor needs to be sorted in preferred order!
  -- If primary record type is not person, continue
  If donor_type != 'P' Then  
    For i In 1..(results.count) Loop
      If results(i).person_or_org = 'P' Then
        return(results(i).id_number);
      End If;
    End Loop;  
  End If;
  
  -- Fallback is to use the existing primary donor ID
  For i In 1..(results.count) Loop
    -- If we find a KSM alum we're done
    If results(i).associated_code = 'P' Then
      Return(results(i).id_number);
    End If;
  End Loop;

-- If we got all the way to the end, return null
Return(NULL);

End ksm_source_donor;
/
