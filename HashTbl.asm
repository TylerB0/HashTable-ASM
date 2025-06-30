COMMENT&
main format for tables is string(21 bytes), address(4 bytes), count(1 byte), size(1 byte), total of 27 bytes
&


INCLUDE Irvine32.inc


.stack 4096

; Function Prototypes
ExitProcess PROTO dwExitCode : DWORD
HTCreate PROTO hSize:BYTE
HTInsert PROTO hTable:DWORD, key:DWORD, value:DWORD
HTRemove PROTO hTable:DWORD, key:DWORD
HTSearch PROTO hTable:DWORD, key:DWORD
HTPrint PROTO htable:DWORD
HTDestroy PROTO hTable:DWORD
HeapReAlloc PROTO hHeap:HANDLE, dwFlags:DWORD, lpMem:DWORD, dwBytes:DWORD
sumString PROTO inStrng:DWORD
dupChk PROTO hTable:DWORD, inString:DWORD
reHash PROTO hTable:DWORD, nTable:DWORD

.data
MAX = 21
k BYTE 21 DUP(?)
v BYTE 21 DUP(?)
prev DWORD ?
next DWORD ?
msg0 BYTE "~~~~~~~~~~~~~Hash Table~~~~~~~~~~~~~",0Ah,0Dh
msg1 BYTE "Press the following to perform specific actions (press Q to quit).",0Ah,0Dh
msg2 BYTE "1 = Create HashTbl    2 = Insert into HashTbl      3 = Remove from HashTbl",0Ah,0Dh
msg3 BYTE "4 = Search HashTbl    5 = Print HashTbl            6 = Destroy HashTbl",0
msg4 BYTE "Enter the key: ",0
msg5 BYTE "Enter the value of the key: ",0
msg6 BYTE "Name the Hash Table (max 20 chars): ",0
msg7 BYTE "Enter the size of the hash table (max is 255): ",0
errMsg BYTE "Something went wrong, either space cannot be allocated anymore, ",0Ah,0Dh
errMsg2 BYTE "your input is invalid/a duplicate value, no more entries/tables can be made,",0Ah,0Dh
errMsg3 BYTE "or something is potentially affecting the program.",0
msg8 BYTE "Key or Table not found.",0
msg9 BYTE "Success.",0
msg10 BYTE "Which Table? ",0
msg11 BYTE "What's the size (how many slots, max = 255)? ",0
msg12 BYTE "Please enter a valid character/input: ",0
sum DWORD 0h
hHeap DWORD ?   ; handle to heap, used for all heap related functions
countTbl BYTE 0h
tbls BYTE 135 DUP(0)        ; an array of the names of the hash table with their respective addresses, max is 5
tmp BYTE 0h
tmp2 DWORD ?
tmp3 WORD 0h
tmp4 DWORD ?
tmp5 DWORD ?
tmp6 BYTE 0h
lfact REAL4 0.75
kPrnt BYTE "Key: ",0
vPrnt BYTE " | Value: ",0
arrw BYTE " -> ",0
op1 BYTE "-Create-",0
op2 BYTE "-Insert-",0
op3 BYTE "-Remove-",0
op4 BYTE "-Search-",0
op5 BYTE "-Print-",0
op6 BYTE "-Destroy-",0
updt BYTE "Size of Table has been increased to: ",0

