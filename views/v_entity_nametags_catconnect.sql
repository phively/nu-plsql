--- Degrees - Identifying KSM Degrees, MD, JD and MMM

with e as (select 
de.donor_id,
case when c.ap_school_name_formula__c
like '%J L Kellogg  School Management%'   then 'Y'  end as KSM_degree,
c.ucinn_ascendv2__class_level__c,
c.ucinn_ascendv2__conferred_degree_year__c as degree_year,
c.ap_degree_type_from_degreecode__c,
d.ucinn_ascendv2__degree_code__c,
de.program, 
de.program_group,
case when de.program like '%FT-MDMBA%'
  or de.program like '%FT-MDMBA%'
  or de.program like '%FT-MMM%'
then 'Joint Program' end as joint_program
from stg_alumni.ucinn_ascendv2__Degree_Information__c c
left join stg_alumni.ucinn_ascendv2__degree_code__c d on d.id = c.ucinn_ascendv2__degree_code__c
inner join  stg_alumni.contact co on co.id = c.ucinn_ascendv2__contact__c
inner join mv_entity_ksm_degrees de on de.donor_id = co.ucinn_ascendv2__donor_id__c
where de.program_group is not null),

--- Clean Degrees

--- Assign MBA, certificate and non MBA 

degrees_clean as (
select e.donor_id,
e.degree_year,
case when e.ap_degree_type_from_degreecode__c = 'Undergraduate Degree'
  then 'Y' Else 'N' End as Undergrad_flag, 
--- MBA and MMGT 
case when e.ucinn_ascendv2__degree_code__c IN ('MBA','MMGT')
then 'MBA' 
--- Marked as degree, but a certificate 
when e.KSM_Degree = 'Y' and e.ucinn_ascendv2__degree_code__c like '%CERT%' then 'cKSM' 
when e.ucinn_ascendv2__degree_code__c like '%CERT%' then 'Cert'
--- Need to find Honorory Degree     
end as degree_code
    
from e),

degrees_group_by_year as (

select dc.donor_id, 
dc.degree_year,
dc.degree_code, 
dc.Undergrad_flag,
'''' || substr(degree_year, -2) -- 'YY class year: rightmost 2 digits
As year_abbr,
Listagg(trim(dc.degree_year), ', ') Within Group (Order By degree_year Asc)
as degree_strings
from degrees_clean dc 
group by dc.donor_id, 
dc.degree_year,
dc.degree_code,
dc.Undergrad_flag),

nametag as (
  Select
    dc.donor_id
    , Listagg(
        trim(year_abbr || ' ' || year_abbr)
        , ', '
      ) Within Group (Order By degree_year Asc, degree_strings Asc)
    As nu_degrees_string
  From degrees_group_by_year dc
  Group By
    dc.donor_id),
    
e as (select e.donor_id,
e.primary_record_type, 
e.institutional_suffix
from mv_entity e),

--- degrees

d as (select d.donor_id,
       d.full_name,
       d.degrees_verbose,
       d.first_ksm_year,
       d.program,
       d.program_group,
       d.class_section
from mv_entity_ksm_degrees d )

select 
e.donor_id,
c.salutation,
c.suffix,
c.firstname,
c.middlename,
c.lastname,
c.name,
 nametag.nu_degrees_string,
 d.first_ksm_year,
 d.degrees_verbose
From stg_alumni.contact c
inner join e on e.donor_id = c.ucinn_ascendv2__donor_id__c
left join d on d.donor_id = c.ucinn_ascendv2__donor_id__c
inner join nametag on nametag.donor_id = c.ucinn_ascendv2__donor_id__c
