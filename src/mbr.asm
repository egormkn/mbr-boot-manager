;********************************************************************;
;*                      x86 Master Boot Record                      *;
;*                                                                  *;
;*                   github.com/egormkn/bootloader                  *;
;********************************************************************;

; Microsoft Windows 7+ MBR
; See http://thestarman.narod.ru/asm/mbr/W7MBR.htm

%define BASE 0x7C00         ; Address at which BIOS will load MBR
%define DEST 0x0600         ; Address at which MBR should be copied
%define SIZE 512            ; MBR sector size (default: 512 bytes)
%define ENTRY_SIZE 16       ; Partition table entry size
%define DISK_ID 0x00000000  ; NT Drive Serial Number

;********************************************************************;
;*                           NASM settings                          *;
;********************************************************************;

[BITS 16]                   ; Enable 16-bit real mode
[ORG BASE]                  ; Set the base address for MBR

;********************************************************************;
;*                         Prepare registers                        *;
;********************************************************************;

XOR AX, AX                  ; Zero out the Accumulator register
MOV SS, AX                  ; Zero out Stack Segment register
MOV SP, BASE                ; Set Stack Pointer to BASE
MOV ES, AX                  ; Zero out Extra Segment register
MOV DS, AX                  ; Zero out Data Segment register

;********************************************************************;
;*                  Copy MBR to DEST and jump there                 *;
;********************************************************************;

MOV SI, BASE                ; Source Index to copy code from
MOV DI, DEST                ; Destination Index to copy code to
MOV CX, SIZE                ; Number of bytes to be copied

CLD                         ; Clear Direction Flag
REP MOVSB                   ; Repeat MOVSB instruction for CX times

PUSH AX                     ; Push continuation address to stack
PUSH DEST + SKIP            ;  to jump to SKIP in the copied code
RETF                        ; Jump to copied code skipping part above

SKIP: EQU ($ - $$)          ; Go here in copied code

;********************************************************************;
;*                   Check for an Active partition                  *;
;********************************************************************;

STI                         ; Enable interrupts
MOV CX, 4                   ; Maximum of four entries as loop counter
MOV BP, TABLE               ; Location of first entry in the table

FIND_ACTIVE:                ; / LOOP
CMP BYTE [BP], 0            ; Subtract 0 from first byte of entry at 
                            ; SS:[BP]. Anything from 80h to FFh has 1
                            ; in highest bit (Sign Flag will be set)

JL BOOT_PARTITION           ; Active partition found (SF set), boot
;JNZ SHOW_ERROR              ; Active flag is not zero, show an error
DB 0x0F, 0x85, 0x0E, 0x01                            ; Otherwise, we found a zero, check other

ADD BP, ENTRY_SIZE          ; Switch to the next partition entry
LOOP FIND_ACTIVE            ; Check next entry unless CL = 0
                            ; \ LOOP

INT 0x18                    ; Start ROM-BASIC or display an error

BOOT_PARTITION:             ; Boot from selected partition, BP holds the entry pointer

;********************************************************************;
;*              Select the way of working with the disk             *;
;********************************************************************;

MOV [BP], DL                ; DL is already set to 80h by BIOS, 
                            ; used as disk number (first HDD = 80h)
PUSH BP                     ; Save Base Pointer on Stack
MOV BYTE [BP+0x11], 5       ; Data storage for possible use by instruction at 069F
MOV BYTE [BP+0x10], 0       ; Used as a flag and/or counter for the 
                            ; INT13 Extensions being installed (see 0656 and 065B below).

MOV AH, 0x41                ;/ INT13h BIOS Extensions check
MOV BX, 0x55AA              ;| AH = 41h, BX = 55AAh, DL = 80h
INT 0x13                    ;| If CF flag cleared and [BX] changes to AA55h, they are installed;  Major
                            ;| version is in AH: 01h=1.x; 20h=2.0/EDD-1.0; 21h=2.1/EDD-1.1; 30h=EDD-3.0.
                            ;| CX = API subset support bitmap. If bit 0 is set (CX = 1, 3, 5, etc.; 'odd'),
                            ;|      then extended disk access functions (AH=42h-44h,47h,48h) are supported.
                            ;\      Only if no extended support is available, will it fail TEST at 0650.

POP BP                      ; Get back original Base Pointer.
JB LABEL                    ; Below? If so, CF=1 (not cleared)
                            ;   so no INT 13 Ext. & do jump!
