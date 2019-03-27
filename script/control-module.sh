#!/sbin/sh

operate=$1
module=$2

workPath=/magisk
modulePath=${workPath}/${module}

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
                echo "已成功启用模块 ${module} !"
                exit 0
            }
        else
            touch $modulePath/disable && {
                echo "已成功禁用模块 ${module} !"
                exit 0
            }
        fi
    } ;;
    "switch_auto_mount") {
        if [ -f $modulePath/auto_mount ]; then
            rm -rf $modulePath/auto_mount && {
                echo "已成功为模块 ${module} 禁用挂载!"
                exit 0
            }
        else
            touch $modulePath/auto_mount && {
                echo "已成功为模块 ${module} 启用挂载!"
                exit 0
            }
        fi
    } ;;
    "switch_skip_mount") {
        if [ -f $modulePath/skip_mount ]; then
            rm -rf $modulePath/skip_mount && {
                echo "已成功为模块 ${module} 启用挂载!"
                exit 0
            }
        else
            touch $modulePath/skip_mount && {
                echo "已成功为模块 ${module} 禁用挂载!"
                exit 0
            }
        fi
    } ;;
    "switch_remove") {
        if [ -f $modulePath/remove ]; then
            rm -rf $modulePath/remove && {
                echo "已撤销操作!"
                exit 0
            }
        else
            touch $modulePath/remove && {
                echo "模块 $module 将在下次重启后移除!"
                exit 0
            }
        fi
    } ;;
    "remove") {
        rm -rf $modulePath && {
            echo "已成功移除模块 ${module} !"
            exit 0
        }
    } ;;
    *) {
        echo -e "\n未知操作: $operate"
        exit 1
    } ;;
esac

echo -e "\n命令执行失败!"
exit 1
