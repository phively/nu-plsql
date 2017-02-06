Create Or Replace Function ksm_source_donor(receipt In varchar2)
Return varchar2 Is

/*
Created by pbh634
Takes an receipt number and returns the ID number of the entity who should receive
primary Kellogg gift credit.

Relies on nu_gft_trp_gifttrans, which combines gifts and matching gifts into a single table.
Kellogg alumni status is defined as 
*/

-- Declarations
id_final varchar2(10); -- id_number of entity to receive credit
gift_type char(1); -- GPYM indicator
id_tmp varchar2(10); -- temporary holder for id_number or receipt

-- Cursor to store potential donors
Cursor t_donor Is
  NULL;

Begin

  -- Check if the receipt is a matching gift
  Select gift.tx_gypm_ind
  Into gift_type
  From nu_gft_trp_gifttrans gift
  Where gift.tx_number = receipt;

  -- For matching gifts, recursively run this but replace the matching gift receipt with matched receipt
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
  

Return(id_final);

End ksm_source_donor;
/
