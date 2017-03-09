; Compiling command: nasm core.asm -f bin -o os.bin

[BITS 16]     ; 16-bit mode
[ORG 0x7C00]  ; easy

; Switching mode
MOV AH, 0
MOV AL, 0x13    ; VGA mode (320x200x8bit)
INT 0x10

MOV AX, 0A000h ; Video offset
MOV ES, AX

; Declaring loop label
endless_drawing:
mov ah, 0
int 0x16

mov ax, 0
call prepare_pixel  ; count new position
mov dl, 4           ; set color: red
call draw_pixel
inc bx              ; x ++

mov ax, 0
call prepare_pixel  ; count new position
mov dl, 1           ; set color: blue
call draw_pixel
inc bx              ; x ++

mov ax, 0
call prepare_pixel  ; count new position
mov dl, 2           ; set color: green
call draw_pixel
inc bx              ; x ++

jmp endless_drawing

; Function
prepare_pixel:
	MOV CX, 320
	MUL CX
	ADD AX, BX
	MOV DI, AX
	ret

; Function 
draw_pixel:
	MOV byte [ES:DI], dl
	RET

; Drawing squares
MOV BX, 0 ; start X
MOV AX, 0 ; start Y
	
jmp endless_drawing
JMP $

TIMES 510 - ($ - $$) db 0
DW 0xAA55