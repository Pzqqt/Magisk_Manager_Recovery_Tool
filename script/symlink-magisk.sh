#!/sbin/sh

modulesdir=$1
workPath=$2

donescript=/tmp/mmr/script/done-script.sh

is_mounted() { mountpoint -q "$1"; }

symlink_modules() {
    mount -o remount,rw /
    [ -d "$2" ] && is_mounted $2 && {
        loopedA=`mount | grep $2 | head -n1 | cut -d " " -f1`
        umount $2
        losetup -d $loopedA
    }
    rm -rf $2
    ln -s $1 $2
}

gen_done_script() {
    cat > $donescript <<EOF
#!/sbin/sh

umount /system
rm -f $workPath

EOF
    chmod 0755 $donescript
}

symlink_modules $modulesdir $workPath

gen_done_script
