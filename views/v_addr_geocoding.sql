Create Or Replace View v_addr_geocoding As

With

/* Merged view; if conflicts, prefer the geocoded_address view */

-- Geocoded addresses
wc As (
  Select
    lpad(to_number(ga.id_number), 10, '0') As id_number
    , ga.xsequence
    , ga.latitude
    , ga.longitude
  From rpt_wcaproon.geocoded_addresses ga
)

, ph As (
  Select gg.*
  From rpt_pbh634.tbl_geo_google gg
)

-- Dedupe conflicts
, dedupe As (
  (
  Select
    id_number
    , xsequence
  From ph
  
  ) Minus (

  Select
    id_number
    , xsequence
  From wc
  )
)

-- Final query
(
Select wc.*
From wc

) Union All (

Select ph.*
From ph
Inner Join dedupe
  On dedupe.id_number = ph.id_number
  And dedupe.xsequence = ph.xsequence
)
;
