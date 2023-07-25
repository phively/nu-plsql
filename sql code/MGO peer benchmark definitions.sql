-- NGC/cash

Select
fiscal_year
--, alloc_short_name
, sum(Case When tx_gypm_ind <> 'Y' Then legal_amount Else 0 End) As ngc
, sum(Case When tx_gypm_ind <> 'P' Then legal_amount Else 0 End) As cash
From v_ksm_giving_trans gt
Where gt.fiscal_year Between 2010 And 2021
--And gt.af_flag = 'Y'
Group By fiscal_year
--, alloc_short_name
Order By fiscal_year Desc
;

-- AF
Select
fiscal_year
--, alloc_short_name
--, sum(Case When tx_gypm_ind <> 'Y' Then legal_amount Else 0 End) As ngc
, sum(Case When tx_gypm_ind <> 'P' Then legal_amount Else 0 End) As cash
From v_ksm_giving_trans gt
Where gt.fiscal_year Between 2010 And 2021
And gt.af_flag = 'Y'
Group By fiscal_year
--, alloc_short_name
Order By fiscal_year Desc
;

-- Corp/Foundation
-- Ignore FA and FN?
Select
fiscal_year
--, alloc_short_name
, sum(Case When tx_gypm_ind <> 'Y' Then legal_amount Else 0 End) As ngc
, sum(Case When tx_gypm_ind <> 'P' Then legal_amount Else 0 End) As cash
From v_ksm_giving_trans gt
Inner Join entity
  On entity.id_number = gt.id_number
Where gt.fiscal_year Between 2010 And 2021
And entity.record_type_code In ('CP', 'CF', 'MA', 'OO') -- Corporation, Corporate Foundation, Medical Affiliate, Other Org
Group By fiscal_year
--, alloc_short_name
Order By fiscal_year Desc
;

-- Alumni
Select
deg.first_ksm_year
, deg.first_masters_year
, deg.program_group
, count(*) As n
From v_entity_ksm_degrees deg
Where deg.record_status_code Not In ('D', 'X', 'I')
And deg.first_ksm_year Is Not Null
Group By
first_ksm_year
, first_masters_year
, program_group
Order By
first_ksm_year Asc
;
