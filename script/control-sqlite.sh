#!/sbin/sh

operate=$1
arg_2=$2
arg_3=$3

sqlite_path=/data/adb/magisk.db
sqlite3_exec=/tmp/mmr/script/sqlite3

# find available sqlite3
find_sqlite3() {
    # force use prebuilt sqlite3 binary
    $sqlite3_exec --version &>/dev/null || {
        echo -e "\nCannot found available sqlite3!"
        exit 2
    }
}

find_sqlite3
case $operate in
    "get_sqlite3_path") echo $sqlite3_exec;;
    "clear_su_log") {
        $sqlite3_exec $sqlite_path "DELETE FROM logs"
    } ;;
    "get_saved_package_name_policy") {
        $sqlite3_exec $sqlite_path "SELECT package_name, policy FROM policies ORDER BY package_name"
    } ;;
    "get_saved_package_name_uid") {
        $sqlite3_exec $sqlite_path "SELECT package_name, uid FROM policies ORDER BY package_name"
    } ;;
    "set_policy") {
        [ -n "$arg_2" -a -n "$arg_3" ] || { echo "Missing parameter" && exit 1; }
        $sqlite3_exec $sqlite_path "UPDATE policies SET policy=${arg_3} WHERE uid=${arg_2}"
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
