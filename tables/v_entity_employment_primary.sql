/*************************************************************************
Current primary entity employment
*************************************************************************/

Create Or Replace View v_entity_employment_primary As
Select *
From mv_entity_employment
Where primary_employment_indicator = 'Y'
;
