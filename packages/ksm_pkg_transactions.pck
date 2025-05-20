Create Or Replace Package ksm_pkg_transactions Is

/*************************************************************************
Author  : PBH634
Created : 5-20-2025
Purpose : Consolidated gift transactions: credit + opportunity + payment, for
  ease of downstream processing.
Dependencies: dw_pkg_base

Suggested naming conventions:
  Pure functions: [function type]_[description]
  Row-by-row retrieval (slow): get_[object type]_[action or description] e.g.
  Table or cursor retrieval (fast): tbl_[object type]_[action or description]
*************************************************************************/

/*************************************************************************
Public constant declarations
*************************************************************************/

pkg_name Constant varchar2(64) := 'ksm_pkg_transactions';

/*************************************************************************
Public type declarations
*************************************************************************/

Type rec_transaction Is Record (
  
);

/*************************************************************************
Public table declarations
*************************************************************************/

Type transactions Is Table Of rec_transaction;

/*************************************************************************
Public pipelined functions declarations
*************************************************************************/

Function tbl_transactions
  Return transactions Pipelined;

/*********************** About pipelined functions ***********************
Q: What is a pipelined function?

A: Pipelined functions are used to return the results of a cursor row by row.
This is an efficient way to re-use a cursor between multiple programs. Pipelined
tables can be queried in SQL exactly like a table when embedded in the table()
function. My experience has been that thanks to the magic of the Oracle compiler,
joining on a table() function scales hugely better than running a function once
on each element of a returned column. Note that the exact columns returned need
to be specified as a public type, which I did in the type and table declarations
above, or the pipelined function can't be run in pure SQL. Alternately, the
pipelined function could return a generic table, but the columns would still need
to be individually named.
*************************************************************************/

/*************************************************************************
End of package
*************************************************************************/

End ksm_pkg_transactions;
/
Create Or Replace Package Body ksm_pkg_transactions Is

/*************************************************************************
Private cursors -- data definitions
*************************************************************************/

Cursor c_transactions Is
  
  
;

/*************************************************************************
Pipelined functions
*************************************************************************/

Function tbl_transactions
  Return transactions Pipelined As
  -- Declarations
  trn transactions;

  Begin
    Open c_transactions;
      Fetch c_transactions Bulk Collect Into trn;
    Close c_transactions;
    For i in 1..(trn.count) Loop
      Pipe row(trn(i));
    End Loop;
    Return;
  End;

End ksm_pkg_transactions;
/
