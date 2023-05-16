        .387

code1 segment
start1:
        mov     ax, seg stos1
        mov     ss, ax
        mov     sp, offset wstos1

        mov     al, 13h         ; 320x200 256 col
        mov     ah, 0           ; zmien tryb graficzny
        int     10h
        
        mov     word ptr cs:[x], 0
        mov     word ptr cs:[y], 0
        mov     byte ptr cs:[k], 12
        
p0:
        call    clr_screen

        mov     cx, 320
p1:     push    cx
        call    sinus
        call    zapal_punkt
        inc     word ptr cs:[x]
        pop     cx
        loop    p1
        mov     word ptr cs:[x], 0

ppp1:
        in      al, 60h
        cmp     al, 1; ESC
        jz      koniec1
        
        cmp     al, byte ptr cs:[k1]
        jz      ppp1
        mov     byte ptr cs:[k1], al

cmp     al, 75; left
        jnz     p2
        dec     word ptr cs:[dziel]
p2:     cmp     al, 77; right
        jnz     p3
        inc     word ptr cs:[dziel]
p3:     cmp     al, 72; up
        jnz     p4
        inc     word ptr cs:[amp]
p4:     cmp     al, 80; down
        jnz     p5
        dec     word ptr cs:[amp]
p5:                   
        jmp     p0


koniec1:

        xor     ax, ax
        int     16h             ; czekaj na dowolny klawisz

        mov     al, 3h          ; tryb tekstowy
        mov     ah, 0           ; zmien tryb graficzny
        int     10h

        mov     ax, 4c00h       ; end program
        int     21h

k1      db      0
;................................................................................
dziel   dw      10
amp     dw      10
jeden   dw      15

sinus:
        finit
        fild    word ptr cs:[x]
        ;fild    word ptr cs:[dziel]
        ;fdiv
        fidiv   word ptr cs:[dziel]
        fsin
        ;fld1    ; wrzuc na stos 1
        fiadd    word ptr cs:[jeden]
        ;fild    word ptr cs:[amp]
        ;fmul
        fimul   word ptr cs:[amp]
        fist    word ptr cs:[y]
        ret
;................................................................................
clr_screen:
        mov     ax, 0a000h
        mov     es, ax
        xor     ax, ax
        mov     di, ax
        cld             ; di = di+1
        mov     cx, 320*200
        rep stosb       ; byte ptr es:[di], al ; di = di+1 ; dopoki cs <> 0
        ret
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
code1 ends


stos1 segment stack
        dw      300 dup(?)
wstos1  dw      ?
stos1 ends


end start1