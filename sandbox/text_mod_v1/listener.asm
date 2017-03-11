[BITS 16]
[ORG 0x7C00]

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