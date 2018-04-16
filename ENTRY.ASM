.386
STACK   SEGMENT USE16 STACK
        DB 200 DUP(0)
STACK   ENDS
DATA    SEGMENT USE16 PUBLIC 'entry'
        ; -------- UI --------
        UI_SEPARATOR    DB '-------------------------------------------------------------------------------', 0DH, 0AH, '$'
        UI_WELCOME      DB 'Welcome!', 0DH, 0AH, '$'
        UI_USERNAME     DB 'Please input your usermane:', 0DH, 0AH, '$'
        UI_PASSWD       DB 'Please input your password', 0DH, 0AH, '$'
        UI_LOGIN_ERROR  DB 'Username or password incorrect, please input again!', 0DH, 0AH, '$'
        UI_CRLF         DB 0DH, 0AH, '$'
            ; --------- MENU ---------
        UI_MENU         DB '1. Get product info      2. Edit product info       3. Sum average profit rate', 0DH, 0AH,
                           '4. Sum profit rate rank  5. Print all product info  6. Exit', 0DH, 0AH, '$'
        UI_MENU_UNLOGIN DB '1. Get product info      2. Exit', 0DH, 0AH, '$'
        UI_MENU_INPUT   DB 'Please input your selection[1-6]:', 0DH, 0AH, '$'
        UI_MENU_INPUT2  DB 'Please input your selection[1-2]:', 0DH, 0AH, '$'
        UI_INPUT_ERROR  DB 'Wrong input number, please input again!', 0DH, 0AH, '$'
        UI_INPUT_PRO    DB 'Please input product name:', 0AH, 0DH, '$'
        UI_PRO_NOTFOUND DB 'Product not found!', 0AH, 0DH, '$'

        UI_SHOP1        DB 'SHOP1$'
        UI_SHOP2        DB 'SHOP2$'

        ; ---------- INPUT BUF -----------
        INPUT_BUF       DB 100
        INPUT_COUNT     DB 0
        INPUT_CONTENT   DB 100 DUP(0)

        ; -------- USER DATA ---------
        USERNAME        DB 'smdshunto$'
        PASSWD          DB 'password$'

        ; -------- Shop DATA ---------
        N EQU 4
        S1 DB 'SHOP1',0
        GA1 DB 'PEN$',6 DUP(0)
        	DW 35,56,70,25,?
        GA2 DB 'BOOK$',5 DUP(0)
        	DW 12,30,25,5,?
        GAN DB N-2 DUP('TEMPVALUE$',15,0,20,0,30,0,2,0,?,?)
        S2 DB 'SHOP2',0
        GB1 DB 'BOOK$',5 DUP(0)
        	DW 12,28,20,15,?
        GB2 DB 'PEN$',6 DUP(0)
        	DW 35,50,30,24,?
        GBN DB N-2 DUP('TEMPVALUE$',15,0,20,0,30,0,2,0,?,?)
        ; -------- Global --------
        AUTH DB 0

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
        .IF     (EAX == 0)              ; zero checking
        MOV     DL, '0'
        MOV     AH, 2
        INT     21H
        RET
        .ENDIF
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

PRINT_SEP PROC FAR STDCALL USES AX DX SEP:BYTE
        ; print separator
        ; Args:
        ;    SEP: separator char
        ; Return: None
        MOV     DL, SEP
        MOV     AH, 2
        INT     21H
        RET
PRINT_SEP ENDP

STR_CMP    PROC FAR STDCALL USES BX CX DI SI STR1_OFFSET:WORD, STR2_OFFSET:WORD
        ; compare str
        ; Args:
        ;    STR1_OFFSET: str1 address
        ;    STR2_OFFSET: str2 address
        ; Return: MOV AX,1 if same else MOV AX,0
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

STR2INT32       PROC FAR STDCALL USES EBX ECX EDX EDI STROFFSET:WORD
        ; str2int32
        ; Args:
        ;    SEP: separator char
        ; Return: None
        MOV     EAX, 0
        MOVZX   EBX, STROFFSET
        MOV     ECX, 10                         ; NOTE: default base is 10
        MOV     EDX, 30H
        .IF     (BYTE PTR [EBX] == '-')         ; skip negative sign
        INC     EBX
        .ELSEIF (BYTE PTR [EBX] == '$')
        MOV     EAX, -1
        RET
        .ELSEIF (BYTE PTR [EBX] < '0' || BYTE PTR [EBX] > '9')
        MOV     EAX, -1
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


