#!/sbin/sh

operate=$1
module=$2

workPath=/magisk
modulePath=${workPath}/${module}

exist_flag() { [ -f ${modulePath}/${1} ]; }

rm_flag() { rm -f ${modulePath}/${1} && echo ${2} && exit 0; }

touch_flag() {
    touch ${modulePath}/${1} || { cd ${modulePath}? && touch ./${1}; }
    [ $? = 0 ] && echo ${2} && exit 0
}

[ -n $operate ] && [ -n $module ] && case $operate in
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
    "switch_module") {
        if exist_flag "disable"; then
            rm_flag "disable" "Successfully enable module $module !"
        else
            touch_flag "disable" "Successfully disable module $module !"
        fi
    } ;;
    "switch_auto_mount") {
        if exist_flag "auto_mount"; then
            rm_flag "auto_mount" "Successfully disable mount for $module !"
        else
            touch_flag "auto_mount" "Successfully enable mount for $module !"
        fi
    } ;;
    "switch_skip_mount") {
        if exist_flag "skip_mount"; then
            rm_flag "skip_mount" "Successfully enable mount for $module !"
        else
            touch_flag "skip_mount" "Successfully disable mount for $module !"
        fi
    } ;;
    "switch_remove") {
        if exist_flag "remove"; then
            rm_flag "remove" "Successful undo."
        else
            touch_flag "remove" "Module $module will be removed at next reboot."
        fi
    } ;;
    "remove") {
        rm -rf $modulePath && echo "Successfully removed module $module !" && exit 0
    } ;;
    *) {
        echo -e "\nUnknown operation: $operate"
        exit 1
    } ;;
esac

echo -e "\nScript execution failed!"
exit 1