CMP BX, 0xAA55              ; Did contents of BX change?  If
JNZ LABEL                   ;   not, jump to offset 0659.
TEST CX, 0001               ; Final test for INT 13 Extensions!
                            ; If bit 0 not set, this will fail,
JZ LABEL                    ;   then we jump over next line...
INC BYTE [BP+0x10]          ; or increase [BP+10h] by one.

LABEL:
PUSHAD                      ; Save all 32-bit Registers on the stack 
                            ; (EAX, ECX, EDX, EBX, ESP, EBP, ESI, EDI)

CMP BYTE [BP+0x10], 00      ;/ Compare [BP+0x10] to zero;
JZ INT13_BASIC              ;\ if 0, can't use Extensions.

;********************************************************************;
;*               Check if active partition is bootable              *;
;********************************************************************;















; The following code uses INT 13, Function 42h ("Extended Read") to read the
; first sector (VBR) of the bootable partition into Memory at location 0x7c00.
; It does this by first pushing what's called the "Disk Address Packet" onto
; the Stack in reverse order of how it will read the data, so 00h (Reserved)
; and 10h bytes are the last to be pushed onto the Stack at location 0674:
;
; Offset Size	       Description of DISK ADDRESS PACKET's Contents
; ------ -----  ------------------------------------------------------------
;   00h	 BYTE	Size of packet (10h or 18h; 16 or 24 bytes).
;   01h	 BYTE	Reserved (00).
;   02h	 WORD	Number of blocks to transfer (Only 1 sector for this code).
;   04h	 DWORD	Points to -> Transfer Buffer (0000 7C00 for this code).
;   08h	 QWORD	Starting Absolute Sector (get from Partition Table entry:
;               (00000000 + DWORD PTR [BP+08]). Remember, the Partition
;               Table Preceding Sectors entry can only be a max. of 32 bits!
;   10h	 QWORD  NOT USED HERE. (EDD-3.0; optional) 64-bit flat address
;               of transfer buffer; only used if DWORD at 04h is FFFF:FFFF.

PUSH STRICT DWORD 0x0  ; Push 4 zero-bytes (32-bits) onto
                  ; Stack to pad VBR's Starting Sector.
PUSH    DWORD  [BP+0x08]   ; Location of VBR Sector.
PUSH    STRICT 0x0      ; \ Segment then Offset parts, so:
PUSH   STRICT 0x7C00      ; / Copy Sector to 0x7c00 in Memory.
PUSH   STRICT 0001      ;   Copy only 1 sector.
PUSH   STRICT 0x0010      ; Reserved and Packet Size (16 bytes).
MOV     AH,0x42      ; Function 42h.
MOV     DL,[BP+00] ; Drive Number.
MOV     SI,SP      ; DS:SI must point to -> "Disk
                                        ;        Address Packet" on Stack.
INT     0x13         ; Try to get VBR Sector from disk.

; If successful, CF (Carry Flag) is cleared (0) and AH set to 00h.
; If any errors, CF              is set to 1    and AH = error code. In either
; case, DAP's block count field is set to number of blocks actually transferred.

LAHF                ; Load Status flags into AH.
ADD    SP,0x10       ; Effectively removes all the DAP bytes
                                       ; from Stack by changing Stack Pointer.
SAHF                ; Save AH into flags register, so we do
                                       ;  not change Status flags by doing so!
JMP    READ_SECTOR

; The MBR uses the standard INT 13 "Read Sectors" function here, because
; no INT 13 Extended functions were found in the BIOS code above (065F):

INT13_BASIC:
MOV    AX,0x0201      ; Function 02h, read only 1 sector.
MOV    BX, 0x7C00      ; Buffer for read starts at 7C00.
MOV    DL,[BP+00]   ; DL = Disk Drive
MOV    DH,[BP+01]   ; DH = Head number (never use FFh).
MOV    CL,[BP+02]   ; Bits 0-5 of CL (max. value 3Fh)
                                       ; make up the Sector number.
MOV    CH,[BP+03]   ; Bits 6-7 of CL become highest two
                                       ; bits (8-9) with bits 0-7 of CH to
                                       ; make Cylinder number (max. 3FFh).
INT    0x13           ; INT13, Function 02h: READ SECTORS
                                       ; into Memory at ES:BX (0000:7C00).

;The following code is missing some comments, but all the instructions are here for you to study.

; Whether Extensions are installed or not, both routines end up here:

READ_SECTOR:
POPAD               ; Restore all 32-bit Registers from
                                       ; the Stack, which we saved at 0659.
JNB    LABEL1
DEC    BYTE [BP+0x11]     ; Begins with 05h from 0638.
JNZ    LABEL2                 ; If 0, tried 5 times to read
                                               ; VBR Sector from disk drive.
CMP    BYTE [BP+00],0x80  
DB 0x0F, 0x84, 0x8A, 0x00;JZ     0x0736                 ;  -> "Error loading

                                               
                                                                                                                                             ;   operating system"
MOV    DL,80
JMP    BOOT_PARTITION

LABEL2:
PUSH   BP
XOR    AH,AH
MOV    DL,[BP+00]
INT    0x13

POP    BP
JMP    LABEL

LABEL1:
CMP    WORD [0x7DFE], 0xAA55
JNZ    0x0731           ; If we don't see it, Error!
                      ; -> "Missing operating system"
PUSH   WORD [BP] ; Popped into DL again at 0727
                 ; (contains 80h if 1st drive).





;
;; =====================================================================
;;   All of the code from 06C6 through 0726 is related to discovering if
;; TPM version 1.2 interface support is operational on the system, since
;; it could be used by  BitLocker for validating the integrity of a PC's
;; early startup components before allowing the OS to boot. The spec for
;; the TPM code below states "There MUST be no requirement placed on the
;; A20 state on entry to these INT 1Ah functions." (p.83) We assume here
;; Microsoft understood this to mean access to memory over 1 MiB must be
;; made available before entering any of the TPM's INT 1Ah functions.
;
;; The following code is actually a method for gaining access to Memory
;; locations above 1 MiB (also known as enabling the A20 address line).
;;
;; Each address line allows the CPU to access ( 2 ^ n ) bytes of memory:
;; A0 through A15 can give access to 2^16 = 64 KiB. The A20 line allows
;; a jump from 2^20 (1 MiB) to 2^21 = 2 MiB in accessible memory.  But
;; our computers are constructed such that simply enabling the A20 line
;; also allows access to any available memory over 1 MiB if both the CPU
;; and code can handle it (once outside of "Real Mode"). Note: With only
;; a few minor differences, this code at 06C6-06E1 and the Subroutine at
;; 0756 ff. are the same as rather old sources we found on the Net.
;
;06C6 E88D00        CALL   0756
;06C9 7517          JNZ    06E2
;
;06CB FA            CLI           ; Clear IF, so CPU ignores maskable interrupts.
;06CC B0D1          MOV    AL,D1
;06CE E664          OUT    64,AL
;06D0 E88300        CALL   0756
;
;06D3 B0DF          MOV    AL,DF
;06D5 E660          OUT    60,AL
;06D7 E87C00        CALL   0756
;
;06DA B0FF          MOV    AL,FF
;06DC E664          OUT    64,AL
;06DE E87500        CALL   0756
;06E1 FB            STI           ; Set IF, so CPU can respond to maskable interrupts
;                                 ; again, after the next instruction is executed.
;
;; Comments below checked with the document, "TCG PC Client Specific
;; Implementation Specification For Conventional BIOS" (Version 1.20
;; FINAL/Revision 1.00/July 13, 2005/For TPM Family 1.2; Level 2), §
;; 12.5, pages 85 ff.  TCG and "TCG BIOS DOS Test Tool" (MSDN).
;
;06E2 B800BB        MOV    AX,BB00   ; With AH = BBh and AL = 00h
;06E5 CD1A          INT    1A        ; Int 1A ->  TCG_StatusCheck
;
;06E7 6623C0      * AND    EAX,EAX  ;/   If EAX does not equal zero,
;06EA 753B          JNZ    0727     ;\ then no BIOS support for TCG.
;
;06EC 6681FB544350+  * CMP  EBX,41504354   ; EBX must also return ..
;                                         ; the numerical equivalent
;; of the ASCII character string "TCPA" ("54 43 50 41") as a further
;; check. (Note: Since hex numbers are stored in reverse order on PC
;; media or in Memory, a TPM BIOS would put 41504354h in EBX.)
;
;06F3 7532             JNZ    0727       ;  If not, exit TCG code.
;06F5 81F90201         CMP    CX,0102    ; Version 1.2 or higher ?
;06F9 722C             JB     0727       ;  If not, exit TCG code.
;
;; If TPM 1.2 found, perform a: "TCG_CompactHashLogExtendEvent".
;
;06FB 666807BB0000   * PUSH   0000BB07   ; Setup for INT 1Ah AH = BB,
;                                        ; AL = 07h command (p.94 f).
;0701 666800020000   * PUSH   00000200   ;
;0707 666808000000   * PUSH   00000008   ;
;070D 6653           * PUSH   EBX        ;
;070F 6653           * PUSH   EBX        ;
;0711 6655           * PUSH   EBP        ;
;0713 666800000000   * PUSH   00000000   ;
;0719 6668007C0000   * PUSH   00007C00   ;
;071F 6661           * POPAD             ; 
;0721 680000         * PUSH   0000       ; 
;0724 07               POP    ES         ; 
;0725 CD1A             INT    1A
;
;; On return, "(EAX) = Return Code as defined in Section 12.3" and
;;            "(EDX) = Event number of the event that was logged".
;; =====================================================================






