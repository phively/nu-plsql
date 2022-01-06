Create or Replace View v_seasonal_calendar as 

With
season As (
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
    --- Substring Month From the Start Date String. Grab 5 and 6th Character since date is year/mm/dd
    , to_number(substr(a.start_dt, 5, 2)) As start_month
    --- Substring Day from the start date string. Grab 7th and 8th Character since date is year/mm/dd
    , Case When to_number(substr(a.start_dt, 7, 2)) = 0 Then 1
      Else to_number(substr(a.start_dt, 7, 2))
      End As start_day
    , a.stop_dt
    --- Substring the Stop Days/months the Same Way
    , to_number(substr(a.stop_dt, 5, 2)) As stop_month
    , Case When to_number(substr(a.stop_dt, 7, 2)) = 0 Then 1
      Else to_number(substr(a.stop_dt, 7, 2))
      End As stop_day
    --- Extract todays day and month from Paul's calendar 
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
  --- Seasonal and Active Addresses Only! 
  Where a.addr_type_code = 'S'
    And a.addr_status_code = 'A'
    --- Take out missing start and stop dates
    And a.start_dt != '00000000'
    And a.stop_dt != '00000000'
),

-- Make the start/stop actual dates
 get_year As (
  Select
    id_number
    , Case
        When start_month <= stop_month Then cal.CURR_FY
          -- create start/stop with the same year. 
        When start_month > stop_month Then (cal.CURR_FY - 1)
          -- create start/stop where the start year is 1 less than stop year

          ELSE Null
      End As start_year1
     , Case
        When start_month >= stop_month Then cal.CURR_FY
          -- create start/stop with the same year
        When start_month < stop_month Then (cal.CURR_FY)
          -- create start/stop where the start year is 1 less than stop year
          ELSE Null
      End As stop_year1
  From season
  Cross Join rpt_pbh634.v_current_calendar cal
),

real_dates as (Select
  gy.id_number
  , Case
  /* Make Case Statements to Reflect Start and Stop Dates
  If the Start and Stop date have Already Passed, then we go to next year
  If the Start and Stop Date have not passed, then we stay in the current year and timeframe */  
         When start_month = 2 And start_day = 29 Then to_date ('03' || '01' || start_year1, 'mmddyyyy') - 1
         Else to_date(lpad(start_month, 2, '0') || lpad(start_day, 2, '0') || start_year1, 'mmddyyyy')
      End As real_start_date1
   , Case
          When stop_month = 2 and stop_day = 29 then to_date ('03' || '01' || stop_year1, 'mmddyyyy') - 1
            Else to_date(lpad(stop_month, 2, '0') || lpad(stop_day, 2, '0') || stop_year1, 'mmddyyyy')
      End As real_stop_date1     
--- Check with Paul about some of the few entities with a start date after a stop date
From get_year gy
inner join season on season.id_number = gy.id_number)
           
select nf.Address_Status
  , nf.Address_Type
  , nf.addr_pref_ind
  , nf.company_name_1
  , nf.company_name_2
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
  , CASE WHEN rpt_pbh634.v_current_calendar.TODAY >= real_dates.real_start_date1
  AND rpt_pbh634.v_current_calendar.TODAY <= real_dates.real_stop_date1 THEN 'SEASONAL' ELSE '' END AS SEASONAL_TIME_IND
  , real_dates.real_start_date1
  , real_dates.real_stop_date1
  from season nf
  cross join rpt_pbh634.v_current_calendar
  inner join real_dates on real_dates.id_number = nf.id_number
      
