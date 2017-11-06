-- Kellogg alumni committee participation
Select
  tms_ct.short_desc As committee
  , tms_cs.short_desc As committee_status
  , tms_r.short_desc As role
  , Case
      When (tms_ct.short_desc || ' ' || tms_ct.full_desc) Like '%KSM%' Then 'Y'
      When (tms_ct.short_desc || ' ' || tms_ct.full_desc) Like '%Kellogg%' Then 'Y'
    End As ksm_committee
  , alum.report_name
  , alum.degrees_concat
  , alum.program
  , alum.program_group
  , c.*
From committee c
Inner Join v_entity_ksm_degrees alum On alum.id_number = c.id_number
Inner Join tms_committee_table tms_ct On tms_ct.committee_code = c.committee_code
Inner Join tms_committee_status tms_cs On tms_cs.committee_status_code = c.committee_status_code
Left Join tms_committee_role tms_r On tms_r.committee_role_code = c.committee_role_code
