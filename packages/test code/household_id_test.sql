Select *
From table(ksm_pkg.tbl_entity_households_ksm)
Where id_number In
  -- Test IDs
  (
    '0000262301', -- non-KSM no spouse
    '0000667071', -- KSM no spouse
    '0000003803', '0000003804', -- both spouses non-KSM
    '0000667067', -- KSM with non-KSM spouse
    '0000697199', -- non-KSM with KSM spouse
    '0000666964', '0000666955', -- same year same programs
    '0000668667', '0000666464', -- different year same programs
    '0000532299', '0000542272', -- same year different programs
    '0000668904', '0000666991', -- different year different programs
    '0000348132', '0000041724'
  )
Order By household_id;
