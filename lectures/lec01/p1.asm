dane1 segment
t1      db "To jest tekst! $"
dane1 ends


code1 segment
start1:
        mov     ax, seg stos1
        mov     ss, ax
        mov     sp, offset wstos1
        
        
        mov     ax, seg t1
        mov     ds, ax
        mov     dx, offset t1
        mov     ah, 9           ; wypisz tekst ds:dx
        int     21h


        mov     al, 0
        mov     ah, 4ch         ; end program
        int     21h

code1 ends


stos1 segment stack
        dw      300 dup(?)
wstos1  dw      ?
stos1 ends


end start1