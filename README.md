# Magisk_Manager_Recovery_Tool

## Description
This is a Magisk Manager tool that can be used in Recovery mode.<br>
It's based on <a href="https://github.com/amarullz/AROMA-Installer">Aroma Installer</a>.<br>

## What can it do
- 1.Enable/Disable modules
- 2.Enable/Disable modules mount
- 3.Remove modules at next reboot(support undo)
- 4.Remove modules directly(useable for Magisk v18.1 and earlier)
- 5.Enable/Disable Magisk core only mode
- 6.View module descriptions, versions, authors, etc.
- 7.View module content(directory structure)
- 8.Shrinking magisk.img(useable for Magisk v18.1 and earlier)
- 9.Clear MagiskSU logs
- 10.Manage Superuser rights
- 11.Uninstall Magisk

## Feature
- 1.Friendly interface & easy to use.<br>
- 2.Supported older recovery or even CWM.

## Note
- 1.Only supported arm & arm64 architecture. Not supported x86 & x64 architecture.<br>
- 2.Will get stuck at Recovery for some device(such as Xiaomi 8). This is a bug in Aroma Installer binary file and I can not fix it(about: <a href="https://github.com/amarullz/AROMA-Installer/issues/38">issue</a>).<br>
- 3.Known unsupported devices: Xiaomi 8, Xiaomi 8SE, Xiaomi 9, Xiaomi Mix2S, Xiaomi Mix3, Oneplus 6

## Reference
- <a href="https://github.com/chenxiaolong/DualBootPatcher/tree/master/utilities">DualBootUtilities</a>(Code framework)<br>
- <a href="https://forum.xda-developers.com/apps/magisk/module-tool-magisk-manager-recovery-mode-t3693165">Magisk Manager for Recovery Mode (mm)</a>(Code of mount magisk.img)<br>
- <a href="https://elementalx.org/devices/">ElementalX Kernel</a>(Aroma Installer theme)<br>
- <a href="https://sourceforge.net/projects/p7zip/files/p7zip/16.02/">p7zip</a>(7za binary)<br>
- <a href="http://mama.indstate.edu/users/ice/tree/">tree</a>(tree binary)<br>

## License
- <a href="https://github.com/Pzqqt/Magisk_Manager_Recovery_Tool/blob/master/LICENSE">GPL-3.0</a>
