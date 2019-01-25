#!/sbin/sh

operate=$1

isnotabdevice=`cat /proc/cmdline | grep -c "androidboot.slot"`
[ $isnotabdevice -eq 0 ] && cache_path=/cache || cache_path=/data/cache

if [ $operate == "status" ]; then
    # Enable core only mode: 1, Disable: 0
    [ -f ${cache_path}/.disable_magisk ] && exit 1
fi

if [ $operate == "switch" ]; then
    if [ -f ${cache_path}/.disable_magisk ]; then
        rm -f ${cache_path}/.disable_magisk
        echo "已成功禁用 Magisk 核心模式!"
    else
        touch ${cache_path}/.disable_magisk
        echo "已成功启用 Magisk 核心模式!"
    fi
fi