; ------------ MENU_FUNC ------------
GET_PRO PROC FAR STDCALL USES AX BX SHOPA:WORD, SHOPB:WORD, PRO:WORD
        MOV BX, 0
        MOV DI, SHOPA
        MOV SI, SHOPB
        ADD DI, 6
        ADD SI, 6

        ; SHOPA
        .WHILE BX < 60
        INVOKE STR_CMP, DI, PRO
        .IF AX
        JMP SHOPB_
        .ENDIF
        ADD BX, 20
        ADD DI, BX
        .ENDW
        MOV DI, 0
        SHOPB_:
        ; SHOPB
        MOV BX, 0
        .WHILE BX < 600
        INVOKE STR_CMP, SI, PRO
        .IF AX
        RET
        .ENDIF
        ADD BX, 20
        ADD SI, BX
        .ENDW

        MOV SI, 0
        RET
GET_PRO ENDP


PRINT_PRO PROC FAR STDCALL USES EAX SI PRO:WORD, UI_SHOP:WORD, CRLF:WORD, PRINT_PROFIT:BYTE
        INVOKE PRINT, UI_SHOP
        INVOKE PRINT_SEP, ','
        INVOKE PRINT, PRO
        INVOKE PRINT_SEP, ','
        MOV SI, PRO
        ADD SI, 10
        MOVSX EAX, WORD PTR [SI]
        INVOKE PRINT_INT32, EAX
        INVOKE PRINT_SEP, ','
        ADD SI, 2
        MOVSX EAX, WORD PTR [SI]
        INVOKE PRINT_INT32, EAX
        INVOKE PRINT_SEP, ','
        ADD SI, 2
        MOVSX EAX, WORD PTR [SI]
        INVOKE PRINT_INT32, EAX
        INVOKE PRINT_SEP, ','
        ADD SI, 2
        MOVSX EAX, WORD PTR [SI]
        INVOKE PRINT_INT32, EAX
        .IF PRINT_PROFIT
        INVOKE PRINT_SEP, ','
        ADD SI, 2
        MOVSX EAX, WORD PTR [SI]
        INVOKE PRINT_INT32, EAX
        .ENDIF
        INVOKE PRINT, CRLF
        RET
PRINT_PRO ENDP

