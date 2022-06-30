# Magisk_Manager_Recovery_Tool

## Description

This is a Magisk Manager tool that can be used in Recovery mode.

It's based on [Aroma Installer](https://github.com/amarullz/AROMA-Installer).

## What can it do

1. Enable/Disable modules
2. Enable/Disable modules mount
3. Remove modules at next reboot (support undo)
4. Remove modules directly
5. Enable/Disable Magisk core only mode
6. Enable/Disable Magisk Hide
7. Enable/Disable Zygisk
8. Enable/Disable DenyList
9. View module descriptions, versions, authors, etc.
10. View module content (directory structure)
11. Shrinking magisk.img (useable for Magisk v18.1 and earlier)
12. Clear MagiskSU logs
13. Manage Superuser rights

## Feature

1. Friendly interface & easy to use.
2. Supported older recovery or even CWM.

## Note

1. Only supported arm & arm64 architecture. Not supported x86 & x64 architecture.
2. Will get stuck at Recovery for some device. This is a bug in Aroma Installer binary file and I can not fix it(about: [issue](https://github.com/amarullz/AROMA-Installer/issues/38)).
3. If your device is using Qualcomm soc and model is greater than {660, 7xx, 835}, then this tool does not support it.

## Reference

- [DualBootUtilities](https://github.com/chenxiaolong/DualBootPatcher/tree/master/utilities)(Code framework)
- [Magisk Manager for Recovery Mode (mm)](https://forum.xda-developers.com/apps/magisk/module-tool-magisk-manager-recovery-mode-t3693165)(Code of mount magisk.img)
- [ElementalX Kernel](https://elementalx.org/devices/)(Aroma Installer theme)
- [p7zip](https://sourceforge.net/projects/p7zip/files/p7zip/16.02/)(7za binary)
- [tree](http://mama.indstate.edu/users/ice/tree/)(tree binary)
- [micropython](https://github.com/micropython/micropython)(micropython binary)
- [usqlite](https://github.com/spatialdude/usqlite)(μSQLite library module for micropython)

## License

- [GPL-3.0](https://github.com/Pzqqt/Magisk_Manager_Recovery_Tool/blob/master/LICENSE)
