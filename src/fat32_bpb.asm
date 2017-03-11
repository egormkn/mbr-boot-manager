;********************************************************************;
;*                    FAT32 BIOS Parameter block                    *;
;********************************************************************;

BPB_BytesPerSector:     DW 512                    ; 512/1024/2048/4096
BPB_SectorsPerCluster:  DB 1                    ; 1/2/4/8/16/32/64/128
BPB_ReservedSectors:    DW 1                 ; Boot sector is reserved
BPB_NumberOfFATs:       DB 2                    ; 2 (recommended) or 1
BPB_RootEntries:        
                        %ifdef FAT32
                          DW 0                   ; Must be 0 for FAT32
                        %elifdef FAT16
                          DW 512           ; 512 recommended for FAT16
                        %elifdef FAT12
                          DW 224               ; x * 32 :: BytesPerSec
                        %else
                          %error Unsupported file system
                        %endif
BPB_TotalSectors16:     
                        %ifdef FAT32
                          DW 0                   ; Must be 0 for FAT32
                        %elifdef FAT16
                          DW 512           ; 512 recommended for FAT16
                        %elifdef FAT12
                          DW 2880            ; Floppy has 2880 sectors
                        %else
                          %error Unsupported file system
                        %endif
BPB_Media:              DB 0xF0        ; 0xF0 (removable) or 0xF8-0xFF
BPB_SectorsPerFAT:      DW 9
BPB_SectorsPerTrack:    DW 18
BPB_HeadsPerCylinder:   DW 2
BPB_HiddenSectors:      DD 0
BPB_TotalSectorsBig:    DD 0
bsDriveNumber:         DB 0
bsUnused:              DB 0
bsExtBootSignature:    DB 0x29
bsSerialNumber:        DD 0xa0a1a2a3
bsVolumeLabel:         DB "BOOTLOADER "           ; 11 bytes
bsFileSystem:          DB "FAT12   "              ;  8 bytes