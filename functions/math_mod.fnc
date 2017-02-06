Create Or Replace Function advance.math_mod(m In number, n In number)
Return number Is

/*
Created by pbh634
Math mod
Calculates the modulo function; needed to correct Oracle mod() weirdness
*/

-- Declarations
remainder number;

Begin

  remainder := mod(m - n * floor(m/n), n);

Return(remainder);

End math_mod;
/
