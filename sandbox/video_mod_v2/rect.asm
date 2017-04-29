bits 16
org 0x7C00

mov ax, 0x0013
int 0x10
	
mov ax, 0xA000 ;
mov es, ax

call draw_rect
ret

draw_rect:
	xor ecx, ecx
	mov dx, 2
	
	mov eax, 80
	push eax
	
	mov eax, 20
	push eax
	
	.inside_loop:
		cmp ecx, 200
		jnl exit
		
		;;;;;;;;;
		
		mov eax, ecx
		mov ebx, 20
		xor edx, edx
		div ebx
		
		mov edi, edx ; rest of division
		xor edx, edx
		
		pop ebx       ; read vertical offset
		add eax, ebx  ; add vertical offset
		push ebx
		
		mov ebx, 320
		mul ebx
		
		;;;;;;;;;
		
		xor ebx, ebx
		pop edx        ; read vertical offset
		pop ebx        ; read horizontal offset
		
		add eax, edi
		add eax, ebx
		
		push ebx       ; write horizontal offset
		push edx       ; write vertical offset
		
		mov dx, 2      ; color
		
		mov edi, eax
		mov [es:edi], dx
		inc ecx
		
		jmp .inside_loop
		
exit:
	ret

times 510 - ($ - $$) db 0
dw 0xAA55