#!/sbin/sh

key=$1

uffile=/data/adb/magisk/util_functions.sh

file_getprop() { grep "^$2=" "$1" | head -n1 | cut -d= -f2; }

if [ -f $uffile ]; then
    infotext=`file_getprop $uffile $key`
    if [ ${#infotext} -ne 0 ]; then
        echo $infotext
    else
        echo "Unknown"
    fi
else
    echo "Unknown"
fi
