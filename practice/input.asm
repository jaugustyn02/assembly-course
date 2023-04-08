data segment
data ends

code segment
start:
        mov     ax, seg stack
        mov     ss, ax
        mov     sp, offset pstack
                
        mov     ax, seg code
        mov     ds, ax
        mov     dx, offset buf
        mov     ah, 0ah
        int     21h
        
        ;mov     bp, offset buf +1
        ;mov     bl, byte ptr cs:[bp]
        ;add     bl, 1
        ;xor     bh, bh
        ;add     bp, bx
        ;mov     byte ptr cs:[bp], '$'

        mov     dx, offset endl
        call    print
        
        mov     dx, offset buf +2
        call    print           ; print input

        mov     al, 0
        mov     ah, 4ch ; end program
        int     21h
    
buf     db 10, ?, 20 dup('$')
endl    db 10, 13, '$'
;..................................
input: 
;..................................
;..................................
print: ; in dx = offset tekstu
        mov     ax, seg code
        mov     ds, ax
        mov     ah, 9   ; print msg ds:dx
        int     21h
        ret
;..................................
code ends

stack segment stack
	dw		300 dup(?)
	pstack	dw ?
stack ends


end start