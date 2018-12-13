#!/sbin/sh

IMG=$1
mountPath=$2

umscript=/tmp/mmr/script/umount-magisk.sh
skscript=/tmp/mmr/script/shrink-magiskimg.sh

is_mounted() { mountpoint -q "$1"; }

mount_image() {
    e2fsck -fy $IMG &>/dev/null
    if [ ! -d "$2" ]; then
        mount -o remount,rw /
        mkdir -p "$2"
    fi
    is_mounted $2 && {
        loopedA=`mount | grep $2 | head -n1 | cut -d " " -f1`
        umount $2
        losetup -d $loopedA
    }
    loopDevice=
    for LOOP in 0 1 2 3 4 5 6 7; do
        if (! is_mounted $2); then
            loopDevice=/dev/block/loop$LOOP
            [ -f "$loopDevice" ] || mknod $loopDevice b 7 $LOOP 2>/dev/null
            losetup $loopDevice $1
            if [ "$?" -eq "0" ]; then
                mount -t ext4 -o loop $loopDevice $2
                is_mounted $2 || /system/bin/toolbox mount -t ext4 -o loop $loopDevice $2
                is_mounted $2 || /system/bin/toybox mount -t ext4 -o loop $loopDevice $2
            fi
            is_mounted $2 && break
        fi
    done
    if ! is_mounted $mountPath; then
        exit 1
    fi
}

gen_umount_script() {
    cat > $umscript <<EOF
#!/sbin/sh

umount /system
umount $mountPath
losetup -d $loopDevice
rmdir $mountPath
EOF
    chmod 0755 $umscript
}

gen_shrink_script() {
    cat > $skscript <<EOF
#!/sbin/sh

require_new_magisk() {
    echo "*******************************"
    echo " Please install Magisk v17.0+! "
    echo "*******************************"
    exit 1
}

if [ -f /data/adb/magisk/util_functions.sh ]; then
    . /data/adb/magisk/util_functions.sh
elif [ -f /data/magisk/util_functions.sh ]; then
    NVBASE=/data
    . /data/magisk/util_functions.sh
else
    require_new_magisk
fi

unset ui_print
ui_print() { echo "\$1"; }

unset check_filesystem
check_filesystem() {
    curSizeM=\`wc -c < \$1\`
    curSizeM=\$((curSizeM / 1048576))
    local DF=\`df -Pk \$2 | grep \$2\`
    curUsedM=\`echo \$DF | awk '{ print int(\$3 / 1024) }'\`
    curFreeM=\`echo \$DF | awk '{ print int(\$4 / 1024) }'\`
}

IMG=$IMG
MOUNTPATH=$mountPath
MAGISKLOOP=$loopDevice

recovery_actions
unmount_magisk_img
recovery_cleanup

is_mounted \$MOUNTPATH && {
    loopedB=\`mount | grep \$MOUNTPATH | head -n1 | cut -d " " -f1\`
    umount \$MOUNTPATH
    losetup -d \$loopedB
}

rmdir \$MOUNTPATH || {
    echo "! Failed to unmount magisk.img!"
    echo ""
    exit 1
}

echo ""
echo "- Shrinking $IMG to \${newSizeM}M"
echo ""

EOF
    chmod 0755 $skscript
}

mount_image $IMG $mountPath || exit 1

gen_umount_script

gen_shrink_script
