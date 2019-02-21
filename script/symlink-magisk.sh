#!/sbin/sh

modulesdir=$1
workPath=$2

donescript=/tmp/mmr/script/done-script.sh

is_mounted() { mountpoint -q "$1"; }

symlink_modules() {
    mount -o remount,rw /
    rm -rf $2
    ln -s $1 $2
}

gen_done_script() {
    cat > $donescript <<EOF
#!/sbin/sh

rm -rf $workPath

EOF
    chmod 0755 $donescript
}

symlink_modules $modulesdir $workPath

gen_done_script
