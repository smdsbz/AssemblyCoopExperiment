# AssemblyCoopExperiment

Repo for HUST Assembly course co-op experiment

## Starring

-   smdsbz
-   Hunto

## PROC Documents

##### `PRINT`

**Args:**  
-   `STROFFSET`: eff. addr. of the string to be printed out
    - string **MUST BE** `'$'` terminated!

**Usage:**  
```assembly
INVOKE      PRINT, OFFSET UI_CRLF
```



##### `INPUT`

**Args:**  
-   `INPUT_BUF`: eff. addr. of the input buffer chunk

**Usage:**  
```assembly
INVOKE      INPUT, OFFSET INPUT_BUF
; NOTE: You still have to manually reset '\r' to '$',
;       for data segment cannot be infered
MOV         AL, INPUT_COUNT         ; or INPUT_BUF[1]
AND         EAX, 0FFH               ; Convert Byte to Double-Word
MOV         INPUT_CONTENT[EAX], '$' ; or INPUT_BUF[2][EAX]
```



##### `PRINT_INT32`

**Args:**  
-   `NUM`: number to be printed out, could be negative

**Usage:**  
```assembly
INVOKE      PRINT_INT32, -123
```
