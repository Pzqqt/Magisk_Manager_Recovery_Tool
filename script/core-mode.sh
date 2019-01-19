#!/sbin/sh

operate=$1

isnotabdevice=`cat /proc/cmdline | grep -c "androidboot.slot"`
[ $isnotabdevice -eq 0 ] && cache_path=/cache || cache_path=/data/cache

if [ $operate == "status" ]; then
  # Enable core only mode: 1, Disable: 0
  # [ -f ${cache_path}/.disable_magisk ] && exit 1 || exit 0
  if [ -f ${cache_path}/.disable_magisk ]; then
    exit 1
  fi
fi

if [ $operate == "switch" ]; then
    if [ -f ${cache_path}/.disable_magisk ]; then
        rm -f ${cache_path}/.disable_magisk
        echo ""
        echo "Successfully disable Magisk core only mode!"
    else
        touch ${cache_path}/.disable_magisk
        echo ""
        echo "Successfully enable Magisk core only mode!"
    fi
fi