.code
main PROC

    INVOKE GetProcessHeap   
    .IF eax == NULL			; if eax is null then the function fails, cant do anything if no heap so you exit
        mov edx, OFFSET errMsg
        call WriteString
	    jmp	quit
	.ELSE
	    mov	hHeap,eax		; if eax isnt null then the heap handle will be stored there, since it will be used later it is stored in memory
	.ENDIF

    menu:
        mov edx, OFFSET msg0
        call WriteString
        readAgn:
            call Crlf
            call ReadChar
            cmp al, '1'
            je create
            cmp al, '2'
            je insrt
            cmp al, '3'
            je rmv
            cmp al, '4'
            je search
            cmp al, '5'
            je printTbl
            cmp al, '6'
            je destry
            cmp al, 'Q'
            je quit
            cmp al, 'q'
            je quit
            mov edx, OFFSET msg12
            call WriteString
            call Crlf
            jmp readAgn

    print:
        mov ecx, 5
        mov tmp, 0
        mov edx, OFFSET tbls
        printAll:
            mov eax, 0
            movzx eax, tmp
            call WriteDec
            mov al, ':'
            call WriteChar
            cmp edx, 00000000h
            je skip1
            call WriteString
            mov al, ' '
            call WriteChar
            inc tmp
            add edx, 26d
            loop printAll
            skip1:
                mov edx, OFFSET msg8
                call WriteString
                mov al, ' '
                call WriteChar
                add edx, 26d
                inc tmp
                loop printAll

    create:
        mov edx, OFFSET op1
        call WriteString
        call Crlf
        call Crlf
        mov edx, OFFSET msg11
        call WriteString
        createagn:
            call ReadDec
            cmp eax, 00000000h
            je createErr
            cmp eax, 000000FFh
            jle skip2
        createErr:
            mov edx, OFFSET msg12
            call WriteString
            jmp createagn
        skip2:
            mov tmp, al
            INVOKE HTCreate, tmp
            jmp readAgn

    insrt:
        mov edx, OFFSET op2
        call WriteString
        call Crlf
        call fndTbl
        cmp ecx, 00000000h
        je readAgn
        mov eax, tmp2
        add eax, 25d
        mov ebx, 0
        mov bl, [eax]
        cmp ebx, 000000FFh
        jl skip
        mov edx, OFFSET errMsg
        call WriteString
        jmp readAgn
        skip:
            mov edx, OFFSET msg4
            call WriteString
            mov ecx, MAX
            mov edx, OFFSET k
            call ReadString
            mov edx, OFFSET msg5
            call WriteString
            mov edx, OFFSET v
            call ReadString
            mov eax, tmp2
            add eax, 21d
            INVOKE HTInsert, [eax], OFFSET k, OFFSET v
            jmp readAgn

    search:
        mov edx, OFFSET op4
        call WriteString
        call Crlf
        call fndTbl
        cmp ecx, 00000000h
        je readAgn
        mov edx, OFFSET msg4
        call WriteString
        mov edx, OFFSET k
        mov ecx, MAX
        call ReadString
        mov eax, tmp2
        add eax, 21d
        INVOKE HTSearch, [eax], OFFSET k
        jmp readAgn

    rmv:
        mov edx, OFFSET op3
        call WriteString
        call Crlf
        call fndTbl
        cmp ecx, 00000000h
        je readAgn
        mov edx, OFFSET msg4
        call WriteString
        mov edx, OFFSET k
        mov ecx, MAX
        call ReadString
        mov eax, tmp2
        add eax, 21d
        INVOKE HTRemove, [eax], OFFSET k
        jmp readAgn

    printTbl:
        mov edx, OFFSET op5
        call WriteString
        call Crlf
        call fndTbl
        cmp ecx, 00000000h
        je readAgn
        mov eax, tmp2
        add eax, 21d
        INVOKE HTPrint, [eax]
        call Crlf
        jmp readAgn

    destry:
        mov edx, OFFSET op6
        call WriteString
        call Crlf
        call fndTbl
        cmp ecx, 00000000h
        je readAgn
        mov eax, tmp2
        add eax, 21d
        INVOKE HTDestroy, [eax]
        jmp readAgn

    quit:
        INVOKE ExitProcess,1
main ENDP

HTCreate PROC hSize:BYTE

    cmp countTbl, 5d
    jl skip
    mov edx, OFFSET errMsg
    call WriteString
    jmp quit
    skip:
        mov eax, 0
        movzx eax, hSize
        mov ebx, 4
        mul bl

    INVOKE HeapAlloc, hHeap, HEAP_ZERO_MEMORY, eax
    .IF eax == NULL			
        mov edx, OFFSET errMsg
        call WriteString
    .ELSE
        mov edx, OFFSET msg6
        call WriteString
        mov edx, OFFSET tbls
        mov ecx, 5
        findSpot:
            mov ebx, [edx]
            cmp ebx, 00000000h
            je found
            add edx, 27d
            loop findSpot
            jmp nfound
        found:
            mov ebx, eax
            mov ecx, MAX
            call ReadString
            mov eax, ebx
            mov [edx+21], eax
            mov al, hSize
            mov [edx+26], al
            inc countTbl
            jmp quit
	.ENDIF

    nfound:
        mov edx, OFFSET errMsg
        call WriteString
        call Crlf
    quit:
        ret
