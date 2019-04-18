#!/sbin/sh

operate=$1

prop_path=/tmp/aroma/magisksu_apps.prop
num_uid_prop=/tmp/mmr/num_uid.prop

file_getprop() { grep "^$2=" "$1" | head -n1 | cut -d= -f2; }

[ -z "$operate" ] && {
    : > $prop_path
    i=1
    for pp in `/tmp/mmr/script/control-sqlite.sh get_saved_package_name_policy | sed 's/|/=/g' | sort`; do
        echo "item.0.${i}=$(expr ${pp#*=} - 1)" >> $prop_path
        let i+=1
    done
    if ! [ -f $num_uid_prop ]; then
        touch $num_uid_prop
        i=1
        for pu in `/tmp/mmr/script/control-sqlite.sh get_saved_package_name_uid | sed 's/|/=/g' | sort`; do
            echo "item.0.${i}=${pu#*=}" >> $num_uid_prop
            let i+=1
        done
    fi
    cp -f $prop_path ${prop_path}.bak
    exit 0
}

if [[ $operate = "apply_change" ]]; then
    changed=`diff ${prop_path}.bak $prop_path | grep "^+item" | sed 's/+//g'`
    [ -z "$changed" ] && exit 0
    for change in $changed; do
        set_value=$(expr ${change#*=} + 1 )
        set_uid=$(file_getprop $num_uid_prop ${change%=*})
        /tmp/mmr/script/control-sqlite.sh set_policy $set_uid $set_value
        pn=`/tmp/mmr/script/control-sqlite.sh get_saved_package_name_uid | sed 's/|/=/g' | grep "=${set_uid}$" | head -n1 | cut -d= -f1`
        case $set_value in
            2) echo "Superuser rights of $pn are granted";;
            1) echo "Superuser rights of $pn are denied";;
        esac
    done
fi
