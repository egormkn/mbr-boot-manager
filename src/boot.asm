;********************************************************************;
;*                         x86 Bootloader                           *;
;*                                                                  *;
;*                  github.com/egormkn/bootloader                   *;
;********************************************************************;

%define FAT12         ; <-- Set filesystem here: FAT12, FAT16 or FAT32

;********************************************************************;
;*                              Header                              *;
;********************************************************************;

[BITS 16]                   ; NASM directive that enables 16-bit mode

[ORG 0x7C00]                ; NASM directive that specifies the memory
                            ;  address at which program will be loaded

boot: JMP loader                          ; Jump over BPB to boot code
TIMES (3 + boot - $) DB 0x90              ; Set BPB offset to 3 bytes

OEM:                 DB "x86 Boot"           ; OEM name (8 characters)

;********************************************************************;
;*                       BIOS Parameter block                       *;
;********************************************************************;

%ifdef FAT12
%include "fat12_bpb.asm"                  ; FAT12 BIOS Parameter block
%elifdef FAT16                            ; or
%include "fat16_bpb.asm"                  ; FAT16 BIOS Parameter block
%elifdef FAT32                            ; or
%include "fat32_bpb.asm"                  ; FAT32 BIOS Parameter block
%else
%error Unsupported file system
%endif

;********************************************************************;
;*                      Bootloader entry point                      *;
;********************************************************************;

loader:
%include "bootcode.asm"              ; Load bootcode from another file

;********************************************************************;
;*                         File system tools                        *;
;********************************************************************;

%ifdef FAT12
%include "fat12.asm"                         ; FAT12 file system tools
%elifdef FAT16                               ; or
%include "fat16.asm"                         ; FAT16 file system tools
%elifdef FAT32                               ; or
%include "fat32.asm"                         ; FAT32 file system tools
%else
%error Unsupported file system
%endif

;********************************************************************;
;*                              Footer                              *;
;********************************************************************;

TIMES 510 - ($ - $$) DB 0                    ; Fill other bytes with 0
DW 0xAA55                                    ; Mark sector as bootable