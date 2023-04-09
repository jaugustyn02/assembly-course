data segment
buff    db 10, ?, 10 dup(?)     ; max length (including 13 - cartridge return); true length; 10 (max len) empty bytes
endl    db 10, 13, '$'
data ends


code segment
start:
;       stack segment assignment
        mov     ax, seg stack
        mov     ss, ax
        mov     sp, offset stack_ptr

;       data segment assignment
        mov     ax, seg data
        mov     ds, ax


;       getting user input
        mov     dx, offset buff
        call    input

;       swapping 10th byte of buff from 13 to '$'
        mov     bp, offset buff +1
        mov     bl, byte ptr ds:[bp]
        add     bl, 1
        xor     bh, bh
        add     bp, bx
        mov     byte ptr ds:[bp], '$'

;       printing new line sign
        mov     dx, offset endl
        call    print
        
;       printing user input
        mov     dx, offset buff +2
        call    print


;       end program
        mov     al, 0
        mov     ah, 4ch
        int     21h


;..................................
input: ; in dx - offset of location where put user input
        mov     ax, seg data
        mov     ds, ax
        mov     ah, 0ah
        int     21h
        ret
;..................................


;..................................
print: ; in dx - offset of text to print
        mov     ax, seg data
        mov     ds, ax
        mov     ah, 9           ; print msg ds:dx
        int     21h
        ret
;..................................
code ends


stack segment stack
	dw		300 dup(?)
	stack_ptr	dw ?
stack ends


end start