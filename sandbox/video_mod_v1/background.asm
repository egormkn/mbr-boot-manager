; Compile with nasm -f bin -o os.bin background.ams
;
; SOME PROBLEMS:
; * In some period of time not very big
; bottom line stops it's updating (may be
; it's caused by emulator)
; * Some strange last pixel if set bounds
; less than 200 px in heihgt
;

[BITS 16]    ; 16-bit mode
[ORG 0x7C00] ; Loading section

%DEFINE SCREEN_WIDTH  320 ; Screen width 
%DEFINE SCREEN_HEIGHT 200 ; Screen heihgt

%DEFINE KEY_UP   72 ; Key UP   code
%DEFINE KEY_DOWN 80 ; Key DOWN code

init:
	; Switching video mode to VGA
	mov ax, 0x0013
	int 0x10
	
	mov ax, 0A000h ; Make video offset
	mov es, ax
	
	jmp key_listener
	
key_listener:
	mov ah, 0 ; Clearing AH register
	int 0x16  ; Waiting for user input
	
	mov bl, 0           ; Array pointer to 0 color
	cmp ah, KEY_UP      ; Check if it is an UP key
	je fill_background   ; Go to painting
	
	inc bl              ; Array pointer to 1 color
	cmp ah, KEY_DOWN    ; Check if it is an DOWN key
	je fill_background   ; Go to painting
	
	inc bl               ; Array pointer to 2 color
	jmp fill_background  ; Go to painting
	
fill_background:
	mov ecx, 0                  ; Make counter to 0
	mov dx, [colors + bx * 1]  ; Set color for drawing
	jmp .inside_loop            ; Srarting drawing
	
	.inside_loop:
		mov edi, ecx      ; Pixel coordinate 
		mov [es:edi], dx  ; Draw pixel with DX color
		inc ecx            ; Go to next pixel
		
		cmp ecx, SCREEN_WIDTH * SCREEN_HEIGHT ; Check if all pixel drawn
		jl .inside_loop                        ; If not then continue
		
	jmp key_listener ; Return to listener for a keys

jmp init ; Starting our programm

; Declaring array of colors
colors:
	db 14 ; Nice yellow
	db 12 ; Nice red
	db 10 ; Nice green

TIMES 510 - ($ - $$) db 0 ; Clearing another space
DW 0xAA55 ; First command address