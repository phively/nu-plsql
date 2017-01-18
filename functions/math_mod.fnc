CREATE OR REPLACE Function ADVANCE.math_mod(m In number, n In number)
/*
Created by pbh634
Math mod
Calculates the modulo function; needed to correct Oracle mod() weirdness
*/
Return number Is
  remainder number;
Begin
  remainder := mod(m - n * floor(m/n), n);
  Return(remainder);
End math_mod;
/
