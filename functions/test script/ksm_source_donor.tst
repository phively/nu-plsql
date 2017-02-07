PL/SQL Developer Test script 3.0
20
-- Created on 2/7/2017 by PBH634 
Declare 
  -- Local variables here
  id varchar2(10);
  Type t_receipts Is Table Of varchar2(10);
  receipts t_receipts;
  
Begin
  
  -- Test receipts
  receipts := t_receipts('0002370746', '0002371580', '0002370765', '0002370763', '0002373286', '0002371650', '0002373070', '0002372038', '0002373551');
  
  -- Test loop
  For i In 1..receipts.count Loop
    id := advance.ksm_source_donor(receipt => receipts(i), debug => TRUE);  
    dbms_output.put_line('*KSM primary is: ' || id);
    dbms_output.put_line('');
  End Loop;

End;
0
0
