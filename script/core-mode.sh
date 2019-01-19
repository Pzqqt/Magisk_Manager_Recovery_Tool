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

if [ $operate == "enable" ]; then
  touch ${cache_path}/.disable_magisk
  echo ""
  echo "已成功启用 Magisk 核心模式!"
  echo ""
  echo "若要关闭核心模式,"
  echo "请重启后在 Magisk Manager 应用设置中关闭."
fi
