With
ids As (
  Select id_number
  From entity
  Where id_number In (
    '0000314497', '0000372980', '0000831507', '0000841535', '0000548536', '0000648089', '0000433433', '0000432865', '0000389887', '0000287825', '0000342515', '0000371305', '0000821991', '0000328033', '0000118434', '0000086400', '0000368183', '0000298670', '0000157941', '0000387701', '0000289974', '0000389798', '0000432836', '0000318037', '0000316396', '0000840488', '0000299226', '0000176162', '0000484797', '0000432796', '0000309198', '0000088507', '0000296400', '0000556508', '0000314248', '0000548229', '0000397139', '0000405808', '0000545711', '0000498723', '0000174698', '0000411480', '0000298039', '0000407580', '0000441681'
  ) Or id_number In (
    '0000842787', '0000809844', '0000809349', '0000836792', '0000729911', '0000316787', '0000782803', ' ', ' ', '0000534427', '0000086401', '0000261938', ' ', '0000604375', ' ', '0000417810', ' ', ' ', ' ', '0000660291', ' ', '0000381849', ' ', ' ', '0000575006', '0000542973', '0000066469', '0000727148', '0000561355', ' ', '0000706108', '0000705550', '0000625758', '0000545712', '0000550689', '0000192359', ' ', '0000798132', ' ', '0000789516'
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
