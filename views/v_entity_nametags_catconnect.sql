with e as (select 
de.donor_id,
case when c.ap_school_name_formula__c
like '%J L Kellogg  School Management%'   
then 'Y' 
end as KSM_degree,
c.ucinn_ascendv2__class_level__c,
c.ucinn_ascendv2__conferred_degree_year__c,
c.ucinn_ascendv2__is_preferred__c,
c.ap_degree_type_from_degreecode__c,
c.ap_status__c,
c.ap_school_name_formula__c,
d.name,
d.ucinn_ascendv2__degree_code__c,
de.program, 
de.program_group,
case when de.program like '%FT-MDMBA%'
  or de.program like '%FT-JDMBA%'
  or de.program like '%FT-MMM%'
then 'Joint Program' end as joint_program
from stg_alumni.ucinn_ascendv2__Degree_Information__c c
left join stg_alumni.ucinn_ascendv2__degree_code__c d on d.id = c.ucinn_ascendv2__degree_code__c
inner join  stg_alumni.contact co on co.id = c.ucinn_ascendv2__contact__c
inner join mv_entity_ksm_degrees de on de.donor_id = co.ucinn_ascendv2__donor_id__c
where de.program_group is not null),

degrees_clean as (


select e.donor_id,
e.ucinn_ascendv2__conferred_degree_year__c as degree_year,
case when e.ucinn_ascendv2__degree_code__c IN ('MBA','MMGT')
  then 'MBA' 
    
  when e.KSM_Degree = 'Y' 
    
    and e.ucinn_ascendv2__degree_code__c like '%CERT%'
    
    then 'cKSM' 
    
    
    when e.ucinn_ascendv2__degree_code__c like '%CERT%' then 'Cert'
      
    
    
    end as degree_code
    
from e),

degrees_group_by_year as (

select dc.donor_id, 
dc.degree_year,
dc.degree_code, 
Listagg(trim(dc.degree_year), ', ') Within Group (Order By degree_year Asc)
as degree_strings
from degrees_clean dc 
group by dc.donor_id, 
dc.degree_year,
dc.degree_code),

nametag as (
  Select
    dc.donor_id
    , Listagg(
        trim(degree_strings || ' ' || degree_strings)
        , ', '
      ) Within Group (Order By degree_year Asc, degree_strings Asc)
    As nu_degrees_string
  From degrees_group_by_year dc
  Group By
    dc.donor_id),
    
e as (select e.donor_id,
e.primary_record_type, 
       e.full_name,
       e.institutional_suffix
from mv_entity e),

--- degrees

d as (select d.donor_id,
       d.full_name,
       d.sort_name,
       d.degrees_verbose,
       d.degrees_concat,
       d.first_ksm_grad_date,
       d.first_ksm_year,
       d.first_masters_year,
       d.last_masters_year,
       d.last_noncert_year,
       d.program,
       d.program_group,
       d.program_group_rank,
       d.class_section,
       d.majors_concat,
       d.etl_update_date,
       d.mv_last_refresh
from mv_entity_ksm_degrees d )

select 
e.donor_id,
c.salutation,
c.suffix,
c.pronouns,
c.firstname,
c.middlename,
c.lastname,
c.name,
 d.first_ksm_grad_date,
 nametag.nu_degrees_string,
 d.first_ksm_year,
 d.first_masters_year,
 d.last_masters_year,
 d.last_noncert_year,
d.degrees_verbose
From stg_alumni.contact c
inner join e on e.donor_id = c.ucinn_ascendv2__donor_id__c
left join d on d.donor_id = c.ucinn_ascendv2__donor_id__c
inner join nametag on nametag.donor_id = c.ucinn_ascendv2__donor_id__c
