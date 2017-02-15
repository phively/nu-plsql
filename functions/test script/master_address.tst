PL/SQL Developer Test script 3.0
19
-- Created on 2/15/2017 by PBH634 
Declare 
  -- Local variables here
  r varchar2(512);
  Type t Is Table Of varchar2(10);
  n t;

Begin
  -- Test statements here
  n := t('0000002354', '0000018027', '0000093027', '0000607626');
  
  For i in 1..n.count Loop
  dbms_output.put_line('=== ID #' || n(i) || ' ===');
  r := ksm_pkg.get_entity_address(n(i), field => 'state_code', debug => TRUE);
  dbms_output.put_line(r);
  dbms_output.new_line;
  End Loop;
  
End;
0
0
