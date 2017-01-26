-- Create table for KSM alumni base
Create Table ksm_alumni_base As

-- List of people with Kellogg degrees
With ksm_degree As (
  Select Distinct id_number
  From degrees d
  Where
    -- Has a KSM or BUS Northwestern degree
    (d.institution_code = '31173' Or d.local_ind = 'Y')
    And d.school_code In ('KSM', 'BUS')
    -- Drop non-grads
    And (d.non_grad_code = ' ' Or d.non_grad_code Is Null)
)
-- Pull needed bio data
Select entity.id_number, entity.pref_name_sort, entity.person_or_org, entity.record_status_code, entity.institutional_suffix,
       advance.ksm_degrees_concat(entity.id_number) As degrees_concat,
       advance.master_addr(entity.id_number, 'state_code') As master_state,
       advance.master_addr(entity.id_number, 'country') As master_country,
       entity.gender_code, entity.spouse_id_number,
       advance.ksm_degrees_concat(entity.spouse_id_number) As spouse_degrees_concat
From entity
  Inner Join ksm_degree
    On entity.id_number = ksm_degree.id_number;
