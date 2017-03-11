;********************************************************************;
;*                    FAT12 BIOS Parameter block                    *;
;*                                                                  *;
;*                  github.com/egormkn/bootloader                   *;
;********************************************************************;

BPB_BytesPerSector:     DW 512                    ; 512/1024/2048/4096
BPB_SectorsPerCluster:  DB 1                    ; 1/2/4/8/16/32/64/128
BPB_ReservedSectors:    DW 1                 ; Boot sector is reserved
BPB_NumberOfFATs:       DB 2                    ; 2 (recommended) or 1
BPB_RootEntries:        DW 224              ; x * 32 :: BytesPerSector
BPB_TotalSectors16:     DW 2880              ; Floppy has 2880 sectors
BPB_Media:              DB 0xF0              ; Removable, single sided
BPB_SectorsPerFAT:      DW 9                       ; 9 sectors per FAT
BPB_SectorsPerTrack:    DW 18                   ; 18 sectors per track
BPB_HeadsPerCylinder:   DW 2                    ; 2 heads per cylinder
BPB_HiddenSectors:      DD 0                       ; No hidden sectors
BPB_TotalSectorsBig:    DD 0                       ; No 32-bit sectors
BS_DriveNumber:         DB 0                         ; Drive number: 0
BS_Unused:              DB 0                           ; Reserved byte
BS_ExtBootSignature:    DB 0x29                        ; MS/PC-DOS 4.0
BS_SerialNumber:        DD 0xa0a1a2a3                   ; Random value
BS_VolumeLabel:         DB "NO NAME    "                    ; 11 bytes
BS_FileSystem:          DB "FAT12   "                       ;  8 bytes