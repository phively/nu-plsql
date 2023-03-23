Create Or Replace Package ksm_pkg_utility Is

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_utility';

/*************************************************************************
Public function declarations
*************************************************************************/

-- Mathematical modulo operator
Function math_mod(
  m In number
  , n In number
) Return number; -- m % n

-- Rewritten to_date to return NULL for invalid dates
Function to_date2(
  str In varchar2
  , format In varchar2 Default 'yyyymmdd'
) Return date;

-- Rewritten to_number to return NULL for invalid strings
Function to_number2(
  str In varchar2
) Return number;

-- Take a string containing a dollar amount and extract the (first) numeric value
Function get_number_from_dollar(
  str In varchar2
) Return number;

End ksm_pkg_utility;
/

Create Or Replace Package Body ksm_pkg_utility Is

/*************************************************************************
Functions
*************************************************************************/

-- Calculates the modulo function; needed to correct Oracle mod() weirdness
Function math_mod(m In number, n In number)
  Return number Is
  -- Declarations
  remainder number;

  Begin
    remainder := mod(m - n * floor(m/n), n);
    Return(remainder);
    Exception
      When Others Then
        Return NULL;
  End;

-- Check whether a passed yyyymmdd string can be parsed sucessfully as a date 
Function to_date2(str In varchar2, format In varchar2)
  Return date Is

  Begin
    Return ksm_pkg_calendar.to_date2(str, format);
  End;

-- Check whether a passed string can be parsed sucessfully as a number
Function to_number2(str In varchar2)
  Return number Is
  
  Begin
    Return to_number(str);
    Exception
      When Others Then
        Return NULL;
  End;

-- Take a string containing a dollar amount and extract the (first) numeric value
Function get_number_from_dollar(str In varchar2) 
  Return number Is
  -- Delcarations
  trimmed varchar2(32);
  mult number;
  amt number;
  
  Begin
    -- Regular expression: extract string starting with $ up to the last digit, period, or comma,
    Select
      -- Target substring starts with a dollar sign and may contain 0-9,.KMB
      regexp_substr(upper(str), '\$[0-9,KMB\.]*')
    Into trimmed
    From DUAL;
    
    -- Look for suffixes K and M and B and calculate the appropriate multiplier
    Select
      Case
        When trimmed Like '%K%' Then 1E3 -- K = thousand = 1,000
        When trimmed Like '%M%' Then 1E6 -- M = million = 1,000,000
        When trimmed Like '%B%' Then 1E9 -- B = billion = 1,000,000,000
        Else 1
      End As mult
    Into mult
    From DUAL;
    
    -- Strip the $ and commas and letters and treat as numeric
    Select
      -- Convert string to numeric
      to_number(
        regexp_replace(
          trimmed
          , '[^0-9\.]' -- Remove non-numeric characters
          , '') -- Replace non-numeric characters with null
        )
    Into amt
    From DUAL;
    
    Return amt * mult;
  End;

End ksm_pkg_utility;
/
