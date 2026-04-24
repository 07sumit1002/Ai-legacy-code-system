       IDENTIFICATION DIVISION.
       PROGRAM-ID. PAYROLL-SYSTEM.
       AUTHOR. LEGACY-IT.
       
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT EMPLOYEE-FILE ASSIGN TO "EMP-DATA.DAT"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT REPORT-FILE ASSIGN TO "PAYROLL-REPORT.TXT"
               ORGANIZATION IS LINE SEQUENTIAL.
               
       DATA DIVISION.
       FILE SECTION.
       FD  EMPLOYEE-FILE.
       01  EMPLOYEE-RECORD.
           05  EMP-ID          PIC 9(5).
           05  EMP-NAME        PIC X(30).
           05  HOURS-WORKED    PIC 9(3)V99.
           05  HOURLY-RATE     PIC 9(3)V99.
           
       FD  REPORT-FILE.
       01  REPORT-RECORD       PIC X(80).
       
       WORKING-STORAGE SECTION.
       01  WS-EOF-FLAG         PIC X VALUE 'N'.
       01  WS-GROSS-PAY        PIC 9(5)V99 VALUE 0.
       01  WS-TAX-AMOUNT       PIC 9(4)V99 VALUE 0.
       01  WS-NET-PAY          PIC 9(5)V99 VALUE 0.
       01  WS-TAX-RATE         PIC V99 VALUE .15.
       
       PROCEDURE DIVISION.
       0000-MAIN-LOGIC.
           OPEN INPUT EMPLOYEE-FILE
           OPEN OUTPUT REPORT-FILE
           
           PERFORM 1000-PROCESS-RECORDS UNTIL WS-EOF-FLAG = 'Y'
           
           CLOSE EMPLOYEE-FILE
           CLOSE REPORT-FILE
           STOP RUN.
           
       1000-PROCESS-RECORDS.
           READ EMPLOYEE-FILE
               AT END
                   MOVE 'Y' TO WS-EOF-FLAG
               NOT AT END
                   COMPUTE WS-GROSS-PAY = HOURS-WORKED * HOURLY-RATE
                   COMPUTE WS-TAX-AMOUNT = WS-GROSS-PAY * WS-TAX-RATE
                   COMPUTE WS-NET-PAY = WS-GROSS-PAY - WS-TAX-AMOUNT
                   PERFORM 2000-WRITE-REPORT
           END-READ.
           
       2000-WRITE-REPORT.
           STRING "ID: " EMP-ID " NAME: " EMP-NAME 
                  " NET PAY: $" WS-NET-PAY
               DELIMITED BY SIZE INTO REPORT-RECORD
           WRITE REPORT-RECORD.
