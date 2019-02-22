#!/sbin/sh

module=$1
propkey=$2

workPath=/magisk

file_getprop() { grep "^$2=" "$1" | head -n1 | cut -d= -f2; }

if [ -f ${workPath}/${module}/module.prop ]; then
    infotext=`file_getprop ${workPath}/${module}/module.prop $propkey`
    if [ ${#infotext} -ne 0 ]; then
        echo $infotext
    else
        echo "(未提供信息)"
    fi
else
    echo "(未提供信息)"
fi
