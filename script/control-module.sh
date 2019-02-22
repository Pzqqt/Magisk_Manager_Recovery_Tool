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
    if [ -f ${workPath}/${module}/disable ]; then
        rm -rf ${workPath}/${module}/disable && {
            echo "已成功启用模块 ${module} !"
            exit 0
        }
    else
        touch ${workPath}/${module}/disable && {
            echo "已成功禁用模块 ${module} !"
            exit 0
        }
    fi
fi

if [ "$operate" = "switch_auto_mount" ]; then
    if [ -f ${workPath}/${module}/auto_mount ]; then
        rm -rf ${workPath}/${module}/auto_mount && {
            echo "已成功为模块 ${module} 禁用 auto_mount!"
            exit 0
        }
    else
        touch ${workPath}/${module}/auto_mount && {
            echo "已成功为模块 ${module} 启用 auto_mount!"
            exit 0
        }
    fi
fi

if [ "$operate" = "remove" ]; then
    rm -rf ${workPath}/${module} && {
        echo "已成功移除模块 ${module} !"
        exit 0
    }
fi

echo ""
echo "命令执行失败!"
exit 1
