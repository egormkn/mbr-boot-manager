;********************************************************************;
;*                      x86 Master Boot Record                      *;
;*                                                                  *;
;*                   github.com/egormkn/bootloader                  *;
;********************************************************************;

%define SIZE 512             ; MBR sector size (512 bytes)
%define BASE 0x7C00          ; Address at which BIOS will load MBR
%define DEST 0x0600          ; Address at which MBR should be copied

%define ENTRY_NUM 4          ; Number of partition entries
%define ENTRY_SIZE 16        ; Partition table entry size
%define DISK_ID 0x12345678   ; NT Drive Serial Number (4 bytes)

%define TOP 8                ; Padding from the top
%define LEFT 32              ; Padding from the left
%define COLOR 0x02           ; Background and text color

;********************************************************************;
;*                           NASM settings                          *;
;********************************************************************;

[BITS 16]                    ; Enable 16-bit real mode
[ORG BASE]                   ; Set the base address for MBR

;********************************************************************;
;*                         Prepare registers                        *;
;********************************************************************;

CLI                          ; Clear interrupts

MOV SP, BASE                 ; Set Stack Pointer to BASE
XOR AX, AX                   ; Zero out the Accumulator register
MOV SS, AX                   ; Zero out Stack Segment register
MOV ES, AX                   ; Zero out Extra Segment register
MOV DS, AX                   ; Zero out Data Segment register
PUSH DX                      ; Save DX value passed by BIOS

;********************************************************************;
;*                  Copy MBR to DEST and jump there                 *;
;********************************************************************;

MOV SI, BASE                 ; Source Index to copy code from
MOV DI, DEST                 ; Destination Index to copy code to
MOV CX, SIZE                 ; Number of bytes to be copied
CLD                          ; Clear Direction Flag (move forward)
REP MOVSB                    ; Repeat MOVSB instruction for CX times
JMP SKIP + DEST              ; Jump to copied code skipping part above

SKIP: EQU ($ - $$)           ; Go here in copied code

;********************************************************************;
;*                        Set BIOS video mode                       *;
;********************************************************************;

STI                          ; Enable interrupts

MOV AX, 0x0003               ; Set video mode to 0x03 (80x25, 4-bit)
INT 0x10                     ; Change video mode (function 0x00)
                             ; Destroyed: AX, SP, BP, SI, DI

MOV AX, 0x0600               ; Scroll window (0x00 lines => clear)
MOV BH, COLOR                ; Background and text color
MOV CX, 0x0000               ; Upper-left point (row: 0, column: 0)
MOV DX, 0x184F               ; Lower-right point (row: 24, column: 79)
INT 0x10                     ; Scroll up window (function 0x06)
                             ; Destroyed: AX, SP, BP, SI, DI

MOV AX, 0x0103               ; Set cursor shape for video mode 0x03
MOV CX, 0x0105               ; Display lines 1-5 (max: 0-7)
INT 0x10                     ; Change cursor shape (function 0x01)
                             ; Destroyed: AX, SP, BP, SI, DI

;********************************************************************;
;*                       Print Partition table                      *;
;********************************************************************;

MOV CX, ENTRY_NUM            ; Maximum of four entries as loop counter
MOV BP, 494 + DEST           ; Location of last entry in the table
MOV BL, 0x00                 ; Index of the first active partition

FOR_PARTITIONS:              ; Loop for each partition entry (4 to 1)
    PUSH BP                  ; Save BP state
    
    CMP BYTE [BP], 0         ; Check for active state of partition
    JNL NOT_ACTIVE           ; Partition is not active, skip
    MOV BL, CL               ; Save index of active partition
    
    NOT_ACTIVE:              ; Go here if partition is not active
    MOV AH, 0x02             ; Set cursor position
    MOV BH, 0x00             ; Set page number to 0x00
    MOV DX, TOP*0x100+LEFT+2 ; DH = row, DL = column
    ADD DH, CL               ; Change the row according to CL
    INT 0x10                 ; Change cursor position (function 0x02)
                             ; Destroyed: AX, SP, BP, SI, DI
                             
    MOV SI, PARTITION_STR    ; Print partition title
    CALL PRINT_STRING        ; Call printing routine
    MOV AL, 0x30             ; Put ASCII code for 0 to AL
    ADD AL, CL               ; Get partition number ASCII code
    CALL PRINT_CHAR          ; Print partition number
                             ; Destroyed: AX, BH
                             
    CMP BL, CL               ; Compare current partition with active
    JNE SKIP_ACTIVE_LABEL    ; If current is not active, skip printing
    MOV SI, ACTIVE_STR       ; Print partition title
    CALL PRINT_STRING        ; Call printing routine
    
    SKIP_ACTIVE_LABEL:       ; Go here to skip printing of "active"
    POP BP                   ; Restore BP state
    SUB BP, ENTRY_SIZE       ; Switch to the previous partition entry
    LOOP FOR_PARTITIONS      ; Print another entry unless CX = 0

