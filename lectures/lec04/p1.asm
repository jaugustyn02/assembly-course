code1 segment
start1:
        mov     ax, seg stos1
        mov     ss, ax
        mov     sp, offset wstos1

        mov     al, 3; tryb tekstowy
        mov     ah, 0; zmien tryb graficzny
        int     10h

        mov     ax, 0b800h
        mov     es, ax
        mov     si, 10*160 + 40*2

        mov     di, 0
        mov     cx, 2000
        mov     ah, 00001001b
        mov     al, 'o'
        cld
        rep stosw


p1:     in      al, 60h
        cmp     al, 1; ESC
        jz      koniec1
        
        cmp     al, byte ptr cs:[k1]
        jz      p1
        mov     byte ptr cs:[k1], al

        mov     byte ptr es:[si], ' '
        mov     byte ptr es:[si +1], 00001100b
                                    ;mrgbwrgb

        cmp     al, 75; left
        jnz     p2
        dec     si
        dec     si

p2:     cmp     al, 77; right
        jnz     p3
        inc     si
        inc     si

p3:     cmp     al, 72; up
        jnz     p4
        sub     si, 160

p4:     cmp     al, 80; down
        jnz     p5
        add     si, 160

p5:
        mov     byte ptr es:[si], 1; 'X'
        mov     byte ptr es:[si +1], 00001100b
                                    ;mrgbwrgb
                      
        jmp     p1


koniec1:
        mov     di, 0
        mov     cx, 2000
        mov     ah, 00000000b
        mov     al, ' '
        cld
        rep stosw

        mov     ax, 4c00h; end program
        int     21h


k1      db      0

code1 ends





stos1 segment stack
        dw      300 dup(?)
wstos1  dw      ?
stos1 ends


end start1