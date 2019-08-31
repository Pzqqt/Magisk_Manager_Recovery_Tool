#!/sbin/sh

workPath=/magisk

file_getprop() { grep "^$2=" "$1" | head -n1 | cut -d= -f2; }

ls_mount_path() { ls -1 ${workPath} | grep -v 'lost+found'; }

