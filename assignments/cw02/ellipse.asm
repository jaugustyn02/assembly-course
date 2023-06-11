        .387 ; use coprocessor

code segment
start:
        ; stack segment assignment:
        mov     ax, seg stack
        mov     ss, ax
        mov     sp, offset stack_ptr

        call    read_arguments

        call    validate_arguments

        call    ellipse_rendering

exit:
        mov     ax, 4c00h
        int     21h

;.................................Arguments......................................
arg_buffer      db      200 dup('$')
bytes_left      dw      ?
nums            dw      2 dup(0)
usage_error_msg db      'Usage: ellipse.exe <dx> <dy>', 13, '$'
args_error_msg  db      'Error: Argument is out of range: (0 <= dx, dy < 200)', 13, '$'
;-----------------------------------------------------
; PSP ds: 80h, 81h, 82h - size, ' ', arguments
read_arguments:

        mov     ax, seg arg_buffer
        mov     es, ax
        mov     si, 082h
        mov     di, offset nums

        ; read number of bytes to read
        mov     word ptr cs:[bytes_left], 0
        mov     al, byte ptr ds:[080h]
        dec     al ; - 1 for '$'
        mov     byte ptr cs:[bytes_left], al

        ; check if there are at least 3 characters (num1 + ' ' + num2)
        cmp     word ptr cs:[bytes_left], 3
        jb      throw_usage_error

        mov     cx, 2 ; numbers to read
;..................................>
loop6:  push    cx
        mov     cx, word ptr cs:[bytes_left]
        call    skip_whitespaces
;.................>
loop4:
        mov     al, byte ptr ds:[si]

        ; check if character is a whitespace
        cmp     al, ' '
        jz      loop4_end

        ; check if character is a digit
        cmp     al, '0'
        jb      throw_usage_error
        cmp     al, '9'
        ja      throw_usage_error

        ; read number
        
        ; num = num * 10
        mov     ax, word ptr cs:[di]
        mov     bx, 10
        mul     bx
        mov     word ptr cs:[di], ax

        ; num = num + (al - '0')
        mov     ah, 0 
        mov     al, byte ptr ds:[si]
        sub     al, '0'
        add     word ptr cs:[di], ax

        inc     si
        loop    loop4
;.................<
loop4_end:
        mov     word ptr cs:[bytes_left], cx
        add     di, 2 ; next number (2 bytes)
        pop     cx
        loop    loop6
;..................................<
loop6_end:
        mov      ax, word ptr cs:[nums]
        mov      bl, 2
        div      bl
        mov      word ptr cs:[nums], 0
        mov      byte ptr cs:[nums], al
        mov      ax, word ptr cs:[nums + 2]
        div      bl
        mov      word ptr cs:[nums + 2], 0
        mov      byte ptr cs:[nums + 2], al

        mov      ax, word ptr cs:[nums]
        mov      word ptr cs:[a], ax
        mov      ax, word ptr cs:[nums + 2]
        mov      word ptr cs:[b], ax
        ret
;-----------------------------------------------------
skip_whitespaces:
loop5:
        mov     al, byte ptr ds:[si]
        cmp     al, ' '
        jnz     loop5_end

        inc     si
        loop    loop5
loop5_end:
        ret
;-----------------------------------------------------
validate_arguments:
        mov     ax, word ptr cs:[a]
        cmp     ax, 100
        jae     throw_args_error
        cmp     ax, 0
        jb      throw_args_error

        mov     ax, word ptr cs:[b]
        cmp     ax, 100
        jae     throw_args_error
        cmp     ax, 0
        jb      throw_args_error
        ret
;-----------------------------------------------------
throw_usage_error:
        mov     dx, offset usage_error_msg
        call    print
        jmp     exit
;-----------------------------------------------------
throw_args_error:
        mov     dx, offset args_error_msg
        call    print
        jmp     exit
;-----------------------------------------------------
print: ; in dx - txt offset
        mov     ax, seg code
        mov     ds, ax
        mov     ah, 9
        int     21h
        ret
;-----------------------------------------------------

;.................................KeysInput......................................
selected_color  db      9
last_key        db      0
a               dw      ? ; in range [0, 160)
b               dw      ? ; in range [0, 100)
clear_switch    db      0 ; 0 - clear screen, 1 - don't clear screen
;-----------------------------------------------------
ellipse_rendering: ; in a, b - ellipse parameters

        mov     al, 13h         ; 320x200 256 colors
        mov     ah, 0           ; change video mode
        int     10h

main_loop:
        ; check if clear_switch is 0
if_5:   cmp     byte ptr cs:[clear_switch], 0
        jnz     else_2
        call    clear_screen
else_2:
        call    draw_elipse

loop1:  in      al, 60h
        cmp     al, 1; ESC
        jz      main_loop_end

        cmp     al, byte ptr cs:[last_key]
        jz      loop1
        mov     byte ptr cs:[last_key], al

if_1:   cmp     al, 75; left arrow key
        jnz     elif_1

        ; check if a > 0
        cmp word ptr cs:[a], 0
        jle     loop1

        dec     word ptr cs:[a]
        jmp     main_loop

elif_1: cmp     al, 77; right arrow key
        jnz     elif_2

        ; check if a < 159
        cmp     word ptr cs:[a], 159
        jge     loop1

        inc     word ptr cs:[a]
        jmp     main_loop

elif_2: cmp     al, 72; up arrow key
        jnz     elif_3

        ; check if b < 99
        cmp     word ptr cs:[b], 99
        jge    loop1

        inc     word ptr cs:[b]
        jmp     main_loop

elif_3: cmp     al, 80; down arrow key
        jnz     elif_4

        ; check if b > 0
        cmp     word ptr cs:[b], 0
        jle     loop1

        dec     word ptr cs:[b]
        jmp     main_loop

elif_4: cmp     al, 2; '1' key 
        jnz     elif_5
        mov     byte ptr cs:[selected_color], 9 ; blue
        jmp     main_loop

elif_5: cmp     al, 3; '2' key
        jnz     elif_6
        mov     byte ptr cs:[selected_color], 2 ; green
        jmp     main_loop

elif_6: cmp     al, 4; '3' key
        jnz     elif_7
        mov     byte ptr cs:[selected_color], 4 ; red
        jmp     main_loop

elif_7: cmp     al, 5; '4' key
        jnz     elif_8
        mov     byte ptr cs:[selected_color], 13 ; purple
        jmp     main_loop

elif_8: cmp     al, 19; 'r' key
        jnz     elif_9
        mov     ax, word ptr cs:[nums]
        mov     word ptr cs:[a], ax
        mov     ax, word ptr cs:[nums + 2]
        mov     word ptr cs:[b], ax
        jmp     main_loop

elif_9: cmp     al, 46; 'c' key
        jnz     else_1

        push    ax
        xor     ax, ax
        mov     al, byte ptr cs:[clear_switch]
        inc     ax
        mov     bl, 2
        div     bl
        mov     byte ptr cs:[clear_switch], ah ; rest of division
        pop     ax

        jmp     main_loop
else_1:
        jmp     loop1

main_loop_end:
        mov     al, 3h          ; text mode
        mov     ah, 0           ; change video mode
        int     10h
        ret
;-----------------------------------------------------

;.................................Drawing.......................................
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
draw_elipse:; in: a, b, x_center, y_center

; ```drawing elipse using mid point (Bresenham's) algorithm```

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


end start
