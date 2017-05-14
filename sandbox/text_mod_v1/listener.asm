[BITS 16]
[ORG 0x7C00]

STI                          ; Enable interrupts

MOV AX, 0x0003               ; Set video mode to 0x03 (80x25, 4-bit)
INT 0x10                     ; Change video mode (function 0x00)

MOV AX, 0x0501               ; Set active display page to 0x01 (clear)
INT 0x10                     ; Switch display page (function 0x05)

MOV AX, 0x0600               ; Scroll window (0x00 lines => clear)
MOV BH, 0x87                 ; Color: red/cyan
MOV CX, 0x0000               ; Upper-left point (row: 0, column: 0)
MOV DX, 0x184F               ; Lower-right point (row: 24, column: 79)
INT 0x10                     ; Scroll up window (function 0x06)

init:
	jmp main_loop
	
main_loop:
	call wait_input
	call print_input_char
	
	jmp main_loop
	
wait_input:
	xor ax, ax
	int 0x16
	
	ret
	
print_input_char:
	cmp al, 0x0D        ; Enter key (13d)
	je .print_enter
	
	cmp al, 0x08        ; Backspace key (8d)
	je .print_backspace
	
	cmp al, 0x48        ; Left arrow (75d)
	je .move_left
	
	mov ah, 0x0E
	int 0x10
	
	ret

	.print_enter:
		mov ah, 0x0E
		mov al, 0x0D
		int 0x10
		
		mov al, 0x0A
		int 0x10
		
		ret
		
	.print_backspace:
		mov al, 0x08
		int 0x10
		
		mov al, 0x20
		int 0x10
		
		mov al, 0x08
		int 0x10
		
		ret
		
	.move_left:
		mov al, 0x08
		int 0x10
		
		ret
	
jmp init

TIMES 510 - ($ - $$) db 0
DW 0xAA55