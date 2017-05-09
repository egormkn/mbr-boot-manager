;********************************************************************;
;*                      x86 Master Boot Record                      *;
;*                                                                  *;
;*                   github.com/egormkn/bootloader                  *;
;********************************************************************;

; MUST READ: http://stackoverflow.com/questions/11174399/pc-boot-dl-register-and-drive-number

%define SIZE 512             ; MBR sector size (512 bytes)
%define BASE 0x7C00          ; Address at which BIOS will load MBR
%define DEST 0x0600          ; Address at which MBR should be copied
%define ENTRY_NUM 4          ; Number of partition entries
%define ENTRY_SIZE 16        ; Partition table entry size
%define DISK_ID 0x12345678   ; NT Drive Serial Number (4 bytes)

;********************************************************************;
;*                           NASM settings                          *;
;********************************************************************;

[BITS 16]                    ; Enable 16-bit real mode
[ORG BASE]                   ; Set the base address for MBR

;********************************************************************;
;*                         Prepare registers                        *;
;********************************************************************;

CLI
MOV SP, BASE                 ; Set Stack Pointer to BASE
XOR AX, AX                   ; Zero out the Accumulator register
MOV SS, AX                   ; Zero out Stack Segment register
MOV ES, AX                   ; Zero out Extra Segment register
MOV DS, AX                   ; Zero out Data Segment register

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

MOV AX, 0x0501               ; Set active display page to 0x01 (clear)
INT 0x10                     ; Switch display page (function 0x05)

MOV AX, 0x0600               ; Scroll window (0x00 lines => clear)
MOV BH, 0x87                 ; Color: red/cyan
MOV CX, 0x0000               ; Upper-left point (row: 0, column: 0)
MOV DX, 0x184F               ; Lower-right point (row: 24, column: 79)
INT 0x10                     ; Scroll up window (function 0x06)

MOV AX, 0x0103               ; Set cursor shape for video mode 0x03
MOV CX, 0x0105               ; Display lines 1-5 (max: 0-7)
INT 0x10                     ; Change cursor shape (function 0x01)

MOV AH, 0x02                 ; Set cursor position
MOV BH, 0x01                 ; Set page number to 0x01
MOV DX, 0x0505               ; Set row and column (starting from 0)
INT 0x10                     ; Move cursor

;********************************************************************;
;*                       Print Partition table                      *;
;********************************************************************;

MOV CX, ENTRY_NUM            ; Maximum of four entries as loop counter
MOV BP, 446 + DEST           ; Location of first entry in the table

FOR_PARTITIONS:              ; Loop for each partition entry
CALL PRINT_PARTITION         ; Print partition info (CX=i, BP=ptr)
ADD BP, ENTRY_SIZE           ; Switch to the next partition entry
LOOP FOR_PARTITIONS          ; Check next entry unless CX = 0

; MENU HERE
;MOV BP, 446 + DEST           ; DELETE THIS LATER
;JMP BOOT

; ax, bx, sp, di






mov cx, 0x0001  ; На всякий случай

main_loop:              ; Основная логика программы:
    call draw_screen    ; * Нарисовать
    xor ax, ax  ; Очищаем буфер
    int 0x16     ; Принимаем сигнал от Клавы
    
    cmp ax, 0x4800 ; up     Проверяем, что это стрелка вверх
    je move_select_up     ; Двигаем уголок вверх

    cmp ax, 0x5000 ; down   Проверяем, что это стрелка вниз
    je move_select_down   ; Двигаем уголок вниз
    
    jmp main_loop       ; Вечно повторить
    
;;;;;;;;;;;;;

move_select_up:      ; Аккуратно двигаем уголок вверх
    cmp cx, 1       ; Проверяем не на верху ли он
    jle move_select_up_ret  ; Уголок наверху, можно забить
    
    dec cx          ; Уменьшаем индекс
    move_select_up_ret:
    jmp main_loop             ; Завершаем обработку
    
move_select_down:    ; Аккуратно двигаем уголок вниз
    cmp cx, 4       ; Проверяем не внизу ли он
    jae move_select_down_ret  ; Уголок внизу, можно забить
    
    inc cx          ; Увеличиваем индекс
    move_select_down_ret:
    jmp main_loop             ; Завершаем обработку
    
    
draw_screen:               ; Рисуем полностью экран
        mov dl, 0x01  ; Фиксируем отступ каретки 0 по вертикали и 1 по горизонтали
        mov dh, cl      ; Меняем вертикальный отступ на посчитанный
        
        mov bh, 0x01    ; Указываем страницу
        mov ah, 0x02    ; Говорим, что будем двигать каретку
        int 0x10        ; Двигаем каретки
        
        ret      ; Завершаем рисовашки