;********************************************************************;
;*                  Skip menu if Shift key pressed                  *;
;********************************************************************;

MOV AH, 0x02                 ; Get the shift status of the keyboard
INT 0x16                     ; Get flags of keyboard state to AL
AND AL, 0x03                 ; AND bitmask for left and right shift
CMP AL, 0x00                 ; Check for shift keys
JNE BOOT_4                   ; Skip menu if shift key pressed

;********************************************************************;
;*                         Display boot menu                        *;
;********************************************************************;

CMP BYTE BL, 0x00            ; Check if we found an active partition
JNE MENU_LOOP                ; If there is one, display menu
MOV BL, 0x01                 ; If not, set cursor to first entry

MENU_LOOP:                   ; Menu loop
    MOV AH, 0x02             ; Set cursor position
    MOV BH, 0x00             ; Set page number to 0x00
    MOV DX, TOP*0x100+LEFT   ; DH = row, DL = column
    ADD DH, BL               ; Change the row according to BL
    INT 0x10                 ; Change cursor position (function 0x02)
                             ; Destroyed: AX, SP, BP, SI, DI

    MOV AH, 0x00             ; Read key code from keyboard
    INT 0x16                 ; Get key code (function 0x00)
    
    CMP AX, 0x4800           ; Check for UP arrow
    JE MOVE_UP               ; Move selection up

    CMP AX, 0x5000           ; Check for DOWN arrow
    JE MOVE_DOWN             ; Move selection down
    
    CMP AX, 0x011B           ; Check for Esc key
    JE REBOOT                ; Reboot
    
    CMP AX, 0x1C0D           ; Check for Enter key
    JE BOOT_4                ; Boot from selected partition
    
    JMP MENU_LOOP            ; Read another key
    
;********************************************************************;
;*                         Boot menu routines                       *;
;********************************************************************;

MOVE_UP:                     ; Move cursor up
    CMP BL, 0x01             ; Check if cursor is at the first entry
    JLE MOVE_UP_RET          ; If it is, do nothing
    DEC BL                   ; Move it up by decrementing index
    MOVE_UP_RET:             
    JMP MENU_LOOP            ; Return to menu loop
    
MOVE_DOWN:                   ; Move cursor down
    CMP BL, 0x04             ; Check if cursor is at the last entry
    JAE MOVE_DOWN_RET        ; If it is, do nothing
    INC BL                   ; Move it up by decrementing index
    MOVE_DOWN_RET:
    JMP MENU_LOOP            ; Return to menu loop

;********************************************************************;
;*                    Print Partition subroutine                    *;
;********************************************************************;

; TODO: Rewrite this block in a more efficient way

BOOT_1:
    MOV SI, BOOT_FROM_1 - BASE + DEST
    CALL PRINT_STRING
    JMP HALT
BOOT_2:
    MOV SI, BOOT_FROM_2 - BASE + DEST
    CALL PRINT_STRING
    JMP HALT
BOOT_3:
    MOV SI, BOOT_FROM_3 - BASE + DEST
    CALL PRINT_STRING
    JMP HALT
BOOT_4:
    MOV SI, BOOT_FROM_4 - BASE + DEST
    CALL PRINT_STRING
    MOV BP, 446 + DEST

REBOOT:
    MOV AX, 0x0600               ; Scroll window (0x00 lines => clear)
    MOV BH, 0x02                 ; Color: black/green
    MOV CX, 0x0000               ; Upper-left point (row: 0, column: 0)
    MOV DX, 0x184F               ; Lower-right point (row: 24, column: 79)
    INT 0x10                     ; Scroll up window (function 0x06)
    INT 0x19
    INT 0x18                     ; Start ROM-BASIC or display an error
    HALT: HLT
    JMP HALT

;********************************************************************;
;*              Select the way of working with the disk             *;
;********************************************************************;

