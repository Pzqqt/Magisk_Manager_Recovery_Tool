#!/sbin/sh

. /tmp/mmr/script/common.sh

echo -e "\nYou have installed $(ls_mount_path | wc -l) module(s), Total size: $(du -sh ${workPath}/ | awk '{print $1}')\c"
