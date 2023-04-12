code segment
start:
; stack segment assignment:
        mov     ax, seg stack
        mov     ss, ax
        mov     sp, offset stack_ptr

; print input prompt:
        mov     ax, seg data
        mov     dx, offset input_prompt
        call    print

; getting user input:
        mov     dx, offset buff
        call    input

; parsing user input:
        call    parse_input
        
; calculating result:
        call    calculate_result

; printing result:
        call    print_result

exit:
        mov     ax, 4c00h
        int     21h

;.................................input/output.......................................
buff    db 32, ?, 32 dup('$')
endl    db 10, 13, '$'
space   db ' ', '$'
;-----------------------------------------------------
input: ; in dx - user input destination offset
        mov     ax, seg code
        mov     ds, ax
        mov     ah, 0ah
        int     21h

; changing last byte of buff from 13 to '$'
        mov     bp, offset buff +1
        mov     bl, byte ptr cs:[bp]
        add     bl, 1
        xor     bh, bh
        add     bp, bx
        mov     byte ptr cs:[bp], '$'
        ret
;-----------------------------------------------------
print_result: ; in: result
        mov     ax, seg data
        mov     dx, offset result_prompt
        call    lnprint

        mov     ax, word ptr cs:[result]
; if result < 0:
        cmp     ax, 0
        jl      negative1
; else:
        jmp     non_negative1
negative1:
        mov     bx, -1
        mul     bx
        push    ax

        mov     ax, seg data
        mov     dx, offset negative
        call    print
        pop     ax
non_negative1:
        mov     bl, 10
        div     bl
        mov     byte ptr cs:[digit1], al
        mov     byte ptr cs:[digit2], ah

; if result >= 20:
        cmp     byte ptr cs:[digit1], 2
        jae     print_tens
; if result >= 10:
        cmp     byte ptr cs:[digit1], 1
        je      print_teens
; else:
        jmp     print_ones
        ret
print_tens:
; calculate position in array:
        xor     ax, ax
        mov     al, byte ptr cs:[digit1]
        sub     al, 1
        mov     bl, 2
        mul     bl
; print word:
        mov     si, offset tens
        add     si, ax
        mov     dx, [ds:[si]]
        mov     ax, seg data
        call    print

; if (result % 10) != 0:
        cmp     byte ptr cs:[digit2], 0
        jne     print_space
; else:
        ret
print_space:
        mov     ax, seg code
        mov     dx, offset space
        call    print
print_ones:
; calculate position in array:
        xor     ax, ax
        mov     al, byte ptr cs:[digit2]
        add     al, 1
        mov     bl, 2
        mul     bl
; print word:
        mov     si, offset digits
        add     si, ax
        mov     dx, [ds:[si]]
        mov     ax, seg data
        call    print
        ret
print_teens:
; calculate position in array:
        xor     ax, ax
        mov     al, byte ptr cs:[digit2]
        add     al, 1
        mov     bl, 2
        mul     bl
; print word:
        mov     si, offset teens
        add     si, ax
        mov     dx, [ds:[si]]
        mov     ax, seg data
        call    print
        ret
;-----------------------------------------------------
raise_error:
        mov     ax, seg data
        mov     dx, offset ds:[error_msg1]
        call    lnprint
        jmp     exit
;-----------------------------------------------------
print: ; in: dx - offset of text to print, ax - data segment address
        push    ds
        mov     ds, ax
        mov     ah, 9
        int     21h
        pop     ds
        ret
;-----------------------------------------------------
lnprint: ; in dx - offset of text to print, ax - data segment address
        push    dx
        push    ax
        mov     ax, seg code
        mov     dx, offset endl
        call    print

        pop     ax
        pop     dx
        call    print
        ret
;-----------------------------------------------------

;................................parsing..input....................................
word1                   db 32 dup('$')
word2                   db 32 dup('$')
word3                   db 32 dup('$')
digit1                  dw ?
digit2                  dw ?
operator_id             dw ?            ; ids: 0 - add, 1 - sub, 2 - mul
result                  dw ?
invalid_digit           dw 10
invalid_operator        dw 3
;-----------------------------------------------------
parse_input:
; reading words:
        mov     si, offset buff +2      ; buffor beginning
        mov     bp, offset buff +1
        mov     bl, byte ptr cs:[bp]    ; real buffor length
        xor     bh, bh
        mov     cx, bx

        mov     di, offset word1
        call    read_word

        mov     di, offset word2
        call    read_word

        mov     di, offset word3
        call    read_word

; parsing words:
        mov     si, offset word1
        mov     di, offset digit1
        mov     bx, offset digits
        call    parse_word        

        mov     si, offset word2
        mov     di, offset operator_id
        mov     bx, offset operators
        call    parse_word

        mov     si, offset word3
        mov     di, offset digit2
        mov     bx, offset digits
        call    parse_word
; validation:
        mov     ax, cs:[invalid_digit]
        cmp     ax, word ptr cs:[digit1]
        je      raise_error

        mov     ax, cs:[[invalid_operator]]
        cmp     ax, word ptr cs:[operator_id]
        je      raise_error

        mov     ax, cs:[invalid_digit]
        cmp     ax, word ptr cs:[digit2]
        je      raise_error

        ret
