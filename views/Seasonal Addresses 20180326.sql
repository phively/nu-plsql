/*
Select *
From address
where addr_type_code = 'S'

Select distinct a.addr_type_code, adt.short_desc
From address a
Left join tms_address_type adt
ON adt.addr_type_code = a.addr_type_code

Select distinct a.addr_status_code, adt.short_desc
From address a
Left join tms_addr_status adt
ON adt.addr_status_code = a.addr_status_code

select *
from tms_address_type

Select * From rpt_pbh634.v_current_calendar

select distinct e.record_status_code, rc.short_desc
from entity e
Left Join tms_record_status rc
ON rc.record_status_code = e.record_status_code

________________________________________________________________________________________
*/
Create or replace view rpt_dgz654.v_seasonal_addr AS

With
numeric_fun As (
  Select
    a.id_number
    , tms_addr_status.short_desc AS Address_Status
    , tms_address_type.short_desc AS Address_Type
    , a.addr_pref_ind
    , a.company_name_1
    , a.company_name_2
    , a.care_of
    , a.street1
    , a.street2
    , a.street3
    , a.foreign_cityzip
    , a.city
    , a.state_code
    , a.zipcode
    , tms_country.short_desc AS Country
    , a.start_dt
    , to_number(substr(a.start_dt, 5, 2)) As start_month
    , Case When to_number(substr(a.start_dt, 7, 2)) = 0 Then 1
      Else to_number(substr(a.start_dt, 7, 2))
      End As start_day
    , a.stop_dt
    , to_number(substr(a.stop_dt, 5, 2)) As stop_month
    , Case When to_number(substr(a.stop_dt, 7, 2)) = 0 Then 1
      Else to_number(substr(a.stop_dt, 7, 2))
      End As stop_day
    , extract(month from cal.today) As today_month
    , extract(day from cal.today) As today_day
  From address a
  Cross Join rpt_pbh634.v_current_calendar cal
  LEFT JOIN tms_addr_status
  ON tms_addr_status.addr_status_code = a.addr_status_code
  LEFT JOIN tms_address_type
  ON tms_address_type.addr_type_code = a.addr_type_code
  LEFT JOIN tms_country
  ON tms_country.country_code = a.country_code
  Where a.addr_type_code = 'S'
    And a.addr_status_code = 'A'
    And a.start_dt != '00000000'
    And a.stop_dt != '00000000'
),

-- Make the start/stop actual dates
 get_year As (
  Select
    id_number
    , Case
        When start_month <= stop_month Then cal.CURR_FY
          -- create start/stop with the same year
        When start_month > stop_month Then (cal.CURR_FY - 1)
          -- create start/stop where the start year is 1 less than stop year
          ELSE Null
      End As start_year1
      , Case
        When start_month <= stop_month Then cal.CURR_FY
          -- create start/stop with the same year
        When start_month > stop_month Then (cal.CURR_FY)
          -- create start/stop where the start year is 1 less than stop year
          ELSE Null
      End As start_year2
     , Case
        When start_month >= stop_month Then cal.CURR_FY
          -- create start/stop with the same year
        When start_month < stop_month Then (cal.CURR_FY)
          -- create start/stop where the start year is 1 less than stop year
          ELSE Null
      End As stop_year1
       , Case
        When start_month >= stop_month Then (cal.CURR_FY + 1)
          -- create start/stop with the same year
        When start_month < stop_month Then (cal.CURR_FY)
          -- create start/stop where the start year is 1 less than stop year
          ELSE Null
      End As stop_year2
      -- Do the same thing for stop_year
  From numeric_fun
  Cross Join rpt_pbh634.v_current_calendar cal
)

-- Final query -- combine everything into a real date
Select
  nf.id_number
  , nf.Address_Status
  , nf.Address_Type
  , nf.addr_pref_ind
  , nf.company_name_1
  , nf.company_name_2
  , nf.care_of
  , nf.street1
  , nf.street2
  , nf.street3
  , nf.foreign_cityzip
  , nf.city
  , nf.state_code
  , nf.zipcode
  , nf.Country
  , nf.start_dt
  , nf.stop_dt
  , Case
         When start_month = 2 And start_day = 29 Then to_date ('03' || '01' || start_year1, 'mmddyyyy') - 1
         Else to_date(lpad(start_month, 2, '0') || lpad(start_day, 2, '0') || start_year1, 'mmddyyyy')
      End As real_start_date1
   , Case
          When stop_month = 2 and stop_day = 29 then to_date ('03' || '01' || stop_year1, 'mmddyyyy') - 1
            Else to_date(lpad(stop_month, 2, '0') || lpad(stop_day, 2, '0') || stop_year1, 'mmddyyyy')
      End As real_stop_date1
   , Case
          When start_month = 2 and start_day = 29 Then to_date ('03' || '01' || start_year2, 'mmddyyyy') - 1
            Else to_date(lpad(start_month, 2, '0') || lpad(start_day, 2, '0') || start_year2, 'mmddyyyy')
      End As real_start_date2
   , Case
          When stop_month = 2 and stop_day = 29 Then to_date ('03' || '01' || stop_year2, 'mmddyyyy') - 1
            Else to_date(lpad(stop_month, 2, '0') || lpad(stop_day, 2, '0') || stop_year2, 'mmddyyyy')
      End As real_stop_date2
 -- , to_date(lpad(start_month, 2, '0') || lpad(start_day, 2, '0') || start_year1, 'mmddyyyy') As real_start_date1
 -- , to_date(lpad(stop_month, 2, '0') || lpad(stop_day, 2, '0') || stop_year1, 'mmddyyyy') As real_stop_date1
 -- , to_date(lpad(start_month, 2, '0') || lpad(start_day, 2, '0') || start_year2, 'mmddyyyy') As real_start_date2
 -- , to_date(lpad(stop_month, 2, '0') || lpad(stop_day, 2, '0') || stop_year2, 'mmddyyyy') As real_stop_date2
From numeric_fun nf
Inner Join get_year gy
      On gy.id_number = nf.id_number
