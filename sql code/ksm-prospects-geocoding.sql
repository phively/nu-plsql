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
  , trim(address.street1 || ' ' || address.street2 || ' ' || address.street3)
    As address_street
  , address.city
  , address.state_code
  , address.zipcode
  , address.foreign_cityzip
  , address.zip_suffix
  , tmsc.short_desc As country
  , Case When address.country_code Is Null Or address.country_code In ('US', '', ' ') Then 'Y' End
    As usa_ind
From addrs
Inner Join address On address.id_number = addrs.id_number
  And address.xsequence = addrs.xsequence
Left Join tms_country tmsc On tmsc.country_code = address.country_code