; MENU HERE

INT 0x18                     ; Start ROM-BASIC or display an error
HALT: HLT
JMP HALT

;********************************************************************;
;*                    Print Partition subroutine                    *;
;********************************************************************;

PRINT_PARTITION:            ; CX = 4..1, BP = pointer
    MOV DL, 0x04   ; Фиксируем отступ каретки 0 по вертикали и 4 по горизонтали
                   ; DH = Row, DL = Column
    MOV DH, CL
    MOV BH, 0x01      ; BH = Page number
    MOV AH, 0x02      ; Set cursor position
    INT 0x10          ; Двигаем каретку

    MOV SI, NO_PARTITION_STR  ; Загружаем строчку
    CALL PRINT_STRING       ; Печатаем строчку
    
    MOV al, 0x30      ; Это 1
    ADD al, dh        ; Получаем истинный номер
    CALL PRINT_CHAR   ; Дописываем номер раздела
    RET
    
    
;PRINT_PARTITION:            ; CX = 4..1, BP = pointer
;    CMP BYTE [BP], 0
;    JZ NON_ACTIVE
;    MOV SI, ACTIVE_STR - BASE + DEST
;    CALL PRINT_STRING
;    JMP CONTINUE_PRINT
;    NON_ACTIVE:
;    MOV SI, NON_ACTIVE_STR - BASE + DEST
;    CALL PRINT_STRING
;    CONTINUE_PRINT:
;    MOV SI, NO_PARTITION_STR - BASE + DEST
;    CALL PRINT_STRING
;    MOV SI, LINE_BREAK - BASE + DEST
;    CALL PRINT_STRING
;    RET

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


;********************************************************************;
;*              Select the way of working with the disk             *;
;********************************************************************;

BOOT:
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

JB TRY_READ                  ; CF not cleared, no INT 13 Extensions
CMP BX, 0xAA55               ; Did contents of BX reverse?
JNZ TRY_READ                 ; BX not reversed, no INT 13 Extensions
TEST CX, 0x0001              ; Check functions support
JZ TRY_READ                  ; Bit 0 not set, no INT 13 Extensions
INC BYTE [BP+0x10]

TRY_READ:
PUSHAD                   ; Save all 32-bit Registers on the
                                            ; Stack in this order: eax, ecx,
                                            ; edx, ebx, esp, ebp, esi, edi.
CMP BYTE [BP+10],00  ;/ CoMPare [BP+10h] to zero;
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

MOV DX, [BP]                 ; Disk number given by BIOS; often 80h
XOR DH, DH                   ; Only DL part matters
JMP 0x0000:0x7C00            ; Jump to VBR

;********************************************************************;
;*                   Print String and Print Char                    *;
;********************************************************************;

PRINT_STRING:
    MOV BX, 0x7                 ; Display page 0, white on black
    LOAD_CHAR:
        LODSB                   ; Load character into AL from [SI]
        CMP AL, 0               ; Check for end of string
        JZ PRINT_STRING_RET     ; Return if string is printed
        CALL PRINT_CHAR
        JMP LOAD_CHAR           ; Go back for another character...
    PRINT_STRING_RET: RET

PRINT_CHAR:
    MOV AH, 0x0E            ; Character print function
    INT 0x10                ; Print character
    RET

;********************************************************************;
;*                             Strings                              *;
;********************************************************************;

NO_PARTITION_STR: DB "Partition ", 0
ACTIVE_STR: DB "A ", 0
NON_ACTIVE_STR: DB "NA ", 0
BOOT_FROM_1: DB "ERR1", 0
BOOT_FROM_2: DB "ERR2", 0
BOOT_FROM_3: DB "ERR3", 0
BOOT_FROM_4: DB "Run ", 0
LINE_BREAK: DB 0x0D, 0x0A, 0

;********************************************************************;
;*                    Fill other bytes with 0x00                    *;
;********************************************************************;

TIMES 440 - ($ - $$) DB 0x00                ; Fill the rest with 0x00

;********************************************************************;
;*                          NT Disk Number                          *;
;********************************************************************;

DD DISK_ID                                  ; NT Drive Serial Number
DW 0x0000                                   ; Padding

;********************************************************************;
;*                          Partition Table                         *;
;********************************************************************;

TABLE_SIZE: EQU (ENTRY_NUM * ENTRY_SIZE)    ; Should be 4*16 = 64
TABLE_OFFSET: EQU (SIZE - TABLE_SIZE - 2)   ; Should be 512-64-2 = 446

TIMES TABLE_SIZE DB 0x00                    ; Zero out partition table
DB 0x55, 0xAA                               ; Mark sector as bootable