HTCreate ENDP

HTInsert PROC hTable:DWORD, key:DWORD, value:DWORD

;
;

    fld lfact
    mov eax, tmp2
    add eax, 25d
    mov ebx, 0
    mov bl, [eax]
    mov tmp3, bx
    fild tmp3
    add eax, 1d
    mov bl, [eax]
    mov tmp3, bx
    fild tmp3
    fdiv
    fcomi ST(0), ST(1)
    mov eax, hTable
    mov tmp4, eax
    jbe norealloc
    mov ecx, 3
    clrFlt:
        fstp ST(0)
        loop clrFlt
    mov eax, ebx
    mov tmp, al
    cmp eax, 0000007fh
    jg equit
    mov ebx, 2
    mul bl  
    mov edx, OFFSET updt
    call WriteString
    call WriteDec
    call Crlf
    mov ebx, tmp2
    add ebx, 26d
    mov [ebx], al
    mov ebx, 4
    mul bl

    INVOKE HeapAlloc, hHeap, HEAP_ZERO_MEMORY, eax
    .IF eax == NULL			
        mov edx, OFFSET errMsg
    call WriteString
	    jmp	quit
	.ENDIF

    mov ebx, tmp2
    add ebx, 21d
    mov [ebx], eax
    mov ecx, 0
    add ebx, 4d
    mov [ebx], cl
    mov ebx, tmp4
    cmp eax, ebx
    je miniskip
    INVOKE reHash, ebx, eax
    miniskip:
        mov tmp4, eax
        jmp skipClr
    norealloc:
        mov ecx, 3
        clrFlt2:
            fstp ST(0)
            loop clrFlt2
    skipClr:
        mov eax, tmp4
        INVOKE dupChk, eax, key
        jz equit

    INVOKE HeapAlloc, hHeap, HEAP_ZERO_MEMORY, 42
    .IF eax == NULL			
        mov edx, OFFSET errMsg
        call WriteString
	    jmp	quit
	.ENDIF

    mov ebx, eax
    INVOKE Str_copy, key, ebx
    add ebx, 21d
    INVOKE Str_copy, value, ebx
    sub ebx, 21d

    INVOKE HeapAlloc, hHeap, HEAP_ZERO_MEMORY, 8
    .IF eax == NULL			
        mov edx, OFFSET errMsg
        call WriteString
	    jmp	quit
	.ENDIF

    mov [eax], ebx
    mov ecx, eax
    mov eax, tmp2
    add eax, 25d
    mov bl, [eax]
    inc bl
    mov [eax], bl
    INVOKE sumString, key 
    mov eax, ebx
    mov edx, tmp2
    add edx, 26d
    mov ebx, 0
    mov bl, [edx]
    mov edx, 0h
    div ebx
    mov ebx, 4
    mov eax, edx
    mul bl
    add eax, tmp4
    mov ebx, [eax]
    cmp ebx, 00000000h
    jne traverse
    mov [eax], ecx
    jmp quit
    traverse:
        add ebx, 4d
        mov edx, [ebx]
        cmp edx, 00000000h
        jne cont
        mov [ebx], ecx
        jmp quit
        cont:
            mov ebx, edx
            jmp traverse

    equit:
        mov edx, OFFSET errMsg
        call WriteString
        call Crlf

    quit:
    ret
HTInsert ENDP

reHash PROC USES eax hTable:DWORD, nTable:DWORD
;
;

    mov ecx, 0
    mov cl, tmp
    mov tmp6, cl
    mov eax, hTable
    mov tmp5, eax

    L1: 
        mov tmp, cl
        mov ebx, [eax]
        cmp ebx, 00000000h
        jne traverse
        contTrav:
        mov ecx, 0
        mov cl, tmp
        mov eax, tmp5
        add eax, 4d
        mov tmp5, eax
        loop L1
        jmp quit

    traverse:
        mov esi, [ebx]
        mov edi, ebx
        mov edx, esi
        add edx, 21
        INVOKE HTInsert, nTable, esi, edx
        mov ebx, edi
        add ebx, 4d
        mov ebx, [ebx]
        cmp ebx, 00000000h
        jne traverse
        jmp contTrav

    quit:
    mov cl, tmp6
    mov eax, hTable
    mov tmp5, eax
    mov tmp, cl

    L2:
        mov ebx, [eax]
        cmp ebx, 00000000h
        jne traverse2
        contTrav2:
        mov eax, tmp5
        add eax, 4d
        mov tmp5, eax
        loop L2
        INVOKE HeapFree, hHeap, 0, hTable
        cmp eax, 00000000h
        je errDest
        jmp quit2

    traverse2:
        mov tmp, cl
        cont:
        mov edx, [ebx]
        INVOKE HeapFree, hHeap, 0, edx
        cmp eax, 00000000h
        je errDest
        mov edx, ebx
        add ebx, 4d
        mov ebx, [ebx]
        INVOKE HeapFree, hHeap, 0, edx
        cmp eax, 00000000h
        je errDest
        cmp ebx, 00000000h
        jne cont
        mov ecx, 0
        mov cl, tmp
        jmp contTrav2

    errDest:
        mov edx, OFFSET errMsg
        call WriteString
        call Crlf

    quit2:
        ret
