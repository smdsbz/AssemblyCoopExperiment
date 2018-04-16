.386
STACK   SEGMENT USE16 STACK
        DB 200 DUP(0)
STACK   ENDS
DATA    SEGMENT USE16 PUBLIC 'entry'
        ; -------- UI --------
        UI_SEPARATOR    DB '--------------------------------------------------------------------', 0DH, 0AH, '$'
        UI_WELCOME      DB 'Welcome!', 0DH, 0AH, '$'
        UI_USERNAME     DB 'Please input your usermane:', 0DH, 0AH, '$'
        UI_PASSWD       DB 'Please input your password', 0DH, 0AH, '$'
        UI_LOGIN_ERROR  DB 'Username or password incorrect, please input again!', 0DH, 0AH, '$'
        UI_CRLF         DB 0DH, 0AH, '$'
            ; --------- MENU ---------
        UI_MENU         DB '1. Get product info      2. Edit product info       3. Sum average profit rate', 0DH, 0AH,
                           '4. Sum profit rate rank  5. Print all product info  6. Exit', 0DH, 0AH, '$'
        UI_MENU_INPUT   DB 'Please input your selection[1-6]:', 0DH, 0AH, '$'
        UI_INPUT_ERROR  DB 'Wrong input number, please input again!', 0DH, 0AH, '$'

        UI_INPUT_PRO    DB 'Please input product name:', 0AH, 0DH, '$'

        INPUT_BUF       DB 100
        INPUT_COUNT     DB 0
        INPUT_CONTENT   DB 100 DUP(0)

        ; -------- USER DATA ---------
        USERNAME        DB 'smdshunto$'
        PASSWD          DB 'password$'

        ; -------- Shop DATA ---------
        N EQU 3
        S1 DB 'SHOP1',0
        	GA1 DB 'PEN$',6 DUP(0)
        		DW 35,56,70,25,1
        	; PRODUCT_LEN EQU $-GA1
        	GA2 DB 'BOOK$',5 DUP(0)
        		DW 12,30,25,5,?
        	GAN DB N-2 DUP('TEMP-VALUE',15,0,20,0,30,0,2,0,?,?)
        CRLF DB 0AH,0DH,'$'
        S2 DB 'SHOP2',0
        	GB1 DB 'BOOK$',5 DUP(0)
        		DW 12,28,20,15,?
        	GB2 DB 'PEN$',6 DUP(0)
        		DW 35,50,30,24,?
        	GBN DB N-2 DUP('TEMP-VALUE',15,0,20,0,30,0,2,0,?,?)
        ; -------- Global --------
        AUTH            DB 0

DATA    ENDS

CODE    SEGMENT USE16
        ASSUME  CS:CODE, DS:DATA, SS:STACK

PRINT   PROC FAR STDCALL USES EAX EDX STROFFSET:WORD
        ; simple print function
        ; Args:
        ;       STROFFSET       - [WORD] eff-addr of source string
        ; Return:
        ;       (None)
        ; PUSH    EAX
        ; PUSH    EDX
        MOV     DX, STROFFSET
        MOV     AH, 9
        INT     21H
        ; POP     EDX
        ; POP     EAX
        RET
PRINT   ENDP



PRINT_INT32     PROC FAR STDCALL USES EAX EBX ECX EDX NUM:DWORD
        ; convert Int32 to printable
        ; Args:
        ;       NUM             - [DWORD] Int32 to print
        ; Return:
        ;       (None)
        MOV     EBX, 0
        MOV     EAX, NUM
        ; negative sign?
        ; AND     EAX, 80000000H
        .IF     (EAX & 80000000H)
        ; output negative sign
        MOV     DL, '-'
        MOV     AH, 2
        INT     21H
        MOV     EAX, NUM
        NEG     EAX             ; (eax) = abs(eax)
        .ENDIF
        ; convert loop
        MOV     ECX, 10         ; divider
        .WHILE  (EAX != 0)
        CDQ
        IDIV    ECX
        ; output remainder, in EDX
        ADD     EDX, 30H        ; to ASCII
        PUSH    EDX
        INC     EBX
        .ENDW
        ; output loop
        .WHILE  (EBX != 0)
        POP     EDX             ; start from highest digit
        MOV     AH, 2
        INT     21H
        DEC     EBX
        .ENDW
        RET
PRINT_INT32     ENDP



STR_CMP    PROC FAR STDCALL USES BX CX DI SI STR1_OFFSET:WORD, STR2_OFFSET:WORD
        ; cmp str
        MOV BX, 0
        MOV CH, 0
        MOV CL, 0
        MOV DI, STR1_OFFSET
        MOV SI, STR2_OFFSET
        .WHILE (CH != '$') && (CL != '$')
        MOV CH, [DI + BX]
        MOV CL, [SI + BX]
        INC BX
        .IF CH != CL
        MOV AX, 0
        RET
        .ENDIF
        .ENDW
        MOV AX, 1
        RET
STR_CMP ENDP



