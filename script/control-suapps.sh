#!/sbin/sh

. /tmp/mmr/script/common.sh

operate=$1

prop_path=/tmp/aroma/magisksu_apps.prop
num_uid_prop=/tmp/mmr/num_uid.prop

[ -z "$operate" ] && {
    : > $prop_path
    i=1
    if [ "$MAGISK_VER_CODE" -ge 24305 ]; then
        for uid_policy in `/tmp/mmr/script/control-sqlite.sh get_saved_uid_policy | sed 's/|/=/g'`; do
            echo "item.0.${i}=$(expr ${uid_policy#*=} - 1)" >> $prop_path
            let i+=1
        done
    else
        for pp in `/tmp/mmr/script/control-sqlite.sh get_saved_package_name_policy | sed 's/|/=/g'`; do
            echo "item.0.${i}=$(expr ${pp#*=} - 1)" >> $prop_path
            let i+=1
        done
    fi
    if ! [ -f $num_uid_prop ]; then
        touch $num_uid_prop
        i=1
        if [ "$MAGISK_VER_CODE" -ge 24305 ]; then
            for uid_policy in `/tmp/mmr/script/control-sqlite.sh get_saved_uid_policy | sed 's/|/=/g'`; do
                echo "item.0.${i}=${uid_policy%=*}" >> $num_uid_prop
                let i+=1
            done
        else
            for pu in `/tmp/mmr/script/control-sqlite.sh get_saved_package_name_uid | sed 's/|/=/g'`; do
                echo "item.0.${i}=${pu#*=}" >> $num_uid_prop
                let i+=1
            done
        fi
    fi
    cp -f $prop_path ${prop_path}.bak
    exit 0
}

if [[ $operate = "apply_change" ]]; then
    changed=`/tmp/mmr/bin/diff -u ${prop_path}.bak $prop_path | grep "^+item" | sed 's/+//g'`
    [ -z "$changed" ] && exit 0
    for change in $changed; do
        set_value=$(expr ${change#*=} + 1)
        set_uid=$(file_getprop $num_uid_prop ${change%=*})
        /tmp/mmr/script/control-sqlite.sh set_policy $set_uid $set_value
        if [ "$MAGISK_VER_CODE" -ge 24305 ]; then
            pn=$(get_package_name_by_uid $set_uid)
        else
            pn=`/tmp/mmr/script/control-sqlite.sh get_saved_package_name_uid | sed 's/|/=/g' | grep "=${set_uid}$" | head -n1 | cut -d= -f1`
        fi
        case $set_value in
            2) echo "允许 $pn 获取超级用户权限";;
            1) echo "拒绝 $pn 获取超级用户权限";;
        esac
    done
fi
