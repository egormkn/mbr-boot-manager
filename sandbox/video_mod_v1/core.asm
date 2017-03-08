; Compiling command: nasm core.asm -f bin -o os.bin

[BITS 16]
[ORG 0x7C00]

; Switching mode
MOV AH, 0
MOV AL, 0x13
INT 0x10

MOV AX, 0A000h ; Video offset
MOV ES, AX

; Drawing squares
MOV BX, 1 ; X
MOV AX, 1 ; Y
CALL prepare_screen
mov dl, 1
call draw_pixel

MOV BX, 2 ; X
MOV AX, 1 ; Y
CALL prepare_screen
mov dl, 1
call draw_pixel

MOV BX, 1 ; X
MOV AX, 2 ; Y
CALL prepare_screen
mov dl, 1
call draw_pixel

MOV BX, 2 ; X
MOV AX, 2 ; Y
CALL prepare_screen
mov dl, 1
call draw_pixel

;;;;;;;;;;;;;;;;;;;

MOV BX, 3 ; X
MOV AX, 1 ; Y
CALL prepare_screen
mov dl, 2
call draw_pixel

MOV BX, 3 ; X
MOV AX, 2 ; Y
CALL prepare_screen
mov dl, 2
call draw_pixel

MOV BX, 4 ; X
MOV AX, 1 ; Y
CALL prepare_screen
mov dl, 2
call draw_pixel

MOV BX, 4 ; X
MOV AX, 2 ; Y
CALL prepare_screen
mov dl, 2
call draw_pixel

;;;;;;;;;;;;;;;;;;;

MOV BX, 5 ; X
MOV AX, 1 ; Y
CALL prepare_screen
mov dl, 3
call draw_pixel

MOV BX, 5 ; X
MOV AX, 2 ; Y
CALL prepare_screen
mov dl, 3
call draw_pixel

MOV BX, 6 ; X
MOV AX, 1 ; Y
CALL prepare_screen
mov dl, 3
call draw_pixel

MOV BX, 6 ; X
MOV AX, 2 ; Y
CALL prepare_screen
mov dl, 3
call draw_pixel

;;;;;;;;;;;;;;;;;;;

MOV BX, 2 ; X
MOV AX, 4 ; Y
CALL prepare_screen
mov dl, 4
call draw_pixel

MOV BX, 6 ; X
MOV AX, 3 ; Y  <<< WTF if put value of 4
CALL prepare_screen
mov dl, 4
call draw_pixel

prepare_screen:
	MOV CX, 320
	MUL CX
	ADD AX, BX
	MOV DI, AX
	ret

draw_pixel:
	MOV [ES:DI], DL
	INT 0x10
	RET

JMP $

TIMES 510 - ($ - $$) db 0
DW 0xAA55