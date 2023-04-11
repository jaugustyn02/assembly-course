code segment
start:
;       stack segment assignment
        mov     ax, seg stack
        mov     ss, ax
        mov     sp, offset stack_ptr


;       getting user input
        mov     dx, offset buff
        call    input
        
        call    parse_input
        
        mov     dx, offset str1
        call    lnprint
        
        mov     dx, offset str2
        call    lnprint
        
        mov     dx, offset str3
        call    lnprint

        mov     dx, offset endl
        call    print
        mov     word ptr cs:[num1], 3
        mov     dx, word ptr cs:[num1]
        add     dx, '0'
        mov     ah, 2
        int     21h

;       end program
        mov     ax, 4c00h
        int     21h

;.................................input/output.......................................
buff    db 32, ?, 32 dup('$')
endl    db 10, 13, '$'
;..................................
input: ; in dx - offset of location where put user input
        mov     ax, seg code
        mov     ds, ax
        mov     ah, 0ah
        int     21h

;       swapping last byte of buff from 13 to '$'
        mov     bp, offset buff +1
        mov     bl, byte ptr cs:[bp]
        add     bl, 1
        xor     bh, bh
        add     bp, bx
        mov     byte ptr cs:[bp], '$'
        ret
;..................................
print: ; in dx - offset of text to print
        mov     ax, seg code
        mov     ds, ax
        mov     ah, 9           ; print msg ds:dx
        int     21h     
        ret
;..................................
lnprint: ; in dx - offset of text to print
        push    dx

        mov     dx, offset endl
        call    print
        
        pop     dx  
        call    print  
        ret
;..................................
lnprint_num: ; in dx - offset of text to print
        push    dx

        mov     dx, offset endl
        call    print
        
        pop     dx  
        call    print  
        ret
;..................................
;................................parsing..input....................................
str1    db 32 dup('$')
str2    db 32 dup('$')
str3    db 32 dup('$')
num1    dw ?
num2    dw ?
result  dw ?
;..................................
parse_input:
        mov     si, offset buff +2      ; source
        mov     bp, offset buff +1      ; num of bytes to copy
        mov     bl, byte ptr cs:[bp]
        xor     bh, bh
        mov     cx, bx
        
        mov     di, offset str1         ; destination
        call    copy_word
        
        mov     di, offset str2         ; destination
        call    copy_word
        
        mov     di, offset str3         ; destination
        call    copy_word
        ret
;..................................
skip_whitespace:
loop1: push cx
        mov     al, byte ptr cs:[si]

        cmp     al, ' '
        jne     loop_exit2

        inc si

        pop cx
        loop loop1
        ret
;..................................
copy_word: ; in si - source offset, di - destination offset

        call    skip_whitespace

loop2:  push cx

        mov     al, byte ptr cs:[si]

        cmp     al, ' '
        je     loop_exit1

        cmp     al, '$'
        je     continue

        mov     byte ptr cs:[di], al
        inc di

continue:
        inc si
        pop cx
        loop loop2      ; loop2 end
        ret

loop_exit1:
        pop cx
        inc si
        ret
loop_exit2:
        pop cx
        ret
;..................................
code ends


stack segment stack
	dw	        300 dup(?)
	stack_ptr	dw ?
stack ends


end start