RANK_ITEM       PROC FAR STDCALL USES EAX EBX ECX EDX EDI ESI SHOP1OFF:WORD, SHOP2OFF:WORD, SNAMESIZE:WORD, NSIZE:WORD, SSIZE:WORD
        ; zero pr field in SHOP2
        ; get first item in SHOP1
        MOVZX   EBX, SHOP2OFF
        MOVZX   EAX, SNAMESIZE
        ADD     EBX, EAX
        ; zero pr field in SHOP2
        ; -- get border ==> (EDX)
        MOVZX   EDX, SHOP2OFF
        MOVZX   EAX, SHOP1OFF
        SUB     EDX, EAX
        MOVZX   EAX, SHOP2OFF
        ADD     EDX, EAX
        ; set default ranking of all to 1
        .REPEAT
        MOV     WORD PTR [EBX][18], 1
        MOVZX   EAX, SSIZE
        ADD     EBX, EAX
        .UNTIL  (EBX >= EDX)

        ; re-get first item in SHOP1 ==> (EBX)
        MOVZX   EBX, SHOP1OFF
        MOVZX   EAX, SNAMESIZE
        ADD     EBX, EAX
        ; re-get border for SHOP1 ==> (EDX)
        MOVZX   EDX, SHOP2OFF
        ; MOVZX   EAX, SHOP1OFF
        ; SUB     EDX, EAX
        ; MOVZX   EAX, SHOP1OFF
        ; ADD     EDX, EAX
        .REPEAT
        ; ECX point to first item in SHOP1
        MOVZX   ECX, SHOP1OFF
        MOVZX   EAX, SNAMESIZE
        ADD     ECX, EAX
                ; stack ranking up
                .REPEAT
                MOV     AX, [EBX][18]
                .IF     (WORD PTR [ECX][18] > AX)
                ; goto SHOP2
                MOVZX   EAX, SHOP1OFF
                SUB     ECX, EAX
                MOVZX   EAX, SHOP2OFF
                ADD     ECX, EAX
                ; inc its ranking
                MOV     AX, [ECX][18]
                INC     AX
                MOV     [ECX][18], AX
                ; go back to SHOP1
                MOVZX   EAX, SHOP2OFF
                SUB     ECX, EAX
                MOVZX   EAX, SHOP1OFF
                ADD     ECX, EAX
                .ENDIF
                ; goto next item
                MOVZX   EAX, SSIZE
                ADD     ECX, EAX
                .UNTIL  (ECX >= EDX)
        ; goto next item
        MOVZX   EAX, SSIZE
        ADD     EBX, EAX
        .UNTIL  (EBX >= EDX)

        ; ; move ranks in SHOP2 to SHOP1
        ; ; get first item in SHOP1
        ; MOVZX   EBX, SHOP1OFF
        ; MOVZX   EAX, SNAMESIZE
        ; ADD     EBX, EAX
        ; ; -- get border ==> (EDX)
        ; MOVZX   EDX, SHOP2OFF
        ; ; MOVZX   EAX, SHOP1OFF
        ; ; SUB     EDX, EAX
        ; ; MOVZX   EAX, SHOP2OFF
        ; ; ADD     EDX, EAX
        ; .REPEAT
        ; ; goto SHOP2
        ; MOVZX   EAX, SHOP1OFF
        ; SUB     EBX, EAX
        ; MOVZX   EAX, SHOP2OFF
        ; ADD     EBX, EAX
        ; ; get ranking
        ; MOV     CX, [EBX][18]
        ; ; go back to SHOP1
        ; MOVZX   EAX, SHOP2OFF
        ; SUB     EBX, EAX
        ; MOVZX   EAX, SHOP1OFF
        ; ADD     EBX, EAX
        ; ; assignment
        ; MOV     [EBX][18], CX
        ; ; goto next item
        ; MOVZX   EAX, SSIZE
        ; ADD     EBX, EAX
        ; .UNTIL  (EBX >= EDX)

        RET
RANK_ITEM       ENDP


EDIT_PRO PROC FAR STDCALL USES EAX SI PRO:WORD, BUF:WORD, COUNT:WORD, CONTENT:WORD, CRLF:WORD
        MOV SI, PRO
        ADD SI, 10
        MOV EAX, 0
EDIT1:
        ; 进货价
        MOVSX EAX, WORD PTR [SI]
        INVOKE PRINT_INT32, EAX
        INVOKE PRINT_SEP, '>'
        INVOKE INPUT, BUF
        INVOKE PRINT, CRLF

        ; cmp input length
        MOV BX, COUNT
        MOV AH, BYTE PTR [BX]
        .IF !AH ; == 0
        ; input empty
        JMP EDIT2
        .ENDIF

        ; str2int
        INVOKE STR2INT32, CONTENT

        .IF EAX == -1
        ; input wrong
        INVOKE PRINT, OFFSET UI_INPUT_ERROR
        JMP EDIT1
        .ELSE
        MOV [SI], AX
        .ENDIF

EDIT2:
        ; 销售价
        ADD SI, 2
        MOVSX EAX, WORD PTR [SI]
        INVOKE PRINT_INT32, EAX
        INVOKE PRINT_SEP, '>'
        INVOKE INPUT, BUF
        INVOKE PRINT, CRLF

        ; cmp input length
        MOV BX, COUNT
        MOV AH, BYTE PTR [BX]
        .IF !AH ; == 0
        ; input empty
        JMP EDIT3
        .ENDIF

        ; str2int
        INVOKE STR2INT32, CONTENT

        .IF EAX == -1
        ; input wrong
        INVOKE PRINT, OFFSET UI_INPUT_ERROR
        ADD SI, -2
        JMP EDIT2
        .ELSE
        MOV [SI], AX
        .ENDIF

