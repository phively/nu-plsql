Create Or Replace Package ksm_pkg_utility Is

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_utility';

/*************************************************************************
Public function declarations
*************************************************************************/

-- Mathematical modulo operator
Function mod_math(
  m In number
  , n In number
) Return number; -- m % n

-- Rewritten to_number to return NULL for invalid strings
Function to_number2(
  str In varchar2
) Return number;

-- Rewritten to_date to return NULL for invalid dates
Function to_date2(
  str In varchar2
  , format In varchar2 Default 'yyyymmdd'
) Return date;

-- Parse yyyymmdd string into a date
-- If there are invalid date parts, overwrite with the corresponding element from fallback_dt
Function to_date_parse(
  date_str In varchar2
  , fallback_dt In date Default current_date()
) Return date;

-- Take a string containing a dollar amount and extract the (first) numeric value
Function to_number_from_dollar(
  str In varchar2
) Return number;

End ksm_pkg_utility;
/

Create Or Replace Package Body ksm_pkg_utility Is

/*************************************************************************
Functions
*************************************************************************/

-- Calculates the modulo function; needed to correct Oracle mod() weirdness
Function mod_math(m In number, n In number)
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

-- Check whether a passed string can be parsed sucessfully as a number
Function to_number2(str In varchar2)
  Return number Is
  
  Begin
    Return to_number(str);
    Exception
      When Others Then
        Return NULL;
  End;

-- Check whether a passed yyyymmdd string can be parsed sucessfully as a date
Function to_date2(str In varchar2, format In varchar2)
  Return date Is
  
  Begin
    Return to_date(str, format);
    Exception
      When Others Then
        Return NULL;
  End;

-- Takes a yyyymmdd string and an optional fallback date argument and produces a date type
Function to_date_parse(date_str In varchar2, fallback_dt In date)
  Return date Is
  -- Declarations
  dt_out date;
  -- Parsed from string
  y varchar2(4);
  m varchar2(2);
  d varchar2(2);
  -- Parsed from fallback date
  fy varchar2(4);
  fm varchar2(2);
  fd varchar2(2);
  
  Begin
    -- Try returning str as-is (y-m-d) as a date
    dt_out := to_date2(date_str);
    If dt_out Is Not Null Then
      Return(dt_out);
    End If;
    
    -- Extract ymd
    y    := substr(date_str, 1, 4);
    m    := substr(date_str, 5, 2);
    d    := substr(date_str, 7, 2);
    fy   := lpad(extract(year from fallback_dt), 4, '0');
    fm   := lpad(extract(month from fallback_dt), 2, '0');
    fd   := lpad(extract(day from fallback_dt), 2, '0');
    
    -- Try returning y-m-01
    dt_out := to_date2(y || m || '01');
    If dt_out Is Not Null Then
      Return(dt_out);
    End If;
    -- Try returning y-fm-fd
    dt_out := to_date2(y || fm || fd);
    If dt_out Is Not Null Then
      Return(dt_out);
    End If;
    -- Try returning fy-m-d
    dt_out := to_date2(fy || m || d);
    If dt_out Is Not Null Then
      Return(dt_out);
    End If;
    -- Try returning fy-m-01
    dt_out := to_date2(fy || m || '01');
    If dt_out Is Not Null Then
      Return(dt_out);
    End If;
    -- If all else fails return the fallback date
    Return(trunc(fallback_dt));
    
  End;

-- Take a string containing a dollar amount and extract the (first) numeric value
Function to_number_from_dollar(str In varchar2) 
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
