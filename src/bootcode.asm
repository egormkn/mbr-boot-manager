;**********************************************************;
;*                    x86 Bootloader                      *;
;*                                                        *;
;*             github.com/egormkn/bootloader              *;
;**********************************************************;



; Switching mode
mov ah, 0
mov al, 0x13    ; VGA mode (320x200x8bit)
int 0x10

mov ax, 0A000h ; Video offset
mov es, ax

mov cx, 0

loop:
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
	
	jmp loop
	
key_down_pressed:
	mov di, cx
	mov byte [es:di], 12 ; Red
	inc cx
	
	jmp loop

key_other_pressed:
      cli      ; Clear all Interrupts
      hlt      ; Halt system

