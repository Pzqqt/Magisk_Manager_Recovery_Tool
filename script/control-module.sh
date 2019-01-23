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
        echo "该模块将在重启后完成更新, 故不允许操作."
        echo "请重启一次后再试."
        exit 3
    fi

    if [ -f /magisk/$module/remove ]; then
        echo "该模块将在重启后移除, 故不允许操作."
        echo "请重启一次后再试."
        exit 4
    fi

    if [ $operate = "on_module" ]; then
        rm -rf /magisk/$module/disable && {
            echo "已成功启用模块 $module !"
            exit 0
        }
    fi

    if [ $operate = "off_module" ]; then
        touch /magisk/$module/disable && {
            echo "已成功禁用模块 $module !"
            exit 0
        }
    fi

    if [ $operate = "on_auto_mount" ]; then
        touch /magisk/$module/auto_mount && {
            echo "已成功为模块 $module 启用 auto_mount!"
            exit 0
        }
    fi

    if [ $operate = "off_auto_mount" ]; then
        rm -rf /magisk/$module/auto_mount && {
            echo "已成功为模块 $module 禁用 auto_mount!"
            exit 0
        }
    fi

    if [ $operate = "remove" ]; then
        rm -rf /magisk/$module && {
            echo "已成功移除模块 $module !"
            exit 0
        }
    fi

    echo ""
    echo "命令执行失败!"
    exit 1
fi
