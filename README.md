# MBR Boot Manager
Simple yet powerful Master Boot Record Boot manager that allows to select one of four primary partitions during the boot.
Got tired with reinstalling Grub or other boot manager, that was overwritten by Windows? 
Now you can choose one of four primary partitions to boot with this tiny (512 bytes only) custom MBR.

## Features
* Windows, Linux, FreeDOS and any other bootable partitions are supported
* Speeds up the boot process for your main OS
* Supports multiple active partitions
* Boot first active partition by default
* If <kbd>Shift</kbd> is pressed during boot, a boot menu will appear
  * Use <kbd>UP</kbd> and <kbd>DOWN</kbd> arrows to choose partition in boot menu
  * Use <kbd>Enter</kbd> to select the partition you want to boot from
  * Use <kbd>Esc</kbd> to reboot your computer
* Easy to install
* Uses only the first sector of disk (512 bytes)
* Absolutely free and open-source
* Well-documented and optimised code
* DIY: compile your own version with NASM

## Installation
#### Windows  
Download BootIce and run as Administrator. Select the disk, then Process MBR -> Restore MBR. Choose [mbr.bin](https://github.com/egormkn/bootloader/releases) as restore file, make sure that "Keep signature and partition table untouched" is selected and choose "Restore".

#### Linux/Unix  
Run `dd if=mbr.bin of=/dev/sdX bs=512 count=1` where X is a letter of the disk

## Bugs/issues  
- [ ] Strange artifacts on error message when menu was skipped and there is no VBR found

## Credits  

* [Egor Makarenko](https://github.com/egormkn)
* [Andrew Plotnikov](https://github.com/shemplo)
* [Vladislaw Zemtsov](https://github.com/Zem4ik)

## License
This is free and unencumbered software released into the public domain. See our [LICENSE](LICENSE) file for more information.
