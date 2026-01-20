With

-- Depends on datamart-degree-mapping sql code
rawdat As (
  Select
    dm.*
  From tmp_dm_degree_mapping dm
)

-- New datamart-side transformation
, dm_priority As (
  Select
    donor_id
    , full_name
    , min(program) keep(dense_rank First Order By degree_level_rank Asc, program Asc)
      As priority_program
  From rawdat
  Group By
    donor_id
    , full_name
)

-- Comparison audit
Select
  dmp.donor_id
  , dmp.full_name
  , dmp.priority_program
  , kd.program
    As comparison_program
From dm_priority dmp
Left Join mv_entity_ksm_degrees kd
  On kd.donor_id = dmp.donor_id
Where kd.program != dmp.priority_program
;
