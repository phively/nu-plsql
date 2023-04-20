With 

ksm_pkg_blockers As (
  -- http://www.dba-oracle.com/t_session_locking_plsql_package.htm
  Select Distinct
     ses.sid
     , ses.serial#
     , ses.username
     , ses.action
     , ses.prev_exec_start
     , ses.sql_exec_start
     , ses.logon_time
     , ses.status
     , ses.wait_class
     , ses.state
     , ses.seconds_in_wait
     , ses.blocking_session
     , ses.final_blocking_session
     , ses.sql_id
     , ses.sql_child_number
     , ses.sql_hash_value
  From
    v$session ses
    , v$sqltext sqltxt
  Where ses.sql_address = sqltxt.address
    And lower(sqltxt.sql_text) Like '%ksm_pkg%'
)

, blocked As (
  -- https://www.support.dbagenesis.com/post/lock-conflict-in-oracle
  Select
    ses.sid
    , ses.serial#
    , ses.status
    , ses.sql_id
    , SQL.sql_text
    , SQL.sql_fulltext
  From ksm_pkg_blockers ses
  Inner Join v$sql SQL
    On sql.sql_id = ses.sql_id
    And ses.sql_hash_value = sql.hash_value
    And sql.child_number = ses.sql_child_number
)

Select
  ksm_pkg_blockers.*
--  , blocked.sql_text
  , blocked.sql_fulltext
From ksm_pkg_blockers
Left Join blocked
  On blocked.sid = ksm_pkg_blockers.sid
  And blocked.serial# = ksm_pkg_blockers.serial#
  And blocked.sql_id = ksm_pkg_blockers.sql_id
Order By
  sql_exec_start Desc
  , prev_exec_start Desc
;
