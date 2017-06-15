PL/SQL Developer Test script 3.0
122
-- Created on 6/13/2017 by PBH634 
Declare 
  -- Local variables here
  Type rc2 Is Ref Cursor;
  crs sys_refcursor;
  Type rec Is Record (
    ID_NUMBER varchar2(10),
    PREF_MAIL_NAME varchar2(512),
    FACULTY_STAFF_IND varchar2(512),
    JOINT_IND varchar2(1),
    JOINT_NAME_1 varchar2(512),
    JOINT_NAME_2 varchar2(512),
    JNT_FORMAL_SALUTATION varchar2(512),
    PREF_NAME_SORT varchar2(512),
    RECORD_TYPE varchar2(512),
    RECORD_STATUS varchar2(512),
    PREF_CLASS_YEAR varchar2(512),
    PREF_SCHOOL varchar2(512),
    PREF_ADDRESS_LINE1 varchar2(512),
    PREF_ADDRESS_LINE2 varchar2(512),
    PREF_ADDRESS_LINE3 varchar2(512),
    PREF_ADDRESS_LINE4 varchar2(512),
    PREF_ADDRESS_LINE5 varchar2(512),
    PREF_ADDRESS_LINE6 varchar2(512),
    PREF_ADDRESS_LINE7 varchar2(512),
    PREF_ADDRESS_LINE8 varchar2(512),
    TX_GYPM_IND varchar2(1),
    TX_NUMBER varchar2(512),
    TX_SEQUENCE integer,
    PMT_ON_PLEDGE_NUMBER varchar2(10),
    ASSOCIATED_CODE varchar2(512),
    TRANSACTION_TYPE varchar2(512),
    PAYMENT_TYPE varchar2(512),
    DATE_OF_RECORD varchar2(10),
    PROCESSED_DATE varchar2(10),
    LEGAL_CREDIT float,
    SOFT_CREDIT float,
    TOTAL_TRANS_AMT float,
    PMT_ON_PLEDGE_DATE varchar2(10),
    PMT_ON_PLEDGE_AMOUNT float,
    PLEDGE_BALANCE float,
    PLEDGE_STATUS varchar2(512),
    PAY_FREQUENCY varchar2(512),
    PLEDGE_COMMENT varchar2(512),
    RECURRING_12MONTHS_AMOUNT float,
    ALLOCATION_CODE varchar2(512),
    ALLOC_SHORT_NAME varchar2(512),
    ALLOC_SCHOOL_GROUP varchar2(512),
    ALLOC_DEPARTMENT varchar2(512),
    APPEAL_CODE varchar2(512),
    APPEAL_DESC varchar2(512),
    TRANSACTION_CATEGORY varchar2(512),
    TRUSTEE_CREDIT_IND varchar2(1),
    BATCH_NUMBER varchar2(512),
    PRIM_PREMIUM_CNT float,
    PRIM_PREMIUM_AMT float,
    ADJUSTMENT_IND varchar2(512),
    REASON_CHANGED varchar2(512),
    REASON_CHANGED_DATE varchar2(10),
    CURRENT_FY varchar2(10),
    CURRENT_FY_GIFT_AMOUNT float,
    CURRENT_FY_GIFT_COUNT integer,
    PREVIOUS_FY varchar2(10),
    PREVIOUS_FY_GIFT_AMOUNT float,
    PREVIOUS_FY_GIFT_COUNT integer,
    SELECTED_SCHOOL_GROUP varchar2(512),
    PROCESSED_COMMENT varchar2(512),
    ANONYMOUS_IND varchar2(1),
    NOTATIONS varchar2(1000),
    REPORT_GROUPING varchar2(512),
    P_MIN_AMOUNT varchar2(512),
    P_MAX_AMOUNT varchar2(512),
    PROSPECT_MANAGER varchar2(512),
    ALLOC_LONG_NAME varchar2(512),
    SALUTATION_TYPE1 varchar2(512),
    STAFF_SALUTATION1 varchar2(512),
    SALUTATION_TYPE2 varchar2(512),
    STAFF_SALUTATION2 varchar2(512),
    SALUTATION_TYPE3 varchar2(512),
    STAFF_SALUTATION3 varchar2(512),
    V_USER_NAME varchar2(512)
  );
  Type recs Is Table Of rec;
  res rec;
  results recs;
Begin
  -- Test statements here
/*  ADVANCE_NU.NU_RPT_PKG_SCHOOL_TRANSACTION.NU_RPT_P_SCHOOL_TRANS_REPORT(
    p_start_date => '06/12/2017', p_end_date => '06/12/2017', 
    p_fiscal_year => '2017', i_username => 'pbh634', O_RC => crs
  );
  Fetch crs Bulk Collect Into results;
  Execute Immediate 'Truncate Table rpt_pbh634.t_giftlog';
  Commit Work;
  Forall i in 1..(results.count)
    Insert Into rpt_pbh634.t_giftlog Values results(i);
  Commit Work;
*/
--  Delete table t_giftlog; 
/*
  Loop
    Fetch crs Into res;
    Exit When crs%notfound;
    dbms_output.put_line(res.TX_NUMBER);
  End Loop;
*/

ksm_gift_log.school_transaction_rpt;
dbms_output.put_line(ksm_pkg.get_fiscal_year(dt => add_months(trunc(sysdate, 'Month'), -1)));
dbms_output.put_line(to_char(add_months(trunc(sysdate, 'Month'), -1), 'mm/dd/yyyy'));
dbms_output.put_line(to_char(trunc(sysdate) - 1, 'mm/dd/yyyy'));

-- Scheduler test
/*  dbms_scheduler.create_job(
    job_name => 'rpt_pbh634.proc_ksm_gift_log',
    job_type => 'PLSQL_BLOCK',
    job_action => 'Begin ksm_gift_log.school_transaction_rpt; Commit; End;',
    start_date => sysdate + 1/24/60, -- 1 minute in the future
    enabled => True
  );
*/
End;
0
0
