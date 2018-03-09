/* KSM prospect geocoding using Data Science Toolkit */

-- Clear existing table
Drop Table tbl_geo_google;

-- Table definition
Create Table tbl_geo_google (
  id_number varchar2(10) -- Entity ID number
  , xsequence number -- Preferred address xsequence
  , latitude number -- Geocoded latitude
  , longitude number -- Geocoded longitude
);

-- Insert rows
Insert All

Into tbl_geo_google Values(/* Data goes here*/)

-- Commit work
Select * From DUAL;
Commit Work;

-- Table index (not really needed)
Create Index pref_addr_geo On tbl_geo_google(id_number, xsequence);

-- Check results
Select *
From tbl_geo_google;
