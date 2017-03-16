@echo off
nasm -f bin Stage1.asm -o Stage1.bin

PARTCOPY Stage1.bin 0 3 -f0 0 
PARTCOPY Stage1.bin 3E 1C2 -f0 3E 

pause

nasm -f bin Stage2.asm -o KRNLDR.SYS

pause
