#!/sbin/sh

key=$1
value=$2

save_prop=/sdcard/TWRP/mmrt.prop

mkdir -p ${save_prop%/*}
touch $save_prop

[ -n $key ] && [ -n $value ] && {
    if [ $(cat $save_prop | grep -c "^${key}=") -eq 0 ]; then
        echo "${key}=${value}" >> $save_prop
    else
        sed -i "/^${key}=/c${key}=${value}" $save_prop
    fi
}
