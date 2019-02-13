#!/sbin/sh

operate=$1
module=$2

if [ $operate = "status" ]; then
    # Enable: 1, Disable: 0, Removed: 2, UpdateFlag: 3, RemoveFlag: 4
    [ ! -d /magisk/$module ] && exit 2
    [ -f /magisk/$module/update ] && exit 3
    [ -f /magisk/$module/remove ] && exit 4
    [ -f /magisk/$module/disable ] && exit 0
    exit 1
fi

if [ $operate = "status_am" ]; then
    # Enable: 1, Disable: 0, Removed: 2
    [ ! -d /magisk/$module ] && exit 2
    [ -f /magisk/$module/auto_mount ] && exit 1 || exit 0
fi

if [ $operate = "switch_module" ]; then
    if [ -f /magisk/$module/disable ]; then
        rm -rf /magisk/$module/disable && {
            echo "Successfully enable module $module !"
            exit 0
        }
    else
        touch /magisk/$module/disable && {
            echo "Successfully disable module $module !"
            exit 0
        }
    fi
fi

if [ $operate = "switch_auto_mount" ]; then
    if [ -f /magisk/$module/auto_mount ]; then
        rm -rf /magisk/$module/auto_mount && {
            echo "Successfully disable auto_mount for $module !"
            exit 0
        }
    else
        touch /magisk/$module/auto_mount && {
            echo "Successfully enable auto_mount for $module !"
            exit 0
        }
    fi
fi

if [ $operate = "remove" ]; then
    if [ -L /magisk/$module ]; then
        touch /magisk/$module/remove && {
            echo "Module $module will be removed at next reboot."
            exit 0
        }
    else
        rm -rf /magisk/$module && {
            echo "Successfully removed module $module !"
            exit 0
        }
    fi
fi

echo ""
echo "Script execution failed!"
exit 1
