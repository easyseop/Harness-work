-- 카드상품 테이블
CREATE TABLE TSCRDBB01 (
  cardNo          CHAR(20) NOT NULL,  -- 카드번호 / 번호
  aprvAmt         DECIMAL(15),        -- 승인금액 / 금액15
  issuYmd         CHAR(8),            -- 발급년월일 / 년월일8
  sysLstPrcDtm    CHAR(14),           -- 시스템최종처리일시 / 일시14
  sysLstUsrNo     CHAR(20),           -- 시스템최종사용자번호 / 번호
  PRIMARY KEY (cardNo)
);