; TODO: Link this code from Win7 MBR to menu above

BOOT:
;MOV BP, 446 + DEST           ; Location of last entry in the table
;MOV AL, 4
;SUB AL, CL
;MOV BL, 16
;MUL BL
;ADD BP, AX
MOV [BP], DL
PUSH BP                     ; Save Base Pointer on Stack
MOV BYTE [BP+0x11], 5       ; Number of attempts of reading the disk
MOV BYTE [BP+0x10], 0       ; Used as a flag for the INT13 Extensions

MOV AH, 0x41                 ;/ INT13h BIOS Extensions check
MOV BX, 0x55AA               ;| AH = 0x41, BX = 0x55AA,
INT 0x13                     ;| DL = BIOS disk number (HDD1 = 0x80)
                             ;| If CF flag cleared and [BX] changes to 
                             ;| 0xAA55, they are installed
                             ;| Major version is in AH: 01h=1.x; 
                             ;| 20h=2.0/EDD-1.0; 21h=2.1/EDD-1.1; 
                             ;| 30h=EDD-3.0.
                             ;| CX = API subset support bitmap. 
                             ;| If bit 0 is set, extended disk access 
                             ;| functions (AH=42h-44h,47h,48h) are 
                             ;| supported. Only if no extended support 
                             ;\ is available, will it fail TEST
POP BP
JB TRY_READ                  ; CF not cleared, no INT 13 Extensions
CMP BX, 0xAA55               ; Did contents of BX reverse?
JNZ TRY_READ                 ; BX not reversed, no INT 13 Extensions
TEST CX, 0x0001              ; Check functions support
JZ TRY_READ                  ; Bit 0 not set, no INT 13 Extensions
INC BYTE [BP+0x10]

TRY_READ:
PUSHAD                       ; Save all 32-bit Registers on the
                                            ; Stack in this order: eax, ecx,
                                            ; edx, ebx, esp, ebp, esi, edi.
CMP BYTE [BP+10],00            ;/ CoMPare [BP+10h] to zero;
JZ INT13_BASIC                 ;\ if 0, can't use Extensions.

;********************************************************************;
;*                 Read VBR with INT13 Extended Read                *;
;********************************************************************;

