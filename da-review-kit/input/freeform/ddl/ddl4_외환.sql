CREATE TABLE TSFXDAC01 (             -- 외환약정
  FX_ACCT_NO       CHAR(20),         -- 외환계좌번호 / 번호
  CUST_GENDER      CHAR(1),          -- 고객성별 / 성별1   (영문 CUST_GENDER)
  BASE_YMD         CHAR(8),          -- 기준년월일 / 년월일8
  SYS_LST_PRC_DTM  CHAR(14),         -- 시스템최종처리일시 / 일시14
  SYS_LST_USR_NO   CHAR(20)          -- 시스템최종사용자번호 / 번호
);
