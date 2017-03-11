
;*******************************************************
;
;	Stage2.asm
;		Stage2 Bootloader
;
;	OS Development Series
;*******************************************************

bits	16

org 0x500

jmp	main				; go to start

;*******************************************************
;	Preprocessor directives
;*******************************************************

; VGA memory is at 0xa000:0
%define VGA_SEG 0xa000

; Mode 13h width
%define VGA_MODE13_WIDTH 320

; Mode 13h height
%define VGA_MODE13_HEIGHT 200

;*******************************************************
;	Data Section
;*******************************************************

;---------------------------;
;	set video mode 13h		;
;---------------------------;
mode13h:
	mov	ah, 0
	mov al, 0x13
	int 0x10
	ret

;---------------------------;
;	get video mode			;
;---------------------------;
getMode:
	mov	ah, 0xf
	int 0x10
	ret
	
;---------------------------;
;	renders pixel			;
;	cl = color				;
;	ax = y					;
;	bx = x					;
;	es:bp = buffer			;
;---------------------------;
pixel:
; [x + y * width] = col

	pusha
	mov di, VGA_MODE13_WIDTH
	mul di ; ax = y * width
	add ax, bx ; add x
	mov di, ax
	mov byte [es:bp + di], cl ; plot pixel
	popa
	ret

;---------------------------;
;	clear screen
;	cl = color
;---------------------------;
clrscr:

	pusha
		mov dl, cl	; dx = 2 pixels
		mov dh, cl

		mov cx, 0
		xor di, di

	.l:
		mov word [es:bp + di], dx ; plot 2 pixels
		inc di ; go forward 2 bytes
		inc di
		inc cx
		cmp cx, (VGA_MODE13_WIDTH * VGA_MODE13_HEIGHT) / 2 ;end of display?
		jl .l

	popa
	ret

;---------------------------;
;	horz line
;	cl = color
;	ax = y
;	bx = start x
;	dx = width
;---------------------------;
line:

.a:
	call pixel

	inc bx ; increment x
	dec dx
	cmp dx, 0 ; line done?
	jg .a
	ret

;--------------------------;
;	main entry
;--------------------------;
main:

	;-------------------------------;
	;   Setup segments and stack	;
	;-------------------------------;

	cli							; clear interrupts
	xor		ax, ax				; null segments
	mov		ds, ax
	mov		es, ax
	mov		ax, 0x0000			; stack begins at 0x9000-0xffff
	mov		ss, ax
	mov		sp, 0xFFFF
	sti							; enable interrupts

	mov		ax, VGA_SEG
	mov		es, ax
	xor		ebp, ebp

; from here, es:bp=>video memory at 0xa000:0

; set video mode
	call	mode13h

; clear screen
	mov cl, 1
	call clrscr

; render pixels

; green rectangle

	mov dx, 0
.c
	push dx
	mov cl, 2
	mov ax, 5 ; y
	add ax, dx ; go to next line
	mov bx, 5 ; x
	mov dx, 20
	call line
	pop dx
	inc dx
	cmp dx, 10
	jl .c

; cyan rectangle

	mov dx, 0
.d
	push dx
	mov cl, 3
	mov ax, 20 ; y
	add ax, dx ; go to next line
	mov bx, 20 ; x
	mov dx, 20
	call line
	pop dx
	inc dx
	cmp dx, 10
	jl .d

; red rectangle

	mov dx, 0
.e
	push dx
	mov cl, 4
	mov ax, 100 ; y
	add ax, dx ; go to next line
	mov bx, 100 ; x
	mov dx, 20
	call line
	pop dx
	inc dx
	cmp dx, 20
	jl .e

; halt
	cli
	hlt
	.l jmp .l