reHash ENDP

dupChk PROC USES eax ebx ecx edx hTable:DWORD, inString:DWORD

    INVOKE sumString, inString 
    mov eax, ebx
    mov edx, tmp2
    add edx, 26d
    mov ebx, 0
    mov bl, [edx]
    mov edx, 0h
    div ebx
    mov ebx, 4
    mov eax, edx
    mul bl
    add eax, hTable
    mov ebx, [eax]
    cmp ebx, 00000000h
    jne traverse
    cmp ebx, 1h
    jmp quit
    traverse:
        mov eax, [ebx]
        INVOKE Str_compare, eax, inString
        jz quit
        add ebx, 4d
        mov edx, [ebx]
        cmp edx, 00000000h
        jne cont
        cmp ebx, 0h
        jmp quit
        cont:
            mov ebx, edx
            jmp traverse

    quit:
    ret
dupChk ENDP

HTRemove PROC hTable:DWORD, key:DWORD
    ; use next of deleted node as new next for its prev node
    ; MAKE SURE TO DEALLOC DELETED NODE

    mov tmp, 0h
    INVOKE sumString, key 
    mov eax, ebx
    mov edx, tmp2
    add edx, 26d
    mov ebx, 0
    mov bl, [edx]
    mov edx, 0h
    div ebx
    mov ebx, 4
    mov eax, edx
    mul bl
    add eax, hTable
    mov ebx, [eax]
    mov prev, eax
    cmp ebx, 00000000h
    jne traverse
    jmp nfound

    traverse:
        inc tmp
        mov eax, [ebx]
        INVOKE Str_compare, eax, key
        jz found
        mov prev, ebx
        add ebx, 4d
        ;mov next, [ebx]
        mov edx, [ebx]
        cmp edx, 00000000h
        jne cont
        cmp ebx, 0h
        jmp nfound
        cont:
            mov ebx, edx
            jmp traverse
    found:
        mov edx, [ebx+4]
        mov ecx, prev
        cmp tmp, 1d
        je skip
        add ecx, 4d
        skip:
        mov [ecx], edx
        INVOKE HeapFree, hHeap, 0, eax
        cmp eax, 00000000h
        je unknwnErr
        INVOKE HeapFree, hHeap, 0, ebx
        cmp eax, 00000000h
        je unknwnErr
        mov edx, OFFSET msg9
        call WriteString
        call Crlf
        jmp quit

    nfound:
        mov edx, OFFSET msg8
        call WriteString
        call Crlf
        jmp quit

    unknwnErr:
        mov edx, OFFSET errMsg
        call WriteString

    quit:
    ret
HTRemove ENDP

HTSearch PROC hTable:DWORD, key:DWORD
    ; iterate through and compare the strings at the addresses with key

    INVOKE sumString, key 
    mov eax, ebx
    mov edx, tmp2
    add edx, 26d
    mov ebx, 0
    mov bl, [edx]
    mov edx, 0h
    div ebx
    mov ebx, 4
    mov eax, edx
    mul bl
    add eax, hTable
    mov ebx, [eax]
    cmp ebx, 00000000h
    jne traverse
    jmp nfound

    traverse:
        mov eax, [ebx]
        INVOKE Str_compare, eax, key
        jz found
        add ebx, 4d
        mov edx, [ebx]
        cmp edx, 00000000h
        jne cont
        cmp ebx, 0h
        jmp nfound
        cont:
            mov ebx, edx
            jmp traverse
    found:
        add eax, 21d
        mov edx, eax
        call WriteString
        Call Crlf
        jmp quit

    nfound:
        mov edx, OFFSET msg8
        call WriteString
        call Crlf

    quit:
    ret