EDIT3:
        ; 进货数
        ADD SI, 2
        MOVSX EAX, WORD PTR [SI]
        INVOKE PRINT_INT32, EAX
        INVOKE PRINT_SEP, '>'
        INVOKE INPUT, BUF
        INVOKE PRINT, CRLF

        ; cmp input length
        MOV BX, COUNT
        MOV AH, BYTE PTR [BX]
        .IF !AH ; == 0
        ; input empty
        RET
        .ENDIF

        ; str2int
        INVOKE STR2INT32, CONTENT

        .IF EAX == -1
        ; input wrong
        INVOKE PRINT, OFFSET UI_INPUT_ERROR
        ADD SI, -2
        JMP EDIT3
        .ELSE
        MOV [SI], AX
        .ENDIF
        ; INVOKE PRINT, CRLF
        RET
EDIT_PRO ENDP


CALC_PROFIT     PROC FAR STDCALL USES EAX EBX ECX EDX GAOFF:WORD, GBOFF:WORD, NSIZE:WORD, SSIZE:WORD
        MOV     EBX, 0
        ; .WHILE  (EBX != N)
        .REPEAT
        PUSH    EBX                             ; save loop count
        MOV     ECX, EBX
        IMUL    ECX, SSIZE
        ; LEA     ECX, GAOFF[10]
        ADD     CX, GAOFF
        ADD     CX, NSIZE
        MOVZX   EAX, WORD PTR [ECX][1*2]
        IMUL    EAX, 100
        IMUL    WORD PTR [ECX][3*2]
        MOVZX   EBX, WORD PTR [ECX][0*2]
        IMUL    EBX, WORD PTR [ECX][2*2]
        .IF     (EBX == 0)                      ; zero div checking
        MOV     WORD PTR [ECX][4*2], 0
        INC     EBX
        .CONTINUE
        .ENDIF
        ; CMP     EBX, 0
        ; JE      ZDIV1
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
        .IF     (EBX == 0)                      ; zero div checking
        MOV     WORD PTR [ECX][4*2], 0
        INC     EBX
        .CONTINUE
        .ENDIF
        ; CMP     EBX, 0
        ; JE      ZDIV1
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
; ZDIV1:  ; zero-divison encountered calc-ing p-r, set both p-rs and avg p-r to 0!
;         MOV     AX, 0
;         MOV     WORD PTR [ECX][4*2], AX
; ZDIV2:  MOV     AX, 0
;         MOV     WORD PTR [ECX][4*2], AX
;         JMP     E_BOSSJ
; E_BOSSJ:; ending of BOSSJ
;         JMP     EXJOB
; EXJOB:  ; reset AUTH, get back to START
;         MOV     AL, 0                   ; reset AUTH to 0
;         MOV     AUTH, AL
;         RET
CALC_PROFIT     ENDP


START:
        MOV     AX, DATA
        MOV     DS, AX

        ; INVOKE  PRINT, OFFSET UI_WELCOME
        ; INVOKE  PRINT_INT32, -123
        ; INVOKE  PRINT, OFFSET UI_CRLF
        ; INVOKE  PRINT_INT32, 1234
        ; INVOKE  PRINT, OFFSET UI_CRLF

        ; print welcome
        INVOKE PRINT, OFFSET UI_WELCOME
        INVOKE PRINT, OFFSET UI_SEPARATOR

