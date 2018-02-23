With
-- Which preferred addresses need to be geocoded?
addrs As (
  (
    Select
      to_number(id_number) As id_number
      , xsequence
    From v_ksm_prospect_pool
  ) Minus (
    Select
      to_number(id_number) As id_number
      , xsequence
    From rpt_wcaproon.geocoded_addresses g
  )
)

Select
  addrs.id_number
  , addrs.xsequence
  , address.addr_pref_ind
  , address.street1
  , address.street2
  , address.street3
  , address.city
  , address.state_code
  , address.foreign_cityzip
  , address.zipcode
  , address.zip_suffix
  , tmsc.short_desc As country
From addrs
Inner Join address On address.id_number = addrs.id_number
  And address.xsequence = addrs.xsequence
Left Join tms_country tmsc On tmsc.country_code = address.country_code
