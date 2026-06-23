-- 테이블: 고객기본 (스키마 DW_CUST)
CREATE TABLE TSCUSCA01 (
  CUST_NO          CHAR(20)   NOT NULL,  -- 고객번호 / 번호
  CUST_SEX         CHAR(1)    NOT NULL,  -- 고객성별 / 성별1
  CUST_NM          CHAR(50),             -- 고객명 / 명50
  BASE_YMD         CHAR(8),              -- 기준년월일 / 년월일8
  SYS_LST_PRC_DTM  CHAR(14),             -- 시스템최종처리일시 / 일시14
  SYS_LST_USR_NO   CHAR(20),             -- 시스템최종사용자번호 / 번호
  PRIMARY KEY (CUST_NO)
);
