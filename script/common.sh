#!/sbin/sh

echo $PATH | grep -q "^/tmp/bb" || export PATH=/tmp/bb:${PATH}

workPath=/magisk
module_backup_path=/sdcard/TWRP/magisk_module_backup

file_getprop() { grep "^$2=" "$1" | head -n1 | cut -d= -f2; }
_ls() { ls -1 ${1} | grep -v 'lost+found'; }
ls_mount_path() { _ls ${workPath}; }

MAGISK_VER=$(file_getprop /data/adb/magisk/util_functions.sh MAGISK_VER)
MAGISK_VER_CODE=$(file_getprop /data/adb/magisk/util_functions.sh MAGISK_VER_CODE)
