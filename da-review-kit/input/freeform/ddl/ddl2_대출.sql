CREATE TABLE TXLONBA01 (              -- 대출계좌 (시스템구분 X)
  LOAN_ACCT_NO     CHAR(20) NOT NULL, -- 대출계좌번호 / 번호
  LOAN_BAL_AMT     DECIMAL(99,3),     -- 대출잔액금액 / 금액99
  TMP_MEMO         VARCHAR(100),      -- 임시메모 / 내용100
  PRIMARY KEY (LOAN_ACCT_NO)
);