;-----------------------------------------------------
parse_word:; in: si - source word offset; di - destination word offset; bx - array of valid words offset
        push    di
        mov     ax, seg data
        mov     ds, ax
        mov     cx, word ptr ds:[bx]    ; size of word array
        push    cx
        add     bx, 2
;....................................>
loop_words1: push cx
        push    si
        mov     di, [ds:[bx]]           ; compared word offset
;........................>>
loop_chars1:
        mov     al, byte ptr cs:[si]
        cmp     al, byte ptr ds:[di]
        jne     continue_words1

        inc     si
        inc     di
        cmp     al, '$'
        jne     loop_chars1
;........................<<
        pop     si
        pop     cx
        jmp     exit_parse_word
continue_words1:
        pop     si
        pop     cx
        add     bx, 2           ; jumping 2 bytes (word)
        loop    loop_words1
exit_parse_word:
        pop     ax              ; size of array (initial cx)
        sub     ax, cx
        pop     di
        mov     word ptr cs:[di], ax
        ret
;....................................<
;-----------------------------------------------------
skip_whitespace:; in - si - buffor current byte address, cx - number of bytes left
;.................>
loop_chars2: push cx
        mov     al, byte ptr cs:[si]

        cmp     al, ' '
        jne     exit_loop_chars2

        inc     si

        pop     cx
        loop    loop_chars2
;.................<
        ret

exit_loop_chars2:
        pop     cx
        ret
;-----------------------------------------------------
read_word: ; in si - source bytes offset, di - destination bytes offset, cx - number of bytes left
        call    skip_whitespace

; checking if user input is not empty
        cmp     cx, 0
        je      exit_read_word
;................................>
loop_chars3:  push cx

        mov     al, byte ptr cs:[si]

        cmp     al, ' '
        je     exit_loop_chars3

        cmp     al, '$'
        je     continue_loop_chars3

        mov     byte ptr cs:[di], al
        inc     di

continue_loop_chars3:
        inc     si
        pop     cx
        loop    loop_chars3
;................................<
exit_read_word:
        ret

exit_loop_chars3:
        inc     si
        pop     cx
        jmp     exit_read_word
;-----------------------------------------------------

;....................................calculations....................................
; digit1, digit2, operator_id
;-----------------------------------------------------
calculate_result:
        xor     ax, ax
        add     ax, cs:[digit1]
        cmp     cs:[operator_id], 0
        je      addition
        cmp     cs:[operator_id], 1
        je      substraction
        cmp     cs:[operator_id], 2
        je      multiplication
addition:
        add     ax, cs:[digit2]
        jmp     exit_calculate_result
substraction:
        sub     ax, cs:[digit2]
        jmp     exit_calculate_result
multiplication:
        mul     cs:[digit2]
        jmp     exit_calculate_result
exit_calculate_result:
        mov     cs:[result], ax
        ret
;-----------------------------------------------------
code ends


stack segment stack
	dw	        300 dup(?)
	stack_ptr	dw ?
stack ends


data segment
b0      db      "zero",         '$'
b1      db      "jeden",        '$'
b2      db      "dwa",          '$'
b3      db      "trzy",         '$'
b4      db      "cztery",       '$'
b5      db      "piec",         '$'
b6      db      "szesc",        '$'
b7      db      "siedem",       '$'
b8      db      "osiem",        '$'
b9      db      "dziewiec",     '$'
digits  dw      10, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9

b10     db      "dziesiec",             '$'
b11     db      "jedenascie",           '$'
b12     db      "dwanascie",            '$'
b13     db      "trzynascie",           '$'
b14     db      "czternascie",          '$'
b15     db      "pietnascie",           '$'
b16     db      "szesnascie",           '$'
b17     db      "siedemnascie",         '$'
b18     db      "osiemnascie",          '$'
b19     db      "dziewietnascie",       '$'
teens   dw      10, b10, b11, b12, b13, b14, b15, b16, b17, b18, b19

b20     db      "dwadziescia",          '$'
b30     db      "trzydziesci",          '$'
b40     db      "czterdziesci",         '$'
b50     db      "piecdziesiat",         '$'
b60     db      "szescdziesiat",        '$'
b70     db      "siedemdziesiat",       '$'
b80     db      "osiemdziesiat",        '$'
b90     db      "dziewiecdziesiat",     '$'
tens    dw      8, b20, b30, b40, b50, b60, b70, b80, b90

badd    db      "dodac",        '$'
bsub    db      "odjac",        '$'
bmul    db      "razy",         '$'
operators       dw    3, badd, bsub, bmul

input_prompt    db      "Wprowadz slowny opis dzialania: ",     '$'
result_prompt   db      "Wynikiem jest: ",                      '$'
negative        db      "minus ",                               '$'     
error_msg1      db      "Blad danych wejsciowych!",             '$'
error_msg2      db      "Nie mozna dzielic przez zero!",        '$'
data ends


end start