times 109 db 0xFF


POP     DX          ; From [BP+00] at 06C3; often 80h.
XOR     DH,DH       ; (Only DL matters)
JMP     0x0000:0x7C00   ; Jump to Volume Boot Record code
                                       ; loaded into Memory by this MBR.

INT     0x18          ; Is this instruction here to meet
                                       ; some specification of TPM v 1.2 ?
; The usual 'INT18 if no disk found' is in the code above at 0632.

; Note: When the last character of any Error Message has been displayed, the
; instructions at offsets 0748, 0753 and 0754 lock computer's execution into
; a never ending loop! You must reboot the machine.  INT 10, Function 0Eh
; (Teletype Output) is used to display each character of these error messages.

 MOV     AL,[0x07B7]   ; ([7B7] -> 9A) + 700 = 79A h
JMP     0x073E        ; Displays: "Missing operating system" 
MOV     AL,[0x07B6]   ; ([7B6] -> 7B) + 700 = 77B h
JMP     0x073E        ; Displays: "Error loading operating 
                                       ;                              system"
MOV     AL,[0x07B5]   ; ([7B5] -> 63) + 700 = 763 h
                                       ; which will display: "Invalid 
                                       ;                     partition table"


PRINT_STRING:
XOR AH, AH       ; Zero-out AH.
ADD AX, 0x0700   ; Add 700h to offsets from above. 
MOV SI, AX       ; Offset of message -> Source Index Reg.
PRINT_CHARACTER:
LODSB            ; Load character into AL from [SI].

