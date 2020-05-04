#!/sbin/sh

modulesPath=$1
workPath=$2

donescript=/tmp/mmr/script/done-script.sh

is_mounted() { mountpoint -q "$1"; }

symlink_modules() {
    mount -o remount,rw /
    [ -L "$2" ] && rm -f $2
    [ -d "$2" ] && {
        is_mounted $2 && {
            loopedA=`mount | grep $2 | head -n1 | cut -d " " -f1`
            umount $2
            losetup -d $loopedA
        }
        rm -rf $2
    }
    ln -s $1 $2 || exit 1
}

gen_done_script() {
    cat > $donescript <<EOF
#!/sbin/sh

rm -f $workPath

[ -z "\$PATH_BAK" ] || {
    export PATH=\$PATH_BAK
    unset PATH_BAK
}

sync
EOF
    chmod 0755 $donescript
}

symlink_modules $modulesPath $workPath

gen_done_script
