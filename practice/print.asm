data segment
data ends

code segment
start:
        mov     ax, seg stack
        mov     ss, ax
        mov     sp, offset pstack
                
        mov     dx, offset msg1
        call    print
        
        mov     dx, offset msg2
        call    print

        mov     al, 0
        mov     ah, 4ch ; end program
        int     21h
    
msg1    db "It works :)", 13, 10, "$"
msg2    db "no new line", "$"
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