Create Or Replace View v_all_address As

with 

G as (Select
gc.*
From table(rpt_pbh634.ksm_pkg_tmp.tbl_geo_code_primary) gc
Inner Join address
On address.id_number = gc.id_number
And address.xsequence = gc.xsequence),

--- Continent 

C as (select *
from RPT_PBH634.v_addr_continents),


prime as (Select DISTINCT
         a.Id_number
      ,  a.addr_pref_ind
      ,  tms_address_type.short_desc AS Address_Type
      ,  a.city
      ,  a.zipcode
      ,  a.state_code
      ,  c.country as country
      ,  G.GEO_CODE_PRIMARY_DESC AS PRIMARY_GEO_CODE
      ,  C.continent
      FROM address a
      LEFT JOIN tms_addr_status ON tms_addr_status.addr_status_code = a.addr_status_code
      LEFT JOIN tms_address_type ON tms_address_type.addr_type_code = a.addr_type_code
      LEFT JOIN tms_country ON tms_country.country_code = a.country_code
      LEFT JOIN C ON C.country_code = A.COUNTRY_CODE
      LEFT JOIN g ON g.id_number = A.ID_NUMBER
      AND g.xsequence = a.xsequence
      WHERE a.addr_status_code = 'A'
      --- Primary Country
      and a.addr_pref_IND = 'Y'),


--- Non Primary Business
Business As(Select DISTINCT
        a.Id_number
      ,  max(tms_address_type.short_desc) AS Address_Type
      ,  max(a.city) as city
      ,  max (a.state_code) as state_code
      ,  max (a.zipcode) as zipcode
      ,  max (c.country) as country
      ,  max (a.start_dt)
      ,  max (G.GEO_CODE_PRIMARY_DESC) AS BUSINESS_GEO_CODE
      ,  max (C.continent) as continent
      FROM address a
      LEFT JOIN tms_addr_status ON tms_addr_status.addr_status_code = a.addr_status_code
      LEFT JOIN tms_address_type ON tms_address_type.addr_type_code = a.addr_type_code
      LEFT JOIN tms_country ON tms_country.country_code = a.country_code
      LEFT JOIN C ON C.country_code = A.COUNTRY_CODE
      LEFT JOIN g ON g.id_number = A.ID_NUMBER
      AND g.xsequence = a.xsequence
      WHERE (a.addr_status_code = 'A'
      and a.addr_pref_IND = 'N'
      AND a.addr_type_code = 'B')
      Group By a.id_number),


Home as (Select DISTINCT
      a.Id_number
      ,  max(tms_address_type.short_desc) AS Address_Type
      ,  max(a.city) as city
      ,  max (a.state_code) as state_code
      ,  max (a.zipcode) as zipcode
      ,  max (c.country) as country 
      ,  max (a.start_dt)
      ,  max (G.GEO_CODE_PRIMARY_DESC) AS home_GEO_CODE
      ,  max (C.continent) as continent
      FROM address a
      LEFT JOIN tms_addr_status ON tms_addr_status.addr_status_code = a.addr_status_code
      LEFT JOIN tms_address_type ON tms_address_type.addr_type_code = a.addr_type_code
      LEFT JOIN tms_country ON tms_country.country_code = a.country_code
      LEFT JOIN C ON C.country_code = A.COUNTRY_CODE
      LEFT JOIN g ON g.id_number = A.ID_NUMBER
      AND g.xsequence = a.xsequence
      WHERE (a.addr_status_code = 'A'
      and a.addr_pref_IND = 'N'
      AND a.addr_type_code = 'H')
      Group By a.id_number),

