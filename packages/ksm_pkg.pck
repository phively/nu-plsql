Create Or Replace Package ksm_pkg Is

/***
Author  : PBH634
Created : 2/8/2017 5:43:38 PM
Purpose : Kellogg-specific package with lots of fun functins
***/

-- Public type declarations
-- Type <TypeName> Is <Datatype>;
  
-- Public constant declarations
  fy_start_month Constant number := 9; -- fiscal start month, 9 = September

-- Public variable declarations
-- <VariableName> <Datatype>;

-- Public function and procedure declarations
-- Function <FunctionName>(<Parameter> <Datatype>)
--  Return <Datatype>;

Function math_mod( -- mathematical modulo operator, m % n
  m In number,
  n In number)
  Return number;
  
Function fytd_indicator( -- fiscal year to date indicator
  dt In date,
  day_offset In number Default -1) -- default offset in days; -1 means up to yesterday, 0 up to today, etc.
  Return character; -- Y or N

end ksm_pkg;
/
Create Or Replace Package Body ksm_pkg Is

-- Private type declarations
-- type <TypeName> is <Datatype>;
  
-- Private constant declarations
-- <ConstantName> constant <Datatype> := <Value>;

-- Private variable declarations
-- <VariableName> <Datatype>;

/* Calculates the modulo function; needed to correct Oracle mod() weirdness
   2017-02-08 */
Function math_mod(m In number, n In number)
  Return number Is
  -- Declarations
  remainder number;

  Begin
    remainder := mod(m - n * floor(m/n), n);
    Return(remainder);
  End;

/* Fiscal year to date indicator: Takes as an argument any date object and returns Y/N
   2017-02-08 */
Function fytd_indicator(dt In date, day_offset In number)
  Return character Is
  -- Declarations
  output character;
  today_fisc_day number;
  today_fisc_mo number;
  dt_fisc_day number;
  dt_fisc_mo number;

  Begin
    -- extract dt fiscal month and day
    today_fisc_day := extract(day from sysdate);
    today_fisc_mo  := math_mod(m => extract(month from sysdate) - fy_start_month, n => 12) + 1;
    dt_fisc_day    := extract(day from dt);
    dt_fisc_mo     := math_mod(m => extract(month from dt) - fy_start_month, n => 12) + 1;
    -- logic to construct output
    If dt_fisc_mo < today_fisc_mo Then
      -- if dt_fisc_mo is earlier than today_fisc_mo no need to continue checking
      output := 'Y';
    ElsIf dt_fisc_mo > today_fisc_mo Then
      output := 'N';
    ElsIf dt_fisc_mo = today_fisc_mo Then
      If dt_fisc_day <= today_fisc_day + day_offset Then
        output := 'Y';
      Else
        output := 'N';
      End If;
    Else
      -- fallback condition
      output := '#ERR';
    End If;
    
    Return(output);
  End;

End ksm_pkg;
/
