Create Or Replace Package ksm_pkg_datamasking Is

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_datamasking';

/*************************************************************************
Public type declarations
*************************************************************************/

Type random_id Is Record (
  id_number entity.id_number%type
  , random_id entity.id_number%type
  , random_name entity.report_name%type
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type t_random_id Is Table Of random_id;

/*************************************************************************
Public function declarations
*************************************************************************/

-- Run the Vignere cypher on input text
Function to_cypher_vignere(
  phrase In varchar2
  , key In varchar2
  , wordlength In integer Default 5
) Return varchar2;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

-- Return random IDs
Function tbl_random_id(
  random_seed In varchar2 Default NULL
) Return t_random_id Pipelined;

/*************************************************************************
Public cursors -- data definitions
*************************************************************************/

Cursor c_random_id Is
  With
  -- Random sort of entity table
  random_seed As (
    Select
      id_number
      , dbms_random.value As rv
      , rownum As rn
    From entity
    Order By dbms_random.value
  )
  , random_name As (
    Select
      id_number
      , person_or_org
      , report_name
      , first_name
      , Case
          When person_or_org = 'O'
            Then regexp_substr(report_name, '[A-Za-z]*')
          Else first_name
          End
        As random_name
      , dbms_random.value As rv2
      , rownum As rn2
    From entity
    Order By dbms_random.value
  )
  -- Relabel id_number with row number from random sort
  Select
    random_seed.id_number
    , rownum As random_id
    , random_name
  From random_seed
  Inner Join random_name
    On random_seed.rn = random_name.rn2
  ;

End ksm_pkg_datamasking;
/

Create Or Replace Package Body ksm_pkg_datamasking Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

-- Vigenere cypher implementation adapted from http://www.orafaq.com/forum/t/156830/
Cursor c_cypher_vignere(phrase In varchar2, key In varchar2, wordlength In integer Default 5) Is
  With
  -- Input and key
  phrase_key As (
    Select
      regexp_replace(phrase, '')
        As phrase
      , regexp_replace(key, '')
        As secretkey
    From DUAL
  )
  -- Align key with input
  , encoder_table As (
    Select
      substr(
          phrase
          , level
          , 1
        )
        As phrase
      , substr(
          secretkey
          , decode(mod(level, length(secretkey)), 0, length(secretkey), mod(level, length(secretkey)))
          , 1
        )
        As secretkey
      , level
        As lvl
    From phrase_key
    Connect By level <= length(phrase)
  )
  -- Reencode as ASCII table
  , ascii_table As (
    Select
    ascii(phrase) - 65
      As phrase
    , ascii(secretkey) - 65
      As secretkey
    , lvl
  From encoder_table
  )
  -- Code table
  , cypher_table As (
    Select
      chr(mod(phrase + secretkey, 26) + 65)
        As cyphertext
      , phrase
      , secretkey
      , lvl
      , row_number() Over (Order By lvl) rn
    From ascii_table
  )
  -- Break into length wordlength "words"
  Select
    regexp_replace(
      max(
        sys_connect_by_path(
          decode(mod(rn, wordlength), 0, cyphertext || ' ', cyphertext)
          , '-'
        )
      )
      , '-'
      , ''
    )
    As cyphertext
  From cypher_table
  Connect By rn = prior rn + 1
  Start With rn = 1
  ;

/*************************************************************************
Functions
*************************************************************************/

-- Run the Vignere cypher on input text
Function to_cypher_vignere(
  phrase In varchar2
  , key In varchar2
  , wordlength In integer Default 5
)
  Return varchar2 Is
  -- Declarations
  cyphertext varchar2(1024);
  -- Run cypher
  Begin
    Open c_cypher_vignere(phrase => phrase, key => key, wordlength => wordlength);
    Fetch c_cypher_vignere Into cyphertext;
    Close c_cypher_vignere;
  Return cyphertext;
  End;

/*************************************************************************
Pipelined functions
*************************************************************************/

-- Pipelined function returning a randomly generated ID conversion table
Function tbl_random_id(random_seed In varchar2 Default NULL)
  Return t_random_id Pipelined As
  -- Declarations
  rid t_random_id;
  
  Begin
    -- Set seed
    If random_seed Is Not Null Then
      -- Set random seed
      dbms_random.seed(random_seed);
    End If;
    Open c_random_id;
      Fetch c_random_id Bulk Collect Into rid;
    Close c_random_id;
    For i in 1..(rid.count) Loop
      Pipe row(rid(i));
    End Loop;
    Return;
  End;

End ksm_pkg_datamasking;
/