Alt_Home As  (Select DISTINCT
      a.Id_number
      ,  max(tms_address_type.short_desc) AS Address_Type
      ,  max(a.city) as city
      ,  max (a.state_code) as state_code
      ,  max (a.zipcode) as zipcode
      ,  max (c.country) as country
      ,  max (a.start_dt)
      ,  max (G.GEO_CODE_PRIMARY_DESC) AS alt_home_GEO_CODE
      ,  max (C.continent) as continent
      FROM address a
      LEFT JOIN tms_addr_status ON tms_addr_status.addr_status_code = a.addr_status_code
      LEFT JOIN tms_address_type ON tms_address_type.addr_type_code = a.addr_type_code
      LEFT JOIN tms_country ON tms_country.country_code = a.country_code
      LEFT JOIN C ON C.country_code = A.COUNTRY_CODE
      LEFT JOIN g ON g.id_number = A.ID_NUMBER
      AND g.xsequence = a.xsequence
      WHERE (a.addr_pref_IND = 'N'
      and a.addr_status_code = 'A')
      AND (a.addr_type_code = 'AH')
      Group By a.id_number),

Alt_Bus As  (Select DISTINCT
      a.Id_number
      ,  max(tms_address_type.short_desc) AS Address_Type
      ,  max(a.city) as city
      ,  max (a.state_code) as state_code
      ,  max (a.zipcode) as zipcode
      ,  max (c.country) as country
      ,  max (a.start_dt)
      ,  max (G.GEO_CODE_PRIMARY_DESC) AS alt_bus_GEO_CODE
      ,  max (C.continent) as continent
      FROM address a
      LEFT JOIN tms_addr_status ON tms_addr_status.addr_status_code = a.addr_status_code
      LEFT JOIN tms_address_type ON tms_address_type.addr_type_code = a.addr_type_code
      LEFT JOIN tms_country ON tms_country.country_code = a.country_code
      LEFT JOIN C ON C.country_code = A.COUNTRY_CODE
      LEFT JOIN g ON g.id_number = A.ID_NUMBER
      AND g.xsequence = a.xsequence
      WHERE (a.addr_pref_IND = 'N'
      and a.addr_status_code = 'A'
      AND a.addr_type_code = 'AB')
      Group By a.id_number),

Seasonal as (
        Select DISTINCT
         a.Id_number
      ,  max(tms_address_type.short_desc) AS Address_Type
      ,  max(a.city) as city
      ,  max (a.state_code) as state_code
      ,  max (a.zipcode) as zipcode
      ,  max (c.country) as country 
      ,  max (a.start_dt)
      ,  max (G.GEO_CODE_PRIMARY_DESC) AS SEASONAL_GEO_CODE
      ,  max (C.continent) as continent
      FROM address a
      LEFT JOIN tms_addr_status ON tms_addr_status.addr_status_code = a.addr_status_code
      LEFT JOIN tms_address_type ON tms_address_type.addr_type_code = a.addr_type_code
      LEFT JOIN tms_country ON tms_country.country_code = a.country_code
      LEFT JOIN C ON C.country_code = A.COUNTRY_CODE
      LEFT JOIN g ON g.id_number = A.ID_NUMBER
      AND g.xsequence = a.xsequence
      WHERE (a.addr_pref_IND = 'N'
      and a.addr_status_code = 'A'
      AND a.addr_type_code = 'S')
      Group By a.id_number)


