Create Or Replace Function advance.master_addr(id In varchar2, field In varchar2)
/*
Created by pbh634
Takes an ID and field and returns active master address, defined as preferred if available, else home, else business.
Standardizes input fields to lower-case.

Sample output (prompt -> result):
advance.master_addr('0000704936', 'city')       -> Chicago
advance.master_addr('0000704936', 'sTaTe_CoDe') -> IL
*/
Return character Is
  master_addr varchar2(120); -- final output
  field_ varchar2(60) := lower(field); -- lower-case field
  -- xsequences for master address
  pref_xseq number(6);
  home_xseq number(6);
  bus_xseq number(6);
  xseq number(6); -- final xsequence of address to retrieve

  -- Cursor to store possible xsequences
  Cursor t_xseq Is
  -- xsequence of active preferred, home, and business addresses
    With pref As (
      Select id_number, xsequence As pref_xseq
      From address
      Where addr_status_code = 'A'
        And addr_pref_ind = 'Y'
    ),
    home As (
      Select id_number, xsequence As home_xseq
      From address
      Where addr_status_code = 'A'
        And addr_type_code = 'H'
    ),
    bus As (
      Select id_number, xsequence As bus_xseq
      From address
      Where addr_status_code = 'A'
        And addr_type_code = 'B'
    )
    -- Combine preferred, home, and business xseq into a row
    Select pref_xseq, home_xseq, bus_xseq
    From entity
      Left Join pref
        On entity.id_number = pref.id_number
      Left Join home
        On entity.id_number = home.id_number
      Left Join bus
        On entity.id_number = bus.id_number
    Where entity.id_number = id;

Begin
    
  -- Determine which xsequence to use for master address
  Open t_xseq;
    -- Grab possible candidates for xseq
    Fetch t_xseq Into pref_xseq, home_xseq, bus_xseq;
  Close t_xseq;
  -- Store best choice in xseq
  If pref_xseq Is Not Null Then xseq := pref_xseq;
    ElsIf home_xseq Is Not Null Then xseq := home_xseq;
    ElsIf bus_xseq Is Not Null Then xseq := bus_xseq;
  End If;
  
  -- Retrieve the master address
  If xseq Is Null Then Return('#NA');
  End If;
  -- Big Case-When to fill in the appropriate field
  Select Case
    When field_ = 'care_of' Then care_of
    When field_ = 'company_name_1' Then company_name_1
    When field_ = 'company_name_2' Then company_name_2
    When field_ = 'business_title' Then business_title
    When field_ = 'street1' Then street1
    When field_ = 'street2' Then street2
    When field_ = 'street3' Then street3
    When field_ = 'foreign_cityzip' Then foreign_cityzip
    When field_ = 'city' Then city
    When field_ = 'state_code' Then address.state_code
    When field_ Like 'state%' Then tms_states.short_desc
    When field_ = 'zipcode' Then zipcode
    When field_ = 'zip_suffix' Then zip_suffix
    When field_ = 'postnet_zip' Then postnet_zip
    When field_ = 'county_code' Then address.county_code
    When field_ Like 'county%' Then tms_county.full_desc
    When field_ = 'country_code' Then address.country_code
    When field_ Like 'country%' Then tms_country.short_desc
  End
  Into master_addr
  From address
    Left Join tms_country
      On address.country_code = tms_country.country_code
    Left Join tms_states
      On address.state_code = tms_states.state_code
    Left Join tms_county
      On address.county_code = tms_county.county_code
  Where id_number = id
    And xsequence = xseq;

Return(master_addr);

End master_addr;
/
