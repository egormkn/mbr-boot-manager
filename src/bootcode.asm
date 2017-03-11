;********************************************************************;
;*                    x86 Bootloader (boot code)                    *;
;*                                                                  *;
;*                  github.com/egormkn/bootloader                   *;
;********************************************************************;

xor	ax, ax		; Setup segments to insure they are 0. Remember that
mov	ds, ax		; we have ORG 0x7c00. This means all addresses are based
mov	es, ax		; from 0x7c00:0. Because the data segments are within the same
				; code segment, null em.

mov	si, msg
call	Print

cli			; Clear all Interrupts
hlt			; halt the system

msg	db	"Welcome to My Operating System!", 0


;************************************************;
;	Prints a string
;	DS=>SI: 0 terminated string
;************************************************;
Print:
	lodsb						; load next byte from string from SI to AL
	or	al, al					; Does AL=0? (current character)
	jz	PrintDone				; Yep, null terminator found-bail out
	mov	ah, 0eh					; Nope-get next character
	int	10h
	jmp	Print					; Repeat until null terminator found
PrintDone:
	ret						; we are done, so return