INPUT   PROC FAR STDCALL USES EAX EDX EDI BUFOFFSET:WORD
        ; simple input function
        ; Args:
        ;       BUFOFFSET       - [WORD] target buffer block
        ; Return:
        ;       (None)
        MOV     DX, BUFOFFSET
        MOV     AH, 10
        INT     21H
        MOVZX   EDX, BUFOFFSET
        INC     EDX
        MOV     AL, BYTE PTR [EDX]
        AND     EAX, 0FFH
        INC     EDX
        MOV     BYTE PTR [EDX][EAX], '$'
        RET
INPUT   ENDP



CALC_PROFIT     PROC FAR STDCALL USES EAX EBX ECX EDX GAOFF:WORD, GBOFF:WORD, NSIZE:WORD, SSIZE:WORD
        MOV     EBX, 0
        ; .WHILE  (EBX != N)
        .REPEAT
        PUSH    EBX                             ; save loop count
        MOV     ECX, EBX
        IMUL    ECX, SSIZE
        ; LEA     ECX, GAOFF[10]
        MOV     CX, GAOFF
        ADD     CX, NSIZE
        MOVZX   EAX, WORD PTR [ECX][1*2]
        IMUL    EAX, 100
        IMUL    WORD PTR [ECX][3*2]
        MOVZX   EBX, WORD PTR [ECX][0*2]
        IMUL    EBX, WORD PTR [ECX][2*2]
        CMP     EBX, 0
        JE      ZDIV1
        DIV     BX
        SUB     AX, 100
        MOV     WORD PTR [ECX][4*2], AX
        SUB     CX, GAOFF
        ADD     CX, GBOFF
        MOVZX   EAX, WORD PTR [ECX][1*2]
        IMUL    EAX, 100
        IMUL    WORD PTR [ECX][3*2]
        MOVZX   EBX, WORD PTR [ECX][0*2]
        IMUL    EBX, WORD PTR [ECX][2*2]
        CMP     EBX, 0
        JE      ZDIV1
        DIV     BX
        SUB     AX, 100
        MOV     WORD PTR [ECX][4*2], AX
        ; calculate avg p-r, store to AX
        SUB     CX, GBOFF
        ADD     CX, GAOFF
        ADD     AX, WORD PTR [ECX][4*2]
        SAR     AX, 1
        ; finished calculation
        MOV     WORD PTR [ECX][4*2], AX
        POP     EBX                             ; restore loop count
        INC     EBX
        ; .ENDW
        .UNTIL  (EBX == N)
        RET
ZDIV1:  ; zero-divison encountered calc-ing p-r, set both p-rs and avg p-r to 0!
        MOV     AX, 0
        MOV     WORD PTR [ECX][4*2], AX
ZDIV2:  MOV     AX, 0
        MOV     WORD PTR [ECX][4*2], AX
        JMP     E_BOSSJ
E_BOSSJ:; ending of BOSSJ
        JMP     EXJOB
EXJOB:  ; reset AUTH, get back to START
        MOV     AL, 0                   ; reset AUTH to 0
        MOV     AUTH, AL
        RET
CALC_PROFIT     ENDP



STR2INT32       PROC FAR STDCALL USES EBX ECX EDX EDI STROFFSET:WORD
        MOV     EAX, 0
        MOVZX   EBX, STROFFSET
        MOV     ECX, 10                         ; NOTE: default base is 10
        MOV     EDX, 30H
        .IF     (BYTE PTR [EBX] == '-')         ; skip negative sign
        INC     EBX
        .ELSEIF (BYTE PTR [EBX] == '$')
        MOV     EAX, 0
        RET
        .ENDIF
        ; convert to Int32
        .REPEAT
        MUL     ECX
        MOVZX   EDX, BYTE PTR [EBX]
        SUB     EDX, 30H
        ADD     EAX, EDX
        INC     EBX
        .UNTIL  (BYTE PTR [EBX] == '$')
        ; signed?
        MOVZX   EBX, STROFFSET
        .IF     (BYTE PTR [EBX] == '-')
        NEG     EAX
        .ENDIF
        RET
STR2INT32       ENDP




START:
        MOV     AX, DATA
        MOV     DS, AX

        ; INVOKE  PRINT, OFFSET UI_WELCOME
        ; INVOKE  PRINT_INT32, -123
        ; INVOKE  PRINT, OFFSET UI_CRLF
        ; INVOKE  PRINT_INT32, 1234
        ; INVOKE  PRINT, OFFSET UI_CRLF
        ; INVOKE  CALC_PROFIT, ADDR GA1, ADDR GA2, 10, 20
        ; MOVSX   EAX, WORD PTR GA1[18]
        ; INVOKE  PRINT_INT32, EAX

        INVOKE  INPUT, ADDR INPUT_BUF
        INVOKE  PRINT, ADDR UI_CRLF
        INVOKE  STR2INT32, ADDR INPUT_CONTENT
        INVOKE  PRINT_INT32, EAX
        INVOKE  PRINT, ADDR UI_CRLF


        MOV     AH, 4CH
        INT     21H

CODE    ENDS
        END     START
