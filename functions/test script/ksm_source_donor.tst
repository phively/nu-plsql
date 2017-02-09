PL/SQL Developer Test script 3.0
21
-- Created on 2/7/2017 by PBH634 
Declare 
  -- Local variables here
  id varchar2(10);
  Type t_receipts Is Table Of varchar2(10);
  receipts t_receipts;
  
Begin
  
  -- Test receipts
  receipts := t_receipts('0002370746', '0002371580', '0002370765', '0002370763', '0002373286', '0002371650', '0002373070', '0002372038', '0002373551',
                         '0002374381', '0002400638', '0002422364');
  
  -- Test loop
  For i In 1..receipts.count Loop
    id := ksm_pkg.get_gift_source_donor_ksm(receipt => receipts(i), debug => TRUE);  
    dbms_output.put_line('*KSM primary is: ' || id);
    dbms_output.new_line;
  End Loop;

End;
0
0
