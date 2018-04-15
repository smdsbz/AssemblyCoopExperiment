.386
STACK   SEGMENT USE16 STACK
        DB 200 DUP(0)
STACK   ENDS
DATA    SEGMENT USE16 PUBLIC 'entry'
        ; -------- UI --------
        UI_WELCOME      DB 'welcome!', 0DH, 0AH, '$'
        UI_CRLF         DB 0DH, 0AH, '$'
        ; -------- Global --------
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


; INPUT   PROC FAR STDCALL,
;         BUFOFFSET:WORD
;         ; simple input function
;         ; Args:
;         ;       BUFOFFSET       - [WORD] target buffer block
;         ; Return:
;         ;       (None)
;         PUSH    EAX
;         PUSH    EDX
;         MOV     DX, BUFOFFSET
;         MOV     AH, 10
;         INT     21H
;         POP     EDX
;         POP     EAX
;         RET
; INPUT   ENDP

START:
        MOV     AX, DATA
        MOV     DS, AX

        INVOKE  PRINT, OFFSET UI_WELCOME
        INVOKE  PRINT_INT32, -123
        INVOKE  PRINT, OFFSET UI_CRLF
        INVOKE  PRINT_INT32, 1234

        MOV     AH, 4CH
        INT     21H

CODE    ENDS
        END     START



