With
ids As (
  Select id_number
  From entity
  Where id_number In (
    '0000730206', '0000296095', '0000291445', '0000343018', '0000297118', '0000316722', '0000420494', '0000328657', '0000056554', '0000403446', '0000406452', '0000313455', '0000355339', '0000311491', '0000314076', '0000308669', '0000301415', '0000397263', '0000285006', '0000285031', '0000758411', '0000254448', '0000404397', '0000286721', '0000200114', '0000573876', '0000289872', '0000338604', '0000383158', '0000402368', '0000286531', '0000289822', '0000282954', '0000298373'
  ) Or id_number In (
    ' ', ' ', '0000605841', '0000786632', '0000626105', '0000677606', '0000633114', ' ', ' ', '0000512824', '0000730775', '0000667521', '0000769024', '0000621277', '0000768970', ' ', '0000393830', '0000306070', ' ', '0000385541', ' ', '0000436317', ' ', '0000803459', '0000293464', ' ', '0000349552', '0000071226', '0000538363', '0000783748', '0000633315', '0000604380', ' ', '0000783760'
  )
)

, nu_kids As (
  Select
    relationship.id_number
    , e.report_name As parent_name
    , e.institutional_suffix As parent_inst_suffix
    , relation_id_number
    , entity.report_name As child_name
    , entity.institutional_suffix As child_inst_suffix
  From relationship
  Inner Join ids
    On ids.id_number = relationship.id_number
  Inner Join entity e
    On e.id_number = relationship.id_number
  Inner Join entity
    On entity.id_number = relationship.relation_id_number
  Where relation_type_code = 'CP'
    And entity.institutional_suffix Is Not Null
)

, kids_listagg As (
  Select
    id_number
    , Listagg(child_name, chr(13)) Within Group (Order By child_name Asc)
      As child_names
    , Listagg(child_inst_suffix, chr(13)) Within Group (Order By child_name Asc)
      As child_suffixes
  From nu_kids
  Group By id_number
)

Select
  ids.id_number
  , entity.report_name
  , entity.institutional_suffix
  , kids_listagg.child_names
  , kids_listagg.child_suffixes
From ids
Inner Join entity
  On entity.id_number = ids.id_number
Left Join kids_listagg
  On kids_listagg.id_number = ids.id_number
