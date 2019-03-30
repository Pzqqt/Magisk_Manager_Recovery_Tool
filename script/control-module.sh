#!/sbin/sh

operate=$1
module=$2

workPath=/magisk
modulePath=${workPath}/${module}

touch_flag() { touch ${1}/${2} || { cd ${1}? && touch ./${2}; }; }

case $operate in
    "status") {
        # Enable: 1, Disable: 0, Removed: 2, UpdateFlag: 3, RemoveFlag: 4
        [ ! -d $modulePath ] && exit 2
        [ -f $modulePath/update ] && exit 3
        [ -f $modulePath/remove ] && exit 4
        [ -f $modulePath/disable ] && exit 0
        exit 1
    } ;;
    "status_auto_mount") {
        # Enable: 1, Disable: 0, Removed: 2
        [ ! -d $modulePath ] && exit 2
        [ -f $modulePath/auto_mount ] && exit 1 || exit 0
    } ;;
    "status_skip_mount") {
        # Enable: 1, Disable: 0, Removed: 2
        [ ! -d $modulePath ] && exit 2
        [ -f $modulePath/skip_mount ] && exit 0 || exit 1
    } ;;
    "switch_module") {
        if [ -f $modulePath/disable ]; then
            rm -rf $modulePath/disable && {
                echo "Successfully enable module ${module} !"
                exit 0
            }
        else
            touch_flag $modulePath disable && {
                echo "Successfully disable module ${module} !"
                exit 0
            }
        fi
    } ;;
    "switch_auto_mount") {
        if [ -f $modulePath/auto_mount ]; then
            rm -rf $modulePath/auto_mount && {
                echo "Successfully disable mount for $module !"
                exit 0
            }
        else
            touch_flag $modulePath auto_mount && {
                echo "Successfully enable mount for $module !"
                exit 0
            }
        fi
    } ;;
    "switch_skip_mount") {
        if [ -f $modulePath/skip_mount ]; then
            rm -rf $modulePath/skip_mount && {
                echo "Successfully enable mount for $module !"
                exit 0
            }
        else
            touch_flag $modulePath skip_mount && {
                echo "Successfully disable mount for $module !"
                exit 0
            }
        fi
    } ;;
    "switch_remove") {
        if [ -f $modulePath/remove ]; then
            rm -rf $modulePath/remove && {
                echo "Successful undo."
                exit 0
            }
        else
            touch_flag $modulePath remove && {
                echo "Module $module will be removed at next reboot."
                exit 0
            }
        fi
    } ;;
    "remove") {
        rm -rf $modulePath && {
            echo "Successfully removed module $module !"
            exit 0
        }
    } ;;
    *) {
        echo -e "\nUnknown operation: $operate"
        exit 1
    } ;;
esac

echo -e "\nScript execution failed!"
exit 1