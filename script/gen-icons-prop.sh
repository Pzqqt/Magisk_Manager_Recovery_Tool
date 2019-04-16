#!/sbin/sh

update_icon_module=$1
force_update_all=$2

workPath=/magisk
dst_prop_file=/tmp/aroma/module_icon.prop

ls_mount_path() { ls -1 ${workPath} | grep -v 'lost+found'; }

get_useicon() {
    /tmp/mmr/script/control-module.sh status $1
    # Enable: 1, Disable: 0, Removed: 2, UpdateFlag: 3, RemoveFlag: 4 or 5
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
        5) useicon="@removeflag"
        ;;
    esac
}

if (! [ -f $dst_prop_file ]) || [ "$force_update_all" = true ]; then
    : > $dst_prop_file
    for module in `ls_mount_path`; do
        get_useicon $module
        echo "module.icon.${module}=${useicon}" >> $dst_prop_file
    done
elif ! [ -z "$update_icon_module" ]; then
    get_useicon $update_icon_module
    sed -i "/^module\.icon\.${update_icon_module}=/cmodule\.icon\.${update_icon_module}=${useicon}" $dst_prop_file
fi
