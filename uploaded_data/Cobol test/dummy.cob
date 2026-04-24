*****************************************************************
      * PROGRAM-ID:    CORBAT01                                       *
      * SYSTEM:        CORE BANKING - NIGHTLY RECONCILIATION          *
      * AUTHOR:        TCS LEGACY MODERNIZATION TEAM                  *
      * DATE-WRITTEN:  1994-03-22                                     *
      * LAST-MODIFIED: 2008-11-15 (ADDED SEPA COMPLIANCE)             *
      * DESCRIPTION:   PROCESSES DAILY TRANSACTIONS, CALCULATES       *
      * INTEREST, ASSESSES FEES, AND GENERATES         *
      * THE GENERAL LEDGER RECONCILIATION EXTRACT.     *
      *****************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. CORBAT01.
       AUTHOR. LEGACY-SYSTEMS.
       INSTALLATION. MAINFRAME-LPAR2.
       DATE-WRITTEN. 03/22/1994.
       DATE-COMPILED. 

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRANS-IN-FILE ASSIGN TO 'TRANDLY.DAT'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-TRANS-FS.
           SELECT ACCT-MASTER-FILE ASSIGN TO 'ACCTMST.DAT'
               ORGANIZATION IS INDEXED
               ACCESS MODE IS RANDOM
               RECORD KEY IS ACCT-NUM-KEY
               FILE STATUS IS WS-ACCT-FS.
           SELECT GL-EXTRACT-FILE ASSIGN TO 'GLEXTRT.DAT'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-GL-FS.
           SELECT ERROR-REPORT ASSIGN TO 'ERRRPT.TXT'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ERR-FS.

       DATA DIVISION.
       FILE SECTION.
       
       FD  TRANS-IN-FILE
           RECORD CONTAINS 120 CHARACTERS
           BLOCK CONTAINS 0 RECORDS.
       01  TRANS-REC.
           05 TR-ACCT-NUM        PIC X(12).
           05 TR-TRANS-CODE      PIC X(3).
           05 TR-TRANS-AMT       PIC S9(9)V99 COMP-3.
           05 TR-TRANS-DATE      PIC 9(8).
           05 TR-BRANCH-ID       PIC X(5).
           05 TR-TELLER-ID       PIC X(8).
           05 TR-NARRATIVE       PIC X(76).

       FD  ACCT-MASTER-FILE
           RECORD CONTAINS 250 CHARACTERS.
       01  ACCT-REC.
           05 ACCT-NUM-KEY       PIC X(12).
           05 ACCT-TYPE          PIC X(2).
           05 ACCT-STATUS        PIC X(1).
           05 ACCT-BALANCE       PIC S9(11)V99 COMP-3.
           05 ACCT-OPEN-DATE     PIC 9(8).
           05 ACCT-INTEREST-YTD  PIC S9(9)V99 COMP-3.
           05 ACCT-FEES-YTD      PIC S9(7)V99 COMP-3.
           05 ACCT-LAST-ACT-DATE PIC 9(8).
           05 ACCT-OVERDRAFT-LMT PIC S9(9)V99 COMP-3.
           05 FILLER             PIC X(185).

       FD  GL-EXTRACT-FILE
           RECORD CONTAINS 80 CHARACTERS.
       01  GL-REC.
           05 GL-ACCOUNT-CODE    PIC X(10).
           05 GL-DR-CR-IND       PIC X(1).
           05 GL-AMOUNT          PIC 9(13)V99.
           05 GL-POSTING-DATE    PIC 9(8).
           05 GL-REFERENCE       PIC X(46).

       FD  ERROR-REPORT
           RECORD CONTAINS 132 CHARACTERS.
       01  ERR-PRINT-LINE        PIC X(132).

       WORKING-STORAGE SECTION.
      *---------------------------------------------------------------*
      * FILE STATUS INDICATORS                                     *
      *---------------------------------------------------------------*
       01  WS-FILE-STATUS.
           05 WS-TRANS-FS        PIC XX VALUE SPACES.
              88 TRANS-EOF       VALUE '10'.
              88 TRANS-OK        VALUE '00'.
           05 WS-ACCT-FS         PIC XX VALUE SPACES.
              88 ACCT-FOUND      VALUE '00'.
              88 ACCT-NOT-FOUND  VALUE '23'.
           05 WS-GL-FS           PIC XX VALUE SPACES.
           05 WS-ERR-FS          PIC XX VALUE SPACES.

      *---------------------------------------------------------------*
      * PROCESSING ACCUMULATORS AND COUNTERS                       *
      *---------------------------------------------------------------*
       01  WS-COUNTERS.
           05 WS-REC-READ        PIC 9(7) VALUE ZERO.
           05 WS-REC-PROCESSED   PIC 9(7) VALUE ZERO.
           05 WS-REC-ERRORS      PIC 9(7) VALUE ZERO.
           05 WS-GL-RECORDS      PIC 9(7) VALUE ZERO.

       01  WS-TOTALS.
           05 WS-TOT-DEPOSITS    PIC S9(13)V99 VALUE ZERO.
           05 WS-TOT-WITHDRAWS   PIC S9(13)V99 VALUE ZERO.
           05 WS-TOT-FEES        PIC S9(11)V99 VALUE ZERO.
           05 WS-TOT-INTEREST    PIC S9(11)V99 VALUE ZERO.

      *---------------------------------------------------------------*
      * SYSTEM DATES AND TIMES                                     *
      *---------------------------------------------------------------*
       01  WS-SYSTEM-DATE.
           05 WS-SYS-YEAR        PIC 9(4).
           05 WS-SYS-MONTH       PIC 9(2).
           05 WS-SYS-DAY         PIC 9(2).
       01  WS-CURR-DATE-NUM      PIC 9(8).

      *---------------------------------------------------------------*
      * FEE AND INTEREST RATE TABLES (SPAGHETTI LOGIC TARGET)      *
      *---------------------------------------------------------------*
       01  WS-RATE-TABLES.
           05 WS-SAVINGS-RATE    PIC V9(5) VALUE .01250.
           05 WS-CHECKING-RATE   PIC V9(5) VALUE .00150.
           05 WS-PREMIUM-RATE    PIC V9(5) VALUE .02750.
           
           05 WS-OD-FEE-BASE     PIC 9(3)V99 VALUE 35.00.
           05 WS-MAINT-FEE       PIC 9(3)V99 VALUE 12.00.
           05 WS-WIRE-FEE        PIC 9(3)V99 VALUE 25.00.

       01  WS-CALC-VARS.
           05 WS-TEMP-BAL        PIC S9(11)V99 COMP-3.
           05 WS-INT-CALC        PIC S9(9)V99 COMP-3.
           05 WS-FEE-CALC        PIC S9(7)V99 COMP-3.
           05 WS-OVERDRAFT-AMT   PIC S9(9)V99 COMP-3.

      *---------------------------------------------------------------*
      * ERROR REPORTING STRUCTURES                                 *
      *---------------------------------------------------------------*
       01  WS-ERR-HEADER.
           05 FILLER             PIC X(40) VALUE SPACES.
           05 FILLER             PIC X(52) 
              VALUE 'NIGHTLY BATCH PROCESSING - EXCEPTION REPORT'.
           05 FILLER             PIC X(40) VALUE SPACES.

       01  WS-ERR-DETAIL.
           05 FILLER             PIC X(2)  VALUE SPACES.
           05 ERR-ACCT           PIC X(12).
           05 FILLER             PIC X(4)  VALUE SPACES.
           05 ERR-CODE           PIC X(3).
           05 FILLER             PIC X(4)  VALUE SPACES.
           05 ERR-MSG            PIC X(100).

      *---------------------------------------------------------------*
      * EMBEDDED SQL SIMULATION VARIABLES                          *
      *---------------------------------------------------------------*
           EXEC SQL BEGIN DECLARE SECTION END-EXEC.
       01  DB2-BRANCH-VARS.
           05 DB2-BRANCH-ID      PIC X(5).
           05 DB2-BRANCH-STATUS  PIC X(1).
           05 DB2-BRANCH-REGION  PIC X(10).
           EXEC SQL END DECLARE SECTION END-EXEC.
           EXEC SQL INCLUDE SQLCA END-EXEC.

       PROCEDURE DIVISION.
       0000-MAIN-PROCESSING.
           PERFORM 1000-INITIALIZATION
           PERFORM 2000-PROCESS-TRANSACTIONS 
               UNTIL TRANS-EOF
           PERFORM 3000-FINALIZATION
           STOP RUN.

       1000-INITIALIZATION.
           DISPLAY '*** CORBAT01 STARTED ***'
           
           MOVE FUNCTION CURRENT-DATE(1:8) TO WS-CURR-DATE-NUM
           
           OPEN INPUT TRANS-IN-FILE
           OPEN I-O   ACCT-MASTER-FILE
           OPEN OUTPUT GL-EXTRACT-FILE
           OPEN OUTPUT ERROR-REPORT
           
           IF WS-TRANS-FS NOT = '00'
               DISPLAY 'FATAL ERROR OPENING TRANSACTION FILE: ' WS-TRANS-FS
               PERFORM 9999-ABEND
           END-IF
           
           WRITE ERR-PRINT-LINE FROM WS-ERR-HEADER AFTER ADVANCING PAGE
           WRITE ERR-PRINT-LINE FROM SPACES AFTER ADVANCING 2 LINES
           
           PERFORM 1100-READ-NEXT-TRANS.

       1100-READ-NEXT-TRANS.
           READ TRANS-IN-FILE
               AT END
                   SET TRANS-EOF TO TRUE
               NOT AT END
                   ADD 1 TO WS-REC-READ
           END-READ.

       2000-PROCESS-TRANSACTIONS.
      * -- FIRST VERIFY THE ACCOUNT EXISTS IN MASTER --
           MOVE TR-ACCT-NUM TO ACCT-NUM-KEY
           READ ACCT-MASTER-FILE
           
           IF ACCT-NOT-FOUND
               MOVE TR-ACCT-NUM TO ERR-ACCT
               MOVE TR-TRANS-CODE TO ERR-CODE
               MOVE 'ACCOUNT NOT FOUND IN MASTER DB' TO ERR-MSG
               PERFORM 8000-WRITE-ERROR
           ELSE
               IF ACCT-STATUS = 'C' OR ACCT-STATUS = 'F'
                   MOVE TR-ACCT-NUM TO ERR-ACCT
                   MOVE TR-TRANS-CODE TO ERR-CODE
                   MOVE 'ACCOUNT CLOSED OR FROZEN - TRANS REJECTED' 
                     TO ERR-MSG
                   PERFORM 8000-WRITE-ERROR
               ELSE
                   PERFORM 2100-APPLY-TRANSACTION
               END-IF
           END-IF
           
           PERFORM 1100-READ-NEXT-TRANS.

       2100-APPLY-TRANSACTION.
      * -- SPAGHETTI EVALUATE BLOCK FOR RAG AGENT TO EXPLAIN --
           MOVE ACCT-BALANCE TO WS-TEMP-BAL
           
           EVALUATE TR-TRANS-CODE
               WHEN 'DEP'
               WHEN 'CRD'
                   COMPUTE WS-TEMP-BAL = WS-TEMP-BAL + TR-TRANS-AMT
                   ADD TR-TRANS-AMT TO WS-TOT-DEPOSITS
                   PERFORM 4000-WRITE-GL-CREDIT
                   
               WHEN 'WTH'
               WHEN 'CHQ'
               WHEN 'DBT'
                   IF (WS-TEMP-BAL - TR-TRANS-AMT) < ACCT-OVERDRAFT-LMT
                       MOVE TR-ACCT-NUM TO ERR-ACCT
                       MOVE TR-TRANS-CODE TO ERR-CODE
                       MOVE 'INSUFFICIENT FUNDS - EXCEEDS OD LIMIT' 
                         TO ERR-MSG
                       PERFORM 8000-WRITE-ERROR
                   ELSE
                       COMPUTE WS-TEMP-BAL = WS-TEMP-BAL - TR-TRANS-AMT
                       ADD TR-TRANS-AMT TO WS-TOT-WITHDRAWS
                       PERFORM 4100-WRITE-GL-DEBIT
                       
                       IF WS-TEMP-BAL < 0
                           PERFORM 2200-ASSESS-OVERDRAFT-FEE
                       END-IF
                   END-IF
                   
               WHEN 'FEE'
                   COMPUTE WS-TEMP-BAL = WS-TEMP-BAL - TR-TRANS-AMT
                   ADD TR-TRANS-AMT TO ACCT-FEES-YTD
                   ADD TR-TRANS-AMT TO WS-TOT-FEES
                   PERFORM 4100-WRITE-GL-DEBIT
                   
               WHEN 'WIR'
                   COMPUTE WS-TEMP-BAL = WS-TEMP-BAL - TR-TRANS-AMT
                   COMPUTE WS-TEMP-BAL = WS-TEMP-BAL - WS-WIRE-FEE
                   ADD WS-WIRE-FEE TO ACCT-FEES-YTD
                   ADD WS-WIRE-FEE TO WS-TOT-FEES
                   ADD TR-TRANS-AMT TO WS-TOT-WITHDRAWS
                   PERFORM 4100-WRITE-GL-DEBIT
                   
               WHEN OTHER
                   MOVE TR-ACCT-NUM TO ERR-ACCT
                   MOVE TR-TRANS-CODE TO ERR-CODE
                   MOVE 'INVALID TRANSACTION CODE' TO ERR-MSG
                   PERFORM 8000-WRITE-ERROR
           END-EVALUATE.

      * -- UPDATE MASTER RECORD --
           IF WS-ERR-FS = '00' OR WS-ERR-FS = SPACES
               MOVE WS-TEMP-BAL TO ACCT-BALANCE
               MOVE WS-CURR-DATE-NUM TO ACCT-LAST-ACT-DATE
               REWRITE ACCT-REC
               ADD 1 TO WS-REC-PROCESSED
           END-IF.

       2200-ASSESS-OVERDRAFT-FEE.
           COMPUTE WS-OVERDRAFT-AMT = WS-TEMP-BAL * -1
           MOVE WS-OD-FEE-BASE TO WS-FEE-CALC
           
           IF WS-OVERDRAFT-AMT > 1000.00
               COMPUTE WS-FEE-CALC = WS-FEE-CALC + 15.00
           END-IF
           
           COMPUTE WS-TEMP-BAL = WS-TEMP-BAL - WS-FEE-CALC
           ADD WS-FEE-CALC TO ACCT-FEES-YTD
           ADD WS-FEE-CALC TO WS-TOT-FEES
           
           MOVE TR-ACCT-NUM TO ERR-ACCT
           MOVE 'ODF' TO ERR-CODE
           MOVE 'OVERDRAFT FEE ASSESSED TO ACCOUNT' TO ERR-MSG
           PERFORM 8000-WRITE-ERROR.

       4000-WRITE-GL-CREDIT.
           MOVE 'GL-100-CAS' TO GL-ACCOUNT-CODE
           MOVE 'C' TO GL-DR-CR-IND
           MOVE TR-TRANS-AMT TO GL-AMOUNT
           MOVE WS-CURR-DATE-NUM TO GL-POSTING-DATE
           MOVE TR-NARRATIVE TO GL-REFERENCE
           WRITE GL-REC
           ADD 1 TO WS-GL-RECORDS.

       4100-WRITE-GL-DEBIT.
           MOVE 'GL-200-LIA' TO GL-ACCOUNT-CODE
           MOVE 'D' TO GL-DR-CR-IND
           MOVE TR-TRANS-AMT TO GL-AMOUNT
           MOVE WS-CURR-DATE-NUM TO GL-POSTING-DATE
           MOVE TR-NARRATIVE TO GL-REFERENCE
           WRITE GL-REC
           ADD 1 TO WS-GL-RECORDS.

       8000-WRITE-ERROR.
           WRITE ERR-PRINT-LINE FROM WS-ERR-DETAIL AFTER ADVANCING 1 LINE
           ADD 1 TO WS-REC-ERRORS
           MOVE SPACES TO WS-ERR-DETAIL.

       3000-FINALIZATION.
      * -- SIMULATED CICS/DB2 LOGIC FOR DEPENDENCY RAG TESTING --
           EXEC SQL
               UPDATE BRANCH_METRICS
               SET DAILY_VOL = :WS-REC-PROCESSED
               WHERE REGION = 'NORTH_AMERICA'
           END-EXEC.
           
           DISPLAY '*** CORBAT01 COMPLETED ***'
           DISPLAY 'RECORDS READ:      ' WS-REC-READ
           DISPLAY 'RECORDS PROCESSED: ' WS-REC-PROCESSED
           DISPLAY 'ERRORS ENCOUNTERED:' WS-REC-ERRORS
           DISPLAY 'GL EXTRACTS WRITTEN:' WS-GL-RECORDS
           DISPLAY 'TOTAL DEPOSITS:    ' WS-TOT-DEPOSITS
           DISPLAY 'TOTAL WITHDRAWALS: ' WS-TOT-WITHDRAWS
           
           CLOSE TRANS-IN-FILE
                 ACCT-MASTER-FILE
                 GL-EXTRACT-FILE
                 ERROR-REPORT.

       9999-ABEND.
           DISPLAY '*** PROGRAM ABORTED DUE TO FATAL ERROR ***'
           CALL 'CEE3ABD' USING 1, 0.