; The following code uses INT 13, Function 42h ("Extended Read")
; by first pushing the "Disk Address Packet" onto the Stack in 
; reverse order of how it will read the data
;
; Offset Size	       Description of DISK ADDRESS PACKET's Contents
; ------ -----  ------------------------------------------------------
;   00h  BYTE	Size of packet (10h or 18h; 16 or 24 bytes).
;   01h  BYTE	Reserved (00).
;   02h  WORD	Number of blocks to transfer (Only 1 sector for us)
;   04h  DWORD	Points to -> Transfer Buffer (00007C00 for us).
;   08h  QWORD	Starting Absolute Sector (get from Partition Table:
;                (00000000 + DWORD PTR [BP+08]). Remember, the 
;                Partition Table Preceding Sectors entry can only be 
;                a max. of 32 bits!
;   10h  QWORD   (EDD-3.0, optional) 64-bit flat address of transfer 
;                buffer; only used if DWORD at 04h is FFFF:FFFF


PUSH STRICT DWORD 0x0       ; Push 4 zero-bytes (32-bits) onto
                            ; Stack to pad VBR's Starting Sector
PUSH STRICT DWORD [BP+0x08] ; Location of VBR Sector
PUSH STRICT 0x0             ; \ Segment then Offset parts, so:
PUSH STRICT 0x7C00          ; / Copy Sector to 0x7c00 in Memory
PUSH STRICT 0x0001          ;   Copy only 1 sector
PUSH STRICT 0x0010          ; Reserved and Packet Size (16 bytes)
MOV AH, 0x42                ; Function 42h
MOV DL, [BP]                ; Drive Number
MOV SI, SP                  ; DS:SI must point to Disk Address Packet
INT 0x13                    ; Try to get VBR Sector from disk

; If successful, CF is cleared (0) and AH set to 00h.
; If any errors, CF is set to 1    and AH = error code. In either case, 
; DAP's block count field is set to number of blocks actually transferred

LAHF                        ; Load Status flags into AH.
ADD SP, 0x10                ; Effectively removes all the DAP bytes
                            ; from Stack by changing Stack Pointer.
SAHF                        ; Save AH into flags register, so we do
                            ;  not change Status flags by doing so!
JMP READ_SECTOR

;********************************************************************;
;*                 Read VBR without INT13 Extensions                *;
;********************************************************************;

INT13_BASIC:
MOV AX, 0x0201              ; Function 02h, read only 1 sector
MOV BX, 0x7C00              ; Buffer for read starts at 7C00
MOV DL, [BP+00]             ; DL = Disk Drive
MOV DH, [BP+01]             ; DH = Head number (never use FFh).
MOV CL, [BP+02]             ; Bits 0-5 of CL (max. value 3Fh)
                            ; make up the Sector number.
MOV CH, [BP+03]             ; Bits 6-7 of CL become highest two
                            ; bits (8-9) with bits 0-7 of CH to
                            ; make Cylinder number (max. 3FFh).
INT 0x13                    ; INT13, Function 02h: READ SECTORS
                            ; into Memory at ES:BX (0000:7C00).

; Whether Extensions are installed or not, both routines end up here:

READ_SECTOR:
POPAD                       ; Restore all 32-bit Registers from
                            ; the Stack, which we saved at 0659.
JNB LABEL1
DEC BYTE [BP+0x11]          ; Begins with 05h from 0638.
JNZ LABEL2                  ; If 0, tried 5 times to read
                            ; VBR Sector from disk drive.
CMP BYTE [BP+00],0x80  
JZ BOOT_2            ;  -> "Error loading operating system"
MOV    DL, 0x80
JMP    BOOT_1

LABEL2:
PUSH BP
XOR AH, AH
MOV DL, [BP+00]
INT 0x13

POP BP
JMP TRY_READ

LABEL1:
CMP WORD [0x7DFE], 0xAA55
JNZ BOOT_3           ; If we don't see it, Error!
                            ; -> "Missing operating system"

;********************************************************************;
;*                        Jump to loaded VBR                        *;
;********************************************************************;

;MOV DX, [BP]                 ; Disk number given by BIOS; often 80h
POP DX          ; From [BP+00] at 06C3; often 80h.
XOR DH, DH                   ; Only DL part matters
JMP 0x0000:0x7C00            ; Jump to VBR

;********************************************************************;
;*                   Print String and Print Char                    *;
;********************************************************************;

; ===== PRINT_STRING =====
; SI: string with 0-end
; BH: page (text mode only)
; BL: color (graphics mode)
PRINT_STRING:                ; Changes: SI, AX, BX (BH in text mode)
    MOV BH, 0x00             ; Set display page to 0
    LOAD_CHAR:               ; Print all characters in loop
        LODSB                ; Load character into AL from [SI]
        CMP AL, 0x00         ; Check for end of string
        JZ PRINT_STRING_RET  ; Return if string is printed
        CALL PRINT_CHAR      ; Print character
        JMP LOAD_CHAR        ; Go for another character
    PRINT_STRING_RET: RET    ; Return

; ====== PRINT_CHAR ======
; AL: ASCII character code
; BH: page (text mode only)
; BL: color (graphics mode)
PRINT_CHAR:                  ; Changes: AH
    MOV AH, 0x0E             ; Character print function
    INT 0x10                 ; Print character
    RET                      ; Return

;********************************************************************;
;*                             Strings                              *;
;********************************************************************;

PARTITION_STR: DB "Partition ", 0
ACTIVE_STR: DB " (A)", 0
BOOT_FROM_1: DB "E1", 0
BOOT_FROM_2: DB "E2", 0
BOOT_FROM_3: DB "E3", 0
BOOT_FROM_4: DB "Run ", 0

;********************************************************************;
;*                    Fill other bytes with 0x00                    *;
;********************************************************************;

TIMES 440 - ($ - $$) DB 0x00                ; Fill the rest with 0x00

;********************************************************************;
;*                          NT Disk Number                          *;
;********************************************************************;

DD DISK_ID                                  ; NT Drive Serial Number
DW 0x0000                                   ; Padding (must be 0x0000)

;********************************************************************;
;*                          Partition Table                         *;
;********************************************************************;

TABLE_SIZE: EQU (ENTRY_NUM * ENTRY_SIZE)    ; Should be 4*16 = 64
TABLE_OFFSET: EQU (SIZE - TABLE_SIZE - 2)   ; Should be 512-64-2 = 446

TIMES TABLE_SIZE DB 0x00                    ; Zero out partition table
DB 0x55, 0xAA                               ; Mark sector as bootable