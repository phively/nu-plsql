/*
Select *
From tms_addr_status;

Select *
From tms_address_type;

Select *
From tms_record_status;
*/

/*
With tms1 As (
  Select addr_status_code, short_desc
  From tms_addr_status
),
tms2 As (
  Select addr_type_code, short_desc
  From tms_address_type
)
Select address.id_number, tms1.short_desc, tms2.short_desc, entity.record_status_code
From entity, address
  -- Note that these joints are both on address
  Inner Join tms1
    On address.addr_status_code = tms1.addr_status_code
  Inner Join tms2
    On address.addr_type_code = tms2.addr_type_code
Where address.id_number = entity.id_number;

-- addr_status_code = 'A' appears to be safe
-- Consider also restricting to home, business, alternate
-- Seasonal is actually quite uncommon
*/

/*
Select id_number, xsequence, addr_type_code, addr_status_code, addr_pref_ind, street1, street2, street3,
  foreign_cityzip, city, state_code, zipcode, zip_suffix, postnet_zip, county_code, country_code
From address
Where addr_status_code = 'A'
  And (
    addr_type_code In ('H', 'B')
    Or addr_pref_ind = 'Y'
  )
ORDER BY id_number;
*/

/*
(Select id_number, xsequence
From address
Where addr_status_code = 'A'
  And addr_pref_ind = 'Y')
Union (
(Select id_number, xsequence
From address
Where addr_status_code = 'A'
  And addr_pref_ind != 'Y'
  And addr_type_code = 'H'
) Minus (
Select id_number, xsequence
From address
Where addr_status_code = 'A'
  And addr_pref_ind = 'Y')
)
*/

/*
Select id_number, xsequence
From address
From address
Where addr_status_code = 'A'
  And (
    addr_type_code In ('H', 'B')
    Or addr_pref_ind = 'Y'
  )
And id_number = '0000002576';
*/

/*
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
Select entity.id_number, pref_xseq, home_xseq, bus_xseq
From entity
  Left Join pref
    On entity.id_number = pref.id_number
  Left Join home
    On entity.id_number = home.id_number
  Left Join bus
    On entity.id_number = bus.id_number
Where entity.id_number = '0000015901'
*/

Select id_number, advance.master_addr(id_number, 'sTaTe_CoDe')
From entity
Where id_number In ('0000704936');
