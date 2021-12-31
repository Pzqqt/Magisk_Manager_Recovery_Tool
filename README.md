# Magisk_Manager_Recovery_Tool

## 简介
这是一个可以在 Recovery 模式下使用的 Magisk Manager.<br>
它基于 <a href="https://github.com/amarullz/AROMA-Installer">Aroma Installer</a>.<br>

## 功能
- 1.启用/禁用模块
- 2.启用/禁用模块挂载
- 3.(撤销)重启后移除模块
- 4.直接移除模块
- 5.启用/禁用 Magisk 核心模式
- 6.查看模块描述 版本 作者等信息
- 7.预览模块目录文件结构
- 8.瘦身 magisk.img (适用于 Magisk v18.1 及之前的版本)
- 9.清除 MagiskSU 日志
- 10.授权管理

## 特性
- 1.GUI 操作, 界面友好, 便于使用<br>
- 2.简体中文界面, 即使你的 TWRP 不支持中文, 即使你的 TWRP 没有内置中文字体, 即使你还在使用 CWM.

## 注意
- 1.目前仅支持 arm 和 arm64 架构的设备.<br>
- 2.在某些设备上刷入后可能会卡在 Recovery 界面, 系 Aroma Installer 二进制文件的 bug, 我无法修复(详见此 <a href="https://github.com/amarullz/AROMA-Installer/issues/38">issue</a>).<br>
- 3.已知不支持的设备: 小米8 小米8SE 小米9 小米Mix2S 小米Mix3 一加6

## 引用
- <a href="https://github.com/chenxiaolong/DualBootPatcher/tree/master/utilities">DualBootUtilities</a>(主体代码)<br>
- <a href="https://forum.xda-developers.com/apps/magisk/module-tool-magisk-manager-recovery-mode-t3693165">Magisk Manager for Recovery Mode (mm)</a>(magisk.img 镜像挂载代码)<br>
- <a href="https://elementalx.org/devices/">ElementalX Kernel</a>(Aroma Installer 主题)<br>
- <a href="https://sourceforge.net/projects/p7zip/files/p7zip/16.02/">p7zip</a>(7za 二进制文件)<br>
- <a href="http://mama.indstate.edu/users/ice/tree/">tree</a>(tree 二进制文件)<br>

## License
- <a href="https://github.com/Pzqqt/Magisk_Manager_Recovery_Tool/blob/master/LICENSE">GPL-3.0</a>
