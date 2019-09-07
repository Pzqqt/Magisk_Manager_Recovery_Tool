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
    "get_app_name") {
        [ -n "$arg_2" ] || { echo "Missing parameter" && exit 1; }
        $sqlite3_exec $sqlite_path "SELECT app_name FROM logs WHERE from_uid=${arg_2} LIMIT 1"
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
    "get_magiskhide_status") {
        exit `$sqlite3_exec $sqlite_path "SELECT value FROM settings WHERE key='magiskhide'"`
    } ;;
    "set_magiskhide_status") {
        [ -n "$arg_2" ] || { echo "Missing parameter" && exit 1; }
        $sqlite3_exec $sqlite_path "UPDATE settings SET value=${arg_2} WHERE key='magiskhide'"
    } ;;
    *) {
        cat <<EOF
Usage: $0 <operate>

operate:
    get_sqlite3_path              : Get available sqlite3 path
    get_app_name <uid>            : Try to get app name
    clear_su_log                  : Clear MagiskSU logs
    get_saved_package_name_policy : List saved package name & policy status
    get_saved_package_name_uid    : List saved package name & uid
    set_policy <uid> <vaule>      : Change policy value
    get_magiskhide_status         : Get Magisk Hide status
    set_magiskhide_status <value> : Set Magisk Hide status (0: disable, 1: enable)
EOF
        exit 1
    } ;;
esac
