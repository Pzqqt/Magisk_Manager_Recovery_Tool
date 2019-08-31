#!/sbin/sh

. /tmp/mmr/script/common.sh

operate=$1
module=$2

modulePath=${workPath}/${module}

exist_flag() { test -f ${modulePath}/${1}; }

rm_flag() { rm -f ${modulePath}/${1} && exit 0; }

touch_flag() {
    touch ${modulePath}/${1} || { cd ${modulePath}? && touch ./${1}; }
    [ $? -eq 0 ] && exit 0
}

switch_flag() { exist_flag "$1" && rm_flag "$1" || touch_flag "$1"; }

[ -n $operate ] && [ -n $module ] && \
case $operate in
    "status") {
        # Enable: 1, Disable: 0, Removed: 2, UpdateFlag: 3,
        # RemoveFlag & Enable: 4, RemoveFlag & Disable: 5
        [ -d $modulePath ] || exit 2
        exist_flag "update" && exit 3
        if exist_flag "remove"; then
            exist_flag "disable" && exit 5 || exit 4
        else
            exist_flag "disable" && exit 0 || exit 1
        fi
    } ;;
    "status_auto_mount") {
        # Enable: 1, Disable: 0, Removed: 2
        [ -d $modulePath ] || exit 2
        exist_flag "auto_mount" && exit 1 || exit 0
    } ;;
    "status_skip_mount") {
        # Enable: 1, Disable: 0, Removed: 2
        [ -d $modulePath ] || exit 2
        exist_flag "skip_mount" && exit 0 || exit 1
    } ;;
    "switch_module") switch_flag "disable";;
    "switch_auto_mount") switch_flag "auto_mount";;
    "switch_skip_mount") switch_flag "skip_mount";;
    "switch_remove") switch_flag "remove";;
    "remove") rm -rf $modulePath && exit 0;;
    *) echo -e "\nUnknown operation: $operate"; exit 1;;
esac

echo -e "\nScript execution failed!"
exit 1