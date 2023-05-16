        .387                    ; use coprocessor

code segment
start:
        ; stack segment assignment:
        mov     ax, seg stack
        mov     ss, ax
        mov     sp, offset stack_ptr

        mov     al, 13h         ; 320x200 256 col
        mov     ah, 0           ; zmien tryb graficzny
        int     10h
        
        call    main_loop

exit:
        mov     al, 3h          ; tryb tekstowy
        mov     ah, 0           ; zmien tryb graficzny
        int     10h

        mov     ax, 4c00h
        int     21h

;.................................key_input......................................
selected_color  db      1
last_key        db      0
a               dw      50
b               dw      75
;-----------------------------------------------------
main_loop:
        call    clear_screen
        call    draw_elipse

loop1:  in      al, 60h
        cmp     al, 1; ESC
        jz      main_loop_end

        cmp     al, byte ptr cs:[last_key]
        jz      loop1
        mov     byte ptr cs:[last_key], al

if_1:   cmp     al, 75; left
        jnz     elif_1
        dec     word ptr cs:[a]
        jmp     else_1

elif_1: cmp     al, 77; right
        jnz     elif_2
        inc     word ptr cs:[a]
        jmp     else_1

elif_2: cmp     al, 72; up
        jnz     elif_3
        inc     word ptr cs:[b]
        jmp     else_1

elif_3: cmp     al, 80; down
        jnz     elif_4
        dec     word ptr cs:[b]
        jmp     else_1

elif_4: cmp     al, 2; 1
        jnz     elif_5
        mov     byte ptr cs:[selected_color], 1
        jmp     else_1

elif_5: cmp     al, 3; 2
        jnz     elif_6
        mov     byte ptr cs:[selected_color], 14
        jmp     else_1

elif_6: cmp     al, 4; 3
        jnz     else_1
        mov     byte ptr cs:[selected_color], 4

else_1:
        jmp     main_loop

main_loop_end:
        call    clear_screen
        ret

;.................................drawing......................................
x_center        dw      159
y_center        dw      99
x_draw          dw      ?
y_draw          dw      ?
x       dw      ?
y       dw      ?
d       dd      ?
d_x     dd      ?
d_y     dd      ?
a2      dw      ?
b2      dw      ?
four    dw      4
tmp     dd      ?
color   db      ?
;-----------------------------------------------------
draw_elipse: ; drawing elipse using mid point algorithm, in: a, b, x_center, y_center

        ; use selected color
        mov     al, byte ptr cs:[selected_color]
        mov     byte ptr cs:[color], al

        ; x = 0
        mov     word ptr cs:[x], 0

        ; y = b
        mov     ax, word ptr cs:[b]
        mov     word ptr cs:[y], ax

        ; a2 = a^2
        mov     ax, word ptr cs:[a]
        mul     ax
        mov     word ptr cs:[a2], ax

        ; b2 = b^2
        mov     ax, word ptr cs:[b]
        mul     ax
        mov     word ptr cs:[b2], ax

        finit

        ; d = b^2 - a^2*b + a^2/4
        fild    word ptr cs:[b2]
        fild    word ptr cs:[a2]
        fimul   word ptr cs:[b]
        fsub
        fild    word ptr cs:[a2]
        fidiv   word ptr cs:[four]
        fadd
        fst     real4 ptr cs:[d]
        
        ; d_x = 2*b^2*x
        fild    word ptr cs:[b2]
        fiadd   word ptr cs:[b2]
        fimul   word ptr cs:[x]
        fist    dword ptr cs:[d_x]

        ; d_y = 2*a^2*y
        fild    word ptr cs:[a2]
        fiadd   word ptr cs:[a2]
        fimul   word ptr cs:[y]
        fist    dword ptr cs:[d_y]

loop2: ; while dx < dy
        finit

        ; cmp d_x, d_y
        fild    dword ptr cs:[d_y]
        fild    dword ptr cs:[d_x]
        fcom    st(1)
        fstsw   word ptr cs:[tmp]
        mov     ax, word ptr cs:[tmp]
        sahf
        fstp    st(0)
        fstp    st(0)

        ; jump if d_x >= d_y to loop2_end
        jae     loop2_end

        call    draw_symmetric_points

        ; x++
        inc     word ptr cs:[x]

        ; d_x = d_x + 2*b^2
        fild     dword ptr cs:[d_x]
        fiadd    word ptr cs:[b2]
        fiadd    word ptr cs:[b2]     
        fist     dword ptr cs:[d_x]

if_4:   fldz
        fld     real4 ptr cs:[d]
        fcom    st(1)
        fstsw   word ptr cs:[tmp]
        mov     ax, word ptr cs:[tmp]
        sahf
        fstp    st(0)
        fstp    st(0)

        ; jump if d < 0 to else_4
        jb      else_4

        ; y--
        dec     word ptr cs:[y]

        ; d_y = d_y - 2*a^2
        fild    dword ptr cs:[d_y]
        fisub   word ptr cs:[a2]
        fisub   word ptr cs:[a2]
        fist    dword ptr cs:[d_y]

        ; d = d - d_y
        fld     real4 ptr cs:[d]
        fisub   dword ptr cs:[d_y]
        fst     real4 ptr cs:[d]

