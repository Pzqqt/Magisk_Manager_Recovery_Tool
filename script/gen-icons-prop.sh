#!/sbin/sh

. /tmp/mmr/script/common.sh

update_icon_module=$1

dst_prop_file=/tmp/aroma/module_icon.prop

get_useicon() {
    /tmp/mmr/script/control-module.sh status $1
    # Enable: 1, Disable: 0, Removed: 2, UpdateFlag: 3, RemoveFlag: 4 or 5
    case $? in
        1) echo "@default";;
        0) echo "@disable";;
        2) echo "@removed";;
        3) echo "@updateflag";;
        4) echo "@removeflag";;
        5) echo "@removeflag";;
    esac
}

[[ $update_icon_module = "--regen" ]] && rm -f $dst_prop_file

if ! [ -f $dst_prop_file ]; then
    touch $dst_prop_file
    for module in `ls_mount_path`; do
        echo "module.icon.${module}=$(get_useicon $module)" >> $dst_prop_file
    done
    sync
    exit 0
fi

if [ -n "$update_icon_module" ]; then
    sed -i "/^module\.icon\.${update_icon_module}=/cmodule\.icon\.${update_icon_module}=$(get_useicon $update_icon_module)" $dst_prop_file
    sync
fi
