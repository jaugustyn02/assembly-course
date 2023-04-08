data segment
	msg	db "Hello World! $"
data ends


code segment
start:
	mov	ax, seg stack
	mov	ss, ax
	mov	sp, offset pstack

	mov 	ax, seg msg
	mov 	ds,ax
	mov 	dx,offset msg
	mov 	ah,9
	int	21h

	mov al,0
	mov ah,4ch
	int 21h

code ends


stack segment stack
	dw		300 dup(?)
	pstack	dw ?
stack ends


end start