else_4:
        ; d = d + d_x + b^2
        fld      real4 ptr cs:[d]
        fiadd    dword ptr cs:[d_x]
        fiadd    word ptr cs:[b2]
        fst      real4 ptr cs:[d]

        jmp    loop2
loop2_end:

        ; d = b^2(x+0.5)^2 + a^2(y-1)^2 - a^2*b^2
        fild    word ptr cs:[x]
        fld1
        mov     word ptr cs:[tmp], 2
        fidiv   word ptr cs:[tmp]
        fadd
        fmul    st(0), st(0)
        fimul   word ptr cs:[b2]

        fild    word ptr cs:[y]
        fld1
        fsub
        fmul    st(0), st(0)
        fimul   word ptr cs:[a2]
        fadd

        fild    word ptr cs:[a2]
        fimul   word ptr cs:[b2]
        fsub

        fst     real4 ptr cs:[d]

loop3: ; while y >= 0
        finit

        ; cmp y, 0
        fild    word ptr cs:[y]
        fldz
        fcom    st(1)
        fstsw   word ptr cs:[tmp]
        mov    ax, word ptr cs:[tmp]
        sahf
        fstp   st(0)
        fstp   st(0)
        ; jump if y < 0 to loop3_end
        ja     loop3_end
        
        call   draw_symmetric_points

        ; --y
        dec    word ptr cs:[y]

        ; d_y = d_y - 2*a^2
        fild   dword ptr cs:[d_y]
        fisub  word ptr cs:[a2]
        fisub  word ptr cs:[a2]
        fist   dword ptr cs:[d_y]

        ; d = d - d_y + a^2
        fld    real4 ptr cs:[d]
        fisub  dword ptr cs:[d_y]
        fiadd  word ptr cs:[a2]
        fst    real4 ptr cs:[d]

        ; cmp d, 0
        fldz
        fld    real4 ptr cs:[d]
        fcom   st(1)
        fstsw  word ptr cs:[tmp]
        mov    ax, word ptr cs:[tmp]
        sahf
        fstp   st(0)
        fstp   st(0)
        ; jump if d > 0 to else_5
        ja     else_5

        ; x++
        inc    word ptr cs:[x]

        ; d_x = d_x + 2*b^2
        fild   dword ptr cs:[d_x]
        fiadd  word ptr cs:[b2]
        fiadd  word ptr cs:[b2]
        fist   dword ptr cs:[d_x]

        ; d = d + d_x
        fld    real4 ptr cs:[d]
        fiadd  dword ptr cs:[d_x]
        fst    real4 ptr cs:[d] 

else_5:
        jmp    loop3

loop3_end:
        ret
;-----------------------------------------------------
draw_symmetric_points:

        ; draw upper right point
        mov     ax, word ptr cs:[x]
        mov     word ptr cs:[x_draw], ax
        mov     ax, word ptr cs:[x_center]
        add     word ptr cs:[x_draw], ax

        mov     ax, word ptr cs:[y_center]
        mov     word ptr cs:[y_draw], ax
        mov     ax, word ptr cs:[y]
        sub     word ptr cs:[y_draw], ax

        call    draw_point

        ; draw lower right point
        mov     ax, word ptr cs:[y]
        mov     word ptr cs:[y_draw], ax
        mov     ax, word ptr cs:[y_center]
        add     word ptr cs:[y_draw], ax

        call    draw_point

        ; draw lower left point
        mov     ax, word ptr cs:[x_center]
        mov     word ptr cs:[x_draw], ax  
        mov     ax, word ptr cs:[x]
        sub     word ptr cs:[x_draw], ax

        call    draw_point

        ; draw upper left point
        mov     ax, word ptr cs:[y_center]
        mov     word ptr cs:[y_draw], ax
        mov     ax, word ptr cs:[y]
        sub     word ptr cs:[y_draw], ax

        call    draw_point

        ret
;-----------------------------------------------------
draw_point:
        mov     ax, 0a000h
        mov     es, ax
        mov     ax, word ptr cs:[y_draw]
        mov     bx, 320
        mul     bx              ; ds:ax = AX * BX <=> ax = 320 * y_draw
        mov     bx, word ptr cs:[x_draw]
        add     bx, ax          ; bx = 320 * y_draw + x_draw
        mov     al, byte ptr cs:[color]
        mov     byte ptr es:[bx], al
        ret
;-----------------------------------------------------
clear_screen:
        mov     ax, 0a000h
        mov     es, ax
        xor     ax, ax
        mov     di, ax
        cld     ; di = di+1
        mov     cx, 320*200
        rep     stosb
        ret
;-----------------------------------------------------
code ends


stack segment stack
	dw	        300 dup(?)
	stack_ptr	dw ?
stack ends

data segment
data ends


end start

;.................>
;.................<
;..................................>
;..................................<
;-----------------------------------------------------