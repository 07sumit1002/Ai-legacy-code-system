       IDENTIFICATION DIVISION.
       PROGRAM-ID. INVENTORY-MGMT.
       AUTHOR. LEGACY-IT.
       
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT INVENTORY-FILE ASSIGN TO "INV-MASTER.DAT"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS ITEM-ID.
               
       DATA DIVISION.
       FILE SECTION.
       FD  INVENTORY-FILE.
       01  INVENTORY-RECORD.
           05  ITEM-ID         PIC X(10).
           05  ITEM-DESC       PIC X(40).
           05  QOH             PIC 9(5).
           05  REORDER-LEVEL   PIC 9(5).
           05  UNIT-PRICE      PIC 9(5)V99.
           
       WORKING-STORAGE SECTION.
       01  WS-STATUS           PIC XX.
       01  WS-SEARCH-ID        PIC X(10).
       
       PROCEDURE DIVISION.
       0000-START.
           OPEN I-O INVENTORY-FILE
           DISPLAY "ENTER ITEM ID TO SEARCH/UPDATE: "
           ACCEPT WS-SEARCH-ID
           
           MOVE WS-SEARCH-ID TO ITEM-ID
           READ INVENTORY-FILE
               INVALID KEY
                   DISPLAY "ITEM NOT FOUND. ADDING NEW ITEM..."
                   MOVE "NEW ITEM" TO ITEM-DESC
                   MOVE 100 TO QOH
                   MOVE 20 TO REORDER-LEVEL
                   MOVE 9.99 TO UNIT-PRICE
                   WRITE INVENTORY-RECORD
                       INVALID KEY DISPLAY "ERROR ADDING"
                   END-WRITE
               NOT INVALID KEY
                   DISPLAY "ITEM FOUND. CHECKING STOCK..."
                   IF QOH < REORDER-LEVEL
                       DISPLAY "WARNING: LOW STOCK. REORDER REQUIRED."
                       COMPUTE QOH = QOH + 50
                       REWRITE INVENTORY-RECORD
                   ELSE
                       DISPLAY "STOCK LEVEL OK."
                   END-IF
           END-READ
           
           CLOSE INVENTORY-FILE
           STOP RUN.
