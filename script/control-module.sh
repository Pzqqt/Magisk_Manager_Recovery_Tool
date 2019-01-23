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

if [ -d /magisk/$module ]; then

    if [ -f /magisk/$module/update ]; then
        echo "The module will be updated after reboot."
        echo "So operation is not allowed."
        echo "Please reboot once and try again."
        exit 3
    fi

    if [ -f /magisk/$module/remove ]; then
        echo "The module will be removed after reboot."
        echo "So operation is not allowed."
        echo "Please reboot once and try again."
        exit 4
    fi

    if [ $operate = "on_module" ]; then
        rm -rf /magisk/$module/disable && {
            echo "Successfully enable module $module !"
            exit 0
        }
    fi

    if [ $operate = "off_module" ]; then
        touch /magisk/$module/disable && {
            echo "Successfully disable module $module !"
            exit 0
        }
    fi

    if [ $operate = "on_auto_mount" ]; then
        touch /magisk/$module/auto_mount && {
            echo "Successfully enable auto_mount for $module!"
            exit 0
        }
    fi

    if [ $operate = "off_auto_mount" ]; then
        rm -rf /magisk/$module/auto_mount && {
            echo "Successfully disable auto_mount for $module!"
            exit 0
        }
    fi

    if [ $operate = "remove" ]; then
        rm -rf /magisk/$module && {
            echo "Successfully removed module $module !"
            exit 0
        }
    fi

    echo ""
    echo "Script execution failed!"
    exit 1
fi
