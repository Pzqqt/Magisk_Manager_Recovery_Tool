#!/sbin/sh

. /tmp/mmr/script/common.sh

echo "\nYou have installed $(ls_mount_path | wc -l) module(s), Total size: $(du -sh ${workPath}/ | awk '{print $1}')"
