#!/sbin/sh

. /tmp/mmr/script/common.sh

operate=$1
arg_2=$2
arg_3=$3

sqlite3_exec=/tmp/mmr/bin/sqlite3

# force use prebuilt sqlite3 binary
$sqlite3_exec --version &>/dev/null || {
    echo -e "\nCannot found available sqlite3!"
    exit 2
}

case $operate in
    "get_sqlite3_path") echo $sqlite3_exec;;
    "clear_su_log") {
        $sqlite3_exec $sulogs_sq "DELETE FROM logs"
    };;
    "get_app_name") {
        [ -n "$arg_2" ] || { echo "Missing parameter"; exit 1; }
        $sqlite3_exec $sulogs_sq "SELECT ${label_appname} FROM logs WHERE ${label_fromuid}=${arg_2} LIMIT 1"
    };;
    "get_saved_package_name_policy") {
        $sqlite3_exec $magisk_db "SELECT package_name, policy FROM policies ORDER BY package_name"
    };;
    "get_saved_package_name_uid") {
        $sqlite3_exec $magisk_db "SELECT package_name, uid FROM policies ORDER BY package_name"
    };;
    "get_saved_uid_policy") {
        $sqlite3_exec $magisk_db "SELECT uid, policy FROM policies ORDER BY uid"
    };;
    "set_policy") {
        [ -n "$arg_2" -a -n "$arg_3" ] || { echo "Missing parameter"; exit 1; }
        $sqlite3_exec $magisk_db "UPDATE policies SET policy=${arg_3} WHERE uid=${arg_2}"
    };;
    "get_magiskhide_status") {
        [ "$MAGISK_VER_CODE" -lt 23010 ] || { echo "Magisk Hide has been removed in Magisk 23010+."; exit 2; }
        rc=`$sqlite3_exec $magisk_db "SELECT value FROM settings WHERE key='magiskhide'"`
        [ -z "$rc" ] && exit 0 || exit $rc
    };;
    "get_zygisk_status") {
        [ "$MAGISK_VER_CODE" -ge 23010 ] || { echo "Zygisk is only available in Magisk 23010+."; exit 2; }
        rc=`$sqlite3_exec $magisk_db "SELECT value FROM settings WHERE key='zygisk'"`
        [ -z "$rc" ] && exit 0 || exit $rc
    };;
    "get_denylist_status") {
        [ "$MAGISK_VER_CODE" -ge 23010 ] || { echo "Deny List is only available in Magisk 23010+."; exit 2; }
        rc=`$sqlite3_exec $magisk_db "SELECT value FROM settings WHERE key='denylist'"`
        [ -z "$rc" ] && exit 0 || exit $rc
    };;
    "set_magiskhide_status") {
        [ "$MAGISK_VER_CODE" -lt 23010 ] || { echo "Magisk Hide has been removed in Magisk 23010+."; exit 1; }
        [ -n "$arg_2" ] || { echo "Missing parameter" && exit 1; }
        $sqlite3_exec $magisk_db "REPLACE INTO settings (key, value) VALUES ('magiskhide', ${arg_2})"
    };;
    "set_zygisk_status") {
        [ "$MAGISK_VER_CODE" -ge 23010 ] || { echo "Zygisk is only available in Magisk 23010+."; exit 1; }
        [ -n "$arg_2" ] || { echo "Missing parameter" && exit 1; }
        $sqlite3_exec $magisk_db "REPLACE INTO settings (key, value) VALUES ('zygisk', ${arg_2})"
    };;
    "set_denylist_status") {
        [ "$MAGISK_VER_CODE" -ge 23010 ] || { echo "Deny List is only available in Magisk 23010+."; exit 1; }
        [ -n "$arg_2" ] || { echo "Missing parameter" && exit 1; }
        $sqlite3_exec $magisk_db "REPLACE INTO settings (key, value) VALUES ('denylist', ${arg_2})"
    };;
    *) {
        cat <<EOF
Usage: $0 <operate>

operate:
    get_sqlite3_path              : Get available sqlite3 binary path
    get_app_name <uid>            : Try to get app name
    clear_su_log                  : Clear MagiskSU logs
    get_saved_package_name_policy : List saved package name & policy status
    get_saved_package_name_uid    : List saved package name & uid
    get_saved_uid_policy          : List saved uid & policy status
    set_policy <uid> <vaule>      : Change policy value
    get_magiskhide_status         : Get Magisk Hide status (NOT for Magisk 23010+)
    set_magiskhide_status <value> : Set Magisk Hide status (0: disable, 1: enable) (NOT for Magisk 23010+)
    get_zygisk_status             : Get Zygisk status (only for Magisk 23010+)
    set_zygisk_status <value>     : Set Zygisk status (0: disable, 1: enable) (only for Magisk 23010+)
    get_denylist_status           : Get Deny List status (only for Magisk 23010+)
    set_denylist_status <value>   : Set Deny List status (0: disable, 1: enable) (only for Magisk 23010+)
EOF
        exit 1
    };;
esac
