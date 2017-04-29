;
; Function that draws rectangle on screen
;
; Problems:
; * stack isn't cleared after function
;

bits 16    ; 16-bit mode
org 0x7C00 ; addresses offset

; switch graphics mode to VGA
mov ax, 0x0013
int 0x10

; make video offset
mov ax, 0xA000 
mov es, ax

; here should be arguments in future
call draw_rect ; call for the function
ret            ; finish programm

draw_rect:
	xor ecx, ecx ; set counter to 0
	
	mov eax, 80  ; top offset of rectangle
	push eax
	
	mov eax, 60  ; left offset of rectangle
	push eax
	
	.inside_loop:
		cmp ecx, 200 ; the number of pixels
		jnl exit     ; jump to exit if ecx >= 200
		
		;; division part ;;
		
		mov eax, ecx ; eax = eax / ebx
		mov ebx, 20   ; width of rectangle
		xor edx, edx ; edx = eax % ebx - must be 0 before devision
		div ebx      ; call for devision
		
		mov edi, edx ; save rest of division
		xor edx, edx  ; edx = 0
		
		pop ebx       ; read vertical offset
		add eax, ebx  ; add vertical offset
		push ebx      ; push back vertical offset for next iteration
		
		mov ebx, 320  ; skip screen lines (320 - width of screen - const)
		mul ebx       ; make multiplication
		
		;; final part ;;
		
		xor ebx, ebx   ; ebx = 0
		pop edx        ; read vertical offset
		pop ebx        ; read horizontal offset
		
		add eax, edi   ; make offset due to division
		add eax, ebx   ; make horizontal offset
		
		push ebx       ; write horizontal offset
		push edx       ; write vertical offset
		
		mov dx, 2      ; color (2 = green)
		
		mov edi, eax      ; save pixel location
		mov [es:edi], dx  ; coloring this pixal
		inc ecx            ; increase counter
		
		jmp .inside_loop  ; do again
		
exit:
	ret ; return to previous call instruction

times 510 - ($ - $$) db 0  ; filling the rest of file with 0
dw 0xAA55 ; special instruction of BIOS