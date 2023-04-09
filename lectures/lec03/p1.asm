code1 segment
start1:
        mov     ax, seg stos1
        mov     ss, ax
        mov     sp, offset wstos1

        mov     al, 13h         ; 320x200 256 col
        mov     ah, 0           ; zmien tryb graficzny
        int     10h
        
        ;mov     word ptr cs:[x], 180
        ;mov     word ptr cs:[y], 60
        ;mov     byte ptr cs:[k], 14
        ;call    zapal_punkt
        
        ;mov     word ptr cs:[x], 130
        ;mov     word ptr cs:[y], 30
        ;mov     byte ptr cs:[k], 10
        ;call    zapal_punkt
        
        ;mov     word ptr cs:[x], 0
        ;mov     word ptr cs:[y], 50
        ;mov     byte ptr cs:[k], 13
        ;mov     word ptr cs:[a], 300
        ;call    linia
        
        mov     word ptr cs:[x], 0
        mov     word ptr cs:[y], 50
        mov     byte ptr cs:[k], 12

        mov     cx, 100
p0:     push    cx

        ;.............................
        mov     cx, 255
p1:     push    cx
        
        mov     al, byte ptr cs:[x]
        mov     byte ptr cs:[k], al
        call    zapal_punkt
        inc     word ptr cs:[x]

        pop     cx
        loop p1         ; cx = cx-1; if cx>0 then goto p1
        ;.............................

        mov     word ptr cs:[x], 0
        inc     word ptr cs:[y]

        pop     cx
        loop p0

        xor     ax, ax
        int     16h             ; czekaj na dowolny klawisz

        mov     al, 3h          ; tryb tekstowy
        mov     ah, 0           ; zmien tryb graficzny
        int     10h

        mov     ax, 4c00h       ; end program
        int     21h

;................................................................................
x       dw      ?
y       dw      ?
k       dw      ?
;.....................
zapal_punkt:
        mov     ax, 0a000h
        mov     es, ax
        mov     ax, word ptr cs:[y]
        mov     bx, 320
        mul     bx              ; ds:ax = AX * BX <=> ax = 320 * y
        mov     bx, word ptr cs:[x]
        add     bx, ax          ; bx = 320*y + x
        mov     al, byte ptr cs:[k]
        mov     byte ptr es:[bx], al
        ret

;................................................................................
a       dw      ?       ; długość lini
;....................
linia:
        mov     cx, word ptr cs:[a]
l1:     push    cx

        call    zapal_punkt
        inc     word ptr cs:[x]

        pop     cx
        loop l1         ; cx = cx-1; if cx>0 then goto p1
        ret

;................................................................................
code1 ends


stos1 segment stack
        dw      300 dup(?)
wstos1  dw      ?
stos1 ends


end start1