CMP AL, 00       ;/ Have we reached end of message
                 ;|   marker?(00) If so, then
JZ HALT          ; 

MOV BX, 0x7     ; Display page 0, normal white on black
                ;   characters.
MOV AH,0x0E               ;/ Teletype Output.. displays only
INT 0x10                  ;\   one character at a time.
JMP PRINT_CHARACTER       ; Go back for another character...

HALT:
HLT
JMP HALT            ; And just in case an NMI occurs,
                    ; we jump right back to HLT again!

; -----------------------------------------------------------------------
;   SUBROUTINE - Part of A20 Line Enablement code (see 06C6 ff. above);
;                This routine checks/waits for access to KB controller.
; -----------------------------------------------------------------------
SUB CX, CX            ; Sets CX = 0.              ; ANOTHER INSTRUCTION
CHECK_SOMETHING:
IN AL, 0x64           ; Check port 64h.
JMP UNUSED_JUMP       ; Seems odd, but this is how it's done.
UNUSED_JUMP:
AND AL, 0b10                  ; Test for only 'Bit 1' *not* set.
LOOPNE  CHECK_SOMETHING       ; Continue to check (loop) until
                              ; CX = 0 (and ZF=1); it's ready.
AND AL, 0b10
RET

;********************************************************************;
;*                          Error messages                          *;
;********************************************************************;

INVALID_TABLE_OFFSET: EQU ($ - $$) % 0x100
INVALID_TABLE: DB "Invalid partition table", 0
LOADING_ERROR_OFFSET: EQU ($ - $$) % 0x100
LOADING_ERROR: DB "Error loading operating system", 0
MISSING_ERROR_OFFSET: EQU ($ - $$) % 0x100
MISSING_ERROR: DB "Missing operating system", 0

DW 0x0000
DB INVALID_TABLE_OFFSET, LOADING_ERROR_OFFSET, MISSING_ERROR_OFFSET
DD DISK_ID
DW 0x0000

;********************************************************************;
;*                          Partition Table                         *;
;********************************************************************;

TABLE: EQU (DEST + 446)
TIMES 64 DB 0x00                    ; Fill partition table with 0xFF
DB 0x55, 0xAA                       ; Mark sector as bootable