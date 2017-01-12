CREATE OR REPLACE Function math_mod(m In number, n In number)
Return number Is
  remainder number;
Begin
  remainder := mod(m - n * floor(m/n), n);
  Return(remainder);
End math_mod;
/
