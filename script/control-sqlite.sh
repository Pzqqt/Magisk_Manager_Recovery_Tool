#!/sbin/sh

operate=$1
arg_2=$2
arg_3=$3

sqlite_path=/data/adb/magisk.db
sqlite3_exec=""

is_mounted() { mountpoint -q $1; }

# find available sqlite3
find_sqlite3() {
    is_mounted /system || mount -o ro /system
    which sqlite3 &>/dev/null && sqlite3_exec=`which sqlite3` || {
        for find_path in /system/bin /system/xbin; do
            if [ -f ${find_path}/sqlite3 ]; then
                ln -s ${find_path}/sqlite3 /sbin/
                sqlite3_exec="sqlite3"
                break
            fi
        done
    }
    [ -n "$sqlite3_exec" ] && $sqlite3_exec --version &>/dev/null || {
        echo -e "\nCannot found available sqlite3!"
        exit 2
    }
}

find_sqlite3
case $operate in
    "get_sqlite3_path") {
        [ -L $sqlite3_exec ] && echo $(readlink $sqlite3_exec) || echo $sqlite3_exec
    };;
    "clear_su_log") {
        $sqlite3_exec $sqlite_path "DELETE FROM logs" <<EOF
.quit
EOF
    } ;;
    "get_saved_package_name_policy") {
        $sqlite3_exec $sqlite_path "SELECT package_name, policy FROM policies" <<EOF
.quit
EOF
    } ;;
    "get_saved_package_name_uid") {
        $sqlite3_exec $sqlite_path "SELECT package_name, uid FROM policies" <<EOF
.quit
EOF
    } ;;
    "set_policy") {
        [ -n "$arg_2" -a -n "$arg_3" ] || { echo "Missing parameter" && exit 1; }
        $sqlite3_exec $sqlite_path "UPDATE policies SET policy=${arg_3} WHERE uid=${arg_2}" <<EOF
.quit
EOF
    } ;;
    *) {
        cat <<EOF
Usage: $0 <operate>

operate:
    get_sqlite3_path              : Get available sqlite3 path
    clear_su_log                  : Clear MagiskSU logs
    get_saved_package_name_policy : List saved package name & policy status
    get_saved_package_name_uid    : List saved package name & uid
    set_policy <uid> <vaule>      : Change policy value
EOF
        exit 1
    } ;;
esac

[ $? = 0 ] || exit 1
