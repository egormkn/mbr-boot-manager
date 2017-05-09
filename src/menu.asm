bits 16
org 0x7C00

;; init
mov ax, 0x0501
int 0x10

;; body
xor cx, cx

main_loop:
	call draw_screen
	call key_listener
	call move_select
	
	jmp main_loop

;; final
mov dx, 0x0801
mov bh, 0x01
mov ah, 0x02
int 0x10

ret

key_listener:
	xor ax, ax
	int 0x16
	
	ret
	
move_select:
	cmp ax, 0x4800 ; up
	je move_select_up

	cmp ax, 0x5000 ; down
	je move_select_down
	
	ret

move_select_up:
	cmp cx, 0
	jle just_return
	
	dec cx
	ret
	
move_select_down:
	cmp cx, 1
	jae just_return
	
	inc cx
	ret
	
just_return:
	ret

draw_screen:
	mov ax, 0x0600
	mov bh, 0x07
	int 0x10

	mov dx, 0x0101
	mov bh, 0x01
	mov ah, 0x02
	int 0x10

	mov edx, title_string
	call print_string
	
	mov dx, 0x0305
	mov bh, 0x01
	mov ah, 0x02
	int 0x10
	
	mov edx, part_first_name
	call print_string
	
	mov dx, 0x0505
	mov bh, 0x01
	mov ah, 0x02
	int 0x10
	
	mov edx, part_second_name
	call print_string
	
	mov dx, 0x0002
	mov al, cl
	mov bl, 2
	mul bl
	
	add al, 3
	add dh, al
	
	mov bh, 0x01
	mov ah, 0x02
	int 0x10
	
	mov al, ">"
	call print_char
	
	ret

print_char:
	mov ah, 0x0E
	int 0x10
	ret

print_string:
	mov al, [edx]
	inc edx
	
	or al, al
	jz print_stop
	call print_char
	jmp print_string
	
	ret
	
print_stop:
	ret
	
title_string db "Select section to boot:", 0
part_first_name db "Partition 0", 0
part_second_name db "Partition 1", 0

times 510 - ($ - $$) db 0
dw 0xAA55