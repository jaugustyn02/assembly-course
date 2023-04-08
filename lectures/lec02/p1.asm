code1 segment
start1:
        nop
        nop
        nop
        
        mov     al, 24
        mov     al, byte ptr ds:[24]
        mov     al, byte ptr es:[24]
        mov     al, byte ptr cs:[24]
        mov     al, byte ptr ss:[24]

        mov     byte ptr ds:[24], 12

        nop
        nop
        nop


        mov     ax, seg stos1
        mov     ss, ax
        mov     sp, offset wstos1

        ;PSP ds: offset 80h 81h 82h - ilość znaków | znak ' ' | początek znaków

        mov     ax, seg lin_c
        mov     es, ax
        mov     si, 082h
        mov     di, offset lin_c
        xor     cx, cx                  ; mov cx, 0
        mov     cl, byte ptr ds:[080h]  ; cx - ilość znaków           
        
p1:     push    cx
        mov     al, byte ptr ds:[si]
        mov     byte ptr es:[di], al
        inc     si
        inc     di

        pop     cx
        loop    p1      ; cx = cx-1;    czy cx==0 ?;      if not 0 then goto p1; else idz dalej
        mov     byte ptr es:[di], '$'

        mov     dx, offset lin_c
        call    wypisz


;        mov     dx, offset t1
;        call    wypisz

;        mov     dx, offset t2
;        call    wypisz


;        mov     ax, seg code1
;        mov     ds, ax
;        mov     dx, offset buf1
;        mov     ah, 0ah
;        int     21h


;        mov     bp, offset buf1 +1
;        mov     bl, byte ptr cs:[bp]
;        add     bl, 1
;        xor     bh, bh                  ; mov     bh, 0
;        add     bp, bx
;        mov     byte ptr cs:[bp], '$'


;        mov     dx, offset nl1
;        call    wypisz

;        mov     dx, offset buf1 +2
;        call    wypisz


        mov     al, 0
        mov     ah, 4ch         ; end program
        int     21h

nl1     db 10, 13, '$'
t1      db "111111111", 10, 13, "$"
t2      db "222222222$"
buf1    db 10, ?, 20 dup('$')
lin_c   db 200 dup('$')

;..........................................
wypisz: ; in dx - offset tekstu
        mov     ax, seg code1
        mov     ds, ax
        mov     ah, 9           ; wypisz tekst ds:dx
        int     21h
        ret
;..........................................


code1 ends


stos1 segment stack
        dw      300 dup(?)
wstos1  dw      ?
stos1 ends


end start1