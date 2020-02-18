#!/sbin/sh

. /tmp/mmr/script/common.sh

operate=$1
module=$2

exist_backup() { test -f ${module_backup_path}/${1}.tar.gz; }

exist_module() { test -d ${workPath}/${1}; }

backup_module() {
    exist_module || {
        echo -e "\n错误: 模块 ${1} 不存在!"；
        exit 1
    }
    cd ${workPath}
    tar -czf ${module_backup_path}/${1}.tar.gz ./${1}
    ec=$?
    sync
    exit $ec
}

restore_backup() {
    rm -rf ${workPath}/${1}
    tar -xzvf ${module_backup_path}/${1}.tar.gz -C ${workPath}/
    ec=$?
    [ "$ec" -eq 0 ] && rm -f ${workPath}/${1}/remove
    sync
    exit $ec
}

[ -n $operate ] && [ -n $module ] && \
case $operate in
    "exist_backup") {
        # exist: 1, not exist: 0
        exist_backup $module
        [ $? -eq 0 ] && exit 1 || exit 0;
    };;
    "exist_module") {
        # exist: 1, not exist: 0
        exist_module $module
        [ $? -eq 0 ] && exit 1 || exit 0;
    };;
    "backup") backup_module $module;;
    "restore") restore_backup $module;;
    "remove_backup") {
        rm -rf ${module_backup_path}/${module}.tar.gz
        local ec=$?
        sync
        exit $ec
    };;
    *) {
        echo -e "\n未知操作: $operate";
        exit 1
    };;
esac