HTSearch ENDP

HTPrint PROC hTable:DWORD
    ; traverse through LL until nxt = 0 then you move on to the other indexes

    mov tmp, 0
    mov ebx, tmp2
    add ebx, 26d
    mov ecx, 0
    mov cl, [ebx]
    mov eax, hTable
    mov tmp2, eax

    L1:
        call Crlf
        mov eax, 0
        mov al, tmp
        call WriteDec
        mov al, ':'
        call WriteChar
        mov eax, tmp2
        mov ebx, [eax]
        cmp ebx, 00000000h
        jne traverse
        contTrav:
        inc tmp
        add tmp2, 4d
        loop L1
        jmp quit

    traverse:
        mov edx, OFFSET kPrnt
        call WriteString
        mov edx, [ebx]
        call WriteString
        mov edx, OFFSET vPrnt
        call WriteString
        mov edx, [ebx]
        add edx, 21d
        call WriteString
        mov edx, OFFSET arrw
        call WriteString
        add ebx, 4d
        mov ebx, [ebx]
        cmp ebx, 00000000h
        jne traverse
        jmp contTrav

    quit:
    ret
HTPrint ENDP

HTDestroy PROC hTable:DWORD
    ; for the LL 1 var keeps track of the prev, another the next
    ; get rid of prev as you iterate through next, all 8 byte blocks of addresses except hash indxs which are 4
    ;INVOKE HeapFree, hHeap, 0, hTable

    mov tmp, 0
    mov ebx, tmp2
    add ebx, 26d
    mov ecx, 0
    mov cl, [ebx]
    mov eax, hTable
    mov tmp4, eax
    mov tmp, cl

    L1:
        mov ebx, [eax]
        cmp ebx, 00000000h
        jne traverse
        contTrav:
        mov eax, tmp4
        add eax, 4d
        mov tmp4, eax
        loop L1
        INVOKE HeapFree, hHeap, 0, hTable
        cmp eax, 00000000h
        je errDest
        mov ecx, 27
        mov eax, tmp2
        tblZO:
            mov [eax], ch
            add eax, 1d
            loop tblZO
        dec countTbl
        jmp quit

    traverse:
        mov tmp, cl
        cont:
        mov edx, [ebx]
        INVOKE HeapFree, hHeap, 0, edx
        cmp eax, 00000000h
        je errDest
        mov edx, ebx
        add ebx, 4d
        mov ebx, [ebx]
        INVOKE HeapFree, hHeap, 0, edx
        cmp eax, 00000000h
        je errDest
        cmp ebx, 00000000h
        jne cont
        mov ecx, 0
        mov cl, tmp
        jmp contTrav

    errDest:
        mov edx, OFFSET errMsg
        call WriteString
        call Crlf

    quit:
    ret
HTDestroy ENDP

sumString PROC USES eax ecx edx inStrng:DWORD 
; Recieves: DWORD containing an address to a string
; Returns: Sum of letter characters ASCII values in ebx
    mov ebx, 0h
    mov edx, inStrng
    call StrLength
    mov ecx, eax
    addStuff:
        mov al, [edx]
        uCaseChk:
            cmp al, 65d
            jl skip
            cmp al, 90d
            jg lCaseChk
            jle add2sum

        lCaseChk:
            cmp al, 97d
            jl skip
            cmp al, 122d
            jg skip
        add2sum:
        add ebx, eax
        skip:
        add edx, 1
        loop addStuff
    ret
sumString ENDP

fndTbl PROC
;
;
    call Crlf
    mov edx, OFFSET msg10
    call WriteString
    mov edx, OFFSET k
    mov ecx, MAX
    call ReadString
    mov ecx, 5
    mov edx, OFFSET tbls
    findTbl:
        inc tmp
        INVOKE Str_compare, OFFSET k, edx
        jz found
        add edx, 27d
        loop findTbl
    mov edx, OFFSET msg8
    call WriteString
    call Crlf
    ret
    found:
        mov eax, edx
        mov tmp2, eax
    ret
fndTbl ENDP

END main