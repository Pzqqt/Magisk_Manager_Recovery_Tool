#!/sbin/sh

operate=$1

magiskbin_path=/data/adb/magisk/magisk
sqlite_path=/data/adb/magisk.db
sqlite3_exec=""

is_mounted() { mountpoint -q $1; }

# find available sqlite3
find_sqlite3() {
    is_mounted /system || mount -o ro /system
    which sqlite3 && sqlite3_exec=`which sqlite3` || {
        for find_path in /system/bin /system/xbin; do
            if [ -f ${find_path}/sqlite3 ]; then
                ln -s ${find_path}/sqlite3 /sbin/
                sqlite3_exec="sqlite3"
                break
            fi
        done
    }
    [ -n "$sqlite3_exec" ] && $sqlite3_exec --version || {
        ps | grep "magiskd" | grep -qv "grep" || {
            $magiskbin_path --daemon || {
                echo -e "\nCannot found available sqlite3!"
                exit 1
            }
        }
        sqlite3_exec="$magiskbin_path --sqlite"
        sqlite_path=""
    }
}

find_sqlite3
case $operate in
    "clear_su_log") {
        $sqlite3_exec $sqlite_path "DELETE FROM logs" <<EOF
.quit
EOF
    } ;;
    "clear_su_policies") {
        $sqlite3_exec $sqlite_path "DELETE FROM policies" <<EOF
.quit
EOF
    } ;;
    "reject_all_su") {
        $sqlite3_exec $sqlite_path "UPDATE policies set policy=1" <<EOF
.quit
EOF
    } ;;
    "allow_all_su") {
        $sqlite3_exec $sqlite_path "UPDATE policies set policy=2" <<EOF
.quit
EOF
    } ;;
    *) {
        cat <<EOF
Usage: $0 <operate>

operate:
    clear_su_log        : Clear MagiskSU logs
    clear_su_policies   : Remove all saved apps MagiskSU permissions
    reject_all_su       : Reject all saved apps MagiskSU permissions
    allow_all_su        : Allow all saved apps MagiskSU permissions
EOF
        exit 1
    } ;;
esac

[ $? = 0 ] || exit 1
