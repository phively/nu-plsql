create or replace package test_pkg is

Function tbl_committee_gab
  Return ksm_pkg_committee.t_committee_members Pipelined;

end test_pkg;
/
create or replace package body test_pkg is

  Function tbl_committee_gab
    Return ksm_pkg_committee.t_committee_members Pipelined As
    committees ksm_pkg_committee.t_committee_members;
    
    Begin
    committees := ksm_pkg_committee.committee_members(my_committee_cd => ksm_pkg_committee.get_string_constant('committee_gab'));

      For i in 1..committees.count Loop
        Pipe row(committees(i));
      End Loop;
      Return;
    End;

end test_pkg;
/
