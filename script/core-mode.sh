#!/sbin/sh

operate=$1

isnotabdevice=`cat /proc/cmdline | grep -c "androidboot.slot"`
[ $isnotabdevice -eq 0 ] && cache_path=/cache || cache_path=/data/cache

core_mode_flag=${cache_path}/.disable_magisk

if [[ $operate = "status" ]]; then
    # Enable core only mode: 1, Disable: 0
    [ -f $core_mode_flag ] && exit 1 || exit 0
fi

if [[ $operate = "switch" ]]; then
    [ -f $core_mode_flag ] && rm -f $core_mode_flag || touch $core_mode_flag
    sync
fi
