;********************************************************************;
;*                      x86 Master Boot Record                      *;
;*                                                                  *;
;*                   github.com/egormkn/bootloader                  *;
;********************************************************************;

; Microsoft Windows 7+ MBR
; See http://thestarman.narod.ru/asm/mbr/W7MBR.htm

%define HOME 0x7C00         ; Address at which BIOS will load the code
%define DEST 0x0600         ; Address at which MBR should be copied
%define SIZE 512            ; MBR sector size (default: 512 bytes)
%define ENTRY_SIZE 16       ; Partition table entry size

;********************************************************************;
;*                           NASM settings                          *;
;********************************************************************;

[BITS 16]                   ; NASM directive that enables 16-bit mode

[ORG HOME]                  ; NASM directive that specifies the memory
                            ;  address at which program will be loaded

;********************************************************************;
;*                         Prepare registers                        *;
;********************************************************************;

XOR AX, AX                  ; Zero out the Accumulator register
MOV SS, AX                  ; Zero out Stack Segment register
MOV SP, HOME                ; Set Stack Pointer to HOME
MOV ES, AX                  ; Zero out Extra Segment register
MOV DS, AX                  ; Zero out Data Segment register

;********************************************************************;
;*                  Copy MBR to DEST and jump there                 *;
;********************************************************************;

MOV SI, HOME                ; Source Index to copy code from
MOV DI, DEST                ; Destination Index to copy code to
MOV CX, SIZE                ; Number of bytes to be copied

CLD                         ; Clear Direction Flag
REP MOVSB                   ; Repeat MOVSB instruction for CX times

PUSH AX                     ; Set up Segment(AX) and Offset(DI)
PUSH DEST + SKIP            ;  for jump to 0000:061C
RETF                        ; Jump to copied code skipping part above

SKIP: EQU ($ - $$)          ; Go here in copied code

;********************************************************************;
;*                   Check for an Active partition                  *;
;********************************************************************;

STI                         ; Enable interrupts
MOV CX, 4                   ; Maximum of four entries as loop counter
MOV BP, TABLE               ; Location of first entry in the table

FIND_ACTIVE:
CMP BYTE [BP+00], 0         ; Subtract 0 from first byte of entry at 
                            ; SS:[BP+00]. Anything from 80h to FFh has
                            ; 1 in highest bit (Sign Flag will be set)

JL CHECK_PARTITION          ; Active partition found (SF set), check
JNZ SHOW_ERROR              ; Active flag is not zero, show an error
                            ; Otherwise, we found a zero, check other

ADD BP, ENTRY_SIZE          ; Switch to the next partition entry
LOOP FIND_ACTIVE            ; Check next entry unless CL = 0
INT 0x18                    ; Start ROM-BASIC or display an error

;********************************************************************;
;*               Check if active partition is bootable              *;
;********************************************************************;

; TODO

CHECK_PARTITION:
MOV [BP+00], DL             ; DL is already set to 80h (Presumably by PC's BIOS.)
times 260 db 0xFF
SHOW_ERROR:
MOV [BP+00], DL

TABLE: EQU DEST + 446

;********************************************************************;
;*                              Footer                              *;
;********************************************************************;

TIMES 510 - ($ - $$) DB 0                    ; Fill other bytes with 0
DW 0xAA55                                    ; Mark sector as bootable