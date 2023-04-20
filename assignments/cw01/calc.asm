code segment
start:
; stack segment assignment:
        mov     ax, seg stack
        mov     ss, ax
        mov     sp, offset stack_ptr

; printing input prompt:
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
buff    db 128, ?, 128 dup('$')
endl    db 10, 13, '$'
space   db ' ', '$'
unit_digit      db ?
tens_digit      db ?
;-----------------------------------------------------
input: ; in: dx - user input destination offset
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
raise_error: ; in: dx - offset of error message in segment data
        mov     ax, seg data
        call    lnprint
        jmp     exit
;-----------------------------------------------------
print_result: ; in: cs:[result]
; print result prompt:
        mov     ax, seg data
        mov     dx, offset result_prompt
        call    lnprint

; print result:
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
        mov     byte ptr cs:[tens_digit], al
        mov     byte ptr cs:[unit_digit], ah

; if result >= 20:
        cmp     byte ptr cs:[tens_digit], 2
        jae     print_tens
; if result >= 10:
        cmp     byte ptr cs:[tens_digit], 1
        je      print_teens
; else:
        jmp     print_ones
        ret
print_tens:
; calculate position in array:
        xor     ax, ax
        mov     al, byte ptr cs:[tens_digit]
        sub     al, 1
        mov     bl, 2
        mul     bl
; print word:
        mov     si, offset tens
        add     si, ax
        mov     dx, word ptr [ds:[si]]
        mov     ax, seg data
        call    print

; if unit digit not equal 0:
        cmp     byte ptr cs:[unit_digit], 0
        jne     print_space
; else:
        ret
print_space:
        mov     ax, seg code
        mov     dx, offset space
        call    print
print_ones:
; calculate word position in array:
        xor     ax, ax
        mov     al, byte ptr cs:[unit_digit]
        add     al, 1
        mov     bl, 2
        mul     bl
; print word:
        mov     si, offset digits
        add     si, ax
        mov     dx, word ptr [ds:[si]]
        mov     ax, seg data
        call    print
        ret
print_teens:
; calculate word position in array:
        xor     ax, ax
        mov     al, byte ptr cs:[unit_digit]
        add     al, 1
        mov     bl, 2
        mul     bl
; print word:
        mov     si, offset teens
        add     si, ax
        mov     dx, word ptr [ds:[si]]
        mov     ax, seg data
        call    print
        ret
;-----------------------------------------------------

;................................input..parser....................................
word1                   db 128 dup('$')
word2                   db 128 dup('$')
word3                   db 128 dup('$')
digit1                  dw ?
digit2                  dw ?
operator_id             dw ?            ; id: 0-add, 1-sub, 2-mul, 3-div
result                  dw ?
;-----------------------------------------------------
parse_input:
; reading words:
        mov     si, offset buff +2      ; buffor beginning
        mov     bp, offset buff +1
        mov     bl, byte ptr cs:[bp]    ; input length
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
        ret
;-----------------------------------------------------
parse_word:; in: si - source word offset; di - destination word offset; bx - array of valid words offset
        push    di
        mov     ax, seg data
        mov     ds, ax
        mov     cx, word ptr ds:[bx]    ; size of valid words array
        push    cx
        add     bx, 2
; iterating through array of valid words
;......................................>
loop_words1: push cx
        push    si
        mov     di, word ptr [ds:[bx]]           ; compared word offset
; iterating through each byte of input word
;..........................>>
loop_chars1:
; comparing two bytes
        mov     al, byte ptr cs:[si]
        cmp     al, byte ptr ds:[di]
        jne     continue_words1

        inc     si
        inc     di
        cmp     al, '$'
        jne     loop_chars1
;..........................<<
; input word matched a valid word (cx > 0) or input word is invalid (cx == 0)
        pop     si
        pop     cx
        jmp     exit_parse_word
continue_words1:
        pop     si
        pop     cx
        add     bx, 2           ; jumping 2 bytes (word)
        loop    loop_words1
exit_parse_word:
; if cx == 0: (invalid word)
        cmp     cx, 0
        mov     dx, offset ds:[invalid_input]
        je      raise_error
; else: (valid word)
        pop     ax              ; size of array (initial cx)
        sub     ax, cx
        pop     di              ; initial offset of word destination
        mov     word ptr cs:[di], ax
        ret
;......................................<
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
; moving to first not ' ' byte 
        call    skip_whitespace

; checking if user input is not empty
        cmp     cx, 0
        je      exit_read_word
;..................................>
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
;..................................<
exit_read_word:
        ret

exit_loop_chars3:
        inc     si
        pop     cx
        jmp     exit_read_word
;-----------------------------------------------------

;....................................calculations....................................
; in: cs:[digit1], cs:[digit2], cs:[operator_id]
;-----------------------------------------------------
calculate_result:
;        xor     ax, ax
        mov     ax, cs:[digit1]
        cmp     cs:[operator_id], 0
        je      addition
        cmp     cs:[operator_id], 1
        je      substraction
        cmp     cs:[operator_id], 2
        je      multiplication
        cmp     cs:[operator_id], 3
        je      division
addition:
        add     ax, cs:[digit2]
        jmp     exit_calculate_result
substraction:
        sub     ax, cs:[digit2]
        jmp     exit_calculate_result
multiplication:
        mul     cs:[digit2]
        jmp     exit_calculate_result
division:
        mov     bl, byte ptr cs:[digit2]
; checking if there is not division by zero
        cmp     bl, 0
        mov     dx, offset ds:[division_by_0]
        je      raise_error

        div     bl
        xor     ah, ah
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
w0      db      "zero",         '$'
w1      db      "jeden",        '$'
w2      db      "dwa",          '$'
w3      db      "trzy",         '$'
w4      db      "cztery",       '$'
w5      db      "piec",         '$'
w6      db      "szesc",        '$'
w7      db      "siedem",       '$'
w8      db      "osiem",        '$'
w9      db      "dziewiec",     '$'
digits  dw      10, w0, w1, w2, w3, w4, w5, w6, w7, w8, w9

w10     db      "dziesiec",             '$'
w11     db      "jedenascie",           '$'
w12     db      "dwanascie",            '$'
w13     db      "trzynascie",           '$'
w14     db      "czternascie",          '$'
w15     db      "pietnascie",           '$'
w16     db      "szesnascie",           '$'
w17     db      "siedemnascie",         '$'
w18     db      "osiemnascie",          '$'
w19     db      "dziewietnascie",       '$'
teens   dw      10, w10, w11, w12, w13, w14, w15, w16, w17, w18, w19

w20     db      "dwadziescia",          '$'
w30     db      "trzydziesci",          '$'
w40     db      "czterdziesci",         '$'
w50     db      "piecdziesiat",         '$'
w60     db      "szescdziesiat",        '$'
w70     db      "siedemdziesiat",       '$'
w80     db      "osiemdziesiat",        '$'
w90     db      "dziewiecdziesiat",     '$'
tens    dw      8, w20, w30, w40, w50, w60, w70, w80, w90

w_add    db      "plus",        '$'
w_sub    db      "minus",       '$'
w_mul    db      "razy",        '$'
w_div    db      "przez",       '$'
operators       dw    4, w_add, w_sub, w_mul, w_div

input_prompt    db      "Wprowadz slowny opis dzialania: ",     '$'
result_prompt   db      "Wynikiem jest: ",                      '$'
negative        db      "minus ",                               '$'     
invalid_input   db      "Blad danych wejsciowych!",             '$'
division_by_0   db      "Nie mozna dzielic przez zero!",        '$'

data ends


end start