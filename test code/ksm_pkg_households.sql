---------------------------
-- ksm_pkg_households tests
---------------------------

Select *
From table(ksm_pkg_households.tbl_households)
;

---------------------------
-- mv tests
---------------------------

With

dat As (
  Select '0000532299' As id1, '0000542272' As id2, 'same year different programs' As explanation From DUAL
  Union Select '0000262301' As id1, NULL As id2, 'non-KSM no spouse' As explanation From DUAL
  Union Select '0000667071' As id1, '' As id2, 'KSM no spouse' As explanation From DUAL
  Union Select '0000666955' As id1, '0000666964' As id2, 'same year same programs' As explanation From DUAL
  Union Select '0000668667' As id1, '0000697199' As id2, 'different year same programs' As explanation From DUAL
  Union Select '0000668904' As id1, '0000666991' As id2, 'different year different programs' As explanation From DUAL
  Union Select '0000667067' As id1, '0000697199' As id2, 'KSM with non-KSM spouse' As explanation From DUAL
  Union Select '0000463496' As id1, '0000889013' As id2, 'non-KSM with non-KSM spouse' As explanation From DUAL
)

Select Distinct
  dat.explanation
  , deg.first_ksm_year As primary_ksm_year
  , sdeg.first_ksm_year As spouse_ksm_year
  , deg.program As primary_ksm_program
  , sdeg.program As spouse_ksm_program
  , hh.*
From mv_households hh
Left Join dat
  On dat.id1 = hh.household_primary_donor_id
Left Join dat sdat
  On sdat.id2 = hh.household_spouse_donor_id
Left Join mv_entity_ksm_degrees deg
  On deg.donor_id = hh.household_primary_donor_id
Left Join mv_entity_ksm_degrees sdeg
  On sdeg.donor_id = hh.household_spouse_donor_id
Where dat.explanation Is Not Null
  Or sdat.explanation Is Not Null
Order By hh.household_id Asc
;
