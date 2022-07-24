#!/sbin/sh

. /tmp/mmr/script/common.sh

MODULES_SIZE_PROP=/tmp/mmr/modules_size.prop

: > $MODULES_SIZE_PROP

for module in $(ls_mount_path); do
    echo "modsize_${module}=$(du -sh ${workPath}/${module} | awk '{print $1}')" >> $MODULES_SIZE_PROP
done
