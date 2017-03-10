; Compiling command: nasm core.asm -f bin -o os.bin

[BITS 16]     ; 16-bit mode
[ORG 0x7C00]  ; easy

; Switching mode
mov ah, 0
mov al, 0x13    ; VGA mode (320x200x8bit)
int 0x10

mov ax, 0A000h ; Video offset
mov es, ax

mov cx, 0

start:
	mov ah, 0
	int 0x16
	
	cmp ah, 72 ; UP key code
	je  key_up_pressed ; Jump if equal
	
	cmp ah, 80 ; DOWN key code
	je  key_down_pressed  ; Jump if equal
	jne key_other_pressed ; Very important to do negative check
	
key_up_pressed:
	mov di, cx
	mov byte [es:di], 14 ; Yellow
	inc cx
	
	jmp start
	
key_down_pressed:
	mov di, cx
	mov byte [es:di], 12 ; Red
	inc cx
	
	jmp start

key_other_pressed:
	mov di, cx
	mov byte [es:di], 10 ; Green
	inc cx 
	
	jmp start

jmp start
JMP $

TIMES 510 - ($ - $$) db 0
DW 0xAA55