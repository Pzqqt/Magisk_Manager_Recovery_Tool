#!/sbin/sh

. /tmp/mmr/script/common.sh

echo "\n你已安装 $(ls_mount_path | wc -l) 个模块, 总占用空间: $(du -sh ${workPath}/ | awk '{print $1}')"
