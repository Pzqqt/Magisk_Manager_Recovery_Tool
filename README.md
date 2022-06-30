# Magisk_Manager_Recovery_Tool

## 简介

这是一个可以在 Recovery 模式下使用的 Magisk Manager.

它基于 [Aroma Installer](https://github.com/amarullz/AROMA-Installer).

## 功能

1. 启用/禁用模块
2. 启用/禁用模块挂载
3. (撤销)重启后移除模块
4. 直接移除模块
5. 启用/禁用 Magisk 核心模式
6. 启用/禁用 Magisk Hide
7. 启用/禁用 Zygisk
8. 启用/禁用遵守排除列表
9. 查看模块描述 版本 作者等信息
10. 预览模块目录文件结构
11. 瘦身 magisk.img (适用于 Magisk v18.1 及之前的版本)
12. 清除 MagiskSU 日志
13. Root 授权管理

## 特性

1. GUI 操作, 界面友好, 便于使用
2. 简体中文界面, 即使你的 TWRP 不支持中文, 即使你的 TWRP 没有内置中文字体, 即使你还在使用 CWM.

## 注意

1. 仅支持 arm 和 arm64 架构的设备.
2. 在某些设备上刷入后可能会卡在 Recovery 界面, 系 Aroma Installer 二进制文件的 bug, 我无法修复(详见此 [issue](https://github.com/amarullz/AROMA-Installer/issues/38)).
3. 如果你的设备使用的是高通 660 之后的 6 系列 soc, 高通所有 7 系列 soc, 高通 835 之后的所有 8 系列 soc, 那么本工具不支持你的设备.

## 引用

- [DualBootUtilities](https://github.com/chenxiaolong/DualBootPatcher/tree/master/utilities)(主体代码)
- [Magisk Manager for Recovery Mode (mm)](https://forum.xda-developers.com/apps/magisk/module-tool-magisk-manager-recovery-mode-t3693165)(magisk.img 镜像挂载代码)
- [ElementalX Kernel](https://elementalx.org/devices/)(Aroma Installer 主题)
- [p7zip](https://sourceforge.net/projects/p7zip/files/p7zip/16.02/)(7za 二进制文件)
- [tree](http://mama.indstate.edu/users/ice/tree/)(tree 二进制文件)
- [micropython](https://github.com/micropython/micropython)(micropython 二进制文件)
- [usqlite](https://github.com/spatialdude/usqlite)(micropython 的 μSQLite 库模块)

## License

- [GPL-3.0](https://github.com/Pzqqt/Magisk_Manager_Recovery_Tool/blob/master/LICENSE)
