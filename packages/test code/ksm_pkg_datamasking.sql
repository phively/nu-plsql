---------------------------
-- ksm_pkg_datamasking tests
---------------------------

-- Vigenere
Select
  ksm_pkg_datamasking.to_cypher_vigenere('hello', 'abc') As trzxb
  , ksm_pkg_datamasking.to_cypher_vigenere('hello', 'abcde') As trzae
  , ksm_pkg_datamasking.to_cypher_vigenere('this time', 'nowandthen') As "SHQEM INFU"
From DUAL
;

-- Random ids with seed
With
table1 As (
  Select *
  From table(ksm_pkg_datamasking.tbl_random_id(random_seed => 101))
  Where rownum <= 10
)
, table2 As (
  Select *
  From table(ksm_pkg_datamasking.tbl_random_id(random_seed => 101))
  Where rownum <= 10
)
Select
  table1.id_number
  , table1.random_id As t1_random_id
  , table2.random_id As t2_random_id
  , table1.random_name As t1_random_name
  , table2.random_name As t2_random_name
From table1
Left Join table2
  On table2.id_number = table1.id_number
;

---------------------------
-- ksm_pkg tests
---------------------------

-- Vigenere
Select
  ksm_pkg_tst.to_cypher_vigenere('hello', 'abc') As trzxb
  , ksm_pkg_tst.to_cypher_vigenere('hello', 'abcde') As trzae
  , ksm_pkg_tst.to_cypher_vigenere('this time', 'nowandthen') As "SHQEM INFU"
From DUAL
;

-- Random ids with seed
With
table1 As (
  Select *
  From table(ksm_pkg_tst.tbl_random_id(random_seed => 101))
  Where rownum <= 10
)
, table2 As (
  Select *
  From table(ksm_pkg_tst.tbl_random_id(random_seed => 101))
  Where rownum <= 10
)
Select
  table1.id_number
  , table1.random_id As t1_random_id
  , table2.random_id As t2_random_id
  , table1.random_name As t1_random_name
  , table2.random_name As t2_random_name
From table1
Left Join table2
  On table2.id_number = table1.id_number
;
