CREATE TABLE TSFXDAC01 (             -- 외환약정
  fxAcctNo         CHAR(20),         -- 외환계좌번호 / 번호
  custGender       CHAR(1),          -- 고객성별 / 성별1   (영문 custGender, 기대 custSex)
  baseYmd          CHAR(8),          -- 기준년월일 / 년월일8
  sysLstPrcDtm     CHAR(14),         -- 시스템최종처리일시 / 일시14
  sysLstUsrNo      CHAR(20)          -- 시스템최종사용자번호 / 번호
);
