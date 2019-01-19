#!/sbin/sh

module=$1

file_getprop() { grep "^$2=" "$1" | head -n1 | cut -d= -f2; }

if [ -f /magisk/$module/module.prop ]; then
    infotext=`file_getprop /magisk/$module/module.prop description`
    if [ ${#infotext} -ne 0 ]; then
        echo $infotext
        exit 0
    fi
fi
echo "无法获取模块描述!"
