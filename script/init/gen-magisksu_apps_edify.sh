#!/sbin/sh

ac_3=/tmp/mmr/template/META-INF/com/google/android/aroma/magisksu_apps.edify

cat >> $ac_3 <<EOF
            checkbox(
                "Root manager",
                "Check the box to grant superuser rights, otherwise denied.",
                "@welcome",
                "magisksu_apps.prop",
EOF

pps=`/tmp/mmr/script/control-sqlite.sh get_saved_package_name_uid | sed 's/|/=/g'`
if [ -z "$pps" ]; then
    echo "                \"Seem you have not given rights for any app\",\"\", 2," >> $ac_3
else
    for pp in $pps; do
        package_name=${pp%=*}
        uid_=${pp#*=}
        app_name=`/tmp/mmr/script/control-sqlite.sh get_app_name ${uid_}`
        [ -z "$app_name" ] || app_name=" (${app_name})"
        echo "                \"${package_name}${app_name}\", \"uid: ${uid_}\", 0," >> $ac_3
    done
fi

cat >> $ac_3 <<EOF
            "", "", 3
        );
EOF
