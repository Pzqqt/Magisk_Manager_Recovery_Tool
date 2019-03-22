#!/sbin/sh

module=$1
propkey=$2

workPath=/magisk

file_getprop() { grep "^$2=" "$1" | head -n1 | cut -d= -f2; }

if [ $propkey = "size" ]; then
    echo `du -s ${workPath}/${module} | awk '{print int($1/1024)}'`
elif [ -f ${workPath}/${module}/module.prop ]; then
    infotext=`file_getprop ${workPath}/${module}/module.prop $propkey`
    [ ${#infotext} -ne 0 ] && echo $infotext || echo "(未提供信息)"
else
    echo "(未提供信息)"
fi
