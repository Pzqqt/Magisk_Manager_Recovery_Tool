#!/sbin/sh

workPath=/magisk
module_backup_path=/sdcard/TWRP/magisk_module_backup

file_getprop() { grep "^$2=" "$1" | head -n1 | cut -d= -f2; }

_ls() { ls -1 ${1} | grep -v 'lost+found'; }

ls_mount_path() { _ls ${workPath}; }

ls_module_backup_path() { _ls ${module_backup_path}; }

magisk_db=/data/adb/magisk.db
