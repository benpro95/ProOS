*> GNU COBOL -- Scan color table for matching color value then convert
*> to 512x6 hex bytes, open pixel control format for opc_client (C program) 
*> 
IDENTIFICATION DIVISION.
PROGRAM-ID.      COLOR-SCAN.

ENVIRONMENT DIVISION.
CONFIGURATION SECTION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
   SELECT TABLE-IN ASSIGN TO "/opt/rpi/effects/colours.txt"
          ORGANIZATION IS LINE SEQUENTIAL.

DATA DIVISION.
FILE SECTION.

FD  TABLE-IN.
  01  TBL-RECS.
      05  TBLFILE-RED          PIC X(03).
      05  FILLER               PIC X(01).
      05  TBLFILE-GREEN        PIC X(03).
      05  FILLER               PIC X(01).
      05  TBLFILE-BLUE         PIC X(03).
      05  FILLER               PIC X(01).
      05  TBLFILE-COLOR        PIC X(25).

WORKING-STORAGE SECTION.

  01  COLOR-TABLE-MAIN.
      05  COLOR-TABLE OCCURS 1000 TIMES INDEXED BY TBL-IDX.
         10  TBL-RED              PIC X(03).
         10  TBL-GREEN            PIC X(03).
         10  TBL-BLUE             PIC X(03).
         10  TBL-COLOR            PIC X(25).

  01  OPC-TABLE-MAIN.
      05  OPC-TABLE OCCURS 512 TIMES INDEXED BY OPC-IDX.
         10  TBL-OPC-BLANK        PIC X(01).
         10  TBL-OPC-HEX          PIC X(06).

  01  STORAGE.
       05  WS-COLOR-COUNT         PIC 9(01).
       05  WS-HEX-RGB             PIC X(06).
       05  WS-COLOR               PIC X(25).
       05  WS-RED                 PIC 9(03).
       05  WS-GREEN               PIC 9(03).
       05  WS-BLUE                PIC 9(03).

  01  HEX-CONV.
       05  NUMERIC-VALUE          COMP PIC 9(18).
       05  ALPHA-VALUE            PIC X(64).
       05  RADIX                  COMP PIC 99.
       05  DIGIT-INDEX            COMP PIC 99.
       05  DIGIT-VALUE            COMP PIC 99.
       05  CHAR-VALUE             PIC X(16) VALUE "0123456789ABCDEF".
       05  HEX-OUT                PIC X(02).

  01  FLAGS.
       05  TABLE-EOF              PIC X(01) VALUE 'N'.
         88  TABLE-EOF-YES        VALUE 'Y'.
         88  TABLE-EOF-NO         VALUE 'N'.

PROCEDURE DIVISION.

0010-MAIN.
   PERFORM 0020-OPEN-FILES.
   PERFORM 1000-LOAD-TABLE THRU 1000-EXIT
      VARYING TBL-IDX FROM 1 BY 1 UNTIL TABLE-EOF-YES.
   PERFORM 2000-PROCESS THRU 2000-EXIT.
   PERFORM 5000-CLOSE THRU 5000-EXIT.
   GOBACK.
0010-EXIT.
    EXIT.

0020-OPEN-FILES.
   OPEN INPUT
      TABLE-IN.
0020-EXIT.
    EXIT.

1000-LOAD-TABLE.
   READ TABLE-IN AT END MOVE 'Y' TO TABLE-EOF.
   IF TABLE-EOF-NO
      MOVE TBLFILE-RED TO TBL-RED (TBL-IDX)
      MOVE TBLFILE-GREEN TO TBL-GREEN (TBL-IDX)
      MOVE TBLFILE-BLUE TO TBL-BLUE (TBL-IDX)
      MOVE TBLFILE-COLOR TO TBL-COLOR (TBL-IDX)
   END-IF.
1000-EXIT.
    EXIT.

2000-PROCESS.
    ACCEPT WS-COLOR FROM COMMAND-LINE
    PERFORM 2100-SEARCH-TABLE THRU 2100-EXIT.
    MOVE 1 TO WS-COLOR-COUNT
    PERFORM 2400-RGB-TO-HEX THRU 2400-EXIT
      UNTIL WS-COLOR-COUNT > 3
    PERFORM 2200-LOAD-OPC THRU 2200-EXIT
      VARYING OPC-IDX FROM 1 BY 1 UNTIL OPC-IDX > 512
    DISPLAY '0' OPC-TABLE-MAIN
    MOVE SPACES TO WS-COLOR.
2000-EXIT.
    EXIT.

2100-SEARCH-TABLE.
    SET TBL-IDX TO +1
    SEARCH COLOR-TABLE
      AT END
        MOVE ZEROS TO WS-RED
        MOVE ZEROS TO WS-GREEN
        MOVE ZEROS TO WS-BLUE
      WHEN TBL-COLOR (TBL-IDX) = WS-COLOR
        MOVE TBL-RED (TBL-IDX) TO WS-RED
        MOVE TBL-GREEN (TBL-IDX) TO WS-GREEN
        MOVE TBL-BLUE (TBL-IDX) TO WS-BLUE
      END-SEARCH.
2100-EXIT.
    EXIT.

2200-LOAD-OPC.
    MOVE WS-HEX-RGB TO TBL-OPC-HEX (OPC-IDX)
    MOVE SPACES TO TBL-OPC-BLANK (OPC-IDX).
2200-EXIT.
    EXIT.

2300-HEX-CONV.
    DIVIDE NUMERIC-VALUE BY RADIX
      GIVING NUMERIC-VALUE
        REMAINDER DIGIT-VALUE
    ADD 1 TO DIGIT-VALUE
    MOVE CHAR-VALUE (DIGIT-VALUE:1)
      TO ALPHA-VALUE (DIGIT-INDEX:1).
2300-EXIT.
    EXIT.

2400-RGB-TO-HEX.
    IF WS-COLOR-COUNT EQUAL 1
      MOVE WS-RED TO NUMERIC-VALUE
    END-IF 
    IF WS-COLOR-COUNT EQUAL 2
      MOVE WS-GREEN TO NUMERIC-VALUE
    END-IF 
    IF WS-COLOR-COUNT EQUAL 3
      MOVE WS-BLUE TO NUMERIC-VALUE
    END-IF
    MOVE 16 TO RADIX
    MOVE ALL "0" TO ALPHA-VALUE
    PERFORM 2300-HEX-CONV THRU 2300-EXIT
      VARYING DIGIT-INDEX FROM 1 BY 1
         UNTIL DIGIT-INDEX > 64 OR NUMERIC-VALUE = 0
    MOVE FUNCTION REVERSE (ALPHA-VALUE (1:2))
      TO HEX-OUT
    IF WS-COLOR-COUNT EQUAL 1
      MOVE HEX-OUT TO WS-HEX-RGB(1:2)
    END-IF 
    IF WS-COLOR-COUNT EQUAL 2
      MOVE HEX-OUT TO WS-HEX-RGB(3:2)
    END-IF 
    IF WS-COLOR-COUNT EQUAL 3
      MOVE HEX-OUT TO WS-HEX-RGB(5:2)
    END-IF
    ADD 1 TO WS-COLOR-COUNT.
2400-EXIT.
    EXIT.

5000-CLOSE.
    CLOSE
      TABLE-IN.
5000-EXIT.
    EXIT.