SELECT DISTINCT
    E.ID_NUMBER
    --- Primary Address
  , prime.Address_Type as primary_address_type
  , prime.CITY as primary_city
  , prime.PRIMARY_GEO_CODE as primary_geo
  , prime.STATE_Code as primary_state
  , prime.zipcode as primary_zipcode
  , prime.country as primary_country
  , prime.continent
  --- Home Address - Non Preferred
  , home.Address_Type as non_preferred_home_type
  , home.city as non_preferred_home_city
  , home.home_GEO_CODE as non_pref_home_geo
  , home.state_code as non_preferred_home_state
  , home.zipcode as non_preferred_home_zipcode
  , home.country as non_preferred_home_country
  , home.continent as non_preferred_home_continent
  --- Business Address - Non Preferred
  , Business.Address_Type as non_preferred_business_type
  , Business.BUSINESS_GEO_CODE as non_preferred_business_geo
  , Business.city as non_preferred_business_city
  , Business.state_code as non_preferred_business_state
  , Business.zipcode as non_preferred_business_zipcode
  , Business.country as non_preferred_business_country
  , Business.continent as non_preferred_busin_continent
  --- Alternative Home - Non Preferred
  , Alt_Home.Address_Type as alt_home_type
  , Alt_Home.alt_home_geo_code as alt_home_geo
  , Alt_Home.city as alt_home_city
  , Alt_Home.state_code as alt_home_state
  , Alt_Home.zipcode as alt_home_zipcode
  , Alt_Home.country as alt_home_country
  , Alt_Home.continent as alt_home_continent
  --- Alternative Business - Non Preferred 
  , Alt_Bus.Address_Type as alt_bus_type
  , Alt_Bus.alt_bus_GEO_CODE as alt_business_geo
  , Alt_Bus.city as alt_bus_city
  , Alt_Bus.state_code as alt_bus_state
  , Alt_Bus.zipcode as alt_bus_zipcode
  , Alt_Bus.country as alt_bus_country
  , Alt_Bus.continent as alt_bus_continent
  ---- Seasonal Address - Non Preferred
  , seasonal.Address_Type as seasonal_Type
  , Seasonal.SEASONAL_GEO_CODE
  , Seasonal.city as seasonal_city
  , Seasonal.state_code as seasonal_state
  , Seasonal.zipcode as seasonal_zipcode
  , Seasonal.country as seasonal_country
  , Seasonal.continent as seasonal_continent
  ---- Lookup Geocode
  , trim(prime.PRIMARY_GEO_CODE || chr(13) || home.home_GEO_CODE || chr(13) || Business.BUSINESS_GEO_CODE ||
    chr(13) || Alt_Home.alt_home_geo_code || chr(13) || Alt_Bus.state_code || chr(13) || Seasonal.SEASONAL_GEO_CODE)
    As lookup_geo
    ---- State
  , trim(prime.STATE_Code || chr(13) || home.state_code || chr(13) || Business.state_code ||
    chr(13) || Alt_Home.state_code || chr(13) || Alt_Bus.state_code || chr(13) || Seasonal.state_code)
    As lookup_state
    --- Zipcode
  ,trim(prime.zipcode || chr(13) || home.zipcode  || chr(13) || Business.zipcode  ||
    chr(13) || Alt_Home.zipcode  || chr(13) || Alt_Bus.zipcode  || chr(13) || Seasonal.zipcode)
    As lookup_zipcode 
    --- Country
      , trim(prime.country || chr(13) || home.country || chr(13) || Business.country ||
    chr(13) || Alt_Home.country || chr(13) || Alt_Bus.country || chr(13) || Seasonal.country)
    As lookup_country
    --- Continent
      ,trim(prime.continent || chr(13) || home.continent || chr(13) || Business.continent ||
    chr(13) || Alt_Home.continent || chr(13) || Alt_Bus.continent || chr(13) || Seasonal.continent)
    As lookup_continent
    
    
   
--FROM rpt_pbh634.v_entity_ksm_households E -- Don't need HHID so just use entity
FROM entity e
LEFT JOIN prime on prime.id_number = e.id_number
LEFT JOIN Business ON Business.id_number = e.id_number
LEFT JOIN Alt_Home ON Alt_Home.id_number = e.id_number
LEFT JOIN Alt_Bus ON Alt_Bus.id_number = e.id_number
LEFT JOIN Seasonal ON Seasonal.id_number = e.id_number
Left Join home on home.id_number = e.id_number


WHERE
(prime.id_number is not null
or Business.id_number is not null
or Alt_Home.id_number is not null
or Alt_Bus.id_number is not null
or Seasonal.id_number is not null
or home.id_number is not null)
and E.PERSON_OR_ORG = 'P'
--and e.PROGRAM is not null
;


/* 

Using the View - Example to find 

--- Geocode

Select *
From v_all_address
Where lookup_geo Like '%%' 

--- State

Select *
From v_all_address
Where lookup_state Like '%%'

--- Zipcode

Select *
From v_all_address
Where lookup_zipcode Like '%%'

--- Country

Select *
From v_all_address
Where lookup_country Like '%%'

*/ 
