#!/sbin/sh

operate=$1
module=$2

workPath=/magisk
modulePath=${workPath}/${module}

if [ "$operate" = "status" ]; then
    # Enable: 1, Disable: 0, Removed: 2, UpdateFlag: 3, RemoveFlag: 4
    [ ! -d $modulePath ] && exit 2
    [ -f $modulePath/update ] && exit 3
    [ -f $modulePath/remove ] && exit 4
    [ -f $modulePath/disable ] && exit 0
    exit 1
fi

if [ "$operate" = "switch_module" ]; then
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
fi

if [ "$operate" = "status_auto_mount" ]; then
    # Enable: 1, Disable: 0, Removed: 2
    [ ! -d $modulePath ] && exit 2
    [ -f $modulePath/auto_mount ] && exit 1 || exit 0
fi

if [ "$operate" = "status_skip_mount" ]; then
    # Enable: 1, Disable: 0, Removed: 2
    [ ! -d $modulePath ] && exit 2
    [ -f $modulePath/skip_mount ] && exit 0 || exit 1
fi

if [ "$operate" = "switch_auto_mount" ]; then
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
fi

if [ "$operate" = "switch_skip_mount" ]; then
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
fi

if [ "$operate" = "switch_remove" ]; then
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
fi

if [ "$operate" = "remove" ]; then
    rm -rf $modulePath && {
        echo "已成功移除模块 ${module} !"
        exit 0
    }
fi

echo -e "\n命令执行失败!"
exit 1