LOGIN:
        ; print 'please input username'
        INVOKE PRINT, OFFSET UI_USERNAME
        ; get username input
        INVOKE INPUT, OFFSET INPUT_BUF
        INVOKE PRINT, OFFSET UI_CRLF
        ; get input length & add '$' to tail
        MOV AL, INPUT_COUNT
            ; if 'q' -- quit
        .IF (AL == 1) && (INPUT_CONTENT[0] == 'q')
        JMP EXIT
            ; if input empty -- goto fun3
        .ELSEIF !AL ; == 0
        ; MOV AUTH, 0
        JMP MENU
        .ENDIF
        AND EAX, 0FFH
        ; cmp username
        INVOKE STR_CMP, OFFSET USERNAME, OFFSET INPUT_CONTENT
        .IF !AX  ; if usermane incorrect
        INVOKE PRINT, OFFSET UI_SEPARATOR
        INVOKE PRINT, OFFSET UI_LOGIN_ERROR
        INVOKE PRINT, OFFSET UI_SEPARATOR
        JMP LOGIN
        .ENDIF

        ; print 'please input password'
        INVOKE PRINT, OFFSET UI_PASSWD
        ; get password input
        INVOKE INPUT, OFFSET INPUT_BUF
        INVOKE PRINT, OFFSET UI_CRLF
        ; get input length & add '$' to tail
        MOV AL, INPUT_COUNT
        AND EAX, 0FFH
        ; cmp passowrd
        INVOKE STR_CMP, OFFSET PASSWD, OFFSET INPUT_CONTENT
        .IF !AX
        INVOKE PRINT, OFFSET UI_SEPARATOR
        INVOKE PRINT, OFFSET UI_LOGIN_ERROR
        INVOKE PRINT, OFFSET UI_SEPARATOR
        JMP LOGIN
        .ENDIF
        MOV AUTH, 1
        JMP MENU

MENU:
.IF AUTH
        ; print menu
        INVOKE PRINT, OFFSET UI_SEPARATOR
        INVOKE PRINT, OFFSET UI_MENU
        INVOKE PRINT, OFFSET UI_SEPARATOR
        ; print input hint
        INVOKE PRINT, OFFSET UI_MENU_INPUT
        ; get menu input
        INVOKE INPUT, OFFSET INPUT_BUF
        INVOKE PRINT, OFFSET UI_CRLF
        ; get input length
        MOV AL, INPUT_COUNT
        MOV AH, INPUT_CONTENT[0]

        .IF AL != 1
        ; input error
        INVOKE PRINT, OFFSET UI_SEPARATOR
        INVOKE PRINT, OFFSET UI_INPUT_ERROR
        INVOKE PRINT, OFFSET UI_SEPARATOR
        ; JMP MENU
        .ELSEIF AH == '1'
        JMP MENU_1
        .ELSEIF AH == '2'
        JMP MENU_2
        .ELSEIF AH == '3'
        JMP MENU_3
        .ELSEIF AH == '4'
        JMP MENU_4
        .ELSEIF AH == '5'
        JMP MENU_5
        .ELSEIF AH == '6'
        JMP EXIT
        .ELSE
        ; input error
        INVOKE PRINT, OFFSET UI_SEPARATOR
        INVOKE PRINT, OFFSET UI_INPUT_ERROR
        INVOKE PRINT, OFFSET UI_SEPARATOR
        .ENDIF
        JMP MENU
.ELSE
        ; print menu
        INVOKE PRINT, OFFSET UI_SEPARATOR
        INVOKE PRINT, OFFSET UI_MENU_UNLOGIN
        INVOKE PRINT, OFFSET UI_SEPARATOR
        ; print input hint
        INVOKE PRINT, OFFSET UI_MENU_INPUT2
        ; get menu input
        INVOKE INPUT, OFFSET INPUT_BUF
        INVOKE PRINT, OFFSET UI_CRLF
        ; get input length
        MOV AL, INPUT_COUNT
        MOV AH, INPUT_CONTENT[0]

        .IF AL != 1
        ; input error
        INVOKE PRINT, OFFSET UI_SEPARATOR
        INVOKE PRINT, OFFSET UI_INPUT_ERROR
        INVOKE PRINT, OFFSET UI_SEPARATOR
        ; JMP MENU
        .ELSEIF AH == '1'
        JMP MENU_1
        .ELSEIF AH == '2'
        JMP EXIT
        .ELSE
        ; input error
        INVOKE PRINT, OFFSET UI_SEPARATOR
        INVOKE PRINT, OFFSET UI_INPUT_ERROR
        INVOKE PRINT, OFFSET UI_SEPARATOR
        .ENDIF
        JMP MENU
.ENDIF

