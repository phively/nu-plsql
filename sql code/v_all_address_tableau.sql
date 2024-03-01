CREATE OR REPLACE VIEW V_ALL_ADDRESS_TABLEAU AS
with assign as (select assign.id_number,
       assign.prospect_manager,
       assign.lgos,
       assign.managers,
       assign.curr_ksm_manager
from rpt_pbh634.v_assignment_summary assign),

i as (select advance_nu_rpt.entity_interest_area_summary.id_number,
            advance_nu_rpt.entity_interest_area_summary.potential_interest_areas,
            advance_nu_rpt.entity_interest_area_summary.multi_or_single_interest
from advance_nu_rpt.entity_interest_area_summary),


v as (select v.id_number,
             v.primary_address_type,
             v.primary_city,
             v.primary_geo,
             v.primary_state,
             v.primary_zipcode,
             v.primary_country,
             v.primary_country_code,
             v.continent,
             v.non_preferred_home_type,
             v.non_preferred_home_city,
             v.non_pref_home_geo,
             v.non_preferred_home_state,
             v.non_preferred_home_zipcode,
             v.non_preferred_home_country,
             v.non_pref_home_country_code,
             v.non_preferred_home_continent,
             v.non_preferred_business_type,
             v.non_preferred_business_geo,
             v.non_preferred_business_city,
             v.non_preferred_business_state,
             v.non_preferred_business_zipcode,
             v.non_preferred_business_country,
             v.non_pref_business_country_code,
             v.non_preferred_busin_continent,
             v.alt_home_type,
             v.alt_home_geo,
             v.alt_home_city,
             v.alt_home_state,
             v.alt_home_zipcode,
             v.alt_home_country,
             v.alt_home_country_code,
             v.alt_home_continent,
             v.alt_bus_type,
             v.alt_business_geo,
             v.alt_bus_city,
             v.alt_bus_state,
             v.alt_bus_zipcode,
             v.alt_bus_country,
             v.alt_bus_country_code,
             v.alt_bus_continent,
             v.seasonal_Type,
             v.SEASONAL_GEO_CODE,
             v.seasonal_city,
             v.seasonal_state,
             v.seasonal_zipcode,
             v.seasonal_country,
             v.seasonal_country_code,
             v.seasonal_continent,
             v.lookup_geo,
             v.lookup_state,
             v.lookup_zipcode,
             v.lookup_country,
             v.lookup_continent
from v_all_address v),

TP AS (SELECT TP.ID_NUMBER,
       TP.EVALUATION_RATING,
       TP.OFFICER_RATING
From nu_prs_trp_prospect TP)


select h.ID_NUMBER,
       entity.person_or_org,
       h.RECORD_STATUS_CODE,
       h.REPORT_NAME,
       h.HOUSEHOLD_PRIMARY,
       h.INSTITUTIONAL_SUFFIX,
       i.potential_interest_areas,
       i.multi_or_single_interest,
       h.SPOUSE_ID_NUMBER,
       h.SPOUSE_REPORT_NAME,
       h.SPOUSE_SUFFIX,
       assign.prospect_manager,
       assign.lgos,
       assign.managers,
       assign.curr_ksm_manager,
       TP.EVALUATION_RATING,
       TP.OFFICER_RATING,
--- Primary address
       v.primary_city,
       v.primary_geo,
       v.primary_state,
       case when v.primary_country = 'United States'
then SUBSTR(v.primary_zipcode, 1, 5) end as primary_zipcode,
       v.primary_country,
--- Non Preferred Home
       v.non_preferred_home_type,
       v.non_preferred_home_city,
       v.non_pref_home_geo,
       v.non_preferred_home_state,
case when v.non_preferred_home_country = 'United States'
then SUBSTR(v.non_preferred_home_zipcode, 1, 5) end as non_pref_home_zipcode,
       v.non_preferred_home_country,
       --- Non Preferred Business
       v.non_preferred_business_geo,
       v.non_preferred_business_city,
       v.non_preferred_business_state,
case when v.non_preferred_business_city = 'United States'
then SUBSTR(v.non_preferred_business_zipcode, 1, 5) end as non_preferred_business_zipcode,
       v.non_preferred_business_country,
       --- Non Preferred Alt Home
       v.alt_home_type,
       v.alt_home_geo,
       v.alt_home_city,
       v.alt_home_state,
case when v.alt_home_country = 'United States'
then SUBSTR(v.alt_home_zipcode, 1, 5) end as alt_home_zipcode,
       v.alt_home_country,
       ---- Non Pref alt business
       v.alt_business_geo,
       v.alt_bus_city,
       v.alt_bus_state,
       case when v.alt_bus_country = 'United States'
then SUBSTR(v.alt_bus_zipcode, 1, 5) end as alt_bus_zipcode,
       v.alt_bus_country,
       --- Seasonal Address
       v.seasonal_Type,
       v.SEASONAL_GEO_CODE,
       v.seasonal_city,
       v.seasonal_state,
 case when v.seasonal_country = 'United States'
then SUBSTR(v.seasonal_zipcode, 1, 5) end as seasonal_zipcode_trimmed,
       v.seasonal_zipcode,
       v.seasonal_country,
       v.lookup_geo,
       v.lookup_state,
       v.lookup_zipcode,
       v.lookup_country
from rpt_pbh634.v_entity_ksm_households h
inner join entity on entity.id_number = h.id_number
left join assign on assign.id_number = h.id_number
left join v on v.id_number = h.ID_NUMBER
left join TP on TP.id_number = h.id_number
left join i on i.id_number = h.id_number
--- Persons!
where entity.person_or_org = 'P'
and h.RECORD_STATUS_CODE = 'A'
order by h.report_name asc;