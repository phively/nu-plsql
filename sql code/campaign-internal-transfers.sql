Select prim_gift_receipt_number, prim_gift_amount, prim_gift_comment,
  to_number(regexp_replace((regexp_replace(regexp_substr(prim_gift_comment, '\$[0-9,\.]*'), '\$', '')), ',', '')) As extracted_amount
From primary_gift pg
Where pg.prim_gift_receipt_number In (
  '0001822680', '0001822680', '0002026958', '0002026958', '0002085466', '0002236510', '0001865609', '0002155493', '0001831716', '0001914963', '0001978781', '0002036842', '0002098537', '0002168385', '0002236470', '0002236510', '0002380946', '0002398045', '0002494980', '0001865609', '0002155493'
)
