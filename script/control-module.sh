#!/sbin/sh

operate=$1
module=$2

workPath=/magisk

if [ "$operate" = "status" ]; then
    # Enable: 1, Disable: 0, Removed: 2, UpdateFlag: 3, RemoveFlag: 4
    [ ! -d ${workPath}/${module} ] && exit 2
    [ -f ${workPath}/${module}/update ] && exit 3
    [ -f ${workPath}/${module}/remove ] && exit 4
    [ -f ${workPath}/${module}/disable ] && exit 0
    exit 1
fi

if [ "$operate" = "status_am" ]; then
    # Enable: 1, Disable: 0, Removed: 2
    [ ! -d ${workPath}/${module} ] && exit 2
    [ -f ${workPath}/${module}/auto_mount ] && exit 1 || exit 0
fi

if [ "$operate" = "switch_module" ]; then
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

if [ "$operate" = "switch_auto_mount" ]; then
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

if [ "$operate" = "remove" ]; then
    rm -rf /magisk/$module && {
        echo "Successfully removed module $module !"
        exit 0
    }
fi

echo ""
echo "Script execution failed!"
exit 1
