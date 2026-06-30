CREATE TABLE TXLONBA01 (              -- 대출계좌 (시스템구분 X)
  loanAcctNo       CHAR(20) NOT NULL, -- 대출계좌번호 / 번호
  loanBalAmt       DECIMAL(99,3),     -- 대출잔액금액 / 금액99
  tmpMemo          VARCHAR(100),      -- 임시메모 / 내용100
  PRIMARY KEY (loanAcctNo)
);
