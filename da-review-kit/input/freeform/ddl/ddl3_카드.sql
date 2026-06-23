-- 카드상품 테이블
CREATE TABLE TSCRDBB01 (
  CARD_NO          CHAR(20) NOT NULL,  -- 카드번호 / 번호
  APRV_AMT         DECIMAL(15),        -- 승인금액 / 금액15
  ISSU_YMD         CHAR(8),            -- 발급년월일 / 년월일8
  SYS_LST_PRC_DTM  CHAR(14),           -- 시스템최종처리일시 / 일시14
  SYS_LST_USR_NO   CHAR(20),           -- 시스템최종사용자번호 / 번호
  PRIMARY KEY (CARD_NO)
);