MENU_1:
; get product info
        ; print input hint
        INVOKE PRINT, OFFSET UI_INPUT_PRO
        ; get product name input
        INVOKE INPUT, OFFSET INPUT_BUF
        INVOKE PRINT, OFFSET UI_CRLF
        ; get input length & add '$' to tail
        MOV AL, INPUT_COUNT
        AND EAX, 0FFH
        .IF AL ; != 0
        INVOKE GET_PRO, OFFSET S1, OFFSET S2, OFFSET INPUT_CONTENT
        .IF !DI ; == 0
        INVOKE PRINT, OFFSET UI_SEPARATOR
        INVOKE PRINT, OFFSET UI_PRO_NOTFOUND
        INVOKE PRINT, OFFSET UI_SEPARATOR
        .ELSE
        INVOKE PRINT, OFFSET UI_SEPARATOR
        INVOKE PRINT_PRO, DI, OFFSET UI_SHOP1, OFFSET UI_CRLF, 0
        .IF SI
        INVOKE PRINT_PRO, SI, OFFSET UI_SHOP2, OFFSET UI_CRLF, 0
        .ENDIF
        .ENDIF
        .ENDIF
        JMP MENU

MENU_2:
; edit product info
        ; print input hint
        INVOKE PRINT, OFFSET UI_INPUT_PRO
        ; get product name input
        INVOKE INPUT, OFFSET INPUT_BUF
        INVOKE PRINT, OFFSET UI_CRLF
        ; get input length & add '$' to tail
        MOV AL, INPUT_COUNT
        AND EAX, 0FFH
        .IF AL ; != 0
        INVOKE GET_PRO, OFFSET S1, OFFSET S2, OFFSET INPUT_CONTENT
        .IF !DI ; == 0
        INVOKE PRINT, OFFSET UI_SEPARATOR
        INVOKE PRINT, OFFSET UI_PRO_NOTFOUND
        INVOKE PRINT, OFFSET UI_SEPARATOR
        .ELSE
        INVOKE PRINT, OFFSET UI_SEPARATOR
        INVOKE EDIT_PRO, DI, OFFSET INPUT_BUF, OFFSET INPUT_COUNT, OFFSET INPUT_CONTENT, OFFSET UI_CRLF
        ; INVOKE PRINT_PRO, DI, OFFSET UI_SHOP1, OFFSET UI_CRLF
        ; .IF SI
        ; INVOKE PRINT_PRO, SI, OFFSET UI_SHOP2, OFFSET UI_CRLF
        ; .ENDIF
        .ENDIF
        .ENDIF
        JMP MENU

MENU_3:
; sum profit rate
        INVOKE CALC_PROFIT, OFFSET GA1, OFFSET GB1, 10, 20
        JMP MENU

MENU_4:
        INVOKE RANK_ITEM, OFFSET S1, OFFSET S2, 6, 10, 20
        JMP MENU

MENU_5:
; print all products
        INVOKE PRINT, OFFSET UI_SEPARATOR
        ; SHOP1
        MOV BX, 0
        MOV DI, OFFSET GA1
        .WHILE BX < 60
        ADD DI, BX
        INVOKE PRINT_PRO, DI, OFFSET UI_SHOP1, OFFSET UI_CRLF, 1
        ADD BX, 20
        .ENDW
        ; SHOP2
        MOV BX, 0
        MOV DI, OFFSET GB1
        .WHILE BX < 60
        ADD DI, BX
        INVOKE PRINT_PRO, DI, OFFSET UI_SHOP2, OFFSET UI_CRLF, 1
        ADD BX, 20
        .ENDW
        JMP MENU

        AND EAX, 0FFH
        ; MOV INPUT_CONTENT[EAX], '$'

        MOV SI, 0
        ; input test
        INVOKE  INPUT, OFFSET INPUT_BUF
        INVOKE  PRINT, OFFSET UI_CRLF
        MOV     AL, INPUT_COUNT
        AND     EAX, 0FFH
        INVOKE  PRINT, OFFSET INPUT_CONTENT

        ; str cmp test
        INVOKE STR_CMP, OFFSET UI_WELCOME, OFFSET UI_WELCOME
        INVOKE STR_CMP, OFFSET UI_WELCOME, OFFSET UI_CRLF
EXIT:
        MOV     AH, 4CH
        INT     21H

CODE    ENDS
        END     START
