#!/sbin/sh

modulesdir=$1
mountPath=$2

donescript=/tmp/mmr/script/done-script.sh

is_mounted() { mountpoint -q "$1"; }

symlink_modules() {
    mount -o remount,rw /
    rm -rf $2
    mkdir -p $2
    is_mounted $2 && {
        loopedA=`mount | grep $2 | head -n1 | cut -d " " -f1`
        umount $2
        losetup -d $loopedA
    }
    installed_modules=`ls -1 $1 | grep -v 'lost+found'`
    if [ ${#installed_modules} -ne 0 ]; then
        for module in ${installed_modules}; do
            ln -s ${1}/${module} $2
        done
    fi
}

gen_done_script() {
    cat > $donescript <<EOF
#!/sbin/sh

rm -rf /magisk

EOF
    chmod 0755 $donescript
}

symlink_modules $modulesdir $mountPath

gen_done_script
