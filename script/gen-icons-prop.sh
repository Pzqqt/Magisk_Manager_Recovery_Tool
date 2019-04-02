#!/sbin/sh

update_icon_module=$1

dst_prop_file=/tmp/aroma/module_icon.prop

get_useicon() {
    /tmp/mmr/script/control-module.sh status $1
    # Enable: 1, Disable: 0, Removed: 2, UpdateFlag: 3, RemoveFlag: 4
    case $? in
        1) useicon="@default"
        ;;
        0) useicon="@disable"
        ;;
        2) useicon="@removed"
        ;;
        3) useicon="@updateflag"
        ;;
        4) useicon="@removeflag"
        ;;
        *) useicon="@default"
        ;;
    esac
}

if ! [ -f $dst_prop_file ]; then
    touch $dst_prop_file
    for module in `cat /tmp/mmr/script/modules_ids`; do
        get_useicon $module
        echo "module.icon.${module}=${useicon}" >> $dst_prop_file
    done
elif ! [ -z $update_icon_module ]; then
    get_useicon $update_icon_module
    sed -i "/module\.icon\.${update_icon_module}/c\module\.icon\.${update_icon_module}=${useicon}" $dst_prop_file
fi
