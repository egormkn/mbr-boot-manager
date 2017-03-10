;**********************************************************;
;*                    x86 Bootloader                      *;
;*                                                        *;
;*             github.com/egormkn/bootloader              *;
;**********************************************************;

; Compiling command: nasm boot.asm -f bin -o boot.bin

[BITS 16]         ; NASM directive that enables 16-bit mode

[ORG 0x7C00]      ; NASM directive that specifies the memory
                  ; address at which program will be loaded

start: JMP loader ; Jump over OEM Parameter block


;**********************************************************;
;*                  OEM Parameter block                   *;
;**********************************************************;

bpbOEM:                DB "My OS   "               ; 8 bytes
bpbBytesPerSector:     DW 512         ; Must be a power of 2
bpbSectorsPerCluster:  DB 1           
bpbReservedSectors:    DW 1        ; Boot sector is reserved
bpbNumberOfFATs:       DB 2
bpbRootEntries:        DW 224
bpbTotalSectors:       DW 2880
bpbMedia:              DB 0xF0
bpbSectorsPerFAT:      DW 9
bpbSectorsPerTrack:    DW 18
bpbHeadsPerCylinder:   DW 2
bpbHiddenSectors:      DD 0
bpbTotalSectorsBig:    DD 0
bsDriveNumber:         DB 0
bsUnused:              DB 0
bsExtBootSignature:    DB 0x29
bsSerialNumber:        DD 0xa0a1a2a3
bsVolumeLabel:         DB "BOOTLOADER "           ; 11 bytes
bsFileSystem:          DB "FAT12   "              ;  8 bytes


;**********************************************************;
;*                 Bootloader entry point                 *;
;**********************************************************;

loader:
%include "bootcode.asm"    ; Load bootcode from separate file

TIMES 510 - ($ - $$) db 0  ; Fill other bytes with 0 ($ - current line, $$ - first line)
DW 0xAA55                  ; Boot sector signature (marks disk as bootable)