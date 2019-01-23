#!/sbin/sh

module=$1
propkey=$2

file_getprop() { grep "^$2=" "$1" | head -n1 | cut -d= -f2; }

if [ -f /magisk/${module}/module.prop ]; then
    infotext=`file_getprop /magisk/${module}/module.prop ${propkey}`
    if [ ${#infotext} -ne 0 ]; then
        echo $infotext
    else
        echo "(未提供信息)"
    fi
else
    echo "(未提供信息)"
fi