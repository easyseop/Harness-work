-- 테이블: 고객기본 (스키마 DW_CUST)
CREATE TABLE TSCUSCA01 (
  custNo          CHAR(20)   NOT NULL,  -- 고객번호 / 번호
  custSex         CHAR(1)    NOT NULL,  -- 고객성별 / 성별1
  custNm          CHAR(50),             -- 고객명 / 명50
  baseYmd         CHAR(8),              -- 기준년월일 / 년월일8
  sysLstPrcDtm    CHAR(14),             -- 시스템최종처리일시 / 일시14
  sysLstUsrNo     CHAR(20),             -- 시스템최종사용자번호 / 번호
  PRIMARY KEY (custNo)
);
