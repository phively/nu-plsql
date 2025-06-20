With K AS (Select CONSTITUENT_DONOR_ID  ,
CONSTITUENT_NAME  ,
DEGREE_SCHOOL_NAME  ,
DEGREE_LEVEL  ,
DEGREE_YEAR ,
DEGREE_CODE ,
DEGREE_NAME ,
DEGREE_PROGRAM  
From table(dw_pkg_base.tbl_degrees)),

e as (select
k.CONSTITUENT_DONOR_ID,
k.CONSTITUENT_NAME,
case when k.DEGREE_SCHOOL_NAME like '%Kellogg%'   then 'Y'  end as KSM_degree,
k.DEGREE_LEVEL,
k.DEGREE_YEAR,
k.DEGREE_CODE
from k),

--- Clean Degrees
--- Assign MBA, certificate and non MBA

degrees_clean as (
select e.CONSTITUENT_DONOR_ID,
e.degree_year,
e.degree_level,
e.degree_code,
e.KSM_Degree,
--- honorary degrees
case when e.degree_code = 'Honorary'
  then 'H'
--- Undergrad degrees
when e.degree_code = 'Undergraduate Degree'
  then ''
--- Certificate
when e.KSM_Degree = 'Y' and e.degree_code like '%CERT%' then 'cKSM'
--- MBA and MMGT
when e.degree_code IN ('MBA','MMGT')
then 'MBA'
else e.degree_code
  --- degree strings - will be the degree abbrivation.... Honorary, Undergrad, Cert, MBA
end as degree_string
from e),


degrees_group_by_year as (
select dc.CONSTITUENT_DONOR_ID,
dc.degree_year,
dc.degree_code,
'''' || substr(degree_year, -2) -- Last two digits of Year on Nametag
As year_abbr,
--- Listagg multiple years - Order by degree asc
Listagg(trim(dc.degree_string), ', ') Within Group (Order By degree_year Asc)
as degree_strings,
Listagg(trim(dc.degree_level), ', ') Within Group (Order By degree_year Asc)
as degree_levels

from degrees_clean dc
group by dc.CONSTITUENT_DONOR_ID,
dc.degree_year,
dc.degree_code),

--- Final concat

degrees_concat As (Select degrees_group_by_year.CONSTITUENT_DONOR_ID,
Listagg(trim(year_abbr || ' ' || degree_strings), ', '
) Within Group (Order By degree_year Asc, degree_strings Asc) As nu_degrees_string,
Listagg(trim(year_abbr || ' ' || degrees_group_by_year.degree_levels), ', '
) Within Group (Order By degree_year Asc, degree_strings Asc) As degree_levels

From degrees_group_by_year
Group By CONSTITUENT_DONOR_ID)

Select distinct k.CONSTITUENT_DONOR_ID,
k.CONSTITUENT_NAME,
case when k.DEGREE_SCHOOL_NAME like '%Kellogg%'   then 'Y'  end as KSM_degree,
dc.degree_levels,
dc.nu_degrees_string
from k
inner join degrees_concat dc on dc.CONSTITUENT_DONOR_ID = k.CONSTITUENT_DONOR_ID
