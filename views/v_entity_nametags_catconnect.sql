--- Get Donor ID 
    
with en as (select e.donor_id
from mv_entity e),

e as (select 
en.donor_id,
case when c.ap_school_name_formula__c
like '%J L Kellogg  School Management%'   then 'Y'  end as KSM_degree,
c.ucinn_ascendv2__class_level__c,
c.ucinn_ascendv2__conferred_degree_year__c as degree_year,
c.ap_degree_type_from_degreecode__c,
d.ucinn_ascendv2__degree_code__c
from stg_alumni.ucinn_ascendv2__Degree_Information__c c
--- inner joins to get donor id 
inner join  stg_alumni.contact co on co.id = c.ucinn_ascendv2__contact__c
inner join en on en.donor_id = co.ucinn_ascendv2__donor_id__c
left join stg_alumni.ucinn_ascendv2__degree_code__c d on d.id = c.ucinn_ascendv2__degree_code__c),

--- Clean Degrees

--- Assign MBA, certificate and non MBA 

degrees_clean as (
select e.donor_id,
e.degree_year,
e.ucinn_ascendv2__degree_code__c as degree_code,
e.KSM_Degree,
--- honorary degrees 
case when e.ap_degree_type_from_degreecode__c = 'Honorary'
  then 'H' 
--- Under grad degrees 
when e.ap_degree_type_from_degreecode__c = 'Undergraduate Degree' 
  then '' 
--- Certificate 
when e.KSM_Degree = 'Y' and e.ucinn_ascendv2__degree_code__c like '%CERT%' then 'cKSM' 
--- MBA and MMGT 
when e.ucinn_ascendv2__degree_code__c IN ('MBA','MMGT')
then 'MBA' 
else e.ucinn_ascendv2__degree_code__c
  --- degree strings - will be the degree abbrivation.... Honorary, Undergrad, Cert, MBA
end as degree_string
from e),

degrees_group_by_year as (
select dc.donor_id, 
dc.degree_year,
dc.degree_code, 
'''' || substr(degree_year, -2) -- Last two digits of Year on Nametag
As year_abbr,
--- Listagg multiple years - Order by degree asc 
Listagg(trim(dc.degree_string), ', ') Within Group (Order By degree_year Asc)
as degree_strings
from degrees_clean dc 
group by dc.donor_id, 
dc.degree_year,
dc.degree_code),

--- Final concat

 degrees_concat As (
  Select
     donor_id
    , Listagg(
        trim(year_abbr || ' ' || degree_strings)
        , ', '
      ) Within Group (Order By degree_year Asc, degree_strings Asc)
    As nu_degrees_string
  From degrees_group_by_year
  Group By
    donor_id
),


--- KSM degrees information
--- Good for double checking data 

d as (select d.donor_id,
       d.full_name,
       d.degrees_verbose,
       d.first_ksm_year,
       d.program,
       d.program_group,
       d.class_section
from mv_entity_ksm_degrees d)

select distinct 
en.donor_id,
--- Dean Salutation? Ask Paul 
c.salutation,
c.suffix,
c.firstname,
c.middlename,
c.lastname,
c.name,
dc.nu_degrees_string as nu_degree_string,
d.first_ksm_year,
d.degrees_verbose
From stg_alumni.contact c
inner join en on en.donor_id = c.ucinn_ascendv2__donor_id__c
inner join degrees_concat dc on dc.donor_id = c.ucinn_ascendv2__donor_id__c
left join d on d.donor_id = c.ucinn_ascendv2__donor_id__c
